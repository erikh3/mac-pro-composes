# mac-pro-composes

A collection of compose configs.

Each stack has its own sub-directory.
The stack name is set to `mac-pro-comoses` for all stacks.

# How to run

First create shared network.

```shell
docker network create mac-pro-composes
```

Add any custom hostnames to `/etc/hosts`.

```
127.0.0.1   homepage
127.0.0.1	it-tools
```

Create & set custom secrets

E.g. for Firefox

```shell
mkdir -p ~/.config/custom/mac-pro-composes/firefox/secrets
cd $_
touch basic-auth-password
touch basic-auth-user
```

## Run everything

The optional services are using [compose profiles](https://docs.docker.com/compose/how-tos/profiles/) and
containers won't be created unless at least one of their profiles is activated.

The default profiles & other environment variables are pre-filled in `.env` file.

```shell
docker compose up -d
```

Enable profiles explicitly:

```shell
docker compose --profile webtop up -d
```

## Updating

Pull new image. Check in `.env` for particular image name.

```shell
docker pull lscr.io/linuxserver/obsidian:latest
```

Update that particular container.

```shell
docker compose up -d obsidian
```
