from __future__ import annotations

import json
from dataclasses import asdict

from policy_engine.domain.models import PolicyRunResult


def to_json(result: PolicyRunResult) -> str:
    return json.dumps(asdict(result), ensure_ascii=True, indent=2)
