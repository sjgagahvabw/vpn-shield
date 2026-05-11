#!/bin/bash

# VPN Shield - Быстрое развертывание улучшений
# Одна команда для применения всех изменений

# ============================================
# ВАРИАНТ 1: Копирование на сервер
# ============================================

# На вашем Mac:
cd /Users/artemmalov/vpn-shield

# Создайте архив с улучшениями
tar -czf vpn-shield-improvements.tar.gz \
    vpn-monitor-improved.sh \
    add-shadowsocks.sh \
    add-wireguard.sh \
    remove-web-panel.sh \
    apply-all-improvements.sh \
    setup-monitor.sh \
    sites/russian-whitelist-extended.txt \
    xray-configs/template-with-shadowsocks.json \
    SUMMARY.md \
    UPGRADE_GUIDE.md \
    DEPLOYMENT.md

# Скопируйте на сервер (замените YOUR_SERVER_IP)
scp vpn-shield-improvements.tar.gz root@YOUR_SERVER_IP:/root/

# ============================================
# ВАРИАНТ 2: На сервере
# ============================================

# Подключитесь к серверу
# ssh root@YOUR_SERVER_IP

# Распакуйте архив
# cd /root
# tar -xzf vpn-shield-improvements.tar.gz
# cd vpn-shield

# Примените все улучшения одной командой
# bash apply-all-improvements.sh

# ============================================
# РЕЗУЛЬТАТ
# ============================================

# После выполнения у вас будет:
# ✓ 6 протоколов (VLESS, Hysteria2, Trojan, VMess, Shadowsocks, WireGuard)
# ✓ 167 сайтов маскировки (было 58)
# ✓ Проверка каждые 5 минут (было 3)
# ✓ Автосмена маскировки БЕЗ смены ключей
# ✓ Клиенту НЕ нужно обновлять подписку

# ============================================
# ПРОВЕРКА
# ============================================

# Статус протоколов:
# systemctl status xray hysteria-server wg-quick@wg0

# Статус мониторинга:
# systemctl status vpn-shield-monitor.timer

# Логи:
# tail -f /var/log/vpn-shield-monitor.log

# Информация о подключении:
# cat /root/vpn-shield/info.txt

# Подписка:
# cat /root/vpn-shield/subscription.txt

echo "Инструкции выше показывают как развернуть улучшения"
echo "Скопируйте команды и выполните их на сервере"
