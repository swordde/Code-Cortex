package services

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
	"time"

	"cortex/backend/internal/models"
	"cortex/backend/internal/store"

	"github.com/google/uuid"
)

type CortexService struct {
	store      *store.MongoStore
	dispatcher *PushDispatcher
	replySender ReplySender
	aiBaseURL  string
	client     *http.Client
}

type cortexReplyResponse struct {
	Reply         string `json:"reply"`
	Action        string `json:"action"`
	ToneUsed      string `json:"tone_used"`
	ModeUsed      string `json:"mode_used"`
	CortexVersion string `json:"cortex_version"`
	LatencyMs     int    `json:"latency_ms"`
}

func NewCortexService(s *store.MongoStore, d *PushDispatcher, aiBaseURL string, timeoutSec int, replySender ReplySender) *CortexService {
	if timeoutSec <= 0 {
		timeoutSec = 5
	}
	if replySender == nil {
		replySender = &NoopReplySender{}
	}
	return &CortexService{
		store:      s,
		dispatcher: d,
		replySender: replySender,
		aiBaseURL:  strings.TrimRight(aiBaseURL, "/"),
		client:     &http.Client{Timeout: time.Duration(timeoutSec) * time.Second},
	}
}

func (c *CortexService) MaybeAutoReply(ctx context.Context, n *models.Notification, cfg *models.CortexConfig) error {
	if cfg == nil || !cfg.Enabled {
		return nil
	}

	allowed, policyReason := shouldGenerateCortexReply(n)
	if !allowed {
		log.Printf("cortex policy: skipping reply notification_id=%s priority=%s confidence=%.3f reason=%s", n.ID, n.Priority, n.Confidence, policyReason)
		return c.logActivity(ctx, n.ID, "suppressed", policyReason)
	}

	tone := toneFromMode(n.Mode)
	aiResp, err := c.callCortexReply(ctx, n, tone)
	if err != nil {
		log.Printf("cortex warning: reply call failed: %v", err)
		return nil
	}

	if normalizePriority(n.Priority) == string(models.PriorityLow) && aiResp.Action == "suppress" {
		aiResp.Action = "draft"
		if strings.TrimSpace(aiResp.Reply) == "" {
			aiResp.Reply = "Got it — I’ll handle this shortly."
		}
	}

	if shouldDirectSendLowPriority(n, c.replySender) && strings.TrimSpace(aiResp.Reply) != "" {
		return c.sendReplyOrFallbackDraft(ctx, n, aiResp.Reply)
	}

	switch aiResp.Action {
	case "suppress":
		return c.logActivity(ctx, n.ID, "suppressed", "")
	case "draft":
		if err := c.createScheduledMessage(ctx, n.ID, aiResp.Reply); err != nil {
			return err
		}
		return c.logActivity(ctx, n.ID, "drafted", aiResp.Reply)
	case "auto_send":
		if cfg.AutoReply {
			return c.sendReplyOrFallbackDraft(ctx, n, aiResp.Reply)
		}
		if err := c.createScheduledMessage(ctx, n.ID, aiResp.Reply); err != nil {
			return err
		}
		return c.logActivity(ctx, n.ID, "drafted", aiResp.Reply)
	default:
		if err := c.createScheduledMessage(ctx, n.ID, aiResp.Reply); err != nil {
			return err
		}
		return c.logActivity(ctx, n.ID, "drafted", aiResp.Reply)
	}
}

func (c *CortexService) GenerateAndSendReply(ctx context.Context, n *models.Notification) (string, string, error) {
	if n == nil {
		return "", "", fmt.Errorf("notification is required")
	}

	tone := toneFromMode(n.Mode)
	aiResp, err := c.callCortexReply(ctx, n, tone)
	if err != nil {
		return "", "", err
	}

	reply := strings.TrimSpace(aiResp.Reply)
	if reply == "" {
		return "", "", fmt.Errorf("empty reply generated")
	}

	if err := c.replySender.Send(ctx, n, reply); err != nil {
		log.Printf("cortex delivery warning: sender=%s notification_id=%s err=%v", c.replySender.Name(), n.ID, err)
		if draftErr := c.createScheduledMessage(ctx, n.ID, reply); draftErr != nil {
			return "", "", draftErr
		}
		if activityErr := c.logActivity(ctx, n.ID, "delivery_failed_drafted", reply); activityErr != nil {
			return "", "", activityErr
		}
		return reply, "drafted", nil
	}

	if err := c.logActivity(ctx, n.ID, "auto_replied", reply); err != nil {
		return "", "", err
	}
	entry := models.CortexActivityEntry{ID: uuid.NewString(), NotificationID: n.ID, Action: "auto_replied", Body: reply, Timestamp: time.Now().UTC()}
	c.dispatcher.DispatchCortexAction(&entry)
	return reply, "sent", nil
}

func shouldDirectSendLowPriority(n *models.Notification, sender ReplySender) bool {
	if sender == nil || sender.Name() == "noop" {
		return false
	}
	return normalizePriority(n.Priority) == string(models.PriorityLow)
}

func (c *CortexService) sendReplyOrFallbackDraft(ctx context.Context, n *models.Notification, reply string) error {
	if err := c.replySender.Send(ctx, n, reply); err != nil {
		log.Printf("cortex delivery warning: sender=%s notification_id=%s err=%v", c.replySender.Name(), n.ID, err)
		if draftErr := c.createScheduledMessage(ctx, n.ID, reply); draftErr != nil {
			return draftErr
		}
		return c.logActivity(ctx, n.ID, "delivery_failed_drafted", reply)
	}

	if err := c.logActivity(ctx, n.ID, "auto_replied", reply); err != nil {
		return err
	}
	entry := models.CortexActivityEntry{ID: uuid.NewString(), NotificationID: n.ID, Action: "auto_replied", Body: reply, Timestamp: time.Now().UTC()}
	c.dispatcher.DispatchCortexAction(&entry)
	return nil
}

func shouldGenerateCortexReply(n *models.Notification) (bool, string) {
	priority := normalizePriority(n.Priority)

	if priority == string(models.PriorityHigh) || priority == string(models.PriorityEmergency) {
		return false, "high_priority_no_reply"
	}

	if priority != string(models.PriorityLow) {
		return false, "only_low_priority_reply"
	}

	if n.Confidence < 0.30 {
		return false, fmt.Sprintf("low_confidence_%.3f", n.Confidence)
	}

	return true, "low_priority_reply"
}

func (c *CortexService) callCortexReply(ctx context.Context, n *models.Notification, tone string) (*cortexReplyResponse, error) {
	payload := map[string]any{
		"content":  n.Content,
		"app":      n.AppName,
		"mode":     toAIMode(n.Mode),
		"priority": toAIPriority(n.Priority),
		"tone":     tone,
		"user_id":  "snp_backend",
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.aiBaseURL+"/cortex/reply", bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("cortex ai returned status %d", resp.StatusCode)
	}

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var parsed cortexReplyResponse
	if err := json.Unmarshal(respBody, &parsed); err != nil {
		return nil, err
	}
	if parsed.Action == "" {
		parsed.Action = "draft"
	}
	return &parsed, nil
}

func (c *CortexService) createScheduledMessage(ctx context.Context, notificationID, reply string) error {
	msg := models.ScheduledMessage{
		ID:             uuid.NewString(),
		NotificationID: notificationID,
		DraftBody:      reply,
		ScheduledAt:    time.Now().UTC(),
		Status:         "pending",
	}
	return c.store.CreateScheduled(ctx, &msg)
}

func (c *CortexService) logActivity(ctx context.Context, notificationID, action, body string) error {
	entry := models.CortexActivityEntry{
		ID:             uuid.NewString(),
		NotificationID: notificationID,
		Action:         action,
		Body:           body,
		Timestamp:      time.Now().UTC(),
	}
	return c.store.AddCortexActivity(ctx, &entry)
}
