#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
import re
import sys
from pathlib import Path


def fail(msg: str) -> None:
    print(msg)
    sys.exit(1)


files = [
    Path("PM/PHASES/feito/F1-INSTALACAO-BASE-OPENCLAW/F2-POS-INSTALACAO-BASELINE-SEGURANCA/EPIC-F2-01-BASELINE-SEGURANCA-E-GATES.md"),
    Path("PM/PHASES/feito/F1-INSTALACAO-BASE-OPENCLAW/F2-POS-INSTALACAO-BASELINE-SEGURANCA/EPIC-F2-02-CONTRATOS-IDEMPOTENCIA-E-RECONCILIACAO.md"),
    Path("PM/PHASES/feito/F1-INSTALACAO-BASE-OPENCLAW/F2-POS-INSTALACAO-BASELINE-SEGURANCA/EPIC-F2-03-CATALOG-ROUTER-MEMORY-BUDGET.md"),
]

required_markers = [
    "**Owner sugerido**",
    "**Estimativa**",
    "**Dependencias**",
    "**Checklist QA**",
]

issue_heading = re.compile(r"^### (ISSUE-F2-[0-9]{2}-[0-9]{2})", re.M)

for path in files:
    text = path.read_text(encoding="utf-8")
    matches = list(issue_heading.finditer(text))
    if not matches:
        fail(f"{path} sem issues F2 para validar.")
    for idx, match in enumerate(matches):
        issue_id = match.group(1)
        start = match.end()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(text)
        block = text[start:end]
        for marker in required_markers:
            if marker not in block:
                fail(f"{path} com issue {issue_id} sem marcador obrigatorio: {marker}")

print("pm-issue-quality: PASS")
PY
