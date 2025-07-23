#!/data/data/com.termux/files/usr/bin/bash

## GTM Booster Configurable Script (Menu + Runtime)

CONFIG_DIR="$HOME/.gtmconfig"
NS_FILE="$CONFIG_DIR/nameservers.txt"
DNS_FILE="$CONFIG_DIR/dns.txt"
GATEWAY_FILE="$CONFIG_DIR/gateways.txt"

mkdir -p "$CONFIG_DIR"

# Set default values if files don't exist
[[ ! -f "$NS_FILE" ]] && cat > "$NS_FILE" <<EOF
ns.jkrol.fiber-x.shop 124.6.181.167
ns.jkrol.fiber-x.shop 124.6.181.31
EOF

[[ ! -f "$DNS_FILE" ]] && echo "default" > "$DNS_FILE"
[[ ! -f "$GATEWAY_FILE" ]] && cat > "$GATEWAY_FILE" <<EOF
1.1.1.1
8.8.8.8
8.8.4.4
EOF

# Function: Load config into variables
load_config() {
  SERVERS=()
  GATEWAYS=()
  while read -r line; do
    [[ -n "$line" ]] && SERVERS+=("$line")
  done < "$NS_FILE"
  while read -r line; do
    [[ -n "$line" ]] && GATEWAYS+=("$line")
  done < "$GATEWAY_FILE"
  DNS_SERVER=$(cat "$DNS_FILE")
}

# Menu for user edits
show_menu() {
  while true; do
    clear
    echo -e "\e[1;32m🛠️  GTM CONFIG MENU\e[0m"
    echo "1. Edit NS (domain + IP, e.g. ns.domain.com 1.2.3.4)"
    echo "2. Edit DNS (set preferred DNS resolver IP or label)"
    echo "3. Edit Gateways (list of IPs)"
    echo "0. Start Script"
    echo -n "Select: "
    read -r choice
    case "$choice" in
      1) nano "$NS_FILE" ;;
      2) nano "$DNS_FILE" ;;
      3) nano "$GATEWAY_FILE" ;;
      0) break ;;
      *) echo "❌ Invalid option"; sleep 1 ;;
    esac
  done
}

# Show menu and load the updated config
show_menu
load_config
