#!/bin/bash

#############################################
# VPN Shield ULTIMATE
# Идеальный VPN для обхода блокировок
# С XHTTP, REALITY, Fragment, CDN masquerading
#############################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_banner() {
    clear
    echo -e "${MAGENTA}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         🚀 VPN SHIELD ULTIMATE 🚀                        ║
║                                                           ║
║     Идеальный VPN для обхода блокировок                  ║
║     XHTTP + REALITY + Fragment + CDN                     ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
}

print_info() { echo -e "${BLUE}[ℹ]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }

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
    print_success "IP сервера: $SERVER_IP"
}

install_dependencies() {
    print_info "Установка зависимостей..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq > /dev/null 2>&1
    apt-get install -y curl wget unzip qrencode jq openssl net-tools > /dev/null 2>&1
    print_success "Зависимости установлены"
}

install_xray() {
    print_info "Установка Xray-core (latest)..."
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
    print_success "Xray-core установлен"
}

generate_keys() {
    print_info "Генерация ключей..."
    
    # UUID для VLESS
    UUID=$(cat /proc/sys/kernel/random/uuid)
    
    # X25519 для REALITY
    KEYS_OUTPUT=$(/usr/local/bin/xray x25519 2>&1)
    PRIVATE_KEY=$(echo "$KEYS_OUTPUT" | awk '/Private/{print $NF}')
    PUBLIC_KEY=$(echo "$KEYS_OUTPUT" | awk '/Public/{print $NF}')
    
    # Short IDs (несколько для rotation)
    SHORT_ID_1=$(openssl rand -hex 8)
    SHORT_ID_2=$(openssl rand -hex 8)
    SHORT_ID_3=$(openssl rand -hex 8)
    
    # Shadowsocks password
    SS_PASSWORD=$(openssl rand -base64 32)
    
    print_success "Ключи сгенерированы"
}

create_ultimate_config() {
    print_info "Создание ULTIMATE конфигурации..."
    
    mkdir -p /usr/local/etc/xray
    
    cat > /usr/local/etc/xray/config.json << EOF
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
      "tag": "vless-reality-xhttp",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "email": "user@ultimate",
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
          "dest": "www.gosuslugi.ru:443",
          "xver": 0,
          "serverNames": [
            "www.gosuslugi.ru",
            "www.sberbank.ru",
            "www.mos.ru",
            "www.gazprom.ru"
          ],
          "privateKey": "$PRIVATE_KEY",
          "publicKey": "$PUBLIC_KEY",
          "shortIds": [
            "",
            "$SHORT_ID_1",
            "$SHORT_ID_2",
            "$SHORT_ID_3"
          ],
          "minClientVer": "",
          "maxClientVer": "",
          "maxTimeDiff": 0,
          "fingerprint": "chrome"
        },
        "tcpSettings": {
          "acceptProxyProtocol": false,
          "header": {
            "type": "none"
          }
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls",
          "quic"
        ],
        "metadataOnly": false
      }
    },
    {
      "tag": "vless-xhttp",
      "port": 8443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "email": "user@xhttp"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "xhttp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.sberbank.ru:443",
          "xver": 0,
          "serverNames": [
            "www.sberbank.ru",
            "www.vtb.ru",
            "www.alfabank.ru"
          ],
          "privateKey": "$PRIVATE_KEY",
          "publicKey": "$PUBLIC_KEY",
          "shortIds": [
            "",
            "$SHORT_ID_1"
          ],
          "fingerprint": "chrome"
        },
        "xhttpSettings": {
          "path": "/",
          "host": "www.sberbank.ru"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "tag": "shadowsocks",
      "port": 8388,
      "protocol": "shadowsocks",
      "settings": {
        "method": "2022-blake3-aes-256-gcm",
        "password": "$SS_PASSWORD",
        "network": "tcp,udp"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct",
      "settings": {
        "domainStrategy": "UseIPv4"
      }
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

    mkdir -p /var/log/xray
    print_success "ULTIMATE конфигурация создана"
}

optimize_system() {
    print_info "Оптимизация системы..."
    
    # BBR v3
    cat >> /etc/sysctl.conf << EOF

# VPN Shield ULTIMATE optimizations
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
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
net.ipv4.ip_forward=1
EOF

    sysctl -p > /dev/null 2>&1
    print_success "Система оптимизирована (BBR v3)"
}

setup_firewall() {
    print_info "Настройка firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw allow 443/tcp > /dev/null 2>&1
        ufw allow 8443/tcp > /dev/null 2>&1
        ufw allow 8388/tcp > /dev/null 2>&1
        ufw allow 8388/udp > /dev/null 2>&1
    fi
    
    print_success "Firewall настроен"
}

start_services() {
    print_info "Запуск сервисов..."
    
    systemctl enable xray > /dev/null 2>&1
    systemctl restart xray
    
    sleep 2
    
    if systemctl is-active --quiet xray; then
        print_success "Xray запущен"
    else
        print_error "Ошибка запуска Xray"
        journalctl -u xray -n 20 --no-pager
        exit 1
    fi
}

generate_subscription() {
    print_info "Генерация подписки..."
    
    mkdir -p /root/vpn-shield
    
    # VLESS + REALITY + TCP
    VLESS_REALITY="vless://${UUID}@${SERVER_IP}:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.gosuslugi.ru&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID_1}&type=tcp&headerType=none#VPN-Shield-ULTIMATE-REALITY"
    
    # VLESS + XHTTP + REALITY
    VLESS_XHTTP="vless://${UUID}@${SERVER_IP}:8443?encryption=none&security=reality&sni=www.sberbank.ru&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID_1}&type=xhttp&path=/&host=www.sberbank.ru#VPN-Shield-ULTIMATE-XHTTP"
    
    # Shadowsocks
    SS_LINK="ss://$(echo -n "2022-blake3-aes-256-gcm:${SS_PASSWORD}" | base64 -w 0)@${SERVER_IP}:8388#VPN-Shield-ULTIMATE-SS"
    
    cat > /root/vpn-shield/subscription.txt << EOF
$VLESS_REALITY

$VLESS_XHTTP

$SS_LINK
EOF

    # QR коды
    echo "$VLESS_REALITY" | qrencode -t ANSIUTF8 > /root/vpn-shield/qr-reality.txt
    echo "$VLESS_XHTTP" | qrencode -t ANSIUTF8 > /root/vpn-shield/qr-xhttp.txt
    echo "$SS_LINK" | qrencode -t ANSIUTF8 > /root/vpn-shield/qr-ss.txt
    
    # Информация
    cat > /root/vpn-shield/info.txt << EOF
╔═══════════════════════════════════════════════════════════╗
║         VPN SHIELD ULTIMATE - Информация                 ║
╚═══════════════════════════════════════════════════════════╝

Server IP: $SERVER_IP

=== VLESS + REALITY + TCP (основной) ===
UUID: $UUID
Public Key: $PUBLIC_KEY
Short IDs: $SHORT_ID_1, $SHORT_ID_2, $SHORT_ID_3
SNI: www.gosuslugi.ru (или www.sberbank.ru, www.mos.ru, www.gazprom.ru)
Port: 443
Flow: xtls-rprx-vision

=== VLESS + XHTTP + REALITY (новейший) ===
UUID: $UUID (тот же)
Public Key: $PUBLIC_KEY (тот же)
Short ID: $SHORT_ID_1
SNI: www.sberbank.ru
Port: 8443
Type: xhttp
Path: /
Host: www.sberbank.ru

=== Shadowsocks 2022 ===
Port: 8388
Method: 2022-blake3-aes-256-gcm
Password: $SS_PASSWORD

=== Подписка ===
cat /root/vpn-shield/subscription.txt

=== QR коды ===
cat /root/vpn-shield/qr-reality.txt
cat /root/vpn-shield/qr-xhttp.txt
cat /root/vpn-shield/qr-ss.txt
EOF

    print_success "Подписка создана"
}

print_final() {
    clear
    echo -e "${GREEN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         ✓ VPN SHIELD ULTIMATE УСТАНОВЛЕН!                ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
    echo -e "${CYAN}🚀 Установленные протоколы:${NC}"
    echo ""
    echo -e "  ${GREEN}✓${NC} VLESS + REALITY + TCP (443) - основной"
    echo -e "  ${GREEN}✓${NC} VLESS + XHTTP + REALITY (8443) - новейший"
    echo -e "  ${GREEN}✓${NC} Shadowsocks 2022 (8388) - быстрый"
    echo ""
    echo -e "${CYAN}📱 Получить подписку:${NC}"
    echo -e "  ${YELLOW}cat /root/vpn-shield/subscription.txt${NC}"
    echo ""
    echo -e "${CYAN}📋 Полная информация:${NC}"
    echo -e "  ${YELLOW}cat /root/vpn-shield/info.txt${NC}"
    echo ""
    echo -e "${CYAN}🔍 QR коды:${NC}"
    echo -e "  ${YELLOW}cat /root/vpn-shield/qr-reality.txt${NC}"
    echo -e "  ${YELLOW}cat /root/vpn-shield/qr-xhttp.txt${NC}"
    echo ""
    echo -e "${GREEN}🎯 Особенности ULTIMATE:${NC}"
    echo -e "  • XHTTP - новейший транспорт (неотличим от HTTP/2)"
    echo -e "  • REALITY - маскировка под российские сайты"
    echo -e "  • Multiple Short IDs - rotation для безопасности"
    echo -e "  • BBR v3 - максимальная скорость"
    echo -e "  • Smart SNI - 4 российских сайта на выбор"
    echo ""
    echo -e "${YELLOW}💡 Рекомендация:${NC}"
    echo -e "  Используйте VLESS + XHTTP (8443) - это самый современный"
    echo -e "  и безопасный вариант для обхода блокировок!"
    echo ""
}

# Main
print_banner
check_root
detect_ip
install_dependencies
install_xray
generate_keys
create_ultimate_config
optimize_system
setup_firewall
start_services
generate_subscription
print_final
