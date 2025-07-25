#!/data/data/com.termux/files/usr/bin/bash

# DNSTT Keep-Alive & DNS Monitor v2.3.7
# Author: GeoDevz69 💕 (Enhanced by ChatGPT)

VER="2.3.7"
LOOP_DELAY=5
FAIL_LIMIT=5
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

load_data() {
  readarray -t DNS_LIST < "$DNS_FILE"
  readarray -t NS_LIST < "$NS_FILE"
  readarray -t GATEWAYS < "$GW_FILE"
}

_DIG=$(command -v dig)
[ ! -x "$_DIG" ] && { echo -e "${RED}[!] dig not found.${NC}"; exit 1; }

arch=$(uname -m)
[[ "$arch" != "aarch64" && "$arch" != "x86_64" ]] && {
  echo -e "${RED}Unsupported arch: $arch${NC}"; exit 1;
}

[ ! -d "/data/data/com.termux" ] && {
  echo -e "${RED}Only runs in Termux!${NC}"; exit 1;
}

edit_dns_only() { echo -e "${YELLOW}Edit DNS IPs only...${NC}"; sleep 1; nano "$DNS_FILE"; }
edit_ns_only()  { echo -e "${YELLOW}Edit NS entries (domain IP)...${NC}"; sleep 1; nano "$NS_FILE"; }
edit_gateways_only() { echo -e "${YELLOW}Edit Gateway IPs only...${NC}"; sleep 1; nano "$GW_FILE"; }

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
  ip link show "$VPN_INTERFACE" &>/dev/null && \
    echo -e "✅ ${GREEN}$VPN_INTERFACE is UP${NC}" || {
    echo -e "❌ ${RED}$VPN_INTERFACE is DOWN${NC}"; restart_vpn;
  }
}

check_speed() {
  stats=$(ip -s link show "$VPN_INTERFACE" | grep -A1 'RX:' | tail -n1)
  RX=$(echo "$stats" | awk '{print $1}')
  TX=$(echo "$stats" | awk '{print $9}')
  echo -e "📶 RX=${RX}B | TX=${TX}B"
}

get_best_gateway() {
  best_gw=""; best_ping=9999
  for gw in "${GATEWAYS[@]}"; do
    out=$(ping -c1 -W2 "$gw" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      ms=$(echo "$out" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}')
      (( ms < best_ping )) && best_ping=$ms && best_gw=$gw
    fi
  done
  echo "$best_gw"
}

get_best_dns() {
  best_dns=""; best_ping=9999
  for dns in "${DNS_LIST[@]}"; do
    out=$(ping -c1 -W2 "$dns" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      ms=$(echo "$out" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}')
      (( ms < best_ping )) && best_ping=$ms && best_dns=$dns
    fi
  done
  echo "$best_dns"
}

check_servers() {
  echo -e "\n🔍 Checking NS Servers:"
  fail_count=0

  best_gateway=$(get_best_gateway)
  best_dns=$(get_best_dns)

  for entry in "${NS_LIST[@]}"; do
    domain=$(echo "$entry" | awk '{print $1}')
    ip=$(echo "$entry" | awk '{print $2}')
    [[ -z "$domain" || -z "$ip" ]] && continue

    ping_out=$(ping -c1 -W2 "$ip" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      ping_ms=$(echo "$ping_out" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}')
      latency_status=$(color_ping "$ping_ms")
    else
      ping_ms="Unreachable"
      latency_status="${RED}✗ Ping FAIL${NC}"
      ((fail_count++))
    fi

    query_status=""
    timeout -k 3 3 "$_DIG" @"$ip" "$domain" &>/dev/null
    [[ $? -eq 0 ]] && query_status="${GREEN}✓ Query OK${NC}" || {
      query_status="${RED}✗ Query FAIL${NC}"
      ((fail_count++))
    }

    echo -e "\n${CYAN}NS Domain:${NC} $domain"
    echo -e "${CYAN}Recommended DNS:${NC} $best_dns"
    echo -e "${CYAN}Recommended Gateway:${NC} $best_gateway"
    echo -e "${CYAN}Status Ping:${NC} $latency_status"
    echo -e "        $query_status"
  done

  (( fail_count >= FAIL_LIMIT )) && restart_vpn
}

check_gateways() {
  echo -e "\n🌐 Gateway Ping:"
  for gw in "${GATEWAYS[@]}"; do
    out=$(ping -c1 -W2 "$gw" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      ms=$(echo "$out" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}')
      echo -ne "  $gw — "; color_ping "$ms"
    else
      echo -e "  $gw — ${RED}Unreachable${NC}"
    fi
  done
}

start_monitor() {
  clear
  load_data
  echo -e "${PINK}╔════════════════════════════════════╗"
  echo -e "     GTM | BOOSTER v$VER              "
  echo -e "╚════════════════════════════════════╝${NC}"
  echo -e "${WHITE}🟢 FAST ≤100ms   🟡 MEDIUM ≤250ms   🔴 SLOW >250ms${NC}"
  echo -e "${YELLOW}Monitoring started. CTRL+C to stop.${NC}"
  while true; do
    load_data
    check_interface
    check_speed
    check_gateways
    check_servers
    echo -e "\n${CYAN}-------------------------------${NC}"
    sleep "$LOOP_DELAY"
  done
}

main_menu() {
  while true; do
    clear
    echo -e "${PINK}╔═══════════════════════════════╗"
    echo -e "       GTM SCRIPT MENU         "
    echo -e "╚═══════════════════════════════╝${NC}"
    echo -e "${WHITE}1) Edit DNS List (IPs Only)"
    echo "2) Edit NS Servers (Domain + IP)"
    echo "3) Edit Gateways (IPs Only)"
    echo "4) Run Monitor Script"
    echo -e "0) Exit Script ${NC}"
    echo -ne "${PINK}Choose Option: ${NC}"; read choice

    case "$choice" in
      1) edit_dns_only ;;
      2) edit_ns_only ;;
      3) edit_gateways_only ;;
      4) start_monitor ;;
      0) echo -e "${YELLOW}Thanks For Using this Script 💕.${NC}"; exit 0 ;;
      *) echo -e "${RED}Invalid option. Try again.${NC}"; sleep 1 ;;
    esac
  done
}

main_menu
