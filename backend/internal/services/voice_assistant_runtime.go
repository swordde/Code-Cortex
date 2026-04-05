package services

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync/atomic"
	"time"
)

type VoiceAssistantRuntimeService struct {
	proxy *AIProxyService
	ready atomic.Bool
}

func NewVoiceAssistantRuntimeService(proxy *AIProxyService) *VoiceAssistantRuntimeService {
	return &VoiceAssistantRuntimeService{proxy: proxy}
}

func (s *VoiceAssistantRuntimeService) Start(ctx context.Context) {
	startupCtx, cancel := context.WithTimeout(ctx, 20*time.Second)
	defer cancel()

	if err := s.startAndVerify(startupCtx); err != nil {
		log.Printf("voice assistant warning: startup init failed: %v", err)
	} else {
		log.Printf("voice assistant runtime ready")
	}

	go func() {
		ticker := time.NewTicker(2 * time.Minute)
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				checkCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
				if err := s.verifyStatus(checkCtx); err != nil {
					s.ready.Store(false)
					log.Printf("voice assistant warning: status check failed: %v", err)
				}
				cancel()
			}
		}
	}()
}

func (s *VoiceAssistantRuntimeService) IsReady() bool {
	return s.ready.Load()
}

func (s *VoiceAssistantRuntimeService) startAndVerify(ctx context.Context) error {
	body, status, err := s.proxy.ProxyToAI(ctx, http.MethodPost, "/voice-assistant/start", nil)
	if err != nil {
		return err
	}
	if status < 200 || status >= 300 {
		return fmt.Errorf("start returned status %d: %s", status, string(body))
	}
	return s.verifyStatus(ctx)
}

func (s *VoiceAssistantRuntimeService) verifyStatus(ctx context.Context) error {
	body, status, err := s.proxy.ProxyToAI(ctx, http.MethodGet, "/voice-assistant/status", nil)
	if err != nil {
		return err
	}
	if status < 200 || status >= 300 {
		return fmt.Errorf("status returned %d: %s", status, string(body))
	}

	var payload struct {
		Running bool `json:"running"`
	}
	if err := json.Unmarshal(body, &payload); err != nil {
		return fmt.Errorf("invalid status payload: %w", err)
	}
	if !payload.Running {
		return fmt.Errorf("voice assistant status running=false")
	}

	s.ready.Store(true)
	return nil
}
