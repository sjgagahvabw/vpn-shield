# 🚀 Инструкция по установке VPN Shield

**Репозиторий:** https://github.com/sjgagahvabw/vpn-shield  
**Версия:** 1.0.0  
**Дата:** 10 мая 2026

---

## ✅ Код уже загружен на GitHub!

Проект полностью готов к установке на сервер.

---

## 📋 Шаг 1: Подготовка VPS сервера

### Выбор провайдера

Рекомендуемые VPS провайдеры:

| Провайдер | Цена | Ссылка |
|-----------|------|--------|
| **Vultr** | от $5/мес | https://www.vultr.com |
| **DigitalOcean** | от $6/мес | https://www.digitalocean.com |
| **Linode** | от $5/мес | https://www.linode.com |

### Минимальные требования:
- **OS:** Ubuntu 20.04+ или Debian 11+
- **RAM:** 1GB (рекомендуется 2GB)
- **CPU:** 1 core (рекомендуется 2 cores)
- **Диск:** 25GB SSD
- **Локация:** США (Нью-Йорк, Чикаго) или Европа

### Рекомендуемая конфигурация:
- **RAM:** 2GB
- **CPU:** 2 cores
- **Диск:** 50GB SSD
- **Трафик:** Unlimited

---

## 🚀 Шаг 2: Установка на сервер (ОДНА КОМАНДА!)

### Вариант 1: Быстрая установка (рекомендуется)

Подключитесь к серверу и выполните:

```bash
wget -O - https://raw.githubusercontent.com/sjgagahvabw/vpn-shield/main/quick-install.sh | sudo bash
```

### Вариант 2: Скачать и запустить

```bash
# Скачайте скрипт
wget https://raw.githubusercontent.com/sjgagahvabw/vpn-shield/main/quick-install.sh

# Сделайте исполняемым
chmod +x quick-install.sh

# Запустите
sudo ./quick-install.sh
```

### Что делает скрипт:

1. ✅ Обновляет систему
2. ✅ Устанавливает Docker и Docker Compose
3. ✅ Настраивает firewall (UFW)
   - Открывает порты: 22, 80, 443, 8443, 8444, 8888, 36712
4. ✅ Включает BBR для оптимизации сети
5. ✅ Настраивает Fail2Ban для защиты SSH
6. ✅ Клонирует проект из GitHub
7. ✅ Генерирует безопасные пароли
8. ✅ Создаёт конфигурацию (.env)
9. ✅ Запускает все сервисы (PostgreSQL, Redis, Backend, Frontend)

**Время установки:** 5-10 минут

---

## 🎯 Шаг 3: Первый вход в панель

### После завершения установки:

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

### Откройте панель:

1. В браузере перейдите: `http://YOUR_SERVER_IP:8888`
2. Войдите с учетными данными из вывода скрипта
3. Вы увидите Dashboard с статистикой

**⚠️ ВАЖНО:** Сохраните пароль администратора! Он также находится в `/opt/vpn-shield/.env`

---

## 👥 Шаг 4: Создание пользователей

### Через веб-панель (рекомендуется):

1. Войдите в панель управления
2. Перейдите в раздел **"Пользователи"**
3. Нажмите **"Добавить пользователя"**
4. Заполните данные:
   - **Username:** `user1`
   - **Email:** `user1@example.com`
   - **Password:** `SecurePassword123`
   - **Протоколы:** Включите все (REALITY, Hysteria2, Trojan, VMess)
5. Нажмите **"Создать"**

### Через API:

```bash
# На сервере выполните:
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "user1",
    "email": "user1@example.com",
    "password": "SecurePassword123"
  }'
```

---

## 📱 Шаг 5: Получение конфигураций

### В веб-панели:

1. Перейдите в раздел **"Конфигурации"**
2. Выберите пользователя `user1`
3. Выберите протокол:
   - **REALITY** - для WiFi (максимальная скрытность)
   - **Hysteria2** - для мобильных сетей (4G/5G)
   - **Trojan** - резервный вариант
   - **VMess** - классический V2Ray
4. Скопируйте ссылку или отсканируйте QR код

---

## 📲 Шаг 6: Настройка клиентов

### Android (v2rayNG) - БЕСПЛАТНО

1. Установите **v2rayNG** из Google Play
2. Откройте приложение
3. Нажмите **+** в правом верхнем углу
4. Выберите **"Импорт из буфера обмена"**
5. Вставьте скопированную ссылку
6. Нажмите на конфигурацию для подключения
7. Разрешите создание VPN соединения

**Скачать:** https://play.google.com/store/apps/details?id=com.v2ray.ang

### iOS (Shadowrocket) - $2.99

1. Купите **Shadowrocket** в App Store
2. Откройте приложение
3. Нажмите **+** в правом верхнем углу
4. Выберите **"Добавить из буфера"**
5. Вставьте ссылку
6. Нажмите на конфигурацию для подключения

**Альтернатива (бесплатно):** Hiddify через TestFlight

### Windows (v2rayN) - БЕСПЛАТНО

1. Скачайте **v2rayN** с GitHub:
   - https://github.com/2dust/v2rayN/releases
   - Скачайте `v2rayN-windows-64.zip`
2. Распакуйте архив
3. Запустите `v2rayN.exe`
4. **Сервер** → **Импорт из буфера обмена**
5. Вставьте ссылку
6. Нажмите **Enter** для подключения

### macOS (v2rayU) - БЕСПЛАТНО

1. Скачайте **v2rayU** с GitHub:
   - https://github.com/yanue/V2rayU/releases
2. Установите приложение
3. Импортируйте конфигурацию из буфера обмена
4. Подключитесь

### Linux (Xray-core) - БЕСПЛАТНО

```bash
# Установите Xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# Скопируйте конфигурацию в /usr/local/etc/xray/config.json

# Запустите
systemctl start xray
systemctl enable xray
```

### Универсальный клиент (Hiddify) - БЕСПЛАТНО

**Рекомендуется для всех платформ!**

- **Android:** https://play.google.com/store/apps/details?id=ang.hiddify.com
- **iOS:** https://apps.apple.com/app/hiddify/id6596777532
- **Windows/macOS/Linux:** https://hiddify.com/download

**Преимущества Hiddify:**
- Поддержка всех протоколов
- Автоматическое переключение между протоколами
- Простой интерфейс
- Бесплатный

---

## 🔧 Полезные команды на сервере

### Управление сервисами:

```bash
# Перейти в директорию
cd /opt/vpn-shield

# Статус всех сервисов
docker-compose ps

# Логи (все сервисы)
docker-compose logs -f

# Логи (только backend)
docker-compose logs -f backend

# Перезапуск всех сервисов
docker-compose restart

# Перезапуск только backend
docker-compose restart backend

# Остановка
docker-compose down

# Запуск
docker-compose up -d
```

### Просмотр конфигурации:

```bash
# Просмотр .env файла
cat /opt/vpn-shield/.env

# Пароль администратора
cat /opt/vpn-shield/.env | grep ADMIN_PASSWORD

# Все пароли
grep PASSWORD /opt/vpn-shield/.env
```

### Создание пользователя через API:

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "user2",
    "email": "user2@example.com",
    "password": "AnotherSecurePass123"
  }'
```

---

## 🌐 Настройка домена (опционально, но рекомендуется)

### Шаг 1: Зарегистрируйте домен

Купите домен на:
- **Namecheap** - https://www.namecheap.com
- **Cloudflare Registrar** - https://www.cloudflare.com
- **Porkbun** - https://porkbun.com

### Шаг 2: Настройте DNS

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

### Шаг 3: Получите SSL сертификат

На сервере выполните:

```bash
# Остановите сервисы
cd /opt/vpn-shield
docker-compose down

# Установите certbot
apt install certbot -y

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

Теперь панель доступна: `https://panel.your-domain.com`

---

## 🛡️ Рекомендации по использованию

### Выбор протокола:

| Сценарий | Протокол | Почему |
|----------|----------|--------|
| **WiFi дома/работа** | REALITY | Максимальная скрытность, обходит DPI |
| **Мобильный интернет** | Hysteria2 | Оптимизирован для 4G/5G, QUIC протокол |
| **Резервный вариант** | Trojan | Надёжный и простой |
| **Через CDN** | VMess | Работает через Cloudflare |

### Для максимальной надёжности:

1. **Создайте конфигурации для всех протоколов**
2. **Используйте Hiddify** с автопереключением
3. **Настройте домен и SSL** для дополнительной защиты
4. **Регулярно обновляйте систему**

---

## 🔒 Безопасность

### Рекомендации:

1. **Измените пароль администратора** после первого входа
2. **Ограничьте доступ к панели:**
   ```bash
   # Разрешите доступ только с вашего IP
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

## 🆘 Решение проблем

### Не подключается к панели

```bash
# Проверьте статус
cd /opt/vpn-shield
docker-compose ps

# Проверьте логи
docker-compose logs backend

# Проверьте firewall
ufw status

# Откройте порт 8888
ufw allow 8888/tcp
```

### Не работает VPN

1. **Проверьте логи:**
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
cat /opt/vpn-shield/.env | grep ADMIN_PASSWORD
```

### Медленная скорость

1. Используйте **Hysteria2** для мобильных сетей
2. Проверьте загрузку сервера в панели
3. Попробуйте другую локацию сервера

---

## 📊 Мониторинг

### Просмотр статистики:

В веб-панели:
- **Dashboard** - общая статистика
- **Пользователи** - статистика по пользователям
- **Подключения** - активные подключения

### Через командную строку:

```bash
# Использование ресурсов
docker stats

# Статус сервисов
docker-compose ps

# Логи в реальном времени
docker-compose logs -f
```

---

## 💰 Стоимость

### Минимальная конфигурация:
- **VPS:** $5-6/месяц
- **Домен:** $10-15/год (опционально)
- **Итого:** ~$5-6/месяц

### Для семьи (5-10 человек):
- **VPS:** $20-24/месяц (4GB RAM, 2 CPU)
- **Домен:** $10-15/год
- **Итого:** ~$2-4/месяц на человека

---

## 📚 Дополнительная документация

### В репозитории:

- **README.md** - Обзор проекта
- **START_HERE.md** - Быстрый старт
- **QUICKSTART.md** - За 5 минут
- **docs/INSTALLATION.md** - Детальная установка
- **docs/DEPLOYMENT.md** - Production деплой
- **docs/USER_GUIDE.md** - Руководство пользователя

### Ссылки:

- **GitHub:** https://github.com/sjgagahvabw/vpn-shield
- **Issues:** https://github.com/sjgagahvabw/vpn-shield/issues

---

## 🎉 Готово!

Теперь у вас есть собственный VPN сервер, который:

✅ Работает даже при жёстких блокировках  
✅ Поддерживает 4 протокола  
✅ Имеет удобную веб-панель  
✅ Защищает вашу приватность  
✅ Обходит цензуру  

---

## 🚀 Команда для установки:

```bash
wget -O - https://raw.githubusercontent.com/sjgagahvabw/vpn-shield/main/quick-install.sh | sudo bash
```

---

**Против цензуры. За свободу информации. 🛡️**

**Сделано с ❤️ для свободного интернета**
