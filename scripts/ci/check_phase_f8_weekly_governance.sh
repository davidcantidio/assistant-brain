#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
from __future__ import annotations

import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(".")
RUNNER = ROOT / "scripts/ci/run_phase_f8_weekly_governance.sh"
REPORT_DIR = ROOT / "artifacts/phase-f8/weekly-governance"

FIELD_ORDER = [
    "week_id",
    "executed_at",
    "eval_gates_status",
    "ci_quality_status",
    "ci_security_status",
    "contract_review_status",
    "critical_drifts_open",
    "decision",
    "risk_notes",
    "next_actions",
]

LOG_KEYS = ["eval-gates", "ci-quality", "ci-security"]


def fail(message: str) -> None:
    print(message)
    sys.exit(1)


def parse_report(path: Path) -> tuple[dict[str, str], dict[str, str], str]:
    text = path.read_text(encoding="utf-8")
    values: dict[str, str] = {}
    logs: dict[str, str] = {}

    for key in FIELD_ORDER:
      match = re.search(rf"^- {re.escape(key)}: (.+)$", text, re.M)
      if not match:
        fail(f"{path} sem campo obrigatorio: {key}")
      value = match.group(1).strip()
      if value.startswith("`") and value.endswith("`"):
        value = value[1:-1]
      values[key] = value

    for key in LOG_KEYS:
      match = re.search(rf"^- {re.escape(key)}: `(.+?)`$", text, re.M)
      if not match:
        fail(f"{path} sem log obrigatorio: {key}")
      logs[key] = match.group(1)

    positions = []
    for key in FIELD_ORDER:
      token = f"- {key}:"
      positions.append(text.index(token))
    if positions != sorted(positions):
      fail(f"{path} com ordem invalida dos campos obrigatorios.")

    return values, logs, text


def expected_decision(values: dict[str, str]) -> str:
    if (
        values["eval_gates_status"] == "PASS"
        and values["ci_quality_status"] == "PASS"
        and values["ci_security_status"] == "PASS"
        and values["contract_review_status"] == "PASS"
        and values["critical_drifts_open"] == "0"
    ):
      return "promote"
    return "hold"


reports = sorted(REPORT_DIR.glob("*.md"))
if not reports:
    fail("artifacts/phase-f8/weekly-governance sem relatorio semanal.")

for report in reports:
    values, logs, _ = parse_report(report)
    if values["decision"] != expected_decision(values):
      fail(f"{report} com decision inconsistente com a formula semanal.")
    for key, rel_path in logs.items():
      log_path = ROOT / rel_path
      if not log_path.exists():
        fail(f"{report} referencia log ausente para {key}: {rel_path}")


def run_mock(name: str, env_updates: dict[str, str]) -> tuple[dict[str, str], dict[str, str]]:
    with tempfile.TemporaryDirectory(prefix=f"f8-weekly-{name}-") as tmpdir:
      artifact_dir = Path(tmpdir) / "weekly-governance"
      env = os.environ.copy()
      env.update(
          {
              "ARTIFACT_DIR": str(artifact_dir),
              "WEEK_ID": "2026-W09",
              "EXECUTED_AT": "2026-03-01T00:00:00-0300",
          }
      )
      env.update(env_updates)
      subprocess.run(["bash", str(RUNNER)], cwd=ROOT, env=env, check=True, capture_output=True, text=True)
      report = artifact_dir / "2026-W09.md"
      values, logs, _ = parse_report(report)
      log_contents = {
          key: Path(log_path).read_text(encoding="utf-8")
          for key, log_path in logs.items()
      }
      return values, log_contents


pass_values, _ = run_mock(
    "promote",
    {
        "EVAL_GATES_CMD": "printf 'eval-gates: PASS\\n'",
        "CI_QUALITY_CMD": "printf 'quality-check: PASS\\n'",
        "CI_SECURITY_CMD": "printf 'security-check: PASS\\n'",
        "CONTRACT_REVIEW_STATUS": "PASS",
        "CRITICAL_DRIFTS_OPEN": "0",
    },
)
if pass_values["decision"] != "promote":
    fail("mock promote deveria resultar em decision=promote.")

eval_fail_values, eval_fail_logs = run_mock(
    "eval-fail",
    {
        "EVAL_GATES_CMD": "printf 'eval-gates: FAIL\\n'; exit 1",
        "CI_QUALITY_CMD": "printf 'quality-check: PASS\\n'",
        "CI_SECURITY_CMD": "printf 'security-check: PASS\\n'",
        "CONTRACT_REVIEW_STATUS": "PASS",
        "CRITICAL_DRIFTS_OPEN": "0",
    },
)
if eval_fail_values["eval_gates_status"] != "FAIL":
    fail("mock eval-fail deveria marcar eval_gates_status=FAIL.")
if eval_fail_values["ci_quality_status"] != "FAIL" or eval_fail_values["ci_security_status"] != "FAIL":
    fail("mock eval-fail deveria marcar gates posteriores como FAIL.")
if "SKIPPED" not in eval_fail_logs["ci-quality"]:
    fail("mock eval-fail deveria registrar skip de ci-quality.")
if "SKIPPED" not in eval_fail_logs["ci-security"]:
    fail("mock eval-fail deveria registrar skip de ci-security.")

quality_fail_values, quality_fail_logs = run_mock(
    "quality-fail",
    {
        "EVAL_GATES_CMD": "printf 'eval-gates: PASS\\n'",
        "CI_QUALITY_CMD": "printf 'quality-check: FAIL\\n'; exit 1",
        "CI_SECURITY_CMD": "printf 'security-check: PASS\\n'",
        "CONTRACT_REVIEW_STATUS": "PASS",
        "CRITICAL_DRIFTS_OPEN": "0",
    },
)
if quality_fail_values["ci_quality_status"] != "FAIL":
    fail("mock quality-fail deveria marcar ci_quality_status=FAIL.")
if quality_fail_values["ci_security_status"] != "FAIL":
    fail("mock quality-fail deveria marcar ci_security_status=FAIL por fail-fast.")
if "SKIPPED" not in quality_fail_logs["ci-security"]:
    fail("mock quality-fail deveria registrar skip de ci-security.")

review_fail_values, _ = run_mock(
    "review-fail",
    {
        "EVAL_GATES_CMD": "printf 'eval-gates: PASS\\n'",
        "CI_QUALITY_CMD": "printf 'quality-check: PASS\\n'",
        "CI_SECURITY_CMD": "printf 'security-check: PASS\\n'",
        "CRITICAL_DRIFTS_OPEN": "0",
    },
)
if review_fail_values["contract_review_status"] != "FAIL":
    fail("mock review-fail deveria usar contract_review_status=FAIL por default.")
if review_fail_values["decision"] != "hold":
    fail("mock review-fail deveria resultar em decision=hold.")

print("phase-f8-weekly-governance: PASS")
PY
