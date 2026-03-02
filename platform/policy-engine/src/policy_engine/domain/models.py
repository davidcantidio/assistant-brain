from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class RuleViolation:
    rule_id: str
    domain: str
    severity: str
    error_code: str
    message: str
    path: str | None = None
    category: str | None = None
    evidence_ref: str | None = None
    remediation_hint: str | None = None


@dataclass(frozen=True)
class RuleResult:
    rule_id: str
    status: str
    severity: str
    runtime_ms: int
    error_code: str | None = None
    category: str | None = None
    evidence_ref: str | None = None


@dataclass(frozen=True)
class PolicyMetrics:
    pass_rate: float
    contradiction_count: int
    rule_runtime_ms_total: int


@dataclass(frozen=True)
class PolicyRunResult:
    schema_version: str
    run_id: str
    status: str
    domain: str
    total_rules: int
    passed_rules: int
    failed_rules: int
    violations: tuple[RuleViolation, ...]
    rule_results: tuple[RuleResult, ...]
    metrics: PolicyMetrics
