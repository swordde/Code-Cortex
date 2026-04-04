package config

import (
	"os"
)

type Config struct {
	ListenAddr          string
	SQLitePath          string
	FlutterDispatchURL  string
	QuickShellSocket    string
	AIEndpoint          string
	ClassificationTries int
	ActivationSecret    string
}

func FromEnv() Config {
	cfg := Config{
		ListenAddr:          envOrDefault("CORTEX_LISTEN_ADDR", "127.0.0.1:8088"),
		SQLitePath:          envOrDefault("CORTEX_SQLITE_PATH", "./cortex_backend.db"),
		FlutterDispatchURL:  os.Getenv("CORTEX_FLUTTER_DISPATCH_URL"),
		QuickShellSocket:    envOrDefault("CORTEX_QUICKSHELL_SOCKET", "/tmp/cortex_quickshell.sock"),
		AIEndpoint:          os.Getenv("CORTEX_AI_ENDPOINT"),
		ClassificationTries: 3,
		ActivationSecret:    envOrDefault("CORTEX_ACTIVATION_SECRET", "change-me-in-prod"),
	}

	return cfg
}

func envOrDefault(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
