package hysteria

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/vpn-shield/backend/internal/config"
	"gopkg.in/yaml.v3"
)

type Manager struct {
	cfg        *config.Config
	configPath string
	binaryPath string
	cmd        *exec.Cmd
}

type HysteriaConfig struct {
	Server    ServerConfig    `yaml:"server"`
	TLS       TLSConfig       `yaml:"tls"`
	Auth      AuthConfig      `yaml:"auth"`
	Masquerade MasqueradeConfig `yaml:"masquerade"`
	QUIC      QUICConfig      `yaml:"quic"`
	Bandwidth BandwidthConfig `yaml:"bandwidth"`
	ACL       ACLConfig       `yaml:"acl"`
	Outbounds []OutboundConfig `yaml:"outbounds"`
}

type ServerConfig struct {
	Listen string `yaml:"listen"`
}

type TLSConfig struct {
	Cert string `yaml:"cert"`
	Key  string `yaml:"key"`
}

type AuthConfig struct {
	Type     string            `yaml:"type"`
	Password string            `yaml:"password,omitempty"`
	Users    map[string]string `yaml:"users,omitempty"`
}

type MasqueradeConfig struct {
	Type  string      `yaml:"type"`
	Proxy ProxyConfig `yaml:"proxy"`
}

type ProxyConfig struct {
	URL         string `yaml:"url"`
	RewriteHost bool   `yaml:"rewriteHost"`
}

type QUICConfig struct {
	InitStreamReceiveWindow  int    `yaml:"initStreamReceiveWindow"`
	MaxStreamReceiveWindow   int    `yaml:"maxStreamReceiveWindow"`
	InitConnReceiveWindow    int    `yaml:"initConnReceiveWindow"`
	MaxConnReceiveWindow     int    `yaml:"maxConnReceiveWindow"`
	MaxIdleTimeout           string `yaml:"maxIdleTimeout"`
	MaxIncomingStreams       int    `yaml:"maxIncomingStreams"`
	DisablePathMTUDiscovery  bool   `yaml:"disablePathMTUDiscovery"`
}

type BandwidthConfig struct {
	Up   string `yaml:"up"`
	Down string `yaml:"down"`
}

type ACLConfig struct {
	Inline []string `yaml:"inline"`
}

type OutboundConfig struct {
	Name string `yaml:"name"`
	Type string `yaml:"type"`
}

func NewManager(cfg *config.Config) *Manager {
	return &Manager{
		cfg:        cfg,
		configPath: filepath.Join(cfg.Hysteria.ConfigPath, "config.yaml"),
		binaryPath: cfg.Hysteria.BinaryPath,
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

	// Start Hysteria
	m.cmd = exec.Command(m.binaryPath, "server", "-c", m.configPath)
	m.cmd.Stdout = os.Stdout
	m.cmd.Stderr = os.Stderr

	if err := m.cmd.Start(); err != nil {
		return fmt.Errorf("failed to start hysteria: %w", err)
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
	config := HysteriaConfig{
		Server: ServerConfig{
			Listen: fmt.Sprintf(":%s", m.cfg.Hysteria.Port),
		},
		TLS: TLSConfig{
			Cert: "/etc/hysteria/cert.pem",
			Key:  "/etc/hysteria/key.pem",
		},
		Auth: AuthConfig{
			Type:  "userpass",
			Users: make(map[string]string),
		},
		Masquerade: MasqueradeConfig{
			Type: "proxy",
			Proxy: ProxyConfig{
				URL:         "https://www.bing.com",
				RewriteHost: true,
			},
		},
		QUIC: QUICConfig{
			InitStreamReceiveWindow:  8388608,
			MaxStreamReceiveWindow:   8388608,
			InitConnReceiveWindow:    20971520,
			MaxConnReceiveWindow:     20971520,
			MaxIdleTimeout:           "30s",
			MaxIncomingStreams:       1024,
			DisablePathMTUDiscovery:  false,
		},
		Bandwidth: BandwidthConfig{
			Up:   "1 gbps",
			Down: "1 gbps",
		},
		ACL: ACLConfig{
			Inline: []string{
				"reject(geoip:private)",
			},
		},
		Outbounds: []OutboundConfig{
			{
				Name: "direct",
				Type: "direct",
			},
			{
				Name: "block",
				Type: "block",
			},
		},
	}

	data, err := yaml.Marshal(config)
	if err != nil {
		return err
	}

	return os.WriteFile(m.configPath, data, 0644)
}

func (m *Manager) AddUser(username, password string) error {
	// Read current config
	data, err := os.ReadFile(m.configPath)
	if err != nil {
		return err
	}

	var config HysteriaConfig
	if err := yaml.Unmarshal(data, &config); err != nil {
		return err
	}

	// Add user
	if config.Auth.Users == nil {
		config.Auth.Users = make(map[string]string)
	}
	config.Auth.Users[username] = password

	// Write updated config
	data, err = yaml.Marshal(config)
	if err != nil {
		return err
	}

	if err := os.WriteFile(m.configPath, data, 0644); err != nil {
		return err
	}

	// Restart Hysteria to apply changes
	return m.Restart()
}

func (m *Manager) RemoveUser(username string) error {
	// Read current config
	data, err := os.ReadFile(m.configPath)
	if err != nil {
		return err
	}

	var config HysteriaConfig
	if err := yaml.Unmarshal(data, &config); err != nil {
		return err
	}

	// Remove user
	delete(config.Auth.Users, username)

	// Write updated config
	data, err = yaml.Marshal(config)
	if err != nil {
		return err
	}

	if err := os.WriteFile(m.configPath, data, 0644); err != nil {
		return err
	}

	// Restart Hysteria to apply changes
	return m.Restart()
}

func (m *Manager) GetStats() (map[string]interface{}, error) {
	// TODO: Implement stats collection from Hysteria API
	return map[string]interface{}{
		"status":  "running",
		"version": "2.0.0",
		"users":   0,
	}, nil
}
