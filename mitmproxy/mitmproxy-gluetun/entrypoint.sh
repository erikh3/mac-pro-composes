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

# Update ca certificates
MITMPROXY_CERT_PATH="/usr/local/share/ca-certificates/mitmproxy-ca-cert.pem"
if [ -f "$MITMPROXY_CERT_PATH" ]; then
    echo "Adding mitmproxy CA certificate to trusted certificates..."
    update-ca-certificates
else
    echo "mitmproxy CA certificate not found at $MITMPROXY_CERT_PATH, skipping."
fi

# Execute the original entrypoint
echo "Executing original entrypoint: /gluetun-entrypoint $@"
exec /gluetun-entrypoint "$@"
