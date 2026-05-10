package api

import (
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/vpn-shield/backend/internal/db"
	"github.com/vpn-shield/backend/internal/models"
)

type ConnectionHandler struct {
	db *db.Database
}

func NewConnectionHandler(database *db.Database) *ConnectionHandler {
	return &ConnectionHandler{db: database}
}

func (h *ConnectionHandler) GetUserConnections(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)

	connections, err := h.db.GetUserConnections(userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to fetch connections",
		})
	}

	return c.JSON(connections)
}

func (h *ConnectionHandler) GetActiveConnections(c *fiber.Ctx) error {
	connections, err := h.db.GetActiveConnections()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to fetch active connections",
		})
	}

	return c.JSON(connections)
}

func (h *ConnectionHandler) DisconnectConnection(c *fiber.Ctx) error {
	id := c.Params("id")
	userID := c.Locals("user_id").(string)
	isAdmin := c.Locals("is_admin").(bool)

	var conn models.Connection
	if err := h.db.DB.First(&conn, "id = ?", id).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Connection not found",
		})
	}

	// Users can only disconnect their own connections unless they're admin
	if conn.UserID.String() != userID && !isAdmin {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "Access denied",
		})
	}

	now := time.Now()
	conn.DisconnectedAt = &now

	if err := h.db.UpdateConnection(&conn); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to disconnect connection",
		})
	}

	return c.JSON(fiber.Map{
		"message": "Connection disconnected successfully",
	})
}
