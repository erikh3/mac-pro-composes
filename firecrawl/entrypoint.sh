#!/bin/sh
# Firecrawl api entrypoint: map docker secrets (mounted at /run/secrets) to the
# environment variables Firecrawl expects, then exec the harness command.
# Same pattern as gluetun/entrypoint.sh in this project.
#
# Optional provider secrets (openai-api-key, proxy-password) may be empty files;
# empty/missing secrets are skipped so LLM/proxy stay optional.
set -e

export_secret() {
  _file="/run/secrets/$1"
  _var="$2"
  if [ -s "$_file" ]; then
    export "$_var=$(cat "$_file")"
  fi
}

if [ ! -s /run/secrets/firecrawl-postgres-password ]; then
  echo "[firecrawl-entrypoint] ERROR: postgres-password secret is missing or empty." >&2
  echo "[firecrawl-entrypoint] Create it under \${FIRECRAWL_SECRETS_BASE_DIR}/postgres-password (see firecrawl/README.md)." >&2
  exit 1
fi

export_secret firecrawl-postgres-password POSTGRES_PASSWORD
export_secret firecrawl-openai-api-key OPENAI_API_KEY
export_secret firecrawl-proxy-password PROXY_PASSWORD

exec "$@"
