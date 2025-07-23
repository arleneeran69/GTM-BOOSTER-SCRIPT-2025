#!/data/data/com.termux/files/usr/bin/bash

# Author: GeoDevz69 
# Version: v2.0 Menu-Based Installer

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Clear screen
clear

# Header
echo -e "${CYAN}"
echo "#########################################"
echo "#     Termux Tools Installer Menu       #"
echo "#     DNS / Gateway / NS Utilities      #"
echo "#     Version: 2.0                      #"
echo "#########################################"
echo -e "${NC}"

# Menu function
menu() {
    echo -e "${YELLOW}Select an option:${NC}"
    echo "1) DNS Tools"
    echo "2) Gateways Installer"
    echo "3) NS Lookup Tools"
    echo "0) Exit"
    echo -n "Enter choice: "
    read choice

    case $choice in
        1) dns_tools ;;
        2) gateway_menu ;;
        3) ns_tools ;;
        0) exit 0 ;;
        *) echo -e "${RED}Invalid option. Try again.${NC}" ; sleep 1 ; menu ;;
    esac
}

# DNS Tools
dns_tools() {
    echo -e "${CYAN}Installing DNS Utilities...${NC}"
    pkg update -y
    pkg install -y dnsutils resolv-conf
    echo -e "${GREEN}DNS tools installed.${NC}"
    pause_return
}

# Gateways installer submenu
gateway_menu() {
    echo -e "${YELLOW}Choose a Gateway script to install:${NC}"
    echo "1) Default Gateway Script"
    echo "2) Custom Gateway A"
    echo "3) Custom Gateway B"
    echo "0) Return to Main Menu"
    echo -n "Enter choice: "
    read gw_choice

    case $gw_choice in
        1) install_default_gateway ;;
        2) install_custom_gateway_a ;;
        3) install_custom_gateway_b ;;
        0) menu ;;
        *) echo -e "${RED}Invalid choice.${NC}" ; sleep 1 ; gateway_menu ;;
    esac
}

install_default_gateway() {
    echo -e "${CYAN}Installing Default Gateway Script...${NC}"
    pkg install -y curl
    curl -sL https://github.com/hahacrunchyrollls/TERMUX-SCRIPT/raw/refs/heads/main/install | bash
    echo -e "${GREEN}Default Gateway Installed.${NC}"
    pause_return
}

install_custom_gateway_a() {
    echo -e "${CYAN}Installing Custom Gateway A...${NC}"
    # Replace this with actual URL/script if available
    echo "Custom Gateway A script goes here."
    pause_return
}

install_custom_gateway_b() {
    echo -e "${CYAN}Installing Custom Gateway B...${NC}"
    # Replace this with actual URL/script if available
    echo "Custom Gateway B script goes here."
    pause_return
}

# NS Lookup Tools
ns_tools() {
    echo -e "${CYAN}Installing NS Lookup Utilities...${NC}"
    pkg install -y bind-utils
    echo -e "${GREEN}NS Lookup tools installed.${NC}"
    echo "Try: nslookup example.com"
    pause_return
}

# Helper: pause and return
pause_return() {
    echo -e "${YELLOW}Press Enter to return to main menu...${NC}"
    read
    clear
    menu
}

# Start Menu
menu
