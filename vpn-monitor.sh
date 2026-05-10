#!/bin/bash

#############################################
# VPN Shield - Auto Monitor & Heal
# Автоматический мониторинг и восстановление
#############################################

XRAY_CONFIG="/usr/local/etc/xray/config.json"
LOG_FILE="/var/log/vpn-shield-monitor.log"
STATE_FILE="/root/vpn-shield/monitor-state.json"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

test_site() {
    local site=$1
    timeout 5 curl -s -o /dev/null -w "%{http_code}" "https://$site" 2>/dev/null | grep -q "200\|301\|302"
}

get_current_sni() {
    jq -r '.inbounds[0].streamSettings.realitySettings.serverNames[0]' "$XRAY_CONFIG" 2>/dev/null
}

get_current_dest() {
    jq -r '.inbounds[0].streamSettings.realitySettings.dest' "$XRAY_CONFIG" 2>/dev/null
}

check_xray_running() {
    systemctl is-active --quiet xray
}

find_working_site() {
    local sites=(
        "www.microsoft.com:443|www.microsoft.com,login.microsoft.com"
        "www.apple.com:443|www.apple.com,www.icloud.com"
        "www.cloudflare.com:443|www.cloudflare.com,dash.cloudflare.com"
        "www.amazon.com:443|www.amazon.com,aws.amazon.com"
        "www.cisco.com:443|www.cisco.com,www.webex.com"
        "www.oracle.com:443|www.oracle.com,cloud.oracle.com"
        "www.ibm.com:443|www.ibm.com,cloud.ibm.com"
        "www.samsung.com:443|www.samsung.com"
        "www.zoom.us:443|www.zoom.us,zoom.us"
        "www.booking.com:443|www.booking.com"
        "www.speedtest.net:443|www.speedtest.net"
        "www.ubuntu.com:443|www.ubuntu.com"
        "www.debian.org:443|www.debian.org"
    )
    
    for site_config in "${sites[@]}"; do
        local site=$(echo "$site_config" | cut -d'|' -f1)
        local domain=$(echo "$site" | cut -d':' -f1)
        
        if test_site "$domain"; then
            echo "$site_config"
            return 0
        fi
    done
    
    # Запасной вариант
    echo "www.cloudflare.com:443|www.cloudflare.com,dash.cloudflare.com"
    return 1
}

update_config() {
    local new_site_config=$1
    local dest=$(echo "$new_site_config" | cut -d'|' -f1)
    local sni_list=$(echo "$new_site_config" | cut -d'|' -f2)
    local sni_primary=$(echo "$sni_list" | cut -d',' -f1)
    local sni_secondary=$(echo "$sni_list" | cut -d',' -f2)
    
    log "Обновление конфигурации: маскировка под $sni_primary"
    
    # Обновляем dest и serverNames в конфиге
    jq --arg dest "$dest" \
       --arg sni1 "$sni_primary" \
       --arg sni2 "$sni_secondary" \
       '.inbounds[0].streamSettings.realitySettings.dest = $dest |
        .inbounds[0].streamSettings.realitySettings.serverNames = [$sni1, $sni2]' \
       "$XRAY_CONFIG" > "${XRAY_CONFIG}.tmp"
    
    if [ $? -eq 0 ]; then
        mv "${XRAY_CONFIG}.tmp" "$XRAY_CONFIG"
        systemctl restart xray
        sleep 3
        
        if check_xray_running; then
            log "✓ Конфигурация обновлена успешно"
            
            # Обновляем ссылку для подключения
            update_connection_link "$sni_primary"
            return 0
        else
            log "✗ Ошибка перезапуска Xray"
            return 1
        fi
    else
        log "✗ Ошибка обновления конфига"
        rm -f "${XRAY_CONFIG}.tmp"
        return 1
    fi
}

update_connection_link() {
    local sni=$1
    local info_file="/root/vpn-shield/info.txt"
    
    if [ -f "$info_file" ]; then
        local server_ip=$(grep "Server IP:" "$info_file" | awk '{print $3}')
        local uuid=$(grep "UUID:" "$info_file" | awk '{print $2}')
        local public_key=$(grep "Public Key:" "$info_file" | awk '{print $3}')
        local short_id=$(grep "Short ID:" "$info_file" | awk '{print $3}')
        
        local new_link="vless://${uuid}@${server_ip}:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${sni}&fp=chrome&pbk=${public_key}&sid=${short_id}&type=tcp&headerType=none#VPN-Shield"
        
        echo "$new_link" > /root/vpn-shield/connection.txt
        
        # Обновляем info.txt
        sed -i "s|^SNI:.*|SNI: $sni|" "$info_file"
        sed -i "/^Connection Link:/,/^$/c\\Connection Link:\\n$new_link\\n" "$info_file"
        
        log "✓ Ссылка для подключения обновлена"
    fi
}

save_state() {
    local current_sni=$1
    local check_time=$(date +%s)
    
    mkdir -p "$(dirname "$STATE_FILE")"
    cat > "$STATE_FILE" <<EOF
{
  "last_check": $check_time,
  "current_sni": "$current_sni",
  "last_change": $check_time
}
EOF
}

main() {
    log "=== Проверка VPN Shield ==="
    
    # Проверяем запущен ли Xray
    if ! check_xray_running; then
        log "⚠ Xray не запущен, попытка перезапуска..."
        systemctl restart xray
        sleep 3
        
        if ! check_xray_running; then
            log "✗ Не удалось запустить Xray"
            exit 1
        fi
        log "✓ Xray перезапущен"
    fi
    
    # Получаем текущий SNI
    current_sni=$(get_current_sni)
    current_dest=$(get_current_dest)
    
    if [ -z "$current_sni" ]; then
        log "✗ Не удалось получить текущий SNI"
        exit 1
    fi
    
    log "Текущая маскировка: $current_sni"
    
    # Проверяем доступность текущего сайта
    current_domain=$(echo "$current_dest" | cut -d':' -f1)
    
    if test_site "$current_domain"; then
        log "✓ Текущий сайт доступен: $current_domain"
        save_state "$current_sni"
        exit 0
    fi
    
    log "⚠ Текущий сайт недоступен: $current_domain"
    log "Поиск нового рабочего сайта..."
    
    # Ищем новый рабочий сайт
    new_site=$(find_working_site)
    new_domain=$(echo "$new_site" | cut -d'|' -f1 | cut -d':' -f1)
    
    log "Найден рабочий сайт: $new_domain"
    
    # Обновляем конфигурацию
    if update_config "$new_site"; then
        log "✓ VPN Shield восстановлен с новой маскировкой"
        save_state "$(echo "$new_site" | cut -d'|' -f2 | cut -d',' -f1)"
        
        # Отправляем уведомление (опционально)
        if command -v mail &> /dev/null && [ -n "$ADMIN_EMAIL" ]; then
            echo "VPN Shield автоматически переключился на новый сайт: $new_domain" | \
                mail -s "VPN Shield: Автоматическое переключение" "$ADMIN_EMAIL"
        fi
    else
        log "✗ Не удалось обновить конфигурацию"
        exit 1
    fi
}

main "$@"
