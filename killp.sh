#!/data/data/com.termux/files/usr/bin/bash
# kill_termux_procs.sh
# Show Termux-owned processes and ask before killing them (excludes this shell).

USER="$(whoami)"
ME=$$
PP=$PPID

echo "[*] Termux user: $USER"
echo "[*] Current shell PID: $ME  Parent PID: $PP"
echo

# Collect PIDs owned by this user (exclude header)
PIDS=$(ps aux | awk -v u="$USER" 'NR>1 && $1==u {print $2}')

if [ -z "$PIDS" ]; then
  echo "[*] No Termux processes found for user $USER."
  exit 0
fi

echo "Found the following Termux processes (PID : CMD):"
for pid in $PIDS; do
  # skip this shell and its parent
  if [ "$pid" -eq "$ME" ] || [ "$pid" -eq "$PP" ]; then
    continue
  fi
  cmd=$(ps -p "$pid" -o cmd= 2>/dev/null)
  echo "  $pid : ${cmd:-[unknown]}"
done

echo
read -p "Kill all listed processes? (y/N) " ans
case "$ans" in
  y|Y)
    for pid in $PIDS; do
      if [ "$pid" -eq "$ME" ] || [ "$pid" -eq "$PP" ]; then
        continue
      fi
      kill -9 "$pid" 2>/dev/null && echo "killed $pid" || echo "failed to kill $pid"
    done
    echo "[*] Done."
    ;;
  *)
    echo "[*] Aborted. No processes were killed."
    ;;
esac
