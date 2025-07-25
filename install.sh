#!/data/data/com.termux/files/usr/bin/bash

# GTM | DNSTT Keep-Alive & DNS Monitor v2.3.5 - Fixed & Enhanced
# Author: GeoDevz69 💕

VER="2.3.5"
LOOP_DELAY=5
FAIL_LIMIT=5
DIG_EXEC="CUSTOM"
CUSTOM_DIG="/data/data/com.termux/files/home/go/bin/fastdig"
VPN_INTERFACE="tun0"
RESTART_CMD="bash /data/data/com.termux/files/home/dnstt/start-client.sh"

# ===== Colors =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
PINK='\033[1;35m'
NC='\033[0m'

# ===== Config Files =====
DNS_FILE="$HOME/.dns_list.txt"
NS_FILE="$HOME/.ns_list.txt"
GW_FILE="$HOME/.gateway_list.txt"

touch "$DNS_FILE" "$NS_FILE" "$GW_FILE"
readarray -t DNS_LIST < "$DNS_FILE"
readarray -t NS_LIST < "$NS_FILE"
readarray -t GATEWAYS < "$GW_FILE"

# ===== Check dig =====
case "$DIG_EXEC" in
  DEFAULT|D) _DIG=$(command -v dig) ;;
  CUSTOM|C) _DIG="$CUSTOM_DIG" ;;
  *) echo -e "${RED}[!] Invalid DIG_EXEC: $DIG_EXEC${NC}"; exit 1 ;;
esac
[ ! -x "$_DIG" ] && { echo -e "${RED}[!] dig not found at: $_DIG${NC}"; exit 1; }

# ===== Architecture Check =====
arch=$(uname -m)
[[ "$arch" != "aarch64" && "$arch" != "x86_64" ]] && {
  echo -e "${RED}Unsupported architecture: $arch${NC}"
  echo -e "${YELLOW}Use Termux for: aarch64 or x86_64${NC}"
  exit 1
}
[ ! -d "/data/data/com.termux" ] && {
  echo -e "${RED}This script runs only in Termux!${NC}"
  exit 1
}

# ===== Edit Menus =====
edit_dns_only() {
  echo -e "${YELLOW}Edit DNS IPs (one per line)...${NC}"
  sleep 1; nano "$DNS_FILE"; exec bash "$0"
}
edit_ns_only() {
  echo -e "${YELLOW}Edit NS Servers (format: domain IP)...${NC}"
  sleep 1; nano "$NS_FILE"; exec bash "$0"
}
edit_gateways_only() {
  echo -e "${YELLOW}Edit Gateway IPs or hosts...${NC}"
  sleep 1; nano "$GW_FILE"; exec bash "$0"
}

# ===== Utilities =====
color_ping() {
  ms=$1
  if (( ms <= 100 )); then echo -e "${GREEN}${ms}ms - FAST 🟢${NC}"
  elif (( ms <= 250 )); then echo -e "${YELLOW}${ms}ms - MEDIUM 🟡${NC}"
  else echo -e "${RED}${ms}ms - SLOW 🔴${NC}"; fi
}

restart_vpn() {
  echo -e "${YELLOW}[!] Restarting DNSTT Client...${NC}"
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
      ms=$(echo "$out" | grep 'time=' | awk -F'time=' '{print int($2)}')
      echo -ne "  $gw — "; color_ping "$ms"
      (( ms < best_ping )) && best_ping=$ms && best_gw=$gw
    else
      echo -e "  $gw — ${RED}Unreachable${NC}"
    fi
  done
  [[ "$best_gw" ]] && echo -e "\n✅ Best Gateway Fit: $best_gw — $(color_ping $best_ping)"
}

check_servers() {
  echo -e "\n🔍 NS Server Check:"
  fail_count=0; best_ns=""; best_ping=9999
  for entry in "${NS_LIST[@]}"; do
    domain=$(echo "$entry" | awk '{print $1}')
    ip=$(echo "$entry" | awk '{print $2}')
    [[ -z "$domain" || -z "$ip" ]] && continue
    echo -e "\nDomain: ${CYAN}$domain${NC}"  
    echo -e "DNS IP: ${WHITE}$ip${NC}"  
    ping_out=$(ping -c1 -W2 "$ip" 2>/dev/null)  
    if [[ $? -eq 0 ]]; then  
      ping_ms=$(echo "$ping_out" | grep 'time=' | awk -F'time=' '{print int($2)}')  
      echo -ne "Status: "; color_ping "$ping_ms"  
      (( ping_ms < best_ping )) && best_ping=$ping_ms && best_ns="$domain @ $ip"  
    else  
      echo -e "Status: ${RED}Unreachable${NC}"  
      ((fail_count++)); continue  
    fi  
    timeout -k 3 3 "$_DIG" @"$ip" "$domain" &>/dev/null  
    [[ $? -eq 0 ]] && echo -e "${GREEN}✓ DNS Query OK${NC}" || echo -e "${RED}✗ DNS Query FAIL${NC}"
  done
  [[ "$best_ns" ]] && echo -e "\n🌟 ${GREEN}Fastest NS: $best_ns [$best_ping ms]${NC}"
  (( fail_count >= FAIL_LIMIT )) && restart_vpn
}

auto_ping_dns_list() {
  echo -e "\n${CYAN}📡 Auto-Ping Test: DNS IPs${NC}"
  best_dns=""; best_ping=9999
  for dns in "${DNS_LIST[@]}"; do
    [[ -z "$dns" ]] && continue
    out=$(ping -c1 -W2 "$dns" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      ms=$(echo "$out" | grep 'time=' | awk -F'time=' '{print int($2)}')
      echo -ne "  $dns — "; color_ping "$ms"
      (( ms < best_ping )) && best_ping=$ms && best_dns=$dns
    else
      echo -e "  $dns — ${RED}Unreachable${NC}"
    fi
  done
  [[ "$best_dns" ]] && echo -e "\n✅ Best DNS: $best_dns — $(color_ping $best_ping)"
  echo -e "\n${YELLOW}Done. Returning to menu...${NC}"; sleep 2
  exec bash "$0"
}

reset_list_menu() {
  clear
  echo -e "${YELLOW}Choose list to clear:${NC}"
  echo -e "${WHITE}1) DNS IPs\n2) NS Servers\n3) Gateway IPs\n4) ALL\n0) Cancel${NC}"
  echo -ne "${PINK}Your Choice: ${NC}"; read reset_choice
  case "$reset_choice" in
    1) > "$DNS_FILE"; echo -e "${GREEN}DNS list cleared.${NC}" ;;
    2) > "$NS_FILE"; echo -e "${GREEN}NS list cleared.${NC}" ;;
    3) > "$GW_FILE"; echo -e "${GREEN}Gateway list cleared.${NC}" ;;
    4) > "$DNS_FILE"; > "$NS_FILE"; > "$GW_FILE"; echo -e "${GREEN}All lists cleared.${NC}" ;;
    0) exec bash "$0" ;;
    *) echo -e "${RED}Invalid option.${NC}" ;;
  esac
  sleep 1; exec bash "$0"
}

start_monitor() {
  clear
  echo -e "${PINK}╔════════════════════════════════════╗"
  echo -e "     GTM | BOOSTER v$VER"
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
echo -e "       GTM SCRIPT MENU          "
echo -e "╚═══════════════════════════════╝${NC}"
echo -e "${WHITE}1) Edit DNS IP List"
echo "2) Edit NS Servers (domain + IP)"
echo "3) Edit Gateway List"
echo "4) Start Monitor"
echo "5) Auto-Ping DNS List"
echo "6) Reset / Clear Lists"
echo -e "0) Exit${NC}"
echo -ne "${PINK}Choose Option: ${NC}"; read choice

case "$choice" in
  1) edit_dns_only ;;
  2) edit_ns_only ;;
  3) edit_gateways_only ;;
  4) start_monitor ;;
  5) auto_ping_dns_list ;;
  6) reset_list_menu ;;
  0) echo -e "${YELLOW}Thanks for using GTM BOOSTER 💕${NC}"; exit 0 ;;
  *) echo -e "${RED}Invalid option.${NC}" ;;
esac
