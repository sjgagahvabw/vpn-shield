package core

import (
	"fmt"
	"log"

	"github.com/vpn-shield/backend/internal/config"
	"github.com/vpn-shield/backend/internal/hysteria"
	"github.com/vpn-shield/backend/internal/xray"
)

// Core manages all VPN protocols
type Core struct {
	cfg             *config.Config
	xrayManager     *xray.Manager
	hysteriaManager *hysteria.Manager
}

func NewCore(cfg *config.Config) *Core {
	return &Core{
		cfg:             cfg,
		xrayManager:     xray.NewManager(cfg),
		hysteriaManager: hysteria.NewManager(cfg),
	}
}

func (c *Core) Start() error {
	log.Println("Starting VPN Shield Core...")

	// Start Xray
	log.Println("Starting Xray-core...")
	if err := c.xrayManager.Start(); err != nil {
		return fmt.Errorf("failed to start xray: %w", err)
	}
	log.Println("✅ Xray-core started")

	// Start Hysteria
	log.Println("Starting Hysteria2...")
	if err := c.hysteriaManager.Start(); err != nil {
		return fmt.Errorf("failed to start hysteria: %w", err)
	}
	log.Println("✅ Hysteria2 started")

	log.Println("✅ VPN Shield Core started successfully")
	return nil
}

func (c *Core) Stop() error {
	log.Println("Stopping VPN Shield Core...")

	if err := c.xrayManager.Stop(); err != nil {
		log.Printf("Error stopping xray: %v", err)
	}

	if err := c.hysteriaManager.Stop(); err != nil {
		log.Printf("Error stopping hysteria: %v", err)
	}

	log.Println("✅ VPN Shield Core stopped")
	return nil
}

func (c *Core) AddUser(userID, email, protocol string) error {
	switch protocol {
	case "reality", "vmess", "trojan", "vless":
		return c.xrayManager.AddUser(userID, email, protocol)
	case "hysteria":
		return c.hysteriaManager.AddUser(userID, email)
	default:
		return fmt.Errorf("unsupported protocol: %s", protocol)
	}
}

func (c *Core) RemoveUser(userID, protocol string) error {
	switch protocol {
	case "reality", "vmess", "trojan", "vless":
		return c.xrayManager.RemoveUser(userID, protocol)
	case "hysteria":
		return c.hysteriaManager.RemoveUser(userID)
	default:
		return fmt.Errorf("unsupported protocol: %s", protocol)
	}
}

func (c *Core) GetXrayManager() *xray.Manager {
	return c.xrayManager
}

func (c *Core) GetHysteriaManager() *hysteria.Manager {
	return c.hysteriaManager
}
