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
	requestID := EnsureRequestID(RequestIDFromContext(ctx))
	cacheKey := s.cacheKey(appName, content, mode)
	if p, c, r, ok := s.readCache(cacheKey); ok {
		s.logEvent("cache_hit", map[string]any{
			"request_id": requestID,
			"app":        appName,
			"mode":       mode,
			"reason":     r,
		})
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
		s.logEvent("marshal_error", map[string]any{
			"request_id": requestID,
			"app":        appName,
			"mode":       mode,
			"error":      marshalErr.Error(),
		})
		return "MEDIUM", 0.0, "fallback:encode", nil
	}
	url := s.baseURL + "/classify"

	callOnce := func(attempt int) (string, float64, string, int, bool, error) {
		start := time.Now()
		req, reqErr := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
		if reqErr != nil {
			return "MEDIUM", 0.0, "fallback:error", 0, false, reqErr
		}
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("X-Request-ID", requestID)
		resp, httpErr := s.client.Do(req)
		if httpErr != nil {
			s.logEvent("upstream_error", map[string]any{
				"request_id":  requestID,
				"attempt":     attempt,
				"duration_ms": time.Since(start).Milliseconds(),
				"app":         appName,
				"mode":        mode,
				"error":       httpErr.Error(),
			})
			return "", 0.0, "", 0, true, nil
		}
		defer resp.Body.Close()

		if resp.StatusCode >= 500 {
			s.logEvent("upstream_5xx", map[string]any{
				"request_id":  requestID,
				"attempt":     attempt,
				"duration_ms": time.Since(start).Milliseconds(),
				"app":         appName,
				"mode":        mode,
				"status":      resp.StatusCode,
			})
			return "", 0, "", resp.StatusCode, true, nil
		}
		if resp.StatusCode == http.StatusUnprocessableEntity {
			s.logEvent("upstream_422", map[string]any{
				"request_id":  requestID,
				"attempt":     attempt,
				"duration_ms": time.Since(start).Milliseconds(),
				"app":         appName,
				"mode":        mode,
				"status":      resp.StatusCode,
			})
			return "MEDIUM", 0.0, "fallback:validation_error", resp.StatusCode, false, nil
		}
		if resp.StatusCode < 200 || resp.StatusCode > 299 {
			s.logEvent("upstream_non_2xx", map[string]any{
				"request_id":  requestID,
				"attempt":     attempt,
				"duration_ms": time.Since(start).Milliseconds(),
				"app":         appName,
				"mode":        mode,
				"status":      resp.StatusCode,
			})
			return "MEDIUM", 0.0, "fallback:non_2xx", resp.StatusCode, false, nil
		}

		respBody, readErr := io.ReadAll(resp.Body)
		if readErr != nil {
			s.logEvent("read_error", map[string]any{
				"request_id":  requestID,
				"attempt":     attempt,
				"duration_ms": time.Since(start).Milliseconds(),
				"app":         appName,
				"mode":        mode,
				"error":       readErr.Error(),
			})
			return "MEDIUM", 0.0, "fallback:decode", 0, false, nil
		}

		var parsed struct {
			Priority   string  `json:"priority"`
			Confidence float64 `json:"confidence"`
			Reason     string  `json:"label_reason"`
		}
		if decodeErr := json.Unmarshal(respBody, &parsed); decodeErr != nil {
			s.logEvent("decode_error", map[string]any{
				"request_id":  requestID,
				"attempt":     attempt,
				"duration_ms": time.Since(start).Milliseconds(),
				"app":         appName,
				"mode":        mode,
				"error":       decodeErr.Error(),
			})
			return "MEDIUM", 0.0, "fallback:decode", 0, false, nil
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
		s.logEvent("success", map[string]any{
			"request_id":  requestID,
			"attempt":     attempt,
			"duration_ms": time.Since(start).Milliseconds(),
			"app":         appName,
			"mode":        mode,
			"status":      resp.StatusCode,
			"priority":    priorityValue,
			"reason":      reason,
		})
		return priorityValue, parsed.Confidence, reason, resp.StatusCode, false, nil
	}

	p, c, r, status, retryable, callErr := callOnce(1)
	if callErr != nil {
		s.logEvent("request_build_error", map[string]any{
			"request_id": requestID,
			"app":        appName,
			"mode":       mode,
			"error":      callErr.Error(),
		})
		return "MEDIUM", 0.0, "fallback:error", nil
	}
	if retryable || status >= 500 {
		time.Sleep(200 * time.Millisecond)
		p2, c2, r2, _, _, retryErr := callOnce(2)
		if retryErr != nil {
			s.logEvent("retry_error", map[string]any{
				"request_id": requestID,
				"app":        appName,
				"mode":       mode,
				"error":      retryErr.Error(),
			})
			return "MEDIUM", 0.0, "fallback:server_error", nil
		}
		if p2 == "" {
			p, c, r = "MEDIUM", 0.0, "fallback:server_error"
			s.logEvent("fallback_after_retry", map[string]any{
				"request_id": requestID,
				"app":        appName,
				"mode":       mode,
				"reason":     r,
			})
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

func (s *ClassifierService) logEvent(event string, fields map[string]any) {
	fields["event"] = event
	fields["component"] = "classifier"
	data, err := json.Marshal(fields)
	if err != nil {
		log.Printf("classifier event=%s marshal_error=%v", event, err)
		return
	}
	log.Printf("%s", data)
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
