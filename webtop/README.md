[Webtop](https://docs.linuxserver.io/images/docker-webtop/) running as a container which is connected via Wireguard (using Gluetun container).

# Setup

Put your Wireguard config `wg0.conf` in `~/.config/custom/mac-pro-composes/gluetun/secrets/`.

In project root directory run:

```shell
docker compose up webtop gluetun -d
```
