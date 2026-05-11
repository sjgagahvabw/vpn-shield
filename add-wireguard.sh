#!/bin/bash

#############################################
# VPN Shield - Добавление WireGuard
# Быстрый и современный VPN протокол
#############################################

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

WG_CONFIG_DIR="/etc/wireguard"
WG_CONFIG_FILE="$WG_CONFIG_DIR/wg0.conf"
INFO_FILE="/root/vpn-shield/info.txt"
WG_PORT=51820
WG_INTERFACE="wg0"

echo -e "${BLUE}Установка и настройка WireGuard...${NC}"

# Проверяем root права
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}✗ Запустите скрипт с правами root${NC}"
    exit 1
fi

# Устанавливаем WireGuard
echo -e "${YELLOW}Установка WireGuard...${NC}"
if command -v apt-get &> /dev/null; then
    apt-get update -qq
    apt-get install -y wireguard wireguard-tools qrencode
elif command -v yum &> /dev/null; then
    yum install -y epel-release
    yum install -y wireguard-tools qrencode
else
    echo -e "${RED}✗ Неподдерживаемая система${NC}"
    exit 1
fi

# Создаем директорию для конфигов
mkdir -p "$WG_CONFIG_DIR"
chmod 700 "$WG_CONFIG_DIR"

# Генерируем ключи сервера
echo -e "${YELLOW}Генерация ключей сервера...${NC}"
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey)

# Генерируем ключи клиента
echo -e "${YELLOW}Генерация ключей клиента...${NC}"
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)
CLIENT_PRESHARED_KEY=$(wg genpsk)

# Получаем IP сервера
SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || echo "YOUR_SERVER_IP")

# Определяем сетевой интерфейс
NETWORK_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

# Создаем конфигурацию сервера
echo -e "${YELLOW}Создание конфигурации сервера...${NC}"
cat > "$WG_CONFIG_FILE" <<EOF
[Interface]
Address = 10.66.66.1/24
ListenPort = $WG_PORT
PrivateKey = $SERVER_PRIVATE_KEY
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $NETWORK_INTERFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $NETWORK_INTERFACE -j MASQUERADE

# Client 1
[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
PresharedKey = $CLIENT_PRESHARED_KEY
AllowedIPs = 10.66.66.2/32
EOF

chmod 600 "$WG_CONFIG_FILE"

# Создаем конфигурацию клиента
CLIENT_CONFIG_FILE="/root/vpn-shield/wireguard-client.conf"
cat > "$CLIENT_CONFIG_FILE" <<EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = 10.66.66.2/24
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
PresharedKey = $CLIENT_PRESHARED_KEY
Endpoint = $SERVER_IP:$WG_PORT
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

chmod 600 "$CLIENT_CONFIG_FILE"

# Включаем IP forwarding
echo -e "${YELLOW}Включение IP forwarding...${NC}"
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
sysctl -p

# Открываем порт в firewall
if command -v ufw &> /dev/null; then
    echo -e "${YELLOW}Открытие порта $WG_PORT в firewall...${NC}"
    ufw allow $WG_PORT/udp
fi

# Запускаем WireGuard
echo -e "${YELLOW}Запуск WireGuard...${NC}"
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

sleep 2

# Проверяем статус
if systemctl is-active --quiet wg-quick@wg0; then
    echo -e "${GREEN}✓ WireGuard успешно запущен${NC}"
else
    echo -e "${RED}✗ Ошибка запуска WireGuard${NC}"
    exit 1
fi

# Проверяем интерфейс
if ip link show $WG_INTERFACE &> /dev/null; then
    echo -e "${GREEN}✓ Интерфейс $WG_INTERFACE создан${NC}"
else
    echo -e "${RED}✗ Интерфейс $WG_INTERFACE не создан${NC}"
    exit 1
fi

# Генерируем QR код для мобильных устройств
QR_FILE="/root/vpn-shield/wireguard-qr.txt"
qrencode -t ansiutf8 < "$CLIENT_CONFIG_FILE" > "$QR_FILE"

# Обновляем info.txt
if [ -f "$INFO_FILE" ]; then
    echo "" >> "$INFO_FILE"
    echo "=== WireGuard ===" >> "$INFO_FILE"
    echo "Server IP: $SERVER_IP" >> "$INFO_FILE"
    echo "Port: $WG_PORT" >> "$INFO_FILE"
    echo "Server Public Key: $SERVER_PUBLIC_KEY" >> "$INFO_FILE"
    echo "Client Config: $CLIENT_CONFIG_FILE" >> "$INFO_FILE"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            WireGuard успешно установлен!                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Параметры подключения:${NC}"
echo -e "  Сервер:           ${GREEN}${SERVER_IP}${NC}"
echo -e "  Порт:             ${GREEN}${WG_PORT}${NC}"
echo -e "  Интерфейс:        ${GREEN}${WG_INTERFACE}${NC}"
echo -e "  Сеть клиентов:    ${GREEN}10.66.66.0/24${NC}"
echo ""
echo -e "${BLUE}Файлы конфигурации:${NC}"
echo -e "  Сервер:  ${GREEN}${WG_CONFIG_FILE}${NC}"
echo -e "  Клиент:  ${GREEN}${CLIENT_CONFIG_FILE}${NC}"
echo -e "  QR код:  ${GREEN}${QR_FILE}${NC}"
echo ""
echo -e "${YELLOW}Преимущества WireGuard:${NC}"
echo "  • Самый быстрый VPN протокол"
echo "  • Минимальная задержка (отлично для игр)"
echo "  • Современная криптография (ChaCha20, Curve25519)"
echo "  • Простая настройка"
echo "  • Низкое потребление ресурсов"
echo "  • Встроен в ядро Linux 5.6+"
echo ""
echo -e "${BLUE}QR код для мобильных устройств:${NC}"
cat "$QR_FILE"
echo ""
echo -e "${BLUE}Клиенты для подключения:${NC}"
echo "  • Android: WireGuard (официальное приложение)"
echo "  • iOS: WireGuard (официальное приложение)"
echo "  • Windows: WireGuard (официальный клиент)"
echo "  • macOS: WireGuard (официальный клиент)"
echo "  • Linux: wireguard-tools (встроено)"
echo ""
echo -e "${BLUE}Управление:${NC}"
echo "  Статус:      systemctl status wg-quick@wg0"
echo "  Перезапуск:  systemctl restart wg-quick@wg0"
echo "  Остановка:   systemctl stop wg-quick@wg0"
echo "  Логи:        journalctl -u wg-quick@wg0 -f"
echo "  Пиры:        wg show"
echo ""
echo -e "${YELLOW}Для добавления новых клиентов используйте:${NC}"
echo "  wg genkey | tee client_private.key | wg pubkey > client_public.key"
echo ""
