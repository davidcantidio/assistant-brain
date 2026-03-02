#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(".")
RUNNER = ROOT / "scripts/ci/run_phase_f8_weekly_governance.sh"
REPORT_DIR = ROOT / "artifacts/phase-f8/weekly-governance"
PRIMARY_EPICS_PATH = ROOT / "PM/PHASES/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPICS.md"
FALLBACK_EPICS_PATH = ROOT / "PM/PHASES/feito/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPICS.md"

FIELD_ORDER = [
    "week_id",
    "executed_at",
    "source_of_truth",
    "prior_phase_decision",
    "phase_transition_status",
    "blocking_reason",
    "operational_readiness",
    "review_validity_status",
    "operational_conformance_status",
    "failed_domains",
    "eval_gates_status",
    "ci_quality_status",
    "ci_security_status",
    "critical_drifts_open",
    "decision",
    "release_review_status",
    "release_justification",
    "residual_risk_summary",
    "rollback_plan",
    "summary_artifact",
    "risk_notes",
    "next_actions",
]

LOG_KEYS = ["eval-gates", "ci-quality", "ci-security"]


def fail(message: str) -> None:
    print(message)
    sys.exit(1)


def parse_report(path: Path) -> tuple[dict[str, str], dict[str, str], str]:
    proc = subprocess.run(
        [
            "python3",
            str(ROOT / "scripts/ci/phase_f8_release_governance.py"),
            "parse-weekly-report",
            "--report-path",
            str(path),
        ],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        fail(proc.stderr.strip() or proc.stdout.strip() or f"falha ao interpretar {path}")

    payload = json.loads(proc.stdout)
    values = payload["values"]
    logs = payload["logs"]
    text = payload["text"]

    positions = []
    for key in FIELD_ORDER:
        token = f"- {key}:"
        positions.append(text.index(token))
    if positions != sorted(positions):
        fail(f"{path} com ordem invalida dos campos obrigatorios.")

    return values, logs, text


def parse_summary(path: Path) -> dict[str, object]:
    proc = subprocess.run(
        [
            "python3",
            str(ROOT / "scripts/ci/phase_f8_release_governance.py"),
            "parse-validation-summary",
            "--summary-path",
            str(path),
        ],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        fail(proc.stderr.strip() or proc.stdout.strip() or f"falha ao interpretar {path}")
    return json.loads(proc.stdout)


def read_epic_statuses(path: Path) -> dict[str, str]:
    proc = subprocess.run(
        [
            "python3",
            str(ROOT / "scripts/ci/phase_f8_release_governance.py"),
            "read-epic-statuses",
            "--epics-path",
            str(path),
        ],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        fail(proc.stderr.strip() or proc.stdout.strip() or f"falha ao ler {path}")
    return json.loads(proc.stdout)


def resolve_epics_path() -> Path:
    if PRIMARY_EPICS_PATH.exists():
        return PRIMARY_EPICS_PATH
    if FALLBACK_EPICS_PATH.exists():
        return FALLBACK_EPICS_PATH
    return PRIMARY_EPICS_PATH


def expected_decision(values: dict[str, str]) -> str:
    if (
        values["prior_phase_decision"] == "promote"
        and values["phase_transition_status"] == "ready"
        and values["blocking_reason"] == "none"
        and values["review_validity_status"] == "PASS"
        and values["operational_conformance_status"] == "PASS"
        and values["eval_gates_status"] == "PASS"
        and values["ci_quality_status"] == "PASS"
        and values["ci_security_status"] == "PASS"
        and values["critical_drifts_open"] == "0"
        and values["release_review_status"] == "PASS"
    ):
      return "promote"
    return "hold"


def expected_operational_readiness(values: dict[str, str]) -> str:
    if values["decision"] == "promote":
        return "ready"
    if (
        values["phase_transition_status"] == "blocked"
        or values["operational_conformance_status"] == "FAIL"
        or values["critical_drifts_open"] != "0"
    ):
        return "blocked"
    return "hold"


reports = sorted(REPORT_DIR.glob("*.md"))
if not reports:
    fail("artifacts/phase-f8/weekly-governance sem relatorio semanal.")

for report in reports:
    values, logs, _ = parse_report(report)
    if values["source_of_truth"] != "PRD/PRD-MASTER.md":
      fail(f"{report} com source_of_truth invalido: {values['source_of_truth']}")
    if values["phase_transition_status"] not in {"ready", "blocked"}:
      fail(f"{report} com phase_transition_status invalido: {values['phase_transition_status']}")
    if values["prior_phase_decision"] not in {"promote", "hold"}:
      fail(f"{report} com prior_phase_decision invalido: {values['prior_phase_decision']}")
    if values["phase_transition_status"] == "blocked" and values["blocking_reason"] in {"", "none"}:
      fail(f"{report} com blocking_reason vazio para transicao bloqueada.")
    if values["phase_transition_status"] == "ready" and values["blocking_reason"] != "none":
      fail(f"{report} deveria usar blocking_reason=none quando a transicao estiver ready.")
    if values["operational_readiness"] not in {"blocked", "hold", "ready"}:
      fail(f"{report} com operational_readiness invalido: {values['operational_readiness']}")
    if values["review_validity_status"] not in {"PASS", "FAIL"}:
      fail(f"{report} com review_validity_status invalido: {values['review_validity_status']}")
    if values["operational_conformance_status"] not in {"PASS", "FAIL"}:
      fail(
          f"{report} com operational_conformance_status invalido: {values['operational_conformance_status']}"
      )
    if values["failed_domains"] == "":
      fail(f"{report} com failed_domains vazio.")
    if values["release_review_status"] not in {"PASS", "FAIL"}:
      fail(f"{report} com release_review_status invalido: {values['release_review_status']}")
    for key in ("release_justification", "residual_risk_summary", "rollback_plan", "summary_artifact", "next_actions"):
      if not values[key].strip():
        fail(f"{report} com {key} vazio.")
    if values["decision"] == "promote" and values["release_review_status"] != "PASS":
      fail(f"{report} nao pode promover release com release_review_status!=PASS.")
    if values["decision"] != expected_decision(values):
      fail(f"{report} com decision inconsistente com a formula semanal.")
    if values["operational_readiness"] != expected_operational_readiness(values):
      fail(f"{report} com operational_readiness inconsistente com a formula semanal.")
    for key, rel_path in logs.items():
      log_path = ROOT / rel_path
      if not log_path.exists():
        fail(f"{report} referencia log ausente para {key}: {rel_path}")
    summary_path = ROOT / values["summary_artifact"]
    if not summary_path.exists():
      fail(f"{report} referencia validation summary ausente: {values['summary_artifact']}")
    summary = parse_summary(summary_path)
    summary_values = summary["values"]
    if summary_values["week_id"] != values["week_id"]:
      fail(f"{summary_path} com week_id inconsistente.")
    if summary_values["weekly_report"] != str(report.relative_to(ROOT)):
      fail(f"{summary_path} com weekly_report inconsistente.")
    for key in (
        "decision",
        "release_review_status",
        "release_justification",
        "phase_transition_status",
        "blocking_reason",
        "operational_readiness",
        "review_validity_status",
        "operational_conformance_status",
        "failed_domains",
        "residual_risk_summary",
        "rollback_plan",
        "next_actions",
        "critical_drifts_open",
    ):
      if summary_values[key] != values[key]:
        fail(f"{summary_path} divergente do weekly report no campo {key}.")
    for key in ("eval_gates_status", "ci_quality_status", "ci_security_status"):
      if summary["gate_statuses"][key] != values[key]:
        fail(f"{summary_path} divergente do weekly report no gate {key}.")
    expected_epics_path = resolve_epics_path()
    expected_epics = read_epic_statuses(expected_epics_path)
    if summary["epic_statuses"] != expected_epics:
      fail(f"{summary_path} com Epic Status divergente de {expected_epics_path}.")
    report_ref = str(report.relative_to(ROOT))
    contract_review_ref = f"artifacts/phase-f8/contract-review/{values['week_id']}.md"
    if report_ref not in summary["evidence_refs"]:
      fail(f"{summary_path} sem referencia ao weekly report autoritativo.")
    if contract_review_ref not in summary["evidence_refs"]:
      fail(f"{summary_path} sem referencia ao contract review da semana.")


def run_mock(name: str, env_updates: dict[str, str]) -> tuple[dict[str, str], dict[str, str], dict[str, object]]:
    with tempfile.TemporaryDirectory(prefix=f"f8-weekly-{name}-") as tmpdir:
      artifact_dir = Path(tmpdir) / "weekly-governance"
      contract_review_dir = Path(tmpdir) / "contract-review"
      summary_artifact = Path(tmpdir) / "validation-summary-2026-W09.md"
      env = os.environ.copy()
      env.update(
          {
              "ARTIFACT_DIR": str(artifact_dir),
              "CONTRACT_REVIEW_DIR": str(contract_review_dir),
              "SUMMARY_ARTIFACT": str(summary_artifact),
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
      summary = parse_summary(summary_artifact)
      return values, log_contents, summary


def write_contract_review(
    path: Path,
    *,
    source_of_truth: str = "PRD/PRD-MASTER.md",
    critical_drifts_open: int = 0,
    failed_domains: str = "[]",
    operational_conformance_status: str = "PASS",
    trading_status: str = "PASS",
    drift_backlog: str = "[]",
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        """# F8 Contract Review 2026-W09

## Metadata
```json
{
  "week_id": "2026-W09",
  "reviewed_at": "2026-03-01T00:00:00-0300",
  "source_of_truth": "%s",
  "previous_week_id": "none",
  "review_validity_status": "PASS",
  "operational_conformance_status": "%s",
  "failed_domains": %s,
  "critical_drifts_open": %s
}
```

## Contracts Reviewed
```json
[
  {
    "domain": "runtime",
    "owner": "Ayrton Senna",
    "status": "PASS",
    "canonical_refs": ["PRD/PRD-MASTER.md", "ARC/ARC-CORE.md"],
    "gate_refs": ["make eval-runtime"],
    "evidence_refs": ["scripts/ci/eval_runtime_contracts.sh"],
    "notes": "runtime review mock"
  },
  {
    "domain": "integrations",
    "owner": "O Garcon",
    "status": "PASS",
    "canonical_refs": ["PRD/PRD-MASTER.md", "INTEGRATIONS/README.md"],
    "gate_refs": ["make eval-integrations"],
    "evidence_refs": ["scripts/ci/eval_integrations.sh"],
    "notes": "integrations review mock"
  },
  {
    "domain": "trading",
    "owner": "Sr. Geldmacher",
    "status": "%s",
    "canonical_refs": ["PRD/PRD-MASTER.md", "VERTICALS/TRADING/TRADING-PRD.md"],
    "gate_refs": ["make eval-trading"],
    "evidence_refs": ["scripts/ci/eval_trading.sh"],
    "notes": "trading review mock"
  },
  {
    "domain": "security",
    "owner": "Bas Rutten",
    "status": "PASS",
    "canonical_refs": ["PRD/PRD-MASTER.md", "SEC/SEC-POLICY.md"],
    "gate_refs": ["make ci-security"],
    "evidence_refs": ["scripts/ci/check_security.sh"],
    "notes": "security review mock"
  }
]
```

## Drift Backlog
```json
%s
```

## Previous Week Closure
```json
{
  "status": "PASS",
  "reviewed_drift_ids": [],
  "closed_refs": [],
  "risk_accepted_refs": [],
  "open_critical_refs": [],
  "carried_over_drifts": [],
  "notes": "first review cycle"
}
```
"""
        % (
            source_of_truth,
            operational_conformance_status,
            failed_domains,
            critical_drifts_open,
            trading_status,
            drift_backlog,
        ),
        encoding="utf-8",
    )


pass_values, _, pass_summary = run_mock(
    "promote",
    {
        "EVAL_GATES_CMD": "printf 'eval-gates: PASS\\n'",
        "CI_QUALITY_CMD": "printf 'quality-check: PASS\\n'",
        "CI_SECURITY_CMD": "printf 'security-check: PASS\\n'",
        "REVIEW_VALIDITY_STATUS": "PASS",
        "OPERATIONAL_CONFORMANCE_STATUS": "PASS",
        "FAILED_DOMAINS": "none",
        "CRITICAL_DRIFTS_OPEN": "0",
        "PRIOR_PHASE_DECISION": "promote",
        "PHASE_TRANSITION_STATUS": "ready",
        "BLOCKING_REASON": "none",
    },
)
if pass_values["decision"] != "promote":
    fail("mock promote deveria resultar em decision=promote.")
if pass_values["release_review_status"] != "PASS":
    fail("mock promote deveria manter release_review_status=PASS.")
if pass_summary["values"]["decision"] != "promote":
    fail("mock promote deveria gerar validation summary coerente.")

eval_fail_values, eval_fail_logs, _ = run_mock(
    "eval-fail",
    {
        "EVAL_GATES_CMD": "printf 'eval-gates: FAIL\\n'; exit 1",
        "CI_QUALITY_CMD": "printf 'quality-check: PASS\\n'",
        "CI_SECURITY_CMD": "printf 'security-check: PASS\\n'",
        "REVIEW_VALIDITY_STATUS": "PASS",
        "OPERATIONAL_CONFORMANCE_STATUS": "PASS",
        "FAILED_DOMAINS": "none",
        "CRITICAL_DRIFTS_OPEN": "0",
        "PRIOR_PHASE_DECISION": "promote",
        "PHASE_TRANSITION_STATUS": "ready",
        "BLOCKING_REASON": "none",
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

quality_fail_values, quality_fail_logs, _ = run_mock(
    "quality-fail",
    {
        "EVAL_GATES_CMD": "printf 'eval-gates: PASS\\n'",
        "CI_QUALITY_CMD": "printf 'quality-check: FAIL\\n'; exit 1",
        "CI_SECURITY_CMD": "printf 'security-check: PASS\\n'",
        "REVIEW_VALIDITY_STATUS": "PASS",
        "OPERATIONAL_CONFORMANCE_STATUS": "PASS",
        "FAILED_DOMAINS": "none",
        "CRITICAL_DRIFTS_OPEN": "0",
        "PRIOR_PHASE_DECISION": "promote",
        "PHASE_TRANSITION_STATUS": "ready",
        "BLOCKING_REASON": "none",
    },
)
if quality_fail_values["ci_quality_status"] != "FAIL":
    fail("mock quality-fail deveria marcar ci_quality_status=FAIL.")
if quality_fail_values["ci_security_status"] != "FAIL":
    fail("mock quality-fail deveria marcar ci_security_status=FAIL por fail-fast.")
if "SKIPPED" not in quality_fail_logs["ci-security"]:
    fail("mock quality-fail deveria registrar skip de ci-security.")
if "release bloqueado por ci-quality=FAIL" not in quality_fail_values["release_justification"]:
    fail("mock quality-fail deveria registrar release_justification para falha de quality.")

artifact_pass_dir = Path(tempfile.mkdtemp(prefix="f8-contract-review-pass-"))
try:
    write_contract_review(artifact_pass_dir / "2026-W09.md")
    artifact_pass_values, _, artifact_pass_summary = run_mock(
        "artifact-pass",
        {
            "EVAL_GATES_CMD": "printf 'eval-gates: PASS\\n'",
            "CI_QUALITY_CMD": "printf 'quality-check: PASS\\n'",
            "CI_SECURITY_CMD": "printf 'security-check: PASS\\n'",
            "CONTRACT_REVIEW_DIR": str(artifact_pass_dir),
            "PRIOR_PHASE_DECISION": "promote",
            "PHASE_TRANSITION_STATUS": "ready",
            "BLOCKING_REASON": "none",
        },
    )
    if artifact_pass_values["review_validity_status"] != "PASS":
        fail("mock artifact-pass deveria usar review_validity_status=PASS a partir do artifact.")
    if artifact_pass_values["operational_conformance_status"] != "PASS":
        fail("mock artifact-pass deveria usar operational_conformance_status=PASS.")
    if artifact_pass_values["decision"] != "promote":
        fail("mock artifact-pass deveria resultar em decision=promote.")
    if artifact_pass_summary["epic_statuses"]["EPIC-F8-03"] != read_epic_statuses(resolve_epics_path())["EPIC-F8-03"]:
        fail("mock artifact-pass deveria refletir o status atual de EPIC-F8-03 no EPICS.md.")
finally:
    for path in sorted(artifact_pass_dir.rglob("*"), reverse=True):
        if path.is_file():
            path.unlink()
        elif path.is_dir():
            path.rmdir()
    if artifact_pass_dir.exists():
        artifact_pass_dir.rmdir()

artifact_open_dir = Path(tempfile.mkdtemp(prefix="f8-contract-review-open-"))
try:
    write_contract_review(
        artifact_open_dir / "2026-W09.md",
        critical_drifts_open=1,
        failed_domains='["trading"]',
        operational_conformance_status="FAIL",
        trading_status="FAIL",
        drift_backlog="""[
  {
    "drift_id": "DRIFT-F8-2026-W09-01",
    "domain": "trading",
    "severity": "critical",
    "summary": "critical drift mock",
    "status": "open",
    "owner": "Sr. Geldmacher",
    "due_date": "2026-03-08",
    "source_refs": ["PRD/PRD-MASTER.md"],
    "evidence_ref": "artifacts/mock.md",
    "risk_exception_ref": null
  }
]""",
    )
    artifact_open_values, _, artifact_open_summary = run_mock(
        "artifact-open",
        {
            "EVAL_GATES_CMD": "printf 'eval-gates: PASS\\n'",
            "CI_QUALITY_CMD": "printf 'quality-check: PASS\\n'",
            "CI_SECURITY_CMD": "printf 'security-check: PASS\\n'",
            "CONTRACT_REVIEW_DIR": str(artifact_open_dir),
            "PRIOR_PHASE_DECISION": "promote",
            "PHASE_TRANSITION_STATUS": "ready",
            "BLOCKING_REASON": "none",
        },
    )
    if artifact_open_values["review_validity_status"] != "PASS":
        fail("mock artifact-open deveria manter review_validity_status=PASS com artifact valido.")
    if artifact_open_values["operational_conformance_status"] != "FAIL":
        fail("mock artifact-open deveria refletir dominio operacional em FAIL.")
    if artifact_open_values["failed_domains"] != "trading":
        fail("mock artifact-open deveria propagar failed_domains=trading.")
    if artifact_open_values["critical_drifts_open"] != "1":
        fail("mock artifact-open deveria propagar critical_drifts_open=1.")
    if artifact_open_values["decision"] != "hold":
        fail("mock artifact-open deveria resultar em decision=hold.")
    if artifact_open_values["operational_readiness"] != "blocked":
        fail("mock artifact-open deveria resultar em operational_readiness=blocked.")
    if "critical_drifts_open=1" not in artifact_open_values["residual_risk_summary"]:
        fail("mock artifact-open deveria refletir drift critico no residual_risk_summary.")
    if artifact_open_summary["values"]["critical_drifts_open"] != "1":
        fail("mock artifact-open deveria propagar critical_drifts_open para o validation summary.")
finally:
    for path in sorted(artifact_open_dir.rglob("*"), reverse=True):
        if path.is_file():
            path.unlink()
        elif path.is_dir():
            path.rmdir()
    if artifact_open_dir.exists():
        artifact_open_dir.rmdir()

review_fail_values, _, _ = run_mock(
    "review-fail",
    {
        "EVAL_GATES_CMD": "printf 'eval-gates: PASS\\n'",
        "CI_QUALITY_CMD": "printf 'quality-check: PASS\\n'",
        "CI_SECURITY_CMD": "printf 'security-check: PASS\\n'",
    },
)
if review_fail_values["review_validity_status"] != "FAIL":
    fail("mock review-fail deveria usar review_validity_status=FAIL quando o artifact estiver ausente.")
if review_fail_values["operational_conformance_status"] != "FAIL":
    fail("mock review-fail deveria usar operational_conformance_status=FAIL quando o artifact estiver ausente.")
if review_fail_values["decision"] != "hold":
    fail("mock review-fail deveria resultar em decision=hold.")

prior_phase_hold_values, _, _ = run_mock(
    "prior-phase-hold",
    {
        "EVAL_GATES_CMD": "printf 'eval-gates: PASS\\n'",
        "CI_QUALITY_CMD": "printf 'quality-check: PASS\\n'",
        "CI_SECURITY_CMD": "printf 'security-check: PASS\\n'",
        "REVIEW_VALIDITY_STATUS": "PASS",
        "OPERATIONAL_CONFORMANCE_STATUS": "PASS",
        "FAILED_DOMAINS": "none",
        "CRITICAL_DRIFTS_OPEN": "0",
        "PRIOR_PHASE_DECISION": "hold",
        "PHASE_TRANSITION_STATUS": "blocked",
        "BLOCKING_REASON": "phase_transition_blocked: F7 -> F8 permanece hold; ativacao prematura da F8 foi recuada ao contrato de promocao entre fases.",
    },
)
if prior_phase_hold_values["decision"] != "hold":
    fail("mock prior-phase-hold deveria resultar em decision=hold.")
if prior_phase_hold_values["phase_transition_status"] != "blocked":
    fail("mock prior-phase-hold deveria marcar phase_transition_status=blocked.")
if prior_phase_hold_values["operational_readiness"] != "blocked":
    fail("mock prior-phase-hold deveria resultar em operational_readiness=blocked.")
if "manter a baseline vigente de F7/F8-02" not in prior_phase_hold_values["rollback_plan"]:
    fail("mock prior-phase-hold deveria usar o rollback canonico de hold.")

print("phase-f8-weekly-governance: PASS")
PY
