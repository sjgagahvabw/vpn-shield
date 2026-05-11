#!/bin/bash

#############################################
# VPN Shield - Улучшенный мониторинг
# Автосмена маскировки БЕЗ смены ключей
# Проверка каждые 5 минут
#############################################

set -e

XRAY_CONFIG="/usr/local/etc/xray/config.json"
HYSTERIA_CONFIG="/etc/hysteria/config.yaml"
LOG_FILE="/var/log/vpn-shield-monitor.log"
STATE_FILE="/root/vpn-shield/monitor-state.json"
INFO_FILE="/root/vpn-shield/info.txt"
SUBSCRIPTION_FILE="/root/vpn-shield/subscription.txt"

# Списки сайтов для маскировки
RUSSIAN_SITES_FILE="/root/vpn-shield/sites/russian-whitelist.txt"
FOREIGN_SITES_FILE="/root/vpn-shield/sites/foreign-sites.txt"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Проверка доступности сайта
test_site() {
    local site=$1
    local domain=$(echo "$site" | cut -d':' -f1)
    timeout 5 curl -s -o /dev/null -w "%{http_code}" "https://$domain" 2>/dev/null | grep -q "200\|301\|302"
}

# Поиск рабочего сайта (приоритет - российские)
find_working_site() {
    local use_russian=${1:-true}
    
    # Сначала пробуем российские сайты
    if [ "$use_russian" = "true" ] && [ -f "$RUSSIAN_SITES_FILE" ]; then
        log "Поиск рабочего российского сайта..."
        while IFS= read -r site || [ -n "$site" ]; do
            # Пропускаем комментарии и пустые строки
            [[ "$site" =~ ^#.*$ ]] && continue
            [[ -z "$site" ]] && continue
            
            local domain=$(echo "$site" | cut -d':' -f1)
            if test_site "$domain"; then
                log "✓ Найден рабочий российский сайт: $domain"
                echo "$site"
                return 0
            fi
        done < "$RUSSIAN_SITES_FILE"
    fi
    
    # Если российские не работают, пробуем зарубежные
    if [ -f "$FOREIGN_SITES_FILE" ]; then
        log "Поиск рабочего зарубежного сайта..."
        while IFS= read -r site || [ -n "$site" ]; do
            [[ "$site" =~ ^#.*$ ]] && continue
            [[ -z "$site" ]] && continue
            
            local domain=$(echo "$site" | cut -d':' -f1)
            if test_site "$domain"; then
                log "✓ Найден рабочий зарубежный сайт: $domain"
                echo "$site"
                return 0
            fi
        done < "$FOREIGN_SITES_FILE"
    fi
    
    # Запасной вариант
    log "⚠ Используется запасной сайт: www.cloudflare.com"
    echo "www.cloudflare.com:443"
    return 1
}

# Получение текущих данных VLESS
get_vless_data() {
    local uuid=$(jq -r '.inbounds[0].settings.clients[0].id // empty' "$XRAY_CONFIG" 2>/dev/null)
    local sni=$(jq -r '.inbounds[0].streamSettings.realitySettings.serverNames[0] // empty' "$XRAY_CONFIG" 2>/dev/null)
    local dest=$(jq -r '.inbounds[0].streamSettings.realitySettings.dest // empty' "$XRAY_CONFIG" 2>/dev/null)
    local public_key=$(jq -r '.inbounds[0].streamSettings.realitySettings.publicKey // empty' "$XRAY_CONFIG" 2>/dev/null)
    local private_key=$(jq -r '.inbounds[0].streamSettings.realitySettings.privateKey // empty' "$XRAY_CONFIG" 2>/dev/null)
    local short_id=$(jq -r '.inbounds[0].streamSettings.realitySettings.shortIds[1] // empty' "$XRAY_CONFIG" 2>/dev/null)
    
    echo "$uuid|$sni|$dest|$public_key|$private_key|$short_id"
}

# Проверка работы VLESS/REALITY
check_vless() {
    if ! systemctl is-active --quiet xray; then
        log "⚠ VLESS: Xray не запущен"
        return 1
    fi
    
    local data=$(get_vless_data)
    local dest=$(echo "$data" | cut -d'|' -f3)
    local domain=$(echo "$dest" | cut -d':' -f1)
    
    if [ -z "$domain" ]; then
        log "⚠ VLESS: Не удалось получить домен маскировки"
        return 1
    fi
    
    if test_site "$domain"; then
        log "✓ VLESS: Работает ($domain)"
        return 0
    else
        log "✗ VLESS: Сайт маскировки недоступен ($domain)"
        return 1
    fi
}

# Обновление конфигурации VLESS (ТОЛЬКО маскировка, ключи НЕ меняем!)
update_vless_config() {
    local new_site=$1
    local dest="$new_site"
    local domain=$(echo "$new_site" | cut -d':' -f1)
    
    log "Обновление VLESS: маскировка под $domain (ключи сохраняются)"
    
    # Получаем текущие ключи
    local data=$(get_vless_data)
    local current_private_key=$(echo "$data" | cut -d'|' -f5)
    local current_public_key=$(echo "$data" | cut -d'|' -f4)
    
    # Если ключей нет - генерируем новые
    if [ -z "$current_private_key" ] || [ -z "$current_public_key" ]; then
        log "Генерация новых ключей (первый запуск)..."
        local keys_output=$(/usr/local/bin/xray x25519 2>&1)
        current_private_key=$(echo "$keys_output" | grep -oP 'Private key: \K[A-Za-z0-9_-]+' || echo "$keys_output" | awk '/Private/{print $NF}')
        current_public_key=$(echo "$keys_output" | grep -oP 'Public key: \K[A-Za-z0-9_-]+' || echo "$keys_output" | awk '/Public/{print $NF}')
        
        if [ -z "$current_private_key" ] || [ -z "$current_public_key" ]; then
            log "✗ VLESS: Ошибка генерации ключей"
            return 1
        fi
    fi
    
    # Обновляем ТОЛЬКО dest и serverNames, ключи оставляем прежними
    jq --arg dest "$dest" \
       --arg sni "$domain" \
       --arg privkey "$current_private_key" \
       --arg pubkey "$current_public_key" \
       '.inbounds[0].streamSettings.realitySettings.dest = $dest |
        .inbounds[0].streamSettings.realitySettings.serverNames = [$sni] |
        .inbounds[0].streamSettings.realitySettings.privateKey = $privkey |
        .inbounds[0].streamSettings.realitySettings.publicKey = $pubkey' \
       "$XRAY_CONFIG" > "${XRAY_CONFIG}.tmp"
    
    if [ $? -eq 0 ]; then
        mv "${XRAY_CONFIG}.tmp" "$XRAY_CONFIG"
        systemctl restart xray
        sleep 3
        
        if systemctl is-active --quiet xray; then
            log "✓ VLESS: Маскировка обновлена успешно (ключи не изменились)"
            
            # Обновляем info.txt
            if [ -f "$INFO_FILE" ]; then
                sed -i "s|^SNI:.*|SNI: $domain|" "$INFO_FILE"
                sed -i "s|^Masquerade:.*|Masquerade: $domain|" "$INFO_FILE"
            fi
            
            return 0
        else
            log "✗ VLESS: Ошибка перезапуска Xray"
            return 1
        fi
    else
        log "✗ VLESS: Ошибка обновления конфига"
        rm -f "${XRAY_CONFIG}.tmp"
        return 1
    fi
}

# Проверка работы Hysteria2
check_hysteria() {
    if ! systemctl is-active --quiet hysteria-server 2>/dev/null; then
        log "⚠ Hysteria2: Сервис не запущен"
        return 1
    fi
    
    if [ ! -f "$HYSTERIA_CONFIG" ]; then
        log "⚠ Hysteria2: Конфиг не найден"
        return 1
    fi
    
    # Проверяем порт
    if ss -tuln | grep -q ":36712 "; then
        log "✓ Hysteria2: Работает (порт 36712)"
        return 0
    else
        log "✗ Hysteria2: Порт не слушается"
        return 1
    fi
}

# Обновление конфигурации Hysteria2 (ТОЛЬКО маскировка, пароль НЕ меняем!)
update_hysteria_config() {
    local new_site=$1
    local domain=$(echo "$new_site" | cut -d':' -f1)
    
    log "Обновление Hysteria2: маскировка под $domain (пароль сохраняется)"
    
    # Обновляем ТОЛЬКО URL маскировки
    sed -i "s|url:.*|url: https://$domain|" "$HYSTERIA_CONFIG"
    
    systemctl restart hysteria-server
    sleep 2
    
    if systemctl is-active --quiet hysteria-server; then
        log "✓ Hysteria2: Маскировка обновлена (пароль не изменился)"
        
        # Обновляем info.txt
        if [ -f "$INFO_FILE" ]; then
            sed -i "s|^Hysteria2 Masquerade:.*|Hysteria2 Masquerade: $domain|" "$INFO_FILE"
        fi
        
        return 0
    else
        log "✗ Hysteria2: Ошибка перезапуска"
        return 1
    fi
}

# Проверка работы Trojan
check_trojan() {
    if ! systemctl is-active --quiet xray; then
        return 1
    fi
    
    # Проверяем порт Trojan (8444)
    if ss -tuln | grep -q ":8444 "; then
        log "✓ Trojan: Работает (порт 8444)"
        return 0
    else
        log "✗ Trojan: Порт не слушается"
        return 1
    fi
}

# Восстановление Trojan (перезапуск Xray)
restore_trojan() {
    log "Восстановление Trojan: перезапуск Xray"
    
    systemctl restart xray
    sleep 2
    
    if systemctl is-active --quiet xray && ss -tuln | grep -q ":8444 "; then
        log "✓ Trojan: Восстановлен"
        return 0
    else
        log "✗ Trojan: Ошибка восстановления"
        return 1
    fi
}

# Проверка работы VMess
check_vmess() {
    if ! systemctl is-active --quiet xray; then
        return 1
    fi
    
    # Проверяем порт VMess (8443)
    if ss -tuln | grep -q ":8443 "; then
        log "✓ VMess: Работает (порт 8443)"
        return 0
    else
        log "✗ VMess: Порт не слушается"
        return 1
    fi
}

# Восстановление VMess (перезапуск Xray)
restore_vmess() {
    log "Восстановление VMess: перезапуск Xray"
    
    systemctl restart xray
    sleep 2
    
    if systemctl is-active --quiet xray && ss -tuln | grep -q ":8443 "; then
        log "✓ VMess: Восстановлен"
        return 0
    else
        log "✗ VMess: Ошибка восстановления"
        return 1
    fi
}

# Генерация единой подписки
generate_subscription() {
    log "Генерация единой подписки..."
    
    if [ ! -f "$INFO_FILE" ]; then
        log "⚠ Файл info.txt не найден, пропускаем генерацию подписки"
        return
    fi
    
    local server_ip=$(grep "Server IP:" "$INFO_FILE" | awk '{print $3}')
    local vless_uuid=$(grep "UUID:" "$INFO_FILE" | awk '{print $2}')
    local vless_pubkey=$(grep "Public Key:" "$INFO_FILE" | awk '{print $3}')
    local vless_sid=$(grep "Short ID:" "$INFO_FILE" | awk '{print $3}')
    local vless_sni=$(grep "SNI:" "$INFO_FILE" | awk '{print $2}')
    local hysteria_pass=$(grep "Hysteria2 Password:" "$INFO_FILE" | awk '{print $3}')
    local trojan_pass=$(grep "Trojan Password:" "$INFO_FILE" | awk '{print $3}')
    local vmess_uuid=$(grep "VMess UUID:" "$INFO_FILE" | awk '{print $3}')
    
    # VLESS/REALITY ссылка
    local vless_link="vless://${vless_uuid}@${server_ip}:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${vless_sni}&fp=chrome&pbk=${vless_pubkey}&sid=${vless_sid}&type=tcp&headerType=none#VPN-Shield-VLESS"
    
    # Hysteria2 ссылка
    local hysteria_link="hysteria2://${hysteria_pass}@${server_ip}:36712?insecure=1&sni=${vless_sni}#VPN-Shield-Hysteria2"
    
    # Trojan ссылка
    local trojan_link="trojan://${trojan_pass}@${server_ip}:8444?security=tls&type=tcp&headerType=none#VPN-Shield-Trojan"
    
    # VMess ссылка (base64)
    local vmess_json=$(cat <<EOF
{
  "v": "2",
  "ps": "VPN-Shield-VMess",
  "add": "${server_ip}",
  "port": "8443",
  "id": "${vmess_uuid}",
  "aid": "0",
  "net": "ws",
  "type": "none",
  "host": "",
  "path": "/vmess",
  "tls": "tls"
}
EOF
)
    local vmess_link="vmess://$(echo -n "$vmess_json" | base64 -w 0)"
    
    # Создаем подписку (все ссылки в одном файле)
    cat > "$SUBSCRIPTION_FILE" <<EOF
$vless_link
$hysteria_link
$trojan_link
$vmess_link
EOF
    
    log "✓ Подписка обновлена: $SUBSCRIPTION_FILE"
}

# Сохранение состояния
save_state() {
    local check_time=$(date +%s)
    local vless_status=$1
    local hysteria_status=$2
    local trojan_status=$3
    local vmess_status=$4
    
    mkdir -p "$(dirname "$STATE_FILE")"
    cat > "$STATE_FILE" <<EOF
{
  "last_check": $check_time,
  "vless_status": "$vless_status",
  "hysteria_status": "$hysteria_status",
  "trojan_status": "$trojan_status",
  "vmess_status": "$vmess_status"
}
EOF
}

# Основная логика
main() {
    log "=== Проверка VPN Shield (все протоколы) ==="
    
    local vless_ok=false
    local hysteria_ok=false
    local trojan_ok=false
    local vmess_ok=false
    local all_dead=true
    
    # Проверяем VLESS/REALITY
    if check_vless; then
        vless_ok=true
        all_dead=false
    else
        log "Попытка восстановления VLESS..."
        local new_site=$(find_working_site true)
        if update_vless_config "$new_site"; then
            vless_ok=true
            all_dead=false
        fi
    fi
    
    # Проверяем Hysteria2
    if check_hysteria; then
        hysteria_ok=true
        all_dead=false
    else
        log "Попытка восстановления Hysteria2..."
        local new_site=$(find_working_site true)
        if update_hysteria_config "$new_site"; then
            hysteria_ok=true
            all_dead=false
        fi
    fi
    
    # Проверяем Trojan
    if check_trojan; then
        trojan_ok=true
        all_dead=false
    else
        log "Попытка восстановления Trojan..."
        if restore_trojan; then
            trojan_ok=true
            all_dead=false
        fi
    fi
    
    # Проверяем VMess
    if check_vmess; then
        vmess_ok=true
        all_dead=false
    else
        log "Попытка восстановления VMess..."
        if restore_vmess; then
            vmess_ok=true
            all_dead=false
        fi
    fi
    
    # Если все протоколы мертвы - обновляем маскировку
    if [ "$all_dead" = true ]; then
        log "⚠⚠⚠ ВСЕ ПРОТОКОЛЫ НЕДОСТУПНЫ! Обновление маскировки..."
        
        local new_site=$(find_working_site true)
        
        update_vless_config "$new_site"
        update_hysteria_config "$new_site"
        restore_trojan
        restore_vmess
        
        log "✓ Обновление завершено"
    fi
    
    # Генерируем подписку
    generate_subscription
    
    # Сохраняем состояние
    save_state "$vless_ok" "$hysteria_ok" "$trojan_ok" "$vmess_ok"
    
    log "=== Проверка завершена ==="
    log "Статус: VLESS=$vless_ok | Hysteria2=$hysteria_ok | Trojan=$trojan_ok | VMess=$vmess_ok"
}

main "$@"
