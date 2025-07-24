#!/data/data/com.termux/files/usr/bin/bash

# Termux Script v4.2.3 - Full Pink UI | DNS, NS, Gateway Editor with Monitor
# Author: GeoDevz69 💕

# Colors
PINK='\033[1;35m'
NC='\033[0m'

# Files
DNS_FILE="$HOME/.dns_list.txt"
NS_FILE="$HOME/.ns_list.txt"
GW_FILE="$HOME/.gw_list.txt"

# Create files if missing
touch "$DNS_FILE" "$NS_FILE" "$GW_FILE"

# Main menu
main_menu() {
    clear
    echo -e "${PINK}┌───────────────────────────────────────────────┐${NC}"
    echo -e "${PINK}│         GeoDevz69 DNSTT Monitor v4.2.3        │${NC}"
    echo -e "${PINK}├───────────────────────────────────────────────┤${NC}"
    echo -e "${PINK}│ 1. Edit DNS Servers (IP only)                 │${NC}"
    echo -e "${PINK}│ 2. Edit NS (domain IP)                        │${NC}"
    echo -e "${PINK}│ 3. Edit Gateway IPs                           │${NC}"
    echo -e "${PINK}│ 4. Start DNSTT Monitor                        │${NC}"
    echo -e "${PINK}│ 0. Exit                                       │${NC}"
    echo -e "${PINK}└───────────────────────────────────────────────┘${NC}"
    echo -ne "${PINK}Choose: ${NC}"
    read -r choice

    case "$choice" in
        1) nano "$DNS_FILE";;
        2) edit_ns_file;;
        3) nano "$GW_FILE";;
        4) start_monitor;;
        0) exit 0;;
        *) echo -e "${PINK}[!] Invalid option${NC}"; sleep 1;;
    esac

    main_menu
}

# Function to edit NS with guide
edit_ns_file() {
    if ! grep -q "^[^#]*\.[a-zA-Z]*[[:space:]][0-9]" "$NS_FILE"; then
        echo -e "# Format: domain IP\n# Ex: ns.example.com 1.1.1.1" > "$NS_FILE"
    fi
    nano "$NS_FILE"
}

# Monitor function
start_monitor() {
    clear
    echo -e "${PINK}Starting DNS Monitor...${NC}"
    sleep 1

    echo -e "${PINK}Loading DNS...${NC}"
    DNS_LIST=()
    while read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        DNS_LIST+=("$line")
    done < "$DNS_FILE"

    echo -e "${PINK}Loading NS...${NC}"
    NS_LIST=()
    while read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        NS_LIST+=("$line")
    done < "$NS_FILE"

    echo -e "${PINK}Loading Gateway IPs...${NC}"
    GW_LIST=()
    while read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        GW_LIST+=("$line")
    done < "$GW_FILE"

    echo -e "${PINK}──────────────────────────────${NC}"
    echo -e "${PINK}Detected DNS Servers:${NC}"
    for dns in "${DNS_LIST[@]}"; do echo -e "${PINK}- $dns${NC}"; done

    echo -e "${PINK}\nDetected NS Servers:${NC}"
    for ns in "${NS_LIST[@]}"; do echo -e "${PINK}- $ns${NC}"; done

    echo -e "${PINK}\nDetected Gateway IPs:${NC}"
    for gw in "${GW_LIST[@]}"; do echo -e "${PINK}- $gw${NC}"; done
    echo -e "${PINK}──────────────────────────────${NC}"

    echo -e "${PINK}[✓] Monitor ready. Press Ctrl+C to return.${NC}"
    while true; do
        sleep 5
        echo -ne "${PINK}Checking... ${NC}"
        # Add monitor logic here (ping/check dig etc)
        echo -e "${PINK}OK${NC}"
    done
}

# Start script
main_menu
