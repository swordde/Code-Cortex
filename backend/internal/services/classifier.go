package services

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"strings"
	"sync"
	"time"

	"cortex/backend/internal/models"
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
	mu      sync.Mutex
	cache   map[string]classifierCache
}

func NewClassifierService(aiBaseURL string) *ClassifierService {
	return &ClassifierService{
		baseURL: strings.TrimRight(aiBaseURL, "/"),
		client:  &http.Client{Timeout: 3 * time.Second},
		cache:   map[string]classifierCache{},
	}
}

func (s *ClassifierService) Classify(ctx context.Context, n *models.Notification, mode string) (priority string, confidence float64, labelReason string, err error) {
	cacheKey := s.hashKey(n.Content + "|" + n.AppPackage + "|" + mode)
	if p, c, r, ok := s.readCache(cacheKey); ok {
		return p, c, r, nil
	}

	payload := map[string]any{
		"content":     n.Content,
		"app_package": n.AppPackage,
		"sender_name": n.SenderName,
		"mode":        mode,
	}
	body, _ := json.Marshal(payload)
	url := s.baseURL + "/classify"

	callOnce := func() (string, float64, string, int, error) {
		req, reqErr := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
		if reqErr != nil {
			return string(models.PriorityMedium), 0, "fallback:error", 0, reqErr
		}
		req.Header.Set("Content-Type", "application/json")
		resp, httpErr := s.client.Do(req)
		if httpErr != nil {
			if ctx.Err() != nil {
				return string(models.PriorityMedium), 0, "fallback:timeout", 0, nil
			}
			return string(models.PriorityMedium), 0, "fallback:error", 0, httpErr
		}
		defer resp.Body.Close()

		if resp.StatusCode >= 500 {
			return "", 0, "", resp.StatusCode, nil
		}
		if resp.StatusCode < 200 || resp.StatusCode > 299 {
			return string(models.PriorityMedium), 0, "fallback:non_2xx", resp.StatusCode, nil
		}

		var parsed struct {
			Priority   string  `json:"priority"`
			Confidence float64 `json:"confidence"`
			Reason     string  `json:"label_reason"`
		}
		if decodeErr := json.NewDecoder(resp.Body).Decode(&parsed); decodeErr != nil {
			return string(models.PriorityMedium), 0, "fallback:decode", 0, nil
		}
		priorityValue := strings.ToUpper(strings.TrimSpace(parsed.Priority))
		switch priorityValue {
		case string(models.PriorityEmergency), string(models.PriorityHigh), string(models.PriorityMedium), string(models.PriorityLow):
		default:
			priorityValue = string(models.PriorityMedium)
		}
		reason := parsed.Reason
		if reason == "" {
			reason = "ai"
		}
		return priorityValue, parsed.Confidence, reason, resp.StatusCode, nil
	}

	p, c, r, status, callErr := callOnce()
	if callErr != nil {
		return string(models.PriorityMedium), 0, "fallback:error", nil
	}
	if status >= 500 {
		time.Sleep(200 * time.Millisecond)
		p2, c2, r2, _, retryErr := callOnce()
		if retryErr != nil {
			return string(models.PriorityMedium), 0, "fallback:error", nil
		}
		p, c, r = p2, c2, r2
	}

	s.writeCache(cacheKey, p, c, r)
	return p, c, r, nil
}

func (s *ClassifierService) hashKey(v string) string {
	h := sha256.Sum256([]byte(v))
	return hex.EncodeToString(h[:])
}

func (s *ClassifierService) readCache(key string) (string, float64, string, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	item, ok := s.cache[key]
	if !ok || time.Now().After(item.expiresAt) {
		if ok {
			delete(s.cache, key)
		}
		return "", 0, "", false
	}
	return item.priority, item.confidence, item.labelReason, true
}

func (s *ClassifierService) writeCache(key, p string, c float64, r string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.cache[key] = classifierCache{priority: p, confidence: c, labelReason: r, expiresAt: time.Now().Add(60 * time.Second)}
}
