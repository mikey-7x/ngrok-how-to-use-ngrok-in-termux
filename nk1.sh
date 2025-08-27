#!/data/data/com.termux/files/usr/bin/env bash
set -e

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
  aarch64)
    BIN="ngrok-v3-stable-linux-arm64.tgz"
    ;;
  arm*|armv7l|armv8l)
    BIN="ngrok-v3-stable-linux-arm.tgz"
    ;;
  *)
    echo "❌ Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

# URL of ngrok v3
URL="https://bin.equinox.io/c/bNyj1mQVY4c/$BIN"

# Make sure required packages are installed
pkg install -y wget tar openssh

# Clean old ngrok
rm -f "$PREFIX/bin/ngrok"

# Download and extract ngrok
echo "⬇️ Downloading $BIN..."
wget -q "$URL" -O "$BIN"
tar -xvzf "$BIN"

# Find extracted ngrok binary and move it
if [ -f ngrok ]; then
    chmod +x ngrok
    mv ngrok "$PREFIX/bin/"
else
    if [ -d ngrok* ]; then
        cd ngrok*/
        chmod +x ngrok
        mv ngrok "$PREFIX/bin/"
        cd ..
    fi
fi

# Cleanup
rm -rf "$BIN" ngrok-v3-stable-linux-*

# Verify installation
echo "✅ ngrok installed at: $PREFIX/bin/ngrok"
ngrok version

echo "✅ openssh installed successfully"
