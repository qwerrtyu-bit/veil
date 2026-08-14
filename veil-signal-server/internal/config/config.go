package config

import (
	"os"
	"strconv"
)

type Config struct {
	Port          string
	DBPath        string
	TTLSeconds    int64
	MaxMessages   int
	RateLimit     int
	RateLimitTime int
}

func Load() *Config {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	dbPath := os.Getenv("DB_PATH")
	if dbPath == "" {
		dbPath = "data/veil_server.db"
	}

	ttl := getEnvAsInt("TTL_SECONDS", 300)
	maxMessages := getEnvAsInt("MAX_MESSAGES", 1000)
	rateLimit := getEnvAsInt("RATE_LIMIT", 300)
	rateLimitTime := getEnvAsInt("RATE_LIMIT_TIME", 60)

	return &Config{
		Port:          port,
		DBPath:        dbPath,
		TTLSeconds:    int64(ttl),
		MaxMessages:   maxMessages,
		RateLimit:     rateLimit,
		RateLimitTime: rateLimitTime,
	}
}

func getEnvAsInt(key string, defaultValue int) int {
	if val := os.Getenv(key); val != "" {
		if parsed, err := strconv.Atoi(val); err == nil {
			return parsed
		}
	}
	return defaultValue
}