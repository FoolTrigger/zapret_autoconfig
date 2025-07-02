#!/bin/sh

(
  flock -n 9 || {
    echo "Скрипт уже запущен, выход."
    exit 1
  }

  CONFIG_FILE="/opt/zapret/config"
  SERVICE_SCRIPT="/etc/init.d/zapret"
  TELEGRAM_BOT_TOKEN=""  # вставь токен бота
  TELEGRAM_CHAT_ID=""    # вставь id чата
  MAX_ATTEMPTS=20
  YOUTUBE_URL="https://www.youtube.com"

  # Легкие параметры — быстрые попытки
  FILTER_TCP_OPTIONS_LIGHT="80 443"
  FILTER_UDP_OPTIONS_LIGHT="443 50000-50100"
  DPI_DESYNC_MODES_LIGHT="fake fakedsplit"
  DPI_DESYNC_FOOLING_LIGHT="badsum md5sig"
  DPI_DESYNC_REPEATS_LIGHT="6 8"
  DPI_DESYNC_TTLS_LIGHT="2"

  # Тяжелые параметры — более эффективные, но медленнее
  FILTER_TCP_OPTIONS_HEAVY="80,443"
  FILTER_UDP_OPTIONS_HEAVY="50000-65535"
  DPI_DESYNC_MODES_HEAVY="multidisorder fakeddisorder split split2"
  DPI_DESYNC_FOOLING_HEAVY="badseq padencap none"
  DPI_DESYNC_REPEATS_HEAVY="11 16"
  DPI_DESYNC_TTLS_HEAVY="4"

  HOSTLISTS="/opt/zapret/ipset/zapret-hosts-google.txt /opt/zapret/ipset/zapret-hosts-user.txt"
  FAKE_TLS_FILES="/opt/zapret/files/fake/tls_clienthello_www_google_com.bin ''"
  FAKE_QUIC_FILES="/opt/zapret/files/fake/quic_initial_www_google_com.bin ''"

  pick_random() {
    set -- $1
    count=$#
    index=$(( RANDOM % count + 1 ))
    i=1
    for item in "$@"; do
      if [ $i -eq $index ]; then
        echo "$item"
        return
      fi
      i=$((i + 1))
    done
  }

  send_telegram() {
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
      message="$1"
      curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$message" >/dev/null 2>&1
    fi
  }

  check_youtube() {
    curl -s --max-time 10 -I "$YOUTUBE_URL" >/dev/null 2>&1
    return $?
  }

  generate_config() {
    tcp_filter="$1"
    udp_filter="$2"
    dpi_mode="$3"
    dpi_fooling="$4"
    dpi_repeats="$5"
    dpi_ttl="$6"

    hostlist=$(pick_random "$HOSTLISTS")
    fake_tls=$(pick_random "$FAKE_TLS_FILES")
    fake_quic=$(pick_random "$FAKE_QUIC_FILES")

    config="--filter-tcp=$tcp_filter $hostlist"
    config="$config --dpi-desync=$dpi_mode"
    config="$config --dpi-desync-autottl=$dpi_ttl"
    config="$config --dpi-desync-fooling=$dpi_fooling"
    config="$config --dpi-desync-repeats=$dpi_repeats"
    if [ "$fake_tls" != "''" ] && [ -n "$fake_tls" ]; then
      config="$config --dpi-desync-fake-tls=$fake_tls"
    fi
    config="$config --new"
    config="$config --filter-udp=$udp_filter $hostlist"
    config="$config --dpi-desync=$dpi_mode"
    config="$config --dpi-desync-repeats=$dpi_repeats"
    if [ "$fake_quic" != "''" ] && [ -n "$fake_quic" ]; then
      config="$config --dpi-desync-fake-quic=$fake_quic"
    fi

    echo "$config"
  }

  replace_config_line() {
    new_value="$1"
    sed -i "/^NFQWS_OPT=/c\NFQWS_OPT=\"$new_value\"" "$CONFIG_FILE"
  }

  restart_zapret() {
    $SERVICE_SCRIPT restart
    sleep 10
  }

  echo "[zapret_autoconfig] Проверяем доступность YouTube..."
  if check_youtube; then
    echo "YouTube доступен, обход не требуется. Выход."
    exit 0
  fi

  send_telegram "⚠️ YouTube недоступен! Начинаем подбор обхода Zapret..."

  attempt=0
  while [ $attempt -lt $MAX_ATTEMPTS ]; do
    attempt=$((attempt + 1))

    if [ $attempt -le 6 ]; then
      phase="light"
      tcp_filter=$(pick_random "$FILTER_TCP_OPTIONS_LIGHT")
      udp_filter=$(pick_random "$FILTER_UDP_OPTIONS_LIGHT")
      dpi_mode=$(pick_random "$DPI_DESYNC_MODES_LIGHT")
      dpi_fooling=$(pick_random "$DPI_DESYNC_FOOLING_LIGHT")
      dpi_repeats=$(pick_random "$DPI_DESYNC_REPEATS_LIGHT")
      dpi_ttl=$(pick_random "$DPI_DESYNC_TTLS_LIGHT")
    else
      phase="heavy"
      tcp_filter=$(pick_random "$FILTER_TCP_OPTIONS_HEAVY")
      udp_filter=$(pick_random "$FILTER_UDP_OPTIONS_HEAVY")
      dpi_mode=$(pick_random "$DPI_DESYNC_MODES_HEAVY")
      dpi_fooling=$(pick_random "$DPI_DESYNC_FOOLING_HEAVY")
      dpi_repeats=$(pick_random "$DPI_DESYNC_REPEATS_HEAVY")
      dpi_ttl=$(pick_random "$DPI_DESYNC_TTLS_HEAVY")
    fi

    echo "🔄 Попытка $attempt (фаза: $phase)..."

    new_config=$(generate_config "$tcp_filter" "$udp_filter" "$dpi_mode" "$dpi_fooling" "$dpi_repeats" "$dpi_ttl")
    echo "Новый конфиг: $new_config"

    replace_config_line "$new_config"
    restart_zapret

    if check_youtube; then
      send_telegram "✅ Zapret обход настроен успешно на попытке #$attempt! Конфиг:\n$new_config"
      echo "YouTube доступен, конфиг успешно подобран."
      exit 0
    else
      echo "YouTube недоступен с текущим конфигом."
    fi
  done

  send_telegram "❌ Zapret обход НЕ удалось настроить за $MAX_ATTEMPTS попыток."
  exit 1

) 9>/var/run/zapret_config.lock
