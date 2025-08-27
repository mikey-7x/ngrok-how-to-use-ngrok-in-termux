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
