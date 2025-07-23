#!/data/data/com.termux/files/usr/bin/bash

## GTM Booster Menu v1.0
## Clean interactive DNS/NS/Gateway Manager
## Author: GeoDevz69

DNS_FILE="$HOME/dnstt/dns.txt"
NS_FILE="$HOME/dnstt/ns.txt"
GATEWAY_FILE="$HOME/dnstt/gateway.txt"

mkdir -p "$HOME/dnstt"

show_menu() {
  clear
  echo -e "\e[1;36m=== GTM Booster Configuration Menu ===\e[0m"
  echo "1) Add DNS (Edit dns.txt)"
  echo "2) Add NS (Edit ns.txt)"
  echo "3) Add Gateway (Edit gateway.txt)"
  echo "0) Exit"
  echo -n -e "\nChoose an option [0-3]: "
  read -r choice

  case "$choice" in
    1)
      echo -e "\nOpening DNS list in nano..."
      nano "$DNS_FILE"
      ;;
    2)
      echo -e "\nOpening NS list in nano..."
      nano "$NS_FILE"
      ;;
    3)
      echo -e "\nOpening Gateway list in nano..."
      nano "$GATEWAY_FILE"
      ;;
    0)
      echo -e "\nGoodbye!"
      exit 0
      ;;
    *)
      echo -e "\nInvalid option. Try again."
      sleep 1
      ;;
  esac
}

# Run only once
show_menu
