#!/bin/bash

#############################################
# VPN Shield - Добавление Shadowsocks 2022
# Современный протокол с отличной производительностью
#############################################

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

XRAY_CONFIG="/usr/local/etc/xray/config.json"
INFO_FILE="/root/vpn-shield/info.txt"

echo -e "${BLUE}Добавление Shadowsocks 2022 в конфигурацию...${NC}"

# Проверяем наличие Xray
if [ ! -f "/usr/local/bin/xray" ]; then
    echo -e "${RED}✗ Xray не установлен!${NC}"
    exit 1
fi

# Генерируем пароль для Shadowsocks 2022 (base64, 32 байта)
SS_PASSWORD=$(openssl rand -base64 32)

echo -e "${YELLOW}Генерация пароля Shadowsocks...${NC}"
echo "Пароль: $SS_PASSWORD"

# Проверяем существующий конфиг
if [ ! -f "$XRAY_CONFIG" ]; then
    echo -e "${RED}✗ Конфиг Xray не найден: $XRAY_CONFIG${NC}"
    exit 1
fi

# Создаем резервную копию
cp "$XRAY_CONFIG" "${XRAY_CONFIG}.backup.$(date +%s)"

# Добавляем Shadowsocks inbound
echo -e "${YELLOW}Добавление Shadowsocks в конфигурацию...${NC}"

jq --arg password "$SS_PASSWORD" \
   '.inbounds += [{
     "tag": "shadowsocks-2022",
     "port": 8388,
     "protocol": "shadowsocks",
     "settings": {
       "method": "2022-blake3-aes-256-gcm",
       "password": $password,
       "network": "tcp,udp"
     },
     "streamSettings": {
       "network": "tcp",
       "security": "none"
     },
     "sniffing": {
       "enabled": true,
       "destOverride": ["http", "tls"]
     }
   }]' "$XRAY_CONFIG" > "${XRAY_CONFIG}.tmp"

if [ $? -eq 0 ]; then
    mv "${XRAY_CONFIG}.tmp" "$XRAY_CONFIG"
    echo -e "${GREEN}✓ Shadowsocks добавлен в конфигурацию${NC}"
else
    echo -e "${RED}✗ Ошибка обновления конфигурации${NC}"
    rm -f "${XRAY_CONFIG}.tmp"
    exit 1
fi

# Открываем порт в firewall
if command -v ufw &> /dev/null; then
    echo -e "${YELLOW}Открытие порта 8388 в firewall...${NC}"
    ufw allow 8388/tcp
    ufw allow 8388/udp
fi

# Перезапускаем Xray
echo -e "${YELLOW}Перезапуск Xray...${NC}"
systemctl restart xray
sleep 3

if systemctl is-active --quiet xray; then
    echo -e "${GREEN}✓ Xray успешно перезапущен${NC}"
else
    echo -e "${RED}✗ Ошибка перезапуска Xray${NC}"
    exit 1
fi

# Проверяем порт
if ss -tuln | grep -q ":8388 "; then
    echo -e "${GREEN}✓ Shadowsocks работает на порту 8388${NC}"
else
    echo -e "${RED}✗ Порт 8388 не слушается${NC}"
    exit 1
fi

# Обновляем info.txt
if [ -f "$INFO_FILE" ]; then
    echo "" >> "$INFO_FILE"
    echo "=== Shadowsocks 2022 ===" >> "$INFO_FILE"
    echo "Port: 8388" >> "$INFO_FILE"
    echo "Method: 2022-blake3-aes-256-gcm" >> "$INFO_FILE"
    echo "Password: $SS_PASSWORD" >> "$INFO_FILE"
fi

# Получаем IP сервера
SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || echo "YOUR_SERVER_IP")

# Генерируем ссылку Shadowsocks
SS_LINK="ss://$(echo -n "2022-blake3-aes-256-gcm:${SS_PASSWORD}" | base64 -w 0)@${SERVER_IP}:8388#VPN-Shield-Shadowsocks"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Shadowsocks 2022 успешно установлен!              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Параметры подключения:${NC}"
echo -e "  Сервер:  ${GREEN}${SERVER_IP}${NC}"
echo -e "  Порт:    ${GREEN}8388${NC}"
echo -e "  Метод:   ${GREEN}2022-blake3-aes-256-gcm${NC}"
echo -e "  Пароль:  ${GREEN}${SS_PASSWORD}${NC}"
echo ""
echo -e "${BLUE}Ссылка для подключения:${NC}"
echo -e "${GREEN}${SS_LINK}${NC}"
echo ""
echo -e "${YELLOW}Преимущества Shadowsocks 2022:${NC}"
echo "  • Современный протокол с улучшенной безопасностью"
echo "  • Отличная производительность"
echo "  • Поддержка UDP (для игр и видеозвонков)"
echo "  • Защита от replay-атак"
echo "  • Низкая задержка"
echo ""
echo -e "${BLUE}Клиенты для подключения:${NC}"
echo "  • Android: Shadowsocks, v2rayNG"
echo "  • iOS: Shadowrocket, Quantumult X"
echo "  • Windows: v2rayN, Clash for Windows"
echo "  • macOS: ClashX, V2RayX"
echo "  • Linux: v2ray-core, Qv2ray"
echo ""
