#!/bin/bash

#############################################################################
#                                                                           #
#                    VPN Shield - Quick Install Script                     #
#                                                                           #
#  Автоматическая установка VPN Shield на чистый сервер Ubuntu/Debian     #
#                                                                           #
#############################################################################

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для красивого вывода
print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Проверка root прав
if [ "$EUID" -ne 0 ]; then 
    print_error "Пожалуйста, запустите скрипт с правами root (используйте sudo)"
    exit 1
fi

print_header "🛡️  VPN Shield - Автоматическая установка"

# Определение ОС
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    print_error "Не удалось определить ОС. Поддерживаются только Ubuntu/Debian."
    exit 1
fi

print_info "Обнаружена ОС: $OS $VERSION"

# Проверка поддерживаемой ОС
if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
    print_error "Поддерживаются только Ubuntu и Debian"
    exit 1
fi

# Получение IP адреса сервера
SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || echo "unknown")
print_info "IP адрес сервера: $SERVER_IP"

# Обновление системы
print_header "📦 Обновление системы"
apt-get update -qq
apt-get upgrade -y -qq
print_success "Система обновлена"

# Установка необходимых пакетов
print_header "📦 Установка зависимостей"
apt-get install -y -qq \
    curl \
    wget \
    git \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    ufw \
    fail2ban \
    htop \
    net-tools \
    openssl

print_success "Зависимости установлены"

# Установка Docker
print_header "🐳 Установка Docker"
if ! command -v docker &> /dev/null; then
    print_info "Установка Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh > /dev/null 2>&1
    rm get-docker.sh
    systemctl enable docker > /dev/null 2>&1
    systemctl start docker
    print_success "Docker установлен"
else
    print_success "Docker уже установлен"
fi

# Установка Docker Compose
print_header "🐳 Установка Docker Compose"
if ! command -v docker-compose &> /dev/null; then
    print_info "Установка Docker Compose..."
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose установлен"
else
    print_success "Docker Compose уже установлен"
fi

# Настройка firewall
print_header "🔥 Настройка firewall"
print_info "Настройка UFW..."
ufw --force enable > /dev/null 2>&1
ufw default deny incoming > /dev/null 2>&1
ufw default allow outgoing > /dev/null 2>&1
ufw allow 22/tcp comment 'SSH' > /dev/null 2>&1
ufw allow 80/tcp comment 'HTTP' > /dev/null 2>&1
ufw allow 443/tcp comment 'HTTPS - REALITY' > /dev/null 2>&1
ufw allow 8443/tcp comment 'VMess' > /dev/null 2>&1
ufw allow 8444/tcp comment 'Trojan' > /dev/null 2>&1
ufw allow 8888/tcp comment 'Admin Panel' > /dev/null 2>&1
ufw allow 36712/udp comment 'Hysteria2' > /dev/null 2>&1
print_success "Firewall настроен"

# Включение BBR
print_header "🚀 Оптимизация сети (BBR)"
if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
    cat >> /etc/sysctl.conf <<EOF

# VPN Shield Network Optimizations
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
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
    sysctl -p > /dev/null 2>&1
    print_success "BBR и оптимизации сети включены"
else
    print_success "BBR уже включен"
fi

# Настройка Fail2Ban
print_header "🔒 Настройка Fail2Ban"
cat > /etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
EOF
systemctl restart fail2ban > /dev/null 2>&1
print_success "Fail2Ban настроен"

# Создание директории установки
INSTALL_DIR="/opt/vpn-shield"
print_header "📁 Установка VPN Shield"
print_info "Директория установки: $INSTALL_DIR"

if [ -d "$INSTALL_DIR" ]; then
    print_warning "Директория $INSTALL_DIR уже существует"
    read -p "Удалить и переустановить? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
        print_info "Старая установка удалена"
    else
        print_error "Установка отменена"
        exit 1
    fi
fi

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Клонирование репозитория
print_info "Клонирование VPN Shield..."
REPO_URL="${VPN_SHIELD_REPO_URL:-https://github.com/YOUR_USERNAME/vpn-shield.git}"

if git clone "$REPO_URL" . 2>/dev/null; then
    print_success "Репозиторий клонирован"
else
    print_error "Не удалось клонировать репозиторий"
    print_info "Убедитесь, что:"
    print_info "1. Вы загрузили код на GitHub"
    print_info "2. URL репозитория правильный: $REPO_URL"
    print_info "3. Репозиторий публичный или у вас есть доступ"
    print_info "4. Или установите переменную: export VPN_SHIELD_REPO_URL=https://github.com/YOUR_USERNAME/vpn-shield.git"
    exit 1
fi

# Генерация паролей
print_header "🔐 Генерация безопасных паролей"
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
REDIS_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
JWT_SECRET=$(openssl rand -base64 48 | tr -d "=+/" | cut -c1-48)
ADMIN_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
HYSTERIA_OBFS=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)

print_success "Пароли сгенерированы"

# Создание .env файла
print_info "Создание конфигурации..."
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

# Domain configuration
DOMAIN=your-domain.com
PANEL_DOMAIN=panel.your-domain.com

# REALITY configuration
REALITY_DEST=www.microsoft.com:443
REALITY_SERVER_NAMES=www.microsoft.com,www.bing.com

# Hysteria2 configuration
HYSTERIA_PORT=36712
HYSTERIA_OBFS_PASSWORD=$HYSTERIA_OBFS

# Monitoring
ENABLE_METRICS=true
METRICS_PORT=9090

# Logging
LOG_LEVEL=info
LOG_FILE=/var/log/vpn-shield/app.log
EOF

print_success "Конфигурация создана"

# Создание директории для логов
mkdir -p /var/log/vpn-shield

# Запуск сервисов
print_header "🚀 Запуск VPN Shield"
print_info "Запуск Docker контейнеров..."
docker-compose up -d

# Ожидание запуска сервисов
print_info "Ожидание запуска сервисов (30 секунд)..."
sleep 30

# Проверка статуса
print_header "📊 Проверка статуса сервисов"
docker-compose ps

# Вывод информации
print_header "✅ Установка завершена!"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}║              🛡️  VPN Shield успешно установлен!              ║${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

print_info "Доступ к панели управления:"
echo -e "   ${BLUE}http://$SERVER_IP:8888${NC}"
echo ""

print_info "Учетные данные администратора:"
echo -e "   Username: ${GREEN}admin${NC}"
echo -e "   Password: ${GREEN}$ADMIN_PASSWORD${NC}"
echo ""

print_warning "⚠️  ВАЖНО: Сохраните эти данные!"
echo ""

print_info "Все пароли также сохранены в: ${BLUE}$INSTALL_DIR/.env${NC}"
echo ""

print_header "📝 Следующие шаги"
echo "1. Откройте панель управления: http://$SERVER_IP:8888"
echo "2. Войдите с учетными данными выше"
echo "3. Создайте пользователей в разделе 'Пользователи'"
echo "4. Получите конфигурации в разделе 'Конфигурации'"
echo "5. Настройте клиенты (v2rayNG, Shadowrocket, Hiddify)"
echo ""

print_header "🔧 Полезные команды"
echo "Статус сервисов:     cd $INSTALL_DIR && docker-compose ps"
echo "Логи:                cd $INSTALL_DIR && docker-compose logs -f"
echo "Перезапуск:          cd $INSTALL_DIR && docker-compose restart"
echo "Остановка:           cd $INSTALL_DIR && docker-compose down"
echo "Обновление:          cd $INSTALL_DIR && ./scripts/update.sh"
echo ""

print_header "📚 Документация"
echo "Полная документация: $INSTALL_DIR/docs/"
echo "Быстрый старт:       $INSTALL_DIR/QUICKSTART.md"
echo "Руководство:         $INSTALL_DIR/docs/USER_GUIDE.md"
echo ""

print_header "🌐 Настройка домена (опционально)"
echo "Если у вас есть домен:"
echo "1. Создайте A записи в DNS:"
echo "   A    @         $SERVER_IP"
echo "   A    panel     $SERVER_IP"
echo ""
echo "2. Получите SSL сертификат:"
echo "   apt install certbot -y"
echo "   certbot certonly --standalone -d your-domain.com"
echo ""
echo "3. Обновите .env файл:"
echo "   nano $INSTALL_DIR/.env"
echo "   # Измените DOMAIN=your-domain.com"
echo ""
echo "4. Перезапустите:"
echo "   cd $INSTALL_DIR && docker-compose restart"
echo ""

print_success "Установка завершена успешно!"
echo ""
echo -e "${GREEN}Против цензуры. За свободу информации. 🛡️${NC}"
echo ""
