#!/data/data/com.termux/files/usr/bin/bash

DNSTT Keep-Alive & DNS Monitor v2.3 - Dig-Only Edition

Author: GeoDevz69 💕

VER="2.3" LOOP_DELAY=5 FAIL_LIMIT=5 DIG_EXEC="DEFAULT" VPN_INTERFACE="tun0" RESTART_CMD="bash /data/data/com.termux/files/home/dnstt/start-client.sh"

Colors

RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' CYAN='\033[0;36m' WHITE='\033[1;37m' PINK='\033[1;35m' NC='\033[0m'

Config files

DNS_FILE="$HOME/.dns_list.txt" NS_FILE="$HOME/.ns_list.txt" GW_FILE="$HOME/.gateway_list.txt"

Create empty files if missing

touch "$DNS_FILE" "$NS_FILE" "$GW_FILE"

Load data

readarray -t DNS_LIST < "$DNS_FILE" readarray -t NS_LIST < "$NS_FILE" readarray -t GATEWAYS < "$GW_FILE"

Dig binary selection

_DIG=$(command -v dig) [ ! -x "$_DIG" ] && { echo -e "${RED}[!] dig not found or not executable. Please install it using:${NC}" echo -e "${YELLOW}pkg install dnsutils${NC}" exit 1 }

Arch check

arch=$(uname -m) [[ "$arch" != "aarch64" && "$arch" != "x86_64" ]] && { echo -e "${RED}Unsupported architecture: $arch${NC}" echo -e "${YELLOW}Use Termux version for: aarch64 or x86_64${NC}" exit 1 } [ ! -d "/data/data/com.termux" ] && { echo -e "${RED}This script runs only in Termux!${NC}" exit 1 }

trap main_menu INT

edit_dns_only() { echo -e "${YELLOW}Edit DNS IPs (1 per line, example: 124.6.181.25)...${NC}" sleep 1; nano "$DNS_FILE"; main_menu }

edit_ns_only() { if ! grep -q "example.com" "$NS_FILE"; then echo "# Format: domain IP" > "$NS_FILE" echo "# Example: gtm.codered-api.shop 1.2.3.4" >> "$NS_FILE" echo "# One entry per line." >> "$NS_FILE" fi echo -e "${YELLOW}Edit NS Servers (domain and IP)...${NC}" sleep 1; nano "$NS_FILE"; main_menu }

edit_gateways_only() { echo -e "${YELLOW}Edit Gateway IPs or Hosts (1 per line, e.g. 8.8.8.8 or www.google.com)...${NC}" sleep 1; nano "$GW_FILE"; main_menu }

color_ping() { ms=$1 if (( ms <= 100 )); then echo -e "${GREEN}${ms}ms FAST${NC}" elif (( ms <= 250 )); then echo -e "${YELLOW}${ms}ms MEDIUM${NC}" else echo -e "${RED}${ms}ms SLOW${NC}"; fi }

restart_vpn() { echo -e "\n${YELLOW}[!] Restarting DNSTT Client...${NC}" pkill -f dnstt-client 2>/dev/null eval "$RESTART_CMD" & sleep 2 }

check_interface() { if ip link show "$VPN_INTERFACE" &>/dev/null; then echo -e "✅ ${GREEN}$VPN_INTERFACE is UP${NC}" else echo -e "❌ ${RED}$VPN_INTERFACE is DOWN${NC}" restart_vpn fi }

check_speed() { stats=$(ip -s link show "$VPN_INTERFACE" 2>/dev/null | grep -A1 'RX:' | tail -n1) RX=$(echo "$stats" | awk '{print $1}') TX=$(echo "$stats" | awk '{print $9}') echo -e "📶 RX=${RX}B | TX=${TX}B" }

check_gateways() { echo -e "\n🌐 Gateway Ping:" best_gw=""; best_ping=9999 for gw in "${GATEWAYS[@]}"; do out=$(ping -c1 -W2 "$gw" 2>/dev/null) if [[ $? -eq 0 ]]; then ms=$(echo "$out" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}') echo -ne "  $gw — "; color_ping "$ms" (( ms < best_ping )) && best_ping=$ms && best_gw=$gw else echo -e "  $gw — ${RED}Unreachable${NC}" fi done [[ "$best_gw" ]] && echo -e "\n✅ Best Gateway: $best_gw — $(color_ping $best_ping)" }

check_servers() { echo -e "\n🔍 Checking NS Servers:" fail_count=0; best_ns=""; best_ping=9999

for entry in "${NS_LIST[@]}"; do domain=$(echo "$entry" | awk '{print $1}') ip=$(echo "$entry" | awk '{print $2}') [[ -z "$domain" || -z "$ip" ]] && continue

echo -e "\n[•] $domain @ $ip"

ping_out=$(ping -c1 -W2 "$ip" 2>/dev/null)
if [[ $? -eq 0 ]]; then
  ping_ms=$(echo "$ping_out" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}')
  echo -ne "    ✓ Ping OK — "; color_ping "$ping_ms"
  (( ping_ms < best_ping )) && best_ping=$ping_ms && best_ns="$domain @ $ip"
else
  echo -e "    ✗ ${RED}Ping FAIL${NC}"; ((fail_count++)); continue
fi

timeout -k 3 3 "$_DIG" @"$ip" "$domain" +short &>/dev/null
if [[ $? -eq 0 ]]; then
  echo -e "    ${GREEN}✓ DNS Query OK${NC}"
else
  echo -e "    ${RED}✗ DNS Query FAIL${NC}"; ((fail_count++))
fi

done

[[ "$best_ns" ]] && echo -e "\n🌟 ${GREEN}Fastest NS: $best_ns [$best_ping ms]${NC}" (( fail_count >= FAIL_LIMIT )) && restart_vpn }

auto_ping_dns_list() { echo -e "\n${CYAN}📱 Auto-Ping Test: DNS IP List (Globe)...${NC}" best_dns=""; best_ping=9999

for dns in "${DNS_LIST[@]}"; do [[ -z "$dns" ]] && continue out=$(ping -c1 -W2 "$dns" 2>/dev/null) if [[ $? -eq 0 ]]; then ms=$(echo "$out" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}') echo -ne "  $dns — "; color_ping "$ms" (( ms < best_ping )) && best_ping=$ms && best_dns=$dns else echo -e "  $dns — ${RED}Unreachable${NC}" fi done [[ "$best_dns" ]] && echo -e "\n✅ ${GREEN}Best DNS: $best_dns — $(color_ping $best_ping)" echo -e "\n${YELLOW}Done. Returning to menu...${NC}"; sleep 2 main_menu }

reset_list_menu() { clear echo -e "${YELLOW}Which list do you want to reset?${NC}" echo -e "${WHITE}1) Clear DNS IP List" echo "2) Clear NS Server List" echo "3) Clear Gateway List" echo -e "4) Clear ALL Lists" echo -e "0) Back to Main Menu${NC}" echo -ne "${PINK}Choose Option: ${NC}"; read reset_choice

case "$reset_choice" in 1) > "$DNS_FILE"; echo -e "${GREEN}DNS list cleared.${NC}"; sleep 1 ;; 2) > "$NS_FILE"; echo -e "${GREEN}NS list cleared.${NC}"; sleep 1 ;; 3) > "$GW_FILE"; echo -e "${GREEN}Gateway list cleared.${NC}"; sleep 1 ;; 4) > "$DNS_FILE"; > "$NS_FILE"; > "$GW_FILE"; echo -e "${GREEN}All lists cleared.${NC}"; sleep 1 ;; 0) main_menu ;; *) echo -e "${RED}Invalid option.${NC}"; sleep 1 ;; esac main_menu }

start_monitor() { clear echo -e "${PINK}╔════════════════════════════╗" echo -e "     GTM | BOOSTER v$VER" echo -e "╚════════════════════════════╝${NC}" echo -e "${WHITE}🟢 FAST ≤100ms   🟡 MEDIUM ≤250ms   🔴 SLOW >250ms${NC}" echo -e "${YELLOW}Monitoring started. CTRL+C to stop.${NC}" while true; do check_interface check_speed check_gateways check_servers echo -e "\n${CYAN}-------------------------------${NC}" sleep "$LOOP_DELAY" done }

main_menu() { clear echo -e "${PINK}╔═══════════════════════════╗" echo -e "       GTM SCRIPT MENU          " echo -e "╚═══════════════════════════╝${NC}" echo -e "${WHITE}1) Edit DNS IP List" echo "2) Edit NS Servers (domain + IP)" echo "3) Edit Gateway Pings (IPs or Domains)" echo "4) Run Monitoring Script" echo "5) Auto-Ping DNS List" echo "6) Reset / Clear Lists" echo -e "0) Exit Script${NC}" echo -ne "${PINK}Choose Option: ${NC}"; read choice

case "$choice" in 1) edit_dns_only ;; 2) edit_ns_only ;; 3) edit_gateways_only ;; 4) start_monitor ;; 5) auto_ping_dns_list ;; 6) reset_list_menu ;; 0) echo -e "${YELLOW}Thanks For Using this Script 💕${NC}"; exit 0 ;; *) echo -e "${RED}Invalid option.${NC}"; sleep 1; main_menu ;; esac }

main_menu

