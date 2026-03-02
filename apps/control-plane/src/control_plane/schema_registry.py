from __future__ import annotations

import json
from pathlib import Path

from jsonschema import Draft202012Validator, FormatChecker
from jsonschema.exceptions import ValidationError

from control_plane.errors import ControlPlaneError


DEFAULT_SCHEMA_MAP: dict[str, str] = {
    "models_catalog": "ARC/schemas/models_catalog.schema.json",
    "router_decision": "ARC/schemas/router_decision.schema.json",
    "llm_run": "ARC/schemas/llm_run.schema.json",
    "credits_snapshot": "ARC/schemas/credits_snapshot.schema.json",
    "budget_governor_policy": "ARC/schemas/budget_governor_policy.schema.json",
    "a2a_delegation_event": "ARC/schemas/a2a_delegation_event.schema.json",
    "webhook_ingest_event": "ARC/schemas/webhook_ingest_event.schema.json",
}


class SchemaRegistry:
    def __init__(self, root: Path, schema_map: dict[str, str] | None = None) -> None:
        self.root = root
        self.schema_map = schema_map or DEFAULT_SCHEMA_MAP
        self._validators: dict[str, Draft202012Validator] = {}

    def validate(self, schema_name: str, payload: dict[str, object]) -> None:
        validator = self._validator(schema_name)
        try:
            validator.validate(payload)
        except ValidationError as exc:
            loc = ".".join([str(item) for item in exc.absolute_path])
            path = loc if loc else "$"
            raise ControlPlaneError(
                code="SCHEMA_VALIDATION_FAILED",
                message=f"schema '{schema_name}' validation failed at {path}: {exc.message}",
                status_code=422,
                details={"schema": schema_name, "path": path},
            ) from exc

    def _validator(self, schema_name: str) -> Draft202012Validator:
        cached = self._validators.get(schema_name)
        if cached is not None:
            return cached

        rel_path = self.schema_map.get(schema_name)
        if rel_path is None:
            raise ControlPlaneError(
                code="SCHEMA_NOT_REGISTERED",
                message=f"schema '{schema_name}' is not registered",
                status_code=500,
            )

        path = self.root / rel_path
        if not path.exists():
            raise ControlPlaneError(
                code="SCHEMA_FILE_MISSING",
                message=f"schema file not found: {rel_path}",
                status_code=500,
            )

        schema = json.loads(path.read_text(encoding="utf-8"))
        validator = Draft202012Validator(schema, format_checker=FormatChecker())
        self._validators[schema_name] = validator
        return validator
