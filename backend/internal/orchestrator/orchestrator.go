package orchestrator

import (
	"context"
	"fmt"
	"sync"
	"time"

	"cortex/backend/internal/ai"
	"cortex/backend/internal/models"
	"cortex/backend/internal/modes"
	"cortex/backend/internal/rules"
)

type cachedItem struct {
	label     models.Priority
	expiresAt time.Time
}

type Orchestrator struct {
	aiClient *ai.Client
	rules    *rules.Engine
	modes    *modes.Manager
	retries  int

	mu    sync.Mutex
	cache map[string]cachedItem
}

func New(aiClient *ai.Client, rulesEngine *rules.Engine, modeManager *modes.Manager, retries int) *Orchestrator {
	if retries < 1 {
		retries = 1
	}
	return &Orchestrator{
		aiClient: aiClient,
		rules:    rulesEngine,
		modes:    modeManager,
		retries:  retries,
		cache:    make(map[string]cachedItem),
	}
}

func (o *Orchestrator) Process(ctx context.Context, n models.Notification) (models.ClassificationResult, error) {
	mode := o.modes.Get()
	cacheKey := fmt.Sprintf("%s|%s|%s|%s", n.App, n.Sender, n.Title, n.Content)

	aiLabel, ok := o.getCached(cacheKey)
	if !ok {
		var err error
		for i := 0; i < o.retries; i++ {
			aiLabel, err = o.aiClient.Classify(ctx, n, mode)
			if err == nil {
				o.setCached(cacheKey, aiLabel, 10*time.Minute)
				break
			}
			time.Sleep(time.Duration(i+1) * 120 * time.Millisecond)
		}
		if err != nil {
			aiLabel = models.PriorityNormal
		}
	}

	finalLabel, reason := o.rules.Apply(n, aiLabel)
	finalLabel = o.modes.Adjust(finalLabel)

	result := models.ClassificationResult{
		NotificationID: n.ID,
		AILabel:        aiLabel,
		FinalLabel:     finalLabel,
		Mode:           string(mode),
		Reason:         reason,
		ProcessedAt:    time.Now().UTC().Format(time.RFC3339),
	}

	if reason != "" {
		result.OverriddenBy = "rule-engine"
	}

	return result, nil
}

func (o *Orchestrator) getCached(key string) (models.Priority, bool) {
	o.mu.Lock()
	defer o.mu.Unlock()

	item, ok := o.cache[key]
	if !ok {
		return "", false
	}
	if time.Now().After(item.expiresAt) {
		delete(o.cache, key)
		return "", false
	}
	return item.label, true
}

func (o *Orchestrator) setCached(key string, label models.Priority, ttl time.Duration) {
	o.mu.Lock()
	defer o.mu.Unlock()
	o.cache[key] = cachedItem{label: label, expiresAt: time.Now().Add(ttl)}
}
