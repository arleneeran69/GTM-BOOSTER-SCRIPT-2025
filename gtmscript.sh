#!/data/data/com.termux/files/usr/bin/bash
# Termux SCRIPT with Loading Screen - Multi-Arch Support - Pink UI
# Version 4.2.3

# Colors
PINK='\033[1;35m'
NC='\033[0m'

VER="4.2.3"

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

# Check for Termux
if [ ! -d "/data/data/com.termux" ]; then
    echo -e "${PINK}This script is for Termux only!${NC}"
    exit 1
fi

ARCH_TYPE="$(get_arch)"
if [[ "$ARCH_TYPE" != "aarch64" && "$ARCH_TYPE" != "x86_64" && "$ARCH_TYPE" != "arm" ]]; then
    echo -e "${PINK}Unsupported architecture: $ARCH_TYPE${NC}"
    echo -e "${PINK}Only aarch64, arm, and x86_64 are supported.${NC}"
    exit 1
fi

handle_error() {
    echo -e "\n${PINK}⚠️  An error occurred at ${progress:-unknown}%${NC}"
    echo -e "${PINK}💡 Fix tips:"
    echo -e "${PINK}1. Check your internet connection"
    echo -e "2. Run: apt update && apt upgrade -y${NC}"
    exit 1
}
trap 'handle_error' ERR

clear_screen() { clear; }

run_silently() {
    eval "$1" >/dev/null 2>&1 || return 1
}

show_header() {
    clear_screen
    echo -e "${PINK}┌──────────────────────────────┐"
    echo -e "${PINK}│    GeoDevz69 Termux Script   │"
    echo -e "${PINK}│        Version: $VER          │"
    echo -e "${PINK}└──────────────────────────────┘${NC}"
    echo
}

show_loading_bar() {
    echo -e "${PINK}Installing Termux Script...${NC}"
    echo

    local width=20
    local progress=0
    local URL_BASE="https://github.com/hahacrunchyrollls/TERMUX-SCRIPT/raw/refs/heads/main"
    local SCRIPT_NAME="termux-script-version-$VER"

    while [ $progress -lt 100 ]; do
        case $progress in
            0) run_silently "rm -rf install"; progress=10 ;;
            10) run_silently "apt update -y"; progress=20 ;;
            20) run_silently "apt install -y wget"; progress=30 ;;
            30) run_silently "apt install -y dnsutils"; progress=40 ;;
            40) run_silently "apt install -y nano curl"; progress=50 ;;
            50) run_silently "wget -q $URL_BASE/$SCRIPT_NAME"; progress=70 ;;
            70) run_silently "chmod +x $SCRIPT_NAME"; progress=80 ;;
            80) run_silently "mv $SCRIPT_NAME /data/data/com.termux/files/usr/bin/menu"; progress=100 ;;
        esac

        filled=$((progress * width / 100))
        bar="["
        for ((i=0; i<filled; i++)); do bar+="■"; done
        for ((i=filled; i<width; i++)); do bar+=" "; done
        bar+="]"

        printf "\r${PINK}%s %3d%%%s" "$bar" "$progress" "${NC}"
        sleep 0.2
    done
    printf "\n"
}

main_installation() {
    show_header
    show_loading_bar
    echo
    echo -e "${PINK}┌──────────────────────────────┐"
    echo -e "${PINK}│     INSTALLATION COMPLETE    │"
    echo -e "${PINK}└──────────────────────────────┘${NC}"
    echo
    echo -e "${PINK}📌 TERMUX SCRIPT ready!"
    echo -e "🌐 https://phcorner.net/members/geodevz69.696969${NC}"
    echo -e "${PINK}Press Enter to continue...${NC}"
    read -p ""
}

main_installation
echo -e "${PINK}✔️ Ready! Type 'menu' to start.${NC}"
