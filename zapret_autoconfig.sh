#!/bin/sh
###############################################################################
# zapret_autoconfig.sh
#  ─ интеллектуальный подбор конфигурации NFQWS_OPT для обхода DPI на OpenWrt
#    ▸ сначала лёгкие (быстрые) методы, затем тяжёлые (эффективные)
#    ▸ результаты — в Telegram (если задан токен)
###############################################################################

(
  ###########################  ‣ Блокировка запуска  ##########################
  flock -n 9 || { echo "[zapret_autoconfig] уже запущен — выходим."; exit 1; }

  ###########################  ‣ Параметры пользователя  ######################
  CONFIG_FILE="/opt/zapret/config"        # куда вставляется NFQWS_OPT
  SERVICE_SCRIPT="/etc/init.d/zapret"     # перезапуск службы zapret

  TELEGRAM_BOT_TOKEN=""                   # ← сюда вставит quick_install.sh
  TELEGRAM_CHAT_ID=""                     # ← сюда вставит quick_install.sh

  # Кол‑во попыток (сначала FAST_PHASE_ATTEMPTS лёгких, затем тяжёлые):
  MAX_ATTEMPTS=12
  FAST_PHASE_ATTEMPTS=5

  YOUTUBE_URL="https://www.youtube.com"

  ###########################  ‣ Наборы параметров  ###########################

  # — Лёгкая фаза (быстродействие) —
  LIGHT_MODES="fake fakedsplit split"
  LIGHT_REPEATS="6 8"
  LIGHT_TTLS="2"

  # — Тяжёлая фаза (эффективность) —
  HEAVY_MODES="multidisorder split2 fakeddisorder"
  HEAVY_REPEATS="11 16"
  HEAVY_TTLS="4"

  # Общие списки
  FILTER_TCP_OPTIONS="80 443 80,443"
  FILTER_UDP_OPTIONS="443 50000-50100 50000-65535"
  DPI_DESYNC_FOOLING="badsum md5sig badseq padencap none"
  HOSTLISTS="/opt/zapret/ipset/zapret-hosts-google.txt /opt/zapret/ipset/zapret-hosts-user.txt"
  FAKE_TLS_FILE="/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"
  FAKE_QUIC_FILE="/opt/zapret/files/fake/quic_initial_www_google_com.bin"

  ###########################  ‣ Вспомогательные функции  ####################

  pick_random() { set -- $1; n=$#; idx=$((RANDOM % n + 1)); eval echo "\${$idx}"; }

  send_telegram() {
    [ -z "$TELEGRAM_BOT_TOKEN" ] && return 0
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
      -d chat_id="$TELEGRAM_CHAT_ID" -d text="$1" >/dev/null 2>&1
  }

  check_youtube() {
    curl -s --max-time 10 -I "$YOUTUBE_URL" | grep -q "200 OK"
  }

  generate_config() {
    phase="$1"  # light | heavy
    if [ "$phase" = "light" ]; then
      MODES="$LIGHT_MODES";  REPEATS="$LIGHT_REPEATS";  TTLS="$LIGHT_TTLS"
      USE_FAKE_TLS=0;        USE_FAKE_QUIC=0
    else
      MODES="$HEAVY_MODES";  REPEATS="$HEAVY_REPEATS";  TTLS="$HEAVY_TTLS"
      USE_FAKE_TLS=1;        USE_FAKE_QUIC=1
    fi

    tcp=$(pick_random "$FILTER_TCP_OPTIONS")
    udp=$(pick_random "$FILTER_UDP_OPTIONS")
    mode=$(pick_random "$MODES")
    fool=$(pick_random "$DPI_DESYNC_FOOLING")
    reps=$(pick_random "$REPEATS")
    ttl=$(pick_random "$TTLS")
    list=$(pick_random "$HOSTLISTS")

    cfg="--filter-tcp=$tcp $list \
--dpi-desync=$mode --dpi-desync-autottl=$ttl \
--dpi-desync-fooling=$fool --dpi-desync-repeats=$reps"

    [ $USE_FAKE_TLS -eq 1 ]  && cfg="$cfg --dpi-desync-fake-tls=$FAKE_TLS_FILE"
    cfg="$cfg --new --filter-udp=$udp $list \
--dpi-desync=$mode --dpi-desync-repeats=$reps"
    [ $USE_FAKE_QUIC -eq 1 ] && cfg="$cfg --dpi-desync-fake-quic=$FAKE_QUIC_FILE"

    echo "$cfg"
  }

  replace_config_line() {
    sed -i "s|^NFQWS_OPT=.*|NFQWS_OPT=\"$1\"|" "$CONFIG_FILE"
  }

  restart_zapret() {
    "$SERVICE_SCRIPT" restart >/dev/null 2>&1
    sleep 10
  }

  ###########################  ‣ Логика работы  ##############################

  echo "[zapret_autoconfig] Проверяем доступность YouTube..."
  if check_youtube; then
    echo "✅ YouTube уже доступен. Скрипт завершается."
    exit 0
  fi

  send_telegram "⚠️ YouTube недоступен. Запускаем подбор конфигурации DPI…"

  attempt=0
  while [ $attempt -lt $MAX_ATTEMPTS ]; do
    attempt=$((attempt + 1))
    phase="light"; [ $attempt -gt $FAST_PHASE_ATTEMPTS ] && phase="heavy"

    echo "🔄 Попытка $attempt (фаза: $phase)…"
    cfg=$(generate_config "$phase")
    replace_config_line "$cfg"
    restart_zapret

    if check_youtube; then
      send_telegram "✅ Обход настроен на попытке #$attempt!\nКонфиг:\n$cfg"
      echo "🎉 Успех — YouTube доступен."
      exit 0
    fi
  done

  send_telegram "❌ Не удалось настроить обход за $MAX_ATTEMPTS попыток."
  echo "🚫 Скрипт завершился без успешного результата."
  exit 1

) 9>/var/run/zapret_config.lock
