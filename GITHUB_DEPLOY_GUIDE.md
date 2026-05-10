# 🚀 Инструкция по загрузке на GitHub и установке на сервер

## Шаг 1: Загрузка на GitHub

### 1.1 Создайте репозиторий на GitHub

1. Перейдите на https://github.com/new
2. Заполните данные:
   - **Repository name:** `vpn-shield`
   - **Description:** `Multi-protocol VPN system for bypassing censorship in Russia`
   - **Visibility:** Public (или Private)
   - **НЕ добавляйте:** README, .gitignore, license (уже есть в проекте)
3. Нажмите **Create repository**

### 1.2 Загрузите код

```bash
cd /Users/artemmalov/vpn-shield

# Добавьте remote (замените YOUR_USERNAME на ваш GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/vpn-shield.git

# Загрузите код
git push -u origin main
```

**Пример для username "artemmalov":**
```bash
git remote add origin https://github.com/artemmalov/vpn-shield.git
git push -u origin main
```

### 1.3 Обновите quick-install.sh

После загрузки на GitHub, обновите URL в файле `quick-install.sh`:

```bash
# Отредактируйте строку 145 в quick-install.sh
nano quick-install.sh

# Найдите:
REPO_URL="https://github.com/YOUR_USERNAME/vpn-shield.git"

# Замените на:
REPO_URL="https://github.com/artemmalov/vpn-shield.git"

# Сохраните и закоммитьте
git add quick-install.sh
git commit -m "Update repository URL in quick-install.sh"
git push
```

---

## Шаг 2: Установка на сервер

### 2.1 Подготовка сервера

**Требования:**
- VPS с Ubuntu 20.04+ или Debian 11+
- Минимум 1GB RAM (рекомендуется 2GB)
- Root доступ
- Публичный IP адрес

**Рекомендуемые провайдеры:**
- **Vultr** - https://www.vultr.com (от $5/мес)
- **DigitalOcean** - https://www.digitalocean.com (от $6/мес)
- **Linode** - https://www.linode.com (от $5/мес)

### 2.2 Быстрая установка (одна команда!)

Подключитесь к серверу и выполните:

```bash
# Замените YOUR_USERNAME на ваш GitHub username
wget -O - https://raw.githubusercontent.com/YOUR_USERNAME/vpn-shield/main/quick-install.sh | sudo bash
```

**Пример для username "artemmalov":**
```bash
wget -O - https://raw.githubusercontent.com/artemmalov/vpn-shield/main/quick-install.sh | sudo bash
```

**Или скачайте и запустите:**
```bash
wget https://raw.githubusercontent.com/YOUR_USERNAME/vpn-shield/main/quick-install.sh
chmod +x quick-install.sh
sudo ./quick-install.sh
```

### 2.3 Что делает скрипт

Скрипт автоматически:
- ✅ Обновляет систему
- ✅ Устанавливает Docker и Docker Compose
- ✅ Настраивает firewall (UFW)
- ✅ Включает BBR для оптимизации сети
- ✅ Настраивает Fail2Ban
- ✅ Клонирует проект из GitHub
- ✅ Генерирует безопасные пароли
- ✅ Создаёт конфигурацию
- ✅ Запускает все сервисы

**Время установки:** ~5-10 минут

### 2.4 После установки

Скрипт покажет:
```
✅ Установка завершена!

Доступ к панели управления:
   http://YOUR_SERVER_IP:8888

Учетные данные администратора:
   Username: admin
   Password: XXXXXXXXXX

⚠️  ВАЖНО: Сохраните эти данные!
```

**Сохраните пароль администратора!** Он также находится в `/opt/vpn-shield/.env`

---

## Шаг 3: Первоначальная настройка

### 3.1 Войдите в панель управления

1. Откройте в браузере: `http://YOUR_SERVER_IP:8888`
2. Войдите с учетными данными из вывода скрипта
3. Вы увидите Dashboard с статистикой

### 3.2 Создайте первого пользователя

1. Перейдите в раздел **"Пользователи"**
2. Нажмите **"Добавить пользователя"**
3. Заполните:
   - Username: `user1`
   - Email: `user1@example.com`
   - Password: `SecurePassword123`
   - Включите все протоколы (REALITY, Hysteria2, Trojan, VMess)
4. Нажмите **"Создать"**

### 3.3 Получите конфигурацию

1. Перейдите в раздел **"Конфигурации"**
2. Выберите пользователя `user1`
3. Выберите протокол:
   - **REALITY** - для WiFi (максимальная скрытность)
   - **Hysteria2** - для мобильных сетей (4G/5G)
4. Скопируйте ссылку или отсканируйте QR код

---

## Шаг 4: Настройка клиентов

### Android (v2rayNG)

1. Установите **v2rayNG** из Google Play
2. Нажмите **+** → **"Импорт из буфера обмена"**
3. Вставьте скопированную ссылку
4. Нажмите на конфигурацию для подключения
5. Разрешите создание VPN соединения

### iOS (Shadowrocket)

1. Купите **Shadowrocket** в App Store ($2.99)
2. Откройте приложение
3. Нажмите **+** → **"Добавить из буфера"**
4. Вставьте ссылку
5. Нажмите на конфигурацию для подключения

### Windows (v2rayN)

1. Скачайте **v2rayN** с GitHub: https://github.com/2dust/v2rayN/releases
2. Распакуйте и запустите `v2rayN.exe`
3. **Сервер** → **Импорт из буфера обмена**
4. Вставьте ссылку
5. Нажмите Enter для подключения

### macOS (v2rayU)

1. Скачайте **v2rayU** с GitHub
2. Установите приложение
3. Импортируйте конфигурацию
4. Подключитесь

### Linux (Xray-core)

```bash
# Установите Xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# Скопируйте конфигурацию в /usr/local/etc/xray/config.json

# Запустите
systemctl start xray
systemctl enable xray
```

---

## Шаг 5: Настройка домена (опционально, но рекомендуется)

### 5.1 Зарегистрируйте домен

Купите домен на:
- **Namecheap** - https://www.namecheap.com
- **Cloudflare Registrar** - https://www.cloudflare.com
- **Porkbun** - https://porkbun.com

### 5.2 Настройте DNS

В панели управления доменом создайте A записи:

```
A    @         YOUR_SERVER_IP
A    panel     YOUR_SERVER_IP
```

Проверьте:
```bash
dig your-domain.com
dig panel.your-domain.com
```

### 5.3 Получите SSL сертификат

На сервере выполните:

```bash
# Установите certbot
apt install certbot -y

# Остановите временно сервисы
cd /opt/vpn-shield
docker-compose down

# Получите сертификат
certbot certonly --standalone \
  -d your-domain.com \
  -d panel.your-domain.com \
  --agree-tos \
  --email your-email@example.com

# Обновите .env
nano /opt/vpn-shield/.env
# Измените:
# DOMAIN=your-domain.com
# PANEL_DOMAIN=panel.your-domain.com

# Запустите снова
docker-compose up -d
```

Теперь панель доступна по адресу: `https://panel.your-domain.com`

---

## Шаг 6: Настройка Cloudflare (опционально)

### Для Domain Fronting и дополнительной защиты

1. **Добавьте домен в Cloudflare:**
   - Зарегистрируйтесь на cloudflare.com
   - Добавьте ваш домен
   - Измените nameservers у регистратора

2. **Настройте DNS:**
   ```
   A    @         YOUR_SERVER_IP    Proxied (🟠)
   A    panel     YOUR_SERVER_IP    DNS only (⚪)
   ```

3. **Настройте SSL/TLS:**
   - SSL/TLS → Overview → **Full (strict)**
   - Edge Certificates → Always Use HTTPS: **On**

4. **Получите API токен:**
   - My Profile → API Tokens → Create Token
   - Edit zone DNS → Use template
   - Сохраните токен

5. **Добавьте в .env:**
   ```bash
   nano /opt/vpn-shield/.env
   
   CLOUDFLARE_API_TOKEN=your_token_here
   CLOUDFLARE_ZONE_ID=your_zone_id
   
   # Перезапустите
   cd /opt/vpn-shield
   docker-compose restart
   ```

---

## Полезные команды

### Управление сервисами

```bash
# Перейти в директорию
cd /opt/vpn-shield

# Статус сервисов
docker-compose ps

# Логи (все сервисы)
docker-compose logs -f

# Логи (только backend)
docker-compose logs -f backend

# Перезапуск
docker-compose restart

# Остановка
docker-compose down

# Запуск
docker-compose up -d

# Обновление
./scripts/update.sh
```

### Просмотр конфигурации

```bash
# Просмотр .env
cat /opt/vpn-shield/.env

# Просмотр паролей
grep PASSWORD /opt/vpn-shield/.env
```

### Резервное копирование

```bash
# Создать backup
cd /opt/vpn-shield
./scripts/backup.sh

# Backup будет в /backup/vpn-shield/
```

---

## Решение проблем

### Не подключается к панели

```bash
# Проверьте статус
docker-compose ps

# Проверьте логи
docker-compose logs backend

# Проверьте firewall
ufw status

# Откройте порт 8888
ufw allow 8888/tcp
```

### Не работает VPN

1. **Проверьте протоколы:**
   ```bash
   docker-compose logs backend | grep -i error
   ```

2. **Попробуйте другой протокол:**
   - WiFi → REALITY
   - Мобильный → Hysteria2

3. **Проверьте порты:**
   ```bash
   netstat -tulpn | grep -E '443|8443|8444|36712'
   ```

### Забыли пароль администратора

```bash
# Посмотрите в .env
cat /opt/vpn-shield/.env | grep ADMIN_PASSWORD
```

---

## Безопасность

### Рекомендации

1. **Измените пароль администратора** после первого входа
2. **Ограничьте доступ к панели:**
   ```bash
   ufw delete allow 8888/tcp
   ufw allow from YOUR_HOME_IP to any port 8888
   ```
3. **Настройте автоматические обновления:**
   ```bash
   crontab -e
   # Добавьте:
   0 3 * * 0 /opt/vpn-shield/scripts/update.sh
   ```
4. **Регулярно делайте backup:**
   ```bash
   crontab -e
   # Добавьте:
   0 3 * * * /opt/vpn-shield/scripts/backup.sh
   ```

---

## Поддержка

- **Документация:** `/opt/vpn-shield/docs/`
- **GitHub Issues:** https://github.com/YOUR_USERNAME/vpn-shield/issues
- **Быстрый старт:** `/opt/vpn-shield/QUICKSTART.md`

---

## Готово! 🎉

Теперь у вас есть собственный VPN сервер, который:

✅ Работает даже при жестких блокировках  
✅ Поддерживает 4 протокола  
✅ Имеет удобную веб-панель  
✅ Защищает вашу приватность  
✅ Обходит цензуру  

**Против цензуры. За свободу информации. 🛡️**
