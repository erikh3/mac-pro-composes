#!/bin/sh

# Kudos to
# https://github.com/linuxserver/docker-obsidian/issues/38#issuecomment-4200739332
# https://forum.obsidian.md/t/obsidian-on-windows-11-keeps-crashing-without-error-messages-solved/105529

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/config/.XDG}"

# no GPU support inside the container on macos
exec /opt/obsidian/obsidian --no-sandbox --disable-gpu --disable-gpu-sandbox --in-process-gpu "$@"
