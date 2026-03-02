from __future__ import annotations

from pathlib import Path
from typing import Any

import yaml


class YamlLoadError(ValueError):
    pass


def load_yaml_file(path: Path) -> Any:
    if not path.exists():
        raise YamlLoadError(f"missing YAML file: {path}")
    try:
        payload = yaml.safe_load(path.read_text(encoding="utf-8"))
    except yaml.YAMLError as exc:
        raise YamlLoadError(f"invalid YAML at {path}: {exc}") from exc
    return payload
