package services

import (
	"context"
	"sort"
	"time"

	"cortex/backend/internal/models"
	"cortex/backend/internal/store"
)

type AnalyticsService struct {
	store *store.MongoStore
}

func NewAnalyticsService(s *store.MongoStore) *AnalyticsService { return &AnalyticsService{store: s} }

func (s *AnalyticsService) GetAnalytics(ctx context.Context, rangeStr string) (*models.AnalyticsResponse, error) {
	bucketCount := 7
	duration := 7 * 24 * time.Hour
	switch rangeStr {
	case "day":
		bucketCount = 24
		duration = 24 * time.Hour
	case "month":
		bucketCount = 30
		duration = 30 * 24 * time.Hour
	case "week":
	default:
		rangeStr = "week"
	}

	since := time.Now().UTC().Add(-duration)
	notifs, err := s.store.ListNotificationsSince(ctx, since)
	if err != nil {
		return nil, err
	}
	activities, err := s.store.ListCortexActivitySince(ctx, since)
	if err != nil {
		return nil, err
	}
	sessions, err := s.store.ListModeSessionsSince(ctx, since)
	if err != nil {
		return nil, err
	}
	finetunes, err := s.store.ListFinetuneEvents(ctx, 20)
	if err != nil {
		return nil, err
	}

	byPriority := map[string]int{string(models.PriorityEmergency): 0, string(models.PriorityHigh): 0, string(models.PriorityMedium): 0, string(models.PriorityLow): 0}
	daily := make([]models.DailyCount, bucketCount)
	topSrc := map[string]*models.TopSource{}
	for i := 0; i < bucketCount; i++ {
		if rangeStr == "day" {
			t := time.Now().UTC().Add(-time.Duration(bucketCount-1-i) * time.Hour)
			daily[i] = models.DailyCount{Date: t.Format("2006-01-02T15:00"), Emergency: 0, High: 0, Medium: 0, Low: 0}
		} else {
			t := time.Now().UTC().AddDate(0, 0, -(bucketCount - 1 - i))
			daily[i] = models.DailyCount{Date: t.Format("2006-01-02"), Emergency: 0, High: 0, Medium: 0, Low: 0}
		}
	}

	for _, n := range notifs {
		byPriority[n.Priority]++
		idx := bucketIndex(n.Timestamp, rangeStr, bucketCount)
		if idx >= 0 && idx < len(daily) {
			switch n.Priority {
			case string(models.PriorityEmergency):
				daily[idx].Emergency++
			case string(models.PriorityHigh):
				daily[idx].High++
			case string(models.PriorityMedium):
				daily[idx].Medium++
			case string(models.PriorityLow):
				daily[idx].Low++
			}
		}
		key := n.AppPackage
		if topSrc[key] == nil {
			topSrc[key] = &models.TopSource{AppName: n.AppName, AppPackage: n.AppPackage}
		}
		topSrc[key].Count++
		if n.Priority == string(models.PriorityHigh) || n.Priority == string(models.PriorityEmergency) {
			topSrc[key].HighRate++
		}
	}

	top := make([]models.TopSource, 0, len(topSrc))
	for _, t := range topSrc {
		if t.Count > 0 {
			t.HighRate = t.HighRate / float64(t.Count)
		}
		top = append(top, *t)
	}
	sort.Slice(top, func(i, j int) bool { return top[i].Count > top[j].Count })
	if len(top) > 5 {
		top = top[:5]
	}

	modeUsage := map[string]int{}
	for _, sess := range sessions {
		minutes := int(sess.EndedAt.Sub(sess.StartedAt).Minutes())
		if minutes < 0 {
			minutes = 0
		}
		modeUsage[sess.ModeName] += minutes
	}

	autoCount := 0
	for _, a := range activities {
		if a.Action == "auto_replied" {
			autoCount++
		}
	}
	rate := 0.0
	if len(activities) > 0 {
		rate = float64(autoCount) / float64(len(activities))
	}

	resp := &models.AnalyticsResponse{
		Range:                rangeStr,
		Total:                len(notifs),
		ByPriority:           byPriority,
		DailyCounts:          daily,
		CortexDelegationRate: rate,
		TopSources:           top,
		ModeUsageMinutes:     modeUsage,
		FinetuneEvents:       finetunes,
	}
	return resp, nil
}

func bucketIndex(ts time.Time, rangeStr string, bucketCount int) int {
	now := time.Now().UTC()
	ts = ts.UTC()
	if rangeStr == "day" {
		diff := int(now.Sub(ts).Hours())
		idx := bucketCount - 1 - diff
		return idx
	}
	diff := int(now.Sub(ts).Hours() / 24)
	idx := bucketCount - 1 - diff
	return idx
}
