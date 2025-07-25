#!/data/data/com.termux/files/usr/bin/bash

# DNSTT Keep-Alive & DNS Monitor v2.3.1 - Domain Only NS Edition
# Author: GeoDevz69 💕

VER="2.3.1"
LOOP_DELAY=5
FAIL_LIMIT=5
DIG_EXEC="CUSTOM"
CUSTOM_DIG="/data/data/com.termux/files/home/go/bin/fastdig"
VPN_INTERFACE="tun0"
RESTART_CMD="bash /data/data/com.termux/files/home/dnstt/start-client.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
PINK='\033[1;35m'
NC='\033[0m'

# Config files
DNS_FILE="$HOME/.dns_list.txt"
NS_FILE="$HOME/.ns_list.txt"
GW_FILE="$HOME/.gateway_list.txt"

# Create empty files if missing
touch "$DNS_FILE" "$NS_FILE" "$GW_FILE"

# Load data
readarray -t DNS_LIST < "$DNS_FILE"
readarray -t NS_LIST < "$NS_FILE"
readarray -t GATEWAYS < "$GW_FILE"

# Choose dig binary with fallback
if [[ "$DIG_EXEC" == "CUSTOM" || "$DIG_EXEC" == "C" ]]; then
  if [[ -x "$CUSTOM_DIG" ]]; then
    _DIG="$CUSTOM_DIG"
  else
    echo -e "${YELLOW}[!] fastdig not found or not executable. Falling back to system dig.${NC}"
    _DIG=$(command -v dig)
    [[ -z "$_DIG" ]] && echo -e "${RED}[!] No dig binary available. Exiting.${NC}" && exit 1
  fi
else
  _DIG=$(command -v dig)
  [[ -z "$_DIG" ]] && echo -e "${RED}[!] No dig binary available. Exiting.${NC}" && exit 1
fi

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

# ===== Editor Functions =====
edit_dns_only() {
  echo -e "${YELLOW}Edit DNS IPs only (1 per line)...${NC}"
  sleep 1; nano "$DNS_FILE"; exec bash "$0"
}

edit_ns_only() {
  echo -e "${YELLOW}Edit NS Domains only (1 per line)...${NC}"
  > "$NS_FILE"
  sleep 1; nano "$NS_FILE"; exec bash "$0"
}

edit_gateways_only() {
  echo -e "${YELLOW}Edit Gateway IPs only (1 per line)...${NC}"
  sleep 1; nano "$GW_FILE"; exec bash "$0"
}

# ===== Utility =====
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
  if ip link show "$VPN_INTERFACE" &>/dev/null; then
    echo -e "✅ ${GREEN}$VPN_INTERFACE is UP${NC}"
  else
    echo -e "❌ ${RED}$VPN_INTERFACE is DOWN${NC}"
    restart_vpn
  fi
}

check_speed() {
  stats=$(ip -s link show "$VPN_INTERFACE" 2>/dev/null | grep -A1 'RX:' | tail -n1)
  RX=$(echo "$stats" | awk '{print $1}')
  TX=$(echo "$stats" | awk '{print $9}')
  echo -e "📶 RX=${RX}B | TX=${TX}B"
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
  [[ "$best_gw" ]] && echo -e "\n✅ Best Gateway: $best_gw — $(color_ping $best_ping)"
}

check_servers() {
  echo -e "\n🔍 Checking NS Domains:"
  fail_count=0; best_ns=""; best_ping=9999

  for domain in "${NS_LIST[@]}"; do
    [[ -z "$domain" ]] && continue
    echo -e "\n[•] $domain"

    best_this=9999; found=0
    for dns_ip in "${DNS_LIST[@]}"; do
      ping_out=$(ping -c1 -W2 "$dns_ip" 2>/dev/null)
      if [[ $? -eq 0 ]]; then
        ping_ms=$(echo "$ping_out" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}')
        echo -ne "    ↳ $dns_ip — "; color_ping "$ping_ms"
        (( ping_ms < best_this )) && best_this=$ping_ms && best_ns="$domain via $dns_ip"
        found=1
      else
        echo -e "    ↳ $dns_ip — ${RED}Unreachable${NC}"
      fi

      # Force TCP in dig query for better compatibility
      timeout -k 3 3 "$_DIG" +tcp @"$dns_ip" "$domain" &>/dev/null
      if [[ $? -eq 0 ]]; then
        echo -e "       ${GREEN}✓ DNS Query OK${NC}"
      else
        echo -e "       ${RED}✗ DNS Query FAIL${NC}"; ((fail_count++))
      fi
    done

    (( found == 0 )) && echo -e "    ${RED}✗ All DNS Unreachable for $domain${NC}"
    (( best_this < best_ping )) && best_ping=$best_this
  done

  [[ "$best_ns" ]] && echo -e "\n🌟 ${GREEN}Fastest NS: $best_ns [$best_ping ms]${NC}"
  (( fail_count >= FAIL_LIMIT )) && restart_vpn
}

start_monitor() {
  clear
  echo -e "${PINK}╔════════════════════════════════════╗"
  echo -e "║     GBooster Tool v$VER            ║"
  echo -e "╚════════════════════════════════════╝${NC}"
  echo -e "${WHITE}🟢 FAST ≤100ms   🟡 MEDIUM ≤250ms   🔴 SLOW >250ms${NC}"
  echo -e "${YELLOW}Monitoring started. CTRL+C to stop.${NC}"
  while true; do
    check_interface
    check_speed
    check_gateways
    check_servers
    echo -e "\n${CYAN}-------------------------------${NC}"
    sleep "$LOOP_DELAY"
  done
}

# ===== Main Menu =====
clear
echo -e "${PINK}╔═══════════════════════════════╗"
echo -e "║         GTM Main Menu         ║"
echo -e "╚═══════════════════════════════╝${NC}"
echo -e "${WHITE}1) Edit DNS List (IPs Only)"
echo "2) Edit NS Domains (1 per line)"
echo "3) Edit Gateways (IPs Only)"
echo "4) Run Script"
echo -e "0) Exit Script ${NC}"
echo -ne "${PINK}Choose Option: ${NC}"; read choice

case "$choice" in
  1) edit_dns_only ;;
  2) edit_ns_only ;;
  3) edit_gateways_only ;;
  4) start_monitor ;;
  0) echo -e "${YELLOW}Thanks For Using this Script 💕.${NC}"; exit 0 ;;
  *) echo -e "${RED}Invalid option.${NC}"; exit 1 ;;
esac
