package services

import (
	"bytes"
	"context"
	"encoding/json"
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

func NewCortexService(s *store.MongoStore, d *PushDispatcher, aiBaseURL string) *CortexService {
	return &CortexService{store: s, dispatcher: d, aiBaseURL: strings.TrimRight(aiBaseURL, "/"), client: &http.Client{Timeout: 3 * time.Second}}
}

func (c *CortexService) MaybeAutoReply(ctx context.Context, n *models.Notification, cfg *models.CortexConfig) error {
	if cfg == nil || !cfg.Enabled {
		return nil
	}
	if n.Priority == string(models.PriorityEmergency) || n.Priority == string(models.PriorityHigh) {
		msg := models.ScheduledMessage{ID: uuid.NewString(), NotificationID: n.ID, DraftBody: "", ScheduledAt: time.Now().UTC().Add(2 * time.Minute), Status: "pending"}
		return c.store.CreateScheduled(ctx, &msg)
	}
	draft := ""
	if n.Priority == string(models.PriorityMedium) || (n.Priority == string(models.PriorityLow) && cfg.AutoReply) {
		draft = c.generateReply(ctx, n)
		status := "pending"
		action := "drafted"
		if n.Priority == string(models.PriorityLow) && cfg.AutoReply {
			status = "sent"
			action = "auto_replied"
		}
		scheduled := models.ScheduledMessage{ID: uuid.NewString(), NotificationID: n.ID, DraftBody: draft, ScheduledAt: time.Now().UTC(), Status: status}
		if err := c.store.CreateScheduled(ctx, &scheduled); err != nil {
			return err
		}
		entry := models.CortexActivityEntry{ID: uuid.NewString(), NotificationID: n.ID, Action: action, Body: draft, Timestamp: time.Now().UTC()}
		if err := c.store.AddCortexActivity(ctx, &entry); err != nil {
			return err
		}
		c.dispatcher.DispatchCortexAction(&entry)
	}
	return nil
}

func (c *CortexService) generateReply(ctx context.Context, n *models.Notification) string {
	payload := map[string]string{"content": n.Content, "sender_name": n.SenderName}
	body, _ := json.Marshal(payload)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.aiBaseURL+"/generate", bytes.NewReader(body))
	if err != nil {
		return ""
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := c.client.Do(req)
	if err != nil {
		return ""
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return ""
	}
	var parsed struct {
		Reply string `json:"reply"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&parsed); err != nil {
		return ""
	}
	return parsed.Reply
}
