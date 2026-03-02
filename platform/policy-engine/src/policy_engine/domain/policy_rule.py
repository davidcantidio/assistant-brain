from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Protocol


@dataclass(frozen=True)
class PolicyContext:
    root: Path


@dataclass(frozen=True)
class RuleEvaluation:
    passed: bool
    message: str = ""
    path: str | None = None
    evidence_ref: str | None = None
    error_code: str | None = None


class PolicyRule(Protocol):
    id: str
    domain: str
    severity: str
    category: str | None
    evidence_refs: tuple[str, ...]
    remediation_hint: str | None

    def evaluate(self, context: PolicyContext) -> RuleEvaluation: ...
