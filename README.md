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

## Run everything

```zsh
COMPOSE_STACKS=(nginx homepage it-tools)
DOCKER_CLI="docker"

for stack in $COMPOSE_STACKS; do
    (cd $stack; $DOCKER_CLI compose up -d)
done;
```

## Run individual composes

- [homepage](homepage/README.md)
- [it-tools](it-tools/README.md)
