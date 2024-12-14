#!/usr/bin/env bash
# shellcheck disable=SC2269

SLEEP_TIME=3
NTFY_HOST="${NTFY_HOST}" # "https://ntfy.example.com/downdetector"

declare -A fail_counts
declare -A last_notified

readarray -t hosts <hosts.txt # newline-separated list of hosts

while true; do
  for host in "${hosts[@]}"; do
    echo "Pinging $host"
    ping_status="$(ping -c 1 -W 1 "$host" | grep "1 packets received")"
    if [ -z "$ping_status" ]; then
      echo "Host $host is down"
      fail_counts["$host"]=$((fail_counts["$host"] + 1))
    else
      echo "Host $host is up"
      fail_counts["$host"]=0
    fi
    if [ "${fail_counts["$host"]}" -eq 3 ]; then
      echo "Host $host is down"
      current_time=$(date +%s)
      if [ -z "${last_notified["$host"]}" ] ||
        [ $((current_time - last_notified["$host"])) -ge 86400 ]; then
        curl -d "Host $host is down" "$NTFY_HOST"
        last_notified["$host"]=$current_time
      fi
      fail_counts["$host"]=0
    fi
    sleep "$SLEEP_TIME"
  done
done
