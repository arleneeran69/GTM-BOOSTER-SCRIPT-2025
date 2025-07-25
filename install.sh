#!/data/data/com.termux/files/usr/bin/bash

# Termux Script v4.3.1 - Pink UI | Fixed NS Check & Latency
# Author: GeoDevz69 💕

# Colors
PINK='\033[1;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Files
DNS_FILE="$HOME/.dns_list.txt"
NS_FILE="$HOME/.ns_list.txt"
GW_FILE="$HOME/.gw_list.txt"

# Create files if missing
touch "$DNS_FILE" "$NS_FILE" "$GW_FILE"

# Menu
main_menu() {
    clear
    echo -e "${PINK}┌───────────────────────────────────────────────┐"
    echo -e "${PINK}│         GeoDevz69 DNSTT Monitor v4.3.1        │"
    echo -e "${PINK}├───────────────────────────────────────────────┤"
    echo -e "${PINK}│ 1. Edit DNS Servers (IP only)                 │"
    echo -e "${PINK}│ 2. Edit NS (domain IP)                        │"
    echo -e "${PINK}│ 3. Edit Gateway IPs                           │"
    echo -e "${PINK}│ 4. Start DNSTT Monitor                        │"
    echo -e "${PINK}│ 5. Apply Globe FastDNS Booster                │"
    echo -e "${PINK}│ 0. Exit                                       │"
    echo -e "${PINK}└───────────────────────────────────────────────┘${NC}"
    echo -ne "${PINK}Choose: ${NC}"
    read -r choice

    case "$choice" in
        1) nano "$DNS_FILE" ;;
        2) edit_ns_file ;;
        3) nano "$GW_FILE" ;;
        4) start_monitor ;;
        5) apply_boost_dns ;;
        0) exit 0 ;;
        *) echo -e "${PINK}[!] Invalid option${NC}"; sleep 1 ;;
    esac
    main_menu
}

edit_ns_file() {
    if ! grep -qE "^[^#]+\.[a-zA-Z]+[[:space:]]+[0-9]" "$NS_FILE"; then
        echo -e "# Format: domain IP\n# Example: ns.example.com 1.1.1.1" > "$NS_FILE"
    fi
    nano "$NS_FILE"
}

apply_boost_dns() {
    echo -e "${PINK}Applying Globe FastDNS preset...${NC}"
    echo -e "124.6.181.25\n124.6.181.26\n124.6.181.27\n124.6.181.31\n124.6.181.248" > "$DNS_FILE"
    echo -e "gtm.codered-api.shop 124.6.181.25\n" > "$NS_FILE"
    echo -e "8.8.8.8\n1.1.1.1\n124.6.181.1" > "$GW_FILE"
    sleep 1
    echo -e "${GREEN}[✔] Globe FastDNS Applied!${NC}"
    sleep 1
}

start_monitor() {
    clear
    echo -e "${PINK}Starting DNSTT Monitor...${NC}"
    sleep 1

    DNS_LIST=()
    NS_LIST=()
    GW_LIST=()

    while read -r line; do [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue; DNS_LIST+=("$line"); done < "$DNS_FILE"
    while read -r line; do [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue; NS_LIST+=("$line"); done < "$NS_FILE"
    while read -r line; do [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue; GW_LIST+=("$line"); done < "$GW_FILE"

    echo -e "${PINK}──────────────────────────────${NC}"
    echo -e "${PINK}Detected DNS Servers:${NC}"; for i in "${DNS_LIST[@]}"; do echo -e "${PINK}- $i${NC}"; done
    echo -e "${PINK}\nDetected NS Servers:${NC}"; for i in "${NS_LIST[@]}"; do echo -e "${PINK}- $i${NC}"; done
    echo -e "${PINK}\nDetected Gateway IPs:${NC}"; for i in "${GW_LIST[@]}"; do echo -e "${PINK}- $i${NC}"; done
    echo -e "${PINK}──────────────────────────────${NC}"

    while true; do
        echo -e "\n${PINK}DNS Response Test:${NC}"
        for dns in "${DNS_LIST[@]}"; do
            dig_out=$(timeout 2s dig @"$dns" example.com +short)
            if [[ -n "$dig_out" ]]; then
                echo -e "${PINK}• $dns → ${GREEN}OK${NC}"
            else
                echo -e "${PINK}• $dns → ${RED}FAIL${NC}"
            fi
        done

        echo -e "\n${PINK}NS Query Test:${NC}"
        for entry in "${NS_LIST[@]}"; do
            ns_domain=$(echo "$entry" | awk '{print $1}')
            ns_ip=$(echo "$entry" | awk '{print $2}')
            if [[ -z "$ns_domain" || -z "$ns_ip" ]]; then
                echo -e "${PINK}• Invalid NS entry → ${RED}FAIL${NC}"
                continue
            fi

            # Get latency
            ms=$(ping -c 1 -W 1 "$ns_ip" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}')
            if [[ -z "$ms" ]]; then
                echo -e "${PINK}• $ns_domain ($ns_ip) → ${RED}No ping${NC}"
                continue
            fi

            # Check dig response
            dig_out=$(timeout 2s dig @"$ns_ip" "$ns_domain" +noall +answer)
            if [[ -z "$dig_out" ]]; then
                echo -e "${PINK}• $ns_domain ($ns_ip) → ${RED}FAIL${NC} ${RED}${ms} ms${NC}"
            elif echo "$dig_out" | grep -q "$ns_domain"; then
                echo -e "${PINK}• $ns_domain ($ns_ip) → ${GREEN}OK${NC} ${GREEN}${ms} ms${NC}"
            else
                echo -e "${PINK}• $ns_domain ($ns_ip) → ${YELLOW}No answer${NC} ${YELLOW}${ms} ms${NC}"
            fi
        done

        echo -e "\n${PINK}Gateway Reachability:${NC}"
        for gw in "${GW_LIST[@]}"; do
            ms=$(ping -c 1 -W 1 "$gw" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}')
            if [[ -z "$ms" ]]; then
                echo -e "${PINK}• $gw → ${RED}timeout${NC}"
            elif [ "$ms" -lt 100 ]; then
                echo -e "${PINK}• $gw → ${GREEN}${ms} ms${NC}"
            elif [ "$ms" -lt 300 ]; then
                echo -e "${PINK}• $gw → ${YELLOW}${ms} ms${NC}"
            else
                echo -e "${PINK}• $gw → ${RED}${ms} ms${NC}"
            fi
        done

        echo -e "${PINK}──────────────────────────────${NC}"
        sleep 5
    done
}

main_menu
