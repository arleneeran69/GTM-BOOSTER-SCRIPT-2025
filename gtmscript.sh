#!/data/data/com.termux/files/usr/bin/bash

## DNSTT Keep-Alive & DNS Monitor v2.3
## Author: GeoDevz69 | Enhanced by GeoDevz69
## Now with Editable Menu System

VER="2.3"
LOOP_DELAY=5
FAIL_LIMIT=5
DIG_EXEC="DEFAULT"
CUSTOM_DIG="/data/data/com.termux/files/home/go/bin/fastdig"
VPN_INTERFACE="tun0"
RESTART_CMD="bash /data/data/com.termux/files/home/dnstt/start-client.sh"
CONFIG_DIR="$HOME/.config/dnstt-monitor"
SERVER_FILE="$CONFIG_DIR/servers.lst"
GATEWAY_FILE="$CONFIG_DIR/gateways.lst"

mkdir -p "$CONFIG_DIR"

# Load default values if not present
if [ ! -f "$SERVER_FILE" ]; then
cat > "$SERVER_FILE" <<EOF
ns.jkrol.fiber-x.shop 124.6.181.167
ns.jkrol.fiber-x.shop 124.6.181.31
vpn.kagerou.site 124.6.181.248
EOF
fi

if [ ! -f "$GATEWAY_FILE" ]; then
echo -e "1.1.1.1\n8.8.8.8\n8.8.4.4\n9.9.9.9" > "$GATEWAY_FILE"
fi

# Load servers and gateways
mapfile -t SERVERS < "$SERVER_FILE"
mapfile -t GATEWAYS < "$GATEWAY_FILE"

fail_count=0
total_ok=0
total_fail=0

# Determine dig executable
case "${DIG_EXEC}" in
  DEFAULT|D) _DIG=$(command -v dig) ;;
  CUSTOM|C) _DIG="${CUSTOM_DIG}" ;;
  *) echo "[!] Invalid DIG_EXEC: $DIG_EXEC"; exit 1 ;;
esac
[ ! -x "$_DIG" ] && echo "[!] dig not executable: $_DIG" && exit 1
trap 'echo -e "\n[+] Exiting..."; exit 0' SIGINT SIGTERM

# Color-coded ping display
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

# VPN Interface checker
check_interface() {
  if ip link show "$VPN_INTERFACE" > /dev/null 2>&1; then
    echo -e "\n[✓] $VPN_INTERFACE is UP"
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
    echo -e "    ⚠️  \e[33mRX/TX = 0 on $VPN_INTERFACE\e[0m"
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
    echo -e "\n✅ Best Gateway: \e[1;36m$best_gw — $(color_ping $best_ping)\e[0m"
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
      echo -ne "    ✓ Ping OK — "
      color_ping "$ping_ms"
    else
      echo -e "    ✗ Ping FAIL"
      ((fail_count++)); ((total_fail++))
      continue
    fi

    if timeout -k 3 3 "$_DIG" @"$ip" "$domain" > /dev/null 2>&1; then
      echo -e "    ✓ DNS Query OK"
      ((ok_count++)); ((total_ok++))
    else
      echo -e "    ✗ DNS Query FAIL"
      ((fail_count++)); ((total_fail++))
    fi
  done

  if (( fail_count >= FAIL_LIMIT )); then
    echo -e "\n[!] Too many failures ($fail_count) — restarting tunnel"
    fail_count=0
    restart_vpn
  fi

  echo -e "\n📊 Summary: OK=$total_ok | FAIL=$total_fail | This Round=$ok_count"
}

edit_menu() {
  echo -e "\n🛠️  EDIT MODE"
  echo "1) View/Edit NS Servers"
  echo "2) View/Edit DNS Gateways"
  echo "3) Back to Monitor"
  echo -n "Choose: "
  read -r choice
  case "$choice" in
    1)
      echo -e "\nCurrent NS List:"
      cat -n "$SERVER_FILE"
      echo -e "\nEdit this file manually? (y/n): "
      read -r ans
      [[ "$ans" == "y" ]] && nano "$SERVER_FILE"
      mapfile -t SERVERS < "$SERVER_FILE"
      ;;
    2)
      echo -e "\nCurrent Gateways:"
      cat -n "$GATEWAY_FILE"
      echo -e "\nEdit this file manually? (y/n): "
      read -r ans
      [[ "$ans" == "y" ]] && nano "$GATEWAY_FILE"
      mapfile -t GATEWAYS < "$GATEWAY_FILE"
      ;;
    *)
      echo "Returning to monitor..."
      ;;
  esac
}

### Menu or Start Immediately
if [[ "$1" == "--edit" ]]; then
  edit_menu
fi

# Header
echo -e "\n[+] DNSTT Keep-Alive v${VER} - Gateway & DNS Monitor"
echo -e "    🟢 \e[32mFAST (≤100ms)\e[0m   🟡 \e[33mMEDIUM (101–250ms)\e[0m   🔴 \e[31mSLOW (>250ms)\e[0m"

# Main loop
((LOOP_DELAY < 1)) && LOOP_DELAY=2
while true; do
  check_interface
  check_speed
  check_gateways
  check_servers
  echo -e "\n-------------------------------"
  sleep "$LOOP_DELAY"
done
