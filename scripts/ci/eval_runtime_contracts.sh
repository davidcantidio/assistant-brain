#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

search_re() {
  local pattern="$1"
  shift
  if command -v rg >/dev/null 2>&1; then
    rg -n -- "$pattern" "$@" >/dev/null
  else
    grep -nE -- "$pattern" "$@" >/dev/null
  fi
}

required_files=(
  "META/DOCUMENT-HIERARCHY.md"
  "PRD/PRD-MASTER.md"
  "ARC/ARC-CORE.md"
  "ARC/schemas/openclaw_runtime_config.schema.json"
  "SEC/SEC-POLICY.md"
  "PM/DECISION-PROTOCOL.md"
  "ARC/ARC-HEARTBEAT.md"
  "workspaces/main/HEARTBEAT.md"
  "workspaces/main/MEMORY.md"
  "workspaces/main/.openclaw/workspace-state.json"
  "PRD/CHANGELOG.md"
)
for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || { echo "Arquivo obrigatorio ausente: $f"; exit 1; }
done

python3 -m json.tool ARC/schemas/openclaw_runtime_config.schema.json >/dev/null

python3 - <<'PY'
import datetime as dt
import json
import pathlib
import re
import sys

path = pathlib.Path("workspaces/main/.openclaw/workspace-state.json")
try:
    data = json.loads(path.read_text(encoding="utf-8"))
except Exception as exc:
    print(f"workspace-state invalido: {path}: {exc}")
    sys.exit(1)

version = data.get("version")
if not isinstance(version, int) or version < 1:
    print("workspace-state invalido: campo 'version' deve ser inteiro >= 1.")
    sys.exit(1)

seeded = data.get("bootstrapSeededAt")
if not isinstance(seeded, str):
    print("workspace-state invalido: campo 'bootstrapSeededAt' ausente ou nao-string.")
    sys.exit(1)

if not re.match(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z$", seeded):
    print("workspace-state invalido: 'bootstrapSeededAt' deve estar em ISO-8601 UTC (terminando com 'Z').")
    sys.exit(1)

try:
    dt.datetime.fromisoformat(seeded.replace("Z", "+00:00"))
except ValueError:
    print("workspace-state invalido: 'bootstrapSeededAt' nao representa timestamp valido.")
    sys.exit(1)
PY

# Canonical precedence
search_re "felixcraft\.md" META/DOCUMENT-HIERARCHY.md

# Runtime contract and A2A/hooks
search_re 'Contrato Canonico `openclaw_runtime_config`' PRD/PRD-MASTER.md
search_re "tools\.agentToAgent\.enabled" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "tools\.agentToAgent\.allow\[\]" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "hooks\.enabled" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "hooks\.mappings\[\]" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "hooks\.internal\.entries\[\]" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "gateway\.bind = loopback" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "gateway\.control_plane\.ws" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "chatCompletions" PRD/PRD-MASTER.md ARC/ARC-CORE.md

# Memory lifecycle contract
search_re 'Contrato `memory_contract`' PRD/PRD-MASTER.md
search_re "nightly-extraction" PRD/PRD-MASTER.md ARC/ARC-HEARTBEAT.md
search_re 'name: "nightly-extraction"' PRD/PRD-MASTER.md
search_re 'schedule: "0 23 \* \* \*"' PRD/PRD-MASTER.md
search_re 'timezone: "America/Sao_Paulo"' PRD/PRD-MASTER.md
search_re "required: true" PRD/PRD-MASTER.md
search_re "workspaces/main/MEMORY\.md" PRD/PRD-MASTER.md META/DOCUMENT-HIERARCHY.md
if ! ls workspaces/main/memory/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md >/dev/null 2>&1; then
  echo "Nenhuma nota diaria encontrada em workspaces/main/memory/YYYY-MM-DD.md"
  exit 1
fi
python3 - <<'PY'
import glob
import re
import sys

daily_files = sorted(glob.glob("workspaces/main/memory/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md"))
required_sections = ("Key Events", "Decisions Made", "Facts Extracted")
errors = []

for path in daily_files:
    text = open(path, "r", encoding="utf-8", errors="ignore").read().splitlines()
    if not text or not re.match(r"^#\s+\d{4}-\d{2}-\d{2}\s*$", text[0].strip()):
        errors.append(f"{path}: cabecalho diario invalido (esperado '# YYYY-MM-DD').")
        continue

    bullets = {section: 0 for section in required_sections}
    current = None
    for line in text:
        m = re.match(r"^##\s+(Key Events|Decisions Made|Facts Extracted)\s*$", line.strip())
        if m:
            current = m.group(1)
            continue
        if current and re.match(r"^\s*-\s+\S+", line):
            bullets[current] += 1

    for section in required_sections:
        if bullets.get(section, 0) == 0:
            errors.append(f"{path}: secao '{section}' sem bullet obrigatorio.")

if errors:
    for err in errors:
        print(err)
    sys.exit(1)
PY

# Channel trust + financial hard gate
search_re "email.*nunca.*canal confiavel de comando|canal nao confiavel para comando" PRD/PRD-MASTER.md SEC/SEC-POLICY.md PM/DECISION-PROTOCOL.md
search_re "aprovacao humana explicita" PRD/PRD-MASTER.md SEC/SEC-POLICY.md VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-RISK-RULES.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md

# Heartbeat baseline alignment
search_re "baseline unico de 15 minutos|base global: 15 minutos" ARC/ARC-HEARTBEAT.md
search_re "Baseline oficial: 15 minutos" workspaces/main/HEARTBEAT.md
search_re "America/Sao_Paulo" ARC/ARC-HEARTBEAT.md PRD/PRD-MASTER.md workspaces/main/HEARTBEAT.md
search_re "Nightly extraction de memoria: 23:00" ARC/ARC-HEARTBEAT.md
search_re "23:00 \\(America/Sao_Paulo\\).*nightly extraction" workspaces/main/HEARTBEAT.md
search_re "override deliberado de timezone.*America/Sao_Paulo" PRD/CHANGELOG.md

echo "eval-runtime-contracts: PASS"
