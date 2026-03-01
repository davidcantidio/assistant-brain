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


f2_files = [
    Path("PM/PHASES/feito/F1-INSTALACAO-BASE-OPENCLAW/F2-POS-INSTALACAO-BASELINE-SEGURANCA/EPIC-F2-01-BASELINE-SEGURANCA-E-GATES.md"),
    Path("PM/PHASES/feito/F1-INSTALACAO-BASE-OPENCLAW/F2-POS-INSTALACAO-BASELINE-SEGURANCA/EPIC-F2-02-CONTRATOS-IDEMPOTENCIA-E-RECONCILIACAO.md"),
    Path("PM/PHASES/feito/F1-INSTALACAO-BASE-OPENCLAW/F2-POS-INSTALACAO-BASELINE-SEGURANCA/EPIC-F2-03-CATALOG-ROUTER-MEMORY-BUDGET.md"),
]

f2_required_markers = [
    "**Owner sugerido**",
    "**Estimativa**",
    "**Dependencias**",
    "**Checklist QA**",
]

f2_issue_heading = re.compile(r"^### (ISSUE-F2-[0-9]{2}-[0-9]{2})", re.M)

for path in f2_files:
    text = path.read_text(encoding="utf-8")
    matches = list(f2_issue_heading.finditer(text))
    if not matches:
        fail(f"{path} sem issues F2 para validar.")
    for idx, match in enumerate(matches):
        issue_id = match.group(1)
        start = match.end()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(text)
        block = text[start:end]
        for marker in f2_required_markers:
            if marker not in block:
                fail(f"{path} com issue {issue_id} sem marcador obrigatorio: {marker}")

# F8 metadata contract
f8_files = [
    Path("PM/PHASES/feito/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-01-CADENCIA-SEMANAL-DE-GATES.md"),
    Path("PM/PHASES/feito/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-02-REVISAO-PERIODICA-DE-CONTRATOS-E-DRIFT.md"),
    Path("PM/PHASES/feito/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-03-GOVERNANCA-DE-EVOLUCAO-E-RELEASE.md"),
    Path("PM/PHASES/feito/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-04-EXPANSAO-MULTIATIVOS-ENABLEMENT.md"),
]

f8_expected = {
    "ISSUE-F8-01-01": {"owner": "pm", "estimativa": "0.5d", "prioridade": "P2", "mapped": {"R1"}},
    "ISSUE-F8-01-02": {"owner": "tech-lead-trading", "estimativa": "0.5d", "prioridade": "P1", "mapped": {"R2"}},
    "ISSUE-F8-01-03": {"owner": "pm", "estimativa": "0.5d", "prioridade": "P2", "mapped": {"R3"}},
    "ISSUE-F8-02-01": {"owner": "tech-lead-trading", "estimativa": "1d", "prioridade": "P0", "mapped": {"R4"}},
    "ISSUE-F8-02-02": {"owner": "product-owner + tech-lead-trading", "estimativa": "0.5d", "prioridade": "P1", "mapped": {"R5"}},
    "ISSUE-F8-02-03": {"owner": "product-owner + tech-lead-trading", "estimativa": "1d", "prioridade": "P0", "mapped": {"R6"}},
    "ISSUE-F8-03-01": {"owner": "product-owner + tech-lead-trading", "estimativa": "0.5d", "prioridade": "P0", "mapped": {"R7", "R6"}},
    "ISSUE-F8-03-02": {"owner": "pm", "estimativa": "0.5d", "prioridade": "P1", "mapped": {"R8"}},
    "ISSUE-F8-03-03": {"owner": "pm + tech-lead-trading", "estimativa": "0.5d", "prioridade": "P1", "mapped": {"R9", "R8"}},
    "ISSUE-F8-04-01": {"owner": "tech-lead-trading", "estimativa": "0.5d", "prioridade": "P1", "mapped": {"R10"}},
    "ISSUE-F8-04-02": {"owner": "tech-lead-trading", "estimativa": "0.5d", "prioridade": "P1", "mapped": {"R11"}},
    "ISSUE-F8-04-03": {"owner": "product-owner + tech-lead-trading", "estimativa": "1d", "prioridade": "P0", "mapped": {"R12", "R7"}},
}

f8_required_markers = [
    "**Metadata da issue**",
    "- **Owner**:",
    "- **Estimativa**:",
    "- **Dependencias**:",
    "- **Mapped requirements**:",
    "- **Prioridade**:",
    "- **Checklist QA/Repro**:",
    "- **Evidence refs**:",
]

f8_issue_heading = re.compile(r"^### (ISSUE-F8-[0-9]{2}-[0-9]{2})", re.M)
owner_pat = re.compile(r"- \*\*Owner\*\*: `([^`]+)`")
estimativa_pat = re.compile(r"- \*\*Estimativa\*\*: `([^`]+)`")
prioridade_pat = re.compile(r"- \*\*Prioridade\*\*: `([^`]+)`")
mapped_pat = re.compile(r"- \*\*Mapped requirements\*\*: ([^\n]+)")

seen_f8: set[str] = set()

for path in f8_files:
    text = path.read_text(encoding="utf-8")
    matches = list(f8_issue_heading.finditer(text))
    if not matches:
        fail(f"{path} sem issues F8 para validar.")
    for idx, match in enumerate(matches):
        issue_id = match.group(1)
        if issue_id in seen_f8:
            fail(f"issue F8 duplicada em docs: {issue_id}")
        seen_f8.add(issue_id)
        start = match.end()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(text)
        block = text[start:end]

        for marker in f8_required_markers:
            if marker not in block:
                fail(f"{path} com issue {issue_id} sem marcador obrigatorio: {marker}")

        expected = f8_expected.get(issue_id)
        if expected is None:
            fail(f"{path} contem issue F8 nao mapeada: {issue_id}")

        owner_match = owner_pat.search(block)
        if not owner_match:
            fail(f"{path} com issue {issue_id} sem Owner valido.")
        if owner_match.group(1).strip() != expected["owner"]:
            fail(
                f"{path} com issue {issue_id} owner divergente: {owner_match.group(1).strip()} != {expected['owner']}"
            )

        estimativa_match = estimativa_pat.search(block)
        if not estimativa_match:
            fail(f"{path} com issue {issue_id} sem Estimativa valida.")
        if estimativa_match.group(1).strip() != expected["estimativa"]:
            fail(
                f"{path} com issue {issue_id} estimativa divergente: {estimativa_match.group(1).strip()} != {expected['estimativa']}"
            )

        prioridade_match = prioridade_pat.search(block)
        if not prioridade_match:
            fail(f"{path} com issue {issue_id} sem Prioridade valida.")
        if prioridade_match.group(1).strip() != expected["prioridade"]:
            fail(
                f"{path} com issue {issue_id} prioridade divergente: {prioridade_match.group(1).strip()} != {expected['prioridade']}"
            )

        mapped_match = mapped_pat.search(block)
        if not mapped_match:
            fail(f"{path} com issue {issue_id} sem Mapped requirements valido.")
        mapped_reqs = set(re.findall(r"`(R[0-9]+)`", mapped_match.group(1)))
        if mapped_reqs != expected["mapped"]:
            fail(
                f"{path} com issue {issue_id} mapped requirements divergente: {sorted(mapped_reqs)} != {sorted(expected['mapped'])}"
            )

missing_f8 = sorted(set(f8_expected) - seen_f8)
extra_f8 = sorted(seen_f8 - set(f8_expected))
if missing_f8:
    fail("issues F8 ausentes no contrato documental: " + ", ".join(missing_f8))
if extra_f8:
    fail("issues F8 extras fora da matriz esperada: " + ", ".join(extra_f8))

print("pm-issue-quality: PASS")
PY
