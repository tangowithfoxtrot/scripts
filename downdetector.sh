#!/usr/bin/env bash

SLEEP_TIME=3
NTFY_HOST="" # "https://ntfy.example.com/downdetector"

declare -A fail_counts

readarray -t ips <ips.txt

while true; do
  for ip in "${ips[@]}"; do
    echo "Pinging $ip"
    ping_status="$(ping -c 1 -W 1 "$ip" | grep "1 packets received")"
    if [ -z "$ping_status" ]; then
      echo "Host $ip is down"
      fail_counts["$ip"]=$((fail_counts["$ip"] + 1))
    else
      echo "Host $ip is up"
      fail_counts["$ip"]=0
    fi
    if [ "${fail_counts["$ip"]}" -eq 3 ]; then
      echo "Host $ip is down"
      curl -d "Host $ip is down" "$NTFY_HOST"
      fail_counts["$ip"]=0
    fi
    sleep "$SLEEP_TIME"
  done
done
