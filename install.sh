#!/data/data/com.termux/files/usr/bin/bash

## GTM | BOOSTER v2.2.1 - Persistent Configs + Editable via Nano
## Author: GeoDevz69 | Enhanced by ChatGPT

VER="2.2.1"
VPN_INTERFACE="tun0"
RESTART_CMD="bash /data/data/com.termux/files/home/dnstt/start-client.sh"
CUSTOM_DIG="/data/data/com.termux/files/home/go/bin/fastdig"
DIG_EXEC="DEFAULT"
FAIL_LIMIT=5

DNS_FILE=".dns_list.txt"
NS_FILE=".ns_list.txt"
GW_FILE=".gw_list.txt"
DELAY_FILE=".loop_delay.txt"

# Ensure files exist
[[ ! -f $DNS_FILE ]] && echo -e "124.6.181.25\n124.6.181.26" > "$DNS_FILE"
[[ ! -f $NS_FILE ]] && echo -e "gtm.codered-api.shop\nns.jkrol.fiber-x.shop" > "$NS_FILE"
[[ ! -f $GW_FILE ]] && echo -e "1.1.1.1\n8.8.8.8\n8.8.4.4\n9.9.9.9\n0.0.0.0" > "$GW_FILE"
[[ ! -f $DELAY_FILE ]] && echo "5" > "$DELAY_FILE"

trap 'echo -e "\n[+] Exiting..."; exit 0' SIGINT SIGTERM

# DIG Executable
case "${DIG_EXEC}" in
  DEFAULT|D) _DIG=$(command -v dig) ;;
  CUSTOM|C) _DIG="${CUSTOM_DIG}" ;;
  *) echo "[!] Invalid DIG_EXEC: $DIG_EXEC"; exit 1 ;;
esac

[ ! -x "$_DIG" ] && echo "[!] dig not executable: $_DIG" && exit 1

# Ping Color
color_ping() {
  local ms=$1
  if [[ $ms -le 100 ]]; then echo -e "\e[32m${ms}ms FAST\e[0m"
  elif [[ $ms -le 250 ]]; then echo -e "\e[33m${ms}ms MEDIUM\e[0m"
  else echo -e "\e[31m${ms}ms SLOW\e[0m"; fi
}

# Edit Menus (with centered art and green menu)
edit_menu() {
  clear
  box_width=33
  header="GDEVZ GTM BOOSTER"
  version="Script Version: ${VER}"

  padding_header=$(( (box_width - ${#header}) / 2 ))
  padding_version=$(( (box_width - ${#version}) / 2 ))

  echo -e "\e[1;35m╔═════════════════════════════════╗\e[0m"
  printf "\e[1;35m║%*s%s%*s║\e[0m\n" $padding_header "" "$header" $((box_width - padding_header - ${#header})) ""
  printf "\e[1;35m║%*s%s%*s║\e[0m\n" $padding_version "" "$version" $((box_width - padding_version - ${#version})) ""
  echo -e "\e[1;35m╚═════════════════════════════════╝\e[0m"

  echo -e "\n\e[1;36m🛠️  Configuration Menu:\e[0m"
  echo -e "\e[1;32m╔═════════════════════════════════╗"
  echo -e "  1) Edit NS Domains"
  echo -e "  2) Edit DNS IPs"
  echo -e "  3) Edit Gateways"
  echo -e "  4) Edit Loop Delay"
  echo -e "  0) Start Monitoring"
  echo -e "╚═════════════════════════════════╝\e[0m"
  echo -ne "\n\e[1;32mChoose option [0–4]: \e[0m"
  read opt
  case $opt in
    1) nano "$NS_FILE" ;;
    2) nano "$DNS_FILE" ;;
    3) nano "$GW_FILE" ;;
    4) nano "$DELAY_FILE" ;;
    0) return ;;
    *) echo -e "\e[31mInvalid option. Try again.\e[0m"; sleep 1 ;;
  esac
  edit_menu
}

# VPN Interface Check
check_interface() {
  if ip link show "$VPN_INTERFACE" > /dev/null 2>&1; then
    echo -e "\n[✓] $VPN_INTERFACE is UP"
  else
    echo -e "\n[✗] $VPN_INTERFACE is DOWN"
    restart_vpn
  fi
}

# Restart Tunnel
restart_vpn() {
  echo -e "\n\e[33m[!] Restarting DNSTT Client...\e[0m"
  pkill -f dnstt-client 2>/dev/null
  eval "$RESTART_CMD" &
  sleep 2
}

# VPN RX/TX
check_speed() {
  stats=$(ip -s link show "$VPN_INTERFACE" 2>/dev/null | grep -A1 'RX:' | tail -n1)
  RX=$(echo "$stats" | awk '{print $1}')
  TX=$(echo "$stats" | awk '{print $9}')
  echo -e "    🔄 RX=${RX}B | TX=${TX}B"
}

# Check Gateways
check_gateways() {
  echo -e "\n🌐 Checking Gateways:"
  local best_gw=""
  local best_ping=9999
  while read -r gw; do
    [[ -z "$gw" ]] && continue
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
  done < "$GW_FILE"
  if [[ -n "$best_gw" ]]; then
    echo -e "\n✅ Best Gateway: \e[1;36m$best_gw — $(color_ping $best_ping)\e[0m"
  else
    echo -e "\n⚠️ No reachable gateways."
  fi
}

# DNS+NS Monitor
check_servers() {
  local total_ok=0
  local total_fail=0
  local fail_count=0
  echo -e "\n🔍 Checking NS & DNS:"
  while read -r ns_domain; do
    [[ -z "$ns_domain" ]] && continue
    while read -r dns_ip; do
      [[ -z "$dns_ip" ]] && continue
      echo -e "\n[•] \e[34m$ns_domain\e[0m @ $dns_ip"

      if ping -c1 -W2 "$dns_ip" > /dev/null; then
        ping_ms=$(ping -c1 -W2 "$dns_ip" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}')
        echo -ne "    \e[32m✓ Ping OK\e[0m — "
        color_ping "$ping_ms"
      else
        echo -e "    \e[31m✗ Ping FAIL\e[0m"
        ((fail_count++)); ((total_fail++))
        continue
      fi

      if timeout -k 3 3 "$_DIG" @"$dns_ip" "$ns_domain" > /dev/null 2>&1; then
        echo -e "    \e[32m✓ DNS Query OK\e[0m"
        ((total_ok++))
      else
        echo -e "    \e[31m✗ DNS Query FAIL\e[0m"
        ((fail_count++)); ((total_fail++))
      fi
    done < "$DNS_FILE"
  done < "$NS_FILE"

  echo -e "\n📊 Result: OK=$total_ok | FAIL=$total_fail"

  if (( fail_count >= FAIL_LIMIT )); then
    echo -e "\n\e[31m[!] Too many failures — restarting tunnel\e[0m"
    restart_vpn
  fi
}

### 🔧 Menu before Monitoring
edit_menu

# 🌀 Main Loop
while true; do
  LOOP_DELAY=$(<"$DELAY_FILE")
  ((LOOP_DELAY < 1)) && LOOP_DELAY=2
  echo -e "\n[+] GTM | BOOSTER v${VER} - Monitor Started"
  echo -e "    🟢 \e[32mFAST (≤100ms)\e[0m   🟡 \e[33mMEDIUM (101–250ms)\e[0m   🔴 \e[31mSLOW (>250ms)\e[0m"
  check_interface
  check_speed
  check_gateways
  check_servers
  echo -e "\n-----------------------------"
  sleep "$LOOP_DELAY"
done
