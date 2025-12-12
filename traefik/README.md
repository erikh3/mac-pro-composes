- https://kcore.org/2023/10/30/switching-to-traefik-stepca/
- https://doc.traefik.io/traefik/https/acme/#providers
    - https://go-acme.github.io/lego/dns/acme-dns/  (note this is acme dns, not TCP!)
- https://www.benjaminrancourt.ca/a-complete-traefik-configuration/

Check from traefik conainer whether step-ca is accessible & trust can be established.

```shell
curl --cacert /home/step/certs/root_ca.crt  https://localhost:9000/health
```

# Traefik config

- https://doc.traefik.io/traefik/getting-started/configuration-overview/#the-static-configuration

## Env. vars:

- https://doc.traefik.io/traefik/reference/static-configuration/env/

# Docker labels

- https://doc.traefik.io/traefik/routing/providers/docker/

# ACME challenges

- https://doc.traefik.io/traefik/https/acme/#the-different-acme-challenges