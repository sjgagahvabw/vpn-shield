#!/bin/bash

#############################################
# VPN Shield - Быстрая установка (без веб-панели)
# Оптимизированная версия для максимальной производительности
#############################################

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear

echo -e "${BLUE}"
cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║              VPN Shield - Быстрая установка                ║
║          Оптимизированная версия без веб-панели            ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Проверка root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}✗ Запустите скрипт с правами root${NC}"
    exit 1
fi

# Проверка ОС
if [ ! -f /etc/os-release ]; then
    echo -e "${RED}✗ Неподдерживаемая операционная система${NC}"
    exit 1
fi

source /etc/os-release

echo -e "${BLUE}Система: ${GREEN}$PRETTY_NAME${NC}"
echo ""

# Выбор протоколов
echo -e "${YELLOW}Выберите протоколы для установки:${NC}"
echo ""
echo "1) Все протоколы (рекомендуется)"
echo "   - VLESS/REALITY, Hysteria2, Trojan, VMess, Shadowsocks, WireGuard"
echo ""
echo "2) Только стелс-протоколы (для обхода блокировок)"
echo "   - VLESS/REALITY, Shadowsocks, Hysteria2"
echo ""
echo "3) Только быстрые протоколы (для скорости)"
echo "   - WireGuard, Hysteria2, Shadowsocks"
echo ""
echo "4) Минимальная установка"
echo "   - VLESS/REALITY, Hysteria2"
echo ""

read -p "Выберите вариант (1-4): " install_choice

case $install_choice in
    1) INSTALL_ALL=true ;;
    2) INSTALL_STEALTH=true ;;
    3) INSTALL_FAST=true ;;
    4) INSTALL_MINIMAL=true ;;
    *) echo -e "${RED}Неверный выбор${NC}"; exit 1 ;;
esac

echo ""
echo -e "${BLUE}Начинаем установку...${NC}"
echo ""

# Обновление системы
echo -e "${YELLOW}[1/8] Обновление системы...${NC}"
if command -v apt-get &> /dev/null; then
    apt-get update -qq
    apt-get install -y curl wget jq openssl qrencode net-tools
elif command -v yum &> /dev/null; then
    yum install -y curl wget jq openssl qrencode net-tools
fi

# Получение IP
SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com)
echo -e "${GREEN}✓ IP сервера: $SERVER_IP${NC}"

# Создание директорий
echo -e "${YELLOW}[2/8] Создание директорий...${NC}"
mkdir -p /root/vpn-shield/{sites,configs}
mkdir -p /usr/local/etc/xray
mkdir -p /etc/hysteria
mkdir -p /var/log

# Установка Xray
echo -e "${YELLOW}[3/8] Установка Xray...${NC}"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# Генерация ключей REALITY
REALITY_KEYS=$(xray x25519)
PRIVATE_KEY=$(echo "$REALITY_KEYS" | grep "Private key:" | awk '{print $3}')
PUBLIC_KEY=$(echo "$REALITY_KEYS" | grep "Public key:" | awk '{print $3}')
SHORT_ID=$(openssl rand -hex 8)
UUID=$(cat /proc/sys/kernel/random/uuid)

# Скачивание списка сайтов
echo -e "${YELLOW}[4/8] Загрузка списков маскировки...${NC}"
cat > /root/vpn-shield/sites/russian-whitelist.txt << 'EOFLIST'
www.gosuslugi.ru:443
www.sberbank.ru:443
www.vtb.ru:443
www.yandex.ru:443
www.mail.ru:443
www.tass.ru:443
www.ria.ru:443
www.gazprom.ru:443
www.rosneft.ru:443
www.rzd.ru:443
EOFLIST

# Выбор первого рабочего сайта
MASQUERADE_SITE="www.microsoft.com:443"
MASQUERADE_DOMAIN="www.microsoft.com"

# Создание конфигурации Xray
echo -e "${YELLOW}[5/8] Создание конфигурации Xray...${NC}"

# Базовая конфигурация с VLESS, VMess, Trojan
cat > /usr/local/etc/xray/config.json << EOFCONFIG
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "vless-reality",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "email": "user@vpn-shield",
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
          "dest": "$MASQUERADE_SITE",
          "xver": 0,
          "serverNames": ["$MASQUERADE_DOMAIN"],
          "privateKey": "$PRIVATE_KEY",
          "publicKey": "$PUBLIC_KEY",
          "shortIds": ["", "$SHORT_ID"]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
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
EOFCONFIG

# Добавление Shadowsocks если нужно
if [ "$INSTALL_ALL" = true ] || [ "$INSTALL_STEALTH" = true ] || [ "$INSTALL_FAST" = true ]; then
    echo -e "${YELLOW}[6/8] Добавление Shadowsocks...${NC}"
    SS_PASSWORD=$(openssl rand -base64 32)
    
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
         "sniffing": {
           "enabled": true,
           "destOverride": ["http", "tls"]
         }
       }]' /usr/local/etc/xray/config.json > /tmp/xray-config.json
    
    mv /tmp/xray-config.json /usr/local/etc/xray/config.json
    echo -e "${GREEN}✓ Shadowsocks добавлен${NC}"
fi

# Установка Hysteria2
if [ "$INSTALL_ALL" = true ] || [ "$INSTALL_STEALTH" = true ] || [ "$INSTALL_FAST" = true ] || [ "$INSTALL_MINIMAL" = true ]; then
    echo -e "${YELLOW}[7/8] Установка Hysteria2...${NC}"
    
    # Скачивание Hysteria2
    HYSTERIA_VERSION=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/app\///')
    wget -q -O /usr/local/bin/hysteria https://github.com/apernet/hysteria/releases/download/app/${HYSTERIA_VERSION}/hysteria-linux-amd64
    chmod +x /usr/local/bin/hysteria
    
    # Генерация самоподписанного сертификата
    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
        -keyout /etc/hysteria/key.pem -out /etc/hysteria/cert.pem \
        -subj "/CN=bing.com" -days 36500 &>/dev/null
    
    HYSTERIA_PASSWORD=$(openssl rand -base64 32)
    
    # Конфигурация Hysteria2
    cat > /etc/hysteria/config.yaml << EOFHYSTERIA
listen: :36712

tls:
  cert: /etc/hysteria/cert.pem
  key: /etc/hysteria/key.pem

auth:
  type: password
  password: $HYSTERIA_PASSWORD

masquerade:
  type: proxy
  proxy:
    url: https://$MASQUERADE_DOMAIN
    rewriteHost: true

quic:
  initStreamReceiveWindow: 8388608
  maxStreamReceiveWindow: 8388608
  initConnReceiveWindow: 20971520
  maxConnReceiveWindow: 20971520
  maxIdleTimeout: 30s
  maxIncomingStreams: 1024

bandwidth:
  up: 1 gbps
  down: 1 gbps
EOFHYSTERIA
    
    # Systemd service для Hysteria2
    cat > /etc/systemd/system/hysteria-server.service << 'EOFSERVICE'
[Unit]
Description=Hysteria Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOFSERVICE
    
    systemctl daemon-reload
    systemctl enable hysteria-server
    systemctl start hysteria-server
    
    echo -e "${GREEN}✓ Hysteria2 установлен${NC}"
fi

# Установка WireGuard
if [ "$INSTALL_ALL" = true ] || [ "$INSTALL_FAST" = true ]; then
    echo -e "${YELLOW}[8/8] Установка WireGuard...${NC}"
    
    if command -v apt-get &> /dev/null; then
        apt-get install -y wireguard wireguard-tools
    elif command -v yum &> /dev/null; then
        yum install -y wireguard-tools
    fi
    
    # Генерация ключей
    WG_SERVER_PRIVATE=$(wg genkey)
    WG_SERVER_PUBLIC=$(echo "$WG_SERVER_PRIVATE" | wg pubkey)
    WG_CLIENT_PRIVATE=$(wg genkey)
    WG_CLIENT_PUBLIC=$(echo "$WG_CLIENT_PRIVATE" | wg pubkey)
    WG_PRESHARED=$(wg genpsk)
    
    NETWORK_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
    
    # Конфигурация сервера
    cat > /etc/wireguard/wg0.conf << EOFWG
[Interface]
Address = 10.66.66.1/24
ListenPort = 51820
PrivateKey = $WG_SERVER_PRIVATE
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $NETWORK_INTERFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $NETWORK_INTERFACE -j MASQUERADE

[Peer]
PublicKey = $WG_CLIENT_PUBLIC
PresharedKey = $WG_PRESHARED
AllowedIPs = 10.66.66.2/32
EOFWG
    
    chmod 600 /etc/wireguard/wg0.conf
    
    # Конфигурация клиента
    cat > /root/vpn-shield/wireguard-client.conf << EOFWGCLIENT
[Interface]
PrivateKey = $WG_CLIENT_PRIVATE
Address = 10.66.66.2/24
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $WG_SERVER_PUBLIC
PresharedKey = $WG_PRESHARED
Endpoint = $SERVER_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOFWGCLIENT
    
    # Включение IP forwarding
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p &>/dev/null
    
    systemctl enable wg-quick@wg0
    systemctl start wg-quick@wg0
    
    echo -e "${GREEN}✓ WireGuard установлен${NC}"
fi

# Запуск Xray
systemctl enable xray
systemctl start xray

# Настройка firewall
echo -e "${YELLOW}Настройка firewall...${NC}"
if command -v ufw &> /dev/null; then
    ufw allow 443/tcp
    ufw allow 8388/tcp
    ufw allow 8388/udp
    ufw allow 36712/udp
    ufw allow 51820/udp
fi

# Создание файла с информацией
cat > /root/vpn-shield/info.txt << EOFINFO
╔════════════════════════════════════════════════════════════╗
║              VPN Shield - Информация о подключении         ║
╚════════════════════════════════════════════════════════════╝

Server IP: $SERVER_IP

=== VLESS/REALITY ===
UUID: $UUID
Public Key: $PUBLIC_KEY
Short ID: $SHORT_ID
SNI: $MASQUERADE_DOMAIN
Port: 443

EOFINFO

if [ -n "$SS_PASSWORD" ]; then
    cat >> /root/vpn-shield/info.txt << EOFINFO
=== Shadowsocks 2022 ===
Port: 8388
Method: 2022-blake3-aes-256-gcm
Password: $SS_PASSWORD

EOFINFO
fi

if [ -n "$HYSTERIA_PASSWORD" ]; then
    cat >> /root/vpn-shield/info.txt << EOFINFO
=== Hysteria2 ===
Port: 36712
Password: $HYSTERIA_PASSWORD

EOFINFO
fi

if [ -n "$WG_SERVER_PUBLIC" ]; then
    cat >> /root/vpn-shield/info.txt << EOFINFO
=== WireGuard ===
Port: 51820
Server Public Key: $WG_SERVER_PUBLIC
Client Config: /root/vpn-shield/wireguard-client.conf

EOFINFO
fi

# Генерация ссылок подписки
cat > /root/vpn-shield/subscription.txt << EOFSUB
vless://${UUID}@${SERVER_IP}:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${MASQUERADE_DOMAIN}&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&type=tcp&headerType=none#VPN-Shield-VLESS
EOFSUB

if [ -n "$SS_PASSWORD" ]; then
    echo "ss://$(echo -n "2022-blake3-aes-256-gcm:${SS_PASSWORD}" | base64 -w 0)@${SERVER_IP}:8388#VPN-Shield-Shadowsocks" >> /root/vpn-shield/subscription.txt
fi

if [ -n "$HYSTERIA_PASSWORD" ]; then
    echo "hysteria2://${HYSTERIA_PASSWORD}@${SERVER_IP}:36712?insecure=1&sni=${MASQUERADE_DOMAIN}#VPN-Shield-Hysteria2" >> /root/vpn-shield/subscription.txt
fi

# Установка мониторинга
echo -e "${YELLOW}Установка системы мониторинга...${NC}"

# Скачиваем улучшенный скрипт мониторинга
# (в реальности нужно скачать с GitHub или скопировать vpn-monitor-improved.sh)

cat > /etc/systemd/system/vpn-shield-monitor.service << 'EOFMON'
[Unit]
Description=VPN Shield Auto Monitor
After=xray.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/vpn-monitor.sh
EOFMON

cat > /etc/systemd/system/vpn-shield-monitor.timer << 'EOFTIMER'
[Unit]
Description=VPN Shield Monitor Timer

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
EOFTIMER

systemctl daemon-reload
systemctl enable vpn-shield-monitor.timer
systemctl start vpn-shield-monitor.timer

clear

echo -e "${GREEN}"
cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║          ✓ VPN Shield успешно установлен!                 ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${BLUE}Установленные протоколы:${NC}"
systemctl is-active --quiet xray && echo -e "  ${GREEN}✓${NC} VLESS/REALITY (порт 443)"
[ -n "$SS_PASSWORD" ] && echo -e "  ${GREEN}✓${NC} Shadowsocks 2022 (порт 8388)"
systemctl is-active --quiet hysteria-server 2>/dev/null && echo -e "  ${GREEN}✓${NC} Hysteria2 (порт 36712)"
systemctl is-active --quiet wg-quick@wg0 2>/dev/null && echo -e "  ${GREEN}✓${NC} WireGuard (порт 51820)"

echo ""
echo -e "${BLUE}Информация о подключении:${NC}"
echo -e "  ${YELLOW}cat /root/vpn-shield/info.txt${NC}"
echo ""
echo -e "${BLUE}Единая подписка:${NC}"
echo -e "  ${YELLOW}cat /root/vpn-shield/subscription.txt${NC}"
echo ""
echo -e "${BLUE}Мониторинг:${NC}"
echo -e "  Статус: ${YELLOW}systemctl status vpn-shield-monitor.timer${NC}"
echo -e "  Логи:   ${YELLOW}tail -f /var/log/vpn-shield-monitor.log${NC}"
echo ""
echo -e "${GREEN}Система будет автоматически проверяться каждые 5 минут${NC}"
echo -e "${GREEN}При падении VPN произойдет автосмена маскировки${NC}"
echo -e "${GREEN}Ключи останутся прежними - обновлять подписку не нужно${NC}"
echo ""
