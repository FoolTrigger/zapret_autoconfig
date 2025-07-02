#!/bin/sh
###############################################################################
#  Quick installer for zapret_autoconfig.sh
#  - Downloads script to /tmp
#  - Optionally injects Telegram credentials
#  - Schedules daily run at 00:00 via cron
###############################################################################

# ➜ Замените USERNAME и REPO на свои
GITHUB_USER="FoolTrigger"
GITHUB_REPO="zapret_autoconfig"

SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/main/zapret_autoconfig.sh"
LOCAL_SCRIPT="/tmp/zapret_autoconfig.sh"

info()  { printf "\033[1;32m[INFO]\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
error() { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*"; }

###############################################################################
# 1. Скачать основной скрипт
###############################################################################
info "Скачиваем zapret_autoconfig.sh в ${LOCAL_SCRIPT} ..."
if ! wget -q -O "${LOCAL_SCRIPT}" "${SCRIPT_URL}"; then
  error "Не удалось скачать скрипт по URL: ${SCRIPT_URL}"
  exit 1
fi
chmod +x "${LOCAL_SCRIPT}"
info "Скрипт загружен и сделан исполняемым."

###############################################################################
# 2. Запрос Telegram‑уведомлений
###############################################################################
echo -n "❓ Хотите получать уведомления в Telegram? [y/N]: "
read use_tg
use_tg=$(echo "$use_tg" | tr '[:upper:]' '[:lower:]')

if [ "$use_tg" = "y" ] || [ "$use_tg" = "yes" ]; then
  printf "🔐 Введите Telegram Bot Token: "
  read tg_token
  printf "💬 Введите Telegram Chat ID: "
  read tg_chatid

  # Вставляем/заменяем строки в скрипте
  sed -i \
    -e "s|^TELEGRAM_BOT_TOKEN=\"[^\"]*\"|TELEGRAM_BOT_TOKEN=\"${tg_token}\"|" \
    -e "s|^TELEGRAM_CHAT_ID=\"[^\"]*\"|TELEGRAM_CHAT_ID=\"${tg_chatid}\"|" \
    "${LOCAL_SCRIPT}"

  info "Данные Telegram вставлены."
else
  warn "Telegram‑уведомления отключены. Позже можно добавить токен вручную в ${LOCAL_SCRIPT}."
fi

###############################################################################
# 3. Добавить задание в cron (если ещё нет)
###############################################################################
CRON_EXPRESSION="0 0 * * * ${LOCAL_SCRIPT}"
if crontab -l 2>/dev/null | grep -Fq "${LOCAL_SCRIPT}"; then
  warn "Запись в cron уже существует — пропускаю добавление."
else
  ( crontab -l 2>/dev/null; echo "${CRON_EXPRESSION}" ) | crontab -
  info "Добавлена cron‑задача: ${CRON_EXPRESSION}"
fi

###############################################################################
info "Установка завершена! Скрипт будет проверять доступность YouTube каждый день в 00:00."
exit 0
