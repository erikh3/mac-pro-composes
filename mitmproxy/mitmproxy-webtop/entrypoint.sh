#!/usr/bin/env bash

if [[ -f /usr/share/ca-certificates/extra/mitmproxy-ca-cert.pem ]]; then
    echo "Adding mitmproxy CA certificate to trusted certificates..."
    openssl x509 -in /usr/share/ca-certificates/extra/mitmproxy-ca-cert.pem -inform PEM -out /usr/share/ca-certificates/extra/mitmproxy-ca-cert.crt
    update-ca-certificates
    echo "mitmproxy CA certificate added successfully"
fi

# start actual entrypoint
exec /init "$@"
