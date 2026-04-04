package services

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

type AIProxyService struct {
	baseURL string
	client  *http.Client
}

func NewAIProxyService(aiBaseURL string, timeoutSec int) *AIProxyService {
	if timeoutSec <= 0 {
		timeoutSec = 5
	}
	return &AIProxyService{
		baseURL: strings.TrimRight(aiBaseURL, "/"),
		client:  &http.Client{Timeout: time.Duration(timeoutSec) * time.Second},
	}
}

func (s *AIProxyService) ProxyToAI(ctx context.Context, method, path string, body []byte) ([]byte, int, error) {
	req, err := http.NewRequestWithContext(ctx, method, s.baseURL+path, bytes.NewReader(body))
	if err != nil {
		return nil, http.StatusServiceUnavailable, err
	}
	if len(body) > 0 {
		req.Header.Set("Content-Type", "application/json")
	}

	resp, err := s.client.Do(req)
	if err != nil {
		return nil, http.StatusServiceUnavailable, err
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, http.StatusBadGateway, fmt.Errorf("failed to read upstream response: %w", err)
	}
	return respBody, resp.StatusCode, nil
}
