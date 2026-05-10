#!/bin/bash

#############################################
# VPN Shield - Final Multi-Protocol Setup
# One subscription link with all protocols
#############################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║                                                       ║"
    echo "║              🛡️  VPN SHIELD v3.0  🛡️                 ║"
    echo "║                                                       ║"
    echo "║          Multi-Protocol VPN with Subscription        ║"
    echo "║                                                       ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

print_info() { echo -e "${BLUE}[ℹ]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Запустите от root: sudo bash $0"
        exit 1
    fi
}

detect_ip() {
    SERVER_IP=$(curl -s4 ifconfig.me 2>/dev/null || curl -s4 icanhazip.com 2>/dev/null)
    if [ -z "$SERVER_IP" ]; then
        print_error "Не удалось определить IP"
        exit 1
    fi
}

install_deps() {
    print_info "Установка зависимостей..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq > /dev/null 2>&1
    apt-get install -y curl wget unzip qrencode python3 > /dev/null 2>&1
    print_success "Зависимости установлены"
}

install_xray() {
    print_info "Установка Xray-core..."
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
    print_success "Xray установлен"
}

generate_config() {
    print_info "Генерация конфигурации..."
    
    UUID=$(cat /proc/sys/kernel/random/uuid)
    KEYS_OUTPUT=$(/usr/local/bin/xray x25519 2>&1)
    PRIVATE_KEY=$(echo "$KEYS_OUTPUT" | awk '/Private/{print $NF}')
    PUBLIC_KEY=$(echo "$KEYS_OUTPUT" | awk '/Public/{print $NF}')
    SHORT_ID=$(openssl rand -hex 8)
    TROJAN_PASS=$(openssl rand -base64 16 | tr -d '/+=' | cut -c1-16)
    
    cat > /usr/local/etc/xray/config.json <<EOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [{"id": "$UUID", "flow": "xtls-rprx-vision"}],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.microsoft.com:443",
          "xver": 0,
          "serverNames": ["www.microsoft.com", "login.microsoft.com"],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": ["$SHORT_ID", ""]
        }
      }
    },
    {
      "port": 8443,
      "protocol": "vmess",
      "settings": {
        "clients": [{"id": "$UUID", "alterId": 0}]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {"path": "/vmess"}
      }
    },
    {
      "port": 8444,
      "protocol": "trojan",
      "settings": {
        "clients": [{"password": "$TROJAN_PASS"}]
      },
      "streamSettings": {"network": "tcp"}
    }
  ],
  "outbounds": [{"protocol": "freedom"}]
}
EOF
    
    print_success "Конфигурация создана"
}

setup_firewall() {
    print_info "Настройка firewall..."
    if command -v ufw &> /dev/null; then
        ufw --force enable > /dev/null 2>&1
        ufw allow 22/tcp > /dev/null 2>&1
        ufw allow 443/tcp > /dev/null 2>&1
        ufw allow 8443/tcp > /dev/null 2>&1
        ufw allow 8444/tcp > /dev/null 2>&1
        ufw allow 8080/tcp > /dev/null 2>&1
        print_success "Firewall настроен"
    fi
}

start_xray() {
    print_info "Запуск Xray..."
    systemctl enable xray > /dev/null 2>&1
    systemctl restart xray
    sleep 2
    
    if systemctl is-active --quiet xray; then
        print_success "Xray запущен"
        return 0
    else
        print_error "Ошибка запуска Xray"
        journalctl -u xray -n 20 --no-pager
        return 1
    fi
}

create_subscription() {
    print_info "Создание подписки..."
    
    VLESS_LINK="vless://${UUID}@${SERVER_IP}:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&type=tcp&headerType=none#VPN-REALITY"
    
    VMESS_JSON="{\"v\":\"2\",\"ps\":\"VPN-VMess\",\"add\":\"${SERVER_IP}\",\"port\":\"8443\",\"id\":\"${UUID}\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"path\":\"/vmess\",\"tls\":\"\"}"
    VMESS_LINK="vmess://$(echo -n "$VMESS_JSON" | base64 -w 0)"
    
    TROJAN_LINK="trojan://${TROJAN_PASS}@${SERVER_IP}:8444?security=none&type=tcp#VPN-Trojan"
    
    mkdir -p /var/www/vpn-sub
    echo -e "${VLESS_LINK}\n${VMESS_LINK}\n${TROJAN_LINK}" | base64 -w 0 > /var/www/vpn-sub/sub
    
    cat > /etc/systemd/system/vpn-sub.service <<'SUBEOF'
[Unit]
Description=VPN Subscription Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m http.server 8080 --directory /var/www/vpn-sub
Restart=always

[Install]
WantedBy=multi-user.target
SUBEOF
    
    systemctl daemon-reload
    systemctl enable vpn-sub > /dev/null 2>&1
    systemctl restart vpn-sub
    
    mkdir -p /root/vpn-shield
    cat > /root/vpn-shield/info.txt <<EOF
VPN Shield Configuration
========================
Server IP: $SERVER_IP
UUID: $UUID
Public Key: $PUBLIC_KEY
Short ID: $SHORT_ID
Trojan Password: $TROJAN_PASS

Subscription URL:
http://${SERVER_IP}:8080/sub

Individual Links:
REALITY: $VLESS_LINK
VMess: $VMESS_LINK
Trojan: $TROJAN_LINK

Installed: $(date)
EOF
    
    print_success "Подписка создана"
}

show_result() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                       ║${NC}"
    echo -e "${GREEN}║              ✅  УСТАНОВКА ЗАВЕРШЕНА  ✅              ║${NC}"
    echo -e "${GREEN}║                                                       ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}📱 ССЫЛКА НА ПОДПИСКУ:${NC}"
    echo ""
    echo -e "${YELLOW}http://${SERVER_IP}:8080/sub${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}📋 Как использовать:${NC}"
    echo ""
    echo "  1. Скопируйте ссылку выше"
    echo "  2. Откройте VPN приложение (v2rayNG, Shadowrocket, etc.)"
    echo "  3. Найдите 'Добавить подписку' или 'Add Subscription'"
    echo "  4. Вставьте ссылку"
    echo "  5. Обновите подписку"
    echo "  6. Все 3 протокола появятся автоматически!"
    echo ""
    echo -e "${BLUE}✨ Протоколы в подписке:${NC}"
    echo "  • VLESS (REALITY) - порт 443 - Лучший обход"
    echo "  • VMess (WebSocket) - порт 8443 - Универсальный"
    echo "  • Trojan - порт 8444 - Надежный"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}💾 Информация сохранена:${NC} /root/vpn-shield/info.txt"
    echo -e "${BLUE}🔧 Управление:${NC}"
    echo "     systemctl status xray    - статус"
    echo "     systemctl restart xray   - перезапуск"
    echo ""
    echo -e "${GREEN}✨ Готово! Одна ссылка - все протоколы!${NC}"
    echo ""
}

main() {
    print_banner
    check_root
    detect_ip
    
    print_info "IP сервера: $SERVER_IP"
    echo ""
    
    install_deps
    install_xray
    generate_config
    setup_firewall
    
    if ! start_xray; then
        exit 1
    fi
    
    create_subscription
    show_result
}

main "$@"
