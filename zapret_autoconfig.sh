#!/bin/sh

(
  flock -n 9 || {
    echo "[zapret_autoconfig] Скрипт уже запущен, выход."
    exit 1
  }

  CONFIG_FILE="/opt/zapret/config"
  SERVICE_SCRIPT="/etc/init.d/zapret"
  TELEGRAM_BOT_TOKEN=""  # вставь токен бота
  TELEGRAM_CHAT_ID=""    # вставь id чата
  YOUTUBE_URL="https://www.youtube.com"
  MAX_ATTEMPTS=12

  # Разделитель конфигов для массива
  CONFIG_SEPARATOR="__END__"

  # Массив готовых конфигов (каждый блок — одна конфигурация)
  READY_CONFIGS="
--filter-tcp=80 <HOSTLIST>
--dpi-desync=fake,fakedsplit
--dpi-desync-autottl=2
--dpi-desync-fooling=badsum

--new
--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake,multidisorder
--dpi-desync-split-pos=1,midsld
--dpi-desync-repeats=11
--dpi-desync-fooling=badsum
--dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com

--new
--filter-udp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake
--dpi-desync-repeats=11
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin

--new
--filter-udp=443 <HOSTLIST_NOAUTO>
--dpi-desync=fake
--dpi-desync-repeats=11

--new
--filter-tcp=443 <HOSTLIST>
--dpi-desync=multidisorder
--dpi-desync-split-pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

__END__

--filter-udp=443 --hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake
--dpi-desync-udplen-increment=10
--dpi-desync-repeats=6
--dpi-desync-udplen-pattern=0xDEADBEEF
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin

--new
--filter-udp=50000-65535
--dpi-desync=fake
--dpi-desync-any-protocol
--dpi-desync-cutoff=d3
--dpi-desync-repeats=6
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin

--new
--filter-tcp=80 <HOSTLIST>
--dpi-desync=fake
--dpi-desync-autottl=2
--dpi-desync-fooling=md5sig

--new
--filter-tcp=443 --hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake
--dpi-desync-autottl=2
--dpi-desync-repeats=6
--dpi-desync-fooling=md5sig
--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin

__END__

--filter-udp=443 --hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake
--dpi-desync-udplen-increment=10
--dpi-desync-repeats=6
--dpi-desync-udplen-pattern=0xDEADBEEF
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin
--new
--filter-udp=50000-65535
--dpi-desync=fake
--dpi-desync-any-protocol
--dpi-desync-cutoff=d3
--dpi-desync-repeats=6
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin
--new
--filter-tcp=80 ˂HOSTLIST˃
--dpi-desync=fake
--dpi-desync-autottl=2
--dpi-desync-fooling=md5sig
--new
--filter-tcp=443 --hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake
--dpi-desync-autottl=2
--dpi-desync-repeats=6
--dpi-desync-fooling=badseq
--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin

__END__

--filter-tcp=80 ˂HOSTLIST˃
--dpi-desync=fakedsplit
--dpi-desync-ttl=4
--dpi-desync-repeats=16

--new
--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fakedsplit
--dpi-desync-split-pos=1,midsld
--dpi-desync-ttl=4
--dpi-desync-repeats=16
--dpi-desync-fake-tls-mod=padencap
--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin

--new
--filter-udp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake
--dpi-desync-repeats=16
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin

--new
--filter-udp=443 ˂HOSTLIST_NOAUTO˃
--dpi-desync=fake
--dpi-desync-repeats=16

--new
--filter-tcp=443 ˂HOSTLIST˃
--dpi-desync=fakeddisorder
--dpi-desync-ttl=4
--dpi-desync-repeats=16
--dpi-desync-fake-tls-mod=padencap

--new
--filter-udp=50000-50099
--filter-l7=discord,stun
--dpi-desync=fake

__END__

-filter-tcp=80
--dpi-desync=fakedsplit
--dpi-desync-ttl=3
--dpi-desync-repeats=12

--new
--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fakedsplit
--dpi-desync-split-pos=1,midsld
--dpi-desync-ttl=3
--dpi-desync-repeats=12
--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin

--new
--filter-udp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake
--dpi-desync-repeats=11
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin

--new
--filter-udp=443 <HOSTLIST_NOAUTO>
--dpi-desync=fake
--dpi-desync-repeats=11

--new
--filter-tcp=443
--dpi-desync=fakeddisorder
--dpi-desync-ttl=3
--dpi-desync-repeats=12

--new
--filter-udp=50000-50099
--filter-l7=discord,stun
--dpi-desync=fake

__END__

--filter-tcp=443
--hostlist-domains=discord.com,cdn.discordapp.com,gateway.discord.gg,media.discordapp.net
--dpi-desync=fake,split2
--dpi-desync-repeats=6
--dpi-desync-fooling=md5sig
--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin
--dpi-desync-fake-tls-mod=none
--new

--filter-udp=50000-50100
--filter-l7=discord,stun
--dpi-desync=fake
--dpi-desync-repeats=6
--new

--filter-udp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake
--dpi-desync-repeats=6
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin
--new

--filter-tcp=80
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake,split2
--dpi-desync-autottl=2
--dpi-desync-fooling=md5sig
--new

--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake,split2
--dpi-desync-repeats=6
--dpi-desync-fooling=md5sig
--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin
--new

--filter-udp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake
--dpi-desync-repeats=16
--dpi-desync-any-protocol
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin
--new

--filter-tcp=80
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fakeddisorder
--dpi-desync-autottl=4
--dpi-desync-repeats=16
--dpi-desync-fooling=md5sig
--new

--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fakeddisorder
--dpi-desync-repeats=16
--dpi-desync-fooling=md5sig
--dpi-desync-cutoff=d3
--new

--filter-tcp=80
--hostlist=/opt/zapret/ipset/zapret-hosts-user.txt
--dpi-desync=fakedsplit
--dpi-desync-split-pos=1,midsld
--dpi-desync-autottl=4
--dpi-desync-repeats=16
--new

--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-user.txt
--dpi-desync=fakedsplit
--dpi-desync-split-pos=1,midsld
--dpi-desync-autottl=4
--dpi-desync-repeats=16
--dpi-desync-fake-tls-mod=padencap
--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin
--new

--filter-udp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-user.txt
--dpi-desync=fake
--dpi-desync-repeats=16
--dpi-desync-any-protocol
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin
--new

--filter-tcp=80
--hostlist=/opt/zapret/ipset/cust1.txt
--dpi-desync=fakedsplit
--dpi-desync-split-pos=1,midsld
--dpi-desync-autottl=4
--dpi-desync-repeats=16
--new

--filter-tcp=443
--hostlist=/opt/zapret/ipset/cust1.txt
--dpi-desync=fakedsplit
--dpi-desync-split-pos=1,midsld
--dpi-desync-autottl=4
--dpi-desync-fake-tls-mod=padencap
--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin
--dpi-desync-repeats=16
--new

--filter-udp=443
--hostlist=/opt/zapret/ipset/cust1.txt
--dpi-desync=fake
--dpi-desync-repeats=16
--dpi-desync-any-protocol
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin
--new

--filter-tcp=80
--hostlist=/opt/zapret/ipset/cust2.txt
--dpi-desync=fakedsplit
--dpi-desync-split-pos=1,midsld
--dpi-desync-autottl=4
--dpi-desync-repeats=16
--new

--filter-tcp=443
--hostlist=/opt/zapret/ipset/cust2.txt
--dpi-desync=fakedsplit
--dpi-desync-split-pos=1,midsld
--dpi-desync-autottl=4
--dpi-desync-fake-tls-mod=padencap
--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin
--dpi-desync-repeats=16
--new

--filter-udp=443
--hostlist=/opt/zapret/ipset/cust2.txt
--dpi-desync=fake
--dpi-desync-repeats=16
--dpi-desync-any-protocol
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin

__END__

--filter-tcp=80
--dpi-desync=fakeddisorder
--dpi-desync-ttl=0
--dpi-desync-repeats=16
--dpi-desync-fooling=md5sig
--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin
--new
--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fakeddisorder
--dpi-desync-repeats=16
--dpi-desync-fooling=md5sig
--new
--filter-udp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fakeddisorder
--dpi-desync-repeats=11
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin
--new
--filter-udp=443 ˂HOSTLIST_NOAUTO˃
--dpi-desync=fake
--dpi-desync-repeats=11
--new
--filter-tcp=443 ˂HOSTLIST˃
--dpi-desync=fakeddisorder
--dpi-desync-split-pos=midsld
--dpi-desync-repeats=6
--dpi-desync-fooling=badseq,md5sig

__END__

--filter-tcp=80 ˂HOSTLIST˃
--dpi-desync=fake,multisplit
--dpi-desync-ttl=0
--dpi-desync-repeats=16
--dpi-desync-fooling=badsum
--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin

--new
--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake,multisplit
--dpi-desync-fooling=badsum
--dpi-desync-split-pos=1
--dpi-desync-fake-tls=0x00000000
--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin

--new
--filter-udp=443 ˂HOSTLIST_NOAUTO˃
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake
--dpi-desync-repeats=16
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin

--new
--filter-tcp=443 ˂HOSTLIST˃
--dpi-desync=fakeddisorder
--dpi-desync-ttl=0
--dpi-desync-repeats=16
--dpi-desync-fooling=badsum
--dpi-desync-fake-tls-mod=padencap
--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin
"

  # Параметры для обязательного перебора
  TCP_FILTERS=("80 <HOSTLIST>" "443 --hostlist=/opt/zapret/ipset/zapret-hosts-google.txt" "443 <HOSTLIST>")
  UDP_FILTERS=("443 <HOSTLIST_NOAUTO>")

  DPI_MODES=("fake" "fakedsplit" "multidisorder" "fakeddisorder" "split" "split2")
  DPI_FOOLING=("badsum" "md5sig" "badseq" "padencap" "none")
  DPI_REPEATS=("6" "8" "11" "16")
  DPI_TTLS=("2" "4")
  HOSTLISTS=("/opt/zapret/ipset/zapret-hosts-google.txt" "/opt/zapret/ipset/zapret-hosts-user.txt")
  FAKE_TLS_FILES=("/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "")
  FAKE_QUIC_FILES=("/opt/zapret/files/fake/quic_initial_www_google_com.bin" "")

  send_telegram() {
    [ -z "$TELEGRAM_BOT_TOKEN" ] && return
    [ -z "$TELEGRAM_CHAT_ID" ] && return
    message="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
      -d chat_id="$TELEGRAM_CHAT_ID" \
      -d text="$message" >/dev/null 2>&1
  }

  check_youtube() {
    curl -s --max-time 10 -I "$YOUTUBE_URL" >/dev/null 2>&1
    return $?
  }

  replace_config_line() {
    new_value="$1"
    sed -i "/^NFQWS_OPT=/c\NFQWS_OPT=\"$new_value\"" "$CONFIG_FILE"
  }

  restart_zapret() {
    $SERVICE_SCRIPT restart
    sleep 15
  }

  # Функция запуска перебора шаблонов из READY_CONFIGS
  try_ready_configs() {
    echo "[zapret_autoconfig] Пробуем готовые конфигурации обхода..."
    IFS="$CONFIG_SEPARATOR"
    for config in $READY_CONFIGS; do
      config_trimmed=$(echo "$config" | sed 's/^[ \t\r\n]*//;s/[ \t\r\n]*$//')
      if [ -z "$config_trimmed" ]; then
        continue
      fi
      echo "[zapret_autoconfig] Пробуем конфиг:"
      echo "$config_trimmed"
      replace_config_line "$config_trimmed"
      restart_zapret
      if check_youtube; then
        echo "[zapret_autoconfig] Успешно с готовым конфигом!"
        send_telegram "✅ Zapret обход успешно настроен готовым конфигом."
        exit 0
      else
        echo "[zapret_autoconfig] YouTube недоступен с этим конфигом."
      fi
    done
    unset IFS
  }

  # Функция умного перебора параметров для критичных фильтров
  smart_param_search() {
    echo "[zapret_autoconfig] Начинаем умный перебор параметров..."

    phases=("light" "heavy")
    attempt=1
    for phase in "${phases[@]}"; do
      echo "[zapret_autoconfig] Фаза перебора: $phase"
      # Настройки по фазам
      case "$phase" in
        light)
          dpi_modes_light=("fake" "fakedsplit" "multidisorder")
          dpi_fooling_light=("badsum" "md5sig")
          dpi_repeats_light=("6" "8")
          dpi_ttls_light=("2")
          ;;
        heavy)
          dpi_modes_light=("${DPI_MODES[@]}")
          dpi_fooling_light=("${DPI_FOOLING[@]}")
          dpi_repeats_light=("${DPI_REPEATS[@]}")
          dpi_ttls_light=("${DPI_TTLS[@]}")
          ;;
      esac

      for tcp_filter in "${TCP_FILTERS[@]}"; do
        for dpi_mode in "${dpi_modes_light[@]}"; do
          for dpi_fooling in "${dpi_fooling_light[@]}"; do
            for dpi_repeats in "${dpi_repeats_light[@]}"; do
              for dpi_ttl in "${dpi_ttls_light[@]}"; do
                for hostlist in "${HOSTLISTS[@]}"; do
                  # Формируем конфиг для TCP
                  tcp_config="--filter-tcp=$tcp_filter $hostlist"
                  tcp_config="$tcp_config --dpi-desync=$dpi_mode"
                  tcp_config="$tcp_config --dpi-desync-autottl=$dpi_ttl"
                  tcp_config="$tcp_config --dpi-desync-fooling=$dpi_fooling"
                  tcp_config="$tcp_config --dpi-desync-repeats=$dpi_repeats"

                  # fake tls, если TCP 443 с google-hostlist
                  if echo "$tcp_filter" | grep -q "443" && echo "$hostlist" | grep -q "google"; then
                    tcp_config="$tcp_config --dpi-desync-fake-tls=${FAKE_TLS_FILES[0]}"
                  fi

                  # Формируем конфиг для UDP (обязателен для всех)
                  for udp_filter in "${UDP_FILTERS[@]}"; do
                    udp_config="--new --filter-udp=$udp_filter $hostlist"
                    udp_config="$udp_config --dpi-desync=$dpi_mode"
                    udp_config="$udp_config --dpi-desync-repeats=$dpi_repeats"

                    # fake quic, если UDP 443 с google-hostlist
                    if echo "$udp_filter" | grep -q "443" && echo "$hostlist" | grep -q "google"; then
                      udp_config="$udp_config --dpi-desync-fake-quic=${FAKE_QUIC_FILES[0]}"
                    fi

                    full_config="$tcp_config $udp_config"

                    echo "[zapret_autoconfig] Попытка #$attempt (фаза: $phase)..."
                    replace_config_line "$full_config"
                    restart_zapret

                    if check_youtube; then
                      echo "[zapret_autoconfig] YouTube доступен, конфиг успешно подобран."
                      send_telegram "✅ Zapret обход успешно настроен на попытке #$attempt (фаза: $phase)."
                      exit 0
                    fi

                    attempt=$((attempt + 1))
                    if [ $attempt -gt $MAX_ATTEMPTS ]; then
                      return 1
                    fi
                  done
                done
              done
            done
          done
        done
      done
    done
    return 1
  }

  echo "[zapret_autoconfig] Проверяем доступность YouTube..."
  if check_youtube; then
    echo "[zapret_autoconfig] YouTube доступен, обход не требуется. Выход."
    exit 0
  fi

  send_telegram "⚠️ YouTube недоступен! Начинаем подбор обхода Zapret..."

  # Пробуем готовые конфиги
  try_ready_configs

  # Если не помогли - перебираем параметры умно
  if ! smart_param
