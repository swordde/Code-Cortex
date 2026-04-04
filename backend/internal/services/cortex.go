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

func NewCortexService(s *store.MongoStore, d *PushDispatcher, aiBaseURL string, timeoutSec int) *CortexService {
	if timeoutSec <= 0 {
		timeoutSec = 5
	}
	return &CortexService{
		store:      s,
		dispatcher: d,
		aiBaseURL:  strings.TrimRight(aiBaseURL, "/"),
		client:     &http.Client{Timeout: time.Duration(timeoutSec) * time.Second},
	}
}

func (c *CortexService) MaybeAutoReply(ctx context.Context, n *models.Notification, cfg *models.CortexConfig) error {
	if cfg == nil || !cfg.Enabled {
		return nil
	}

	tone := toneFromMode(n.Mode)
	aiResp, err := c.callCortexReply(ctx, n, tone)
	if err != nil {
		log.Printf("cortex warning: reply call failed: %v", err)
		return nil
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
			if err := c.logActivity(ctx, n.ID, "auto_replied", aiResp.Reply); err != nil {
				return err
			}
			entry := models.CortexActivityEntry{ID: uuid.NewString(), NotificationID: n.ID, Action: "auto_replied", Body: aiResp.Reply, Timestamp: time.Now().UTC()}
			c.dispatcher.DispatchCortexAction(&entry)
			return nil
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
