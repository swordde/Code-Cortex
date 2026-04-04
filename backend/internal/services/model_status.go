package services

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"
)

type ModelStatusCache struct {
	Version               int       `json:"version"`
	Accuracy              float64   `json:"accuracy"`
	LastFinetuneTimestamp string    `json:"last_finetune_timestamp"`
	SampleCount           int       `json:"sample_count"`
	ModelLoaded           bool      `json:"model_loaded"`
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
	parsed.FetchedAt = time.Now().UTC()

	s.mu.Lock()
	s.data = parsed
	s.mu.Unlock()
	return nil
}

func (s *ModelStatusService) GetModelStatus() *ModelStatusCache {
	s.mu.RLock()
	defer s.mu.RUnlock()
	copy := s.data
	return &copy
}
