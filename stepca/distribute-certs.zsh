#!/usr/bin/env zsh

CERT_FILE_PATH="service-certs/localhost.crt"
KEY_FILE_PATH="service-certs/localhost.key"

if [[ ! -f "$CERT_FILE_PATH" ]]; then
  echo "No $CERT_FILE_PATH found, generate certificate & key first."
  exit 1
fi

if [[ ! -f "$KEY_FILE_PATH" ]]; then
  echo "No $KEY_FILE_PATH found, generate certificate & key first."
  exit 1
fi

# Distribute the certs to the right places

BACKUP_DATE=$(date +"%Y-%m-%dT%H:%M:%S")

# Firefox

FIREFOX_SSL_PATH="firefox/firefox/config/ssl"
FIREFOX_CERT_PATH="../$FIREFOX_SSL_PATH/cert.pem"
FIREFOX_KEY_PATH="../$FIREFOX_SSL_PATH/cert.key"

echo "Distributing certificate to $FIREFOX_SSL_PATH"

if [[ -f "$FIREFOX_CERT_PATH" ]]; then
  echo "Backing up existing certificate at $FIREFOX_CERT_PATH => $FIREFOX_CERT_PATH.$BACKUP_DATE"
  mv "$FIREFOX_CERT_PATH" "$FIREFOX_CERT_PATH.$BACKUP_DATE"
fi
cp "$CERT_FILE_PATH" "$FIREFOX_CERT_PATH"

if [[ -f "$FIREFOX_KEY_PATH" ]]; then
  echo "Backing up existing key at $FIREFOX_KEY_PATH => $FIREFOX_KEY_PATH.$BACKUP_DATE"
  mv "$FIREFOX_KEY_PATH" "$FIREFOX_KEY_PATH.$BACKUP_DATE"
fi
cp "$KEY_FILE_PATH" "$FIREFOX_KEY_PATH"

# Obsidian

OBSIDIAN_SSL_PATH="obsidian/obsidian/config/ssl"
OBSIDIAN_CERT_PATH="../$OBSIDIAN_SSL_PATH/cert.pem"
OBSIDIAN_KEY_PATH="../$OBSIDIAN_SSL_PATH/cert.key"

echo "Distributing certificate to $OBSIDIAN_SSL_PATH"

if [[ -f "$OBSIDIAN_CERT_PATH" ]]; then
  echo "Backing up existing certificate at $OBSIDIAN_CERT_PATH => $OBSIDIAN_CERT_PATH.$BACKUP_DATE"
  mv "$OBSIDIAN_CERT_PATH" "$OBSIDIAN_CERT_PATH.$BACKUP_DATE"
fi
cp "$CERT_FILE_PATH" "$OBSIDIAN_CERT_PATH"

if [[ -f "$OBSIDIAN_KEY_PATH" ]]; then
  echo "Backing up existing key at $OBSIDIAN_KEY_PATH => $OBSIDIAN_KEY_PATH.$BACKUP_DATE"
  mv "$OBSIDIAN_KEY_PATH" "$OBSIDIAN_KEY_PATH.$BACKUP_DATE"
fi
cp "$KEY_FILE_PATH" "$OBSIDIAN_KEY_PATH"
