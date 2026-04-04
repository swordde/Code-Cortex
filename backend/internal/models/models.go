package models

import "time"

type Priority string

const (
	PriorityEmergency Priority = "emergency"
	PriorityHigh      Priority = "high"
	PriorityNormal    Priority = "normal"
	PriorityLow       Priority = "low"
)

type Notification struct {
	ID         string    `json:"id,omitempty"`
	Platform   string    `json:"platform"`
	App        string    `json:"app"`
	Sender     string    `json:"sender"`
	Title      string    `json:"title"`
	Content    string    `json:"content"`
	ReceivedAt time.Time `json:"receivedAt"`
}

type Rule struct {
	ID       string   `json:"id"`
	Contact  string   `json:"contact,omitempty"`
	Keywords []string `json:"keywords,omitempty"`
	Priority Priority `json:"priority"`
	Enabled  bool     `json:"enabled"`
}

type ContextMode string

const (
	ModeDefault  ContextMode = "default"
	ModeWork     ContextMode = "work"
	ModeSleep    ContextMode = "sleep"
	ModeDriving  ContextMode = "driving"
	ModeDeepWork ContextMode = "deep_work"
)

type ClassificationResult struct {
	NotificationID string   `json:"notificationId,omitempty"`
	AILabel        Priority `json:"aiLabel"`
	FinalLabel     Priority `json:"finalLabel"`
	OverriddenBy   string   `json:"overriddenBy,omitempty"`
	Mode           string   `json:"mode"`
	Reason         string   `json:"reason,omitempty"`
	ProcessedAt    string   `json:"processedAt"`
}

type IngestResponse struct {
	Result     ClassificationResult `json:"result"`
	Dispatched bool                 `json:"dispatched"`
}

type VoiceSignature struct {
	UserID        string    `json:"userId"`
	SignatureHash string    `json:"signatureHash"`
	CreatedAt     time.Time `json:"createdAt"`
}
