from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Callable

from policy_engine.domain.contract_models import ContractManifest, RuleContract
from policy_engine.domain.policy_rule import PolicyContext, PolicyRule, RuleEvaluation

REQUIRED_FILES: tuple[str, ...] = (
    "META/DOCUMENT-HIERARCHY.md",
    "PRD/PRD-MASTER.md",
    "ARC/ARC-CORE.md",
    "ARC/schemas/openclaw_runtime_config.schema.json",
    "ARC/schemas/ops_autonomy_contract.schema.json",
    "ARC/schemas/nightly_memory_cycle.schema.json",
    "ARC/schemas/llm_run.schema.json",
    "ARC/schemas/router_decision.schema.json",
    "ARC/schemas/credits_snapshot.schema.json",
    "ARC/schemas/budget_governor_policy.schema.json",
    "ARC/schemas/a2a_delegation_event.schema.json",
    "ARC/schemas/webhook_ingest_event.schema.json",
    "CORE/FINANCIAL-GOVERNANCE.md",
    "EVALS/SYSTEM-HEALTH-THRESHOLDS.md",
    "SEC/SEC-POLICY.md",
    "PM/DECISION-PROTOCOL.md",
    "ARC/ARC-HEARTBEAT.md",
    "workspaces/main/HEARTBEAT.md",
    "workspaces/main/MEMORY.md",
    "workspaces/main/.openclaw/workspace-state.json",
    "PRD/CHANGELOG.md",
    "apps/control-plane/README.md",
    "apps/ops-api/README.md",
    "contracts/runtime/ops_api.v1.yaml",
    "scripts/ci/eval_runtime_control_plane.sh",
    "apps/control-plane/tests/test_service.py",
    "apps/ops-api/tests/test_app.py",
)

REQUIRED_RUNTIME_FIELDS: tuple[str, ...] = (
    "agents",
    "tools",
    "channels",
    "hooks",
    "memory",
    "gateway",
)

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


def _load_json(root: Path, rel_path: str) -> tuple[dict[str, object] | None, RuleEvaluation | None]:
    path = root / rel_path
    if not path.exists():
        return None, RuleEvaluation(
            passed=False, message=f"missing file: {rel_path}", path=rel_path
        )

    try:
        loaded = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return None, RuleEvaluation(
            passed=False,
            message=f"invalid JSON at {rel_path}: {exc}",
            path=rel_path,
        )

    if not isinstance(loaded, dict):
        return None, RuleEvaluation(
            passed=False,
            message=f"invalid JSON object at {rel_path}",
            path=rel_path,
        )

    return loaded, None


def check_required_files(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    missing = [rel for rel in REQUIRED_FILES if not (context.root / rel).exists()]
    if not missing:
        return RuleEvaluation(passed=True)

    return RuleEvaluation(
        passed=False,
        message=f"required runtime files missing: {', '.join(missing[:5])}",
        path=missing[0],
        evidence_ref=missing[0],
    )


def check_runtime_schema_valid_json(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    payload, error = _load_json(context.root, "ARC/schemas/openclaw_runtime_config.schema.json")
    if error is not None:
        return error
    if payload is None:
        return RuleEvaluation(
            passed=False,
            message="runtime schema payload not loaded",
            path="ARC/schemas/openclaw_runtime_config.schema.json",
        )
    return RuleEvaluation(passed=True)


def check_runtime_schema_required_fields(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    payload, error = _load_json(context.root, "ARC/schemas/openclaw_runtime_config.schema.json")
    if error is not None:
        return error

    required_obj = payload.get("required") if payload is not None else None
    if not isinstance(required_obj, list):
        return RuleEvaluation(
            passed=False,
            message="openclaw_runtime_config.schema.json missing list field 'required'",
            path="ARC/schemas/openclaw_runtime_config.schema.json",
        )

    required = {str(item) for item in required_obj}
    missing = [item for item in REQUIRED_RUNTIME_FIELDS if item not in required]
    if missing:
        return RuleEvaluation(
            passed=False,
            message=f"runtime schema missing required fields: {', '.join(missing)}",
            path="ARC/schemas/openclaw_runtime_config.schema.json",
        )

    return RuleEvaluation(passed=True)


def check_idempotency_schema_contract(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    payload, error = _load_json(context.root, "ARC/schemas/decision.schema.json")
    if error is not None:
        return error

    required_obj = payload.get("required") if payload is not None else None
    if not isinstance(required_obj, list):
        return RuleEvaluation(
            passed=False,
            message="decision.schema.json missing list field 'required'",
            path="ARC/schemas/decision.schema.json",
        )

    required = {str(item) for item in required_obj}
    required_challenge = {"challenge_id", "challenge_status", "challenge_expires_at"}
    missing_required = sorted(required_challenge - required)
    if missing_required:
        return RuleEvaluation(
            passed=False,
            message=f"decision schema missing challenge required fields: {missing_required}",
            path="ARC/schemas/decision.schema.json",
        )

    props_obj = payload.get("properties") if payload is not None else None
    if not isinstance(props_obj, dict):
        return RuleEvaluation(
            passed=False,
            message="decision schema missing 'properties' object",
            path="ARC/schemas/decision.schema.json",
        )

    challenge_status = props_obj.get("challenge_status")
    if not isinstance(challenge_status, dict):
        return RuleEvaluation(
            passed=False,
            message="decision schema missing properties.challenge_status",
            path="ARC/schemas/decision.schema.json",
        )

    enum_obj = challenge_status.get("enum")
    if not isinstance(enum_obj, list):
        return RuleEvaluation(
            passed=False,
            message="decision schema missing enum for challenge_status",
            path="ARC/schemas/decision.schema.json",
        )

    expected_status = {"NOT_REQUIRED", "PENDING", "VALIDATED", "EXPIRED", "INVALIDATED"}
    if {str(item) for item in enum_obj} != expected_status:
        return RuleEvaluation(
            passed=False,
            message="decision schema has invalid challenge_status enum",
            path="ARC/schemas/decision.schema.json",
        )

    challenge_expires = props_obj.get("challenge_expires_at")
    if not isinstance(challenge_expires, dict):
        return RuleEvaluation(
            passed=False,
            message="decision schema missing properties.challenge_expires_at",
            path="ARC/schemas/decision.schema.json",
        )

    expires_type = challenge_expires.get("type")
    if not isinstance(expires_type, list) or sorted(str(item) for item in expires_type) != [
        "null",
        "string",
    ]:
        return RuleEvaluation(
            passed=False,
            message="decision schema invalid type for challenge_expires_at (expected string|null)",
            path="ARC/schemas/decision.schema.json",
        )

    if challenge_expires.get("format") != "date-time":
        return RuleEvaluation(
            passed=False,
            message="decision schema invalid format for challenge_expires_at (expected date-time)",
            path="ARC/schemas/decision.schema.json",
        )

    return RuleEvaluation(passed=True)


def check_idempotency_protocol_markers(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    rel_path = "PM/DECISION-PROTOCOL.md"
    path = context.root / rel_path
    if not path.exists():
        return RuleEvaluation(passed=False, message=f"missing file: {rel_path}", path=rel_path)

    text = path.read_text(encoding="utf-8", errors="ignore")
    patterns: tuple[tuple[str, str], ...] = (
        (r"command_id.*unico", "marker de command_id unico ausente"),
        (r"no-op", "marker de no-op para replay ausente"),
        (r"auditado como replay", "marker de auditoria de replay ausente"),
    )

    for pattern, message in patterns:
        if re.search(pattern, text, flags=re.IGNORECASE) is None:
            return RuleEvaluation(passed=False, message=message, path=rel_path)

    return RuleEvaluation(passed=True)


def check_timezone_anchor_markers(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    refs: tuple[str, ...] = (
        "PRD/PRD-MASTER.md",
        "ARC/ARC-HEARTBEAT.md",
        "workspaces/main/HEARTBEAT.md",
        "PRD/CHANGELOG.md",
    )
    expected = "America/Sao_Paulo"
    for rel in refs:
        path = context.root / rel
        if not path.exists():
            return RuleEvaluation(passed=False, message=f"missing file: {rel}", path=rel)
        if expected not in path.read_text(encoding="utf-8", errors="ignore"):
            return RuleEvaluation(
                passed=False,
                message=f"timezone anchor '{expected}' missing in {rel}",
                path=rel,
            )
    return RuleEvaluation(passed=True)


def check_ops_api_contract(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    rel_path = "contracts/runtime/ops_api.v1.yaml"
    payload, error = _load_json(context.root, rel_path)
    if error is not None:
        return error

    if payload is None:
        return RuleEvaluation(
            passed=False,
            message="ops_api.v1 contract payload not loaded",
            path=rel_path,
        )

    base_url = payload.get("base_url")
    if base_url != "http://127.0.0.1:18901/v1":
        return RuleEvaluation(
            passed=False,
            message="ops_api.v1 base_url must be http://127.0.0.1:18901/v1",
            path=rel_path,
        )

    endpoints_obj = payload.get("endpoints")
    if not isinstance(endpoints_obj, list):
        return RuleEvaluation(
            passed=False,
            message="ops_api.v1 must define endpoints[]",
            path=rel_path,
        )

    expected_paths = {
        "POST /model-catalog/sync",
        "GET /model-catalog/models",
        "POST /router/decide",
        "POST /runs",
        "POST /budget/snapshots",
        "POST /budget/check",
        "POST /a2a/delegate",
        "POST /hooks/ingest",
    }
    actual_paths: set[str] = set()
    for item in endpoints_obj:
        if not isinstance(item, dict):
            continue
        method = str(item.get("method", "")).upper()
        path = str(item.get("path", ""))
        if method and path:
            actual_paths.add(f"{method} {path}")

    missing_paths = sorted(expected_paths - actual_paths)
    if missing_paths:
        return RuleEvaluation(
            passed=False,
            message=f"ops_api.v1 missing required endpoints: {missing_paths}",
            path=rel_path,
        )

    return RuleEvaluation(passed=True)


def check_runtime_schema_extensions(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    rel_path = "ARC/schemas/openclaw_runtime_config.schema.json"
    payload, error = _load_json(context.root, rel_path)
    if error is not None:
        return error
    if payload is None:
        return RuleEvaluation(
            passed=False,
            message="runtime config schema payload not loaded",
            path=rel_path,
        )

    properties_obj = payload.get("properties")
    if not isinstance(properties_obj, dict):
        return RuleEvaluation(
            passed=False,
            message="runtime schema missing root properties object",
            path=rel_path,
        )

    memory_obj = properties_obj.get("memory")
    if not isinstance(memory_obj, dict):
        return RuleEvaluation(
            passed=False,
            message="runtime schema missing memory section",
            path=rel_path,
        )
    memory_props = memory_obj.get("properties")
    if not isinstance(memory_props, dict) or "telemetry_store" not in memory_props:
        return RuleEvaluation(
            passed=False,
            message="runtime schema missing memory.telemetry_store",
            path=rel_path,
        )

    privacy_obj = properties_obj.get("privacy")
    if not isinstance(privacy_obj, dict):
        return RuleEvaluation(
            passed=False,
            message="runtime schema missing privacy section",
            path=rel_path,
        )
    privacy_props = privacy_obj.get("properties")
    if not isinstance(privacy_props, dict):
        return RuleEvaluation(
            passed=False,
            message="runtime schema missing privacy.properties",
            path=rel_path,
        )

    required_privacy_tokens = {
        "data_sensitivity_default",
        "provider_allowlist_by_sensitivity",
        "prompt_storage_mode",
    }
    missing_tokens = sorted(required_privacy_tokens - set(privacy_props.keys()))
    if missing_tokens:
        return RuleEvaluation(
            passed=False,
            message=f"runtime schema missing privacy fields: {missing_tokens}",
            path=rel_path,
        )

    return RuleEvaluation(passed=True)


def check_runtime_test_coverage(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    required_tests = (
        "apps/control-plane/tests/test_service.py",
        "apps/ops-api/tests/test_app.py",
        "scripts/ci/eval_runtime_control_plane.sh",
    )
    missing = [item for item in required_tests if not (context.root / item).exists()]
    if missing:
        return RuleEvaluation(
            passed=False,
            message=f"missing runtime control-plane tests/checkers: {missing}",
            path=missing[0],
        )
    return RuleEvaluation(passed=True)


def build_runtime_rules(manifest: ContractManifest) -> tuple[PolicyRule, ...]:
    if manifest.domain != "runtime":
        raise ValueError("runtime manifest expected")

    implementation_map: dict[str, Checker] = {
        "required_files": check_required_files,
        "runtime_schema_valid_json": check_runtime_schema_valid_json,
        "runtime_schema_required_fields": check_runtime_schema_required_fields,
        "idempotency_schema_contract": check_idempotency_schema_contract,
        "idempotency_protocol_markers": check_idempotency_protocol_markers,
        "timezone_anchor_markers": check_timezone_anchor_markers,
        "ops_api_contract": check_ops_api_contract,
        "runtime_schema_extensions": check_runtime_schema_extensions,
        "runtime_test_coverage": check_runtime_test_coverage,
    }

    out: list[PolicyRule] = []
    for contract in manifest.rules:
        if not contract.enabled:
            continue

        checker = implementation_map.get(contract.implementation)
        if checker is None:
            raise ValueError(
                f"runtime contract '{contract.rule_id}' references unknown implementation '{contract.implementation}'"
            )
        out.append(ManifestRule(contract, checker))

    return tuple(out)
