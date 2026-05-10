package api

import (
	"encoding/base64"
	"encoding/json"
	"fmt"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/vpn-shield/backend/internal/config"
	"github.com/vpn-shield/backend/internal/db"
	"github.com/vpn-shield/backend/internal/models"
)

type ConfigHandler struct {
	db  *db.Database
	cfg *config.Config
}

func NewConfigHandler(database *db.Database, cfg *config.Config) *ConfigHandler {
	return &ConfigHandler{
		db:  database,
		cfg: cfg,
	}
}

type CreateConfigRequest struct {
	Protocol string                 `json:"protocol"`
	Name     string                 `json:"name"`
	Settings map[string]interface{} `json:"settings"`
}

func (h *ConfigHandler) GetUserConfigs(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)

	configs, err := h.db.GetUserConfigs(userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to fetch configs",
		})
	}

	return c.JSON(configs)
}

func (h *ConfigHandler) CreateConfig(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)

	var req CreateConfigRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid request body",
		})
	}

	// Validate protocol
	validProtocols := []string{"reality", "hysteria", "trojan", "vmess", "naive"}
	isValid := false
	for _, p := range validProtocols {
		if req.Protocol == p {
			isValid = true
			break
		}
	}
	if !isValid {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid protocol",
		})
	}

	// Get user to check enabled protocols
	user, err := h.db.GetUserByID(userID)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "User not found",
		})
	}

	// Check if protocol is enabled for user
	switch req.Protocol {
	case "reality":
		if !user.EnableREALITY {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"error": "REALITY protocol is not enabled for this user",
			})
		}
	case "hysteria":
		if !user.EnableHysteria {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"error": "Hysteria protocol is not enabled for this user",
			})
		}
	case "trojan":
		if !user.EnableTrojan {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"error": "Trojan protocol is not enabled for this user",
			})
		}
	case "vmess":
		if !user.EnableVMess {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"error": "VMess protocol is not enabled for this user",
			})
		}
	case "naive":
		if !user.EnableNaive {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"error": "Naive protocol is not enabled for this user",
			})
		}
	}

	// Generate config URL based on protocol
	configURL := h.generateConfigURL(req.Protocol, userID, req.Settings)

	cfg := &models.Config{
		ID:        uuid.New(),
		UserID:    user.ID,
		Protocol:  req.Protocol,
		Name:      req.Name,
		Settings:  req.Settings,
		ConfigURL: configURL,
		IsActive:  true,
	}

	if err := h.db.CreateConfig(cfg); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to create config",
		})
	}

	// Audit log
	h.db.CreateAuditLog(&models.AuditLog{
		UserID:    &user.ID,
		Action:    "config_created",
		Resource:  "configs",
		Details:   fmt.Sprintf("Config created: %s (%s)", cfg.Name, cfg.Protocol),
		IPAddress: c.IP(),
		UserAgent: c.Get("User-Agent"),
	})

	return c.Status(fiber.StatusCreated).JSON(cfg)
}

func (h *ConfigHandler) GetConfig(c *fiber.Ctx) error {
	id := c.Params("id")
	userID := c.Locals("user_id").(string)
	isAdmin := c.Locals("is_admin").(bool)

	cfg, err := h.db.GetConfigByID(id)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Config not found",
		})
	}

	// Users can only view their own configs unless they're admin
	if cfg.UserID.String() != userID && !isAdmin {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "Access denied",
		})
	}

	return c.JSON(cfg)
}

func (h *ConfigHandler) UpdateConfig(c *fiber.Ctx) error {
	id := c.Params("id")
	userID := c.Locals("user_id").(string)
	isAdmin := c.Locals("is_admin").(bool)

	cfg, err := h.db.GetConfigByID(id)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Config not found",
		})
	}

	if cfg.UserID.String() != userID && !isAdmin {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "Access denied",
		})
	}

	var req struct {
		Name     *string                 `json:"name"`
		Settings *map[string]interface{} `json:"settings"`
		IsActive *bool                   `json:"is_active"`
	}

	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid request body",
		})
	}

	if req.Name != nil {
		cfg.Name = *req.Name
	}
	if req.Settings != nil {
		cfg.Settings = *req.Settings
		cfg.ConfigURL = h.generateConfigURL(cfg.Protocol, cfg.UserID.String(), cfg.Settings)
	}
	if req.IsActive != nil {
		cfg.IsActive = *req.IsActive
	}

	if err := h.db.UpdateConfig(cfg); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to update config",
		})
	}

	return c.JSON(cfg)
}

func (h *ConfigHandler) DeleteConfig(c *fiber.Ctx) error {
	id := c.Params("id")
	userID := c.Locals("user_id").(string)
	isAdmin := c.Locals("is_admin").(bool)

	cfg, err := h.db.GetConfigByID(id)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Config not found",
		})
	}

	if cfg.UserID.String() != userID && !isAdmin {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "Access denied",
		})
	}

	if err := h.db.DeleteConfig(id); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to delete config",
		})
	}

	return c.JSON(fiber.Map{
		"message": "Config deleted successfully",
	})
}

func (h *ConfigHandler) GetQRCode(c *fiber.Ctx) error {
	id := c.Params("id")
	userID := c.Locals("user_id").(string)
	isAdmin := c.Locals("is_admin").(bool)

	cfg, err := h.db.GetConfigByID(id)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Config not found",
		})
	}

	if cfg.UserID.String() != userID && !isAdmin {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "Access denied",
		})
	}

	// TODO: Generate actual QR code image
	// For now, return the config URL
	return c.JSON(fiber.Map{
		"config_url": cfg.ConfigURL,
		"qr_code":    "data:image/png;base64,..." + cfg.ConfigURL,
	})
}

func (h *ConfigHandler) ExportConfig(c *fiber.Ctx) error {
	id := c.Params("id")
	userID := c.Locals("user_id").(string)
	isAdmin := c.Locals("is_admin").(bool)

	cfg, err := h.db.GetConfigByID(id)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Config not found",
		})
	}

	if cfg.UserID.String() != userID && !isAdmin {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "Access denied",
		})
	}

	format := c.Query("format", "json")

	switch format {
	case "json":
		return c.JSON(cfg)
	case "url":
		return c.SendString(cfg.ConfigURL)
	case "clash":
		// TODO: Generate Clash config
		return c.JSON(fiber.Map{
			"error": "Clash format not yet implemented",
		})
	default:
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid format",
		})
	}
}

func (h *ConfigHandler) generateConfigURL(protocol, userID string, settings map[string]interface{}) string {
	// This is a simplified version. In production, you'd generate proper protocol URLs
	switch protocol {
	case "reality":
		return h.generateREALITYURL(userID, settings)
	case "hysteria":
		return h.generateHysteriaURL(userID, settings)
	case "trojan":
		return h.generateTrojanURL(userID, settings)
	case "vmess":
		return h.generateVMessURL(userID, settings)
	case "naive":
		return h.generateNaiveURL(userID, settings)
	default:
		return ""
	}
}

func (h *ConfigHandler) generateREALITYURL(userID string, settings map[string]interface{}) string {
	// VLESS+REALITY URL format
	// vless://uuid@server:port?security=reality&sni=example.com&fp=chrome&pbk=publickey&sid=shortid&type=tcp&flow=xtls-rprx-vision#name
	
	config := map[string]interface{}{
		"protocol": "vless",
		"uuid":     userID,
		"server":   "your-server.com",
		"port":     443,
		"security": "reality",
		"sni":      "www.microsoft.com",
		"fp":       "chrome",
		"type":     "tcp",
		"flow":     "xtls-rprx-vision",
	}
	
	configJSON, _ := json.Marshal(config)
	return "vless://" + base64.StdEncoding.EncodeToString(configJSON)
}

func (h *ConfigHandler) generateHysteriaURL(userID string, settings map[string]interface{}) string {
	// Hysteria2 URL format
	// hysteria2://password@server:port?sni=example.com&obfs=salamander&obfs-password=pass#name
	
	return fmt.Sprintf("hysteria2://%s@your-server.com:%s?sni=your-server.com&obfs=salamander#Hysteria2",
		userID, h.cfg.Hysteria.Port)
}

func (h *ConfigHandler) generateTrojanURL(userID string, settings map[string]interface{}) string {
	// Trojan URL format
	// trojan://password@server:port?sni=example.com&type=tcp#name
	
	return fmt.Sprintf("trojan://%s@your-server.com:8444?sni=your-server.com&type=tcp#Trojan", userID)
}

func (h *ConfigHandler) generateVMessURL(userID string, settings map[string]interface{}) string {
	// VMess URL format (base64 encoded JSON)
	config := map[string]interface{}{
		"v":    "2",
		"ps":   "VMess",
		"add":  "your-server.com",
		"port": "8443",
		"id":   userID,
		"aid":  "0",
		"net":  "tcp",
		"type": "none",
		"host": "",
		"path": "",
		"tls":  "tls",
	}
	
	configJSON, _ := json.Marshal(config)
	return "vmess://" + base64.StdEncoding.EncodeToString(configJSON)
}

func (h *ConfigHandler) generateNaiveURL(userID string, settings map[string]interface{}) string {
	// Naive Proxy URL format
	// https://username:password@server:port
	
	return fmt.Sprintf("https://%s:password@your-server.com:443", userID)
}
