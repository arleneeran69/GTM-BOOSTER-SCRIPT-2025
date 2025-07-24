#!/data/data/com.termux/files/usr/bin/bash
# Termux SCRIPT with Loading Screen, DNSTT, Fastdig, and Gateway Menu
# Author: GeoDevz69 💕 | Version 4.2.2

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

VER="4.2.2"
BIN_DIR="$HOME/go/bin"
GATEWAY_FILE="$HOME/gateways.txt"

# Detect architecture
get_arch() {
    case "$(uname -m)" in
        aarch64) echo "aarch64" ;;
        x86_64) echo "x86_64" ;;
        armv7l|armv8l|arm) echo "arm" ;;
        i*86) echo "i686" ;;
        *) echo "unknown" ;;
    esac
}

# Check for Termux environment
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

# Error handling
handle_error() {
    echo -e "\n${RED}An error occurred at ${progress:-unknown}%!${NC}"
    echo -e "${YELLOW}Fix Tips:${NC}"
    echo -e "${WHITE}1. Check internet"
    echo -e "2. Run: apt update && apt upgrade -y${NC}"
    exit 1
}
trap 'handle_error' ERR

clear_screen() {
    clear
}

run_silently() {
    eval "$1" >/dev/null 2>&1 || return 1
}

show_header() {
    clear_screen
    echo -e "${WHITE}╔══════════════════════════╗${NC}"
    echo -e "${WHITE}  GeoDevz69 💕 Termux Script${NC}"
    echo -e "${WHITE}       Version: $VER        ${NC}"
    echo -e "${WHITE}╚══════════════════════════╝${NC}"
    echo
}

add_to_path() {
    if ! grep -q 'export PATH=$HOME/go/bin:$PATH' ~/.bashrc; then
        echo 'export PATH=$HOME/go/bin:$PATH' >> ~/.bashrc
    fi
    export PATH=$HOME/go/bin:$PATH
}

show_loading_bar() {
    echo -e "${WHITE}Installing Termux Script...${NC}"
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
        *)       echo -e "${RED}No dnstt binary for $ARCH${NC}"; exit 1 ;;
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
            60) run_silently "mv $SCRIPT_NAME /data/data/com.termux/files/usr/bin/menu"; progress=70 ;;
            70) run_silently "wget -qO $BIN_DIR/dnstt-client $DNSTT_URL"; progress=80 ;;
            80) run_silently "wget -qO $BIN_DIR/fastdig $FASTDIG_URL"; progress=90 ;;
            90) run_silently "chmod +x $BIN_DIR/dnstt-client $BIN_DIR/fastdig"; progress=100 ;;
        esac

        # Draw loading bar
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
    echo -e "${WHITE}╔══════════════════════════╗${NC}"
    echo -e "${WHITE}   INSTALLATION COMPLETE   ${NC}"
    echo -e "${WHITE}╚══════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}TERMUX SCRIPT by GeoDevz69 💕${NC}"
    echo -e "${BLUE}https://github.com/GeoDevz69${NC}"
    echo
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -p ""
}

edit_gateway_menu() {
    echo -e "${CYAN}GATEWAY EDITOR${NC}"
    [ ! -f "$GATEWAY_FILE" ] && echo "# Your gateway list goes here" > "$GATEWAY_FILE"
    nano "$GATEWAY_FILE"
}

show_menu() {
    while true; do
        clear_screen
        echo -e "${WHITE}╔═════════════════════╗${NC}"
        echo -e "${WHITE}   TERMUX MAIN MENU   ${NC}"
        echo -e "${WHITE}╚═════════════════════╝${NC}"
        echo -e "${GREEN}[1]${NC} Edit Gateways"
        echo -e "${GREEN}[0]${NC} Exit"
        echo
        read -p "Choose: " opt
        case "$opt" in
            1) edit_gateway_menu ;;
            0) echo -e "${YELLOW}Goodbye.${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option.${NC}"; sleep 1 ;;
        esac
    done
}

main_installation
show_menu
