#!/data/data/com.termux/files/usr/bin/bash
# Termux Script v4.2.3 - Modified - Full Pink Menu + Fastdig/DNSTT Included

# Colors
PINK='\033[1;35m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
CYAN='\033[0;36m'
NC='\033[0m'

VER="4.2.3"
BIN_DIR="$HOME/go/bin"
GATEWAY_FILE="$HOME/gateways.txt"
DNS_FILE="$HOME/dns.txt"
NS_FILE="$HOME/ns.txt"
LOOP_DELAY="5"

get_arch() {
    case "$(uname -m)" in
        aarch64) echo "aarch64" ;;
        x86_64) echo "x86_64" ;;
        armv7l|armv8l|arm) echo "arm" ;;
        i*86) echo "i686" ;;
        *) echo "unknown" ;;
    esac
}

if [ ! -d "/data/data/com.termux" ]; then
    echo -e "${RED}This script is for Termux only!${NC}"
    exit 1
fi

ARCH_TYPE="$(get_arch)"
if [[ "$ARCH_TYPE" != "aarch64" && "$ARCH_TYPE" != "x86_64" && "$ARCH_TYPE" != "arm" ]]; then
    echo -e "${RED}Unsupported architecture: $ARCH_TYPE${NC}"
    echo -e "${YELLOW}Supported: aarch64, arm, x86_64${NC}"
    exit 1
fi

handle_error() {
    echo -e "\n${RED}❌ Error occurred at ${progress:-unknown}%!${NC}"
    echo -e "${YELLOW}Fix tips:${NC}"
    echo -e "${WHITE}1. Check internet connection"
    echo -e "2. Run: apt update && apt upgrade -y${NC}"
    exit 1
}
trap 'handle_error' ERR

clear_screen() { clear; }

run_silently() {
    eval "$1" >/dev/null 2>&1 || return 1
}

add_to_path() {
    if ! grep -q 'export PATH=$HOME/go/bin:$PATH' ~/.bashrc; then
        echo 'export PATH=$HOME/go/bin:$PATH' >> ~/.bashrc
    fi
    export PATH=$HOME/go/bin:$PATH
}

show_header() {
    clear_screen
    echo -e "${PINK}┌────────────────────────────────────┐${NC}"
    echo -e "${PINK}│   Termux Script v$VER               │${NC}"
    echo -e "${PINK}│    Modified by GeoDevz69           │${NC}"
    echo -e "${PINK}└────────────────────────────────────┘${NC}"
    echo
}

show_loading_bar() {
    echo -e "${PINK}Installing Termux Script...${NC}"
    echo

    local width=20
    local progress=0
    local ARCH="$(get_arch)"
    local URL_BASE="https://github.com/hahacrunchyrollls/TERMUX-SCRIPT/raw/refs/heads/main"
    local SCRIPT_NAME="termux-script-version-4.2"
    local DNSTT_URL FASTDIG_URL

    mkdir -p "$BIN_DIR"

    case "$ARCH" in
        aarch64) DNSTT_URL="https://raw.githubusercontent.com/GeoDevz69/dnstt-binaries/main/dnstt-client-arm64" ;;
        arm)     DNSTT_URL="https://raw.githubusercontent.com/GeoDevz69/dnstt-binaries/main/dnstt-client-arm" ;;
        x86_64)  DNSTT_URL="https://raw.githubusercontent.com/GeoDevz69/dnstt-binaries/main/dnstt-client-amd64" ;;
        *)       echo -e "${RED}No DNSTT binary for $ARCH${NC}"; exit 1 ;;
    esac
    FASTDIG_URL="https://raw.githubusercontent.com/GeoDevz69/dnstt-binaries/main/fastdig"

    while [ $progress -lt 100 ]; do
        case $progress in
            0) run_silently "rm -rf install"; progress=10 ;;
            10) run_silently "apt update -y"; progress=20 ;;
            20) run_silently "apt install -y wget curl"; progress=30 ;;
            30) run_silently "apt install -y dnsutils nano"; progress=40 ;;
            40) run_silently "wget -q $URL_BASE/$SCRIPT_NAME"; progress=50 ;;
            50) run_silently "chmod +x $SCRIPT_NAME"; progress=60 ;;
            60) run_silently "mv $SCRIPT_NAME /data/data/com.termux/files/usr/bin/setup-now"; progress=70 ;;
            70) run_silently "wget -qO $BIN_DIR/dnstt-client $DNSTT_URL"; progress=80 ;;
            80) run_silently "wget -qO $BIN_DIR/fastdig $FASTDIG_URL"; progress=90 ;;
            90) run_silently "chmod +x $BIN_DIR/dnstt-client $BIN_DIR/fastdig"; progress=100 ;;
        esac

        filled=$((progress * width / 100))
        bar="["
        for ((i=0; i<filled; i++)); do bar+="■"; done
        for ((i=filled; i<width; i++)); do bar+=" "; done
        bar+="]"
        printf "\r%s %3d%%" "$bar" "$progress"
        sleep 0.2
    done
    printf "\n"
    add_to_path
}

main_installation() {
    show_header
    show_loading_bar
    echo
    echo -e "${PINK}┌────────────────────────────────────┐${NC}"
    echo -e "${GREEN}     ✅ INSTALLATION COMPLETE        ${NC}"
    echo -e "${PINK}└────────────────────────────────────┘${NC}"
    echo
    echo -e "${PINK}Type '${YELLOW}setup-now${PINK}' to start.${NC}"
    echo
}

edit_gateway_menu() {
    echo -e "${PINK}┌──────────────────────────────┐${NC}"
    echo -e "${PINK}│     ✨ Edit Gateways         │${NC}"
    echo -e "${PINK}└──────────────────────────────┘${NC}"
    [ ! -f "$GATEWAY_FILE" ] && echo "# Add gateway IPs" > "$GATEWAY_FILE"
    nano "$GATEWAY_FILE"
}

edit_dns_menu() {
    echo -e "${PINK}┌──────────────────────────────┐${NC}"
    echo -e "${PINK}│     ✨ Edit DNS Servers      │${NC}"
    echo -e "${PINK}└──────────────────────────────┘${NC}"
    [ ! -f "$DNS_FILE" ] && echo "124.6.181.25" > "$DNS_FILE"
    nano "$DNS_FILE"
}

edit_ns_menu() {
    echo -e "${PINK}┌──────────────────────────────┐${NC}"
    echo -e "${PINK}│     ❌ Edit NS Entries       │${NC}"
    echo -e "${PINK}└──────────────────────────────┘${NC}"
    [ ! -f "$NS_FILE" ] && echo "# Add NS entries" > "$NS_FILE"
    nano "$NS_FILE"
}

start_dnstt_client() {
    echo -e "${GREEN}✅ Running DNSTT Client [Fast]...${NC}"
    "$BIN_DIR/dnstt-client" --help 2>/dev/null || echo -e "${RED}DNSTT client not working.${NC}"
    sleep 2
}

show_legacy_style_menu() {
    local dns_count ns_count
    dns_count=$(grep -c '.' "$DNS_FILE" 2>/dev/null || echo 0)
    ns_count=$(grep -c '.' "$NS_FILE" 2>/dev/null || echo 0)

    echo -e "${PINK}┌──────────────────────────────┐${NC}"
    echo -e "${PINK}│  GeoDevz69 Termux Script     │${NC}"
    echo -e "${PINK}│        Version: $VER         │${NC}"
    echo -e "${PINK}├──────────────────────────────┤${NC}"
    echo -e "${PINK}│  DNS: $dns_count  NS: $ns_count  Delay: ${LOOP_DELAY}s │${NC}"
    echo -e "${PINK}└──────────────────────────────┘${NC}"
    echo -e "${PINK}┌──────────────────────────────┐${NC}"
    echo -e "${PINK}│         Main Menu            │${NC}"
    echo -e "${PINK}├──────────────────────────────┤${NC}"
    echo -e "${PINK}│ 1. DNS Management            │${NC}"
    echo -e "${PINK}│ 2. NS Management             │${NC}"
    echo -e "${PINK}│ 3. Set Loop Delay            │${NC}"
    echo -e "${PINK}│ 4. Start Digging             │${NC}"
    echo -e "${PINK}│ 5. IP Scanner                │${NC}"
    echo -e "${PINK}│ 6. Check for Update          │${NC}"
    echo -e "${PINK}│ 0. Exit                      │${NC}"
    echo -e "${PINK}└──────────────────────────────┘${NC}"
    echo -ne "${PINK}Option: ${NC}"
}

show_menu() {
    while true; do
        clear_screen
        show_legacy_style_menu
        read -r opt
        case "$opt" in
            1) edit_dns_menu ;;
            2) edit_ns_menu ;;
            3) echo -e "${YELLOW}Set loop delay not implemented${NC}"; sleep 1 ;;
            4) start_dnstt_client ;;
            5) echo -e "${YELLOW}IP Scanner not implemented${NC}"; sleep 1 ;;
            6) echo -e "${YELLOW}Update check not implemented${NC}"; sleep 1 ;;
            0) echo -e "${YELLOW}Goodbye from GeoDevz69!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option.${NC}"; sleep 1 ;;
        esac
    done
}

main_installation
show_menu
