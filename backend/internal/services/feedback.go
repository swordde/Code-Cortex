package services

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"
)

type FeedbackService struct {
	baseURL string
	client  *http.Client
}

func NewFeedbackService(aiBaseURL string, timeoutSec int) *FeedbackService {
	if timeoutSec <= 0 {
		timeoutSec = 5
	}
	return &FeedbackService{
		baseURL: strings.TrimRight(aiBaseURL, "/"),
		client:  &http.Client{Timeout: time.Duration(timeoutSec) * time.Second},
	}
}

func (s *FeedbackService) SubmitFeedback(ctx context.Context, content, appName, mode, priority string) error {
	payload := map[string]any{
		"content": content,
		"app":     appName,
		"mode":    toAIMode(mode),
		"label":   toAIPriority(priority),
		"user_id": "snp_backend",
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, s.baseURL+"/feedback", bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := s.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("feedback returned status %d", resp.StatusCode)
	}
	return nil
}
