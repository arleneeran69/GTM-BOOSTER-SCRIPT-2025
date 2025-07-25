#!/data/data/com.termux/files/usr/bin/bash

# DNSTT Keep-Alive & DNS Monitor v2.3.4 - Data-Validated NS Edition
# Author: GeoDevz69 💕 (Optimized with Web Access Checks)
VER="2.3.4"
LOOP_DELAY=5
FAIL_LIMIT=5
DIG_EXEC="CUSTOM"
CUSTOM_DIG="/data/data/com.termux/files/home/go/bin/fastdig"
VPN_INTERFACE="tun0"
RESTART_CMD="$HOME/dnstt/start-client.sh"

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

# Placeholders
[[ ! -f "$RESTART_CMD" ]] && {
  mkdir -p "$HOME/dnstt"
  echo -e "#!/data/data/com.termux/files/usr/bin/bash\nexit 0" > "$RESTART_CMD"
  chmod +x "$RESTART_CMD"
}
touch "$DNS_FILE" "$NS_FILE" "$GW_FILE"

# System check
arch=$(uname -m)
[[ "$arch" != "aarch64" && "$arch" != "x86_64" ]] && {
  echo -e "${RED}Unsupported architecture: $arch${NC}"; exit 1; }
[ ! -d "/data/data/com.termux" ] && {
  echo -e "${RED}This script runs only in Termux!${NC}"; exit 1; }

# Choose dig
if [[ "$DIG_EXEC" == "CUSTOM" || "$DIG_EXEC" == "C" ]]; then
  [[ -x "$CUSTOM_DIG" ]] && _DIG="$CUSTOM_DIG" || {
    echo -e "${YELLOW}[!] fastdig not found. Using dig.${NC}"
    _DIG=$(command -v dig)
  }
else _DIG=$(command -v dig); fi
[[ -z "$_DIG" ]] && echo -e "${RED}[!] dig not found. Exiting.${NC}" && exit 1

# === Functions ===

edit_dns_only() { echo -e "${YELLOW}Edit DNS IPs only...${NC}"; sleep 1; nano "$DNS_FILE"; }
edit_ns_only() { echo -e "${YELLOW}Edit NS Domains only...${NC}"; sleep 1; nano "$NS_FILE"; }
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
  bash "$RESTART_CMD" &>/dev/null &
  echo -e "${GREEN}[✓] Restart command sent.${NC}"
  sleep 2
}

check_interface() {
  ip link show "$VPN_INTERFACE" &>/dev/null &&
    echo -e "✅ ${GREEN}$VPN_INTERFACE is UP${NC}" ||
    { echo -e "❌ ${RED}$VPN_INTERFACE is DOWN${NC}"; restart_vpn; }
}

check_speed() {
  stats=$(ip -s link show "$VPN_INTERFACE" 2>/dev/null | grep -A1 'RX:' | tail -n1)
  RX=$(echo "$stats" | awk '{print $1}')
  TX=$(echo "$stats" | awk '{print $9}')
  echo -e "📶 RX=${RX}B | TX=${TX}B"
}

check_gateways() {
  echo -e "\n🌐 Gateway Ping + Data Access:"
  readarray -t GATEWAYS < "$GW_FILE"
  best_gw=""; best_ping=9999

  for gw in "${GATEWAYS[@]}"; do
    out=$(ping -c1 -W2 "$gw" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      ms=$(echo "$out" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}')
      echo -ne "  $gw — "; color_ping "$ms"

      test=$(curl -m 4 -s --connect-timeout 2 --head http://connectivitycheck.gstatic.com/generate_204)
      if [[ "$test" == *"204 No Content"* ]]; then
        echo -e "       ${GREEN}✓ Data OK${NC}"
        (( ms < best_ping )) && best_ping=$ms && best_gw=$gw
      else
        echo -e "       ${RED}✗ No Internet Access${NC}"
      fi
    else
      echo -e "  $gw — ${RED}Unreachable${NC}"
    fi
  done

  [[ "$best_gw" ]] && echo -e "\n✅ Best Gateway: $best_gw — $(color_ping $best_ping)"
}

check_servers() {
  echo -e "\n🔍 Checking NS Domains:"
  readarray -t DNS_LIST < "$DNS_FILE"
  readarray -t NS_LIST < "$NS_FILE"
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
        found=1
      else
        echo -e "    ↳ $dns_ip — ${RED}Unreachable${NC}"
      fi

      timeout -k 3 3 "$_DIG" +tcp @"$dns_ip" "$domain" &>/dev/null
      if [[ $? -eq 0 ]]; then
        echo -e "       ${GREEN}✓ DNS Query OK${NC}"
        real_test=$(curl -m 4 -s --connect-timeout 2 --resolve google.com:80:$dns_ip http://google.com -o /dev/null -w "%{http_code}")
        if [[ "$real_test" == "200" ]]; then
          echo -e "       ${GREEN}✓ Web Access OK${NC}"
          (( ping_ms < best_this )) && best_this=$ping_ms && best_ns="$domain via $dns_ip"
        else
          echo -e "       ${RED}✗ No Web Access${NC}"; ((fail_count++))
        fi
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

globe_dns_lookup() {
  echo -e "${YELLOW}📡 Scanning best Globe DNS (124.6.181.*)...${NC}"
  DNS_CANDIDATES=(124.6.181.25 124.6.181.26 124.6.181.27 124.6.181.31 124.6.181.167 124.6.181.171 124.6.181.248)
  best_dns=""; best_ms=9999

  for ip in "${DNS_CANDIDATES[@]}"; do
    out=$(ping -c1 -W2 "$ip" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      ms=$(echo "$out" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}')
      echo -ne "  $ip — "; color_ping "$ms"
      (( ms < best_ms )) && best_ms=$ms && best_dns=$ip
    else
      echo -e "  $ip — ${RED}Unreachable${NC}"
    fi
  done

  if [[ "$best_dns" ]]; then
    echo -e "${GREEN}✅ Best Globe DNS: $best_dns ($best_ms ms)${NC}"
    grep -qxF "$best_dns" "$DNS_FILE" || echo "$best_dns" >> "$DNS_FILE"
    echo -e "${CYAN}📁 DNS list updated with: $best_dns${NC}"
  else
    echo -e "${RED}✗ No Globe DNS is reachable right now.${NC}"
  fi
  sleep 3
}

ping_common_destinations() {
  echo -e "${CYAN}📡 Pinging common DNS destinations...${NC}"
  declare -A DESTS=(
    ["dns9.quad9.net"]="9.9.9.9"
    ["www.google.com"]="8.8.8.8"
    ["one.one.one.one"]="1.1.1.1"
  )

  for name in "${!DESTS[@]}"; do
    ip="${DESTS[$name]}"
    echo -ne "  $name ($ip) — "
    out=$(ping -c1 -W2 "$ip" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      ms=$(echo "$out" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}')
      color_ping "$ms"
    else
      echo -e "${RED}Unreachable${NC}"
    fi
  done
  sleep 3
}

start_monitor() {
  clear
  echo -e "${PINK}╔═════════════════════════════════╗"
  echo -e "     GeoDevz Script v$VER         "
  echo -e "╚═════════════════════════════════╝${NC}"
  echo -e "${WHITE}🟢 FAST ≤100ms   🟡 MEDIUM ≤250ms   🔴 SLOW >250ms${NC}"
  echo -e "${YELLOW}Monitoring started. Press CTRL+C to return to menu.${NC}"
  trap 'echo -e "\n${CYAN}Returning to menu...${NC}"; main_menu' SIGINT

  while true; do
    check_interface
    check_speed
    check_gateways
    check_servers
    echo -e "\n${CYAN}-------------------------------${NC}"
    sleep "$LOOP_DELAY"
  done
}

main_menu() {
  trap '' SIGINT
  clear
  echo -e "${PINK}╔═════════════════════════════════╗"
  echo -e "         📡 GTM BOOSTER 📡         "
  echo -e "╚═════════════════════════════════╝${NC}"
  echo -e "${WHITE}1) Edit DNS List (IPs Only)"
  echo "2) Edit NS Domains (1 per line)"
  echo "3) Edit Gateways (IPs Only)"
  echo "4) Run Monitor Script"
  echo "5) Check Available DNS"
  echo "6) DNS Resolver"
  echo -e "0) Exit Script${NC}"
  echo -ne "${PINK}Choose Option: ${NC}"; read choice

  case "$choice" in
    1) edit_dns_only ;;
    2) edit_ns_only ;;
    3) edit_gateways_only ;;
    4) start_monitor ;;
    5) globe_dns_lookup ;;
    6) ping_common_destinations ;;
    0) echo -e "${YELLOW}Thanks for using the script 💕${NC}"; exit 0 ;;
    *) echo -e "${RED}Invalid option.${NC}"; sleep 1 ;;
  esac
  main_menu
}

main_menu
