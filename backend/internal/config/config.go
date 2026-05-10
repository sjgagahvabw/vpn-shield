package config

import (
	"os"
	"strings"
)

type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	Redis    RedisConfig
	JWT      JWTConfig
	Xray     XrayConfig
	Hysteria HysteriaConfig
}

type ServerConfig struct {
	Host           string
	Port           string
	AllowedOrigins string
}

type DatabaseConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	DBName   string
	SSLMode  string
}

type RedisConfig struct {
	Host     string
	Port     string
	Password string
	DB       int
}

type JWTConfig struct {
	Secret     string
	Expiration int // hours
}

type XrayConfig struct {
	BinaryPath  string
	ConfigPath  string
	LogPath     string
}

type HysteriaConfig struct {
	BinaryPath string
	ConfigPath string
	LogPath    string
	Port       string
}

func Load() *Config {
	return &Config{
		Server: ServerConfig{
			Host:           getEnv("SERVER_HOST", "0.0.0.0"),
			Port:           getEnv("SERVER_PORT", "8080"),
			AllowedOrigins: getEnv("ALLOWED_ORIGINS", "*"),
		},
		Database: DatabaseConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnv("DB_PORT", "5432"),
			User:     getEnv("DB_USER", "vpnshield"),
			Password: getEnvRequired("DB_PASSWORD"),
			DBName:   getEnv("DB_NAME", "vpnshield"),
			SSLMode:  getEnv("DB_SSLMODE", "disable"),
		},
		Redis: RedisConfig{
			Host:     getEnv("REDIS_HOST", "localhost"),
			Port:     getEnv("REDIS_PORT", "6379"),
			Password: getEnv("REDIS_PASSWORD", ""),
			DB:       0,
		},
		JWT: JWTConfig{
			Secret:     getEnvRequired("JWT_SECRET"),
			Expiration: 24 * 7, // 7 days
		},
		Xray: XrayConfig{
			BinaryPath: getEnv("XRAY_PATH", "/usr/local/bin/xray"),
			ConfigPath: getEnv("XRAY_CONFIG_PATH", "./xray-configs"),
			LogPath:    getEnv("XRAY_LOG_PATH", "/var/log/vpn-shield/xray.log"),
		},
		Hysteria: HysteriaConfig{
			BinaryPath: getEnv("HYSTERIA_PATH", "/usr/local/bin/hysteria"),
			ConfigPath: getEnv("HYSTERIA_CONFIG_PATH", "./hysteria-configs"),
			LogPath:    getEnv("HYSTERIA_LOG_PATH", "/var/log/vpn-shield/hysteria.log"),
			Port:       getEnv("HYSTERIA_PORT", "36712"),
		},
	}
}

func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return strings.TrimSpace(value)
}

func getEnvRequired(key string) string {
	value := os.Getenv(key)
	if value == "" {
		panic("Required environment variable " + key + " is not set")
	}
	return strings.TrimSpace(value)
}
