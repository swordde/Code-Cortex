package services

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"sync"
	"time"
)

type ModelStatusCache struct {
	Version               int       `json:"version"`
	Accuracy              float64   `json:"accuracy"`
	LastFinetuneTimestamp string    `json:"last_finetune_timestamp"`
	SampleCount           int       `json:"sample_count"`
	ModelLoaded           bool      `json:"model_loaded"`
	ClassificationReady   bool      `json:"classification_ready"`
	InferenceProbeOK      bool      `json:"inference_probe_ok"`
	InferenceProbeReason  string    `json:"inference_probe_reason,omitempty"`
	FetchedAt             time.Time `json:"fetched_at"`
}

type ModelStatusService struct {
	proxy *AIProxyService
	mu    sync.RWMutex
	data  ModelStatusCache
}

func NewModelStatusService(proxy *AIProxyService) *ModelStatusService {
	return &ModelStatusService{proxy: proxy}
}

func (s *ModelStatusService) Start(ctx context.Context) {
	if err := s.Refresh(ctx); err != nil {
		log.Printf("model status warning: startup fetch failed: %v", err)
		s.mu.Lock()
		s.data = ModelStatusCache{ModelLoaded: false, FetchedAt: time.Now().UTC()}
		s.mu.Unlock()
	}

	go func() {
		ticker := time.NewTicker(5 * time.Minute)
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				tickCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
				if err := s.Refresh(tickCtx); err != nil {
					log.Printf("model status warning: periodic fetch failed: %v", err)
				}
				cancel()
			}
		}
	}()
}

func (s *ModelStatusService) Refresh(ctx context.Context) error {
	body, status, err := s.proxy.ProxyToAI(ctx, http.MethodGet, "/model/status", nil)
	if err != nil {
		return err
	}
	if status < 200 || status >= 300 {
		return fmt.Errorf("model status upstream returned %d", status)
	}

	var parsed ModelStatusCache
	if err := json.Unmarshal(body, &parsed); err != nil {
		return err
	}

	probeOK, probeReason := s.runClassifyProbe(ctx)
	parsed.ClassificationReady = probeOK
	parsed.InferenceProbeOK = probeOK
	parsed.InferenceProbeReason = probeReason
	parsed.FetchedAt = time.Now().UTC()

	s.mu.Lock()
	s.data = parsed
	s.mu.Unlock()
	return nil
}

func (s *ModelStatusService) runClassifyProbe(ctx context.Context) (bool, string) {
	payload := map[string]any{
		"content": "health probe: critical outage in payment service",
		"app":     "healthcheck",
		"mode":    "office",
		"user_id": "healthcheck",
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return false, "probe_encode_error"
	}

	respBody, status, err := s.proxy.ProxyToAI(ctx, http.MethodPost, "/classify", body)
	if err != nil {
		return false, "probe_upstream_error"
	}
	if status < 200 || status >= 300 {
		return false, fmt.Sprintf("probe_status_%d", status)
	}

	var parsed struct {
		Priority   string  `json:"priority"`
		Confidence float64 `json:"confidence"`
		Reason     string  `json:"label_reason"`
	}
	if err := json.Unmarshal(respBody, &parsed); err != nil {
		return false, "probe_decode_error"
	}
	if strings.TrimSpace(parsed.Priority) == "" || strings.TrimSpace(parsed.Reason) == "" {
		return false, "probe_invalid_payload"
	}

	return true, "ok"
}

func (s *ModelStatusService) GetModelStatus() *ModelStatusCache {
	s.mu.RLock()
	defer s.mu.RUnlock()
	copy := s.data
	return &copy
}
