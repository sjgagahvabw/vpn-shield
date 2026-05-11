# Инструкция по развертыванию улучшений VPN Shield

## 📦 Что было создано

### Новые скрипты (5 файлов)
1. `vpn-monitor-improved.sh` - улучшенный мониторинг (сохранение ключей)
2. `add-shadowsocks.sh` - добавление Shadowsocks 2022
3. `add-wireguard.sh` - добавление WireGuard
4. `remove-web-panel.sh` - удаление веб-панели
5. `optimized-install.sh` - быстрая установка без панели

### Конфигурации (2 файла)
6. `xray-configs/template-with-shadowsocks.json` - шаблон с Shadowsocks
7. `sites/russian-whitelist-extended.txt` - 167 российских сайтов

### Документация (3 файла)
8. `SUMMARY.md` - подробный отчет о всех улучшениях
9. `UPGRADE_GUIDE.md` - руководство по обновлению
10. `README_IMPROVED.md` - краткое описание

### Вспомогательные файлы
11. `test-improvements.sh` - проверка всех улучшений
12. `DEPLOYMENT.md` - этот файл

## ✅ Результаты проверки

```
✓ Все 10 файлов созданы
✓ Права на выполнение установлены
✓ Синтаксис всех скриптов корректен
✓ JSON конфигурации валидны
✓ 167 сайтов маскировки (было 58)
```

## 🚀 Варианты развертывания

### Вариант 1: Новая установка на чистом сервере

```bash
# На вашем компьютере
cd /Users/artemmalov/vpn-shield
tar -czf vpn-shield-improved.tar.gz \
    vpn-monitor-improved.sh \
    add-shadowsocks.sh \
    add-wireguard.sh \
    remove-web-panel.sh \
    optimized-install.sh \
    setup-monitor.sh \
    xray-configs/ \
    sites/ \
    *.md

# Скопируйте на сервер
scp vpn-shield-improved.tar.gz root@YOUR_SERVER_IP:/root/

# На сервере
ssh root@YOUR_SERVER_IP
cd /root
tar -xzf vpn-shield-improved.tar.gz
cd vpn-shield
bash optimized-install.sh
```

### Вариант 2: Обновление существующей системы

```bash
# На вашем компьютере
cd /Users/artemmalov/vpn-shield

# Скопируйте только новые файлы
scp vpn-monitor-improved.sh root@YOUR_SERVER_IP:/root/vpn-shield/
scp add-shadowsocks.sh root@YOUR_SERVER_IP:/root/vpn-shield/
scp add-wireguard.sh root@YOUR_SERVER_IP:/root/vpn-shield/
scp remove-web-panel.sh root@YOUR_SERVER_IP:/root/vpn-shield/
scp setup-monitor.sh root@YOUR_SERVER_IP:/root/vpn-shield/
scp sites/russian-whitelist-extended.txt root@YOUR_SERVER_IP:/root/vpn-shield/sites/

# На сервере
ssh root@YOUR_SERVER_IP
cd /root/vpn-shield

# 1. Обновите мониторинг (КРИТИЧНО!)
cp vpn-monitor-improved.sh /usr/local/bin/vpn-monitor.sh
chmod +x /usr/local/bin/vpn-monitor.sh

# 2. Обновите интервал на 5 минут
bash setup-monitor.sh

# 3. Добавьте Shadowsocks
bash add-shadowsocks.sh

# 4. Добавьте WireGuard
bash add-wireguard.sh

# 5. Обновите список сайтов
cp sites/russian-whitelist-extended.txt /root/vpn-shield/sites/russian-whitelist.txt

# 6. Перезапустите мониторинг
systemctl restart vpn-shield-monitor.timer

# 7. Проверьте работу
systemctl status vpn-shield-monitor.timer
tail -f /var/log/vpn-shield-monitor.log
```

### Вариант 3: Удаление веб-панели (опционально)

```bash
# На сервере
cd /root/vpn-shield
bash remove-web-panel.sh

# Это освободит:
# - 1-2 GB RAM
# - 500 MB диска
# - 10-20% CPU
```

## 📋 Пошаговая инструкция для обновления

### Шаг 1: Подготовка файлов

```bash
# На вашем Mac
cd /Users/artemmalov/vpn-shield

# Создайте архив с улучшениями
tar -czf vpn-shield-update.tar.gz \
    vpn-monitor-improved.sh \
    add-shadowsocks.sh \
    add-wireguard.sh \
    remove-web-panel.sh \
    setup-monitor.sh \
    sites/russian-whitelist-extended.txt \
    SUMMARY.md \
    UPGRADE_GUIDE.md \
    README_IMPROVED.md

# Проверьте архив
tar -tzf vpn-shield-update.tar.gz
```

### Шаг 2: Копирование на сервер

```bash
# Замените YOUR_SERVER_IP на IP вашего сервера
scp vpn-shield-update.tar.gz root@YOUR_SERVER_IP:/root/
```

### Шаг 3: Установка на сервере

```bash
# Подключитесь к серверу
ssh root@YOUR_SERVER_IP

# Распакуйте архив
cd /root
tar -xzf vpn-shield-update.tar.gz

# Перейдите в директорию
cd /root/vpn-shield

# Сделайте скрипты исполняемыми
chmod +x *.sh

# Прочитайте инструкцию
cat UPGRADE_GUIDE.md
```

### Шаг 4: Применение улучшений

```bash
# 1. Обновление мониторинга (ВАЖНО!)
echo "Обновление мониторинга..."
cp vpn-monitor-improved.sh /usr/local/bin/vpn-monitor.sh
chmod +x /usr/local/bin/vpn-monitor.sh
echo "✓ Мониторинг обновлен"

# 2. Изменение интервала на 5 минут
echo "Изменение интервала..."
bash setup-monitor.sh
echo "✓ Интервал изменен на 5 минут"

# 3. Добавление Shadowsocks
echo "Добавление Shadowsocks..."
bash add-shadowsocks.sh
echo "✓ Shadowsocks добавлен"

# 4. Добавление WireGuard
echo "Добавление WireGuard..."
bash add-wireguard.sh
echo "✓ WireGuard добавлен"

# 5. Обновление списка сайтов
echo "Обновление списка сайтов..."
cp sites/russian-whitelist-extended.txt /root/vpn-shield/sites/russian-whitelist.txt
echo "✓ Список обновлен (167 сайтов)"

# 6. Перезапуск мониторинга
echo "Перезапуск мониторинга..."
systemctl restart vpn-shield-monitor.timer
echo "✓ Мониторинг перезапущен"
```

### Шаг 5: Проверка работы

```bash
# Проверьте статус всех протоколов
echo "=== Статус протоколов ==="
systemctl status xray | grep Active
systemctl status hysteria-server | grep Active
systemctl status wg-quick@wg0 | grep Active

# Проверьте мониторинг
echo "=== Статус мониторинга ==="
systemctl status vpn-shield-monitor.timer

# Проверьте порты
echo "=== Открытые порты ==="
ss -tuln | grep -E ":(443|8388|8443|8444|36712|51820) "

# Запустите ручную проверку
echo "=== Ручная проверка ==="
/usr/local/bin/vpn-monitor.sh

# Посмотрите логи
echo "=== Последние логи ==="
tail -20 /var/log/vpn-shield-monitor.log
```

### Шаг 6: Получение данных для подключения

```bash
# Вся информация
cat /root/vpn-shield/info.txt

# Единая подписка
cat /root/vpn-shield/subscription.txt

# WireGuard конфиг
cat /root/vpn-shield/wireguard-client.conf

# WireGuard QR код
cat /root/vpn-shield/wireguard-qr.txt
```

## 🔍 Проверка улучшений

### Проверка 1: Ключи не меняются

```bash
# Запомните текущий Public Key
PUBLIC_KEY_BEFORE=$(jq -r '.inbounds[0].streamSettings.realitySettings.publicKey' /usr/local/etc/xray/config.json)
echo "Public Key до: $PUBLIC_KEY_BEFORE"

# Запустите мониторинг
/usr/local/bin/vpn-monitor.sh

# Проверьте Public Key после
PUBLIC_KEY_AFTER=$(jq -r '.inbounds[0].streamSettings.realitySettings.publicKey' /usr/local/etc/xray/config.json)
echo "Public Key после: $PUBLIC_KEY_AFTER"

# Они должны совпадать!
if [ "$PUBLIC_KEY_BEFORE" = "$PUBLIC_KEY_AFTER" ]; then
    echo "✓ Ключи НЕ изменились - работает правильно!"
else
    echo "✗ Ключи изменились - что-то не так"
fi
```

### Проверка 2: Все протоколы работают

```bash
# Проверка портов
echo "Проверка портов..."
ss -tuln | grep ":443 " && echo "✓ VLESS (443)"
ss -tuln | grep ":8388 " && echo "✓ Shadowsocks (8388)"
ss -tuln | grep ":8443 " && echo "✓ VMess (8443)"
ss -tuln | grep ":8444 " && echo "✓ Trojan (8444)"
ss -tuln | grep ":36712 " && echo "✓ Hysteria2 (36712)"
ss -tuln | grep ":51820 " && echo "✓ WireGuard (51820)"
```

### Проверка 3: Мониторинг работает каждые 5 минут

```bash
# Проверьте таймер
systemctl list-timers vpn-shield-monitor.timer

# Должно показать:
# NEXT: через ~5 минут
# LEFT: оставшееся время
# LAST: время последнего запуска
```

## 📊 Ожидаемые результаты

После применения всех улучшений:

### Протоколы
- ✅ VLESS/REALITY работает на порту 443
- ✅ Shadowsocks 2022 работает на порту 8388
- ✅ VMess работает на порту 8443
- ✅ Trojan работает на порту 8444
- ✅ Hysteria2 работает на порту 36712
- ✅ WireGuard работает на порту 51820

### Мониторинг
- ✅ Проверка каждые 5 минут
- ✅ Автосмена маскировки без смены ключей
- ✅ 167 сайтов для маскировки
- ✅ Логирование в /var/log/vpn-shield-monitor.log

### Файлы
- ✅ /root/vpn-shield/info.txt - информация о подключении
- ✅ /root/vpn-shield/subscription.txt - единая подписка
- ✅ /root/vpn-shield/wireguard-client.conf - конфиг WireGuard
- ✅ /root/vpn-shield/wireguard-qr.txt - QR код WireGuard

## 🐛 Решение проблем

### Проблема: Скрипт не запускается

```bash
# Проверьте права
ls -la /usr/local/bin/vpn-monitor.sh

# Должно быть: -rwxr-xr-x
# Если нет, исправьте:
chmod +x /usr/local/bin/vpn-monitor.sh
```

### Проблема: Порты не открываются

```bash
# Проверьте firewall
ufw status

# Откройте порты
ufw allow 443/tcp
ufw allow 8388/tcp
ufw allow 8388/udp
ufw allow 8443/tcp
ufw allow 8444/tcp
ufw allow 36712/udp
ufw allow 51820/udp
```

### Проблема: Мониторинг не работает

```bash
# Проверьте таймер
systemctl status vpn-shield-monitor.timer

# Перезапустите
systemctl restart vpn-shield-monitor.timer

# Запустите вручную
/usr/local/bin/vpn-monitor.sh
```

## 📞 Поддержка

Если возникли проблемы:

1. Проверьте логи: `tail -f /var/log/vpn-shield-monitor.log`
2. Проверьте статус: `systemctl status xray hysteria-server wg-quick@wg0`
3. Прочитайте документацию: `cat SUMMARY.md`

## ✅ Чеклист развертывания

- [ ] Файлы скопированы на сервер
- [ ] Скрипты сделаны исполняемыми
- [ ] Мониторинг обновлен
- [ ] Интервал изменен на 5 минут
- [ ] Shadowsocks добавлен
- [ ] WireGuard добавлен
- [ ] Список сайтов обновлен
- [ ] Все протоколы работают
- [ ] Мониторинг запущен
- [ ] Подписка сгенерирована
- [ ] Клиент подключен и работает

## 🎉 Готово!

После выполнения всех шагов ваш VPN Shield будет:
- Надежнее (6 протоколов)
- Умнее (автосмена без смены ключей)
- Быстрее (WireGuard, Shadowsocks 2022)
- Эффективнее (167 сайтов маскировки)

Удачи! 🚀
