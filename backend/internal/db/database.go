package db

import (
	"fmt"
	"log"
	"os"

	"github.com/google/uuid"
	"github.com/vpn-shield/backend/internal/config"
	"github.com/vpn-shield/backend/internal/models"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

type Database struct {
	DB *gorm.DB
}

func NewDatabase(cfg config.DatabaseConfig) (*Database, error) {
	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		cfg.Host, cfg.Port, cfg.User, cfg.Password, cfg.DBName, cfg.SSLMode,
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	log.Println("✅ Database connected successfully")

	return &Database{DB: db}, nil
}

func (d *Database) Migrate() error {
	log.Println("Running database migrations...")

	err := d.DB.AutoMigrate(
		&models.User{},
		&models.Connection{},
		&models.Config{},
		&models.Server{},
		&models.Stats{},
		&models.AuditLog{},
	)
	if err != nil {
		return fmt.Errorf("failed to run migrations: %w", err)
	}

	log.Println("✅ Database migrations completed")
	
	// Create default admin user if no users exist
	if err := d.CreateDefaultAdmin(); err != nil {
		return fmt.Errorf("failed to create default admin: %w", err)
	}
	
	return nil
}

func (d *Database) CreateDefaultAdmin() error {
	var count int64
	d.DB.Model(&models.User{}).Count(&count)
	
	if count > 0 {
		log.Println("ℹ️  Users already exist, skipping admin creation")
		return nil
	}
	
	adminUsername := os.Getenv("ADMIN_USERNAME")
	if adminUsername == "" {
		adminUsername = "admin"
	}
	
	adminPassword := os.Getenv("ADMIN_PASSWORD")
	if adminPassword == "" {
		log.Fatal("❌ ADMIN_PASSWORD environment variable must be set for security reasons")
	}
	
	adminEmail := os.Getenv("ADMIN_EMAIL")
	if adminEmail == "" {
		adminEmail = "admin@example.com"
	}
	
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(adminPassword), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("failed to hash password: %w", err)
	}
	
	admin := &models.User{
		ID:       uuid.New(),
		Username: adminUsername,
		Email:    adminEmail,
		Password: string(hashedPassword),
		IsAdmin:  true,
		IsActive: true,
	}
	
	if err := d.DB.Create(admin).Error; err != nil {
		return fmt.Errorf("failed to create admin user: %w", err)
	}
	
	log.Printf("✅ Default admin user created: %s", adminUsername)
	return nil
}

func (d *Database) Close() error {
	sqlDB, err := d.DB.DB()
	if err != nil {
		return err
	}
	return sqlDB.Close()
}

// User operations
func (d *Database) CreateUser(user *models.User) error {
	return d.DB.Create(user).Error
}

func (d *Database) GetUserByID(id string) (*models.User, error) {
	var user models.User
	err := d.DB.Preload("Connections").Preload("Configs").First(&user, "id = ?", id).Error
	return &user, err
}

func (d *Database) GetUserByUsername(username string) (*models.User, error) {
	var user models.User
	err := d.DB.First(&user, "username = ?", username).Error
	return &user, err
}

func (d *Database) GetUserByEmail(email string) (*models.User, error) {
	var user models.User
	err := d.DB.First(&user, "email = ?", email).Error
	return &user, err
}

func (d *Database) GetAllUsers() ([]models.User, error) {
	var users []models.User
	err := d.DB.Find(&users).Error
	return users, err
}

func (d *Database) UpdateUser(user *models.User) error {
	return d.DB.Save(user).Error
}

func (d *Database) DeleteUser(id string) error {
	return d.DB.Delete(&models.User{}, "id = ?", id).Error
}

// Connection operations
func (d *Database) CreateConnection(conn *models.Connection) error {
	return d.DB.Create(conn).Error
}

func (d *Database) GetActiveConnections() ([]models.Connection, error) {
	var connections []models.Connection
	err := d.DB.Preload("User").Where("disconnected_at IS NULL").Find(&connections).Error
	return connections, err
}

func (d *Database) GetUserConnections(userID string) ([]models.Connection, error) {
	var connections []models.Connection
	err := d.DB.Where("user_id = ?", userID).Order("connected_at DESC").Find(&connections).Error
	return connections, err
}

func (d *Database) UpdateConnection(conn *models.Connection) error {
	return d.DB.Save(conn).Error
}

// Config operations
func (d *Database) CreateConfig(cfg *models.Config) error {
	return d.DB.Create(cfg).Error
}

func (d *Database) GetUserConfigs(userID string) ([]models.Config, error) {
	var configs []models.Config
	err := d.DB.Where("user_id = ?", userID).Find(&configs).Error
	return configs, err
}

func (d *Database) GetConfigByID(id string) (*models.Config, error) {
	var cfg models.Config
	err := d.DB.First(&cfg, "id = ?", id).Error
	return &cfg, err
}

func (d *Database) UpdateConfig(cfg *models.Config) error {
	return d.DB.Save(cfg).Error
}

func (d *Database) DeleteConfig(id string) error {
	return d.DB.Delete(&models.Config{}, "id = ?", id).Error
}

// Stats operations
func (d *Database) CreateStats(stats *models.Stats) error {
	return d.DB.Create(stats).Error
}

func (d *Database) GetLatestStats() (*models.Stats, error) {
	var stats models.Stats
	err := d.DB.Order("created_at DESC").First(&stats).Error
	return &stats, err
}

// Audit log operations
func (d *Database) CreateAuditLog(log *models.AuditLog) error {
	return d.DB.Create(log).Error
}

func (d *Database) GetAuditLogs(limit int) ([]models.AuditLog, error) {
	var logs []models.AuditLog
	err := d.DB.Preload("User").Order("created_at DESC").Limit(limit).Find(&logs).Error
	return logs, err
}
