from __future__ import annotations

import re
from pathlib import Path

_LINK_PATTERN = re.compile(r"\[[^\]]+\]\(([^)]+)\)")


def _skip_path(path: Path) -> bool:
    parts = path.parts
    if ".git" in parts:
        return True
    return any(part.startswith(".venv") for part in parts)


def _markdown_files(root: Path) -> list[Path]:
    files: list[Path] = []
    for path in root.rglob("*.md"):
        if _skip_path(path):
            continue
        files.append(path)
    return files


def validate_quality(root: Path) -> list[str]:
    errors: list[str] = []
    doc_ids: dict[str, list[str]] = {}

    for md_file in _markdown_files(root):
        text = md_file.read_text(encoding="utf-8", errors="ignore")
        for match in _LINK_PATTERN.finditer(text):
            target = match.group(1).strip()
            if target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            target = target.split("#", 1)[0]
            resolved = (md_file.parent / target).resolve()
            if not resolved.exists():
                rel_file = md_file.relative_to(root).as_posix()
                errors.append(
                    f"MISSING_LINK {rel_file} -> {target} ({resolved.relative_to(root.resolve()) if resolved.is_relative_to(root.resolve()) else resolved})"
                )

        lines = text.splitlines()
        if len(lines) < 3 or lines[0].strip() != "---":
            continue

        for line in lines[1:40]:
            stripped = line.strip()
            if stripped == "---":
                break
            if stripped.startswith("doc_id:"):
                doc_id = stripped.split(":", 1)[1].strip().strip('"')
                rel_file = md_file.relative_to(root).as_posix()
                doc_ids.setdefault(doc_id, []).append(rel_file)
                break

    for doc_id, files in sorted(doc_ids.items()):
        if len(files) > 1:
            errors.append(f"DUPLICATE_DOC_ID {doc_id} -> {files}")

    return errors
