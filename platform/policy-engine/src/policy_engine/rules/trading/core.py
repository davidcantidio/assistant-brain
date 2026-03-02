from __future__ import annotations

import re
import subprocess
from typing import Callable

from policy_engine.domain.contract_models import ContractManifest, RuleContract
from policy_engine.domain.policy_rule import PolicyContext, PolicyRule, RuleEvaluation

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


def check_trading_eval_contract(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    rel_path = "scripts/ci/legacy/eval_trading_legacy.sh"
    script_path = context.root / rel_path
    if not script_path.exists():
        return RuleEvaluation(
            passed=False,
            message=f"missing trading legacy script: {rel_path}",
            path=rel_path,
            evidence_ref=rel_path,
            error_code="TRD.MISSING_LEGACY_SCRIPT",
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

    line = (proc.stderr.strip() or proc.stdout.strip()).splitlines()[-1:] or ["trading eval failed"]
    return RuleEvaluation(
        passed=False,
        message=f"legacy trading eval failed: {line[0]}",
        path=rel_path,
        evidence_ref=rel_path,
        error_code="TRD.EVAL_CONTRACT_FAIL",
    )


def check_live_readiness_guardrail(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    rel_path = "SEC/allowlists/OPERATORS.yaml"
    path = context.root / rel_path
    if not path.exists():
        return RuleEvaluation(
            passed=False,
            message=f"missing file: {rel_path}",
            path=rel_path,
            evidence_ref=rel_path,
            error_code="TRD.OPERATORS_ALLOWLIST_MISSING",
        )

    text = path.read_text(encoding="utf-8", errors="ignore")
    live_ready_match = re.search(r"live_ready:\s*(true|false)", text)
    live_ready = (live_ready_match.group(1) == "true") if live_ready_match else False
    if not live_ready:
        return RuleEvaluation(passed=True)

    required_markers = (
        "trading_live_requires_backup_operator: true",
        "backup_operator_operator_id:",
    )
    for marker in required_markers:
        if marker not in text:
            return RuleEvaluation(
                passed=False,
                message=f"live_ready=true requires marker in OPERATORS.yaml: {marker}",
                path=rel_path,
                evidence_ref=rel_path,
                error_code="TRD.LIVE_READY_GUARDRAIL_MISSING",
            )

    checklist_rel = "artifacts/trading/pre_live_checklist/CHECKLIST-F7-02-S1-20260301-01.json"
    if not (context.root / checklist_rel).exists():
        return RuleEvaluation(
            passed=False,
            message=(
                "live_ready=true requires an audited pre-live checklist artifact. "
                f"missing {checklist_rel}"
            ),
            path=checklist_rel,
            evidence_ref=checklist_rel,
            error_code="TRD.LIVE_READY_CHECKLIST_MISSING",
        )

    readiness_rel = "artifacts/governance/phase1-readiness-checklist.md"
    readiness_path = context.root / readiness_rel
    if not readiness_path.exists():
        return RuleEvaluation(
            passed=False,
            message=f"live_ready=true requires readiness checklist: {readiness_rel}",
            path=readiness_rel,
            evidence_ref=readiness_rel,
            error_code="TRD.LIVE_READY_READINESS_CHECKLIST_MISSING",
        )
    readiness_text = readiness_path.read_text(encoding="utf-8", errors="ignore")
    if "status: PASS" not in readiness_text:
        return RuleEvaluation(
            passed=False,
            message="live_ready=true requires readiness checklist with status: PASS",
            path=readiness_rel,
            evidence_ref=readiness_rel,
            error_code="TRD.LIVE_READY_READINESS_CHECKLIST_NOT_PASS",
        )

    return RuleEvaluation(passed=True)


def build_trading_rules(manifest: ContractManifest) -> tuple[PolicyRule, ...]:
    if manifest.domain != "trading":
        raise ValueError("trading manifest expected")

    implementation_map: dict[str, Checker] = {
        "trading_eval_contract": check_trading_eval_contract,
        "live_readiness_guardrail": check_live_readiness_guardrail,
    }

    out: list[PolicyRule] = []
    for contract in manifest.rules:
        if not contract.enabled:
            continue
        checker = implementation_map.get(contract.implementation)
        if checker is None:
            raise ValueError(
                f"trading contract '{contract.rule_id}' references unknown implementation "
                f"'{contract.implementation}'"
            )
        out.append(ManifestRule(contract, checker))

    return tuple(out)
