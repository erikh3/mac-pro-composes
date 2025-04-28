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

```shell
mkdir -p ~/.config/custom/mac-pro-composes/firefox/secrets
cd $_
touch basic-auth-password
touch basic-auth-user
```

## Run everything

The optional services are using [compose profiles](https://docs.docker.com/compose/how-tos/profiles/) and
containers won't be created unless at least one of their profiles is activated.

```zsh
# pick & choose which ones you want
export COMPOSE_PROFILES="it-tools,firefox"

COMPOSE_STACKS=(nginx homepage it-tools firefox)
DOCKER_CLI="docker"

for stack in $COMPOSE_STACKS; do
    (cd $stack; $DOCKER_CLI compose up -d)
done;
```

## Run individual composes

- [homepage](homepage/README.md)
- [it-tools](it-tools/README.md)
