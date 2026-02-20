#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TS="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="$ROOT/.local_backups"
OUT_FILE="$OUT_DIR/assistant-brain_${TS}.tar.gz"

mkdir -p "$OUT_DIR"
tar -czf "$OUT_FILE" \
  --exclude ".git" \
  --exclude ".local_backups" \
  -C "$ROOT" .

echo "Backup local gerado em: $OUT_FILE"
echo "Este script nao executa git add/commit/push."
