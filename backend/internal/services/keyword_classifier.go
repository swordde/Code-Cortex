package services

import "strings"

var emergencyKeywords = []string{
	"critical outage",
	"production down",
	"service down",
	"system down",
	"data breach",
	"security incident",
	"sev1",
	"p1",
	"emergency",
}

var highKeywords = []string{
	"urgent",
	"asap",
	"immediately",
	"right now",
	"blocked",
	"cannot login",
	"can't login",
	"failure",
	"failed",
	"deadline today",
}

var mediumKeywords = []string{
	"follow up",
	"review",
	"pending",
	"meeting",
	"tomorrow",
	"please check",
}

var lowKeywords = []string{
	"low:",
	"no rush",
	"whenever",
	"later",
	"fyi",
	"newsletter",
	"promotion",
	"promo",
	"offer",
	"sale",
	"reminder",
	"update",
}

func InferPriorityByKeywords(content string) (string, string, bool) {
	text := strings.ToLower(strings.TrimSpace(content))
	if text == "" {
		return "", "", false
	}

	if containsAnyKeyword(text, emergencyKeywords) {
		return "EMERGENCY", "keyword_emergency", true
	}
	if containsAnyKeyword(text, highKeywords) {
		return "HIGH", "keyword_high", true
	}
	if containsAnyKeyword(text, mediumKeywords) {
		return "MEDIUM", "keyword_medium", true
	}
	if containsAnyKeyword(text, lowKeywords) {
		return "LOW", "keyword_low", true
	}

	return "", "", false
}

func containsAnyKeyword(text string, keywords []string) bool {
	for _, keyword := range keywords {
		if keyword != "" && strings.Contains(text, keyword) {
			return true
		}
	}
	return false
}
