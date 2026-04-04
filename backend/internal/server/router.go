package server

import (
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"strings"
	"time"

	"cortex/backend/internal/analytics"
	"cortex/backend/internal/auth"
	"cortex/backend/internal/dispatch"
	"cortex/backend/internal/models"
	"cortex/backend/internal/modes"
	"cortex/backend/internal/orchestrator"
	"cortex/backend/internal/rules"
)

type API struct {
	orchestrator *orchestrator.Orchestrator
	rules        *rules.Engine
	modes        *modes.Manager
	dispatcher   *dispatch.Dispatcher
	auth         *auth.Service
	analytics    *analytics.Writer
}

func NewAPI(
	orc *orchestrator.Orchestrator,
	rulesEngine *rules.Engine,
	modeManager *modes.Manager,
	dispatcher *dispatch.Dispatcher,
	authService *auth.Service,
	analyticsWriter *analytics.Writer,
) *API {
	return &API{
		orchestrator: orc,
		rules:        rulesEngine,
		modes:        modeManager,
		dispatcher:   dispatcher,
		auth:         authService,
		analytics:    analyticsWriter,
	}
}

func (a *API) Routes() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /v1/health", a.handleHealth)
	mux.HandleFunc("POST /v1/ingest", a.handleIngest)
	mux.HandleFunc("GET /v1/rules", a.handleListRules)
	mux.HandleFunc("POST /v1/rules", a.handleAddRule)
	mux.HandleFunc("GET /v1/mode", a.handleGetMode)
	mux.HandleFunc("PUT /v1/mode", a.handleSetMode)
	mux.HandleFunc("POST /v1/auth/voice-signature", a.handleStoreVoiceSignature)
	mux.HandleFunc("POST /v1/auth/token", a.handleCreateToken)
	return jsonMiddleware(mux)
}

func (a *API) handleHealth(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{"status": "ok", "time": time.Now().UTC().Format(time.RFC3339)})
}

func (a *API) handleIngest(w http.ResponseWriter, r *http.Request) {
	var n models.Notification
	if err := json.NewDecoder(r.Body).Decode(&n); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json"})
		return
	}
	if n.ReceivedAt.IsZero() {
		n.ReceivedAt = time.Now().UTC()
	}
	if n.Platform == "" {
		n.Platform = "unknown"
	}

	result, err := a.orchestrator.Process(r.Context(), n)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "classification failed"})
		return
	}

	dispatchErr := a.dispatcher.Dispatch(n, result)
	dispatched := dispatchErr == nil
	if dispatchErr != nil && !errors.Is(dispatchErr, netErrNoTargets{}) {
		log.Printf("dispatch warning: %v", dispatchErr)
	}

	a.analytics.Enqueue(analytics.Event{Notification: n, Result: result})
	writeJSON(w, http.StatusOK, models.IngestResponse{Result: result, Dispatched: dispatched})
}

type netErrNoTargets struct{}

func (netErrNoTargets) Error() string { return "no dispatch targets configured" }

func (a *API) handleListRules(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{"rules": a.rules.List()})
}

func (a *API) handleAddRule(w http.ResponseWriter, r *http.Request) {
	var rule models.Rule
	if err := json.NewDecoder(r.Body).Decode(&rule); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json"})
		return
	}
	if rule.ID == "" {
		rule.ID = time.Now().UTC().Format("20060102150405.000000")
	}
	if rule.Priority == "" {
		rule.Priority = models.PriorityHigh
	}
	rule.Enabled = true
	a.rules.Add(rule)
	writeJSON(w, http.StatusCreated, rule)
}

func (a *API) handleGetMode(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"mode": string(a.modes.Get())})
}

func (a *API) handleSetMode(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Mode string `json:"mode"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json"})
		return
	}
	mode := models.ContextMode(strings.ToLower(req.Mode))
	a.modes.Set(mode)
	writeJSON(w, http.StatusOK, map[string]string{"mode": string(a.modes.Get())})
}

func (a *API) handleStoreVoiceSignature(w http.ResponseWriter, r *http.Request) {
	var req struct {
		UserID        string `json:"userId"`
		SignatureHash string `json:"signatureHash"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json"})
		return
	}
	if req.UserID == "" || req.SignatureHash == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "userId and signatureHash are required"})
		return
	}
	sig := a.auth.StoreVoiceSignature(req.UserID, req.SignatureHash)
	writeJSON(w, http.StatusCreated, sig)
}

func (a *API) handleCreateToken(w http.ResponseWriter, r *http.Request) {
	var req struct {
		UserID string `json:"userId"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json"})
		return
	}
	if req.UserID == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "userId is required"})
		return
	}
	token := a.auth.CreateActivationToken(req.UserID, 24*time.Hour)
	writeJSON(w, http.StatusCreated, map[string]string{"token": token})
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func jsonMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPost || r.Method == http.MethodPut || r.Method == http.MethodPatch {
			if r.Header.Get("Content-Type") == "" {
				r.Header.Set("Content-Type", "application/json")
			}
		}
		next.ServeHTTP(w, r)
	})
}
