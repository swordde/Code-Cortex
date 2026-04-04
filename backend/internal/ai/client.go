package ai

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"

	"cortex/backend/internal/models"
)

type Client struct {
	endpoint   string
	httpClient *http.Client
}

func NewClient(endpoint string) *Client {
	return &Client{
		endpoint: endpoint,
		httpClient: &http.Client{
			Timeout: 3 * time.Second,
		},
	}
}

func (c *Client) Classify(ctx context.Context, n models.Notification, mode models.ContextMode) (models.Priority, error) {
	if c.endpoint == "" {
		return heuristicFallback(n, mode), nil
	}

	payload := map[string]any{
		"sender":  n.Sender,
		"title":   n.Title,
		"content": n.Content,
		"app":     n.App,
		"mode":    mode,
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return models.PriorityNormal, err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.endpoint, bytes.NewReader(body))
	if err != nil {
		return models.PriorityNormal, err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return models.PriorityNormal, err
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return models.PriorityNormal, errors.New("ai endpoint returned non-2xx")
	}

	var parsed struct {
		Label string `json:"label"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&parsed); err != nil {
		return models.PriorityNormal, err
	}

	label := models.Priority(strings.ToLower(parsed.Label))
	switch label {
	case models.PriorityEmergency, models.PriorityHigh, models.PriorityNormal, models.PriorityLow:
		return label, nil
	default:
		return models.PriorityNormal, nil
	}
}

func heuristicFallback(n models.Notification, mode models.ContextMode) models.Priority {
	text := strings.ToLower(n.Title + " " + n.Content + " " + n.Sender)
	switch {
	case strings.Contains(text, "urgent") || strings.Contains(text, "emergency") || strings.Contains(text, "asap"):
		return models.PriorityEmergency
	case strings.Contains(text, "meeting") || strings.Contains(text, "deadline") || strings.Contains(text, "important"):
		return models.PriorityHigh
	case strings.Contains(text, "promo") || strings.Contains(text, "sale") || strings.Contains(text, "offer"):
		return models.PriorityLow
	}

	if mode == models.ModeSleep || mode == models.ModeDeepWork {
		return models.PriorityLow
	}
	return models.PriorityNormal
}
