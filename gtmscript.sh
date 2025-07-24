#!/data/data/com.termux/files/usr/bin/bash
# Termux Script v4.2.3 - GeoDevz69 Full Pink UI

# Colors
PINK='\033[1;35m'
NC='\033[0m'

VER="4.2.3"

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
    echo -e "\n${PINK}An error occurred at ${progress:-unknown}%!${NC}"
    echo -e "${PINK}1. Check your internet connection"
    echo -e "2. Run 'apt update && apt upgrade -y'${NC}"
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
    echo -e "${PINK}┌──────────────────────────────┐${NC}"
    echo -e "${PINK}│     GeoDevz69 Termux Script  │${NC}"
    echo -e "${PINK}│        Version: $VER         │${NC}"
    echo -e "${PINK}├──────────────────────────────┤${NC}"
    echo -e "${PINK}│ DNS: 1  NS: 0  Delay: 5s      │${NC}"
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
            40) run_silently "apt install -y nano"; progress=50 ;;
            50) run_silently "wget -q $URL_BASE/$SCRIPT_NAME"; progress=70 ;;
            70) run_silently "chmod +x $SCRIPT_NAME"; progress=80 ;;
            80) run_silently "mv $SCRIPT_NAME /data/data/com.termux/files/usr/bin/menu"; progress=100 ;;
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
}

show_main_menu() {
    echo -e "${PINK}┌──────────────────────────────┐${NC}"
    echo -e "${PINK}│          Main Menu           │${NC}"
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
    read choice
    case "$choice" in
        1) echo -e "${PINK}DNS menu placeholder${NC}";;
        2) echo -e "${PINK}NS menu placeholder${NC}";;
        3) echo -e "${PINK}Set delay...${NC}";;
        4) echo -e "${PINK}Starting dig...${NC}";;
        5) echo -e "${PINK}Scanning IPs...${NC}";;
        6) echo -e "${PINK}Checking for updates...${NC}";;
        0) echo -e "${PINK}Goodbye!${NC}"; exit 0;;
        *) echo -e "${PINK}Invalid option${NC}";;
    esac
}

main_installation() {
    show_header
    show_loading_bar
    echo -e "${PINK}┌──────────────────────────────┐${NC}"
    echo -e "${PINK}│   INSTALLATION COMPLETE      │${NC}"
    echo -e "${PINK}└──────────────────────────────┘${NC}"
    echo -e "${PINK}Press Enter to continue...${NC}"
    read -p ""
    show_header
    show_main_menu
}

main_installation
echo -e "${PINK}Ready! Type 'menu' to start this later.${NC}"
