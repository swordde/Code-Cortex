package services

import (
	"strings"
	"time"

	"cortex/backend/internal/models"
)

func ApplyRules(n *models.Notification, rules []models.Rule, mode *models.Mode) (string, string) {
	current := n.Priority
	reason := n.LabelReason
	lowerSender := strings.ToLower(n.SenderName)
	lowerContent := strings.ToLower(n.Content)

	for _, rule := range rules {
		if !rule.Enabled {
			continue
		}
		switch rule.Type {
		case "contact":
			if rule.ContactID != "" && strings.Contains(lowerSender, strings.ToLower(rule.ContactID)) {
				return rule.Priority, "contact_rule"
			}
		case "keyword":
			for _, kw := range rule.Keywords {
				if kw != "" && strings.Contains(lowerContent, strings.ToLower(kw)) {
					return rule.Priority, "keyword_rule"
				}
			}
		case "app":
			if rule.AppPackage != "" && n.AppPackage == rule.AppPackage {
				current = minPriority(current, rule.Priority)
				reason = "app_rule"
			}
		case "time":
			if withinTimeWindow(rule.TimeStart, rule.TimeEnd, time.Now()) {
				current = rule.Priority
				reason = "time_rule"
			}
		}
	}

	if mode != nil {
		for _, appCap := range mode.AppCaps {
			if appCap.AppPackage == n.AppPackage {
				current = minPriority(current, appCap.MaxPriority)
				reason = "mode_app_cap"
			}
		}
	}

	return current, reason
}

func minPriority(current, capValue string) string {
	curRank := models.PriorityRank[current]
	capRank := models.PriorityRank[capValue]
	if capRank == 0 {
		return current
	}
	if curRank > capRank {
		return capValue
	}
	return current
}

func withinTimeWindow(start, end string, now time.Time) bool {
	if start == "" || end == "" {
		return false
	}
	nowMin := now.Hour()*60 + now.Minute()
	st, err1 := parseHHMM(start)
	en, err2 := parseHHMM(end)
	if err1 != nil || err2 != nil {
		return false
	}
	if st <= en {
		return nowMin >= st && nowMin <= en
	}
	return nowMin >= st || nowMin <= en
}

func parseHHMM(v string) (int, error) {
	t, err := time.Parse("15:04", v)
	if err != nil {
		return 0, err
	}
	return t.Hour()*60 + t.Minute(), nil
}
