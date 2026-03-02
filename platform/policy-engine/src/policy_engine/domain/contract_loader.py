from __future__ import annotations

import json
from pathlib import Path
from typing import Iterable

from policy_engine.domain.contract_models import (
    ALLOWED_DOMAINS,
    ALLOWED_SEVERITIES,
    ContractManifest,
    RuleContract,
)


def _as_non_empty_str(value: object, *, field_name: str, context: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{context}: invalid {field_name}")
    return value.strip()


def _as_string_list(value: object, *, field_name: str, context: str) -> tuple[str, ...]:
    if not isinstance(value, list) or not value:
        raise ValueError(f"{context}: invalid {field_name}")

    out: list[str] = []
    for item in value:
        if not isinstance(item, str) or not item.strip():
            raise ValueError(f"{context}: invalid {field_name} item")
        out.append(item.strip())
    return tuple(out)


def _parse_rule(
    raw_rule: object, *, index: int, manifest_domain: str, source: Path
) -> RuleContract:
    context = f"{source}:{index}"
    if not isinstance(raw_rule, dict):
        raise ValueError(f"{context}: rule must be an object")

    rule_id = _as_non_empty_str(raw_rule.get("rule_id"), field_name="rule_id", context=context)
    domain = _as_non_empty_str(raw_rule.get("domain"), field_name="domain", context=context)
    if domain not in ALLOWED_DOMAINS:
        raise ValueError(f"{context}: unsupported domain '{domain}'")
    if domain != manifest_domain:
        raise ValueError(
            f"{context}: domain '{domain}' does not match manifest domain '{manifest_domain}'"
        )

    severity = _as_non_empty_str(raw_rule.get("severity"), field_name="severity", context=context)
    if severity not in ALLOWED_SEVERITIES:
        raise ValueError(f"{context}: unsupported severity '{severity}'")

    category = _as_non_empty_str(raw_rule.get("category"), field_name="category", context=context)
    implementation = _as_non_empty_str(
        raw_rule.get("implementation"), field_name="implementation", context=context
    )
    evidence_refs = _as_string_list(
        raw_rule.get("evidence_refs"), field_name="evidence_refs", context=context
    )
    remediation_hint = _as_non_empty_str(
        raw_rule.get("remediation_hint"), field_name="remediation_hint", context=context
    )

    enabled_obj = raw_rule.get("enabled", True)
    if not isinstance(enabled_obj, bool):
        raise ValueError(f"{context}: invalid enabled flag")

    return RuleContract(
        rule_id=rule_id,
        domain=domain,
        severity=severity,
        category=category,
        implementation=implementation,
        evidence_refs=evidence_refs,
        remediation_hint=remediation_hint,
        enabled=enabled_obj,
    )


def load_contract_from_path(path: Path) -> ContractManifest:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"{path}: invalid YAML/JSON payload: {exc}") from exc

    if not isinstance(raw, dict):
        raise ValueError(f"{path}: manifest must be an object")

    schema_version = _as_non_empty_str(
        raw.get("schema_version"), field_name="schema_version", context=str(path)
    )
    if schema_version != "1.0":
        raise ValueError(f"{path}: unsupported contract schema_version '{schema_version}'")

    domain = _as_non_empty_str(raw.get("domain"), field_name="domain", context=str(path))
    if domain not in ALLOWED_DOMAINS:
        raise ValueError(f"{path}: unsupported domain '{domain}'")

    rules_obj = raw.get("rules")
    if not isinstance(rules_obj, list) or not rules_obj:
        raise ValueError(f"{path}: rules must be a non-empty list")

    rules: list[RuleContract] = []
    seen_ids: set[str] = set()
    for idx, raw_rule in enumerate(rules_obj):
        rule = _parse_rule(raw_rule, index=idx, manifest_domain=domain, source=path)
        if rule.rule_id in seen_ids:
            raise ValueError(f"{path}: duplicated rule_id '{rule.rule_id}'")
        seen_ids.add(rule.rule_id)
        rules.append(rule)

    return ContractManifest(schema_version=schema_version, domain=domain, rules=tuple(rules))


def load_contract(root: Path, domain: str) -> ContractManifest:
    if domain not in ALLOWED_DOMAINS:
        raise ValueError(f"unsupported domain '{domain}'")

    manifest_path = root / "platform/policy-engine/contracts" / f"{domain}.v1.yaml"
    if not manifest_path.exists():
        raise ValueError(f"missing contract manifest: {manifest_path}")
    return load_contract_from_path(manifest_path)


def load_contracts(root: Path, domains: Iterable[str]) -> dict[str, ContractManifest]:
    manifests: dict[str, ContractManifest] = {}
    for domain in domains:
        manifest = load_contract(root, domain)
        manifests[manifest.domain] = manifest
    return manifests
