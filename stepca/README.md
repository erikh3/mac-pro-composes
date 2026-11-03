Custom self-hosted certificate authority.

0. Create step dirs & passwords

```shell
mkdir -p step
mkdir -p ~/.config/custom/step-ca/secrets
```

```shell
echo "pass" > ~/.config/custom/step-ca/secrets/ca-password
echo "pass" > ~/.config/custom/step-ca/secrets/default-jwk-password
```

1. Start compose

```shell
docker compose up -d
```

2. Add smallstep on host & trust root cert

Confirm adding the cert to keychain with your user password.
Run script in the `step-ca` directory.

```shell
CA_FINGERPRINT=$(docker run --rm -v ./step:/home/step smallstep/step-ca step certificate fingerprint /home/step/certs/root_ca.crt)
step ca bootstrap --ca-url https://localhost:9000 --fingerprint $CA_FINGERPRINT --install
```

output:

```
✔ Would you like to overwrite /Users/xxx/.step/certs/root_ca.crt [y/n]: y
The root certificate has been saved in /Users/xxx/.step/certs/root_ca.crt.
✔ Would you like to overwrite /Users/xxx/.step/config/defaults.json [y/n]: y
The authority configuration has been saved in /Users/xxx/.step/config/defaults.json.
Installing the root certificate in the system truststore... Password:
done.
```

The CA root certificate will be added to KeyChain => System Keychains => System => Certificates => `mac-pro-composes-step-ca Root CA`

3. Check REST API health and whether host system trusts CA

https://127.0.0.1:9000/health

```shell
curl https://127.0.0.1:9000/health
```

4. Update provisioners

Needs to be run inside the container (which has volume mounted in correct place).

#### ACME

```shell
docker run \
   --rm \
   -v ./step:/home/step smallstep/step-ca \
   step ca provisioner update acme \
   --challenge tls-alpn-01 \
   --challenge http-01 \
   --x509-default-dur=10000h
```

#### default JWK

```shell
docker run \
   --rm \
   -v ./step:/home/step smallstep/step-ca \
   step ca provisioner update default-jwk \
   --x509-max-dur 80000h \
   --x509-default-dur 40000h
```

- https://smallstep.com/docs/step-cli/reference/ca/provisioner/index.html

5. Restart the container so that acme provisioner changes apply

```shell
docker compose restart
```

6. Generate certificate manually using default JWK (JSON Web key) provisioner

```shell
MOUNT_BASE_PATH=/home/service-certs
CONTAINER_ID=$(docker container ls -q --filter "label=one.dify.stepca=true" --filter "status=running")
docker exec -t $CONTAINER_ID bash -c "step ca certificate shared-localhost-stepca \
   --san localhost --san 127.0.0.1 \
   --san homepage.localhost \
   --san firefox.localhost \
   --san obsidian.localhost \
   --san syncthing.localhost \
   --san it-tools.localhost --san traefik.localhost --san step-ca.localhost \
   --not-after 8000h \
   $MOUNT_BASE_PATH/localhost.crt \
   $MOUNT_BASE_PATH/localhost.key \
   --provisioner default-jwk \
   --provisioner-password-file /run/secrets/default-jwk-provisioner-password \
   --force"
```

- https://smallstep.com/docs/step-cli/reference/ca/certificate/index.html

SANs contain hostnames or IP addresses, never ports. Use `8000h` for server certificates.
The previous `40000h` certificate failed native macOS SSL validation; `8000h` passed.

7. Install certs to apps

Install `service-certs/localhost.crt` as `config/ssl/cert.pem` and
`service-certs/localhost.key` as `config/ssl/cert.key` in Obsidian.
Firefox uses a named volume, so copy directly into its running container:

```shell
docker compose cp stepca/service-certs/localhost.crt firefox:/config/ssl/cert.pem
docker compose cp stepca/service-certs/localhost.key firefox:/config/ssl/cert.key
docker compose restart --no-deps firefox
```

Run those commands from the repository root. The distribution script still targets
the old Firefox host-mounted configuration and does not populate its named volume.

Traefik expects `traefik/traefik/service-certs/localhost.pem` and `localhost.key`.
Copy the server certificate there as `localhost.pem`. If this directory is a symlink
to `stepca/service-certs`, only the `.crt` to `.pem` copy is needed.
Copy `step/certs/root_ca.crt` into `traefik/traefik/ca-certs` for client authentication.
Restart Traefik after changing its certificates or client trust roots.

## macOS user trust

If `step ca bootstrap --install` cannot use sudo, install the root in the login keychain:

```shell
security add-trusted-cert -r trustRoot -k "$HOME/Library/Keychains/login.keychain-db" stepca/step/certs/root_ca.crt
```

This trusts the CA for the current user, not system-wide.

## Client certificate authentication

Homepage, IT Tools, Syncthing, Firefox, and Obsidian routes require a client certificate
signed by the CA in `traefik/traefik/ca-certs`. Keep client private keys outside
`stepca/service-certs`, which is mounted into Traefik.

For the local setup, the client certificate, key, and encrypted browser-import bundle
are stored in `~/.config/custom/mac-pro-composes/client`. The bundle is `client.p12`;
its password is in `bundle-password`. The client identity is imported into the macOS
login keychain for Chrome. Firefox can import the bundle through its certificate settings.
New server and client certificates use `8000h` validity.

