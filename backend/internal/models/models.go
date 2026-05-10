package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// User represents a VPN user
type User struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Username  string    `gorm:"uniqueIndex;not null" json:"username"`
	Email     string    `gorm:"uniqueIndex;not null" json:"email"`
	Password  string    `gorm:"not null" json:"-"`
	IsAdmin   bool      `gorm:"default:false" json:"is_admin"`
	IsActive  bool      `gorm:"default:true" json:"is_active"`
	
	// Limits
	DataLimit     int64     `gorm:"default:0" json:"data_limit"` // 0 = unlimited, in bytes
	DataUsed      int64     `gorm:"default:0" json:"data_used"`
	ExpiryDate    *time.Time `json:"expiry_date"`
	MaxDevices    int       `gorm:"default:5" json:"max_devices"`
	
	// Protocols enabled
	EnableREALITY  bool `gorm:"default:true" json:"enable_reality"`
	EnableHysteria bool `gorm:"default:true" json:"enable_hysteria"`
	EnableTrojan   bool `gorm:"default:true" json:"enable_trojan"`
	EnableVMess    bool `gorm:"default:true" json:"enable_vmess"`
	EnableNaive    bool `gorm:"default:false" json:"enable_naive"`
	
	// Relations
	Connections []Connection `gorm:"foreignKey:UserID" json:"connections,omitempty"`
	Configs     []Config     `gorm:"foreignKey:UserID" json:"configs,omitempty"`
	
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

// Connection represents an active connection
type Connection struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	UserID    uuid.UUID `gorm:"type:uuid;not null" json:"user_id"`
	User      User      `gorm:"foreignKey:UserID" json:"user,omitempty"`
	
	Protocol    string    `gorm:"not null" json:"protocol"` // reality, hysteria, trojan, vmess, naive
	DeviceName  string    `json:"device_name"`
	IPAddress   string    `json:"ip_address"`
	Country     string    `json:"country"`
	
	DataUpload   int64 `gorm:"default:0" json:"data_upload"`
	DataDownload int64 `gorm:"default:0" json:"data_download"`
	
	ConnectedAt  time.Time  `json:"connected_at"`
	DisconnectedAt *time.Time `json:"disconnected_at"`
	
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
}

// Config represents a protocol configuration for a user
type Config struct {
	ID       uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	UserID   uuid.UUID `gorm:"type:uuid;not null" json:"user_id"`
	User     User      `gorm:"foreignKey:UserID" json:"user,omitempty"`
	
	Protocol string `gorm:"not null" json:"protocol"`
	Name     string `gorm:"not null" json:"name"`
	
	// Protocol-specific settings
	Settings map[string]interface{} `gorm:"type:jsonb" json:"settings"`
	
	// Generated config
	ConfigURL  string `json:"config_url"`
	QRCode     string `json:"qr_code"`
	
	IsActive   bool `gorm:"default:true" json:"is_active"`
	
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

// Server represents the VPN server configuration
type Server struct {
	ID       uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Name     string    `gorm:"not null" json:"name"`
	Host     string    `gorm:"not null" json:"host"`
	Country  string    `json:"country"`
	City     string    `json:"city"`
	
	// Status
	IsActive   bool   `gorm:"default:true" json:"is_active"`
	Load       int    `gorm:"default:0" json:"load"` // 0-100
	Ping       int    `json:"ping"` // ms
	
	// Protocols
	REALITYPort  int    `json:"reality_port"`
	HysteriaPort int    `json:"hysteria_port"`
	TrojanPort   int    `json:"trojan_port"`
	VMessPort    int    `json:"vmess_port"`
	NaivePort    int    `json:"naive_port"`
	
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

// Stats represents system statistics
type Stats struct {
	ID              uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	
	TotalUsers      int   `json:"total_users"`
	ActiveUsers     int   `json:"active_users"`
	TotalConnections int  `json:"total_connections"`
	
	TotalUpload     int64 `json:"total_upload"`
	TotalDownload   int64 `json:"total_download"`
	
	CPUUsage        float64 `json:"cpu_usage"`
	MemoryUsage     float64 `json:"memory_usage"`
	DiskUsage       float64 `json:"disk_usage"`
	
	Timestamp time.Time `json:"timestamp"`
	CreatedAt time.Time `json:"created_at"`
}

// AuditLog represents system audit logs
type AuditLog struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	UserID    *uuid.UUID `gorm:"type:uuid" json:"user_id"`
	User      *User     `gorm:"foreignKey:UserID" json:"user,omitempty"`
	
	Action    string `gorm:"not null" json:"action"`
	Resource  string `json:"resource"`
	Details   string `gorm:"type:text" json:"details"`
	IPAddress string `json:"ip_address"`
	UserAgent string `json:"user_agent"`
	
	CreatedAt time.Time `json:"created_at"`
}
