from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class CodeownersRule:
    pattern: str
    owners: tuple[str, ...]


def parse_codeowners(text: str) -> tuple[CodeownersRule, ...]:
    rules: list[CodeownersRule] = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) < 2:
            continue
        pattern = parts[0]
        owners = tuple(part for part in parts[1:] if part.startswith("@"))
        if not owners:
            continue
        rules.append(CodeownersRule(pattern=pattern, owners=owners))
    return tuple(rules)


def parse_codeowners_file(path: Path) -> tuple[CodeownersRule, ...]:
    return parse_codeowners(path.read_text(encoding="utf-8", errors="ignore"))


def global_owners(rules: tuple[CodeownersRule, ...]) -> tuple[str, ...]:
    for rule in rules:
        if rule.pattern == "*":
            return rule.owners
    return tuple()
