package api

import (
	"os/exec"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/vpn-shield/backend/internal/config"
	"github.com/vpn-shield/backend/internal/db"
)

type ProtocolHandler struct {
	db  *db.Database
	cfg *config.Config
}

func NewProtocolHandler(database *db.Database, cfg *config.Config) *ProtocolHandler {
	return &ProtocolHandler{
		db:  database,
		cfg: cfg,
	}
}

func (h *ProtocolHandler) GetXrayStatus(c *fiber.Ctx) error {
	// Check if Xray process is running
	cmd := exec.Command("pgrep", "-f", "xray")
	output, err := cmd.Output()
	
	status := "stopped"
	if err == nil && len(output) > 0 {
		status = "running"
	}
	
	// Try to get version
	version := "unknown"
	versionCmd := exec.Command(h.cfg.Xray.BinaryPath, "version")
	if versionOutput, err := versionCmd.Output(); err == nil {
		lines := strings.Split(string(versionOutput), "\n")
		if len(lines) > 0 {
			version = strings.TrimSpace(lines[0])
		}
	}
	
	return c.JSON(fiber.Map{
		"status":  status,
		"version": version,
		"uptime":  "N/A", // Would require tracking start time
	})
}

func (h *ProtocolHandler) RestartXray(c *fiber.Ctx) error {
	// Kill existing Xray process
	killCmd := exec.Command("pkill", "-f", "xray")
	_ = killCmd.Run() // Ignore error if process not found
	
	// Wait a moment for process to stop
	time.Sleep(500 * time.Millisecond)
	
	// Start Xray in background
	// Note: In production, this should use systemd or supervisor
	startCmd := exec.Command(h.cfg.Xray.BinaryPath, "run", "-c", h.cfg.Xray.ConfigPath+"/config.json")
	if err := startCmd.Start(); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to restart Xray: " + err.Error(),
		})
	}
	
	return c.JSON(fiber.Map{
		"message": "Xray restarted successfully",
	})
}

func (h *ProtocolHandler) GetHysteriaStatus(c *fiber.Ctx) error {
	// Check if Hysteria process is running
	cmd := exec.Command("pgrep", "-f", "hysteria")
	output, err := cmd.Output()
	
	status := "stopped"
	if err == nil && len(output) > 0 {
		status = "running"
	}
	
	// Try to get version
	version := "unknown"
	versionCmd := exec.Command(h.cfg.Hysteria.BinaryPath, "version")
	if versionOutput, err := versionCmd.Output(); err == nil {
		version = strings.TrimSpace(string(versionOutput))
	}
	
	return c.JSON(fiber.Map{
		"status":  status,
		"version": version,
		"uptime":  "N/A", // Would require tracking start time
	})
}

func (h *ProtocolHandler) RestartHysteria(c *fiber.Ctx) error {
	// Kill existing Hysteria process
	killCmd := exec.Command("pkill", "-f", "hysteria")
	_ = killCmd.Run() // Ignore error if process not found
	
	// Wait a moment for process to stop
	time.Sleep(500 * time.Millisecond)
	
	// Start Hysteria in background
	// Note: In production, this should use systemd or supervisor
	startCmd := exec.Command(h.cfg.Hysteria.BinaryPath, "server", "-c", h.cfg.Hysteria.ConfigPath+"/config.yaml")
	if err := startCmd.Start(); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to restart Hysteria: " + err.Error(),
		})
	}
	
	return c.JSON(fiber.Map{
		"message": "Hysteria restarted successfully",
	})
}

func (h *ProtocolHandler) TestProtocols(c *fiber.Ctx) error {
	// Test protocol availability by checking if processes are running
	results := make(map[string]bool)
	
	// Test Xray-based protocols (REALITY, Trojan, VMess)
	xrayCmd := exec.Command("pgrep", "-f", "xray")
	xrayOutput, xrayErr := xrayCmd.Output()
	xrayRunning := xrayErr == nil && len(xrayOutput) > 0
	
	results["reality"] = xrayRunning
	results["trojan"] = xrayRunning
	results["vmess"] = xrayRunning
	
	// Test Hysteria
	hysteriaCmd := exec.Command("pgrep", "-f", "hysteria")
	hysteriaOutput, hysteriaErr := hysteriaCmd.Output()
	results["hysteria"] = hysteriaErr == nil && len(hysteriaOutput) > 0
	
	// Naive is typically disabled
	results["naive"] = false
	
	return c.JSON(results)
}
