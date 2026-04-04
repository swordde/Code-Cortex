package services

import (
	"context"
	"time"

	"cortex/backend/internal/models"
	"cortex/backend/internal/store"

	"github.com/google/uuid"
)

type ModeManager struct {
	store      *store.MongoStore
	dispatcher *PushDispatcher
}

func NewModeManager(s *store.MongoStore, d *PushDispatcher) *ModeManager {
	return &ModeManager{store: s, dispatcher: d}
}

func (m *ModeManager) Init(ctx context.Context) error {
	active, err := m.store.GetActiveMode(ctx)
	if err != nil {
		return err
	}
	if active == nil {
		_ = m.store.ActivateMode(ctx, "mode-default")
	}
	go m.scheduleLoop()
	return nil
}

func (m *ModeManager) GetActive(ctx context.Context) (*models.Mode, error) {
	mode, err := m.store.GetActiveMode(ctx)
	if err != nil {
		return nil, err
	}
	if mode == nil {
		return &models.Mode{ID: "mode-default", Name: models.ModeDefault, IsActive: true, IsPreset: true}, nil
	}
	return mode, nil
}

func (m *ModeManager) SetActive(ctx context.Context, id string) error {
	before, _ := m.store.GetActiveMode(ctx)
	if err := m.store.ActivateMode(ctx, id); err != nil {
		return err
	}
	after, err := m.store.GetActiveMode(ctx)
	if err != nil {
		return err
	}
	if after != nil {
		m.dispatcher.DispatchModeChanged(after.Name)
		now := time.Now().UTC()
		if before != nil {
			_ = m.store.LogModeSession(ctx, models.ModeSession{
				ID:        uuid.NewString(),
				ModeName:  before.Name,
				StartedAt: now.Add(-time.Minute),
				EndedAt:   now,
			})
		}
	}
	return nil
}

func (m *ModeManager) scheduleLoop() {
	ticker := time.NewTicker(1 * time.Minute)
	defer ticker.Stop()
	for range ticker.C {
		ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
		modes, err := m.store.ListModes(ctx)
		if err == nil {
			now := time.Now()
			wday := int(now.Weekday())
			for _, md := range modes {
				if md.ScheduleStart == "" || md.ScheduleEnd == "" || len(md.ScheduleDays) == 0 {
					continue
				}
				if !containsDay(md.ScheduleDays, wday) {
					continue
				}
				if withinTimeWindow(md.ScheduleStart, md.ScheduleEnd, now) {
					_ = m.SetActive(ctx, md.ID)
					break
				}
			}
		}
		cancel()
	}
}

func containsDay(days []int, d int) bool {
	for _, day := range days {
		if day == d {
			return true
		}
	}
	return false
}
