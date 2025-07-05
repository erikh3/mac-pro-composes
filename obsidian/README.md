Personal knowledge data lake based on awesome [Obsidian](https://obsidian.md/).

# stepca certificates

~~Replace certificates from `service-certs` to `firefox/config/ssl`.~~

```shell
cd stepca && ./distribute-certs.zsh
```

# Start

```shell
docker compose --profile obsidian up -d
```

# Open Obsidian

[https://localhost:3101](https://localhost:3101) or [https://obsidian.localhost](https://obsidian.localhost)

# Update

## All images

```shell
docker compose --profile obsidian pull
```

## Obsidian image

```shell
docker compose --profile obsidian pull obsidian
```

## Update all containers

```shell
docker compose --profile obsidian up -d
```

## Obsidian container

```shell
docker compose up --profile obsidian -d obsidian
```
