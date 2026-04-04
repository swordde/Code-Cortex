package modes

import (
	"sync"

	"cortex/backend/internal/models"
)

type Manager struct {
	mu   sync.RWMutex
	mode models.ContextMode
}

func NewManager() *Manager {
	return &Manager{mode: models.ModeDefault}
}

func (m *Manager) Set(mode models.ContextMode) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.mode = mode
}

func (m *Manager) Get() models.ContextMode {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.mode
}

func (m *Manager) Adjust(label models.Priority) models.Priority {
	mode := m.Get()
	switch mode {
	case models.ModeSleep:
		if label == models.PriorityNormal {
			return models.PriorityLow
		}
		if label == models.PriorityHigh {
			return models.PriorityNormal
		}
	case models.ModeDriving, models.ModeDeepWork:
		if label == models.PriorityLow {
			return models.PriorityNormal
		}
	}
	return label
}
