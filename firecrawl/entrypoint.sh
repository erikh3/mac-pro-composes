#!/bin/sh
# Firecrawl api entrypoint: map the postgres docker secret (mounted at
# /run/secrets) to the env var Firecrawl expects, then exec the harness command.
# Same pattern as gluetun/entrypoint.sh in this project.
#
# Optional provider values (OPENAI_API_KEY, PROXY_PASSWORD) arrive as plain env
# vars sourced from the shell; empty/unset leaves LLM extraction / proxy off.
set -e

if [ ! -s /run/secrets/firecrawl-postgres-password ]; then
  echo "[firecrawl-entrypoint] ERROR: postgres-password secret is missing or empty." >&2
  echo "[firecrawl-entrypoint] Create it under \${FIRECRAWL_SECRETS_BASE_DIR}/postgres-password (see firecrawl/README.md)." >&2
  exit 1
fi

export POSTGRES_PASSWORD="$(cat /run/secrets/firecrawl-postgres-password)"

exec "$@"
