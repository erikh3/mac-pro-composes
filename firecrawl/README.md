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

## Image pinning

The `firecrawl` (api) image publishes semver tags and is pinned via
`FIRECRAWL_TAG` (default `2.11.202`). The `playwright-service` and `nuq-postgres`
images publish only `latest` (no semver), matching upstream's own compose image
references.

## Setup

### 1. Create the postgres secret

Only one secret file is required. It is loaded via docker `secrets:` and mapped
to an environment variable by [`entrypoint.sh`](entrypoint.sh), and lives under
`~/.config/custom/mac-pro-composes/firecrawl/secrets`:

```shell
mkdir -p ~/.config/custom/mac-pro-composes/firecrawl/secrets
openssl rand -hex 32 > ~/.config/custom/mac-pro-composes/firecrawl/secrets/postgres-password
```

Optional provider secrets (OpenAI/Ollama key, proxy password) are sourced from
environment variables — **no files needed**. Leave them unset to disable; see
[Optional: LLM extraction](#optional-llm-extraction) to enable.

### 2. Run

Run all compose commands from the **repo root** (where the top-level
`compose.yaml` lives), not from `firecrawl/`.

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
formats need an OpenAI-compatible endpoint or Ollama:

1. Uncomment the non-secret settings (base URL, model) in [`llm.env`](llm.env).
2. Provide the key as an environment variable when starting the stack — it is
   mounted as a docker secret, never written to a tracked file:

   ```shell
   OPENAI_API_KEY=sk-... docker compose --profile firecrawl up -d
   ```

Screenshots and page actions require Fire-engine (not included).

## Optional: outbound proxy

Uncomment the non-secret settings in [`proxy.env`](proxy.env); supply the
password the same way as the LLM key: `PROXY_PASSWORD=... docker compose
--profile firecrawl up -d`.

## Notes

- **No persistence.** Redis/RabbitMQ/Postgres run without volumes; in-flight
  async crawl state is lost on restart. Scrape/search responses are returned to
  the caller regardless.
- **Resources.** Defaults reserve `FIRECRAWL_API_MEM` (3G) + `PLAYWRIGHT_MEM`
  (1G), plus ~1G for the sidecars. Verified to boot + scrape + search on this
  machine's ~6.3 GiB Docker VM with `NUQ_WORKER_COUNT=1`, but that VM is shared
  with the other stacks — raise the Docker Desktop memory allocation if you run
  them together or hit OOM (harness workers exit with code 137). `NUQ_WORKER_COUNT`
  is the main lever: it drops the harness from ~10 node processes to ~6.
- **Upgrade** by bumping `FIRECRAWL_TAG` after reviewing the target release's
  [`docker-compose.yaml`](https://github.com/firecrawl/firecrawl/blob/main/docker-compose.yaml)
  and [self-host guide](https://docs.firecrawl.dev/contributing/self-host).
