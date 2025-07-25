#!/data/data/com.termux/files/usr/bin/bash

# DNSTT Keep-Alive & DNS Monitor v2.3.4 - Full Menu Edition
# Author: GeoDevz69 💕 (Now without watermark as requested)

VER="2.3.4"
LOOP_DELAY=5
FAIL_LIMIT=5
VPN_INTERFACE="tun0"
DIG_EXEC="$HOME/go/bin/fastdig"

# Files
DNS_FILE=".dns_list.txt"
NS_FILE=".ns_list.txt"
GW_FILE=".gw_list.txt"

# Colors
PINK='\033[1;35m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
NC='\033[0m'

check_fastdig() {
    if [ ! -x "$DIG_EXEC" ]; then
        echo -e "${RED}[!] fastdig not found: $DIG_EXEC${NC}"
        echo -e "${YELLOW}Please run install.sh or recheck Go installation.${NC}"
        exit 1
    fi
}

print_menu() {
    clear
    echo -e "${PINK}╔═════════════════════════════════════════════╗"
    echo -e "║        GTM | BOOSTER - DNSTT Monitor        ║"
    echo -e "║                 Version $VER                     ║"
    echo -e "╚═════════════════════════════════════════════╝${NC}"
    echo -e "${PINK}[1] Edit DNS List"
    echo -e "[2] Edit NS List"
    echo -e "[3] Edit Gateway List"
    echo -e "[4] Lookup Best Globe DNS"
    echo -e "[5] Auto Ping DNS List"
    echo -e "[6] Ping Popular DNS (9.9.9.9, 8.8.8.8, 1.1.1.1)"
    echo -e "[7] Start DNSTT Monitor"
    echo -e "[0] Exit${NC}"
}

edit_file() {
    local name=$1
    local file=$2
    echo -e "${PINK}[•] Editing $name List...${NC}"
    sleep 0.5
    nano "$file"
}

lookup_best_dns() {
    echo -e "${PINK}[•] Scanning Globe DNS (124.6.181.*)...${NC}"
    for ip in {1..254}; do
        addr="124.6.181.$ip"
        ping -c1 -W1 $addr &> /dev/null && echo -e "${GREEN}[+] $addr is alive${NC}" || echo -e "${RED}[-] $addr unreachable${NC}"
    done
    read -p "Press Enter to return..."
}

ping_dns_list() {
    echo -e "${PINK}[•] Pinging DNS IPs in $DNS_FILE...${NC}"
    while read -r ip; do
        [ -z "$ip" ] && continue
        ping_result=$(ping -c1 -W1 "$ip" 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | cut -d' ' -f1)
        if [ -n "$ping_result" ]; then
            echo -e "${GREEN}[+] $ip - ${ping_result} ms${NC}"
        else
            echo -e "${RED}[-] $ip - No response${NC}"
        fi
    done < "$DNS_FILE"
    read -p "Press Enter to return..."
}

ping_known_dns() {
    echo -e "${PINK}[•] Pinging Public DNS Servers...${NC}"
    declare -A targets=( ["dns9.quad9.net"]="9.9.9.9" ["one.one.one.one"]="1.1.1.1" ["google.com"]="8.8.8.8" )
    for name in "${!targets[@]}"; do
        ip=${targets[$name]}
        result=$(ping -c1 -W1 "$ip" 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | cut -d' ' -f1)
        if [ -n "$result" ]; then
            echo -e "${GREEN}[+] $name ($ip) - ${result} ms${NC}"
        else
            echo -e "${RED}[-] $name ($ip) - Unreachable${NC}"
        fi
    done
    read -p "Press Enter to return..."
}

start_monitor() {
    echo -e "${PINK}[•] Starting DNSTT Monitor Loop...${NC}"
    sleep 1
    while true; do
        clear
        echo -e "${PINK}╔═══════════ MONITORING DNS/NS/GW ═══════════╗${NC}"

        echo -e "${YELLOW}DNS IPs:${NC}"
        while read -r dns; do
            [ -z "$dns" ] && continue
            ping -c1 -W1 "$dns" &>/dev/null && status="${GREEN}OK${NC}" || status="${RED}FAIL${NC}"
            echo -e "$dns - $status"
        done < "$DNS_FILE"

        echo -e "${YELLOW}\nNS List:${NC}"
        while read -r line; do
            [ -z "$line" ] && continue
            domain=$(echo "$line" | awk '{print $1}')
            nsip=$(echo "$line" | awk '{print $2}')
            result=$("$DIG_EXEC" +timeout=1 @"$nsip" "$domain" A | grep "ms" | tail -n1 | awk '{print $4}')
            if [[ "$result" =~ ^[0-9]+$ ]]; then
                if [ "$result" -lt 50 ]; then color=$GREEN
                elif [ "$result" -lt 150 ]; then color=$YELLOW
                else color=$RED; fi
                echo -e "$domain ($nsip) - ${color}${result} ms${NC}"
            else
                echo -e "$domain ($nsip) - ${RED}FAIL${NC}"
            fi
        done < "$NS_FILE"

        echo -e "${YELLOW}\nGateways:${NC}"
        while read -r gw; do
            [ -z "$gw" ] && continue
            ping -c1 -W1 "$gw" &>/dev/null && echo -e "$gw - ${GREEN}OK${NC}" || echo -e "$gw - ${RED}FAIL${NC}"
        done < "$GW_FILE"

        echo -e "${PINK}\n[Auto-refreshing in $LOOP_DELAY seconds] Ctrl+C to stop...${NC}"
        sleep $LOOP_DELAY
    done
}

check_fastdig
mkdir -p ~
touch "$DNS_FILE" "$NS_FILE" "$GW_FILE"

while true; do
    print_menu
    read -p "$(echo -e "${YELLOW}Select option:${NC} ")" opt
    case $opt in
        1) edit_file "DNS" "$DNS_FILE" ;;
        2) edit_file "NS" "$NS_FILE" ;;
        3) edit_file "Gateway" "$GW_FILE" ;;
        4) lookup_best_dns ;;
        5) ping_dns_list ;;
        6) ping_known_dns ;;
        7) start_monitor ;;
        0) echo -e "${GREEN}Exiting.${NC}"; exit ;;
        *) echo -e "${RED}[!] Invalid option.${NC}" ;;
    esac
done
