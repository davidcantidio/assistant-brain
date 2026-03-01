#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
from __future__ import annotations

import glob
import os
import re
import sys
from pathlib import Path

ROOT = Path(".")
AUDIT_FILES = sorted(glob.glob("PM/audit/*.json"))
ABS_PREFIX = "/Users/genivalfreirenobrejunior/Documents/code/npbb/openclaw/assistant-brain"

legacy_rel = re.compile(r"PM/PHASES/F7-TRADING-POR-ESTAGIOS/[^\"\s`]*\.md")
legacy_abs = re.compile(
    re.escape(ABS_PREFIX) + r"/PM/PHASES/F7-TRADING-POR-ESTAGIOS/[^\"\s`]*\.md"
)
abs_paths = re.compile(re.escape(ABS_PREFIX) + r"[^\"\s]*")

errors: list[str] = []

for f in AUDIT_FILES:
    text = Path(f).read_text(encoding="utf-8")

    for m in legacy_rel.finditer(text):
        errors.append(
            f"LEGACY_F7_PATH {f} -> {m.group(0)} (use PM/PHASES/feito/F7-TRADING-POR-ESTAGIOS/...)"
        )
    for m in legacy_abs.finditer(text):
        errors.append(
            f"LEGACY_F7_PATH {f} -> {m.group(0)} (use .../PM/PHASES/feito/F7-TRADING-POR-ESTAGIOS/...)"
        )

    for m in abs_paths.finditer(text):
        raw = m.group(0)
        base = raw.split(":", 1)[0]
        if not os.path.exists(base):
            errors.append(f"MISSING_ABS_REF {f} -> {base}")

if errors:
    print("pm-audit-paths: FAIL")
    for e in sorted(set(errors)):
        print(e)
    sys.exit(1)

print("pm-audit-paths: PASS")
PY
