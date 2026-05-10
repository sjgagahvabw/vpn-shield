#!/bin/bash

#############################################
# VPN Shield - Автоматическая установка
# Простой VPN с обходом блокировок
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
    echo "║              🛡️  VPN SHIELD v2.0  🛡️                 ║"
    echo "║                                                       ║"
    echo "║          Автоматическая установка VPN                 ║"
    echo "║         с обходом блокировок и цензуры                ║"
    echo "║                                                       ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

print_info() { echo -e "${BLUE}[ℹ]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Запустите скрипт от root: sudo bash $0"
        exit 1
    fi
}

detect_ip() {
    SERVER_IP=$(curl -s4 ifconfig.me 2>/dev/null || curl -s4 icanhazip.com 2>/dev/null || curl -s4 ipinfo.io/ip 2>/dev/null)
    if [ -z "$SERVER_IP" ]; then
        print_error "Не удалось определить IP сервера"
        exit 1
    fi
}

install_dependencies() {
    print_info "Установка зависимостей..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq > /dev/null 2>&1
    apt-get install -y curl wget unzip qrencode jq > /dev/null 2>&1
    print_success "Зависимости установлены"
}

install_xray() {
    print_info "Установка Xray-core..."
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
    print_success "Xray-core установлен"
}

test_site() {
    local site=$1
    local domain=$(echo "$site" | cut -d':' -f1)
    
    # Проверяем доступность через curl с таймаутом
    if timeout 5 curl -s -o /dev/null -w "%{http_code}" "https://$domain" | grep -q "200\|301\|302"; then
        return 0
    fi
    return 1
}

generate_config() {
    print_info "Генерация конфигурации..."
    
    # Генерируем UUID
    UUID=$(cat /proc/sys/kernel/random/uuid)
    
    # Генерируем X25519 ключи
    KEYS_OUTPUT=$(/usr/local/bin/xray x25519 2>&1)
    PRIVATE_KEY=$(echo "$KEYS_OUTPUT" | grep -oP 'Private key: \K[A-Za-z0-9_-]+' || echo "$KEYS_OUTPUT" | awk '/Private/{print $NF}')
    PUBLIC_KEY=$(echo "$KEYS_OUTPUT" | grep -oP 'Public key: \K[A-Za-z0-9_-]+' || echo "$KEYS_OUTPUT" | awk '/Public/{print $NF}')
    
    if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then
        print_error "Ошибка генерации ключей"
        exit 1
    fi
    
    # Генерируем Short ID
    SHORT_ID=$(openssl rand -hex 8)
    
    print_info "Поиск рабочего сайта для маскировки..."
    
    # Список популярных сайтов для маскировки (CDN, крупные сервисы)
    CANDIDATE_SITES=(
        "www.microsoft.com:443|www.microsoft.com,login.microsoft.com"
        "www.apple.com:443|www.apple.com,www.icloud.com"
        "www.cloudflare.com:443|www.cloudflare.com,dash.cloudflare.com"
        "www.amazon.com:443|www.amazon.com,aws.amazon.com"
        "www.cisco.com:443|www.cisco.com,www.webex.com"
        "www.oracle.com:443|www.oracle.com,cloud.oracle.com"
        "www.ibm.com:443|www.ibm.com,cloud.ibm.com"
        "www.samsung.com:443|www.samsung.com"
        "www.logitech.com:443|www.logitech.com"
        "www.zoom.us:443|www.zoom.us,zoom.us"
        "www.booking.com:443|www.booking.com"
        "www.speedtest.net:443|www.speedtest.net"
        "www.ubuntu.com:443|www.ubuntu.com"
        "www.debian.org:443|www.debian.org"
    )
    
    DEST=""
    SNI_PRIMARY=""
    SNI_SECONDARY=""
    
    # Проверяем каждый сайт
    for site_config in "${CANDIDATE_SITES[@]}"; do
        site=$(echo "$site_config" | cut -d'|' -f1)
        domain=$(echo "$site" | cut -d':' -f1)
        
        print_info "Проверка: $domain..."
        
        if test_site "$site"; then
            DEST="$site"
            SNI_LIST=$(echo "$site_config" | cut -d'|' -f2)
            SNI_PRIMARY=$(echo "$SNI_LIST" | cut -d',' -f1)
            SNI_SECONDARY=$(echo "$SNI_LIST" | cut -d',' -f2)
            
            print_success "✓ Найден рабочий сайт: $SNI_PRIMARY"
            break
        fi
    done
    
    # Если не нашли рабочий сайт, используем запасной
    if [ -z "$DEST" ]; then
        print_warning "Используем запасной вариант: www.cloudflare.com"
        DEST="www.cloudflare.com:443"
        SNI_PRIMARY="www.cloudflare.com"
        SNI_SECONDARY="dash.cloudflare.com"
    fi
    
    print_info "Маскировка под: $SNI_PRIMARY"
    
    # Создаем конфиг с маскировкой
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
          "dest": "$DEST",
          "xver": 0,
          "serverNames": [
            "$SNI_PRIMARY",
            "$SNI_SECONDARY"
          ],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [
            "$SHORT_ID",
            ""
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "block"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "block"
      }
    ]
  }
}
EOF
    
    # Сохраняем SNI для использования в ссылке
    SNI_NAMES=("$SNI_PRIMARY" "$SNI_SECONDARY")
    
    print_success "Конфигурация создана с маскировкой под $SNI_PRIMARY"
}

configure_firewall() {
    print_info "Настройка firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw --force enable > /dev/null 2>&1
        ufw allow 22/tcp > /dev/null 2>&1
        ufw allow 443/tcp > /dev/null 2>&1
        print_success "UFW настроен"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=443/tcp > /dev/null 2>&1
        firewall-cmd --reload > /dev/null 2>&1
        print_success "Firewalld настроен"
    fi
}

optimize_network() {
    print_info "Оптимизация сети..."
    
    cat >> /etc/sysctl.conf <<EOF

# VPN Shield Network Optimization
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_slow_start_after_idle=0
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
EOF
    
    sysctl -p > /dev/null 2>&1
    print_success "Сеть оптимизирована (BBR включен)"
}

start_xray() {
    print_info "Запуск Xray..."
    systemctl enable xray > /dev/null 2>&1
    systemctl restart xray
    sleep 2
    
    if systemctl is-active --quiet xray; then
        print_success "Xray запущен и работает"
        return 0
    else
        print_error "Ошибка запуска Xray"
        journalctl -u xray -n 20 --no-pager
        return 1
    fi
}

save_config() {
    mkdir -p /root/vpn-shield
    
    cat > /root/vpn-shield/info.txt <<EOF
VPN Shield Configuration
========================

Server IP: $SERVER_IP
UUID: $UUID
Public Key: $PUBLIC_KEY
Short ID: $SHORT_ID
SNI: ${SNI_NAMES[0]}

Connection Link:
$VLESS_LINK

Управление:
- Статус: systemctl status xray
- Перезапуск: systemctl restart xray
- Логи: journalctl -u xray -f
- Конфиг: /usr/local/etc/xray/config.json

Установлено: $(date)
EOF
    
    echo "$VLESS_LINK" > /root/vpn-shield/connection.txt
}

generate_qr() {
    if command -v qrencode &> /dev/null; then
        qrencode -t ANSIUTF8 "$VLESS_LINK" > /root/vpn-shield/qr.txt 2>/dev/null || true
    fi
}

show_connection_info() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                       ║${NC}"
    echo -e "${GREEN}║              ✅  УСТАНОВКА ЗАВЕРШЕНА  ✅              ║${NC}"
    echo -e "${GREEN}║                                                       ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}📱 ССЫЛКА ДЛЯ ПОДКЛЮЧЕНИЯ:${NC}"
    echo ""
    echo -e "${YELLOW}$VLESS_LINK${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}📲 Приложения для подключения:${NC}"
    echo ""
    echo -e "  ${GREEN}iOS:${NC}     Shadowrocket, V2Box, Streisand"
    echo -e "  ${GREEN}Android:${NC} v2rayNG, NekoBox, Hiddify"
    echo -e "  ${GREEN}Windows:${NC} v2rayN, Nekoray, Hiddify"
    echo -e "  ${GREEN}macOS:${NC}   V2rayU, Qv2ray, Hiddify"
    echo -e "  ${GREEN}Linux:${NC}   Qv2ray, Nekoray"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}📋 Инструкция:${NC}"
    echo ""
    echo "  1. Скопируйте ссылку выше"
    echo "  2. Откройте VPN приложение"
    echo "  3. Нажмите '+' или 'Добавить'"
    echo "  4. Вставьте ссылку"
    echo "  5. Подключитесь!"
    echo ""
    
    if [ -f /root/vpn-shield/qr.txt ]; then
        echo -e "${BLUE}📊 QR-код:${NC}"
        echo ""
        cat /root/vpn-shield/qr.txt
        echo ""
    fi
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}💾 Файлы сохранены в:${NC} /root/vpn-shield/"
    echo -e "${BLUE}🔧 Управление:${NC}"
    echo "     systemctl status xray    - статус"
    echo "     systemctl restart xray   - перезапуск"
    echo "     journalctl -u xray -f    - логи"
    echo ""
    echo -e "${GREEN}✨ VPN готов к использованию!${NC}"
    echo ""
}

main() {
    print_banner
    
    check_root
    detect_ip
    
    print_info "IP сервера: $SERVER_IP"
    echo ""
    
    install_dependencies
    install_xray
    generate_config
    configure_firewall
    optimize_network
    
    if ! start_xray; then
        exit 1
    fi
    
    # Генерируем ссылку для подключения
    VLESS_LINK="vless://${UUID}@${SERVER_IP}:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SNI_NAMES[0]}&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&type=tcp&headerType=none#VPN-Shield"
    
    save_config
    generate_qr
    show_connection_info
}

main "$@"
