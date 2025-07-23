#!/data/data/com.termux/files/usr/bin/bash

## DNSTT Keep-Alive & DNS Monitor v2.3
## Author: GeoDevz69 | Cleaned by ChatGPT

VER="2.3"
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
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# === Editable Section ===
DNS_LIST=( "124.6.181.25" "124.6.181.26" "8.8.8.8" )
NS_LIST=(
  "dns1.example.com 124.6.181.25"
  "dns2.example.net 124.6.181.26"
)
GATEWAYS=( "1.1.1.1" "8.8.4.4" "9.9.9.9" )
# =========================

# Dig detection
case "$DIG_EXEC" in
  DEFAULT|D) _DIG=$(command -v dig) ;;
  CUSTOM|C) _DIG="${CUSTOM_DIG}" ;;
  *) echo "[!] Invalid DIG_EXEC: $DIG_EXEC"; exit 1 ;;
esac

[ ! -x "$_DIG" ] && echo "[!] dig not found or not executable: $_DIG" && exit 1

# Validate Termux & Arch
arch=$(uname -m)
[[ "$arch" != "aarch64" && "$arch" != "x86_64" ]] && {
  echo -e "${RED}Unsupported architecture: $arch${NC}"
  echo -e "${YELLOW}Use Termux version for: aarch64 or x86_64${NC}"
  exit 1
}
[ ! -d "/data/data/com.termux" ] && {
  echo -e "${RED}This script runs only in Termux!${NC}"
  exit 1
}

# Editors
edit_dns_only() {
  echo -e "${YELLOW}Editing DNS List... (Only IPs like 124.6.181.25)${NC}"
  sleep 1; nano "$0"; echo -e "${YELLOW}Restarting script...${NC}"; sleep 1; bash "$0"; exit
}

edit_ns_only() {
  echo -e "${YELLOW}Editing NS List... (domain IP format only)${NC}"
  sleep 1; nano "$0"; echo -e "${YELLOW}Restarting script...${NC}"; sleep 1; bash "$0"; exit
}

edit_gateways_only() {
  echo -e "${YELLOW}Editing Gateway List... (Only IPs)${NC}"
  sleep 1; nano "$0"; echo -e "${YELLOW}Restarting script...${NC}"; sleep 1; bash "$0"; exit
}

# Display ping quality
color_ping() {
  ms=$1
  if (( ms <= 100 )); then echo -e "${GREEN}${ms}ms FAST${NC}"
  elif (( ms <= 250 )); then echo -e "${YELLOW}${ms}ms MEDIUM${NC}"
  else echo -e "${RED}${ms}ms SLOW${NC}"; fi
}

restart_vpn() {
  echo -e "\n${YELLOW}[!] Restarting DNSTT Client...${NC}"
  pkill -f dnstt-client 2>/dev/null
  eval "$RESTART_CMD" &
  sleep 2
}

check_interface() {
  ip link show "$VPN_INTERFACE" &>/dev/null \
    && echo -e "[✓] $VPN_INTERFACE is UP" \
    || { echo -e "[✗] $VPN_INTERFACE is DOWN"; restart_vpn; return 1; }
}

check_speed() {
  stats=$(ip -s link show "$VPN_INTERFACE" 2>/dev/null | grep -A1 'RX:' | tail -n1)
  RX=$(echo "$stats" | awk '{print $1}')
  TX=$(echo "$stats" | awk '{print $9}')
  [[ "$RX" == "0" && "$TX" == "0" ]] \
    && echo -e "⚠️  RX/TX = 0 on $VPN_INTERFACE" \
    || echo -e "🔄 RX=${RX}B | TX=${TX}B"
}

check_gateways() {
  echo -e "\n🌐 Gateway Ping:"
  best_gw=""; best_ping=9999
  for gw in "${GATEWAYS[@]}"; do
    out=$(ping -c1 -W2 "$gw" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      ms=$(echo "$out" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}')
      echo -ne "  $gw — "; color_ping "$ms"
      (( ms < best_ping )) && best_ping=$ms && best_gw=$gw
    else
      echo -e "  $gw — ${RED}Unreachable${NC}"
    fi
  done
  [[ "$best_gw" ]] \
    && echo -e "\n✅ Best Gateway: $best_gw — $(color_ping $best_ping)" \
    || echo -e "\n⚠️  No reachable gateways."
}

check_servers() {
  fail_count=0
  for entry in "${NS_LIST[@]}"; do
    domain=$(echo "$entry" | awk '{print $1}')
    ip=$(echo "$entry" | awk '{print $2}')
    echo -e "\n[•] $domain @ $ip"

    ping_out=$(ping -c1 -W2 "$ip" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      ping_ms=$(echo "$ping_out" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}')
      echo -ne "    ✓ Ping OK — "; color_ping "$ping_ms"
    else
      echo -e "    ✗ Ping FAIL"
      ((fail_count++)); continue
    fi

    timeout -k 3 3 "$_DIG" @"$ip" "$domain" &>/dev/null \
      && echo -e "    ✓ DNS Query OK" \
      || { echo -e "    ✗ DNS Query FAIL"; ((fail_count++)); }
  done

  (( fail_count >= FAIL_LIMIT )) && restart_vpn
}

start_monitor() {
  clear
  echo -e "${CYAN}╔════════════════════════════════════╗"
  echo -e "║      DNSTT Keep-Alive Monitor v$VER     ║"
  echo -e "╚════════════════════════════════════╝${NC}"
  echo -e "${WHITE}🟢 FAST ≤100ms   🟡 MEDIUM ≤250ms   🔴 SLOW >250ms${NC}"
  echo -e "${YELLOW}Monitoring started. CTRL+C to stop.${NC}"
  while true; do
    check_interface
    check_speed
    check_gateways
    check_servers
    echo -e "\n-------------------------------"
    sleep "$LOOP_DELAY"
  done
}

# ===== Main Menu =====
clear
echo -e "${CYAN}╔═══════════════════════════════╗"
echo -e "║       DNSTT Utility Menu       ║"
echo -e "╚═══════════════════════════════╝${NC}"
echo -e "${WHITE}1) Edit DNS List (Only DNS IPs)"
echo "2) Edit NS Servers (domain + IP)"
echo "3) Edit Gateways (Only Gateway IPs)"
echo "4) Start DNSTT Monitor"
echo "0) Exit${NC}"
echo -n "Choose Option: "; read choice

case "$choice" in
  1) edit_dns_only ;;
  2) edit_ns_only ;;
  3) edit_gateways_only ;;
  4) start_monitor ;;
  0) echo -e "${YELLOW}Bye.${NC}"; exit 0 ;;
  *) echo -e "${RED}Invalid option.${NC}"; exit 1 ;;
esac
