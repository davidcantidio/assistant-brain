#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

PDF_PATH="felixcraft.pdf"
MD_PATH="felixcraft.md"

log_info() { echo "INFO[pdf-md-sync]: $*"; }
log_warn() { echo "WARN[pdf-md-sync]: $*" >&2; }
log_fail() { echo "FAIL[pdf-md-sync]: $*" >&2; }

resolve_range() {
  local base_ref range

  if [[ -n "${GITHUB_BASE_REF:-}" ]]; then
    base_ref="${GITHUB_BASE_REF}"

    if git rev-parse --verify --quiet "origin/${base_ref}" >/dev/null; then
      echo "origin/${base_ref}...HEAD"
      return 0
    fi

    if git rev-parse --verify --quiet "${base_ref}" >/dev/null; then
      echo "${base_ref}...HEAD"
      return 0
    fi

    log_warn "base ref '${base_ref}' nao encontrado; fallback para range de push."
  fi

  if git rev-parse --verify --quiet HEAD~1 >/dev/null; then
    echo "HEAD~1...HEAD"
    return 0
  fi

  return 1
}

if ! RANGE="$(resolve_range)"; then
  log_info "historico insuficiente para diff range; policy nao aplicavel."
  exit 0
fi

if ! CHANGED_FILES="$(git diff --name-only "$RANGE" --)"; then
  log_warn "falha ao calcular diff para range '$RANGE'; policy nao aplicavel."
  exit 0
fi

if [[ -z "$CHANGED_FILES" ]]; then
  log_info "nenhuma mudanca detectada no range '$RANGE'; policy nao aplicavel."
  exit 0
fi

pdf_changed=0
md_changed=0

while IFS= read -r file; do
  [[ "$file" == "$PDF_PATH" ]] && pdf_changed=1
  [[ "$file" == "$MD_PATH" ]] && md_changed=1
done <<< "$CHANGED_FILES"

if [[ "$pdf_changed" -eq 0 ]]; then
  log_info "PDF alvo nao mudou no range '$RANGE'; policy nao aplicavel."
  exit 0
fi

if [[ "$md_changed" -eq 0 ]]; then
  log_fail "'${PDF_PATH}' mudou sem '${MD_PATH}'. Rode make pdf-to-md e commite ${MD_PATH}."
  exit 1
fi

log_info "co-mudanca validada: '${PDF_PATH}' e '${MD_PATH}' alterados no range '$RANGE'."
exit 0
