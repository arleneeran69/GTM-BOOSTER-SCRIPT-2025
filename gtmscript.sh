#!/data/data/com.termux/files/usr/bin/bash
# Termux Script v4.2.3 – Pink UI, DNS/NS/GW Editor, DNSTT
# Author: GeoDevz69

# Colors
PINK='\033[1;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# Paths
DNS_FILE="$HOME/.dns_list"
NS_FILE="$HOME/.ns_list"
GW_FILE="$HOME/.gw_list"
DNSTT_BIN="$HOME/go/bin/dnstt-client"

# Ensure files exist
touch "$DNS_FILE" "$NS_FILE" "$GW_FILE"

# Header UI
show_header() {
  clear
  echo -e "${PINK}┌────────────────────────────────────┐"
  echo -e "│     GeoDevz Termux Script v4.2.3  │"
  echo -e "├────────────────────────────────────┤"
  echo -e "│ DNS: $(wc -l < $DNS_FILE)  NS: $(wc -l < $NS_FILE)  GW: $(wc -l < $GW_FILE) │"
  echo -e "└────────────────────────────────────┘${NC}"
}

# Pink Loading Screen
loading_screen() {
  echo -e "${PINK}Loading"
  for i in {1..3}; do
    echo -n "."
    sleep 0.5
  done
  echo -e "${NC}"
}

# Install Requirements
install_requirements() {
  pkg install -y curl wget nano proot tar git || exit 1
  # Download DNSTT client if not available
  if [ ! -f "$DNSTT_BIN" ]; then
    echo -e "${PINK}[+] Installing DNSTT client...${NC}"
    mkdir -p "$(dirname "$DNSTT_BIN")"
    curl -sLo "$DNSTT_BIN" https://raw.githubusercontent.com/geo-dns/dnstt-client/main/dnstt-client && chmod +x "$DNSTT_BIN"
  fi
}

# Edit DNS List
edit_dns() {
  nano "$DNS_FILE"
}

# Edit NS List
edit_ns() {
  nano "$NS_FILE"
}

# Edit Gateway List
edit_gateway() {
  nano "$GW_FILE"
}

# Start DNSTT Keep-Alive
start_dnstt() {
  show_header
  echo -e "${PINK}[+] Starting DNSTT Client...${NC}"
  NS=$(head -n1 "$NS_FILE")
  DNS=$(head -n1 "$DNS_FILE")
  GW=$(head -n1 "$GW_FILE")
  echo -e "${PINK}Using NS: $NS, DNS: $DNS, GW: $GW${NC}"
  $DNSTT_BIN -r 127.0.0.1:2222 "$NS" "$DNS" &
  echo -e "${PINK}[+] DNSTT Client Started${NC}"
  sleep 2
}

# Main Menu
main_menu() {
  while true; do
    show_header
    echo -e "${PINK}[1] Edit DNS Servers"
    echo -e "[2] Edit Nameservers (NS)"
    echo -e "[3] Edit Gateways"
    echo -e "[4] Start DNSTT Script"
    echo -e "[5] Install Requirements"
    echo -e "[0] Exit${NC}"
    echo -ne "${PINK}Choose: ${NC}"
    read -r choice
    case "$choice" in
      1) edit_dns ;;
      2) edit_ns ;;
      3) edit_gateway ;;
      4) start_dnstt ;;
      5) install_requirements ;;
      0) echo -e "${PINK}Goodbye! 💕${NC}"; exit ;;
      *) echo -e "${PINK}Invalid option.${NC}"; sleep 1 ;;
    esac
  done
}

# Run
loading_screen
main_menu
