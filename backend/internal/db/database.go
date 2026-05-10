package db

import (
	"fmt"
	"log"

	"github.com/vpn-shield/backend/internal/config"
	"github.com/vpn-shield/backend/internal/models"
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
