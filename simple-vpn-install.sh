#!/bin/bash

# Simple VPN Shield Installation Script
# Installs Xray with REALITY protocol and generates connection link

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "Этот скрипт должен быть запущен от root"
   exit 1
fi

print_info "🚀 Установка VPN Shield (простая версия)"
echo ""

# Get server IP
SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || curl -s ipinfo.io/ip)
print_info "IP сервера: $SERVER_IP"

# Update system
print_info "Обновление системы..."
apt-get update -qq > /dev/null 2>&1
apt-get install -y curl wget unzip qrencode > /dev/null 2>&1
print_success "Система обновлена"

# Install Xray
print_info "Установка Xray-core..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
print_success "Xray установлен"

# Generate keys
print_info "Генерация ключей..."
UUID=$(cat /proc/sys/kernel/random/uuid)
SHORT_ID=$(openssl rand -hex 8)

# Generate X25519 keys
KEYS_OUTPUT=$(/usr/local/bin/xray x25519 2>&1)
PRIVATE_KEY=$(echo "$KEYS_OUTPUT" | grep -oP 'Private key: \K[A-Za-z0-9_-]+')
PUBLIC_KEY=$(echo "$KEYS_OUTPUT" | grep -oP 'Public key: \K[A-Za-z0-9_-]+')

if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then
    print_error "Не удалось сгенерировать ключи"
    echo "Вывод xray x25519:"
    echo "$KEYS_OUTPUT"
    exit 1
fi

print_success "Ключи сгенерированы"
print_info "Private: $PRIVATE_KEY"
print_info "Public: $PUBLIC_KEY"

# Create Xray config
print_info "Создание конфигурации..."
cat > /usr/local/etc/xray/config.json <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.microsoft.com:443",
          "xver": 0,
          "serverNames": [
            "www.microsoft.com",
            "www.bing.com"
          ],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [
            "$SHORT_ID"
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ]
}
EOF

print_success "Конфигурация создана"

# Enable and start Xray
print_info "Запуск Xray..."
systemctl enable xray > /dev/null 2>&1
systemctl restart xray
sleep 2

if systemctl is-active --quiet xray; then
    print_success "Xray запущен"
else
    print_error "Ошибка запуска Xray"
    exit 1
fi

# Configure firewall
print_info "Настройка firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 443/tcp > /dev/null 2>&1
    print_success "Firewall настроен"
fi

# Generate connection link
VLESS_LINK="vless://${UUID}@${SERVER_IP}:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&type=tcp&headerType=none#VPN-Shield"

# Save to file
mkdir -p /root/vpn-shield
echo "$VLESS_LINK" > /root/vpn-shield/connection.txt
echo "$UUID" > /root/vpn-shield/uuid.txt
echo "$PUBLIC_KEY" > /root/vpn-shield/public_key.txt
echo "$SHORT_ID" > /root/vpn-shield/short_id.txt

# Generate QR code
qrencode -t ANSIUTF8 "$VLESS_LINK" > /root/vpn-shield/qr.txt

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_success "🎉 VPN Shield установлен и запущен!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_info "📱 ССЫЛКА ДЛЯ ПОДКЛЮЧЕНИЯ:"
echo ""
echo -e "${GREEN}${VLESS_LINK}${NC}"
echo ""
print_info "📋 Скопируйте эту ссылку в приложение:"
echo ""
echo "  iOS:     Shadowrocket, V2Box"
echo "  Android: v2rayNG, NekoBox"
echo "  Windows: v2rayN, Nekoray"
echo "  macOS:   V2rayU, Qv2ray"
echo ""
print_info "📁 Файлы сохранены в: /root/vpn-shield/"
echo ""
print_info "🔄 Управление:"
echo "  Статус:      systemctl status xray"
echo "  Перезапуск:  systemctl restart xray"
echo "  Логи:        journalctl -u xray -f"
echo ""
print_info "📊 QR-код:"
cat /root/vpn-shield/qr.txt
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_success "✅ Готово! Просто скопируйте ссылку выше в VPN приложение"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
