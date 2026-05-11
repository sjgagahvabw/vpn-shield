#!/bin/bash

#############################################
# VPN Shield - Автоматическое применение всех улучшений
# Запустите этот скрипт на сервере для обновления системы
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
║        VPN Shield - Автоматическое обновление              ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Проверка root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}✗ Запустите скрипт с правами root${NC}"
    exit 1
fi

# Проверка наличия файлов
echo -e "${YELLOW}Проверка наличия файлов...${NC}"
REQUIRED_FILES=(
    "vpn-monitor-improved.sh"
    "add-shadowsocks.sh"
    "add-wireguard.sh"
    "setup-monitor.sh"
    "sites/russian-whitelist-extended.txt"
)

MISSING=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}✗ Файл не найден: $file${NC}"
        MISSING=$((MISSING + 1))
    fi
done

if [ $MISSING -gt 0 ]; then
    echo -e "${RED}Отсутствует $MISSING файлов. Скопируйте все файлы на сервер.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Все необходимые файлы найдены${NC}"
echo ""

# Показываем что будет сделано
echo -e "${BLUE}Будут применены следующие улучшения:${NC}"
echo ""
echo "  1. Обновление мониторинга (сохранение ключей)"
echo "  2. Изменение интервала проверки на 5 минут"
echo "  3. Добавление Shadowsocks 2022 (порт 8388)"
echo "  4. Добавление WireGuard (порт 51820)"
echo "  5. Обновление списка сайтов (167 сайтов)"
echo "  6. Перезапуск мониторинга"
echo ""

read -p "Продолжить? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Отменено${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}Начинаем обновление...${NC}"
echo ""

# Создаем резервные копии
echo -e "${YELLOW}[1/7] Создание резервных копий...${NC}"
BACKUP_DIR="/root/vpn-shield-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

if [ -f "/usr/local/bin/vpn-monitor.sh" ]; then
    cp /usr/local/bin/vpn-monitor.sh "$BACKUP_DIR/"
    echo -e "${GREEN}✓ Резервная копия мониторинга создана${NC}"
fi

if [ -f "/usr/local/etc/xray/config.json" ]; then
    cp /usr/local/etc/xray/config.json "$BACKUP_DIR/"
    echo -e "${GREEN}✓ Резервная копия конфигурации Xray создана${NC}"
fi

echo -e "${GREEN}✓ Резервные копии сохранены в: $BACKUP_DIR${NC}"
echo ""

# Обновление мониторинга
echo -e "${YELLOW}[2/7] Обновление мониторинга...${NC}"
cp vpn-monitor-improved.sh /usr/local/bin/vpn-monitor.sh
chmod +x /usr/local/bin/vpn-monitor.sh
echo -e "${GREEN}✓ Мониторинг обновлен (теперь ключи сохраняются)${NC}"
echo ""

# Изменение интервала
echo -e "${YELLOW}[3/7] Изменение интервала на 5 минут...${NC}"

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
echo -e "${GREEN}✓ Интервал изменен на 5 минут${NC}"
echo ""

# Добавление Shadowsocks
echo -e "${YELLOW}[4/7] Добавление Shadowsocks 2022...${NC}"

# Проверяем, не установлен ли уже
if ss -tuln | grep -q ":8388 "; then
    echo -e "${YELLOW}⚠ Shadowsocks уже работает на порту 8388, пропускаем${NC}"
else
    if [ -f "add-shadowsocks.sh" ]; then
        bash add-shadowsocks.sh
        echo -e "${GREEN}✓ Shadowsocks 2022 добавлен${NC}"
    else
        echo -e "${YELLOW}⚠ Скрипт add-shadowsocks.sh не найден, пропускаем${NC}"
    fi
fi
echo ""

# Добавление WireGuard
echo -e "${YELLOW}[5/7] Добавление WireGuard...${NC}"

# Проверяем, не установлен ли уже
if systemctl is-active --quiet wg-quick@wg0 2>/dev/null; then
    echo -e "${YELLOW}⚠ WireGuard уже установлен, пропускаем${NC}"
else
    if [ -f "add-wireguard.sh" ]; then
        bash add-wireguard.sh
        echo -e "${GREEN}✓ WireGuard добавлен${NC}"
    else
        echo -e "${YELLOW}⚠ Скрипт add-wireguard.sh не найден, пропускаем${NC}"
    fi
fi
echo ""

# Обновление списка сайтов
echo -e "${YELLOW}[6/7] Обновление списка сайтов маскировки...${NC}"
mkdir -p /root/vpn-shield/sites
cp sites/russian-whitelist-extended.txt /root/vpn-shield/sites/russian-whitelist.txt
SITE_COUNT=$(grep -v "^#" /root/vpn-shield/sites/russian-whitelist.txt | grep -v "^$" | wc -l)
echo -e "${GREEN}✓ Список обновлен: $SITE_COUNT сайтов (было 58)${NC}"
echo ""

# Перезапуск мониторинга
echo -e "${YELLOW}[7/7] Перезапуск мониторинга...${NC}"
systemctl restart vpn-shield-monitor.timer
systemctl enable vpn-shield-monitor.timer
sleep 2

if systemctl is-active --quiet vpn-shield-monitor.timer; then
    echo -e "${GREEN}✓ Мониторинг перезапущен и работает${NC}"
else
    echo -e "${RED}✗ Ошибка запуска мониторинга${NC}"
fi
echo ""

# Проверка результатов
echo -e "${BLUE}Проверка результатов...${NC}"
echo ""

echo -e "${YELLOW}Статус протоколов:${NC}"
systemctl is-active --quiet xray && echo -e "  ${GREEN}✓${NC} Xray работает" || echo -e "  ${RED}✗${NC} Xray не работает"
systemctl is-active --quiet hysteria-server 2>/dev/null && echo -e "  ${GREEN}✓${NC} Hysteria2 работает" || echo -e "  ${YELLOW}⚠${NC} Hysteria2 не установлен"
systemctl is-active --quiet wg-quick@wg0 2>/dev/null && echo -e "  ${GREEN}✓${NC} WireGuard работает" || echo -e "  ${YELLOW}⚠${NC} WireGuard не установлен"

echo ""
echo -e "${YELLOW}Открытые порты:${NC}"
ss -tuln | grep -q ":443 " && echo -e "  ${GREEN}✓${NC} VLESS/REALITY (443)" || echo -e "  ${RED}✗${NC} VLESS/REALITY (443)"
ss -tuln | grep -q ":8388 " && echo -e "  ${GREEN}✓${NC} Shadowsocks (8388)" || echo -e "  ${YELLOW}⚠${NC} Shadowsocks (8388)"
ss -tuln | grep -q ":8443 " && echo -e "  ${GREEN}✓${NC} VMess (8443)" || echo -e "  ${RED}✗${NC} VMess (8443)"
ss -tuln | grep -q ":8444 " && echo -e "  ${GREEN}✓${NC} Trojan (8444)" || echo -e "  ${RED}✗${NC} Trojan (8444)"
ss -tuln | grep -q ":36712 " && echo -e "  ${GREEN}✓${NC} Hysteria2 (36712)" || echo -e "  ${YELLOW}⚠${NC} Hysteria2 (36712)"
ss -tuln | grep -q ":51820 " && echo -e "  ${GREEN}✓${NC} WireGuard (51820)" || echo -e "  ${YELLOW}⚠${NC} WireGuard (51820)"

echo ""
echo -e "${YELLOW}Мониторинг:${NC}"
systemctl is-active --quiet vpn-shield-monitor.timer && echo -e "  ${GREEN}✓${NC} Таймер работает" || echo -e "  ${RED}✗${NC} Таймер не работает"
NEXT_RUN=$(systemctl list-timers vpn-shield-monitor.timer | grep vpn-shield | awk '{print $1, $2}')
echo -e "  ${BLUE}Следующая проверка:${NC} $NEXT_RUN"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ✓ Обновление завершено успешно!                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Информация о подключении
echo -e "${BLUE}Информация о подключении:${NC}"
echo ""

if [ -f "/root/vpn-shield/info.txt" ]; then
    echo -e "  ${YELLOW}Полная информация:${NC}"
    echo -e "    cat /root/vpn-shield/info.txt"
    echo ""
fi

if [ -f "/root/vpn-shield/subscription.txt" ]; then
    echo -e "  ${YELLOW}Единая подписка (все протоколы):${NC}"
    echo -e "    cat /root/vpn-shield/subscription.txt"
    echo ""
fi

if [ -f "/root/vpn-shield/wireguard-client.conf" ]; then
    echo -e "  ${YELLOW}WireGuard конфигурация:${NC}"
    echo -e "    cat /root/vpn-shield/wireguard-client.conf"
    echo ""
fi

if [ -f "/root/vpn-shield/wireguard-qr.txt" ]; then
    echo -e "  ${YELLOW}WireGuard QR код:${NC}"
    echo -e "    cat /root/vpn-shield/wireguard-qr.txt"
    echo ""
fi

# Логи
echo -e "${BLUE}Мониторинг и логи:${NC}"
echo ""
echo -e "  ${YELLOW}Статус мониторинга:${NC}"
echo -e "    systemctl status vpn-shield-monitor.timer"
echo ""
echo -e "  ${YELLOW}Логи мониторинга:${NC}"
echo -e "    tail -f /var/log/vpn-shield-monitor.log"
echo ""
echo -e "  ${YELLOW}Ручной запуск проверки:${NC}"
echo -e "    /usr/local/bin/vpn-monitor.sh"
echo ""

# Ключевые улучшения
echo -e "${BLUE}Ключевые улучшения:${NC}"
echo ""
echo -e "  ${GREEN}✓${NC} Автосмена маскировки БЕЗ смены ключей"
echo -e "  ${GREEN}✓${NC} Клиенту НЕ нужно обновлять подписку"
echo -e "  ${GREEN}✓${NC} Проверка каждые 5 минут (было 3)"
echo -e "  ${GREEN}✓${NC} 6 протоколов вместо 4"
echo -e "  ${GREEN}✓${NC} 167 сайтов маскировки (было 58)"
echo ""

# Резервные копии
echo -e "${BLUE}Резервные копии:${NC}"
echo -e "  ${YELLOW}Сохранены в:${NC} $BACKUP_DIR"
echo -e "  ${YELLOW}Для отката:${NC} cp $BACKUP_DIR/* /usr/local/bin/"
echo ""

# Следующие шаги
echo -e "${BLUE}Рекомендации:${NC}"
echo ""
echo -e "  1. Проверьте логи мониторинга:"
echo -e "     ${YELLOW}tail -f /var/log/vpn-shield-monitor.log${NC}"
echo ""
echo -e "  2. Запустите ручную проверку:"
echo -e "     ${YELLOW}/usr/local/bin/vpn-monitor.sh${NC}"
echo ""
echo -e "  3. Получите новую подписку:"
echo -e "     ${YELLOW}cat /root/vpn-shield/subscription.txt${NC}"
echo ""
echo -e "  4. Для удаления веб-панели (опционально):"
echo -e "     ${YELLOW}bash remove-web-panel.sh${NC}"
echo ""

echo -e "${GREEN}Готово! VPN Shield обновлен и работает. 🚀${NC}"
echo ""
