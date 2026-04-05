package config

import (
	"os"
	"strconv"
	"time"
)

type Config struct {
	Port           string
	DBPath         string
	NotificationsJSONDir string
	MongoURI       string
	MongoDBName    string
	MongoTimeout   time.Duration
	MongoInsecure  bool
	AIServiceURL   string
	ReplyWebhookURL string
	ReplyWebhookSlackURL string
	ReplyWebhookWhatsAppURL string
	ReplyWebhookTeamsURL string
	ReplyWebhookDiscordURL string
	UnixSocketPath string
	AvatarDir      string
	AITimeoutSec   int
	EnableVoiceAssistant bool
}

func Load() Config {
	return Config{
		Port:           envOrDefault("SNP_PORT", ":8080"),
		DBPath:         envOrDefault("SNP_DB_PATH", "./snp.db"),
		NotificationsJSONDir: envOrDefault("SNP_NOTIFICATIONS_JSON_DIR", "./data/notifications"),
		MongoURI:       envOrDefault("SNP_MONGO_URI", "mongodb://localhost:27017"),
		MongoDBName:    envOrDefault("SNP_MONGO_DB", "snp"),
		MongoTimeout:   durationOrDefault("SNP_MONGO_TIMEOUT", 10*time.Second),
		MongoInsecure:  boolOrDefault("SNP_MONGO_INSECURE_TLS", false),
		AIServiceURL:   envOrDefault("SNP_AI_URL", "https://marisela-tiderode-mollifyingly.ngrok-free.dev"),
		ReplyWebhookURL: envOrDefault("SNP_REPLY_WEBHOOK_URL", ""),
		ReplyWebhookSlackURL: envOrDefault("SNP_REPLY_WEBHOOK_SLACK_URL", ""),
		ReplyWebhookWhatsAppURL: envOrDefault("SNP_REPLY_WEBHOOK_WHATSAPP_URL", ""),
		ReplyWebhookTeamsURL: envOrDefault("SNP_REPLY_WEBHOOK_TEAMS_URL", ""),
		ReplyWebhookDiscordURL: envOrDefault("SNP_REPLY_WEBHOOK_DISCORD_URL", ""),
		UnixSocketPath: envOrDefault("SNP_SOCKET_PATH", "/tmp/snp.sock"),
		AvatarDir:      envOrDefault("SNP_AVATAR_DIR", "./avatars"),
		AITimeoutSec:   intOrDefault("SNP_AI_TIMEOUT", 5),
		EnableVoiceAssistant: boolOrDefault("SNP_ENABLE_VOICE_ASSISTANT", false),
	}
}

func envOrDefault(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func boolOrDefault(key string, fallback bool) bool {
	v := os.Getenv(key)
	if v == "" {
		return fallback
	}
	parsed, err := strconv.ParseBool(v)
	if err != nil {
		return fallback
	}
	return parsed
}

func durationOrDefault(key string, fallback time.Duration) time.Duration {
	v := os.Getenv(key)
	if v == "" {
		return fallback
	}
	parsed, err := time.ParseDuration(v)
	if err != nil {
		return fallback
	}
	return parsed
}

func intOrDefault(key string, fallback int) int {
	v := os.Getenv(key)
	if v == "" {
		return fallback
	}
	parsed, err := strconv.Atoi(v)
	if err != nil {
		return fallback
	}
	return parsed
}
