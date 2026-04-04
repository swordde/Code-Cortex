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
	"sync"
	"time"
)

type classifierCache struct {
	priority    string
	confidence  float64
	labelReason string
	expiresAt   time.Time
}

type ClassifierService struct {
	baseURL string
	client  *http.Client
	cache   sync.Map
}

func NewClassifierService(aiBaseURL string, timeoutSec int) *ClassifierService {
	if timeoutSec <= 0 {
		timeoutSec = 5
	}
	return &ClassifierService{
		baseURL: strings.TrimRight(aiBaseURL, "/"),
		client:  &http.Client{Timeout: time.Duration(timeoutSec) * time.Second},
	}
}

func (s *ClassifierService) Classify(ctx context.Context, appName string, content string, mode string) (priority string, confidence float64, labelReason string, err error) {
	cacheKey := s.cacheKey(appName, content, mode)
	if p, c, r, ok := s.readCache(cacheKey); ok {
		return p, c, r, nil
	}

	payload := map[string]any{
		"content": content,
		"app":     appName,
		"mode":    toAIMode(mode),
		"user_id": "snp_backend",
	}
	body, marshalErr := json.Marshal(payload)
	if marshalErr != nil {
		return "MEDIUM", 0.0, "fallback:encode", nil
	}
	url := s.baseURL + "/classify"

	callOnce := func() (string, float64, string, int, error) {
		req, reqErr := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
		if reqErr != nil {
			return "MEDIUM", 0.0, "fallback:error", 0, reqErr
		}
		req.Header.Set("Content-Type", "application/json")
		resp, httpErr := s.client.Do(req)
		if httpErr != nil {
			log.Printf("classifier warning: AI call failed: %v", httpErr)
			return "MEDIUM", 0.0, "fallback:timeout", 0, nil
		}
		defer resp.Body.Close()

		if resp.StatusCode >= 500 {
			return "", 0, "", resp.StatusCode, nil
		}
		if resp.StatusCode == http.StatusUnprocessableEntity {
			return "MEDIUM", 0.0, "fallback:validation_error", resp.StatusCode, nil
		}
		if resp.StatusCode < 200 || resp.StatusCode > 299 {
			return "MEDIUM", 0.0, "fallback:non_2xx", resp.StatusCode, nil
		}

		respBody, readErr := io.ReadAll(resp.Body)
		if readErr != nil {
			return "MEDIUM", 0.0, "fallback:decode", 0, nil
		}

		var parsed struct {
			Priority   string  `json:"priority"`
			Confidence float64 `json:"confidence"`
			Reason     string  `json:"label_reason"`
		}
		if decodeErr := json.Unmarshal(respBody, &parsed); decodeErr != nil {
			return "MEDIUM", 0.0, "fallback:decode", 0, nil
		}

		priorityValue := normalizePriority(parsed.Priority)
		switch priorityValue {
		case "EMERGENCY", "HIGH", "MEDIUM", "LOW":
		default:
			priorityValue = "MEDIUM"
		}
		reason := parsed.Reason
		if reason == "" {
			reason = "ai"
		}
		return priorityValue, parsed.Confidence, reason, resp.StatusCode, nil
	}

	p, c, r, status, callErr := callOnce()
	if callErr != nil {
		return "MEDIUM", 0.0, "fallback:error", nil
	}
	if status >= 500 {
		time.Sleep(200 * time.Millisecond)
		p2, c2, r2, _, retryErr := callOnce()
		if retryErr != nil {
			return "MEDIUM", 0.0, "fallback:server_error", nil
		}
		if p2 == "" {
			p, c, r = "MEDIUM", 0.0, "fallback:server_error"
		} else {
			p, c, r = p2, c2, r2
		}
	}

	if p == "" {
		p = "MEDIUM"
	}
	s.writeCache(cacheKey, p, c, r)
	return p, c, r, nil
}

func (s *ClassifierService) cacheKey(appName, content, mode string) string {
	trimmedContent := content
	if len(trimmedContent) > 50 {
		trimmedContent = trimmedContent[:50]
	}
	return fmt.Sprintf("%s|%s|%s", appName, trimmedContent, mode)
}

func (s *ClassifierService) readCache(key string) (string, float64, string, bool) {
	v, ok := s.cache.Load(key)
	if !ok {
		return "", 0, "", false
	}
	item := v.(classifierCache)
	if time.Now().After(item.expiresAt) {
		s.cache.Delete(key)
		return "", 0, "", false
	}
	return item.priority, item.confidence, item.labelReason, true
}

func (s *ClassifierService) writeCache(key, p string, c float64, r string) {
	s.cache.Store(key, classifierCache{priority: p, confidence: c, labelReason: r, expiresAt: time.Now().Add(60 * time.Second)})
}
