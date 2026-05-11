#!/bin/bash

#############################################
# VPN Shield - Удаление веб-интерфейса
# Оптимизация системы для работы без панели
#############################################

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Удаление веб-интерфейса VPN Shield                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Проверяем root права
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}✗ Запустите скрипт с правами root${NC}"
    exit 1
fi

echo -e "${YELLOW}Это удалит следующие компоненты:${NC}"
echo "  • Frontend (React приложение)"
echo "  • Backend (Go API сервер)"
echo "  • Nginx (веб-сервер)"
echo "  • PostgreSQL (база данных)"
echo "  • Redis (кэш)"
echo ""
echo -e "${GREEN}Останутся работать:${NC}"
echo "  • Xray (VLESS, VMess, Trojan, Shadowsocks)"
echo "  • Hysteria2"
echo "  • WireGuard (если установлен)"
echo "  • Система мониторинга"
echo ""

read -p "Продолжить удаление? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Отменено${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Остановка и удаление Docker контейнеров...${NC}"

# Останавливаем Docker Compose
if [ -f "/root/vpn-shield/docker-compose.yml" ]; then
    cd /root/vpn-shield
    docker-compose down -v
    echo -e "${GREEN}✓ Docker контейнеры остановлены${NC}"
else
    echo -e "${YELLOW}⚠ docker-compose.yml не найден${NC}"
fi

# Удаляем Docker образы
echo -e "${YELLOW}Удаление Docker образов...${NC}"
docker images | grep vpn-shield | awk '{print $3}' | xargs -r docker rmi -f
echo -e "${GREEN}✓ Docker образы удалены${NC}"

# Удаляем Docker volumes
echo -e "${YELLOW}Удаление Docker volumes...${NC}"
docker volume ls | grep vpn-shield | awk '{print $2}' | xargs -r docker volume rm
echo -e "${GREEN}✓ Docker volumes удалены${NC}"

# Останавливаем и отключаем Nginx
if systemctl is-active --quiet nginx; then
    echo -e "${YELLOW}Остановка Nginx...${NC}"
    systemctl stop nginx
    systemctl disable nginx
    echo -e "${GREEN}✓ Nginx остановлен${NC}"
fi

# Удаляем директории веб-интерфейса
echo -e "${YELLOW}Удаление файлов веб-интерфейса...${NC}"
rm -rf /root/vpn-shield/frontend
rm -rf /root/vpn-shield/backend
rm -rf /root/vpn-shield/docker
rm -rf /root/vpn-shield/docker-compose.yml
echo -e "${GREEN}✓ Файлы веб-интерфейса удалены${NC}"

# Закрываем порты веб-панели в firewall
if command -v ufw &> /dev/null; then
    echo -e "${YELLOW}Закрытие портов веб-панели в firewall...${NC}"
    ufw delete allow 8888/tcp 2>/dev/null || true
    ufw delete allow 8080/tcp 2>/dev/null || true
    echo -e "${GREEN}✓ Порты закрыты${NC}"
fi

# Проверяем работу VPN протоколов
echo ""
echo -e "${BLUE}Проверка работы VPN протоколов...${NC}"

# Проверяем Xray
if systemctl is-active --quiet xray; then
    echo -e "${GREEN}✓ Xray работает${NC}"
    
    # Проверяем порты
    if ss -tuln | grep -q ":443 "; then
        echo -e "${GREEN}  ✓ VLESS/REALITY (порт 443)${NC}"
    fi
    if ss -tuln | grep -q ":8443 "; then
        echo -e "${GREEN}  ✓ VMess (порт 8443)${NC}"
    fi
    if ss -tuln | grep -q ":8444 "; then
        echo -e "${GREEN}  ✓ Trojan (порт 8444)${NC}"
    fi
    if ss -tuln | grep -q ":8388 "; then
        echo -e "${GREEN}  ✓ Shadowsocks (порт 8388)${NC}"
    fi
else
    echo -e "${RED}✗ Xray не работает${NC}"
fi

# Проверяем Hysteria2
if systemctl is-active --quiet hysteria-server 2>/dev/null; then
    echo -e "${GREEN}✓ Hysteria2 работает (порт 36712)${NC}"
else
    echo -e "${YELLOW}⚠ Hysteria2 не установлен${NC}"
fi

# Проверяем WireGuard
if systemctl is-active --quiet wg-quick@wg0 2>/dev/null; then
    echo -e "${GREEN}✓ WireGuard работает (порт 51820)${NC}"
else
    echo -e "${YELLOW}⚠ WireGuard не установлен${NC}"
fi

# Проверяем мониторинг
if systemctl is-active --quiet vpn-shield-monitor.timer 2>/dev/null; then
    echo -e "${GREEN}✓ Система мониторинга работает${NC}"
else
    echo -e "${YELLOW}⚠ Система мониторинга не установлена${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Веб-интерфейс успешно удален!                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Освобождено ресурсов:${NC}"
echo "  • RAM: ~1-2 GB"
echo "  • CPU: ~10-20%"
echo "  • Disk: ~500 MB"
echo ""
echo -e "${BLUE}Управление VPN теперь через:${NC}"
echo "  • Конфигурационные файлы:"
echo "    - Xray: /usr/local/etc/xray/config.json"
echo "    - Hysteria2: /etc/hysteria/config.yaml"
echo "    - WireGuard: /etc/wireguard/wg0.conf"
echo ""
echo "  • Информация о подключении:"
echo "    - /root/vpn-shield/info.txt"
echo "    - /root/vpn-shield/subscription.txt"
echo ""
echo "  • Логи мониторинга:"
echo "    - tail -f /var/log/vpn-shield-monitor.log"
echo ""
echo "  • Управление сервисами:"
echo "    - systemctl status xray"
echo "    - systemctl status hysteria-server"
echo "    - systemctl status wg-quick@wg0"
echo "    - systemctl status vpn-shield-monitor.timer"
echo ""
echo -e "${YELLOW}Для добавления новых пользователей редактируйте конфиги вручную${NC}"
echo ""
