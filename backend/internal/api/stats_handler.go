package api

import (
	"github.com/gofiber/fiber/v2"
	"github.com/vpn-shield/backend/internal/db"
)

type StatsHandler struct {
	db *db.Database
}

func NewStatsHandler(database *db.Database) *StatsHandler {
	return &StatsHandler{db: database}
}

func (h *StatsHandler) GetStats(c *fiber.Ctx) error {
	stats, err := h.db.GetLatestStats()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to fetch stats",
		})
	}

	return c.JSON(stats)
}

func (h *StatsHandler) GetDashboard(c *fiber.Ctx) error {
	// Get all users
	users, err := h.db.GetAllUsers()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to fetch users",
		})
	}

	// Get active connections
	activeConns, err := h.db.GetActiveConnections()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to fetch connections",
		})
	}

	// Calculate totals
	totalUsers := len(users)
	activeUsers := 0
	var totalUpload, totalDownload int64

	for _, user := range users {
		if user.IsActive {
			activeUsers++
		}
	}

	for _, conn := range activeConns {
		totalUpload += conn.DataUpload
		totalDownload += conn.DataDownload
	}

	dashboard := fiber.Map{
		"total_users":        totalUsers,
		"active_users":       activeUsers,
		"active_connections": len(activeConns),
		"total_upload":       totalUpload,
		"total_download":     totalDownload,
		"total_traffic":      totalUpload + totalDownload,
	}

	return c.JSON(dashboard)
}

func (h *StatsHandler) GetTrafficStats(c *fiber.Ctx) error {
	// Get all connections
	var connections []struct {
		Protocol     string
		DataUpload   int64
		DataDownload int64
	}

	if err := h.db.DB.Model(&struct {
		Protocol     string
		DataUpload   int64
		DataDownload int64
	}{}).Select("protocol, SUM(data_upload) as data_upload, SUM(data_download) as data_download").Group("protocol").Find(&connections).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to fetch traffic stats",
		})
	}

	return c.JSON(connections)
}
