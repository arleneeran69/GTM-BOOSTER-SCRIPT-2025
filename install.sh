#!/data/data/com.termux/files/usr/bin/bash

# DNSTT Keep-Alive & DNS Monitor v2.3.4 - Auto-Installer + Menu UI Edition

# Auto-install packages
echo -e "\033[1;35m[•] Installing dependencies...\033[0m"
pkg update -y && pkg upgrade -y
pkg install -y curl bash coreutils grep dnsutils inetutils iproute2 procps nano git golang

# Install fastdig
echo -e "\033[1;35m[•] Installing fastdig...\033[0m"
go install github.com/jedisct1/fastdig@latest

# Add fastdig to PATH (optional)
if ! grep -q 'export PATH=$PATH:$HOME/go/bin' ~/.bashrc; then
  echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
fi
export PATH=$PATH:$HOME/go/bin

# ---- Script Variables ----
VER="2.3.4"
LOOP_DELAY=5
FAIL_LIMIT=5
DIG_EXEC="DEFAULT"
VPN_INTERFACE="tun0"
RESTART_CMD="bash /data/data/com.termux/files/home/dnstt/start-client.sh"

DNS_FILE=".dns_list.txt"
NS_FILE=".ns_list.txt"
GW_FILE=".gw_list.txt"

# ---- Colors ----
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
PINK='\033[1;35m'
NC='\033[0m'

# ---- Auto-fill Files ----
if [ ! -s "$DNS_FILE" ]; then
  echo -e "124.6.181.25\n124.6.181.26\n124.6.181.27\n124.6.181.31\n124.6.181.167\n124.6.181.171\n124.6.181.248" > "$DNS_FILE"
fi

if [ ! -s "$NS_FILE" ]; then
  echo "# Format: domain IP (one per line)" > "$NS_FILE"
  echo "# Example: gtm.codered-api.shop 124.6.181.25" >> "$NS_FILE"
fi

if [ ! -s "$GW_FILE" ]; then
  echo "8.8.8.8" > "$GW_FILE"
fi

# ---- Menu Functions ----

edit_dns_only() {
  echo -e "${YELLOW}Edit DNS IPs (one per line)...${NC}"
  sleep 1
  nano "$DNS_FILE"
  grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' "$DNS_FILE" | grep -v '[a-zA-Z]' > "$DNS_FILE.tmp"
  mv "$DNS_FILE.tmp" "$DNS_FILE"
  echo -e "${GREEN}✔ DNS list updated with valid IPs only.${NC}"
  sleep 1; main_menu
}

edit_ns_only() {
  echo -e "${YELLOW}Edit NS Servers (domain + IP)...${NC}"
  sleep 1
  nano "$NS_FILE"
  grep -E '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\s+([0-9]{1,3}\.){3}[0-9]{1,3}$' "$NS_FILE" > "$NS_FILE.tmp"
  mv "$NS_FILE.tmp" "$NS_FILE"
  echo -e "${GREEN}✔ NS list updated and validated.${NC}"
  sleep 1; main_menu
}

edit_gateway_only() {
  echo -e "${YELLOW}Edit Gateway IPs (one per line)...${NC}"
  sleep 1
  nano "$GW_FILE"
  grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' "$GW_FILE" > "$GW_FILE.tmp"
  mv "$GW_FILE.tmp" "$GW_FILE"
  echo -e "${GREEN}✔ Gateway list updated with valid IPs only.${NC}"
  sleep 1; main_menu
}

main_menu() {
  clear
  echo -e "${PINK}═══════════════════════════════════════════════"
  echo -e "      🌐 DNSTT Keep-Alive Monitor v$VER 🌐"
  echo -e "═══════════════════════════════════════════════${NC}"
  echo -e "${PINK}[1] Edit DNS IPs${NC}"
  echo -e "${PINK}[2] Edit NS (domain + IP)${NC}"
  echo -e "${PINK}[3] Edit Gateway IPs${NC}"
  echo -e "${PINK}[4] Start Monitoring${NC}"
  echo -e "${PINK}[0] Exit${NC}"
  echo -ne "${YELLOW}Select: ${NC}"
  read choice

  case "$choice" in
    1) edit_dns_only ;;
    2) edit_ns_only ;;
    3) edit_gateway_only ;;
    4) echo -e "${GREEN}Starting monitor... (not implemented in this block)${NC}" ;;
    0) echo -e "${RED}Exiting...${NC}" && exit ;;
    *) echo -e "${RED}Invalid option!${NC}" && sleep 1 && main_menu ;;
  esac
}

# Start menu
main_menu
