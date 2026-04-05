package server

import (
	"context"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"cortex/backend/internal/config"
	"cortex/backend/internal/models"
	"cortex/backend/internal/services"
	"cortex/backend/internal/store"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"go.mongodb.org/mongo-driver/mongo"
)

type API struct {
	cfg        config.Config
	store      *store.MongoStore
	classifier *services.ClassifierService
	feedback   *services.FeedbackService
	analytics  *services.AnalyticsService
	modes      *services.ModeManager
	cortex     *services.CortexService
	aiProxy    *services.AIProxyService
	modelStats *services.ModelStatusService
	dispatcher *services.PushDispatcher
	upgrader   websocket.Upgrader
}

func NewAPI(
	cfg config.Config,
	s *store.MongoStore,
	classifier *services.ClassifierService,
	feedback *services.FeedbackService,
	analytics *services.AnalyticsService,
	modeManager *services.ModeManager,
	cortex *services.CortexService,
	aiProxy *services.AIProxyService,
	modelStats *services.ModelStatusService,
	dispatcher *services.PushDispatcher,
) *API {
	return &API{
		cfg:        cfg,
		store:      s,
		classifier: classifier,
		feedback:   feedback,
		analytics:  analytics,
		modes:      modeManager,
		cortex:     cortex,
		aiProxy:    aiProxy,
		modelStats: modelStats,
		dispatcher: dispatcher,
		upgrader:   websocket.Upgrader{CheckOrigin: func(r *http.Request) bool { return true }},
	}
}

func (a *API) Routes() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /ws", a.handleWS)
	mux.HandleFunc("POST /api/notifications/ingest", a.handleIngest)
	mux.HandleFunc("GET /api/notifications", a.handleListNotifications)
	mux.HandleFunc("GET /api/notifications/{id}", a.handleGetNotification)
	mux.HandleFunc("PUT /api/notifications/{id}/read", a.handleMarkRead)
	mux.HandleFunc("PUT /api/notifications/{id}/action", a.handleMarkActioned)
	mux.HandleFunc("DELETE /api/notifications/{id}", a.handleDismiss)
	mux.HandleFunc("GET /api/analytics", a.handleAnalytics)
	mux.HandleFunc("GET /api/modes", a.handleListModes)
	mux.HandleFunc("GET /api/modes/active", a.handleGetActiveMode)
	mux.HandleFunc("POST /api/modes", a.handleCreateMode)
	mux.HandleFunc("PUT /api/modes/{id}", a.handleUpdateMode)
	mux.HandleFunc("PUT /api/modes/{id}/activate", a.handleActivateMode)
	mux.HandleFunc("DELETE /api/modes/{id}", a.handleDeleteMode)
	mux.HandleFunc("GET /api/rules", a.handleListRules)
	mux.HandleFunc("POST /api/rules", a.handleCreateRule)
	mux.HandleFunc("PUT /api/rules/{id}", a.handleUpdateRule)
	mux.HandleFunc("DELETE /api/rules/{id}", a.handleDeleteRule)
	mux.HandleFunc("PUT /api/rules/reorder", a.handleReorderRules)
	mux.HandleFunc("GET /api/cortex/config", a.handleGetCortexConfig)
	mux.HandleFunc("PUT /api/cortex/config", a.handleUpdateCortexConfig)
	mux.HandleFunc("GET /api/cortex/replies", a.handleListReplies)
	mux.HandleFunc("POST /api/cortex/replies", a.handleCreateReply)
	mux.HandleFunc("PUT /api/cortex/replies/{id}", a.handleUpdateReply)
	mux.HandleFunc("DELETE /api/cortex/replies/{id}", a.handleDeleteReply)
	mux.HandleFunc("GET /api/cortex/scheduled", a.handleListScheduled)
	mux.HandleFunc("POST /api/cortex/scheduled", a.handleCreateScheduled)
	mux.HandleFunc("PUT /api/cortex/scheduled/{id}/approve", a.handleApproveScheduled)
	mux.HandleFunc("DELETE /api/cortex/scheduled/{id}", a.handleCancelScheduled)
	mux.HandleFunc("GET /api/cortex/activity", a.handleListActivity)
	mux.HandleFunc("POST /api/cortex/voice/enroll", a.handleVoiceEnroll)
	mux.HandleFunc("POST /api/cortex/voice/verify", a.handleVoiceVerify)
	mux.HandleFunc("GET /api/ai/model/status", a.handleAIModelStatus)
	mux.HandleFunc("POST /api/ai/finetune", a.handleAIFinetune)
	mux.HandleFunc("GET /api/ai/cortex/log", a.handleAICortexLog)
	mux.HandleFunc("GET /api/ai/cortex/status", a.handleAICortexStatus)
	mux.HandleFunc("POST /api/ai/voice-assistant/start", a.handleAIVoiceAssistantStart)
	mux.HandleFunc("POST /api/ai/voice-assistant/stop", a.handleAIVoiceAssistantStop)
	mux.HandleFunc("GET /api/ai/voice-assistant/status", a.handleAIVoiceAssistantStatus)
	mux.HandleFunc("POST /api/ai/voice-assistant/transcribe", a.handleAIVoiceAssistantTranscribe)
	mux.HandleFunc("POST /api/ai/voice-assistant/reader/command", a.handleAIVoiceAssistantReaderCommand)
	mux.HandleFunc("GET /api/profile", a.handleGetProfile)
	mux.HandleFunc("PUT /api/profile", a.handleUpdateProfile)
	mux.HandleFunc("POST /api/profile/avatar", a.handleUploadAvatar)
	return corsMiddleware(mux)
}

func (a *API) handleWS(w http.ResponseWriter, r *http.Request) {
	conn, err := a.upgrader.Upgrade(w, r, nil)
	if err != nil {
		writeError(w, http.StatusBadRequest, "websocket upgrade failed", "BAD_REQUEST")
		return
	}
	a.dispatcher.AddConn(conn)
	go func() {
		defer a.dispatcher.RemoveConn(conn)
		for {
			if _, _, err := conn.ReadMessage(); err != nil {
				return
			}
		}
	}()
}

func (a *API) handleIngest(w http.ResponseWriter, r *http.Request) {
	var n models.Notification
	if err := json.NewDecoder(r.Body).Decode(&n); err != nil {
		writeError(w, http.StatusBadRequest, "invalid json body", "VALIDATION_ERROR")
		return
	}
	if n.Content == "" || n.AppPackage == "" {
		writeError(w, http.StatusBadRequest, "content and app_package are required", "VALIDATION_ERROR")
		return
	}
	if strings.TrimSpace(n.AppName) == "" {
		n.AppName = n.AppPackage
	}

	n.ID = uuid.NewString()
	n.Timestamp = time.Now().UTC()
	n.IsRead = false
	n.IsActioned = false

	activeMode, err := a.modes.GetActive(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to resolve active mode", "INTERNAL_ERROR")
		return
	}

	p, conf, reason, err := a.classifier.Classify(r.Context(), n.AppName, n.Content, activeMode.Name)
	if err != nil {
		log.Printf("classifier warning: %v", err)
	}
	n.Priority = p
	n.Confidence = conf
	n.LabelReason = reason

	rules, err := a.store.ListRules(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed loading rules", "INTERNAL_ERROR")
		return
	}
	finalPriority, finalReason := services.ApplyRules(&n, rules, activeMode)
	n.Priority = finalPriority
	n.Mode = activeMode.Name
	if finalReason != "" {
		n.LabelReason = finalReason
	}

	if err := a.store.SaveNotification(r.Context(), &n); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to save notification", "INTERNAL_ERROR")
		return
	}
	a.dispatcher.DispatchNotification(&n)

	cfg, err := a.store.GetCortexConfig(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed loading cortex config", "INTERNAL_ERROR")
		return
	}
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := a.cortex.MaybeAutoReply(ctx, &n, cfg); err != nil {
			log.Printf("cortex async warning: %v", err)
		}
	}()

	writeJSON(w, http.StatusCreated, n)
}

func (a *API) handleListNotifications(w http.ResponseWriter, r *http.Request) {
	items, err := a.store.ListNotifications(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list notifications", "INTERNAL_ERROR")
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (a *API) handleGetNotification(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	n, err := a.store.GetNotification(r.Context(), id)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to fetch notification", "INTERNAL_ERROR")
		return
	}
	if n == nil {
		writeError(w, http.StatusNotFound, "notification not found", "NOT_FOUND")
		return
	}
	writeJSON(w, http.StatusOK, n)
}

func (a *API) handleMarkRead(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	err := a.store.MarkRead(r.Context(), id)
	if err == mongo.ErrNoDocuments {
		writeError(w, http.StatusNotFound, "notification not found", "NOT_FOUND")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to mark read", "INTERNAL_ERROR")
		return
	}
	writeJSON(w, http.StatusOK, map[string]bool{"ok": true})
}

func (a *API) handleMarkActioned(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	n, err := a.store.GetNotification(r.Context(), id)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to fetch notification", "INTERNAL_ERROR")
		return
	}
	if n == nil {
		writeError(w, http.StatusNotFound, "notification not found", "NOT_FOUND")
		return
	}

	var payload struct {
		CorrectedPriority string `json:"corrected_priority"`
	}
	if r.Body != nil {
		_ = json.NewDecoder(r.Body).Decode(&payload)
	}

	err = a.store.MarkActioned(r.Context(), id)
	if err == mongo.ErrNoDocuments {
		writeError(w, http.StatusNotFound, "notification not found", "NOT_FOUND")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to mark actioned", "INTERNAL_ERROR")
		return
	}

	if strings.TrimSpace(payload.CorrectedPriority) != "" {
		go func(notification *models.Notification, corrected string) {
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()
			if err := a.feedback.SubmitFeedback(ctx, notification.Content, notification.AppName, notification.Mode, corrected); err != nil {
				log.Printf("feedback warning: %v", err)
			}
		}(n, payload.CorrectedPriority)
	}
	writeJSON(w, http.StatusOK, map[string]bool{"ok": true})
}

func (a *API) handleDismiss(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	err := a.store.SoftDeleteNotification(r.Context(), id)
	if err == mongo.ErrNoDocuments {
		writeError(w, http.StatusNotFound, "notification not found", "NOT_FOUND")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to dismiss notification", "INTERNAL_ERROR")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (a *API) handleAnalytics(w http.ResponseWriter, r *http.Request) {
	rangeStr := r.URL.Query().Get("range")
	if rangeStr == "" {
		writeError(w, http.StatusBadRequest, "range query param is required", "VALIDATION_ERROR")
		return
	}
	resp, err := a.analytics.GetAnalytics(r.Context(), rangeStr)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to compute analytics", "INTERNAL_ERROR")
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (a *API) handleListModes(w http.ResponseWriter, r *http.Request) {
	items, err := a.store.ListModes(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list modes", "INTERNAL_ERROR")
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (a *API) handleGetActiveMode(w http.ResponseWriter, r *http.Request) {
	mode, err := a.modes.GetActive(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to fetch active mode", "INTERNAL_ERROR")
		return
	}
	writeJSON(w, http.StatusOK, mode)
}

func (a *API) handleCreateMode(w http.ResponseWriter, r *http.Request) {
	var mode models.Mode
	if err := json.NewDecoder(r.Body).Decode(&mode); err != nil {
		writeError(w, http.StatusBadRequest, "invalid json body", "VALIDATION_ERROR")
		return
	}
	if mode.Name == "" {
		writeError(w, http.StatusBadRequest, "name is required", "VALIDATION_ERROR")
		return
	}
	mode.ID = uuid.NewString()
	mode.IsPreset = false
	mode.IsActive = false
	if err := a.store.CreateMode(r.Context(), &mode); err != nil {
		writeError(w, http.StatusConflict, "mode already exists", "CONFLICT")
		return
	}
	writeJSON(w, http.StatusCreated, mode)
}

func (a *API) handleUpdateMode(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	existing, err := a.store.GetModeByID(r.Context(), id)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to fetch mode", "INTERNAL_ERROR")
		return
	}
	if existing == nil {
		writeError(w, http.StatusNotFound, "mode not found", "NOT_FOUND")
		return
	}
	var mode models.Mode
	if err := json.NewDecoder(r.Body).Decode(&mode); err != nil {
		writeError(w, http.StatusBadRequest, "invalid json body", "VALIDATION_ERROR")
		return
	}
	mode.ID = existing.ID
	mode.IsPreset = existing.IsPreset
	if existing.IsPreset {
		mode.Name = existing.Name
	}
	if err := a.store.UpdateMode(r.Context(), id, &mode); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update mode", "INTERNAL_ERROR")
		return
	}
	updated, _ := a.store.GetModeByID(r.Context(), id)
	writeJSON(w, http.StatusOK, updated)
}

func (a *API) handleActivateMode(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if err := a.modes.SetActive(r.Context(), id); err == mongo.ErrNoDocuments {
		writeError(w, http.StatusNotFound, "mode not found", "NOT_FOUND")
		return
	} else if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to activate mode", "INTERNAL_ERROR")
		return
	}
	active, _ := a.modes.GetActive(r.Context())
	writeJSON(w, http.StatusOK, active)
}

func (a *API) handleDeleteMode(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	err := a.store.DeleteMode(r.Context(), id)
	if err == mongo.ErrNoDocuments {
		writeError(w, http.StatusNotFound, "mode not found", "NOT_FOUND")
		return
	}
	if err != nil {
		writeError(w, http.StatusConflict, "cannot delete preset mode", "CONFLICT")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (a *API) handleListRules(w http.ResponseWriter, r *http.Request) {
	rules, err := a.store.ListRules(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list rules", "INTERNAL_ERROR")
		return
	}
	writeJSON(w, http.StatusOK, rules)
}

func (a *API) handleCreateRule(w http.ResponseWriter, r *http.Request) {
	var rule models.Rule
	if err := json.NewDecoder(r.Body).Decode(&rule); err != nil {
		writeError(w, http.StatusBadRequest, "invalid json body", "VALIDATION_ERROR")
		return
	}
	rule.ID = uuid.NewString()
	if rule.Order == 0 {
		nextOrder, err := a.store.NextRuleOrder(r.Context())
		if err != nil {
			writeError(w, http.StatusInternalServerError, "failed to allocate rule order", "INTERNAL_ERROR")
			return
		}
		rule.Order = nextOrder
	}
	if err := a.store.CreateRule(r.Context(), &rule); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to create rule", "INTERNAL_ERROR")
		return
	}
	writeJSON(w, http.StatusCreated, rule)
}

func (a *API) handleUpdateRule(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var rule models.Rule
	if err := json.NewDecoder(r.Body).Decode(&rule); err != nil {
		writeError(w, http.StatusBadRequest, "invalid json body", "VALIDATION_ERROR")
		return
	}
	rule.ID = id
	if err := a.store.UpdateRule(r.Context(), id, &rule); err == mongo.ErrNoDocuments {
		writeError(w, http.StatusNotFound, "rule not found", "NOT_FOUND")
		return
	} else if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update rule", "INTERNAL_ERROR")
		return
	}
	writeJSON(w, http.StatusOK, rule)
}

func (a *API) handleDeleteRule(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if err := a.store.DeleteRule(r.Context(), id); err == mongo.ErrNoDocuments {
		writeError(w, http.StatusNotFound, "rule not found", "NOT_FOUND")
		return
	} else if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to delete rule", "INTERNAL_ERROR")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (a *API) handleReorderRules(w http.ResponseWriter, r *http.Request) {
	var body []map[string]any
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid json body", "VALIDATION_ERROR")
		return
	}
	if err := a.store.ReorderRules(r.Context(), body); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to reorder rules", "INTERNAL_ERROR")
		return
	}
	writeJSON(w, http.StatusOK, map[string]bool{"ok": true})
}

func (a *API) handleGetCortexConfig(w http.ResponseWriter, r *http.Request) {
	cfg, err := a.store.GetCortexConfig(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load cortex config", "INTERNAL_ERROR")
		return
	}
	writeJSON(w, http.StatusOK, cfg)
}

func (a *API) handleUpdateCortexConfig(w http.ResponseWriter, r *http.Request) {
	var cfg models.CortexConfig
	if err := json.NewDecoder(r.Body).Decode(&cfg); err != nil {
		writeError(w, http.StatusBadRequest, "invalid json body", "VALIDATION_ERROR")
		return
	}
	if cfg.Enabled {
		profile, err := a.store.GetProfile(r.Context())
		if err == nil && profile != nil && profile.VoiceLocked {
			writeError(w, http.StatusLocked, "voice profile is locked", "VOICE_LOCKED")
			return
		}
	}
	if err := a.store.UpdateCortexConfig(r.Context(), &cfg); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update cortex config", "INTERNAL_ERROR")
		return
	}
	writeJSON(w, http.StatusOK, cfg)
}

func (a *API) handleListReplies(w http.ResponseWriter, r *http.Request) {
	items, err := a.store.ListReplyTemplates(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list reply templates", "INTERNAL_ERROR")
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (a *API) handleCreateReply(w http.ResponseWriter, r *http.Request) {
	var item models.ReplyTemplate
	if err := json.NewDecoder(r.Body).Decode(&item); err != nil {
		writeError(w, http.StatusBadRequest, "invalid json body", "VALIDATION_ERROR")
		return
	}
	item.ID = uuid.NewString()
	if err := a.store.CreateReplyTemplate(r.Context(), &item); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to create reply template", "INTERNAL_ERROR")
		return
	}
	writeJSON(w, http.StatusCreated, item)
}

func (a *API) handleUpdateReply(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var item models.ReplyTemplate
	if err := json.NewDecoder(r.Body).Decode(&item); err != nil {
		writeError(w, http.StatusBadRequest, "invalid json body", "VALIDATION_ERROR")
		return
	}
	item.ID = id
	if err := a.store.UpdateReplyTemplate(r.Context(), id, &item); err == mongo.ErrNoDocuments {
		writeError(w, http.StatusNotFound, "template not found", "NOT_FOUND")
		return
	} else if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update template", "INTERNAL_ERROR")
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func (a *API) handleDeleteReply(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if err := a.store.DeleteReplyTemplate(r.Context(), id); err == mongo.ErrNoDocuments {
		writeError(w, http.StatusNotFound, "template not found", "NOT_FOUND")
		return
	} else if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to delete template", "INTERNAL_ERROR")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (a *API) handleListScheduled(w http.ResponseWriter, r *http.Request) {
	items, err := a.store.ListScheduledPending(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list scheduled messages", "INTERNAL_ERROR")
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (a *API) handleCreateScheduled(w http.ResponseWriter, r *http.Request) {
	var item models.ScheduledMessage
	if err := json.NewDecoder(r.Body).Decode(&item); err != nil {
		writeError(w, http.StatusBadRequest, "invalid json body", "VALIDATION_ERROR")
		return
	}
	if item.DraftBody == "" || item.ScheduledAt.IsZero() {
		writeError(w, http.StatusBadRequest, "draft_body and scheduled_at are required", "VALIDATION_ERROR")
		return
	}
	if item.NotificationID == "" {
		item.NotificationID = "manual"
	}
	item.ID = uuid.NewString()
	item.Status = "pending"

	if err := a.store.CreateScheduled(r.Context(), &item); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to create scheduled message", "INTERNAL_ERROR")
		return
	}
	writeJSON(w, http.StatusCreated, item)
}

func (a *API) handleApproveScheduled(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if err := a.store.SetScheduledStatus(r.Context(), id, "sent"); err == mongo.ErrNoDocuments {
		writeError(w, http.StatusNotFound, "scheduled message not found", "NOT_FOUND")
		return
	} else if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to approve scheduled message", "INTERNAL_ERROR")
		return
	}
	writeJSON(w, http.StatusOK, map[string]bool{"ok": true})
}

func (a *API) handleCancelScheduled(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if err := a.store.SetScheduledStatus(r.Context(), id, "cancelled"); err == mongo.ErrNoDocuments {
		writeError(w, http.StatusNotFound, "scheduled message not found", "NOT_FOUND")
		return
	} else if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to cancel scheduled message", "INTERNAL_ERROR")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (a *API) handleListActivity(w http.ResponseWriter, r *http.Request) {
	items, err := a.store.ListCortexActivity(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list cortex activity", "INTERNAL_ERROR")
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (a *API) handleVoiceEnroll(w http.ResponseWriter, r *http.Request) {
	var reqBody map[string]any
	contentType := r.Header.Get("Content-Type")
	if strings.HasPrefix(contentType, "multipart/form-data") {
		if err := r.ParseMultipartForm(20 << 20); err != nil {
			writeError(w, http.StatusBadRequest, "invalid multipart form", "VALIDATION_ERROR")
			return
		}
		reqBody = map[string]any{
			"user_id":       strings.TrimSpace(r.FormValue("user_id")),
			"audio_samples": r.MultipartForm.Value["audio_samples"],
		}
	} else {
		if err := json.NewDecoder(r.Body).Decode(&reqBody); err != nil {
			writeError(w, http.StatusBadRequest, "invalid json body", "VALIDATION_ERROR")
			return
		}
	}

	userID, _ := reqBody["user_id"].(string)
	rawSamples, ok := reqBody["audio_samples"].([]any)
	if !ok {
		if cast, ok := reqBody["audio_samples"].([]string); ok {
			rawSamples = make([]any, 0, len(cast))
			for _, sample := range cast {
				rawSamples = append(rawSamples, sample)
			}
		}
	}
	if strings.TrimSpace(userID) == "" {
		writeError(w, http.StatusBadRequest, "user_id is required", "VALIDATION_ERROR")
		return
	}
	if len(rawSamples) != 3 {
		writeError(w, http.StatusBadRequest, "audio_samples must contain exactly 3 samples", "VALIDATION_ERROR")
		return
	}

	body, err := json.Marshal(reqBody)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to encode request", "INTERNAL_ERROR")
		return
	}

	respBody, status, proxyErr := a.aiProxy.ProxyToAI(r.Context(), http.MethodPost, "/voice/enroll", body)
	if proxyErr != nil {
		writeError(w, http.StatusServiceUnavailable, "AI service unavailable", "AI_UNREACHABLE")
		return
	}
	writeRawJSON(w, status, respBody)
}

func (a *API) handleVoiceVerify(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(r.Body)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body", "VALIDATION_ERROR")
		return
	}

	respBody, status, proxyErr := a.aiProxy.ProxyToAI(r.Context(), http.MethodPost, "/voice/verify", body)
	if proxyErr != nil {
		writeError(w, http.StatusServiceUnavailable, "AI service unavailable", "AI_UNREACHABLE")
		return
	}

	var verifyResp map[string]any
	if err := json.Unmarshal(respBody, &verifyResp); err == nil {
		if locked, ok := verifyResp["locked"].(bool); ok && locked {
			_ = a.store.SetProfileVoiceLock(r.Context(), true)
		}
	}

	writeRawJSON(w, status, respBody)
}

func (a *API) handleAIModelStatus(w http.ResponseWriter, r *http.Request) {
	status := a.modelStats.GetModelStatus()
	writeJSON(w, http.StatusOK, status)
}

func (a *API) handleAIFinetune(w http.ResponseWriter, r *http.Request) {
	a.handleAIProxy(w, r, http.MethodPost, "/finetune")
}

func (a *API) handleAICortexLog(w http.ResponseWriter, r *http.Request) {
	a.handleAIProxy(w, r, http.MethodGet, "/cortex/log")
}

func (a *API) handleAICortexStatus(w http.ResponseWriter, r *http.Request) {
	a.handleAIProxy(w, r, http.MethodGet, "/cortex/status")
}

func (a *API) handleAIVoiceAssistantStart(w http.ResponseWriter, r *http.Request) {
	a.handleAIProxy(w, r, http.MethodPost, "/voice-assistant/start")
}

func (a *API) handleAIVoiceAssistantStop(w http.ResponseWriter, r *http.Request) {
	a.handleAIProxy(w, r, http.MethodPost, "/voice-assistant/stop")
}

func (a *API) handleAIVoiceAssistantStatus(w http.ResponseWriter, r *http.Request) {
	a.handleAIProxy(w, r, http.MethodGet, "/voice-assistant/status")
}

func (a *API) handleAIVoiceAssistantTranscribe(w http.ResponseWriter, r *http.Request) {
	data, err := io.ReadAll(r.Body)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body", "VALIDATION_ERROR")
		return
	}

	if len(data) > 0 {
		var payload map[string]any
		if err := json.Unmarshal(data, &payload); err == nil {
			if _, hasBase64 := payload["audio_base64"]; !hasBase64 {
				if audio, hasAudio := payload["audio"]; hasAudio {
					payload["audio_base64"] = audio
					delete(payload, "audio")
					if rewritten, marshalErr := json.Marshal(payload); marshalErr == nil {
						data = rewritten
					}
				}
			}
		}
	}

	respBody, status, proxyErr := a.aiProxy.ProxyToAI(r.Context(), http.MethodPost, "/voice-assistant/transcribe", data)
	if proxyErr != nil {
		writeError(w, http.StatusServiceUnavailable, "AI service unavailable", "AI_UNREACHABLE")
		return
	}
	writeRawJSON(w, status, respBody)
}

func (a *API) handleAIVoiceAssistantReaderCommand(w http.ResponseWriter, r *http.Request) {
	a.handleAIProxy(w, r, http.MethodPost, "/voice-assistant/reader/command")
}

func (a *API) handleAIProxy(w http.ResponseWriter, r *http.Request, method, path string) {
	var body []byte
	if r.Body != nil {
		data, err := io.ReadAll(r.Body)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid request body", "VALIDATION_ERROR")
			return
		}
		body = data
	}

	respBody, status, err := a.aiProxy.ProxyToAI(r.Context(), method, path, body)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, "AI service unavailable", "AI_UNREACHABLE")
		return
	}
	writeRawJSON(w, status, respBody)
}

func (a *API) handleGetProfile(w http.ResponseWriter, r *http.Request) {
	p, err := a.store.GetProfile(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load profile", "INTERNAL_ERROR")
		return
	}
	writeJSON(w, http.StatusOK, p)
}

func (a *API) handleUpdateProfile(w http.ResponseWriter, r *http.Request) {
	var profile models.UserProfile
	if err := json.NewDecoder(r.Body).Decode(&profile); err != nil {
		writeError(w, http.StatusBadRequest, "invalid json body", "VALIDATION_ERROR")
		return
	}
	if err := a.store.UpdateProfile(r.Context(), &profile); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update profile", "INTERNAL_ERROR")
		return
	}
	writeJSON(w, http.StatusOK, profile)
}

func (a *API) handleUploadAvatar(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseMultipartForm(10 << 20); err != nil {
		writeError(w, http.StatusBadRequest, "invalid multipart form", "VALIDATION_ERROR")
		return
	}
	file, header, err := r.FormFile("avatar")
	if err != nil {
		writeError(w, http.StatusBadRequest, "avatar file is required", "VALIDATION_ERROR")
		return
	}
	defer file.Close()

	if err := os.MkdirAll(a.cfg.AvatarDir, 0o755); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to create avatar directory", "INTERNAL_ERROR")
		return
	}
	filename := uuid.NewString() + filepath.Ext(header.Filename)
	path := filepath.Join(a.cfg.AvatarDir, filename)
	dst, err := os.Create(path)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to save avatar", "INTERNAL_ERROR")
		return
	}
	defer dst.Close()
	if _, err := io.Copy(dst, file); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to persist avatar", "INTERNAL_ERROR")
		return
	}
	p, err := a.store.GetProfile(r.Context())
	if err == nil && p != nil {
		p.AvatarPath = path
		_ = a.store.UpdateProfile(r.Context(), p)
	}
	writeJSON(w, http.StatusOK, map[string]string{"avatar_path": path})
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func writeRawJSON(w http.ResponseWriter, status int, body []byte) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_, _ = w.Write(body)
}

func writeError(w http.ResponseWriter, status int, msg, code string) {
	writeJSON(w, status, map[string]string{"error": msg, "code": code})
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}
