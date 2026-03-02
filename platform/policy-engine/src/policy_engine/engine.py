from __future__ import annotations

from datetime import UTC, datetime
from pathlib import Path
from time import perf_counter

from policy_engine.application.convergence import validate_policy_convergence
from policy_engine.domain.contract_loader import load_contracts
from policy_engine.domain.models import PolicyMetrics, PolicyRunResult, RuleResult, RuleViolation
from policy_engine.domain.policy_rule import PolicyContext, PolicyRule
from policy_engine.rules.governance import build_governance_rules
from policy_engine.rules.runtime import build_runtime_rules
from policy_engine.rules.security import build_security_rules
from policy_engine.rules.trading import build_trading_rules


def _run_id() -> str:
    now = datetime.now(tz=UTC)
    return now.strftime("policy-run-%Y%m%dT%H%M%SZ")


def _resolve_rules(domain: str, root: Path) -> tuple[PolicyRule, ...]:
    if domain == "runtime":
        manifests = load_contracts(root, ("runtime",))
        return build_runtime_rules(manifests["runtime"])
    if domain == "security":
        manifests = load_contracts(root, ("security",))
        return build_security_rules(manifests["security"])
    if domain == "governance":
        manifests = load_contracts(root, ("governance",))
        return build_governance_rules(manifests["governance"])
    if domain == "trading":
        manifests = load_contracts(root, ("trading",))
        return build_trading_rules(manifests["trading"])
    if domain == "all":
        manifests = load_contracts(root, ("runtime", "security", "governance", "trading"))
        runtime_rules = build_runtime_rules(manifests["runtime"])
        security_rules = build_security_rules(manifests["security"])
        governance_rules = build_governance_rules(manifests["governance"])
        trading_rules = build_trading_rules(manifests["trading"])
        return runtime_rules + security_rules + governance_rules + trading_rules
    raise ValueError(f"unsupported domain: {domain}")


def _evaluate_rule(
    *,
    context: PolicyContext,
    rule: PolicyRule,
) -> tuple[RuleResult, RuleViolation | None]:
    started_at = perf_counter()
    outcome = rule.evaluate(context)
    elapsed_ms = int((perf_counter() - started_at) * 1000)

    evidence_ref = outcome.evidence_ref
    if evidence_ref is None and rule.evidence_refs:
        evidence_ref = rule.evidence_refs[0]

    error_code = outcome.error_code
    if error_code is None and not outcome.passed:
        error_code = f"{rule.id}.VIOLATION"

    result = RuleResult(
        rule_id=rule.id,
        status="PASS" if outcome.passed else "FAIL",
        severity=rule.severity,
        runtime_ms=elapsed_ms,
        error_code=error_code,
        category=rule.category,
        evidence_ref=evidence_ref,
    )

    if outcome.passed:
        return result, None

    violation = RuleViolation(
        rule_id=rule.id,
        domain=rule.domain,
        severity=rule.severity,
        error_code=error_code or f"{rule.id}.VIOLATION",
        message=outcome.message or f"rule failed: {rule.id}",
        path=outcome.path,
        category=rule.category,
        evidence_ref=evidence_ref,
        remediation_hint=rule.remediation_hint,
    )
    return result, violation


def run_domain(domain: str, root: Path, *, category: str | None = None) -> PolicyRunResult:
    context = PolicyContext(root=root)
    all_rules = _resolve_rules(domain, root)

    selected_rules: list[PolicyRule] = []
    for rule in all_rules:
        if category is not None and rule.category != category:
            continue
        selected_rules.append(rule)

    rule_results: list[RuleResult] = []
    violations: list[RuleViolation] = []

    for rule in selected_rules:
        result, violation = _evaluate_rule(context=context, rule=rule)
        rule_results.append(result)
        if violation is not None:
            violations.append(violation)

    total_rules = len(rule_results)
    passed_rules = sum(1 for r in rule_results if r.status == "PASS")
    failed_rules = total_rules - passed_rules

    contradiction_count = 0
    if category is None:
        contradiction_count = len(validate_policy_convergence(root))

    runtime_total = sum(item.runtime_ms for item in rule_results)
    pass_rate = 100.0 if total_rules == 0 else round((passed_rules / total_rules) * 100.0, 2)

    return PolicyRunResult(
        schema_version="2.0",
        run_id=_run_id(),
        status="FAIL" if failed_rules else "PASS",
        domain=domain,
        total_rules=total_rules,
        passed_rules=passed_rules,
        failed_rules=failed_rules,
        violations=tuple(violations),
        rule_results=tuple(rule_results),
        metrics=PolicyMetrics(
            pass_rate=pass_rate,
            contradiction_count=contradiction_count,
            rule_runtime_ms_total=runtime_total,
        ),
    )
