# 🚦 zapret_autoconfig

Автоматический скрипт для подбора и применения параметров DPI-обхода в проекте [zapret](https://github.com/bol-van/zapret) и проекта [zapret-openwrt](https://github.com/remittor/zapret-openwrt), с проверкой доступности YouTube и Telegram-уведомлениями.

---

## 📋 Содержание

| пункт | описание |
|-------|----------|
| [1. Что делает скрипт](#1-что-делает-скрипт) |
| [2. Требования](#2-требования) |
| [3. Скачивание PuTTY (Windows)](#3-скачивание-putty-windows) |
| [4. Быстрая автоматическая установка](#4-быстрая-автоматическая-установка) |

---

## 1. Что делает скрипт

1. Проверяет доступность `https://www.youtube.com`.
2. Если YouTube **доступен** — тихо завершается.  
   Если **недоступен** — запускает подбор конфигурации:  
   - **Фаза 1 (light)** — быстрые/лёгкие методы обхода;  
   - **Фаза 2 (heavy)** — надёжные/агрессивные методы.
3. После каждой попытки:
   - Записывает новую строку `NFQWS_OPT="..."` в `/opt/zapret/config`;
   - Перезапускает `/etc/init.d/zapret`;
   - Снова проверяет YouTube.
4. При успехе — отправляет уведомление в Telegram (если настроено).
5. Надёжность:
   - защита от параллельного запуска (`flock`);
   - до 12 попыток (6 light + 6 heavy).

---

## 2. Требования

| ПО / пакет | Примечание |
|------------|------------|
| **OpenWrt 23 +**      | или любая совместимая прошивка с `ash`/`busybox` |
| **zapret**               | [[репозиторий]](https://github.com/remittor/zapret-openwrt) — должен быть установлен и рабочий |
| `curl` + `wget-ssl`      | для проверки YouTube и загрузки файлов |
| `flock` (из `util-linux`) | обычно уже есть в OpenWrt репозитории |
| **PuTTY** (Windows)      | SSH‑клиент для подключения к роутеру |

---

## 3. Скачивание **PuTTY** (Windows)

1. Перейдите на <https://www.putty.org>  
2. Скачайте **`putty.exe`** (32‑/64‑bit) и установите.  
3. Откройте **PuTTY** и подключитесь к роутеру:  
   - Host Name: `192.168.1.1` (или IP вашего OpenWrt)  
   - Port `22`, Protocol `SSH`.  
4. Авторизуйтесь (по умолчанию `root` / пароль, заданный в LuCI).

---

## 4. Быстрая-автоматическая-установка
Введите следующую команду:
<pre><code>#!/bin/sh

echo "[INFO] Отключаем zapret..."
/etc/init.d/zapret stop
sleep 5

echo "[INFO] Пытаемся скачать скрипт..."
wget -O /tmp/quick_install.sh https://raw.githubusercontent.com/FoolTrigger/zapret_autoconfig/main/quick_install.sh
if [ $? -ne 0 ]; then
  echo "[ERROR] Скачивание не удалось. Не запускаем zapret."
  exit 1
fi

echo "[INFO] Делаем скрипт исполняемым..."
chmod +x /tmp/quick_install.sh

echo "[INFO] Запускаем zapret..."
/etc/init.d/zapret start
sleep 5

echo "[INFO] Запускаем скрипт..."
/tmp/quick_install.sh</code></pre>

Разработано для удобного подбора конфигураций обхода DPI для OpenWRT.
Благодарность за проект zapret — ©bol‑van, мы лишь автоматизируем рутину.
