# VPN Shield - Руководство по установке

## Требования

- VPS/Dedicated сервер с Ubuntu 20.04+ или Debian 11+
- Минимум 1GB RAM, 1 CPU core, 10GB диска
- Root доступ
- Публичный IP адрес
- Домен (опционально, но рекомендуется)

## Быстрая установка

### 1. Подготовка сервера

```bash
# Обновите систему
apt update && apt upgrade -y

# Скачайте скрипт установки
wget https://raw.githubusercontent.com/yourusername/vpn-shield/main/scripts/install.sh

# Сделайте скрипт исполняемым
chmod +x install.sh

# Запустите установку
sudo ./install.sh
```

### 2. Настройка домена (опционально)

Если у вас есть домен, настройте DNS записи:

```
A запись: your-domain.com -> IP_вашего_сервера
A запись: panel.your-domain.com -> IP_вашего_сервера
```

### 3. Получение SSL сертификата

```bash
# Установите certbot
apt install certbot -y

# Получите сертификат
certbot certonly --standalone -d your-domain.com -d panel.your-domain.com

# Сертификаты будут в /etc/letsencrypt/live/your-domain.com/
```

### 4. Настройка конфигурации

```bash
cd /opt/vpn-shield

# Отредактируйте .env файл
nano .env
```

Измените следующие параметры:

```env
DOMAIN=your-domain.com
PANEL_DOMAIN=panel.your-domain.com
```

### 5. Запуск системы

```bash
cd /opt/vpn-shield

# Запустите Docker Compose
docker-compose up -d

# Проверьте статус
docker-compose ps
```

### 6. Доступ к панели управления

Откройте в браузере:
```
http://your-server-ip:8888
```

Или если настроили домен:
```
https://panel.your-domain.com
```

Используйте учетные данные из файла `.env`:
- Username: admin
- Password: (смотрите в .env файле)

## Настройка протоколов

### REALITY

REALITY уже настроен и работает на порту 443. Для генерации ключей:

```bash
docker exec vpn-shield-backend xray x25519
```

Скопируйте приватный ключ в конфигурацию Xray.

### Hysteria2

Hysteria2 работает на UDP порту 36712. Убедитесь, что порт открыт в firewall:

```bash
ufw allow 36712/udp
```

### Trojan

Trojan работает на порту 8444 с TLS.

### VMess

VMess работает на порту 8443 с WebSocket и TLS.

## Настройка Cloudflare (Domain Fronting)

1. Добавьте ваш домен в Cloudflare
2. Включите прокси (оранжевое облако) для записей
3. В настройках SSL/TLS выберите "Full (strict)"
4. Получите API токен в разделе "API Tokens"
5. Добавьте токен в `.env`:

```env
CLOUDFLARE_API_TOKEN=your_token_here
CLOUDFLARE_ZONE_ID=your_zone_id
```

## Создание пользователей

### Через веб-панель

1. Войдите в панель управления
2. Перейдите в раздел "Пользователи"
3. Нажмите "Добавить пользователя"
4. Заполните данные и выберите протоколы
5. Сохраните

### Через API

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "user1",
    "email": "user1@example.com",
    "password": "secure_password"
  }'
```

## Генерация конфигураций для клиентов

После создания пользователя, система автоматически генерирует конфигурации для всех включенных протоколов.

### Клиенты для разных платформ

**iOS:**
- Shadowrocket (платный)
- Stash (платный)
- Hiddify (бесплатный)

**Android:**
- v2rayNG (бесплатный)
- Hiddify (бесплатный)
- NekoBox (бесплатный)

**Windows:**
- v2rayN (бесплатный)
- Hiddify (бесплатный)

**macOS:**
- v2rayU (бесплатный)
- Hiddify (бесплатный)

**Linux:**
- Xray-core (CLI)
- Hiddify (GUI)

## Мониторинг

### Просмотр логов

```bash
# Все сервисы
docker-compose logs -f

# Только backend
docker-compose logs -f backend

# Xray
docker exec vpn-shield-backend tail -f /var/log/vpn-shield/xray.log

# Hysteria
docker exec vpn-shield-backend tail -f /var/log/vpn-shield/hysteria.log
```

### Проверка статуса

```bash
# Статус контейнеров
docker-compose ps

# Использование ресурсов
docker stats
```

## Обновление

```bash
cd /opt/vpn-shield

# Остановите сервисы
docker-compose down

# Обновите код
git pull

# Пересоберите образы
docker-compose build

# Запустите снова
docker-compose up -d
```

## Резервное копирование

### Автоматическое резервное копирование

```bash
# Создайте скрипт backup.sh
cat > /opt/vpn-shield/backup.sh <<'EOF'
#!/bin/bash
BACKUP_DIR="/backup/vpn-shield"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup database
docker exec vpn-shield-db pg_dump -U vpnshield vpnshield > $BACKUP_DIR/db_$DATE.sql

# Backup configs
tar -czf $BACKUP_DIR/configs_$DATE.tar.gz /opt/vpn-shield/xray-configs /opt/vpn-shield/hysteria-configs

# Keep only last 7 backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
EOF

chmod +x /opt/vpn-shield/backup.sh

# Добавьте в cron (каждый день в 3:00)
echo "0 3 * * * /opt/vpn-shield/backup.sh" | crontab -
```

## Устранение неполадок

### Порты заняты

Если порты 443, 8443, 8444 уже используются:

```bash
# Проверьте, что использует порт
netstat -tulpn | grep :443

# Остановите конфликтующий сервис
systemctl stop nginx  # или apache2
```

### Проблемы с подключением

1. Проверьте firewall:
```bash
ufw status
```

2. Проверьте, что сервисы запущены:
```bash
docker-compose ps
```

3. Проверьте логи:
```bash
docker-compose logs backend
```

### REALITY не работает

1. Убедитесь, что сгенерированы ключи
2. Проверьте, что dest домен доступен:
```bash
curl -I https://www.microsoft.com
```

### Hysteria2 не работает

1. Проверьте, что UDP порт открыт:
```bash
nc -u -l 36712
```

2. Убедитесь, что провайдер не блокирует UDP

## Оптимизация производительности

### Увеличение лимитов

```bash
# Добавьте в /etc/sysctl.conf
cat >> /etc/sysctl.conf <<EOF
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.core.netdev_max_backlog=250000
net.ipv4.tcp_max_syn_backlog=8192
EOF

sysctl -p
```

### BBR Congestion Control

Уже включен скриптом установки. Проверить:

```bash
sysctl net.ipv4.tcp_congestion_control
# Должно быть: bbr
```

## Безопасность

### Изменение портов панели

В `docker-compose.yml` измените:
```yaml
ports:
  - "8888:8888"  # Измените первое число
```

### Ограничение доступа к панели

```bash
# Разрешите доступ только с определенного IP
ufw allow from YOUR_IP to any port 8888
```

### Регулярные обновления

```bash
# Обновляйте систему еженедельно
apt update && apt upgrade -y
```

## Поддержка

Если возникли проблемы:

1. Проверьте логи
2. Убедитесь, что все порты открыты
3. Проверьте конфигурацию
4. Создайте issue на GitHub

## Полезные команды

```bash
# Перезапуск всех сервисов
docker-compose restart

# Перезапуск только backend
docker-compose restart backend

# Просмотр использования ресурсов
docker stats

# Очистка неиспользуемых образов
docker system prune -a

# Экспорт базы данных
docker exec vpn-shield-db pg_dump -U vpnshield vpnshield > backup.sql

# Импорт базы данных
docker exec -i vpn-shield-db psql -U vpnshield vpnshield < backup.sql
```
