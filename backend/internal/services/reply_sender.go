package services

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"cortex/backend/internal/models"
)

type ReplySender interface {
	Name() string
	Send(ctx context.Context, n *models.Notification, reply string) error
}

type NoopReplySender struct{}

func (s *NoopReplySender) Name() string {
	return "noop"
}

func (s *NoopReplySender) Send(ctx context.Context, n *models.Notification, reply string) error {
	return fmt.Errorf("reply sender not configured")
}

type WebhookReplySender struct {
	url    string
	client *http.Client
}

type PlatformReplySender struct {
	defaultSender ReplySender
	platformSenders map[string]ReplySender
}

func NewWebhookReplySender(url string, timeoutSec int) *WebhookReplySender {
	if timeoutSec <= 0 {
		timeoutSec = 5
	}
	return &WebhookReplySender{
		url:    strings.TrimSpace(url),
		client: &http.Client{Timeout: time.Duration(timeoutSec) * time.Second},
	}
}

func (s *WebhookReplySender) Name() string {
	return "webhook"
}

func NewPlatformReplySender(defaultURL string, platformURLs map[string]string, timeoutSec int) ReplySender {
	trimmedDefault := strings.TrimSpace(defaultURL)
	defaultSender := ReplySender(&NoopReplySender{})
	if trimmedDefault != "" {
		defaultSender = NewWebhookReplySender(trimmedDefault, timeoutSec)
	}

	routers := map[string]ReplySender{}
	for platform, endpoint := range platformURLs {
		if strings.TrimSpace(endpoint) == "" {
			continue
		}
		routers[strings.ToLower(strings.TrimSpace(platform))] = NewWebhookReplySender(endpoint, timeoutSec)
	}

	if len(routers) == 0 && trimmedDefault == "" {
		return &NoopReplySender{}
	}

	return &PlatformReplySender{
		defaultSender: defaultSender,
		platformSenders: routers,
	}
}

func (s *PlatformReplySender) Name() string {
	return "platform-webhook"
}

func (s *PlatformReplySender) Send(ctx context.Context, n *models.Notification, reply string) error {
	platform := inferPlatform(n)
	if sender, ok := s.platformSenders[platform]; ok {
		return sender.Send(ctx, n, reply)
	}
	return s.defaultSender.Send(ctx, n, reply)
}

func inferPlatform(n *models.Notification) string {
	combined := strings.ToLower(strings.TrimSpace(n.AppPackage + " " + n.AppName))

	switch {
	case strings.Contains(combined, "slack"):
		return "slack"
	case strings.Contains(combined, "whatsapp") || strings.Contains(combined, "wa"):
		return "whatsapp"
	case strings.Contains(combined, "teams") || strings.Contains(combined, "msteams"):
		return "teams"
	case strings.Contains(combined, "discord"):
		return "discord"
	default:
		return "default"
	}
}

func (s *WebhookReplySender) Send(ctx context.Context, n *models.Notification, reply string) error {
	if strings.TrimSpace(s.url) == "" {
		return fmt.Errorf("reply webhook url is empty")
	}

	payload := map[string]any{
		"notification_id": n.ID,
		"user_id":         n.UserID,
		"app_name":        n.AppName,
		"app_package":     n.AppPackage,
		"priority":        n.Priority,
		"mode":            n.Mode,
		"confidence":      n.Confidence,
		"reply":           reply,
		"timestamp":       time.Now().UTC().Format(time.RFC3339Nano),
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, s.url, bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	if requestID := RequestIDFromContext(ctx); requestID != "" {
		req.Header.Set("X-Request-ID", requestID)
	}

	resp, err := s.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("reply webhook returned status %d", resp.StatusCode)
	}

	return nil
}
