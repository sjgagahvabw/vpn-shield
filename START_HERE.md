# 🚀 START HERE - Начните отсюда!

**VPN Shield v1.0.0** - Готов к использованию!

---

## ⚡ Быстрый старт (3 шага)

### 1️⃣ Загрузите на GitHub (2 минуты)

```bash
# Создайте репозиторий: https://github.com/new
# Название: vpn-shield

# Загрузите код (замените YOUR_USERNAME на ваш GitHub username)
cd /Users/artemmalov/vpn-shield
git remote add origin https://github.com/YOUR_USERNAME/vpn-shield.git
git push -u origin main
```

### 2️⃣ Обновите URL в скрипте (1 минута)

```bash
# Отредактируйте quick-install.sh
nano quick-install.sh

# Найдите строку 145 и замените YOUR_USERNAME:
# REPO_URL="https://github.com/YOUR_USERNAME/vpn-shield.git"

# Сохраните и закоммитьте
git add quick-install.sh
git commit -m "Update repository URL"
git push
```

### 3️⃣ Установите на сервер (5-10 минут)

```bash
# На вашем VPS сервере выполните:
wget -O - https://raw.githubusercontent.com/YOUR_USERNAME/vpn-shield/main/quick-install.sh | sudo bash
```

**Готово!** Панель доступна по адресу: `http://YOUR_SERVER_IP:8888`

---

## 📚 Документация

| Файл | Описание |
|------|----------|
| **GITHUB_DEPLOY_GUIDE.md** | 📖 Полная инструкция по деплою |
| **QUICKSTART.md** | ⚡ Быстрый старт за 5 минут |
| **COMPLETE.md** | ✅ Итоговая сводка проекта |
| **docs/USER_GUIDE.md** | 👥 Руководство пользователя |

---

## 🎯 Что получится

После установки на сервер:

✅ **Веб-панель:** http://SERVER_IP:8888  
✅ **4 протокола:** REALITY, Hysteria2, Trojan, VMess  
✅ **Автоматическая настройка:** Firewall, BBR, Fail2Ban  
✅ **Готовые конфигурации:** Для всех клиентов  
✅ **Время установки:** 5-10 минут  

---

## 💡 Пример для username "artemmalov"

```bash
# 1. Загрузка на GitHub
git remote add origin https://github.com/artemmalov/vpn-shield.git
git push -u origin main

# 2. Установка на сервер
wget -O - https://raw.githubusercontent.com/artemmalov/vpn-shield/main/quick-install.sh | sudo bash
```

---

## 📱 Клиенты

- **iOS:** Shadowrocket ($2.99), Hiddify (бесплатно)
- **Android:** v2rayNG, Hiddify, NekoBox (все бесплатно)
- **Windows:** v2rayN, Hiddify (бесплатно)
- **macOS:** v2rayU, Hiddify (бесплатно)
- **Linux:** Xray-core, Hiddify (бесплатно)

---

## 🔧 Полезные команды

```bash
# На сервере
cd /opt/vpn-shield

# Статус
docker-compose ps

# Логи
docker-compose logs -f

# Перезапуск
docker-compose restart

# Пароль админа
cat .env | grep ADMIN_PASSWORD
```

---

## 🆘 Проблемы?

1. Читайте **GITHUB_DEPLOY_GUIDE.md**
2. Проверьте логи: `docker-compose logs`
3. Убедитесь, что порты открыты: `ufw status`

---

## 🎉 Готово!

**Против цензуры. За свободу информации. 🛡️**

