package services

import "strings"

func normalizePriority(raw string) string {
	return strings.ToUpper(strings.TrimSpace(raw))
}

func toAIPriority(p string) string {
	switch strings.ToUpper(strings.TrimSpace(p)) {
	case "EMERGENCY":
		return "Emergency"
	case "HIGH":
		return "High"
	case "MEDIUM":
		return "Medium"
	case "LOW":
		return "Low"
	default:
		return "Medium"
	}
}

func toAIMode(m string) string {
	if strings.EqualFold(strings.TrimSpace(m), "default") {
		return "custom"
	}
	return strings.TrimSpace(m)
}

func toneFromMode(mode string) string {
	switch strings.ToLower(strings.TrimSpace(mode)) {
	case "study":
		return "brief"
	case "office":
		return "professional"
	case "home":
		return "casual"
	case "gaming":
		return "casual"
	default:
		return "casual"
	}
}
