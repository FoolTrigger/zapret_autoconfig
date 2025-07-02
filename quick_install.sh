#!/bin/sh

# Путь для временного скрипта
TARGET_SCRIPT="/tmp/zapret_autoconfig.sh"
SCRIPT_URL="https://raw.githubusercontent.com/FoolTrigger/zapret_autoconfig/main/zapret_autoconfig.sh"

echo "[INFO] Скачиваем zapret_autoconfig.sh в $TARGET_SCRIPT ..."
wget -q -O "$TARGET_SCRIPT" "$SCRIPT_URL"

if [ ! -f "$TARGET_SCRIPT" ]; then
  echo "[ERROR] Не удалось загрузить основной скрипт."
  exit 1
fi

chmod +x "$TARGET_SCRIPT"
echo "[INFO] Скрипт загружен и сделан исполняемым."

# Запрос на Telegram-оповещения
echo "Хотите получать уведомления в Telegram? [y/N]: "
read enable_tg

if [ "$enable_tg" = "y" ] || [ "$enable_tg" = "Y" ]; then
  echo "Введите Telegram Bot Token: "
  read tg_token

  echo "Введите Telegram Chat ID: "
  read tg_chat_id

  # Подставим токены в нужные строки внутри скрипта
  sed -i "s|TELEGRAM_BOT_TOKEN=\".*\"|TELEGRAM_BOT_TOKEN=\"$tg_token\"|" "$TARGET_SCRIPT"
  sed -i "s|TELEGRAM_CHAT_ID=\".*\"|TELEGRAM_CHAT_ID=\"$tg_chat_id\"|" "$TARGET_SCRIPT"
else
  # Выключаем Telegram-оповещения
  sed -i "s|TELEGRAM_BOT_TOKEN=\".*\"|TELEGRAM_BOT_TOKEN=\"\"|" "$TARGET_SCRIPT"
  sed -i "s|TELEGRAM_CHAT_ID=\".*\"|TELEGRAM_CHAT_ID=\"\"|" "$TARGET_SCRIPT"
fi

# Создание задания в crontab
CRON_LINE="0 0 * * * /bin/sh $TARGET_SCRIPT"
( crontab -l 2>/dev/null | grep -v "$TARGET_SCRIPT" ; echo "$CRON_LINE" ) | crontab -

echo "[OK] Скрипт установлен. Он будет запускаться каждый день в 00:00."
