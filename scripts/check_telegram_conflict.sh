#!/usr/bin/env bash
set -euo pipefail

# Diagnostico operacional para conflito Telegram getUpdates (409).
# Regras:
# - 0 ou 1 processo gateway: seguro para iniciar/manter polling local.
# - 2+ processos gateway: conflito local provavel.
# - lock stale de sessao: risco de "session file locked" (falha operacional).
# - lock ativo de sessao: apenas aviso; pode ser normal se houver run em andamento.

count_by_pattern() {
  local pattern="$1"
  local count
  count="$(pgrep -f "$pattern" 2>/dev/null | wc -l | tr -d ' ')"
  printf "%s" "${count:-0}"
}

gateway_count="$(count_by_pattern "openclaw-gateway")"
openclaw_count="$(count_by_pattern "openclaw gateway run")"

effective_count="$gateway_count"
if [ "$openclaw_count" -gt "$effective_count" ]; then
  effective_count="$openclaw_count"
fi

sessions_dir="${HOME}/.openclaw/agents/main/sessions"
active_lock_count=0
stale_lock_count=0
declare -a active_locks
declare -a stale_locks

extract_pid_from_lock() {
  local lock_file="$1"
  sed -nE 's/.*"pid"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p' "$lock_file" | head -n 1
}

if [ -d "$sessions_dir" ]; then
  while IFS= read -r -d '' lock_file; do
    pid="$(extract_pid_from_lock "$lock_file" || true)"
    if [ -n "${pid:-}" ] && kill -0 "$pid" 2>/dev/null; then
      active_lock_count=$((active_lock_count + 1))
      active_locks+=("${lock_file}:${pid}")
    else
      stale_lock_count=$((stale_lock_count + 1))
      stale_locks+=("${lock_file}:${pid:-unknown}")
    fi
  done < <(find "$sessions_dir" -maxdepth 1 -type f -name '*.jsonl.lock' -print0 2>/dev/null || true)
fi

echo "== Telegram conflict precheck =="
echo "openclaw-gateway processos: $gateway_count"
echo "openclaw gateway run processos: $openclaw_count"
echo "session lock ativos: $active_lock_count"
echo "session lock stale: $stale_lock_count"

if [ "$effective_count" -gt 1 ]; then
  echo "[FAIL] Multiplas instancias locais detectadas ($effective_count)."
  echo "Isso tende a causar Telegram getUpdates 409 (mesmo token em pollers concorrentes)."
  echo
  echo "Remediacao sugerida (manual):"
  echo "  1) Encerrar gateways duplicados: pkill -f openclaw-gateway"
  echo "  2) Confirmar processo unico:     ./scripts/check_telegram_conflict.sh"
  echo "  3) Subir gateway unico:          openclaw gateway run --bind loopback --port 18789 --force"
  echo
  echo "Se ainda houver 409 com processo local unico, verifique instancia remota/container usando o mesmo TELEGRAM_BOT_TOKEN."
  exit 1
fi

if [ "$stale_lock_count" -gt 0 ]; then
  echo "[FAIL] Encontrado lock de sessao stale ($stale_lock_count)."
  for entry in "${stale_locks[@]}"; do
    lock_path="${entry%%:*}"
    lock_pid="${entry##*:}"
    echo "  - stale: ${lock_path} (pid=${lock_pid})"
  done
  echo
  echo "Remediacao sugerida (manual):"
  echo "  1) Parar gateway atual (se houver)."
  echo "  2) Remover lock stale: rm -f ~/.openclaw/agents/main/sessions/*.jsonl.lock"
  echo "  3) Subir gateway: openclaw gateway run --bind loopback --port 18789 --force"
  exit 1
fi

echo "[PASS] Instancia unica detectada (0 ou 1 gateway local)."
if [ "$active_lock_count" -gt 0 ]; then
  echo "[WARN] Lock de sessao ativo detectado (${active_lock_count}); normal se houver run em andamento."
  for entry in "${active_locks[@]}"; do
    lock_path="${entry%%:*}"
    lock_pid="${entry##*:}"
    echo "  - ativo: ${lock_path} (pid=${lock_pid})"
  done
fi
echo "Pode iniciar/manter o gateway com o bot Telegram neste host."
exit 0
