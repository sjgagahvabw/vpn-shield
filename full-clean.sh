#!/bin/bash

echo "╔════════════════════════════════════════════════════════════╗"
echo "║           ПОЛНАЯ ОЧИСТКА СЕРВЕРА ОТ VPN SHIELD            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

read -p "Вы уверены? Это удалит ВСЁ! (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Отменено"
    exit 0
fi

echo ""
echo "[1/8] Остановка всех сервисов..."
systemctl stop xray 2>/dev/null
systemctl stop xray@* 2>/dev/null
systemctl stop hysteria-server 2>/dev/null
systemctl stop wg-quick@wg0 2>/dev/null
systemctl stop vpn-shield-monitor.timer 2>/dev/null
systemctl stop vpn-shield-monitor.service 2>/dev/null

echo "[2/8] Отключение автозапуска..."
systemctl disable xray 2>/dev/null
systemctl disable xray@* 2>/dev/null
systemctl disable hysteria-server 2>/dev/null
systemctl disable wg-quick@wg0 2>/dev/null
systemctl disable vpn-shield-monitor.timer 2>/dev/null

echo "[3/8] Удаление бинарных файлов..."
rm -f /usr/local/bin/xray
rm -f /usr/local/bin/hysteria
rm -f /usr/local/bin/vpn-monitor.sh

echo "[4/8] Удаление конфигураций..."
rm -rf /usr/local/etc/xray
rm -rf /etc/xray
rm -rf /etc/hysteria
rm -rf /etc/wireguard/wg0.conf
rm -rf /root/vpn-shield
rm -rf /root/vpn-shield-backup-*

echo "[5/8] Удаление systemd сервисов..."
rm -f /etc/systemd/system/xray.service
rm -f /etc/systemd/system/xray@.service
rm -rf /etc/systemd/system/xray.service.d
rm -f /etc/systemd/system/xray@*.service
rm -f /etc/systemd/system/hysteria-server.service
rm -f /etc/systemd/system/vpn-shield-monitor.service
rm -f /etc/systemd/system/vpn-shield-monitor.timer
systemctl daemon-reload

echo "[6/8] Удаление логов..."
rm -f /var/log/vpn-shield-monitor.log
rm -f /var/log/xray/*.log
rm -rf /var/log/xray

echo "[7/8] Закрытие портов в firewall..."
ufw delete allow 443/tcp 2>/dev/null
ufw delete allow 8388/tcp 2>/dev/null
ufw delete allow 8388/udp 2>/dev/null
ufw delete allow 8443/tcp 2>/dev/null
ufw delete allow 8444/tcp 2>/dev/null
ufw delete allow 36712/udp 2>/dev/null
ufw delete allow 51820/udp 2>/dev/null

echo "[8/8] Очистка временных файлов..."
rm -f /root/vpn-shield-improvements.tar.gz
rm -f /root/auto-vpn-install.sh
rm -f /root/optimized-install.sh

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              ✓ СЕРВЕР ПОЛНОСТЬЮ ОЧИЩЕН!                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Сервер готов к новой установке."
echo ""
