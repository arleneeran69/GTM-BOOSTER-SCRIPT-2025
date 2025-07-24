#!/data/data/com.termux/files/usr/bin/bash

# DNSTT Keep-Alive & DNS Monitor v2.3.1
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

touch "$DNS_FILE" "$NS_FILE" "$GW_FILE"

readarray -t DNS_LIST < "$DNS_FILE"
readarray -t NS_LIST < "$NS_FILE"
readarray -t GATEWAYS < "$GW_FILE"

case "$DIG_EXEC" in
  DEFAULT|D) _DIG=$(command -v dig) ;;
  CUSTOM|C) _DIG="$CUSTOM_DIG" ;;
  *) echo -e "${RED}[!] Invalid DIG_EXEC: $DIG_EXEC${NC}"; exit 1 ;;
esac

[ ! -x "$_DIG" ] && { echo -e "${RED}[!] dig not found: $_DIG${NC}"; exit 1; }

[[ "$(uname -m)" != "aarch64" && "$(uname -m)" != "x86_64" ]] && {
  echo -e "${RED}Unsupported architecture${NC}"; exit 1;
}
[ ! -d "/data/data/com.termux" ] && {
  echo -e "${RED}This script runs only in Termux!${NC}"; exit 1;
}

# ==== Ping Coloring ====
color_ping() {
  ms=$1
  if (( ms <= 100 )); then echo -e "${GREEN}${ms}ms FAST${NC}"
  elif (( ms <= 250 )); then echo -e "${YELLOW}${ms}ms MEDIUM${NC}"
  else echo -e "${RED}${ms}ms SLOW${NC}"; fi
}

# ==== Restart ====
restart_vpn() {
  echo -e "\n${YELLOW}[!] Restarting DNSTT Client...${NC}"
  pkill -f dnstt-client 2>/dev/null
  eval "$RESTART_CMD" &
  sleep 2
}

# ==== Interface ====
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

# ==== Gateway Ping ====
check_gateways() {
  echo -e "\n🌐 Gateway Ping:"
  best_gw=""; best_ping=9999
  for gw in "${GATEWAYS[@]}"; do
    [[ -z "$gw" ]] && continue
    out=$(ping -c1 -W2 "$gw" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      ms=$(echo "$out" | grep 'time=' | awk -F'time=' '{print int($2)}')
      echo -ne "  $gw — "; color_ping "$ms"
      (( ms < best_ping )) && best_ping=$ms && best_gw=$gw
    else
      echo -e "  $gw — ${RED}Unreachable${NC}"
    fi
  done
  [[ "$best_gw" ]] && echo -e "\n✅ Best Gateway: $best_gw — $(color_ping $best_ping)"
}

# ==== DNS-only IPs ====
check_dns_ips() {
  echo -e "\n📡 DNS IPs:"
  for dnsip in "${DNS_LIST[@]}"; do
    [[ -z "$dnsip" ]] && continue
    out=$(ping -c1 -W2 "$dnsip" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      ms=$(echo "$out" | grep 'time=' | awk -F'time=' '{print int($2)}')
      echo -ne "  $dnsip — "; color_ping "$ms"
    else
      echo -e "  $dnsip — ${RED}Ping FAIL${NC}"
    fi
  done
}

# ==== NS Server Check ====
check_servers() {
  echo -e "\n🔍 Checking NS Servers:"
  fail_count=0; best_ns=""; best_ping=9999

  for entry in "${NS_LIST[@]}"; do
    domain=$(echo "$entry" | awk '{print $1}')
    ip=$(echo "$entry" | awk '{print $2}')
    [[ -z "$domain" || -z "$ip" ]] && continue

    echo -e "[•] $domain @ $ip"
    ping_out=$(ping -c1 -W2 "$ip" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      ping_ms=$(echo "$ping_out" | grep 'time=' | awk -F'time=' '{print int($2)}')
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

# ==== Monitoring Loop ====
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
    check_dns_ips
    check_servers
    echo -e "\n${CYAN}Loop complete: Status updated. [$(date '+%H:%M:%S')]${NC}"
    echo -e "${CYAN}-------------------------------${NC}"
    sleep "$LOOP_DELAY"
  done
}

# ==== Menu ====
edit_dns_only() { echo -e "${YELLOW}Editing DNS IPs only...${NC}"; sleep 1; nano "$DNS_FILE"; exec bash "$0"; }
edit_ns_only() {
  echo -e "${YELLOW}Editing NS Servers (domain IP)...${NC}"
  echo "# Format: domain IP" > "$NS_FILE"
  echo "# Ex: example.com 1.1.1.1" >> "$NS_FILE"
  sleep 1; nano "$NS_FILE"; exec bash "$0"
}
edit_gateways_only() { echo -e "${YELLOW}Editing Gateway IPs...${NC}"; sleep 1; nano "$GW_FILE"; exec bash "$0"; }

clear
echo -e "${PINK}╔═══════════════════════════════╗"
echo -e "║       GTM Main Menu           ║"
echo -e "╚═══════════════════════════════╝${NC}"
echo -e "${WHITE}1) Edit DNS List (IPs Only)"
echo "2) Edit NS Servers (domain IP)"
echo "3) Edit Gateways (IPs Only)"
echo "4) Run Monitor Script"
echo -e "0) Exit ${NC}"
echo -ne "${PINK}Choose Option: ${NC}"; read choice

case "$choice" in
  1) edit_dns_only ;;
  2) edit_ns_only ;;
  3) edit_gateways_only ;;
  4) start_monitor ;;
  0) echo -e "${YELLOW}Goodbye! For Now 💕${NC}"; exit 0 ;;
  *) echo -e "${RED}Invalid option.${NC}"; exit 1 ;;
esac
