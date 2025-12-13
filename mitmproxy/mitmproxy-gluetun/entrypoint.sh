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
# https://stackoverflow.com/a/67232164
if [ -f /usr/local/share/ca-certificates/mitmproxy-ca-cert.pem ]; then
    echo "Adding mitmproxy CA certificate to trusted certificates..."
    # todo
    cat /usr/local/share/ca-certificates/mitmproxy-ca-cert.pem >> /etc/ssl/certs/ca-certificates.crt
    apk --no-cache add
fi

# Execute the original entrypoint
exec /gluetun-entrypoint "$@"
