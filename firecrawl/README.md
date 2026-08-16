# Firecrawl

Self-hosted [Firecrawl](https://github.com/firecrawl/firecrawl) — a web
scraping/crawling/search API (scrape, crawl, map, search → clean markdown /
structured data) designed to be consumed by AI agents.

Image-based mirror of the upstream self-host Docker Compose, using **prebuilt
ghcr images** (no source build), the **PostgreSQL (NuQ) queue backend**, and a
**bundled SearXNG** so `/search` works. The experimental FoundationDB backend
is intentionally omitted.

## Services

All gated behind the `firecrawl` compose profile, on a private `firecrawl`
bridge network. Only `firecrawl-api` is published and also joins the shared
`mac-pro-composes` network.

| Service | Image | Purpose |
|---|---|---|
| `firecrawl-api` | `ghcr.io/firecrawl/firecrawl` | API + in-process workers; bound to `127.0.0.1:31002` |
| `firecrawl-playwright` | `ghcr.io/firecrawl/playwright-service` | Headless-browser rendering (JS pages) |
| `firecrawl-searxng` | `searxng/searxng` | `/search` backend |
| `firecrawl-redis` | `redis:alpine` | Cache / rate-limit |
| `firecrawl-rabbitmq` | `rabbitmq:3-management` | NuQ queue transport |
| `firecrawl-nuq-postgres` | `ghcr.io/firecrawl/nuq-postgres` | NuQ queue backend (bundles `pg_cron`) |

### Why all of these?

Current Firecrawl (v2.11, NuQ architecture) **requires** the api + redis +
rabbitmq + nuq-postgres core — every endpoint (scrape/crawl/search) flows
through the NuQ queue, which is RabbitMQ (transport) + Postgres (state) + Redis
(cache). There is no redis-only mode anymore, and `nuq-postgres` is a custom
image bundling `pg_cron` and the NuQ schema (vanilla `postgres` will not work
without manual setup). `playwright` is the JS-rendering engine (plain HTTP fetch
is the weaker fallback). `searxng` is needed because self-hosted `/search`
otherwise defaults to a provider that gets IP-banned quickly.

## Image pinning

The `firecrawl` (api) image publishes semver tags and is pinned via
`FIRECRAWL_TAG` (default `2.11.202`). The `playwright-service` and `nuq-postgres`
images publish **only `latest`** (no semver), matching upstream's own compose
image references. For reference, their `latest` digests at the time of writing:

- `playwright-service`: `sha256:468009bae00911d40d7120d58489a1d529362c22c45585cb9076094fe61b0025`
- `nuq-postgres`: `sha256:aed86f62858f29bd971abddcdeb301c12888098d2cf5d33c1ba42b053bc460f6`

## Setup

### 1. Create the secrets

Secrets are loaded from files via docker `secrets:` and mapped to environment
variables by [`entrypoint.sh`](entrypoint.sh) (same pattern as the gluetun
wireguard entrypoint). They live under
`~/.config/custom/mac-pro-composes/firecrawl/secrets`.

```shell
mkdir -p ~/.config/custom/mac-pro-composes/firecrawl/secrets
cd $_
# required: a real password (32+ random chars recommended)
printf 'change-me-to-32-plus-random-characters' > postgres-password
# optional providers: create empty (disabled) or fill in to enable
touch openai-api-key    # OpenAI-compatible / Ollama API key (for /extract)
touch proxy-password    # authenticated outbound scraping proxy password
```

All three secret files must exist (empty = feature disabled) because compose
references them. Fill `openai-api-key` / `proxy-password` only if you use those
features, alongside the non-secret settings in [`llm.env`](llm.env) /
[`proxy.env`](proxy.env).

### 2. Run

The stack is **opt-in** — it is not in the repo's default `COMPOSE_PROFILES`, so
`docker compose up -d` alone does not start it.

```shell
docker compose --profile firecrawl up -d
```

`restart: unless-stopped` keeps it running across Docker/host restarts. Stop it:

```shell
docker compose --profile firecrawl down
```

## Use it (AI agents)

Unauthenticated, bound to `127.0.0.1:31002` (trusted local machine). No API key
or `Authorization` header needed.

```shell
# health
curl --fail --silent http://localhost:31002/v0/health/readiness   # {"status":"ok"}

# scrape → markdown
curl --fail-with-body --silent -X POST http://localhost:31002/v2/scrape \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://example.com","formats":["markdown"],"timeout":60000}'

# web search (via bundled SearXNG)
curl --fail-with-body --silent -X POST http://localhost:31002/v2/search \
  -H 'Content-Type: application/json' \
  -d '{"query":"firecrawl","limit":3}'
```

### Connect a client

Point the Firecrawl MCP server / SDKs / CLI at `http://localhost:31002` (use any
dummy API key, since auth is disabled).

## Optional: LLM extraction

Core scrape/crawl/map/search need no model. `/extract` and LLM-structured
formats need an OpenAI-compatible endpoint or Ollama: uncomment settings in
[`llm.env`](llm.env) and put the key in the `openai-api-key` secret. Screenshots
and page actions require Fire-engine (not included).

## Notes

- **No persistence.** Redis/RabbitMQ/Postgres run without volumes; in-flight
  async crawl state is lost on restart. Scrape/search responses are returned to
  the caller regardless.
- **Resources.** Defaults reserve up to `FIRECRAWL_API_MEM` (3G) +
  `PLAYWRIGHT_MEM` (1G). Lower `PLAYWRIGHT_CPUS` to `0.5` for minimal use
  (slower JS rendering). Ensure the Docker Desktop VM has enough RAM.
- **Proxy.** Non-secret proxy settings apply to both api and playwright; the
  proxy password secret is wired on the api.
- Upgrade by bumping `FIRECRAWL_TAG` after reviewing the target release's
  [`docker-compose.yaml`](https://github.com/firecrawl/firecrawl/blob/main/docker-compose.yaml)
  and [self-host guide](https://docs.firecrawl.dev/contributing/self-host).
