#!/usr/bin/env sh
set -e

echo "Loading WireGuard configuration from secret..."

WIREGUARD_CONFIG_LOCATION=${WIREGUARD_CONFIG_LOCATION:-/run/secrets/wg0.conf}

if [ -f "$WIREGUARD_CONFIG_LOCATION" ]; then
    mkdir -p /gluetun/wireguard
    cp $WIREGUARD_CONFIG_LOCATION /gluetun/wireguard/wg0.conf
    echo "WireGuard configuration loaded successfully from $WIREGUARD_CONFIG_LOCATION."
else
    echo "WireGuard configuration not found at $WIREGUARD_CONFIG_LOCATION"
    exit 1
fi

# Execute the original entrypoint
exec /gluetun-entrypoint "$@"
