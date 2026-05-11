# VPN Shield - Быстрое исправление

## Что исправлено:

1. ✅ Убран WireGuard (не нужен)
2. ✅ Оставлены: VLESS/REALITY, Hysteria2, Shadowsocks, Trojan, VMess
3. ✅ Единая подписка с одним ключом для всех протоколов
4. ✅ QR коды для всех протоколов
5. ✅ Исправлены все ошибки конфигурации

## Команды для установки:

### 1. Очистка сервера:
```bash
wget https://raw.githubusercontent.com/sjgagahvabw/vpn-shield/main/full-clean.sh
bash full-clean.sh
```

### 2. Установка (выберите один вариант):

**Вариант A - Автоматическая установка (рекомендуется):**
```bash
wget -O - https://raw.githubusercontent.com/sjgagahvabw/vpn-shield/main/auto-vpn-install.sh | bash
```

**Вариант B - По отдельности:**
```bash
# Шаг 1: Установите Xray (VLESS/REALITY)
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) install

# Шаг 2: Настройте VLESS
wget https://raw.githubusercontent.com/sjgagahvabw/vpn-shield/main/auto-vpn-install.sh
bash auto-vpn-install.sh

# Шаг 3: Добавьте Shadowsocks
wget https://raw.githubusercontent.com/sjgagahvabw/vpn-shield/main/add-shadowsocks.sh
bash add-shadowsocks.sh

# Шаг 4: Добавьте Hysteria2
# (уже включен в auto-vpn-install.sh)
```

## Что получите:

- ✅ VLESS/REALITY (443) - стелс
- ✅ Hysteria2 (36712) - мобильные сети
- ✅ Shadowsocks 2022 (8388) - быстрый
- ✅ Trojan (8444) - надежный
- ✅ VMess (8443) - классический
- ✅ Единая подписка для всех
- ✅ QR коды для каждого протокола
- ✅ Автомониторинг каждые 5 минут
- ✅ Ключи НЕ меняются при автосмене

## Проверка после установки:

```bash
# Статус
systemctl status xray
systemctl status hysteria-server

# Подписка
cat /root/vpn-shield/subscription.txt

# Информация
cat /root/vpn-shield/info.txt
```
