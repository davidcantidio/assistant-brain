#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
from __future__ import annotations

import glob
import re
import sys
from pathlib import Path

ROOT = Path(".")
AUDIT_FILES = sorted(glob.glob("PM/audit/*.json"))

legacy_rel = re.compile(r"PM/PHASES/F7-TRADING-POR-ESTAGIOS/[^\"\s`]*\.md")
unix_abs_paths = re.compile(r"(?<![A-Za-z0-9_])/(?:Users|home|root|mnt|opt|var)/[^\"\s`]+")
windows_abs_paths = re.compile(r"(?<![A-Za-z0-9_])[A-Za-z]:\\[^\"\s`]+")

errors: list[str] = []

for f in AUDIT_FILES:
    text = Path(f).read_text(encoding="utf-8")

    for m in legacy_rel.finditer(text):
        errors.append(
            f"LEGACY_F7_PATH {f} -> {m.group(0)} (use PM/PHASES/feito/F7-TRADING-POR-ESTAGIOS/...)"
        )
    for pattern in (unix_abs_paths, windows_abs_paths):
        for m in pattern.finditer(text):
            raw = m.group(0)
            base = raw.split(":", 1)[0]
            hint = "use caminho relativo ao repo"
            try:
                rel = Path(base).resolve().relative_to(ROOT.resolve())
            except Exception:
                rel = None
            if rel is not None:
                hint = f"use '{rel.as_posix()}'"
            errors.append(f"ABS_PATH_REF {f} -> {raw} ({hint})")

if errors:
    print("pm-audit-paths: FAIL")
    for e in sorted(set(errors)):
        print(e)
    sys.exit(1)

print("pm-audit-paths: PASS")
PY
