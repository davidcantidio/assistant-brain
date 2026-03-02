from __future__ import annotations

import json
import re
from datetime import UTC, datetime
from pathlib import Path
from typing import Any, Iterable, Sequence


class CheckFailure(RuntimeError):
    pass


JSON = dict[str, Any]


def fail(message: str) -> None:
    raise CheckFailure(message)


def utc_now() -> str:
    return datetime.now(tz=UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def ensure_files(root: Path, rel_paths: Sequence[str]) -> None:
    missing = [rel for rel in rel_paths if not (root / rel).exists()]
    if missing:
        fail("Arquivo obrigatorio ausente: " + ", ".join(missing))


def read_text(root: Path, rel_path: str) -> str:
    path = root / rel_path
    if not path.exists():
        fail(f"Arquivo obrigatorio ausente: {rel_path}")
    return path.read_text(encoding="utf-8", errors="ignore")


def load_json(root: Path, rel_path: str) -> JSON:
    text = read_text(root, rel_path)
    try:
        payload = json.loads(text)
    except json.JSONDecodeError as exc:
        fail(f"json invalido em {rel_path}: {exc}")
    if not isinstance(payload, dict):
        fail(f"{rel_path} deve conter um objeto JSON.")
    return payload


def json_tool(root: Path, rel_path: str) -> None:
    load_json(root, rel_path)


def _search(pattern: str, text: str, *, fixed: bool) -> bool:
    if fixed:
        return pattern in text
    return re.search(pattern, text, flags=re.MULTILINE) is not None


def search(root: Path, pattern: str, rel_paths: Sequence[str], *, fixed: bool = False) -> None:
    for rel_path in rel_paths:
        text = read_text(root, rel_path)
        if _search(pattern, text, fixed=fixed):
            return
    fail(f"Padrao obrigatorio ausente: {pattern}")


def search_each_file(root: Path, pattern: str, rel_paths: Sequence[str], *, fixed: bool = False) -> None:
    for rel_path in rel_paths:
        text = read_text(root, rel_path)
        if not _search(pattern, text, fixed=fixed):
            prefix = "Texto obrigatorio ausente" if fixed else "Padrao obrigatorio ausente"
            fail(f"{prefix} em {rel_path}: {pattern}")


def search_absent(root: Path, pattern: str, rel_paths: Sequence[str], *, fixed: bool = False) -> None:
    for rel_path in rel_paths:
        text = read_text(root, rel_path)
        if _search(pattern, text, fixed=fixed):
            fail(f"Padrao proibido encontrado em {rel_path}: {pattern}")


def write_output(output_path: Path | None, payload: JSON) -> None:
    if output_path is None:
        return
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(payload, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")


def parse_iso8601(value: str, field: str) -> None:
    if not isinstance(value, str):
        raise ValueError(f"{field} deve ser string ISO-8601.")
    try:
        datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ValueError(f"{field} invalido: {exc}") from exc


def ensure_json_paths(root: Path, rel_paths: Iterable[str]) -> None:
    for rel_path in rel_paths:
        json_tool(root, rel_path)
