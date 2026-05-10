package api

import (
	"github.com/gofiber/fiber/v2"
	"github.com/vpn-shield/backend/internal/db"
)

type AuditHandler struct {
	db *db.Database
}

func NewAuditHandler(database *db.Database) *AuditHandler {
	return &AuditHandler{db: database}
}

func (h *AuditHandler) GetAuditLogs(c *fiber.Ctx) error {
	limit := c.QueryInt("limit", 100)
	
	logs, err := h.db.GetAuditLogs(limit)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to fetch audit logs",
		})
	}

	return c.JSON(logs)
}
