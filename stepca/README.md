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
   --san it-tools.localhost \
   --not-after 40000h \
   $MOUNT_BASE_PATH/localhost.crt \
   $MOUNT_BASE_PATH/localhost.key \
   --provisioner default-jwk \
   --provisioner-password-file /run/secrets/default-jwk-provisioner-password \
   --force"
```

- https://smallstep.com/docs/step-cli/reference/ca/certificate/index.html
