#!/data/data/com.termux/files/usr/bin/bash

# DNSTT Keep-Alive & DNS Monitor v2.4 - Separated Menu Input
# Author: GeoDevz69 💕

VER="2.4"
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

# Ensure files exist
touch "$DNS_FILE" "$NS_FILE" "$GW_FILE"

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
  readarray -t GATEWAYS < "$GW_FILE"
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
  echo -e "\n🔍 Checking NS Servers:"
  readarray -t NS_LIST < "$NS_FILE"
  fail_count=0; best_ns=""; best_ping=9999

  for entry in "${NS_LIST[@]}"; do
    domain=$(echo "$entry" | awk '{print $1}')
    ip=$(echo "$entry" | awk '{print $2}')
    [[ -z "$domain" || -z "$ip" ]] && continue

    echo -e "\n[•] $domain @ $ip"

    ping_out=$(ping -c1 -W2 "$ip" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      ping_ms=$(echo "$ping_out" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}')
      echo -ne "    ✓ Ping OK — "; color_ping "$ping_ms"
      (( ping_ms < best_ping )) && best_ping=$ping_ms && best_ns="$domain @ $ip"
    else
      echo -e "    ✗ ${RED}Ping FAIL${NC}"; ((fail_count++)); continue
    fi

    timeout -k 3 3 "$_DIG" @"$ip" "$domain" &>/dev/null
    if [[ $? -eq 0 ]]; then
      echo -e "    ${GREEN}✓ DNS Query OK${NC}"
    else
      echo -e "    ${RED}✗ DNS Query FAIL${NC}"; ((fail_count++))
    fi
  done

  [[ "$best_ns" ]] && echo -e "\n🌟 ${GREEN}Fastest NS: $best_ns [$best_ping ms]${NC}"
  (( fail_count >= FAIL_LIMIT )) && restart_vpn
}

# ===== Editor Functions =====
edit_ns_entries() {
  echo -e "${YELLOW}Edit NS (format: domain IP)...${NC}"
  echo -e "# Format: domain IP\n# Example: gtm.codered-api.shop 124.6.181.25" > "$NS_FILE"
  sleep 1; nano "$NS_FILE"
}

edit_dns_only() {
  echo -e "${YELLOW}Edit DNS IPs only (1 per line)...${NC}"
  sleep 1; nano "$DNS_FILE"
}

edit_gateways_only() {
  echo -e "${YELLOW}Edit Gateway IPs only (1 per line)...${NC}"
  sleep 1; nano "$GW_FILE"
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
while true; do
  clear
  echo -e "${PINK}╔════════════════════════════════════╗"
  echo -e "║         GTM Booster Menu          ║"
  echo -e "╚════════════════════════════════════╝${NC}"
  echo -e "${WHITE}1) Edit NS (domain IP only)"
  echo "2) Edit DNS IPs only"
  echo "3) Edit Gateways only"
  echo "4) Start DNSTT Monitor"
  echo -e "0) Exit Script${NC}"
  echo -ne "${PINK}Choose Option: ${NC}"; read choice

  case "$choice" in
    1) edit_ns_entries ;;
    2) edit_dns_only ;;
    3) edit_gateways_only ;;
    4) start_monitor ;;
    0) echo -e "${YELLOW}Thank you for using this script 💕${NC}"; exit 0 ;;
    *) echo -e "${RED}Invalid option. Try again.${NC}"; sleep 1 ;;
  esac
done
