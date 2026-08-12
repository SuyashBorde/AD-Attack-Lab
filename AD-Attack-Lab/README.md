# Active Directory Attack Lab

A self-built Active Directory home lab demonstrating end-to-end AD enumeration and
credential attacks: null-session recon, AS-REP Roasting, offline hash cracking, and
(in progress) Kerberoasting / lateral movement. Built as a follow-up to
[VulnScan Lab](#) to specifically target Active Directory attack paths ahead of the
EC-Council CPENT (412-80) exam.

> ⚠️ This lab runs entirely on an isolated VirtualBox **Internal Network** with no
> internet access. All credentials, hostnames, and IPs below belong to a disposable,
> fictional lab domain (`vulncorp.local`) and are not connected to any real system.

---

## Lab Architecture

| Host  | Role                  | OS                    | IP             |
|-------|-----------------------|------------------------|----------------|
| DC01  | Domain Controller     | Windows Server 2019    | 192.168.56.10  |
| WIN7  | Domain-joined client   | Windows 7               | 192.168.56.20  |
| Kali  | Attack box             | Kali Linux              | 192.168.56.30  |

- **Domain:** `vulncorp.local`
- **Network:** VirtualBox Internal Network (`intnet`), fully isolated from host/internet
- **Hypervisor:** Oracle VirtualBox

### Domain Objects Created

| Account      | Purpose                                    | Misconfiguration                          |
|--------------|---------------------------------------------|--------------------------------------------|
| `svc-sql`    | Service account (SQL SPN)                   | Kerberoastable (SPN registered)            |
| `Y.Borde`    | Standard domain user                        | AS-REP roastable (preauth disabled)        |
| `admin-svc`  | Domain Admin, reused as local admin on WIN7 | Shared privileged account across machines  |

---

## Attack Chain

1. **Recon & Enumeration** — `nmap`, `netexec`, `enum4linux-ng`
2. **AS-REP Roasting** — `impacket-GetNPUsers` against `Y.Borde` (no valid creds needed)
3. **Offline Cracking** — `hashcat -m 18200` against captured AS-REP hash
4. **Kerberoasting** *(in progress)* — `impacket-GetUserSPNs` against `svc-sql` using cracked `Y.Borde` credentials
5. **Lateral Movement** *(planned)* — BloodHound attack-path mapping, pass-the-hash to WIN7/DC01 via `admin-svc`

Full methodology, commands, and findings write-up: [`docs/METHODOLOGY.md`](docs/METHODOLOGY.md)
Findings summary (report-style): [`reports/`](reports/)

---

## Key Findings So Far

| # | Finding                                             | Severity | Status        |
|---|------------------------------------------------------|----------|---------------|
| 1 | SMB Null Session / Anonymous Auth allowed on DC01     | Medium   | Confirmed     |
| 2 | User account with Kerberos preauth disabled (AS-REP roastable) | High | Exploited — credential cracked |
| 3 | Weak/dictionary-crackable domain password policy      | High     | Confirmed — cracked via rockyou.txt |
| 4 | Service account (`svc-sql`) has registered SPN (Kerberoastable) | High | Identified — cracking in progress |
| 5 | Privileged account (`admin-svc`) reused as local admin across hosts | High | Configured — exploitation pending |

Full detail for each finding, including reproduction steps and remediation, is in `docs/METHODOLOGY.md`.

---

## Repository Structure

```
AD-Attack-Lab/
├── README.md                     # This file
├── .gitignore                    # Excludes real credential/loot output from git
├── docs/
│   └── METHODOLOGY.md            # Full step-by-step writeup with commands
├── screenshots/
│   ├── 01-ad-object-creation/    # User/SPN/Domain Admin group creation
│   ├── 02-domain-join-networking/# Static IPs, domain join, connectivity troubleshooting
│   ├── 03-recon-enumeration/     # nmap, netexec, enum4linux-ng
│   ├── 04-as-rep-roasting/       # impacket-GetNPUsers
│   ├── 05-hash-cracking/         # hashcat AS-REP crack
│   ├── 06-kerberoasting/         # In progress (clock-skew troubleshooting)
│   └── 07-lateral-movement/      # Planned — BloodHound, PtH
├── loot/                         # Sanitized/example hash formats (real values gitignored)
├── scripts/                      # Reusable attack commands
└── reports/                      # Polished report(s) for portfolio use
```

---

## Tools Used

`Nmap` · `netexec` · `enum4linux-ng` · `Impacket` (`GetNPUsers`, `GetUserSPNs`) · `Hashcat` · `BloodHound` (planned)

## Roadmap

- [x] Build 3-VM AD lab (DC01, WIN7, Kali)
- [x] Recon & null-session enumeration
- [x] AS-REP Roasting + offline crack
- [ ] Kerberoasting (`svc-sql`) — blocked on VirtualBox host-time-sync clock skew, fix identified
- [ ] BloodHound attack path mapping
- [ ] Lateral movement (pass-the-hash, `admin-svc` → WIN7 → DC01)
- [ ] Final polished PDF pentest report

---

## Author

**Suyash Borde** — [GitHub](https://github.com/SuyashBorde) · [LinkedIn](https://linkedin.com/in/suyash-borde)
Built as portfolio work while preparing for EC-Council CPENT (Exam 412-80).
