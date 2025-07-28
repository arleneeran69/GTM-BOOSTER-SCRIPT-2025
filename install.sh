#!/data/data/com.termux/files/usr/bin/bash

## GTM | BOOSTER v2.2.2 - With Ctrl+C Trap + ASCII Art Header
## Author: GeoDevz69 | Enhanced by ChatGPT

VER="2.2.2"
VPN_INTERFACE="tun0"
RESTART_CMD="bash /data/data/com.termux/files/home/dnstt/start-client.sh"
CUSTOM_DIG="/data/data/com.termux/files/home/go/bin/fastdig"
DIG_EXEC="DEFAULT"
FAIL_LIMIT=5

NS_FILE=".ns_list.txt"
GW_FILE=".gw_list.txt"
DELAY_FILE=".loop_delay.txt"

[[ ! -f $NS_FILE ]] && echo -e "vpn.kagerou.site 124.6.181.167\nphc.jericoo.xyz 124.6.181.26" > "$NS_FILE"
[[ ! -f $GW_FILE ]] && echo -e "1.1.1.1\n8.8.8.8\n8.8.4.4\n9.9.9.9\n0.0.0.0" > "$GW_FILE"
[[ ! -f $DELAY_FILE ]] && echo "5" > "$DELAY_FILE"

trap ctrl_c_handler SIGINT
ctrl_c_handler() {
  echo -e "\n\n⚠️  Ctrl+C detected — returning to main menu..."
  sleep 1
  edit_menu
}

case "${DIG_EXEC}" in
  DEFAULT|D) _DIG=$(command -v dig) ;;
  CUSTOM|C) _DIG="${CUSTOM_DIG}" ;;
  *) echo "[!] Invalid DIG_EXEC: $DIG_EXEC"; exit 1 ;;
esac

[ ! -x "$_DIG" ] && echo "[!] dig not executable: $_DIG" && exit 1

color_ping() {
  local ms=$1
  if [[ $ms -le 100 ]]; then echo -e "\e[32m${ms}ms FAST\e[0m"
  elif [[ $ms -le 250 ]]; then echo -e "\e[33m${ms}ms MEDIUM\e[0m"
  else echo -e "\e[31m${ms}ms SLOW\e[0m"; fi
}

edit_menu() {
  clear

  # GREEN ASCII ART HEADER
  echo -e "\e[1;32m"
  cat << "EOF"
⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠠⠾⠿⢿⣿⣧⣄⠀⠀⠀⠀⣀⣼⣿⡿⠿⠷⠄⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⠁⠀⠀⠈⡿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢀⣠⣾⣿⣿⣷⣶⠁⠀⠀⠈⢴⣾⣿⣿⣿⣄⡀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠀⠁⠀⣰⠀⠀⣆⠀⠈⠁⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡀⠔⢹⠀⠀⡏⠣⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⡶⣖⠈⠉⠀⠀⢜⣤⣤⡣⠄⠀⠈⠁⣲⢖⡞⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠻⣜⢷⣤⣤⣶⣿⠋⠙⣿⣶⣤⣤⡾⢫⠞⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠙⢄⠀⠀⠈⠉⠉⠉⠉⠁⠀⠀⢠⠋⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣹⣿⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠸⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⣠⠖⠋⠹⢃⣷⡀⢰⠇⣿⣙⠑⢋⡟⠛⠀⠘⣇⠀⣠⠟⣽⣹⠆⣷⣄⢀⡏⠀
⠀⣿⡀⢀⡶⣼⠁⠻⡾⢰⣏⡉⠀⣼⠀⠀⠀⠀⢿⡼⠁⢰⡏⠁⢸⠃⠹⣾⠁
EOF
  echo -e "\e[0m"

  # Terminal width
  TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
  box_width=41
  header="GDEVZ GTM BOOSTER"
  version="Script Version: ${VER}"
  padding_header=$(( (box_width - ${#header}) / 2 ))
  padding_version=$(( (box_width - ${#version}) / 2 ))

  echo -e "\e[1;35m╔══════════════════════════════════════╗\e[0m"
  printf "\e[1;35m %*s%s%*s \e[0m\n" $padding_header "" "$header" $((box_width - padding_header - ${#header})) ""
  printf "\e[1;35m %*s%s%*s \e[0m\n" $padding_version "" "$version" $((box_width - padding_version - ${#version})) ""
  echo -e "\e[1;35m╚══════════════════════════════════════╝\e[0m"

  echo -e "\e[1;32m╔═════════════GTM•MAIN•MENU════════════╗"
  echo -e "  1) Edit NS Domains + DNS IPs"
  echo -e "  2) Edit Gateways"
  echo -e "  3) Edit Loop Delay"
  echo -e "  4) Start Monitoring"
  echo -e "  0) Exit Script Now"
  echo -e "╚══════════════════════════════════════╝\e[0m"
  echo -ne "\n\e[1;32mChoose option [0–4]: \e[0m"
  read opt
  case $opt in
    1) nano "$NS_FILE" ;;
    2) nano "$GW_FILE" ;;
    3) nano "$DELAY_FILE" ;;
    4) main_loop ;;
    0) echo -e "\n👋 Exiting GTM Booster. Stay fast!"; exit 0 ;;
    *) echo -e "\e[31mInvalid option. Try again.\e[0m"; sleep 1 ;;
  esac
  edit_menu
}

# ... rest of the script continues (unchanged)
