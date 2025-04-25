# mac-pro-composes

A collection of compose configs.

# How to run

## Run everything

```zsh
COMPOSE_STACKS=(homepage it-tools)

for stack in $COMPOSE_STACKS; do
    (cd $stack; docker compose up -d)
done;
```

## Run individual composes

- [homepage](homepage/README.md)
- [it-tools](it-tools/README.md)
