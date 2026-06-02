#!/usr/bin/env bash
# Sync the local build into the launchd-readable runtime copy.
#
# Why this exists: launchd jobs cannot read ~/Documents/ without TCC grant.
# `restic-mba-backup.zsh` refuses to run ai-vault if its binary resolves into
# ~/Documents/. Keeping a production copy at ~/.local/share/ai-vault-runtime/
# avoids that without touching TCC.
#
# Called from npm `postbuild`. Idempotent.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RUNTIME="${AI_VAULT_RUNTIME_DIR:-$HOME/.local/share/ai-vault-runtime}"

if [[ ! -d "$ROOT/dist" ]]; then
  echo "sync-runtime: $ROOT/dist not found (run build first)" >&2
  exit 1
fi

mkdir -p "$RUNTIME"
rsync -a --delete "$ROOT/dist/" "$RUNTIME/dist/"
rsync -a "$ROOT/package.json" "$RUNTIME/package.json"

# node_modules is large; only sync if missing or visibly stale (package.json mtime newer).
if [[ ! -d "$RUNTIME/node_modules" || "$ROOT/package.json" -nt "$RUNTIME/node_modules/.package-lock.json" ]]; then
  echo "sync-runtime: refreshing node_modules (this is slow)"
  rsync -a --delete "$ROOT/node_modules/" "$RUNTIME/node_modules/"
fi

chmod +x "$RUNTIME/dist/cli.js"
echo "sync-runtime: $RUNTIME up to date"
