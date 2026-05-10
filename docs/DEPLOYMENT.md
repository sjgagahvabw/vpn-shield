# VPN Shield - Deployment Guide

## Подготовка к деплою

### 1. Выбор VPS провайдера

Рекомендуемые провайдеры для США:
- **Vultr** - от $5/месяц, хорошая скорость в РФ
- **DigitalOcean** - от $6/месяц, стабильный
- **Linode** - от $5/месяц, отличная производительность
- **Hetzner** - от €4/месяц, но может быть заблокирован

**Минимальные требования:**
- 1 vCPU
- 1GB RAM
- 25GB SSD
- 1TB трафик

**Рекомендуемые:**
- 2 vCPU
- 2GB RAM
- 50GB SSD
- Unlimited трафик

### 2. Выбор локации

**Лучшие локации для России:**
1. **США (Нью-Йорк, Чикаго)** - 150-200ms пинг
2. **Германия (Франкфурт)** - 80-120ms пинг (может быть заблокирована)
3. **Нидерланды (Амстердам)** - 100-150ms пинг
4. **Великобритания (Лондон)** - 120-180ms пинг

### 3. Регистрация домена

**Рекомендуемые регистраторы:**
- Namecheap
- Cloudflare Registrar
- Porkbun

**Советы:**
- Используйте .com, .net, .org домены
- Включите WHOIS Privacy
- Не используйте личные данные

## Пошаговый деплой

### Шаг 1: Создание VPS

```bash
# Пример для Vultr через CLI
vultr-cli instance create \
  --region ewr \
  --plan vc2-1c-1gb \
  --os 387 \
  --label vpn-shield

# Сохраните IP адрес и root пароль
```

### Шаг 2: Первоначальная настройка сервера

```bash
# Подключитесь к серверу
ssh root@YOUR_SERVER_IP

# Обновите систему
apt update && apt upgrade -y

# Создайте нового пользователя (опционально)
adduser vpnadmin
usermod -aG sudo vpnadmin

# Настройте SSH ключи (рекомендуется)
mkdir -p ~/.ssh
nano ~/.ssh/authorized_keys
# Вставьте ваш публичный ключ

# Отключите вход по паролю (опционально)
nano /etc/ssh/sshd_config
# Установите: PasswordAuthentication no
systemctl restart sshd
```

### Шаг 3: Настройка DNS

В панели управления доменом создайте A записи:

```
A    @                  YOUR_SERVER_IP
A    panel              YOUR_SERVER_IP
A    *                  YOUR_SERVER_IP  (wildcard, опционально)
```

Проверьте DNS:
```bash
dig your-domain.com
dig panel.your-domain.com
```

### Шаг 4: Установка VPN Shield

```bash
# Скачайте и запустите скрипт установки
wget https://raw.githubusercontent.com/yourusername/vpn-shield/main/scripts/install.sh
chmod +x install.sh
sudo ./install.sh

# Скрипт автоматически:
# - Установит Docker и Docker Compose
# - Настроит firewall
# - Оптимизирует сеть (BBR)
# - Создаст конфигурацию
# - Сгенерирует пароли
```

### Шаг 5: Получение SSL сертификатов

```bash
# Остановите временно nginx если запущен
systemctl stop nginx

# Установите certbot
apt install certbot -y

# Получите сертификаты
certbot certonly --standalone \
  -d your-domain.com \
  -d panel.your-domain.com \
  --agree-tos \
  --email your-email@example.com

# Сертификаты будут в:
# /etc/letsencrypt/live/your-domain.com/fullchain.pem
# /etc/letsencrypt/live/your-domain.com/privkey.pem

# Настройте автообновление
certbot renew --dry-run
```

### Шаг 6: Конфигурация VPN Shield

```bash
cd /opt/vpn-shield

# Отредактируйте .env
nano .env
```

Обязательно измените:
```env
# Ваш домен
DOMAIN=your-domain.com
PANEL_DOMAIN=panel.your-domain.com

# Для REALITY - выберите популярный сайт для маскировки
REALITY_DEST=www.microsoft.com:443
REALITY_SERVER_NAMES=www.microsoft.com,www.bing.com

# Для Cloudflare (если используете)
CLOUDFLARE_API_TOKEN=your_token
CLOUDFLARE_ZONE_ID=your_zone_id
```

### Шаг 7: Генерация ключей REALITY

```bash
# Сгенерируйте X25519 ключи
docker run --rm ghcr.io/xtls/xray-core:latest xray x25519

# Вывод будет примерно таким:
# Private key: SLw...
# Public key: 8Qv...

# Сохраните приватный ключ в конфигурацию Xray
nano /opt/vpn-shield/xray-configs/config.json

# Найдите "privateKey" и замените на сгенерированный
```

### Шаг 8: Запуск системы

```bash
cd /opt/vpn-shield

# Запустите все сервисы
docker-compose up -d

# Проверьте статус
docker-compose ps

# Все сервисы должны быть "Up"
```

### Шаг 9: Проверка работы

```bash
# Проверьте логи
docker-compose logs -f

# Проверьте порты
netstat -tulpn | grep -E '443|8443|8444|36712|8888'

# Проверьте доступность панели
curl http://localhost:8888

# Проверьте REALITY
curl -I https://your-domain.com
```

### Шаг 10: Создание первого пользователя

```bash
# Через API
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "SecurePassword123!"
  }'

# Или войдите в панель управления:
# http://YOUR_SERVER_IP:8888
# Используйте admin credentials из .env файла
```

## Настройка Cloudflare (опционально)

### 1. Добавление домена в Cloudflare

1. Зарегистрируйтесь на cloudflare.com
2. Добавьте ваш домен
3. Измените nameservers у регистратора на Cloudflare NS
4. Дождитесь активации (до 24 часов)

### 2. Настройка DNS в Cloudflare

```
A    @         YOUR_SERVER_IP    Proxied (оранжевое облако)
A    panel     YOUR_SERVER_IP    DNS only (серое облако)
```

### 3. Настройка SSL/TLS

1. SSL/TLS → Overview → Full (strict)
2. SSL/TLS → Edge Certificates → Always Use HTTPS: On
3. SSL/TLS → Edge Certificates → Minimum TLS Version: 1.2

### 4. Получение API токена

1. My Profile → API Tokens → Create Token
2. Edit zone DNS → Use template
3. Zone Resources → Include → Specific zone → your-domain.com
4. Continue to summary → Create Token
5. Сохраните токен в .env файл

### 5. Настройка для VMess через CDN

В конфигурации VMess используйте:
```json
{
  "address": "your-domain.com",
  "port": 443,
  "host": "your-domain.com",
  "path": "/vmess"
}
```

## Оптимизация производительности

### 1. Настройка BBR (уже сделано скриптом)

Проверка:
```bash
sysctl net.ipv4.tcp_congestion_control
# Должно быть: bbr
```

### 2. Увеличение лимитов

```bash
# Добавьте в /etc/security/limits.conf
* soft nofile 51200
* hard nofile 51200

# Перезагрузите
reboot
```

### 3. Оптимизация Docker

```bash
# Создайте /etc/docker/daemon.json
cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

systemctl restart docker
```

## Мониторинг

### 1. Установка мониторинга (опционально)

```bash
# Установите Netdata для мониторинга
bash <(curl -Ss https://my-netdata.io/kickstart.sh)

# Доступ: http://YOUR_SERVER_IP:19999
```

### 2. Настройка алертов

```bash
# Создайте скрипт проверки
cat > /opt/vpn-shield/healthcheck.sh <<'EOF'
#!/bin/bash

# Проверка сервисов
if ! docker-compose ps | grep -q "Up"; then
    echo "VPN Shield services are down!" | mail -s "VPN Shield Alert" your-email@example.com
    docker-compose restart
fi
EOF

chmod +x /opt/vpn-shield/healthcheck.sh

# Добавьте в cron (каждые 5 минут)
echo "*/5 * * * * /opt/vpn-shield/healthcheck.sh" | crontab -
```

## Безопасность

### 1. Настройка Fail2Ban

```bash
# Установите Fail2Ban
apt install fail2ban -y

# Создайте конфигурацию для SSH
cat > /etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF

systemctl restart fail2ban
```

### 2. Ограничение доступа к панели

```bash
# Разрешите доступ к панели только с вашего IP
ufw allow from YOUR_HOME_IP to any port 8888

# Или используйте VPN для доступа к панели
```

### 3. Регулярные обновления

```bash
# Создайте скрипт обновления
cat > /opt/vpn-shield/update.sh <<'EOF'
#!/bin/bash
cd /opt/vpn-shield
docker-compose pull
docker-compose up -d
docker system prune -f
EOF

chmod +x /opt/vpn-shield/update.sh

# Запускайте еженедельно
echo "0 3 * * 0 /opt/vpn-shield/update.sh" | crontab -
```

## Резервное копирование

### Автоматическое резервное копирование

```bash
# Создайте скрипт backup
cat > /opt/vpn-shield/backup.sh <<'EOF'
#!/bin/bash
BACKUP_DIR="/backup/vpn-shield"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup database
docker exec vpn-shield-db pg_dump -U vpnshield vpnshield | gzip > $BACKUP_DIR/db_$DATE.sql.gz

# Backup configs
tar -czf $BACKUP_DIR/configs_$DATE.tar.gz \
  /opt/vpn-shield/.env \
  /opt/vpn-shield/xray-configs \
  /opt/vpn-shield/hysteria-configs

# Backup SSL certificates
tar -czf $BACKUP_DIR/ssl_$DATE.tar.gz /etc/letsencrypt

# Keep only last 7 backups
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete

# Upload to remote storage (опционально)
# rclone copy $BACKUP_DIR remote:vpn-shield-backups
EOF

chmod +x /opt/vpn-shield/backup.sh

# Запускайте ежедневно в 3:00
echo "0 3 * * * /opt/vpn-shield/backup.sh" | crontab -
```

## Масштабирование

### Добавление второго сервера

1. Повторите установку на новом сервере
2. Используйте ту же базу данных (настройте репликацию)
3. Настройте балансировку через Cloudflare Load Balancer

### Использование нескольких доменов

```bash
# Получите сертификаты для нового домена
certbot certonly --standalone -d new-domain.com

# Добавьте в конфигурацию Xray
# Используйте разные SNI для разных доменов
```

## Troubleshooting

### Проблема: Порты заняты

```bash
# Найдите процесс
netstat -tulpn | grep :443

# Остановите конфликтующий сервис
systemctl stop nginx
```

### Проблема: Docker не запускается

```bash
# Проверьте логи
journalctl -u docker

# Переустановите Docker
apt remove docker docker-engine docker.io containerd runc
curl -fsSL https://get.docker.com | sh
```

### Проблема: Не работает REALITY

```bash
# Проверьте ключи
docker exec vpn-shield-backend cat /app/xray-configs/config.json | grep privateKey

# Проверьте dest домен
curl -I https://www.microsoft.com

# Проверьте логи Xray
docker exec vpn-shield-backend tail -f /var/log/vpn-shield/xray.log
```

## Чеклист после установки

- [ ] Сервер обновлен
- [ ] Docker установлен и работает
- [ ] Firewall настроен
- [ ] DNS записи созданы
- [ ] SSL сертификаты получены
- [ ] VPN Shield запущен
- [ ] Все порты открыты
- [ ] REALITY ключи сгенерированы
- [ ] Тестовый пользователь создан
- [ ] Подключение работает
- [ ] Резервное копирование настроено
- [ ] Мониторинг настроен
- [ ] Fail2Ban установлен
- [ ] Документация сохранена

## Полезные команды

```bash
# Статус всех сервисов
docker-compose ps

# Логи в реальном времени
docker-compose logs -f

# Перезапуск сервиса
docker-compose restart backend

# Обновление
docker-compose pull && docker-compose up -d

# Очистка
docker system prune -a

# Проверка использования ресурсов
docker stats

# Backup базы данных
docker exec vpn-shield-db pg_dump -U vpnshield vpnshield > backup.sql

# Restore базы данных
docker exec -i vpn-shield-db psql -U vpnshield vpnshield < backup.sql
```
