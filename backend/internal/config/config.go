package config

import (
	"os"
	"strconv"
	"time"
)

type Config struct {
	Port           string
	MongoURI       string
	MongoDBName    string
	MongoTimeout   time.Duration
	MongoInsecure  bool
	AIServiceURL   string
	UnixSocketPath string
	AvatarDir      string
}

func Load() Config {
	return Config{
		Port:           envOrDefault("SNP_PORT", ":8080"),
		MongoURI:       envOrDefault("SNP_MONGO_URI", "mongodb://localhost:27017"),
		MongoDBName:    envOrDefault("SNP_MONGO_DB", "snp"),
		MongoTimeout:   durationOrDefault("SNP_MONGO_TIMEOUT", 10*time.Second),
		MongoInsecure:  boolOrDefault("SNP_MONGO_INSECURE_TLS", false),
		AIServiceURL:   envOrDefault("SNP_AI_URL", "http://localhost:5000"),
		UnixSocketPath: envOrDefault("SNP_SOCKET_PATH", "/tmp/snp.sock"),
		AvatarDir:      envOrDefault("SNP_AVATAR_DIR", "./avatars"),
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
