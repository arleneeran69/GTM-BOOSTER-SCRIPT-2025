#!/data/data/com.termux/files/usr/bin/bash

## DNSTT Keep-Alive & DNS Monitor v2.2
## Author: GeoDevz69 | Enhanced by GeoDevz69 (Gateways First + Best Ping Suggestion)

VER="2.2"
LOOP_DELAY=5
FAIL_LIMIT=5
DIG_EXEC="DEFAULT"
CUSTOM_DIG="/data/data/com.termux/files/home/go/bin/fastdig"
VPN_INTERFACE="tun0"
RESTART_CMD="bash /data/data/com.termux/files/home/dnstt/start-client.sh"

# DNS Tunnel Servers (unchanged)
SERVERS=(
  "ns.jkrol.fiber-x.shop 124.6.181.167"
  "ns.jkrol.fiber-x.shop 124.6.181.31"
  "ns.jkrol.fiber-x.shop 124.6.181.26"
  "ns.jkrol.fiber-x.shop 124.6.181.25"
  "ns.jkrol.fiber-x.shop 124.6.181.171"
  "ns.jkrol.fiber-x.shop 124.6.181.161"
  "ns.jkrol.fiber-x.shop 124.6.181.27"
  "ns.jkrol.fiber-x.shop 124.6.181.248"
  "vpn.kagerou.site 124.6.181.167"
  "vpn.kagerou.site 124.6.181.31"
  "vpn.kagerou.site 124.6.181.26"
  "vpn.kagerou.site 124.6.181.25"
  "vpn.kagerou.site 124.6.181.171"
  "vpn.kagerou.site 124.6.181.161"
  "vpn.kagerou.site 124.6.181.27"
  "vpn.kagerou.site 124.6.181.248"
  "ns.juanscript.com 124.6.181.167"
  "ns.juanscript.com 124.6.181.171"
  "ns.juanscript.com 124.6.181.161"
  "ns.juanscript.com 124.6.181.27"
  "ns.juanscript.com 124.6.181.31"
  "ns.juanscript.com 124.6.181.26"
  "ns.juanscript.com 124.6.181.25"
  "ns.juanscript.com 124.6.181.248"
  "gtm.codered-api.shop 124.6.181.167"
  "gtm.codered-api.shop 124.6.181.171"
  "gtm.codered-api.shop 124.6.181.161"
  "gtm.codered-api.shop 124.6.181.27"
  "gtm.codered-api.shop 124.6.181.31"
  "gtm.codered-api.shop 124.6.181.26"
  "gtm.codered-api.shop 124.6.181.25"
  "gtm.codered-api.shop 124.6.181.248"
  "ns.olptf.fiber-x.shop 124.6.181.167"
  "ns.olptf.fiber-x.shop 124.6.181.171"
  "ns.olptf.fiber-x.shop 124.6.181.161"
  "ns.olptf.fiber-x.shop 124.6.181.27"
  "ns.olptf.fiber-x.shop 124.6.181.31"
  "ns.olptf.fiber-x.shop 124.6.181.26"
  "ns.olptf.fiber-x.shop 124.6.181.25"
  "ns.olptf.fiber-x.shop 124.6.181.248"
  "sgns.lenux333.fun 124.6.181.167"
  "sgns.lenux333.fun 124.6.181.171"
  "sgns.lenux333.fun 124.6.181.161"
  "sgns.lenux333.fun 124.6.181.27"
  "sgns.lenux333.fun 124.6.181.31"
  "sgns.lenux333.fun 124.6.181.26"
  "sgns.lenux333.fun 124.6.181.25"
  "sgns.lenux333.fun 124.6.181.248"
)

# Public DNS Gateways
GATEWAYS=( "1.1.1.1" "8.8.8.8" "8.8.4.4" "9.9.9.9" "0.0.0.0" )

fail_count=0
total_ok=0
total_fail=0

case "${DIG_EXEC}" in
  DEFAULT|D) _DIG=$(command -v dig) ;;
  CUSTOM|C) _DIG="${CUSTOM_DIG}" ;;
  *) echo "[!] Invalid DIG_EXEC: $DIG_EXEC"; exit 1 ;;
esac

[ ! -x "$_DIG" ] && echo "[!] dig not executable: $_DIG" && exit 1
trap 'echo -e "\n[+] Exiting..."; exit 0' SIGINT SIGTERM

color_ping() {
  local ms=$1
  if [[ $ms -le 100 ]]; then
    echo -e "\e[32m${ms}ms FAST\e[0m"
  elif [[ $ms -le 250 ]]; then
    echo -e "\e[33m${ms}ms MEDIUM\e[0m"
  else
    echo -e "\e[31m${ms}ms SLOW\e[0m"
  fi
}

check_interface() {
  if ip link show "$VPN_INTERFACE" > /dev/null 2>&1; then
    echo -e "\n[✓] $VPN_INTERFACE is UP"
    return 0
  else
    echo -e "\n[✗] $VPN_INTERFACE is DOWN"
    restart_vpn
    return 1
  fi
}

restart_vpn() {
  echo -e "\n\e[33m[!] Restarting DNSTT Client...\e[0m"
  pkill -f dnstt-client 2>/dev/null
  eval "$RESTART_CMD" &
  sleep 2
}

check_speed() {
  stats=$(ip -s link show "$VPN_INTERFACE" 2>/dev/null | grep -A1 'RX:' | tail -n1)
  RX=$(echo "$stats" | awk '{print $1}')
  TX=$(echo "$stats" | awk '{print $9}')
  if [[ "$RX" == "0" && "$TX" == "0" ]]; then
    echo -e "    \e[33m⚠️  RX/TX = 0 on $VPN_INTERFACE\e[0m"
  else
    echo -e "    🔄 RX=${RX}B | TX=${TX}B"
  fi
}

check_gateways() {
  echo -e "\n🌐 Checking Gateway DNS Response Times:"
  best_gw=""
  best_ping=9999
  for gw in "${GATEWAYS[@]}"; do
    out=$(ping -c1 -W2 "$gw" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      ms=$(echo "$out" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}')
      echo -ne "    $gw — "
      color_ping "$ms"
      if [[ $ms -lt $best_ping ]]; then
        best_ping=$ms
        best_gw=$gw
      fi
    else
      echo -e "    $gw — \e[31mUnreachable\e[0m"
    fi
  done
  if [[ -n "$best_gw" ]]; then
    echo -e "\n✅ Best Gateway (Airplane Mode): \e[1;36m$best_gw — $(color_ping $best_ping)\e[0m"
  else
    echo -e "\n⚠️  No reachable gateways detected."
  fi
}

check_servers() {
  local ok_count=0
  for entry in "${SERVERS[@]}"; do
    domain=$(echo "$entry" | awk '{print $1}')
    ip=$(echo "$entry" | awk '{print $2}')
    echo -e "\n[•] Checking \e[34m$domain\e[0m @ $ip"

    ping_out=$(ping -c1 -W2 "$ip" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      ping_ms=$(echo "$ping_out" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}')
      echo -ne "    \e[32m✓ Ping OK\e[0m — "
      color_ping "$ping_ms"
    else
      echo -e "    \e[31m✗ Ping FAIL\e[0m"
      ((fail_count++)); ((total_fail++))
      continue
    fi

    if timeout -k 3 3 "$_DIG" @"$ip" "$domain" > /dev/null 2>&1; then
      echo -e "    \e[32m✓ DNS Query OK\e[0m"
      ((ok_count++)); ((total_ok++))
    else
      echo -e "    \e[31m✗ DNS Query FAIL\e[0m"
      ((fail_count++)); ((total_fail++))
    fi
  done

  if (( fail_count >= FAIL_LIMIT )); then
    echo -e "\n\e[31m[!] Too many failures ($fail_count) — restarting tunnel\e[0m"
    fail_count=0
    restart_vpn
  fi

  echo -e "\n\e[36m📊 Summary: OK=$total_ok | FAIL=$total_fail | This round OK=$ok_count\e[0m"
}

# Header
echo -e "\n[+] DNSTT Keep-Alive v${VER} - Gateway & DNS Monitor"
echo -e "    🟢 \e[32mFAST (≤100ms)\e[0m   🟡 \e[33mMEDIUM (101–250ms)\e[0m   🔴 \e[31mSLOW (>250ms)\e[0m"

# Main loop
((LOOP_DELAY < 1)) && LOOP_DELAY=2
while true; do
  check_interface
  check_speed
  check_gateways     ## <<< Gateways now run BEFORE server checks
  check_servers
  echo -e "\n-------------------------------"
  sleep "$LOOP_DELAY"
done
