#!/bin/bash
# Recon & enumeration against the DC
# Usage: ./01_recon.sh <DC_IP>

DC_IP="${1:-192.168.56.10}"

echo "[*] Full port scan..."
sudo nmap -sV -sC -p- "$DC_IP" -oN dc01_scan.txt

echo "[*] SMB enumeration (netexec)..."
netexec smb "$DC_IP"

echo "[*] Null session / anonymous enum (enum4linux-ng)..."
enum4linux-ng -A "$DC_IP"
