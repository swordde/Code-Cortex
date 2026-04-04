package models

import "time"

type Priority string

const (
	PriorityEmergency Priority = "EMERGENCY"
	PriorityHigh      Priority = "HIGH"
	PriorityMedium    Priority = "MEDIUM"
	PriorityLow       Priority = "LOW"
)

type Notification struct {
	ID          string    `json:"id" bson:"_id"`
	Content     string    `json:"content" bson:"content"`
	AppName     string    `json:"app_name" bson:"app_name"`
	AppPackage  string    `json:"app_package" bson:"app_package"`
	SenderName  string    `json:"sender_name" bson:"sender_name"`
	Priority    string    `json:"priority" bson:"priority"`
	Mode        string    `json:"mode" bson:"mode"`
	IsRead      bool      `json:"is_read" bson:"is_read"`
	IsActioned  bool      `json:"is_actioned" bson:"is_actioned"`
	Confidence  float64   `json:"confidence" bson:"confidence"`
	LabelReason string    `json:"label_reason" bson:"label_reason"`
	Timestamp   time.Time `json:"timestamp" bson:"timestamp"`
	Deleted     bool      `json:"-" bson:"deleted"`
}

type Rule struct {
	ID         string   `json:"id" bson:"_id"`
	Type       string   `json:"type" bson:"type"`
	ContactID  string   `json:"contact_id,omitempty" bson:"contact_id,omitempty"`
	Keywords   []string `json:"keywords,omitempty" bson:"keywords,omitempty"`
	AppPackage string   `json:"app_package,omitempty" bson:"app_package,omitempty"`
	Priority   string   `json:"priority" bson:"priority"`
	TimeStart  string   `json:"time_start,omitempty" bson:"time_start,omitempty"`
	TimeEnd    string   `json:"time_end,omitempty" bson:"time_end,omitempty"`
	Order      int      `json:"order" bson:"order"`
	Enabled    bool     `json:"enabled" bson:"enabled"`
}

type AppCap struct {
	AppPackage  string `json:"app_package" bson:"app_package"`
	MaxPriority string `json:"max_priority" bson:"max_priority"`
}

type Mode struct {
	ID            string   `json:"id" bson:"_id"`
	Name          string   `json:"name" bson:"name"`
	IsActive      bool     `json:"is_active" bson:"is_active"`
	IsPreset      bool     `json:"is_preset" bson:"is_preset"`
	AppCaps       []AppCap `json:"app_caps" bson:"app_caps"`
	Keywords      []string `json:"keywords" bson:"keywords"`
	ContactIDs    []string `json:"contact_ids" bson:"contact_ids"`
	CortexLevel   string   `json:"cortex_level" bson:"cortex_level"`
	ScheduleStart string   `json:"schedule_start" bson:"schedule_start"`
	ScheduleEnd   string   `json:"schedule_end" bson:"schedule_end"`
	ScheduleDays  []int    `json:"schedule_days" bson:"schedule_days"`
}

type CortexConfig struct {
	Enabled   bool   `json:"enabled" bson:"enabled"`
	AutoReply bool   `json:"auto_reply" bson:"auto_reply"`
	Scope     string `json:"scope" bson:"scope"`
}

type ReplyTemplate struct {
	ID        string `json:"id" bson:"_id"`
	Body      string `json:"body" bson:"body"`
	Tone      string `json:"tone" bson:"tone"`
	IsDefault bool   `json:"is_default" bson:"is_default"`
}

type ScheduledMessage struct {
	ID             string    `json:"id" bson:"_id"`
	NotificationID string    `json:"notification_id" bson:"notification_id"`
	DraftBody      string    `json:"draft_body" bson:"draft_body"`
	ScheduledAt    time.Time `json:"scheduled_at" bson:"scheduled_at"`
	Status         string    `json:"status" bson:"status"`
}

type CortexActivityEntry struct {
	ID             string    `json:"id" bson:"_id"`
	NotificationID string    `json:"notification_id" bson:"notification_id"`
	Action         string    `json:"action" bson:"action"`
	Body           string    `json:"body" bson:"body"`
	Timestamp      time.Time `json:"timestamp" bson:"timestamp"`
}

type UserProfile struct {
	DisplayName     string   `json:"display_name" bson:"display_name"`
	AvatarPath      string   `json:"avatar_path" bson:"avatar_path"`
	NotifPermission bool     `json:"notif_permission" bson:"notif_permission"`
	ThemeMode       string   `json:"theme_mode" bson:"theme_mode"`
	LinkedAccounts  []string `json:"linked_accounts" bson:"linked_accounts"`
	VoiceLocked     bool     `json:"voice_locked" bson:"voice_locked"`
}

type NotificationMessage struct {
	Type    string       `json:"type"`
	Payload Notification `json:"payload"`
}

type ModeChangedMessage struct {
	Type    string         `json:"type"`
	Payload map[string]any `json:"payload"`
}

type CortexActionMessage struct {
	Type    string              `json:"type"`
	Payload CortexActivityEntry `json:"payload"`
}

type DailyCount struct {
	Date      string `json:"date"`
	Emergency int    `json:"EMERGENCY"`
	High      int    `json:"HIGH"`
	Medium    int    `json:"MEDIUM"`
	Low       int    `json:"LOW"`
}

type TopSource struct {
	AppName    string  `json:"app_name"`
	AppPackage string  `json:"app_package"`
	Count      int     `json:"count"`
	HighRate   float64 `json:"high_rate"`
}

type FinetuneEvent struct {
	ID            string    `json:"id" bson:"_id"`
	Timestamp     time.Time `json:"timestamp" bson:"timestamp"`
	AccuracyDelta float64   `json:"accuracy_delta" bson:"accuracy_delta"`
	SampleCount   int       `json:"sample_count" bson:"sample_count"`
}

type AnalyticsResponse struct {
	Range                string          `json:"range"`
	Total                int             `json:"total"`
	ByPriority           map[string]int  `json:"by_priority"`
	DailyCounts          []DailyCount    `json:"daily_counts"`
	CortexDelegationRate float64         `json:"cortex_delegation_rate"`
	TopSources           []TopSource     `json:"top_sources"`
	ModeUsageMinutes     map[string]int  `json:"mode_usage_minutes"`
	FinetuneEvents       []FinetuneEvent `json:"finetune_events"`
}

type ModeSession struct {
	ID        string    `bson:"_id"`
	ModeName  string    `bson:"mode_name"`
	StartedAt time.Time `bson:"started_at"`
	EndedAt   time.Time `bson:"ended_at"`
}

var PriorityRank = map[string]int{
	string(PriorityLow):       1,
	string(PriorityMedium):    2,
	string(PriorityHigh):      3,
	string(PriorityEmergency): 4,
}

const (
	ModeDefault = "default"
)
