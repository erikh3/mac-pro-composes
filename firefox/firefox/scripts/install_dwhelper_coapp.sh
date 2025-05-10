#!/usr/bin/env bash

# This script installs the DWHelper CoApp package.
# https://www.downloadhelper.net/install-coapp-v2

# Redefine HOME to /config (mounted volume) instead of default /root to persist the installation across container restarts.
export HOME=/config

# Check if file exists
if [ -f /config/.mozilla/native-messaging-hosts/net.downloadhelper.coapp.json ]; then
    echo "$(date) DWHelper CoApp package already installed."
    exit 0
fi

echo "$(date) Installing DWHelper CoApp package..."

apt-get update && apt-get install -y --no-install-recommends bzip2
curl -sSLf https://github.com/aclap-dev/vdhcoapp/releases/latest/download/install.sh | bash

# Check if the installation was successful
if [ $? -ne 0 ]; then
    echo "DWHelper CoApp package installation failed."
    exit 1
fi

# Install the coapp to volume (which persists across container restarts).
exec ~/.local/share/vdhcoapp/vdhcoapp install --user
