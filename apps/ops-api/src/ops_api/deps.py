from __future__ import annotations

import os
from pathlib import Path

from fastapi import Header, HTTPException, Request, status

from control_plane.schema_registry import SchemaRegistry
from control_plane.service import ControlPlaneService
from control_plane.store import InMemoryTelemetryStore, PostgresTelemetryStore

_service_singleton: ControlPlaneService | None = None


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def _parse_allowlist(value: str, fallback: tuple[str, ...]) -> tuple[str, ...]:
    parsed = [item.strip() for item in value.split(",") if item.strip()]
    if not parsed:
        return fallback
    return tuple(parsed)


def get_service() -> ControlPlaneService:
    global _service_singleton
    if _service_singleton is not None:
        return _service_singleton

    root = Path(os.getenv("OPENCLAW_ROOT", str(_repo_root()))).resolve()
    schemas = SchemaRegistry(root)

    backend = os.getenv("OPENCLAW_TELEMETRY_BACKEND", "memory").strip().lower()
    if backend == "postgres":
        dsn = os.getenv("OPENCLAW_TELEMETRY_DSN", "").strip()
        if not dsn:
            raise RuntimeError("OPENCLAW_TELEMETRY_DSN is required when backend=postgres")
        store = PostgresTelemetryStore(dsn)
    else:
        store = InMemoryTelemetryStore()

    provider_allowlist = {
        "public": _parse_allowlist(
            os.getenv("OPENCLAW_PROVIDER_ALLOWLIST_PUBLIC", "openrouter,ollama,litellm"),
            ("openrouter", "ollama", "litellm"),
        ),
        "internal": _parse_allowlist(
            os.getenv("OPENCLAW_PROVIDER_ALLOWLIST_INTERNAL", "openrouter,litellm"),
            ("openrouter", "litellm"),
        ),
        "sensitive": _parse_allowlist(
            os.getenv("OPENCLAW_PROVIDER_ALLOWLIST_SENSITIVE", "openrouter"),
            ("openrouter",),
        ),
    }

    prompt_storage_mode = os.getenv("OPENCLAW_PROMPT_STORAGE_MODE", "hash_and_summary")

    _service_singleton = ControlPlaneService(
        schemas=schemas,
        store=store,
        provider_allowlist_by_sensitivity=provider_allowlist,
        prompt_storage_mode=prompt_storage_mode,
    )
    return _service_singleton


def require_auth(request: Request) -> None:
    authz = request.headers.get("Authorization", "").strip()
    expected = os.getenv("OPENCLAW_OPS_API_TOKEN", "openclaw-dev-token")

    if not authz.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="missing Bearer token",
        )

    token = authz[7:].strip()
    if token != expected:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="invalid API token",
        )


def require_idempotency_key(
    x_idempotency_key: str = Header(default="", alias="X-Idempotency-Key"),
) -> str:
    key = x_idempotency_key.strip()
    if not key:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="X-Idempotency-Key is required",
        )
    return key
