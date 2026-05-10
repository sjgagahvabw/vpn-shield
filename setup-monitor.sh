#!/bin/bash

#############################################
# VPN Shield - Setup Auto Monitor
# Установка автоматического мониторинга
#############################################

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Установка автоматического мониторинга VPN Shield...${NC}"

# Скачиваем скрипт мониторинга
wget -q -O /usr/local/bin/vpn-monitor.sh https://raw.githubusercontent.com/sjgagahvabw/vpn-shield/main/vpn-monitor.sh
chmod +x /usr/local/bin/vpn-monitor.sh

# Создаем systemd service для мониторинга
cat > /etc/systemd/system/vpn-shield-monitor.service <<'EOF'
[Unit]
Description=VPN Shield Auto Monitor
After=xray.service
Requires=xray.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/vpn-monitor.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Создаем systemd timer (запуск каждые 5 минут)
cat > /etc/systemd/system/vpn-shield-monitor.timer <<'EOF'
[Unit]
Description=VPN Shield Auto Monitor Timer
Requires=vpn-shield-monitor.service

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
AccuracySec=1min

[Install]
WantedBy=timers.target
EOF

# Перезагружаем systemd и включаем таймер
systemctl daemon-reload
systemctl enable vpn-shield-monitor.timer
systemctl start vpn-shield-monitor.timer

echo ""
echo -e "${GREEN}✓ Автоматический мониторинг установлен!${NC}"
echo ""
echo "Мониторинг будет проверять VPN каждые 5 минут и автоматически:"
echo "  • Проверять работу Xray"
echo "  • Проверять доступность текущего сайта маскировки"
echo "  • Автоматически переключаться на другой сайт если текущий недоступен"
echo "  • Перезапускать Xray при необходимости"
echo ""
echo "Управление:"
echo "  Статус:      systemctl status vpn-shield-monitor.timer"
echo "  Логи:        tail -f /var/log/vpn-shield-monitor.log"
echo "  Запуск:      systemctl start vpn-shield-monitor.service"
echo "  Остановка:   systemctl stop vpn-shield-monitor.timer"
echo ""
