package rules

import (
	"strings"
	"sync"

	"cortex/backend/internal/models"
)

type Engine struct {
	mu    sync.RWMutex
	rules []models.Rule
}

func NewEngine() *Engine {
	return &Engine{rules: make([]models.Rule, 0)}
}

func (e *Engine) List() []models.Rule {
	e.mu.RLock()
	defer e.mu.RUnlock()

	cp := make([]models.Rule, len(e.rules))
	copy(cp, e.rules)
	return cp
}

func (e *Engine) Add(rule models.Rule) {
	e.mu.Lock()
	defer e.mu.Unlock()
	e.rules = append(e.rules, rule)
}

func (e *Engine) Apply(n models.Notification, aiLabel models.Priority) (models.Priority, string) {
	e.mu.RLock()
	defer e.mu.RUnlock()

	sender := strings.ToLower(n.Sender)
	content := strings.ToLower(n.Content + " " + n.Title)

	for _, rule := range e.rules {
		if !rule.Enabled {
			continue
		}

		if rule.Contact != "" && strings.Contains(sender, strings.ToLower(rule.Contact)) {
			return rule.Priority, "contact-match"
		}

		for _, kw := range rule.Keywords {
			if kw != "" && strings.Contains(content, strings.ToLower(kw)) {
				return rule.Priority, "keyword-match"
			}
		}
	}

	return aiLabel, ""
}
