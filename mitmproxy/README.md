# Mitmproxy

This submodule sets up `mitmproxy` with a `gluetun` VPN and a `webtop` GUI.

## Services

- `mitmproxy`: The core `mitmproxy` service. It provides a web interface for inspecting traffic.
- `mitmproxy-gluetun`: A `gluetun` service that provides a Wireguard VPN connection. All traffic from `mitmproxy-webtop` is routed through this container.
- `mitmproxy-webtop`: A `webtop` service that provides a full Linux desktop environment in web browser. It's configured to use the `mitmproxy-gluetun` VPN connection.

## Usage

Run the services using Docker Compose profiles.

### Headless (VPN only)

To run `mitmproxy` with only the `gluetun` VPN service:

```shell
docker compose --profile mitmproxy-gluetun up -d
```

### Webtop (VPN + Desktop GUI)

To run `mitmproxy` with the `gluetun` VPN and the `webtop` desktop environment:

```shell
docker compose --profile mitmproxy-webtop up -d
```

## Configuration

### Wireguard VPN

1.  After running the `mitmproxy` service for the first time, it will generate a Wireguard configuration.
2.  Access the `mitmproxy` web interface at [https://proxy.mitm.localhost](proxy.mitm.localhost).
3.  Go to the "Capture" tab and download the Wireguard configuration.
4.  Save Wireguard configuration to a file `mitmproxy-gluetun/wg0.conf`.
5.  Restart the services.

### Mitmproxy CA Certificate

The `mitmproxy` CA certificate is required to intercept HTTPS traffic. The certificate is generated on the first run and is located at `mitmproxy/config/mitmproxy-ca-cert.pem`.

This certificate is automatically mounted into the `mitmproxy-gluetun` and `mitmproxy-webtop` services. To use the certificate in your browser or on your system, you need to import it into your trust store.

## Accessing Web Interfaces

- **Mitmproxy Web UI**: [https://proxy.mitm.localhost](proxy.mitm.localhost)
- **Mitmproxy Webtop**: [https://webtop.mitm.localhost](webtop.mitm.localhost)
