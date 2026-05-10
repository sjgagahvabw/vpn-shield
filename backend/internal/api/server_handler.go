package api

import (
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/vpn-shield/backend/internal/db"
	"github.com/vpn-shield/backend/internal/models"
)

type ServerHandler struct {
	db *db.Database
}

func NewServerHandler(database *db.Database) *ServerHandler {
	return &ServerHandler{db: database}
}

type CreateServerRequest struct {
	Name         string `json:"name"`
	Host         string `json:"host"`
	Country      string `json:"country"`
	City         string `json:"city"`
	REALITYPort  int    `json:"reality_port"`
	HysteriaPort int    `json:"hysteria_port"`
	TrojanPort   int    `json:"trojan_port"`
	VMessPort    int    `json:"vmess_port"`
	NaivePort    int    `json:"naive_port"`
}

func (h *ServerHandler) GetServers(c *fiber.Ctx) error {
	var servers []models.Server
	if err := h.db.DB.Find(&servers).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to fetch servers",
		})
	}
	return c.JSON(servers)
}

func (h *ServerHandler) GetServer(c *fiber.Ctx) error {
	id := c.Params("id")
	
	var server models.Server
	if err := h.db.DB.First(&server, "id = ?", id).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Server not found",
		})
	}
	
	return c.JSON(server)
}

func (h *ServerHandler) CreateServer(c *fiber.Ctx) error {
	var req CreateServerRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid request body",
		})
	}
	
	// Validate required fields
	if req.Name == "" || req.Host == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Name and host are required",
		})
	}
	
	server := &models.Server{
		ID:           uuid.New(),
		Name:         req.Name,
		Host:         req.Host,
		Country:      req.Country,
		City:         req.City,
		IsActive:     true,
		REALITYPort:  req.REALITYPort,
		HysteriaPort: req.HysteriaPort,
		TrojanPort:   req.TrojanPort,
		VMessPort:    req.VMessPort,
		NaivePort:    req.NaivePort,
	}
	
	if err := h.db.DB.Create(server).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to create server",
		})
	}
	
	return c.Status(fiber.StatusCreated).JSON(server)
}

func (h *ServerHandler) UpdateServer(c *fiber.Ctx) error {
	id := c.Params("id")
	
	var server models.Server
	if err := h.db.DB.First(&server, "id = ?", id).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Server not found",
		})
	}
	
	var req CreateServerRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid request body",
		})
	}
	
	// Update fields
	if req.Name != "" {
		server.Name = req.Name
	}
	if req.Host != "" {
		server.Host = req.Host
	}
	if req.Country != "" {
		server.Country = req.Country
	}
	if req.City != "" {
		server.City = req.City
	}
	if req.REALITYPort > 0 {
		server.REALITYPort = req.REALITYPort
	}
	if req.HysteriaPort > 0 {
		server.HysteriaPort = req.HysteriaPort
	}
	if req.TrojanPort > 0 {
		server.TrojanPort = req.TrojanPort
	}
	if req.VMessPort > 0 {
		server.VMessPort = req.VMessPort
	}
	if req.NaivePort > 0 {
		server.NaivePort = req.NaivePort
	}
	
	if err := h.db.DB.Save(&server).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to update server",
		})
	}
	
	return c.JSON(server)
}

func (h *ServerHandler) DeleteServer(c *fiber.Ctx) error {
	id := c.Params("id")
	
	result := h.db.DB.Delete(&models.Server{}, "id = ?", id)
	if result.Error != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to delete server",
		})
	}
	
	if result.RowsAffected == 0 {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Server not found",
		})
	}
	
	return c.JSON(fiber.Map{
		"message": "Server deleted successfully",
	})
}

func (h *ServerHandler) GetServerStatus(c *fiber.Ctx) error {
	id := c.Params("id")
	
	var server models.Server
	if err := h.db.DB.First(&server, "id = ?", id).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Server not found",
		})
	}
	
	// In a real implementation, you would ping the server or check service status
	status := "online"
	if !server.IsActive {
		status = "offline"
	}
	
	return c.JSON(fiber.Map{
		"id":     server.ID,
		"name":   server.Name,
		"status": status,
		"load":   server.Load,
		"ping":   server.Ping,
	})
}
