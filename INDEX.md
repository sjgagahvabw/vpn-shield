# 📑 VPN Shield - Навигация по проекту

## 🎯 Быстрый доступ

### Для начала работы
- **[QUICKSTART.md](QUICKSTART.md)** - Запуск за 5 минут ⚡
- **[NEXT_STEPS.md](NEXT_STEPS.md)** - Что делать дальше 🚀
- **[README.md](README.md)** - Обзор проекта 📖

### Документация
- **[docs/INSTALLATION.md](docs/INSTALLATION.md)** - Детальная установка 🔧
- **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Production деплой 🌐
- **[docs/USER_GUIDE.md](docs/USER_GUIDE.md)** - Руководство пользователя 👥

### Информация о проекте
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - Полная сводка 📊
- **[CHANGELOG.md](CHANGELOG.md)** - История изменений 📝
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Как внести вклад 🤝
- **[LICENSE](LICENSE)** - MIT License 📜

## 📂 Структура проекта

```
vpn-shield/
├── 📱 frontend/          React + TypeScript веб-панель
├── 🔧 backend/           Go backend API
├── 🐳 docker/            Docker конфигурации
├── 📜 scripts/           Скрипты установки и управления
├── 📚 docs/              Полная документация
├── ⚙️ xray-configs/      Шаблоны Xray
└── ⚙️ hysteria-configs/  Шаблоны Hysteria2
```

## 🎓 Сценарии использования

### Я хочу быстро запустить VPN
→ Читайте **[QUICKSTART.md](QUICKSTART.md)**

### Я хочу установить на production сервер
→ Читайте **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)**

### Я хочу настроить для пользователей
→ Читайте **[docs/USER_GUIDE.md](docs/USER_GUIDE.md)**

### Я хочу понять архитектуру
→ Читайте **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)**

### Я хочу внести изменения в код
→ Читайте **[CONTRIBUTING.md](CONTRIBUTING.md)**

## 🔑 Ключевые файлы

### Конфигурация
- `.env.example` - Шаблон переменных окружения
- `docker-compose.yml` - Docker оркестрация
- `xray-configs/template.json` - Шаблон Xray
- `hysteria-configs/template.yaml` - Шаблон Hysteria2

### Скрипты
- `scripts/install.sh` - Автоматическая установка
- `scripts/start.sh` - Быстрый старт
- `scripts/stop.sh` - Остановка сервисов
- `scripts/update.sh` - Обновление системы

### Backend (Go)
- `backend/cmd/server/main.go` - Entry point
- `backend/internal/api/` - HTTP handlers
- `backend/internal/xray/` - Xray manager
- `backend/internal/hysteria/` - Hysteria2 manager

### Frontend (React)
- `frontend/src/App.tsx` - Главный компонент
- `frontend/src/pages/` - Страницы
- `frontend/src/components/` - Компоненты
- `frontend/src/store/` - State management

## 📞 Поддержка

- 🐛 **Баги:** [GitHub Issues](https://github.com/yourusername/vpn-shield/issues)
- 💬 **Вопросы:** Читайте документацию в `docs/`
- 🤝 **Вклад:** См. [CONTRIBUTING.md](CONTRIBUTING.md)

## ⭐ Полезные ссылки

- [Xray-core](https://github.com/XTLS/Xray-core) - Ядро протоколов
- [Hysteria](https://github.com/apernet/hysteria) - QUIC протокол
- [net4people](https://github.com/net4people/bbs) - Исследования блокировок
- [Hiddify](https://hiddify.com) - Универсальный клиент

---

**Против цензуры. За свободу информации. 🛡️**
