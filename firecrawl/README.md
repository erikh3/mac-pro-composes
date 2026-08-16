# Firecrawl

Self-hosted [Firecrawl](https://github.com/firecrawl/firecrawl) — a web
scraping/crawling API (scrape, crawl, map, search → clean markdown / structured
data) designed to be consumed by AI agents.

This stack mirrors the upstream self-host Docker Compose, using **prebuilt ghcr
images** (no source build) and the **PostgreSQL (NuQ) queue backend**. The
experimental FoundationDB backend is intentionally omitted.

## Services

All gated behind the `firecrawl` compose profile, on a private `firecrawl`
bridge network. Only `firecrawl-api` is published and also joins the shared
`mac-pro-composes` network.

| Service | Image | Purpose |
|---|---|---|
| `firecrawl-api` | `ghcr.io/firecrawl/firecrawl` | API + in-process workers; bound to `127.0.0.1:3002` |
| `firecrawl-playwright` | `ghcr.io/firecrawl/playwright-service` | Headless-browser rendering |
| `firecrawl-redis` | `redis:alpine` | Cache / rate-limit |
| `firecrawl-rabbitmq` | `rabbitmq:3-management` | Queue transport |
| `firecrawl-nuq-postgres` | `ghcr.io/firecrawl/nuq-postgres` | NuQ queue backend (bundles `pg_cron`) |

## Image pinning

The `firecrawl` (api) image publishes semver tags and is pinned via
`FIRECRAWL_TAG` (default `2.11.202`). The `playwright-service` and `nuq-postgres`
images publish **only `latest`** (no semver), matching upstream's own compose
image references. For reference, the `latest` digests at the time of writing:

- `playwright-service`: `sha256:468009bae00911d40d7120d58489a1d529362c22c45585cb9076094fe61b0025`
- `nuq-postgres`: `sha256:aed86f62858f29bd971abddcdeb301c12888098d2cf5d33c1ba42b053bc460f6`

Pin these by digest in `.env` (e.g. `PLAYWRIGHT_TAG=latest@sha256:...` is not
valid; use `PLAYWRIGHT_IMAGE=ghcr.io/firecrawl/playwright-service@sha256:...`
with an empty tag) if you need full reproducibility.

## Run

The stack is **opt-in** — it is not in the repo's default `COMPOSE_PROFILES`, so
`docker compose up -d` alone does not start it.

```shell
# Change POSTGRES_PASSWORD in firecrawl/.env first.
docker compose --profile firecrawl up -d
```

Once started, `restart: unless-stopped` keeps it running across Docker/host
restarts. Stop it with:

```shell
docker compose --profile firecrawl down
```

## Use it (AI agents)

The API is unauthenticated and bound to `127.0.0.1:3002` (trusted local machine).
No API key or `Authorization` header is needed.

Health check:

```shell
curl --fail --silent http://localhost:3002/v0/health/readiness
# {"status":"ok"}
```

Scrape smoke test:

```shell
curl --fail-with-body --silent -X POST http://localhost:3002/v2/scrape \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://example.com","formats":["markdown"],"timeout":60000}'
```

### Connect a client

- **Firecrawl MCP server** / SDKs / CLI: point the API base URL at
  `http://localhost:3002`.
- SDKs: set `api_url="http://localhost:3002"` (and any dummy API key, since auth
  is disabled).

## What works / what needs more

| Capability | Status |
|---|---|
| `scrape`, `crawl`, `map`, `search` | ✅ included (fetch + Playwright) |
| `/extract`, LLM-structured formats | needs an OpenAI-compatible endpoint or Ollama — set `OPENAI_*` / `OLLAMA_BASE_URL` in `.env` |
| Screenshots, page actions | ❌ require Fire-engine (not included) |

## Notes

- **No persistence.** Redis/RabbitMQ/Postgres run without volumes; in-flight
  async crawl state is lost on restart. Scrape responses are returned to the
  caller regardless.
- **Resources.** Defaults reserve up to `FIRECRAWL_API_MEM` (8G) +
  `PLAYWRIGHT_MEM` (4G). Ensure the Docker Desktop VM has enough RAM, or lower
  them in `.env`.
- **Postgres password** lives in `.env` (Firecrawl reads it via env, not a file
  secret). It is internal-only on the private network; still change the default.
- Upgrade by bumping `FIRECRAWL_TAG` after reviewing the target release's
  [`docker-compose.yaml`](https://github.com/firecrawl/firecrawl/blob/main/docker-compose.yaml)
  and [self-host guide](https://docs.firecrawl.dev/contributing/self-host).
