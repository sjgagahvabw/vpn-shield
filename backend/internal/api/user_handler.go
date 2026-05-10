package api

import (
	"github.com/gofiber/fiber/v2"
	"github.com/vpn-shield/backend/internal/db"
	"github.com/vpn-shield/backend/internal/models"
)

type UserHandler struct {
	db *db.Database
}

func NewUserHandler(database *db.Database) *UserHandler {
	return &UserHandler{db: database}
}

func (h *UserHandler) GetAllUsers(c *fiber.Ctx) error {
	users, err := h.db.GetAllUsers()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to fetch users",
		})
	}

	return c.JSON(users)
}

func (h *UserHandler) GetUser(c *fiber.Ctx) error {
	id := c.Params("id")
	userID := c.Locals("user_id").(string)
	isAdmin := c.Locals("is_admin").(bool)

	// Users can only view their own profile unless they're admin
	if id != userID && !isAdmin {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "Access denied",
		})
	}

	user, err := h.db.GetUserByID(id)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "User not found",
		})
	}

	return c.JSON(user)
}

type UpdateUserRequest struct {
	Email          *string `json:"email"`
	DataLimit      *int64  `json:"data_limit"`
	MaxDevices     *int    `json:"max_devices"`
	EnableREALITY  *bool   `json:"enable_reality"`
	EnableHysteria *bool   `json:"enable_hysteria"`
	EnableTrojan   *bool   `json:"enable_trojan"`
	EnableVMess    *bool   `json:"enable_vmess"`
	EnableNaive    *bool   `json:"enable_naive"`
	IsActive       *bool   `json:"is_active"`
}

func (h *UserHandler) UpdateUser(c *fiber.Ctx) error {
	id := c.Params("id")
	userID := c.Locals("user_id").(string)
	isAdmin := c.Locals("is_admin").(bool)

	// Users can only update their own profile unless they're admin
	if id != userID && !isAdmin {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "Access denied",
		})
	}

	user, err := h.db.GetUserByID(id)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "User not found",
		})
	}

	var req UpdateUserRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid request body",
		})
	}

	// Update fields
	if req.Email != nil {
		user.Email = *req.Email
	}
	if req.DataLimit != nil && isAdmin {
		user.DataLimit = *req.DataLimit
	}
	if req.MaxDevices != nil && isAdmin {
		user.MaxDevices = *req.MaxDevices
	}
	if req.EnableREALITY != nil {
		user.EnableREALITY = *req.EnableREALITY
	}
	if req.EnableHysteria != nil {
		user.EnableHysteria = *req.EnableHysteria
	}
	if req.EnableTrojan != nil {
		user.EnableTrojan = *req.EnableTrojan
	}
	if req.EnableVMess != nil {
		user.EnableVMess = *req.EnableVMess
	}
	if req.EnableNaive != nil {
		user.EnableNaive = *req.EnableNaive
	}
	if req.IsActive != nil && isAdmin {
		user.IsActive = *req.IsActive
	}

	if err := h.db.UpdateUser(user); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to update user",
		})
	}

	// Audit log
	h.db.CreateAuditLog(&models.AuditLog{
		UserID:    &user.ID,
		Action:    "user_updated",
		Resource:  "users",
		Details:   "User updated: " + user.Username,
		IPAddress: c.IP(),
		UserAgent: c.Get("User-Agent"),
	})

	return c.JSON(user)
}

func (h *UserHandler) DeleteUser(c *fiber.Ctx) error {
	id := c.Params("id")

	user, err := h.db.GetUserByID(id)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "User not found",
		})
	}

	if err := h.db.DeleteUser(id); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to delete user",
		})
	}

	// Audit log
	adminID := c.Locals("user_id").(string)
	h.db.CreateAuditLog(&models.AuditLog{
		Action:    "user_deleted",
		Resource:  "users",
		Details:   "User deleted: " + user.Username + " by admin: " + adminID,
		IPAddress: c.IP(),
		UserAgent: c.Get("User-Agent"),
	})

	return c.JSON(fiber.Map{
		"message": "User deleted successfully",
	})
}

func (h *UserHandler) GetUserStats(c *fiber.Ctx) error {
	id := c.Params("id")
	userID := c.Locals("user_id").(string)
	isAdmin := c.Locals("is_admin").(bool)

	if id != userID && !isAdmin {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "Access denied",
		})
	}

	user, err := h.db.GetUserByID(id)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "User not found",
		})
	}

	connections, err := h.db.GetUserConnections(id)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to fetch connections",
		})
	}

	// Calculate stats
	var totalUpload, totalDownload int64
	activeConnections := 0

	for _, conn := range connections {
		totalUpload += conn.DataUpload
		totalDownload += conn.DataDownload
		if conn.DisconnectedAt == nil {
			activeConnections++
		}
	}

	stats := fiber.Map{
		"user_id":            user.ID,
		"username":           user.Username,
		"data_used":          user.DataUsed,
		"data_limit":         user.DataLimit,
		"data_remaining":     user.DataLimit - user.DataUsed,
		"total_upload":       totalUpload,
		"total_download":     totalDownload,
		"total_connections":  len(connections),
		"active_connections": activeConnections,
		"max_devices":        user.MaxDevices,
	}

	return c.JSON(stats)
}
