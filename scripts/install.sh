#!/bin/bash

# VPN Shield Installation Script
# This script installs and configures VPN Shield on a fresh server

set -e

echo "================================"
echo "VPN Shield Installation Script"
echo "================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo "Cannot detect OS. This script supports Ubuntu/Debian only."
    exit 1
fi

echo "Detected OS: $OS $VERSION"
echo ""

# Update system
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install dependencies
echo "Installing dependencies..."
apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    ufw \
    fail2ban

# Install Docker
echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
    echo "✅ Docker installed"
else
    echo "✅ Docker already installed"
fi

# Install Docker Compose
echo "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose installed"
else
    echo "✅ Docker Compose already installed"
fi

# Configure firewall
echo "Configuring firewall..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp      # SSH
ufw allow 80/tcp      # HTTP
ufw allow 443/tcp     # HTTPS (REALITY)
ufw allow 8443/tcp    # VMess
ufw allow 8444/tcp    # Trojan
ufw allow 8888/tcp    # Admin Panel
ufw allow 36712/udp   # Hysteria2
echo "✅ Firewall configured"

# Enable BBR
echo "Enabling BBR congestion control..."
if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
    echo "✅ BBR enabled"
else
    echo "✅ BBR already enabled"
fi

# Optimize network settings
echo "Optimizing network settings..."
cat >> /etc/sysctl.conf <<EOF
# VPN Shield Network Optimizations
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_mtu_probing=1
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.core.netdev_max_backlog=250000
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_max_tw_buckets=2000000
EOF
sysctl -p
echo "✅ Network settings optimized"

# Create installation directory
INSTALL_DIR="/opt/vpn-shield"
echo "Creating installation directory: $INSTALL_DIR"
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# Download VPN Shield
echo "Downloading VPN Shield..."
# TODO: Replace with actual repository URL
# git clone https://github.com/yourusername/vpn-shield.git .
echo "⚠️  Please manually copy VPN Shield files to $INSTALL_DIR"

# Generate random passwords
DB_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 48)
ADMIN_PASSWORD=$(openssl rand -base64 16)

# Create .env file
echo "Creating .env file..."
cat > .env <<EOF
# Database
DB_PASSWORD=$DB_PASSWORD
DB_NAME=vpnshield
DB_USER=vpnshield

# Redis
REDIS_PASSWORD=$REDIS_PASSWORD

# JWT
JWT_SECRET=$JWT_SECRET

# Admin credentials
ADMIN_USERNAME=admin
ADMIN_PASSWORD=$ADMIN_PASSWORD
ADMIN_EMAIL=admin@example.com

# Server configuration
SERVER_PORT=8080
SERVER_HOST=0.0.0.0

# Domain configuration (CHANGE THESE!)
DOMAIN=your-domain.com
PANEL_DOMAIN=panel.your-domain.com

# Hysteria2 configuration
HYSTERIA_PORT=36712
HYSTERIA_OBFS_PASSWORD=$(openssl rand -base64 16)

# Monitoring
ENABLE_METRICS=true
METRICS_PORT=9090

# Logging
LOG_LEVEL=info
LOG_FILE=/var/log/vpn-shield/app.log
EOF

echo "✅ .env file created"

# Save credentials
echo ""
echo "================================"
echo "IMPORTANT: Save these credentials!"
echo "================================"
echo "Admin Username: admin"
echo "Admin Password: $ADMIN_PASSWORD"
echo "Database Password: $DB_PASSWORD"
echo "Redis Password: $REDIS_PASSWORD"
echo ""
echo "These credentials have been saved to: $INSTALL_DIR/.env"
echo "================================"
echo ""

# Create log directory
mkdir -p /var/log/vpn-shield

echo ""
echo "================================"
echo "Installation Complete!"
echo "================================"
echo ""
echo "Next steps:"
echo "1. Edit $INSTALL_DIR/.env and set your domain"
echo "2. Generate SSL certificates (use certbot or self-signed)"
echo "3. Run: cd $INSTALL_DIR && docker-compose up -d"
echo "4. Access admin panel at: http://your-server-ip:8888"
echo ""
echo "For SSL certificates with Let's Encrypt:"
echo "  apt-get install certbot"
echo "  certbot certonly --standalone -d your-domain.com"
echo ""
