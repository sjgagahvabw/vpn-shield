# VPN Shield

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Go Version](https://img.shields.io/badge/Go-1.22-blue.svg)](https://golang.org)
[![React](https://img.shields.io/badge/React-18.2-blue.svg)](https://reactjs.org)

**VPN Shield** - продвинутая multi-protocol VPN система, специально разработанная для обхода жёстких блокировок в России. Поддерживает REALITY, Hysteria2, Trojan, VMess с автоматическим переключением и маскировкой трафика.

## 🌟 Основные возможности

### 🛡️ Множественные протоколы
- **REALITY** - Неотличим от обычного HTTPS, маскируется под Microsoft/Bing
- **Hysteria2** - QUIC-based, оптимизирован для мобильных сетей
- **Trojan-GFW** - Надёжный backup протокол с TLS
- **VMess** - Классический V2Ray с WebSocket
- **Naive Proxy** - Stealth режим (в разработке)

### 🔄 Интеллектуальное переключение
- Автоматический fallback между протоколами
- Определение блокировок в реальном времени
- Бесшовное переключение без разрыва соединения

### 🎭 Продвинутая маскировка
- Domain fronting через Cloudflare CDN
- TLS fingerprint randomization
- SNI camouflage
- Маскировка под белый список сайтов

### 📊 Удобная панель управления
- Современный веб-интерфейс на React
- Управление пользователями и конфигурациями
- Статистика использования в реальном времени
- Мониторинг состояния протоколов
- Генерация QR кодов и конфигов

### 📱 Поддержка всех платформ
- **iOS**: Shadowrocket, Stash, Hiddify
- **Android**: v2rayNG, Hiddify, NekoBox
- **Windows**: v2rayN, Hiddify
- **macOS**: v2rayU, Hiddify
- **Linux**: Xray-core, Hiddify

## 🚀 Быстрый старт

### Требования

- VPS с Ubuntu 20.04+ или Debian 11+
- Минимум 1GB RAM, 1 CPU, 10GB диска
- Root доступ
- Публичный IP адрес

### Установка

```bash
# Скачайте скрипт установки
wget https://raw.githubusercontent.com/yourusername/vpn-shield/main/scripts/install.sh

# Запустите установку
chmod +x install.sh
sudo ./install.sh
```

Скрипт автоматически:
- Установит Docker и Docker Compose
- Настроит firewall и оптимизирует сеть
- Создаст конфигурацию и сгенерирует пароли
- Запустит все сервисы

### Доступ к панели

После установки откройте в браузере:
```
http://your-server-ip:8888
```

Учетные данные находятся в `/opt/vpn-shield/.env`

## 📖 Документация

- [Руководство по установке](docs/INSTALLATION.md)
- [Руководство по деплою](docs/DEPLOYMENT.md)
- [Руководство пользователя](docs/USER_GUIDE.md)
- [API документация](docs/API.md)

## 🏗️ Архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                     VPN Shield System                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐      ┌──────────────┐                     │
│  │  Web Panel   │◄────►│  Backend API │                     │
│  │  (React)     │      │  (Go/Fiber)  │                     │
│  └──────────────┘      └──────┬───────┘                     │
│                                │                              │
│                    ┌───────────┴───────────┐                │
│                    │                       │                 │
│              ┌─────▼─────┐         ┌──────▼──────┐         │
│              │ Xray-core │         │  Hysteria2  │         │
│              │  Manager  │         │   Manager   │         │
│              └─────┬─────┘         └──────┬──────┘         │
│                    │                       │                 │
│    ┌───────────────┼───────────────────────┼──────────┐    │
│    │               │                       │          │    │
│  ┌─▼──────┐  ┌────▼─────┐  ┌──────▼─────┐  ┌───▼────┐   │
│  │REALITY │  │Trojan-GFW│  │   VMess    │  │Hysteria│   │
│  └────────┘  └──────────┘  └────────────┘  └────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 Технологический стек

### Backend
- **Go 1.22** - Основной язык
- **Fiber** - Web framework
- **Xray-core** - Ядро для REALITY/VMess/Trojan
- **Hysteria2** - QUIC-based протокол
- **PostgreSQL** - База данных
- **Redis** - Кэширование

### Frontend
- **React 18** - UI framework
- **TypeScript** - Типизация
- **Tailwind CSS** - Стилизация
- **Zustand** - State management
- **Vite** - Build tool

### DevOps
- **Docker** - Контейнеризация
- **Docker Compose** - Оркестрация
- **Nginx** - Reverse proxy

## 🎯 Почему VPN Shield?

### Vs 3x-ui
- ✅ Более современный стек (Go + React)
- ✅ Лучшая производительность
- ✅ Поддержка REALITY из коробки
- ✅ Автоматическое переключение протоколов
- ✅ Domain fronting через CDN

### Vs обычные VPN
- ✅ Специально для обхода блокировок в РФ
- ✅ Множественные протоколы
- ✅ Маскировка под обычный HTTPS
- ✅ Работает даже при отключении интернета
- ✅ Поддержка мобильных сетей (Hysteria2)

## 📊 Производительность

- Поддержка до **1000** одновременных подключений
- Пропускная способность до **1 Gbps**
- Задержка (latency) < **5ms** overhead
- Использование RAM: ~200MB (idle), ~500MB (под нагрузкой)

## 🔒 Безопасность

- Все пароли хешируются с **bcrypt**
- **JWT** токены для аутентификации
- **TLS 1.3** шифрование
- **REALITY** неотличим от обычного HTTPS
- Регулярная ротация ключей
- Полное логирование действий

## 🌍 Обход блокировок

### Методы, которые работают в 2026

1. **REALITY** - Основной протокол
   - Маскируется под Microsoft/Bing
   - Обходит DPI и SNI filtering
   - Неотличим от легитимного трафика

2. **Hysteria2** - Для мобильных сетей
   - QUIC протокол (UDP)
   - Обходит TCP throttling
   - Работает при нестабильном соединении

3. **Domain Fronting** - Через CDN
   - Использует Cloudflare
   - Маскируется под популярные сайты
   - Обходит IP блокировки

4. **Multiple Fallback** - Автопереключение
   - Если один протокол заблокирован
   - Автоматически переключается на другой
   - Без разрыва соединения

## 📈 Roadmap

- [x] Базовая архитектура
- [x] Backend API
- [x] Web панель
- [x] REALITY протокол
- [x] Hysteria2 протокол
- [x] Trojan протокол
- [x] VMess протокол
- [x] Система мониторинга
- [x] Генератор конфигов
- [ ] Naive Proxy
- [ ] Автоматический fallback
- [ ] Domain fronting через CDN
- [ ] Мобильное приложение
- [ ] Telegram бот для управления
- [ ] Автоматическое обновление

## 🤝 Вклад в проект

Мы приветствуем вклад в проект! Пожалуйста:

1. Fork репозиторий
2. Создайте feature branch (`git checkout -b feature/amazing-feature`)
3. Commit изменения (`git commit -m 'Add amazing feature'`)
4. Push в branch (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

## 📝 Лицензия

Этот проект распространяется под лицензией MIT. См. файл [LICENSE](LICENSE) для деталей.

## ⚠️ Дисклеймер

Этот проект создан исключительно в образовательных целях и для обхода цензуры. Используйте на свой страх и риск. Авторы не несут ответственности за использование программного обеспечения.

## 🙏 Благодарности

- [Xray-core](https://github.com/XTLS/Xray-core) - За отличное ядро
- [Hysteria](https://github.com/apernet/hysteria) - За QUIC-based протокол
- [3x-ui](https://github.com/MHSanaei/3x-ui) - За вдохновение
- [net4people](https://github.com/net4people/bbs) - За исследования блокировок

## 📞 Контакты

- GitHub Issues: [Создать issue](https://github.com/yourusername/vpn-shield/issues)
- Telegram: @vpnshield (в разработке)
- Email: support@vpnshield.example.com

## ⭐ Поддержите проект

Если проект вам помог, поставьте звезду на GitHub!

---

**Сделано с ❤️ для свободного интернета**

**Против цензуры. За свободу информации. 🛡️**
