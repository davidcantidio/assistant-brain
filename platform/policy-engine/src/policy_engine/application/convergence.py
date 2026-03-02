from __future__ import annotations

from pathlib import Path

OPENROUTER_RULE = "OpenRouter e o adaptador cloud padrao (cloud-first), habilitado por default no runtime cloud e hibrido."

DOCS = (
    "README.md",
    "PRD/ROADMAP.md",
    "PRD/PRD-MASTER.md",
    "ARC/ARC-MODEL-ROUTING.md",
    "SEC/SEC-POLICY.md",
)

FORBIDDEN_DOC_PATTERNS = (
    "OpenRouter e adaptador cloud opcional, permanece desabilitado por default",
)

PROVIDER_POLICY_PATH = "SEC/allowlists/PROVIDERS.yaml"
REQUIRED_PROVIDER_LINES = (
    'cloud_adapter_default: "enabled"',
    'cloud_adapter_enablement: "default_on"',
    'cloud_adapter_primary: "openrouter"',
)
FORBIDDEN_PROVIDER_LINES = (
    'cloud_adapter_default: "disabled"',
    'cloud_adapter_enablement: "decision_required"',
    'cloud_adapter_preferred_when_enabled: "openrouter"',
)


def _read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore")


def validate_policy_convergence(root: Path) -> list[str]:
    errors: list[str] = []

    for rel in DOCS:
        path = root / rel
        if not path.exists():
            errors.append(f"missing file: {rel}")
            continue
        text = _read_text(path)
        if OPENROUTER_RULE not in text:
            errors.append(f"missing openrouter rule in {rel}")
        for pattern in FORBIDDEN_DOC_PATTERNS:
            if pattern in text:
                errors.append(f"forbidden openrouter text in {rel}: {pattern}")

    provider_path = root / PROVIDER_POLICY_PATH
    if not provider_path.exists():
        errors.append(f"missing file: {PROVIDER_POLICY_PATH}")
        return errors

    provider_text = _read_text(provider_path)
    for required in REQUIRED_PROVIDER_LINES:
        if required not in provider_text:
            errors.append(f"missing provider policy line: {required}")
    for forbidden in FORBIDDEN_PROVIDER_LINES:
        if forbidden in provider_text:
            errors.append(f"forbidden provider policy line: {forbidden}")

    return errors
