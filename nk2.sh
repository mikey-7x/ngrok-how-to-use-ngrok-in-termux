#!/data/data/com.termux/files/usr/bin/env bash
# Start SSH server
sshd

# Wait for sshd to initialize
sleep 2

# Show running sshd processes
ps aux | grep sshd

# Run ngrok TCP tunnel on port 8022 (Termux SSH default)
# ⚠️ Change "8022" to your actual sshd port if needed
ngrok tcp 8022
