#!/data/data/com.termux/files/usr/bin/bash

# === GTM Booster Menu ===
clear
echo "=== GTM Booster Configuration Menu ==="
echo "1) Add DNS (Edit dns.txt)"
echo "2) Add NS (Edit ns.txt)"
echo "3) Add Gateway (Edit gateway.txt)"
echo "0) Exit"
echo ""

read -p "Choose an option [0-3]: " choice

case "$choice" in
  1)
    echo "Opening dns.txt..."
    nano dns.txt
    ;;
  2)
    echo "Opening ns.txt..."
    nano ns.txt
    ;;
  3)
    echo "Opening gateway.txt..."
    nano gateway.txt
    ;;
  0)
    echo "Exiting..."
    exit 0
    ;;
  *)
    echo "Invalid option. Exiting..."
    exit 1
    ;;
esac
