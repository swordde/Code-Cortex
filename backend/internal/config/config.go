package config

import (
	"os"
)

type Config struct {
	Port           string
	MongoURI       string
	MongoDBName    string
	AIServiceURL   string
	UnixSocketPath string
	AvatarDir      string
}

func Load() Config {
	return Config{
		Port:           envOrDefault("SNP_PORT", ":8080"),
		MongoURI:       envOrDefault("SNP_MONGO_URI", "mongodb://localhost:27017"),
		MongoDBName:    envOrDefault("SNP_MONGO_DB", "snp"),
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
