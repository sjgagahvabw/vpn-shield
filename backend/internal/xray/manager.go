package xray

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/google/uuid"
	"github.com/vpn-shield/backend/internal/config"
)

type Manager struct {
	cfg        *config.Config
	configPath string
	binaryPath string
	cmd        *exec.Cmd
}

type XrayConfig struct {
	Log       LogConfig       `json:"log"`
	Inbounds  []Inbound       `json:"inbounds"`
	Outbounds []Outbound      `json:"outbounds"`
	Routing   RoutingConfig   `json:"routing"`
}

type LogConfig struct {
	LogLevel string `json:"loglevel"`
}

type Inbound struct {
	Tag            string                 `json:"tag"`
	Port           int                    `json:"port"`
	Protocol       string                 `json:"protocol"`
	Settings       map[string]interface{} `json:"settings"`
	StreamSettings map[string]interface{} `json:"streamSettings"`
	Sniffing       map[string]interface{} `json:"sniffing"`
}

type Outbound struct {
	Protocol string `json:"protocol"`
	Tag      string `json:"tag"`
}

type RoutingConfig struct {
	DomainStrategy string        `json:"domainStrategy"`
	Rules          []RoutingRule `json:"rules"`
}

type RoutingRule struct {
	Type        string   `json:"type"`
	IP          []string `json:"ip,omitempty"`
	OutboundTag string   `json:"outboundTag"`
}

type Client struct {
	ID    string `json:"id"`
	Email string `json:"email"`
	Flow  string `json:"flow,omitempty"`
}

func NewManager(cfg *config.Config) *Manager {
	return &Manager{
		cfg:        cfg,
		configPath: filepath.Join(cfg.Xray.ConfigPath, "config.json"),
		binaryPath: cfg.Xray.BinaryPath,
	}
}

func (m *Manager) Start() error {
	// Check if config exists
	if _, err := os.Stat(m.configPath); os.IsNotExist(err) {
		// Create default config
		if err := m.CreateDefaultConfig(); err != nil {
			return fmt.Errorf("failed to create default config: %w", err)
		}
	}

	// Start Xray
	m.cmd = exec.Command(m.binaryPath, "run", "-config", m.configPath)
	m.cmd.Stdout = os.Stdout
	m.cmd.Stderr = os.Stderr

	if err := m.cmd.Start(); err != nil {
		return fmt.Errorf("failed to start xray: %w", err)
	}

	return nil
}

func (m *Manager) Stop() error {
	if m.cmd != nil && m.cmd.Process != nil {
		return m.cmd.Process.Kill()
	}
	return nil
}

func (m *Manager) Restart() error {
	if err := m.Stop(); err != nil {
		return err
	}
	return m.Start()
}

func (m *Manager) CreateDefaultConfig() error {
	config := XrayConfig{
		Log: LogConfig{
			LogLevel: "warning",
		},
		Inbounds: []Inbound{
			{
				Tag:      "vless-reality",
				Port:     443,
				Protocol: "vless",
				Settings: map[string]interface{}{
					"clients":    []Client{},
					"decryption": "none",
				},
				StreamSettings: map[string]interface{}{
					"network":  "tcp",
					"security": "reality",
					"realitySettings": map[string]interface{}{
						"show": false,
						"dest": "www.microsoft.com:443",
						"xver": 0,
						"serverNames": []string{
							"www.microsoft.com",
							"www.bing.com",
						},
						"privateKey": "GENERATE_WITH_XRAY_X25519",
						"shortIds": []string{
							"",
							"0123456789abcdef",
						},
					},
				},
				Sniffing: map[string]interface{}{
					"enabled": true,
					"destOverride": []string{
						"http",
						"tls",
					},
				},
			},
		},
		Outbounds: []Outbound{
			{
				Protocol: "freedom",
				Tag:      "direct",
			},
			{
				Protocol: "blackhole",
				Tag:      "block",
			},
		},
		Routing: RoutingConfig{
			DomainStrategy: "IPIfNonMatch",
			Rules: []RoutingRule{
				{
					Type:        "field",
					IP:          []string{"geoip:private"},
					OutboundTag: "block",
				},
			},
		},
	}

	data, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(m.configPath, data, 0644)
}

func (m *Manager) AddUser(userID, email, protocol string) error {
	// Read current config
	data, err := os.ReadFile(m.configPath)
	if err != nil {
		return err
	}

	var config XrayConfig
	if err := json.Unmarshal(data, &config); err != nil {
		return err
	}

	// Find the inbound for the protocol
	for i, inbound := range config.Inbounds {
		if inbound.Protocol == protocol {
			clients, ok := inbound.Settings["clients"].([]interface{})
			if !ok {
				clients = []interface{}{}
			}

			// Add new client
			newClient := map[string]interface{}{
				"id":    userID,
				"email": email,
			}

			if protocol == "vless" {
				newClient["flow"] = "xtls-rprx-vision"
			}

			clients = append(clients, newClient)
			config.Inbounds[i].Settings["clients"] = clients
			break
		}
	}

	// Write updated config
	data, err = json.MarshalIndent(config, "", "  ")
	if err != nil {
		return err
	}

	if err := os.WriteFile(m.configPath, data, 0644); err != nil {
		return err
	}

	// Restart Xray to apply changes
	return m.Restart()
}

func (m *Manager) RemoveUser(userID, protocol string) error {
	// Read current config
	data, err := os.ReadFile(m.configPath)
	if err != nil {
		return err
	}

	var config XrayConfig
	if err := json.Unmarshal(data, &config); err != nil {
		return err
	}

	// Find and remove user from the protocol
	for i, inbound := range config.Inbounds {
		if inbound.Protocol == protocol {
			clients, ok := inbound.Settings["clients"].([]interface{})
			if !ok {
				continue
			}

			// Filter out the user
			newClients := []interface{}{}
			for _, client := range clients {
				clientMap, ok := client.(map[string]interface{})
				if !ok {
					continue
				}
				if clientMap["id"] != userID {
					newClients = append(newClients, client)
				}
			}

			config.Inbounds[i].Settings["clients"] = newClients
			break
		}
	}

	// Write updated config
	data, err = json.MarshalIndent(config, "", "  ")
	if err != nil {
		return err
	}

	if err := os.WriteFile(m.configPath, data, 0644); err != nil {
		return err
	}

	// Restart Xray to apply changes
	return m.Restart()
}

func (m *Manager) GetStats() (map[string]interface{}, error) {
	// TODO: Implement stats collection from Xray API
	return map[string]interface{}{
		"status":  "running",
		"version": "1.8.0",
		"users":   0,
	}, nil
}

func (m *Manager) GenerateKeys() (privateKey, publicKey string, err error) {
	// Generate X25519 key pair using xray command
	cmd := exec.Command(m.binaryPath, "x25519")
	output, err := cmd.Output()
	if err != nil {
		return "", "", err
	}

	// Parse output to extract keys
	// Format: Private key: xxx\nPublic key: yyy
	lines := string(output)
	// TODO: Parse the output properly
	
	return "private_key_placeholder", "public_key_placeholder", nil
}
