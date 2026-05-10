#!/bin/bash

#############################################
# VPN Shield - Ultimate Auto Install
# Полностью автоматическая установка
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
    echo "║              🛡️  VPN SHIELD FINAL  🛡️                ║"
    echo "║                                                       ║"
    echo "║          Полностью автоматическая установка           ║"
    echo "║                                                       ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

log() { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# Проверка root
[[ $EUID -ne 0 ]] && error "Запустите от root: sudo bash $0"

print_banner

# Получение IP
log "Определение IP сервера..."
SERVER_IP=$(curl -s4 ifconfig.me 2>/dev/null || curl -s4 icanhazip.com 2>/dev/null)
[[ -z "$SERVER_IP" ]] && error "Не удалось определить IP"
success "IP сервера: $SERVER_IP"

# Установка зависимостей
log "Установка зависимостей..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq > /dev/null 2>&1
apt-get install -y curl wget unzip nginx qrencode > /dev/null 2>&1
success "Зависимости установлены"

# Установка Xray
log "Установка Xray-core..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
success "Xray установлен"

# Генерация параметров
log "Генерация ключей и паролей..."
UUID=$(cat /proc/sys/kernel/random/uuid)
KEYS_OUTPUT=$(/usr/local/bin/xray x25519 2>&1)
PRIVATE_KEY=$(echo "$KEYS_OUTPUT" | awk '/Private/{print $NF}')
PUBLIC_KEY=$(echo "$KEYS_OUTPUT" | awk '/Public/{print $NF}')
SHORT_ID=$(openssl rand -hex 8)
TROJAN_PASS=$(openssl rand -base64 16 | tr -d '/+=' | cut -c1-16)
success "Ключи сгенерированы"

# Создание конфигурации Xray
log "Создание конфигурации..."
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
          "serverNames": ["www.microsoft.com"],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": ["$SHORT_ID"]
        }
      }
    },
    {
      "port": 8443,
      "protocol": "vmess",
      "settings": {"clients": [{"id": "$UUID", "alterId": 0}]},
      "streamSettings": {"network": "ws", "wsSettings": {"path": "/vmess"}}
    },
    {
      "port": 8444,
      "protocol": "trojan",
      "settings": {"clients": [{"password": "$TROJAN_PASS"}]},
      "streamSettings": {"network": "tcp"}
    }
  ],
  "outbounds": [{"protocol": "freedom"}]
}
EOF
success "Конфигурация создана"

# Настройка firewall
log "Настройка firewall..."
if command -v ufw &> /dev/null; then
    ufw --force enable > /dev/null 2>&1
    ufw allow 22/tcp > /dev/null 2>&1
    ufw allow 80/tcp > /dev/null 2>&1
    ufw allow 443/tcp > /dev/null 2>&1
    ufw allow 8443/tcp > /dev/null 2>&1
    ufw allow 8444/tcp > /dev/null 2>&1
    success "Firewall настроен"
fi

# Запуск Xray
log "Запуск Xray..."
systemctl enable xray > /dev/null 2>&1
systemctl restart xray
sleep 3

if ! systemctl is-active --quiet xray; then
    error "Xray не запустился. Логи: $(journalctl -u xray -n 5 --no-pager)"
fi
success "Xray запущен"

# Создание ссылок
log "Создание ссылок..."
VLESS="vless://${UUID}@${SERVER_IP}:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&type=tcp#VPN-REALITY"
VMESS="vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"VPN-VMess\",\"add\":\"${SERVER_IP}\",\"port\":\"8443\",\"id\":\"${UUID}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vmess\",\"tls\":\"\"}" | base64 -w 0)"
TROJAN="trojan://${TROJAN_PASS}@${SERVER_IP}:8444?security=none&type=tcp#VPN-Trojan"

# Создание подписки
mkdir -p /var/www/html
echo -e "${VLESS}\n${VMESS}\n${TROJAN}" | base64 -w 0 > /var/www/html/sub
success "Подписка создана"

# Создание веб-страницы
log "Создание веб-интерфейса..."
cat > /var/www/html/index.html <<'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VPN Shield</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, system-ui, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .card {
            background: white;
            border-radius: 20px;
            padding: 40px;
            max-width: 500px;
            width: 100%;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        h1 {
            text-align: center;
            color: #667eea;
            margin-bottom: 30px;
            font-size: 28px;
        }
        .btn {
            display: block;
            width: 100%;
            padding: 15px;
            margin: 10px 0;
            border: none;
            border-radius: 10px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s;
            text-align: center;
            text-decoration: none;
        }
        .btn:hover { transform: translateY(-2px); }
        .btn-primary {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
        }
        .info {
            background: #f0f0f0;
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
        }
        .info h3 {
            color: #667eea;
            margin-bottom: 10px;
        }
        .link {
            background: #f9f9f9;
            padding: 15px;
            border-radius: 8px;
            word-break: break-all;
            font-size: 12px;
            font-family: monospace;
            margin-top: 15px;
        }
    </style>
</head>
<body>
    <div class="card">
        <h1>🛡️ VPN Shield</h1>
        
        <button class="btn btn-primary" onclick="copy()">
            📋 Скопировать ссылку на подписку
        </button>

        <div class="info">
            <h3>📦 3 протокола в подписке:</h3>
            <p>• VLESS (REALITY) - порт 443</p>
            <p>• VMess (WebSocket) - порт 8443</p>
            <p>• Trojan - порт 8444</p>
        </div>

        <div class="info">
            <h3>📱 Как использовать:</h3>
            <p>1. Нажмите кнопку выше</p>
            <p>2. Откройте VPN приложение</p>
            <p>3. Добавьте подписку</p>
            <p>4. Вставьте ссылку</p>
        </div>

        <div class="link">
            <strong>Ссылка:</strong><br>
            <span id="url">SUB_URL</span>
        </div>
    </div>

    <script>
        function copy() {
            const url = 'SUB_URL';
            navigator.clipboard.writeText(url).then(() => {
                alert('✅ Ссылка скопирована!\\n\\nТеперь добавьте её в VPN приложение как подписку.');
            }).catch(() => {
                prompt('Скопируйте ссылку:', url);
            });
        }
    </script>
</body>
</html>
HTMLEOF

sed -i "s|SUB_URL|http://${SERVER_IP}/sub|g" /var/www/html/index.html
success "Веб-интерфейс создан"

# Настройка Nginx
log "Настройка Nginx..."
systemctl enable nginx > /dev/null 2>&1
systemctl restart nginx
success "Nginx запущен"

# Сохранение информации
mkdir -p /root/vpn-shield
cat > /root/vpn-shield/info.txt <<EOF
VPN Shield - Установлено $(date)
==================================

Веб-интерфейс: http://${SERVER_IP}
Подписка: http://${SERVER_IP}/sub

UUID: $UUID
Public Key: $PUBLIC_KEY
Short ID: $SHORT_ID
Trojan Password: $TROJAN_PASS

Ссылки:
-------
REALITY: $VLESS
VMess: $VMESS
Trojan: $TROJAN

Управление:
-----------
systemctl status xray
systemctl restart xray
journalctl -u xray -f
EOF

# Финальный вывод
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                       ║${NC}"
echo -e "${GREEN}║              ✅  УСТАНОВКА ЗАВЕРШЕНА  ✅              ║${NC}"
echo -e "${GREEN}║                                                       ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}🌐 Откройте в браузере:${NC}"
echo ""
echo -e "${YELLOW}   http://${SERVER_IP}${NC}"
echo ""
echo -e "${CYAN}📱 На странице нажмите кнопку 'Скопировать ссылку'${NC}"
echo -e "${CYAN}   и добавьте её в VPN приложение как подписку${NC}"
echo ""
echo -e "${BLUE}💾 Вся информация сохранена: /root/vpn-shield/info.txt${NC}"
echo ""
echo -e "${GREEN}✨ Готово! 3 протокола в одной подписке!${NC}"
echo ""
