## **🐛🪱🐝ngrok:how to use ngrok in termux🐛🪱**

> A practical, step‑by‑step guide to install and use ngrok v3 (and Cloudflare Tunnel) on Termux (Android) to expose local HTTP, SSH and arbitrary TCP services. This README records the real errors encountered, their causes, and exact working solutions so others can reproduce the working setup.




---

Quick summary

This guide shows how to install ngrok v3 in Termux (ARM/ARM64), add your auth token, and expose services: HTTP, TCP (SSH), and custom TCP.

When ngrok is blocked or unstable, use cloudflared (Cloudflare Tunnel) as a reliable alternative.

Includes small helper scripts to automate starting a server + tunnel and to kill Termux-owned processes.



---

Prerequisites

Termux installed on Android (up-to-date pkg repository)

Internet connection (Wi‑Fi preferred when mobile carriers block tunnels)

Basic familiarity with the Termux shell



---

**1) Install ngrok v3 (Termux)**

**1.1** Detect CPU architecture (choose correct binary)
```
uname -m
```

aarch64  -> 64-bit ARM
armv7l  -> 32-bit ARM

**1.2** Remove any old ngrok binary (if present)
```
rm -f "$PREFIX/bin/ngrok" 2>/dev/null || true
```
**1.3** Download & install ngrok v3 (example for arm64)

For 64-bit ARM (most modern phones)
```
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz
tar -xvzf ngrok-v3-stable-linux-arm64.tgz
chmod +x ngrok
mv ngrok "$PREFIX/bin/"
```

For 32-bit ARM (if uname -m shows armv7l), use:
```
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm.tgz
```

**1.4** Verify installation

ngrok version
should show something like: ngrok version 3.x.x

> If ngrok version still shows 2.x.x, you did not replace the old binary. Remove the old binary and re-run the mv step.




---

**2) Add your ngrok authtoken (v3)**

1. Sign into https://dashboard.ngrok.com and copy your authtoken.


2. Preferred: store the token in the v3 config folder:



ensure the v3 config directory exists
mkdir -p ~/.config/ngrok

add the token (recommended command for v3)
ngrok config add-authtoken <YOUR_AUTHTOKEN>

verify config
```
cat ~/.config/ngrok/ngrok.yml
```
or if it was saved to the old v2 path, copy it:
```
[ -f ~/.ngrok2/ngrok.yml ] && cp ~/.ngrok2/ngrok.yml ~/.config/ngrok/ngrok.yml
cat ~/.config/ngrok/ngrok.yml
```
Common problem: Authtoken saved to /home/.ngrok2/ngrok.yml but ngrok v3 looks in ~/.config/ngrok.

Solution: create ~/.config/ngrok and copy the file (shown above).

Helpful environment fix (Termux warning): you may see this warning:

WARN failed to get home directory, using $HOME instead err="user: Current requires cgo or $USER set in environment"

It is harmless, but to silence it and help some tools, add:
```
export USER=$(whoami)
echo 'export USER=$(whoami)' >> ~/.bashrc   # or ~/.zshrc
```

---

**3) Expose an HTTP server (example)**

**3.1** Start a simple Python HTTP server
```
pkg install python -y
```
start server on port 8080
```
python3 -m http.server 8080
```

If you get OSError: [Errno 98] Address already in use that means something is already bound to the port. To free it:

find Termux-owned python processes and kill them

```
ps aux | grep http.server
kill -9 <PID>
```

or use a different port
```
python3 -m http.server 9090
```

**3.2** Start ngrok tunnel to the port

use explicit config path to be safe
```
ngrok http --config ~/.config/ngrok/ngrok.yml 8080
```

Expected output contains a Forwarding line such as:

Forwarding    https://<random>.ngrok-free.app -> http://localhost:8080

Open that HTTPS URL in a browser to view your Termux directory listing or served app.


---

**4) Expose SSH (Termux) using ngrok TCP**

Termux openssh typically listens on port 8022 by default (not 22).

```
pkg install openssh -y
passwd  # set your password for Termux user
sshd    # starts sshd (default port 8022)
ps aux | grep sshd
```

expose via ngrok TCP
```
ngrok tcp --config ~/.config/ngrok/ngrok.yml 8022
```

**ngrok will print a tcp://<host>:**

<port> mapping — connect remotely with:

ssh -p <ngrok-port> <termux-user>@<tcp-host>

Example:
ssh -p 12345 u0_a456@0.tcp.ngrok.io

Security note: Exposing SSH to the public is sensitive. Use strong passwords, or better: set up key-based auth in Termux and disable password login.


---

**5) Expose arbitrary TCP service**

Replace 8022 in the SSH example with any port your app listens on.
```
ngrok tcp --config ~/.config/ngrok/ngrok.yml 5000
```

then connect to the provided host:port


---

**6) When ngrok fails: use Cloudflare Tunnel (cloudflared)**

If ngrok repeatedly fails to connect (ISP blocking, high packet loss, or denied connections), cloudflared quick tunnels are a great fallback.

Install Cloudflared
```
pkg install cloudflared -y
```
Create a quick tunnel (no Cloudflare account required)
```
cloudflared tunnel --url http://localhost:8080
```
You will get a trycloudflare.com URL like:

https://<random>.trycloudflare.com

Open that URL to access your local server.

Notes / logs

Quick tunnels are temporary and have no uptime guarantee.

For production, create a managed tunnel with a Cloudflare account and origin certificate.



---

**7) Troubleshooting (real issues we encountered + fixes)**

**A.** ERR_NGROK_121 — "agent version too old"

Symptom: Your ngrok-agent version "2.x" is too old. Minimum is "3.x"

Fix: Remove old binary and install ngrok v3 (see section 1). Verify ngrok version shows 3.x.

**B.** ERR_NGROK_4018 — "Install your authtoken"

Symptom: ngrok says you must install an authtoken even after running authtoken command.

Cause: ngrok v2 saved token to ~/.ngrok2/ngrok.yml while v3 expects ~/.config/ngrok/ngrok.yml.

Fix:
```
mkdir -p ~/.config/ngrok
cp ~/.ngrok2/ngrok.yml ~/.config/ngrok/ngrok.yml 2>/dev/null || true
cat ~/.config/ngrok/ngrok.yml
```
Or re-run:
```
ngrok config add-authtoken <YOUR_AUTHTOKEN>
```

**C.** "failed to get home directory" / user: Current requires cgo or $USER set

Symptom: ngrok prints a WARN about home directory and $USER.

Fix (cosmetic / safe):
```
export USER=$(whoami)
echo 'export USER=$(whoami)' >> ~/.bashrc
```
This avoids the warning and ensures tools that read $USER work predictably.

**D.** lsof "cannot locate symbol getrpcbynumber"

Symptom: lsof binary is broken on some Termux installs.

Fix: Use ps + grep to find processes (see examples), or use the /proc and fd tricks (but note /proc/net/tcp may be permission restricted on unrooted Android).

Examples:

ps aux | grep http.server
kill -9 <PID>

**E.** ss / netstat permission denied or unsupported

Cause: Android restricts raw netlink and AF_INET sockets for normal apps.

Workaround: use ps to find and kill Termux processes (we provide helper scripts below).

**F.** Connection instability / high packet loss

Symptoms: ngrok reconnecting, timeouts, or cloudflared stream cancels.

Fixes:

Try Wi‑Fi or different mobile network / hotspot.

Use a VPN or switch to cloudflared.

Reduce large file transfers through the tunnel (mobile networks can drop large requests).



---

**8) Handy scripts (paste into Termux and chmod +x)**

**8.1** install_ngrok_v3.sh — auto install (arm64/arm)
```
#!/data/data/com.termux/files/usr/bin/env bash
set -e
ARCH=$(uname -m)
BIN=""
if [ "$ARCH" = "aarch64" ]; then
  BIN="ngrok-v3-stable-linux-arm64.tgz"
else
  BIN="ngrok-v3-stable-linux-arm.tgz"
fi
URL="https://bin.equinox.io/c/bNyj1mQVY4c/$BIN"
rm -f "$PREFIX/bin/ngrok"
wget "$URL"
tar -xvzf "$BIN"
chmod +x ngrok
mv ngrok "$PREFIX/bin/"
ngrok version
echo "ngrok installed to $PREFIX/bin/ngrok"
```

**8.2** start_http_ngrok.sh — start python server + ngrok
```
#!/data/data/com.termux/files/usr/bin/env bash
PORT=${1:-8080}
# start python server in background
nohup python3 -m http.server "$PORT" >/dev/null 2>&1 &
PID=$!
echo "Python server started (PID $PID) on port $PORT"
# start ngrok
ngrok http --config ~/.config/ngrok/ngrok.yml $PORT
```

**8.3** start_ssh_ngrok.sh — start sshd + ngrok tcp
```
#!/data/data/com.termux/files/usr/bin/env bash
pkg install -y openssh
# set password if needed
# passwd
sshd
sleep 1
ps aux | grep sshd
ngrok tcp --config ~/.config/ngrok/ngrok.yml 8022
```

**8.4** kill_termux_procs.sh — kill all Termux-owned processes (safe)
```
#!/data/data/com.termux/files/usr/bin/env bash
ME=$$
PP=$PPID
USER=$(whoami)
for pid in $(ps aux | awk -v u="$USER" 'NR>1 && $1==u {print $2}'); do
  if [ "$pid" != "$ME" ] && [ "$pid" != "$PP" ]; then
    echo "Killing $pid -> $(ps -p $pid -o cmd= 2>/dev/null)"
    kill -9 $pid 2>/dev/null || true
  fi
done

echo "Done."
```
**8.5** ngrok_removal.sh:to remove ngrok and all related files/packages 

```
#!/data/data/com.termux/files/usr/bin/bash
# Script to remove ngrok (all versions) and related packages in Termux

echo "[*] Stopping any running ngrok processes..."
pkill -9 ngrok 2>/dev/null
pkill -9 ngrokv3 2>/dev/null
pkill -9 ngrokd 2>/dev/null

echo "[*] Removing ngrok binaries..."
rm -f $PREFIX/bin/ngrok
rm -f $PREFIX/bin/ngrokv3
rm -f $PREFIX/bin/ngrokd

echo "[*] Searching and removing ngrok-related files..."
find $PREFIX -type f -iname "ngrok*" -exec rm -f {} \; 2>/dev/null
find $HOME -type f -iname "ngrok*" -exec rm -f {} \; 2>/dev/null

echo "[*] Checking if ngrok was installed via packages..."
pkg uninstall -y ngrok 2>/dev/null || true
pkg uninstall -y ngrok2 2>/dev/null || true
pkg uninstall -y ngrok3 2>/dev/null || true

echo "[*] Cleaning up..."
hash -r

echo "[✔] ngrok and all its versions/packages have been removed!"
```


---

**9) Security & best practices**

Do not expose critical services without authentication or key-based SSH access.

When exposing SSH, prefer key-based logins and disable password auth in /data/data/com.termux/home/.ssh/sshd_config.

Be mindful of data privacy when tunneling large files through public tunnels.



---

**10) Attribution / Copyright**

This repository contains documentation and helper scripts only. The following third-party tools are used but are not included in this repo and remain the property of their respective authors:

ngrok (https://ngrok.com)

cloudflared / Cloudflare (https://developers.cloudflare.com)

Termux packages



---

**11) Appendix — common commands quick reference**

- **install ngrok v3 (arm64)**
  
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz
tar -xvzf ngrok-v3-stable-linux-arm64.tgz
chmod +x ngrok
mv ngrok $PREFIX/bin/

- **add token**
  
mkdir -p ~/.config/ngrok
ngrok config add-authtoken <AUTHTOKEN>

- **if saved to old path, copy it**

cp ~/.ngrok2/ngrok.yml ~/.config/ngrok/ngrok.yml 2>/dev/null || true

- **start http server**
  
python3 -m http.server 8080

- **start tunnel**

ngrok http --config ~/.config/ngrok/ngrok.yml 8080

- **SSH (Termux)**
  
pkg install openssh -y
sshd
ngrok tcp --config ~/.config/ngrok/ngrok.yml 8022

- **cloudflared quick tunnel**
  
pkg install cloudflared -y
cloudflared tunnel --url http://localhost:8080


---
## **📜License**

Copyright (c) 2025 Yogesh R. Chauhan

This project contains original scripts and documentation created to simplify the use of
ngrok v3, cloudflared, and related tools inside Termux (Android).

All third-party software, including but not limited to **ngrok**, **scapy**, and other 
dependencies, are the property of their respective authors and license holders.  
This repository does not claim ownership over them.

The scripts and documentation in this repository are released under the MIT License, 
permitting free use, modification, and distribution, provided that this copyright 
notice is included.

Third-party software must be used according to their own licenses.



This project is licensed under the 
[MIT License](LICENSE).
You are free to use, modify, and distribute it with proper attribution.

---

## **📜Credits**

Developed by **[mikey-7x](https://github.com/mikey-7x)** 🚀🔥  


[other repository](https://github.com/mikey-7x?tab=repositories)



---



