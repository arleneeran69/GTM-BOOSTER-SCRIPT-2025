#!/data/data/com.termux/files/usr/bin/bash

## DNSTT Keep-Alive & DNS Monitor v2.2-Enhanced
## Author: GeoDevz69 | Modified by ChatGPT (Installer + Loader + Arch Check)

VER="2.2"
LOOP_DELAY=5
FAIL_LIMIT=5
DIG_EXEC="DEFAULT"
CUSTOM_DIG="/data/data/com.termux/files/home/go/bin/fastdig"
VPN_INTERFACE="tun0"
RESTART_CMD="bash /data/data/com.termux/files/home/dnstt/start-client.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Detect architecture
get_arch() {
    case "$(uname -m)" in
        aarch64) echo "aarch64" ;;
        x86_64) echo "x86_64" ;;
        armv7l|armv8l|arm) echo "arm" ;;
        i*86) echo "i686" ;;
        *) echo "unknown" ;;
    esac
}

# Check Termux and architecture
ARCH_TYPE="$(get_arch)"
if [[ "$ARCH_TYPE" != "aarch64" && "$ARCH_TYPE" != "x86_64" ]]; then
    echo -e "${RED}Unsupported architecture: $ARCH_TYPE${NC}"
    echo -e "${YELLOW}Please use Termux version for: aarch64 or x86_64${NC}"
    exit 1
fi

if [ ! -d "/data/data/com.termux" ]; then
    echo -e "${RED}This script runs only in Termux!${NC}"
    exit 1
fi

# Animated loading bar
show_loading_bar() {
    echo -e "${WHITE}Launching DNSTT Keep-Alive Script...${NC}"
    local progress=0
    local width=30
    while [ $progress -le 100 ]; do
        bar="["
        filled=$((progress * width / 100))
        for ((i=0; i<filled; i++)); do bar+="■"; done
        for ((i=filled; i<width; i++)); do bar+=" "; done
        bar+="]"
        printf "\r%s %3d%%" "$bar" "$progress"
        sleep 0.1
        progress=$((progress + 10))
    done
    echo -e "\n"
}

# DNS Tunnel Servers
SERVERS=( ... )  # << Omitted here for brevity. Use your existing SERVERS block.

# Public Gateways
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
  if [[ $ms -le 100 ]]; then echo -e "\e[32m${ms}ms FAST\e[0m"
  elif [[ $ms -le 250 ]]; then echo -e "\e[33m${ms}ms MEDIUM\e[0m"
  else echo -e "\e[31m${ms}ms SLOW\e[0m"; fi
}

check_interface() {
  ip link show "$VPN_INTERFACE" > /dev/null 2>&1 \
    && echo -e "\n[✓] $VPN_INTERFACE is UP" \
    || { echo -e "\n[✗] $VPN_INTERFACE is DOWN"; restart_vpn; return 1; }
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
  [[ "$RX" == "0" && "$TX" == "0" ]] \
    && echo -e "    \e[33m⚠️  RX/TX = 0 on $VPN_INTERFACE\e[0m" \
    || echo -e "    🔄 RX=${RX}B | TX=${TX}B"
}

check_gateways() {
  echo -e "\n🌐 Checking Gateway DNS Response Times:"
  best_gw=""
  best_ping=9999
  for gw in "${GATEWAYS[@]}"; do
    out=$(ping -c1 -W2 "$gw" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      ms=$(echo "$out" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}')
      echo -ne "    $gw — "; color_ping "$ms"
      [[ $ms -lt $best_ping ]] && best_ping=$ms && best_gw=$gw
    else
      echo -e "    $gw — \e[31mUnreachable\e[0m"
    fi
  done
  [[ -n "$best_gw" ]] \
    && echo -e "\n✅ Best Gateway (Airplane Mode): \e[1;36m$best_gw — $(color_ping $best_ping)\e[0m" \
    || echo -e "\n⚠️  No reachable gateways detected."
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
      echo -ne "    \e[32m✓ Ping OK\e[0m — "; color_ping "$ping_ms"
    else
      echo -e "    \e[31m✗ Ping FAIL\e[0m"
      ((fail_count++)); ((total_fail++)); continue
    fi

    timeout -k 3 3 "$_DIG" @"$ip" "$domain" > /dev/null 2>&1 \
      && { echo -e "    \e[32m✓ DNS Query OK\e[0m"; ((ok_count++)); ((total_ok++)); } \
      || { echo -e "    \e[31m✗ DNS Query FAIL\e[0m"; ((fail_count++)); ((total_fail++)); }
  done

  if (( fail_count >= FAIL_LIMIT )); then
    echo -e "\n\e[31m[!] Too many failures ($fail_count) — restarting tunnel\e[0m"
    fail_count=0
    restart_vpn
  fi

  echo -e "\n\e[36m📊 Summary: OK=$total_ok | FAIL=$total_fail | This round OK=$ok_count\e[0m"
}

# -- Begin Execution --
clear
echo -e "${CYAN}╔═════════════════════════════════════╗"
echo -e "${CYAN}║  DNSTT Keep-Alive Monitor v$VER     ║"
echo -e "${CYAN}╚═════════════════════════════════════╝${NC}"
show_loading_bar
echo -e "${WHITE}    🟢 \e[32mFAST (≤100ms)\e[0m   🟡 \e[33mMEDIUM (101–250ms)\e[0m   🔴 \e[31mSLOW (>250ms)\e[0m${NC}"
echo -e "${YELLOW}Starting Monitor... Press CTRL+C to stop.${NC}"
sleep 2

((LOOP_DELAY < 1)) && LOOP_DELAY=2
while true; do
  check_interface
  check_speed
  check_gateways
  check_servers
  echo -e "\n-------------------------------"
  sleep "$LOOP_DELAY"
done
