from __future__ import annotations

from dataclasses import dataclass

ALLOWED_DOMAINS: frozenset[str] = frozenset({"runtime", "security", "governance", "trading"})
ALLOWED_SEVERITIES: frozenset[str] = frozenset({"critical", "high", "medium", "low"})


@dataclass(frozen=True)
class RuleContract:
    rule_id: str
    domain: str
    severity: str
    category: str
    implementation: str
    evidence_refs: tuple[str, ...]
    remediation_hint: str
    enabled: bool = True


@dataclass(frozen=True)
class ContractManifest:
    schema_version: str
    domain: str
    rules: tuple[RuleContract, ...]
