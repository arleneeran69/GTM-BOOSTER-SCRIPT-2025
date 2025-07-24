#!/data/data/com.termux/files/usr/bin/bash
# Termux Script v4.2.3 - Full Pink UI | Menu System

# Colors
PINK='\033[1;35m'
NC='\033[0m'

# Files
DNS_FILE="$HOME/.dns_list.txt"
NS_FILE="$HOME/.ns_list.txt"

# Create empty files if not exist
touch "$DNS_FILE"
touch "$NS_FILE"

# Header UI
print_header() {
  DNS_COUNT=$(wc -l < "$DNS_FILE")
  NS_COUNT=$(wc -l < "$NS_FILE")
  DELAY="1s"
  echo -e "${PINK}┌──────────────────────────────┐"
  echo -e "│  PHC_GeoDevz69 Termux Script │"
  echo -e "│         Version: 4.2         │"
  echo -e "├──────────────────────────────┤"
  echo -e "│ DNS: $DNS_COUNT  NS: $NS_COUNT  Delay: $DELAY │"
  echo -e "└──────────────────────────────┘${NC}"
}

# Main Menu
main_menu() {
  clear
  print_header
  echo -e "${PINK}┌──────────────────────────────┐"
  echo -e "│          Main Menu           │"
  echo -e "├──────────────────────────────┤"
  echo -e "│ 1. DNS Management            │"
  echo -e "│ 2. NS Management             │"
  echo -e "│ 3. Set Loop Delay            │"
  echo -e "│ 4. Start Digging             │"
  echo -e "│ 5. IP Scanner                │"
  echo -e "│ 6. Check for Update          │"
  echo -e "│ 0. Exit                      │"
  echo -e "└──────────────────────────────┘${NC}"
  echo -ne "${PINK}Option: ${NC}"
  read opt
  case $opt in
    1) dns_menu ;;
    2) ns_menu ;;  # Not yet implemented
    3) echo -e "${PINK}Delay setup coming soon!${NC}" && pause ;;
    4) echo -e "${PINK}Start Digging coming soon!${NC}" && pause ;;
    5) echo -e "${PINK}IP Scanner coming soon!${NC}" && pause ;;
    6) echo -e "${PINK}Update checker coming soon!${NC}" && pause ;;
    0) exit ;;
    *) echo -e "${PINK}Invalid option${NC}" && sleep 1 && main_menu ;;
  esac
}

# DNS Management Menu
dns_menu() {
  clear
  print_header
  echo -e "${PINK}┌──────────────────────────────┐"
  echo -e "│        DNS Management        │"
  echo -e "├──────────────────────────────┤"
  echo -e "│ 1. Add DNS                   │"
  echo -e "│ 2. Remove DNS                │"
  echo -e "│ 3. Edit DNS in nano          │"
  echo -e "│ 4. View Current DNS          │"
  echo -e "│ 5. Delete ALL DNS            │"
  echo -e "│ 0. Back to Main Menu         │"
  echo -e "└──────────────────────────────┘${NC}"
  echo -ne "${PINK}Option: ${NC}"
  read dns_opt
  case $dns_opt in
    1)
      echo -ne "${PINK}Enter new DNS IP: ${NC}"
      read new_dns
      echo "$new_dns" >> "$DNS_FILE"
      echo -e "${PINK}Added: $new_dns${NC}"
      sleep 1
      dns_menu
      ;;
    2)
      echo -ne "${PINK}Enter DNS to remove: ${NC}"
      read rm_dns
      sed -i "/$rm_dns/d" "$DNS_FILE"
      echo -e "${PINK}Removed: $rm_dns${NC}"
      sleep 1
      dns_menu
      ;;
    3)
      nano "$DNS_FILE"
      dns_menu
      ;;
    4)
      echo -e "${PINK}Current DNS List:${NC}"
      cat "$DNS_FILE"
      echo
      pause
      dns_menu
      ;;
    5)
      > "$DNS_FILE"
      echo -e "${PINK}All DNS entries deleted.${NC}"
      sleep 1
      dns_menu
      ;;
    0)
      main_menu
      ;;
    *)
      echo -e "${PINK}Invalid option${NC}"
      sleep 1
      dns_menu
      ;;
  esac
}

# Pause utility
pause() {
  echo -e "${PINK}Press Enter to continue...${NC}"
  read
}

# Launch menu when user types 'menu'
if [[ "$1" == "menu" || "$0" == *menu* ]]; then
  main_menu
fi
