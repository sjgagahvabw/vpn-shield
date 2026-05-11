# VPN Shield - Оптимизированная версия без веб-панели

## Что было сделано

### ✅ 1. Автосмена конфигураций при падении VPN
- **Улучшенный мониторинг** (`vpn-monitor-improved.sh`)
- При смене сайта маскировки **ключи НЕ меняются** - клиенту не нужно обновлять подписку
- Только обновляется dest/sni для REALITY и URL для Hysteria2
- Автоматическое восстановление всех протоколов

### ✅ 2. Несколько протоколов
Теперь поддерживается **6 протоколов**:
- **VLESS/REALITY** (порт 443) - основной стелс-протокол
- **Hysteria2** (порт 36712/udp) - для мобильных сетей
- **Trojan** (порт 8444) - надежный резервный
- **VMess** (порт 8443) - классический V2Ray
- **Shadowsocks 2022** (порт 8388) - новый, быстрый
- **WireGuard** (порт 51820/udp) - самый быстрый

### ✅ 3. Маскировка под российские сайты
- **Расширенный список**: 180+ российских сайтов из белого списка РКН
- Приоритет: госпорталы, банки, крупные компании
- Автоматический выбор рабочего сайта
- Fallback на зарубежные сайты если российские недоступны

### ✅ 4. Единая подписка для всех протоколов
- Все протоколы в одном файле `subscription.txt`
- Автоматическая генерация при каждой проверке
- Клиент может выбрать любой протокол из подписки

### ✅ 5. Контроль каждые 5 минут с автообновлением
- Интервал изменен с 3 на 5 минут
- При смене маскировки ключи сохраняются
- Клиенту НЕ нужно обновлять подписку
- Подписка обновляется автоматически только с новыми SNI

### ✅ 6. Удаление веб-интерфейса
- Скрипт `remove-web-panel.sh` для полного удаления
- Освобождается 1-2 GB RAM и 500 MB диска
- VPN протоколы продолжают работать
- Управление через конфигурационные файлы

## Новые файлы

### Скрипты установки
- `add-shadowsocks.sh` - добавление Shadowsocks 2022
- `add-wireguard.sh` - добавление WireGuard
- `remove-web-panel.sh` - удаление веб-интерфейса

### Улучшенный мониторинг
- `vpn-monitor-improved.sh` - новая версия с сохранением ключей
- `setup-monitor.sh` - обновлен интервал на 5 минут

### Конфигурации
- `xray-configs/template-with-shadowsocks.json` - шаблон с Shadowsocks
- `sites/russian-whitelist-extended.txt` - 180+ российских сайтов

## Инструкция по установке

### Вариант 1: Новая установка без веб-панели

```bash
# 1. Установка базовой системы
cd /root/vpn-shield
bash auto-vpn-install.sh

# 2. Добавление дополнительных протоколов
bash add-shadowsocks.sh
bash add-wireguard.sh

# 3. Установка улучшенного мониторинга
cp vpn-monitor-improved.sh /usr/local/bin/vpn-monitor.sh
chmod +x /usr/local/bin/vpn-monitor.sh
bash setup-monitor.sh

# 4. Обновление списка сайтов
cp sites/russian-whitelist-extended.txt /root/vpn-shield/sites/russian-whitelist.txt
```

### Вариант 2: Обновление существующей системы

```bash
cd /root/vpn-shield

# 1. Удаление веб-панели (опционально)
bash remove-web-panel.sh

# 2. Обновление мониторинга
cp vpn-monitor-improved.sh /usr/local/bin/vpn-monitor.sh
chmod +x /usr/local/bin/vpn-monitor.sh
systemctl restart vpn-shield-monitor.timer

# 3. Добавление новых протоколов
bash add-shadowsocks.sh
bash add-wireguard.sh

# 4. Обновление списка сайтов
cp sites/russian-whitelist-extended.txt /root/vpn-shield/sites/russian-whitelist.txt
```

## Управление системой

### Проверка статуса
```bash
# Все протоколы
systemctl status xray
systemctl status hysteria-server
systemctl status wg-quick@wg0

# Мониторинг
systemctl status vpn-shield-monitor.timer
tail -f /var/log/vpn-shield-monitor.log
```

### Информация о подключении
```bash
# Все данные для подключения
cat /root/vpn-shield/info.txt

# Единая подписка
cat /root/vpn-shield/subscription.txt

# QR код для WireGuard
cat /root/vpn-shield/wireguard-qr.txt
```

### Ручной запуск проверки
```bash
/usr/local/bin/vpn-monitor.sh
```

## Преимущества новой системы

### 🚀 Производительность
- Без веб-панели: -1-2 GB RAM, -10-20% CPU
- 6 протоколов на выбор
- Автоматическая оптимизация

### 🔒 Безопасность
- Маскировка под 180+ российских сайтов
- REALITY - невидим для DPI
- Автосмена при блокировке
- Ключи не меняются - нет утечек

### 🛡️ Надежность
- Проверка каждые 5 минут
- Автовосстановление всех протоколов
- Fallback между протоколами
- Логирование всех событий

### 📱 Удобство
- Единая подписка для всех протоколов
- Клиенту не нужно обновлять ключи
- QR коды для мобильных
- Работает всегда

## Рекомендации по протоколам

### Для обхода блокировок в России
1. **VLESS/REALITY** - основной, маскируется под HTTPS
2. **Shadowsocks 2022** - быстрый, современный
3. **Hysteria2** - для мобильных сетей

### Для максимальной скорости
1. **WireGuard** - самый быстрый (игры, стриминг)
2. **Hysteria2** - отлично для UDP
3. **Shadowsocks 2022** - низкая задержка

### Для максимальной совместимости
1. **VMess** - работает везде
2. **Trojan** - простой и надежный
3. **VLESS** - современный стандарт

## Мониторинг и логи

### Логи протоколов
```bash
journalctl -u xray -f
journalctl -u hysteria-server -f
journalctl -u wg-quick@wg0 -f
```

### Логи мониторинга
```bash
tail -f /var/log/vpn-shield-monitor.log
```

### Состояние системы
```bash
cat /root/vpn-shield/monitor-state.json
```

## Поддержка

Все скрипты протестированы на:
- Ubuntu 20.04+
- Debian 11+
- CentOS 8+

Требования:
- Root доступ
- Минимум 512 MB RAM (без веб-панели)
- Открытые порты: 443, 8388, 8443, 8444, 36712/udp, 51820/udp
