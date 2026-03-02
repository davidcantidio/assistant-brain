from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path
from typing import Callable

from policy_engine.domain.contract_models import ContractManifest, RuleContract
from policy_engine.domain.policy_rule import PolicyContext, PolicyRule, RuleEvaluation

CRITICAL_WRAPPERS: tuple[str, ...] = (
    "scripts/ci/check_phase_f8_weekly_governance.sh",
    "scripts/ci/eval_trading.sh",
    "scripts/ci/check_security.sh",
    "scripts/ci/check_quality.sh",
)

MAX_WRAPPER_LINES = 60

Checker = Callable[[PolicyContext, RuleContract], RuleEvaluation]


class ManifestRule:
    id: str
    domain: str
    severity: str
    category: str | None
    evidence_refs: tuple[str, ...]
    remediation_hint: str | None
    _contract: RuleContract
    _checker: Checker

    def __init__(self, contract: RuleContract, checker: Checker) -> None:
        self.id = contract.rule_id
        self.domain = contract.domain
        self.severity = contract.severity
        self.category = contract.category
        self.evidence_refs = contract.evidence_refs
        self.remediation_hint = contract.remediation_hint
        self._contract = contract
        self._checker = checker

    def evaluate(self, context: PolicyContext) -> RuleEvaluation:
        return self._checker(context, self._contract)


def _run_bash_script(context: PolicyContext, rel_path: str) -> RuleEvaluation:
    script_path = context.root / rel_path
    if not script_path.exists():
        return RuleEvaluation(
            passed=False,
            message=f"missing governance script: {rel_path}",
            path=rel_path,
            evidence_ref=rel_path,
            error_code="GOV.MISSING_SCRIPT",
        )

    proc = subprocess.run(
        ["bash", str(script_path)],
        cwd=context.root,
        text=True,
        capture_output=True,
        check=False,
    )
    if proc.returncode == 0:
        return RuleEvaluation(passed=True)

    tail = (proc.stderr.strip() or proc.stdout.strip()).splitlines()[-1:] or ["governance check failed"]
    return RuleEvaluation(
        passed=False,
        message=f"{rel_path} failed: {tail[0]}",
        path=rel_path,
        evidence_ref=rel_path,
        error_code="GOV.WEEKLY_CONTRACT_FAIL",
    )


def check_weekly_governance(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    return _run_bash_script(context, "scripts/ci/legacy/check_phase_f8_weekly_governance_legacy.sh")


def check_shell_wrapper_limits(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    oversized: list[str] = []
    for rel_path in CRITICAL_WRAPPERS:
        path = context.root / rel_path
        if not path.exists():
            oversized.append(f"{rel_path}(missing)")
            continue
        line_count = path.read_text(encoding="utf-8", errors="ignore").count("\n")
        if line_count > MAX_WRAPPER_LINES:
            oversized.append(f"{rel_path}({line_count})")

    if oversized:
        return RuleEvaluation(
            passed=False,
            message=(
                "critical shell wrappers above limit "
                f"(max={MAX_WRAPPER_LINES}): {', '.join(oversized)}"
            ),
            path="scripts/ci",
            evidence_ref="scripts/ci/check_quality.sh",
            error_code="GOV.SHELL_WRAPPER_TOO_LONG",
        )
    return RuleEvaluation(passed=True)


def check_reconstruction_kpi_baseline(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    rel_path = "artifacts/governance/phase1-kpi-baseline.json"
    path = context.root / rel_path
    if not path.exists():
        return RuleEvaluation(
            passed=False,
            message=f"missing KPI baseline artifact: {rel_path}",
            path=rel_path,
            evidence_ref=rel_path,
            error_code="GOV.KPI_BASELINE_MISSING",
        )

    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return RuleEvaluation(
            passed=False,
            message=f"invalid KPI baseline JSON: {exc}",
            path=rel_path,
            evidence_ref=rel_path,
            error_code="GOV.KPI_BASELINE_INVALID",
        )

    required_fields = {
        "lead_time_days",
        "deploy_frequency_per_day",
        "change_failure_rate",
        "mttr_minutes",
        "critical_checks_typed_pct",
        "critical_flows_e2e_covered_pct",
    }
    missing = sorted([field for field in required_fields if field not in payload])
    if missing:
        return RuleEvaluation(
            passed=False,
            message=f"KPI baseline missing required fields: {missing}",
            path=rel_path,
            evidence_ref=rel_path,
            error_code="GOV.KPI_BASELINE_MISSING_FIELDS",
        )
    return RuleEvaluation(passed=True)


def check_ownership_spof(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    codeowners_path = context.root / ".github/CODEOWNERS"
    operators_path = context.root / "SEC/allowlists/OPERATORS.yaml"

    if not codeowners_path.exists():
        return RuleEvaluation(
            passed=False,
            message="missing CODEOWNERS",
            path=".github/CODEOWNERS",
            evidence_ref=".github/CODEOWNERS",
            error_code="GOV.CODEOWNERS_MISSING",
        )
    if not operators_path.exists():
        return RuleEvaluation(
            passed=False,
            message="missing operators allowlist",
            path="SEC/allowlists/OPERATORS.yaml",
            evidence_ref="SEC/allowlists/OPERATORS.yaml",
            error_code="GOV.OPERATORS_MISSING",
        )

    codeowners_text = codeowners_path.read_text(encoding="utf-8", errors="ignore")
    global_owners: list[str] = []
    for raw in codeowners_text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("*"):
            global_owners = re.findall(r"@[A-Za-z0-9_-]+", line)
            break
    if len(global_owners) < 2:
        return RuleEvaluation(
            passed=False,
            message=f"global CODEOWNERS below minimum: {len(global_owners)} < 2",
            path=".github/CODEOWNERS",
            evidence_ref=".github/CODEOWNERS",
            error_code="GOV.CODEOWNERS_GLOBAL_SPOF",
        )

    operators_text = operators_path.read_text(encoding="utf-8", errors="ignore")
    backup_match = re.search(r'backup_operator_operator_id:\s*"([^"]+)"', operators_text)
    if backup_match is None:
        return RuleEvaluation(
            passed=False,
            message="backup operator id missing in OPERATORS allowlist",
            path="SEC/allowlists/OPERATORS.yaml",
            evidence_ref="SEC/allowlists/OPERATORS.yaml",
            error_code="GOV.BACKUP_OPERATOR_MISSING",
        )
    backup_operator_id = backup_match.group(1)

    blocks = re.split(r"\n\s*-\s+operator_id:\s*", operators_text)
    enabled_ids: list[str] = []
    for block in blocks[1:]:
        lines = block.splitlines()
        if not lines:
            continue
        operator_id = lines[0].strip().strip('"')
        enabled_match = re.search(r"\n\s+enabled:\s*(true|false)", "\n" + block)
        enabled = (enabled_match.group(1) == "true") if enabled_match else False
        if enabled:
            enabled_ids.append(operator_id)

    if len(enabled_ids) < 2:
        return RuleEvaluation(
            passed=False,
            message=f"enabled operators below minimum: {len(enabled_ids)} < 2",
            path="SEC/allowlists/OPERATORS.yaml",
            evidence_ref="SEC/allowlists/OPERATORS.yaml",
            error_code="GOV.OPERATORS_SPOF",
        )
    if backup_operator_id not in enabled_ids:
        return RuleEvaluation(
            passed=False,
            message=f"backup operator disabled: {backup_operator_id}",
            path="SEC/allowlists/OPERATORS.yaml",
            evidence_ref="SEC/allowlists/OPERATORS.yaml",
            error_code="GOV.BACKUP_OPERATOR_DISABLED",
        )
    return RuleEvaluation(passed=True)


def check_runtime_hard_gates(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    hierarchy_path = context.root / "META/DOCUMENT-HIERARCHY.md"
    quality_path = context.root / "scripts/ci/check_quality.sh"
    microtask_path = context.root / "PRD/PRD-MASTER.md"

    if not hierarchy_path.exists():
        return RuleEvaluation(
            passed=False,
            message="missing hierarchy doc for hard gate",
            path="META/DOCUMENT-HIERARCHY.md",
            evidence_ref="META/DOCUMENT-HIERARCHY.md",
            error_code="GOV.HARD_GATE_HIERARCHY_MISSING",
        )

    hierarchy_text = hierarchy_path.read_text(encoding="utf-8", errors="ignore")
    required_priority_tokens = ("1. SEC/", "2. PRD/", "3. ARC/")
    for token in required_priority_tokens:
        if token not in hierarchy_text:
            return RuleEvaluation(
                passed=False,
                message=f"hard gate precedence token missing in hierarchy: {token}",
                path="META/DOCUMENT-HIERARCHY.md",
                evidence_ref="META/DOCUMENT-HIERARCHY.md",
                error_code="GOV.HARD_GATE_PRECEDENCE_INVALID",
            )

    if not quality_path.exists():
        return RuleEvaluation(
            passed=False,
            message="missing quality gate script",
            path="scripts/ci/check_quality.sh",
            evidence_ref="scripts/ci/check_quality.sh",
            error_code="GOV.HARD_GATE_QUALITY_SCRIPT_MISSING",
        )
    quality_text = quality_path.read_text(encoding="utf-8", errors="ignore")
    if "check_pr_governance.sh" not in quality_text:
        return RuleEvaluation(
            passed=False,
            message="check_quality.sh must execute check_pr_governance.sh",
            path="scripts/ci/check_quality.sh",
            evidence_ref="scripts/ci/check_quality.sh",
            error_code="GOV.HARD_GATE_PR_GOV_MISSING",
        )

    if not microtask_path.exists():
        return RuleEvaluation(
            passed=False,
            message="missing PRD master for microtask hard gate",
            path="PRD/PRD-MASTER.md",
            evidence_ref="PRD/PRD-MASTER.md",
            error_code="GOV.HARD_GATE_MICROTASK_DOC_MISSING",
        )
    microtask_text = microtask_path.read_text(encoding="utf-8", errors="ignore")
    if "runs/<issue_id>/<microtask_id>/" not in microtask_text:
        return RuleEvaluation(
            passed=False,
            message="PRD-MASTER missing runs/<issue_id>/<microtask_id>/ marker",
            path="PRD/PRD-MASTER.md",
            evidence_ref="PRD/PRD-MASTER.md",
            error_code="GOV.HARD_GATE_MICROTASK_MARKER_MISSING",
        )

    return RuleEvaluation(passed=True)


def build_governance_rules(manifest: ContractManifest) -> tuple[PolicyRule, ...]:
    if manifest.domain != "governance":
        raise ValueError("governance manifest expected")

    implementation_map: dict[str, Checker] = {
        "weekly_governance_contract": check_weekly_governance,
        "shell_wrapper_line_limits": check_shell_wrapper_limits,
        "reconstruction_kpi_baseline": check_reconstruction_kpi_baseline,
        "ownership_spof_controls": check_ownership_spof,
        "runtime_hard_gates": check_runtime_hard_gates,
    }

    out: list[PolicyRule] = []
    for contract in manifest.rules:
        if not contract.enabled:
            continue
        checker = implementation_map.get(contract.implementation)
        if checker is None:
            raise ValueError(
                "governance contract "
                f"'{contract.rule_id}' references unknown implementation '{contract.implementation}'"
            )
        out.append(ManifestRule(contract, checker))

    return tuple(out)
