#!/usr/bin/env python3
"""Build runtime_merge_plan.v1 from .env + runtime config + PRD schema."""

from __future__ import annotations

import argparse
import datetime as dt
import json
from pathlib import Path
from typing import Any


PRESERVE_PATHS = [
    "auth",
    "channels",
    "agents",
    "messages",
    "commands",
    "plugins",
    "wizard",
]


def parse_env(path: Path) -> dict[str, str]:
    env: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        env[key.strip()] = value.strip()
    return env


def load_json(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(data, dict):
        return data
    raise ValueError(f"JSON invalido em {path}: esperado objeto.")


def get_path(payload: dict[str, Any], path: str) -> Any:
    cur: Any = payload
    for key in path.split("."):
        if not isinstance(cur, dict) or key not in cur:
            return None
        cur = cur[key]
    return cur


def set_path(payload: dict[str, Any], path: str, value: Any) -> None:
    cur: dict[str, Any] = payload
    parts = path.split(".")
    for key in parts[:-1]:
        nxt = cur.get(key)
        if not isinstance(nxt, dict):
            nxt = {}
            cur[key] = nxt
        cur = nxt
    cur[parts[-1]] = value


def parse_gateway_port(env: dict[str, str]) -> int:
    raw = env.get("OPENCLAW_GATEWAY_PORT", "").strip()
    if raw:
        return int(raw)

    url = env.get("OPENCLAW_GATEWAY_URL", "").strip()
    if ":" in url:
        maybe_port = url.rsplit(":", 1)[-1].split("/")[0]
        if maybe_port.isdigit():
            return int(maybe_port)
    return 18789


def parse_heartbeat(env: dict[str, str]) -> str:
    raw = env.get("HEARTBEAT_MINUTES", "").strip()
    if raw.isdigit() and int(raw) > 0:
        return f"{int(raw)}m"
    return "15m"


def schema_gaps(runtime_cfg: dict[str, Any], schema: dict[str, Any]) -> list[dict[str, Any]]:
    gaps: list[dict[str, Any]] = []

    required_top = schema.get("required", [])
    if isinstance(required_top, list):
        for key in required_top:
            if key not in runtime_cfg:
                gaps.append(
                    {
                        "type": "missing_top_level",
                        "path": key,
                        "reason": "required no schema canonico",
                    }
                )

    channel_required = (
        ((schema.get("properties") or {}).get("channels") or {}).get("required")
    )
    runtime_channels = runtime_cfg.get("channels") if isinstance(runtime_cfg.get("channels"), dict) else {}
    if isinstance(channel_required, list):
        for ch in channel_required:
            if ch not in runtime_channels:
                gaps.append(
                    {
                        "type": "missing_channel_in_runtime",
                        "path": f"channels.{ch}",
                        "reason": "schema exige canal explicito",
                    }
                )

    return gaps


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--env-file", required=True)
    parser.add_argument("--runtime-json", required=True)
    parser.add_argument("--prd-schema", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    env_file = Path(args.env_file)
    runtime_json = Path(args.runtime_json)
    schema_json = Path(args.prd_schema)
    out_file = Path(args.out)

    env = parse_env(env_file)
    runtime_payload = load_json(runtime_json)
    runtime_cfg = runtime_payload.get("runtime_config") if isinstance(runtime_payload.get("runtime_config"), dict) else runtime_payload
    schema = load_json(schema_json)

    enforce_paths: dict[str, Any] = {
        "gateway.bind": "loopback",
        "gateway.port": parse_gateway_port(env),
        "agents.defaults.heartbeat.every": parse_heartbeat(env),
    }

    operations: list[dict[str, Any]] = []
    for path, desired in enforce_paths.items():
        current = get_path(runtime_cfg, path)
        if current == desired:
            continue
        operations.append(
            {
                "op": "set",
                "path": path,
                "current": current,
                "value": desired,
                "reason": "convergencia PRD/.env",
            }
        )

    utc_now = dt.datetime.now(dt.timezone.utc)
    plan = {
        "schema": "runtime_merge_plan.v1",
        "plan_id": f"RMP-{utc_now.strftime('%Y%m%d-%H%M%S')}",
        "generated_at": utc_now.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "profile": runtime_payload.get("profile", "active"),
        "preserve_paths": PRESERVE_PATHS,
        "enforce_paths": enforce_paths,
        "allowlist_changed_paths": [
            "gateway.bind",
            "gateway.port",
            "agents.defaults.heartbeat.every",
            "meta.lastTouchedAt",
            "meta.lastTouchedVersion",
        ],
        "operations": operations,
        "rollback": {
            "strategy": "restore_state_dir_backup",
            "backup_required": True,
            "backup_scope": "full_state_dir",
            "notes": "restaurar backup integral antes do restart do gateway",
        },
        "schema_gaps": schema_gaps(runtime_cfg, schema),
        "sources": {
            "env_file": str(env_file),
            "runtime_json": str(runtime_json),
            "prd_schema": str(schema_json),
        },
    }

    out_file.parent.mkdir(parents=True, exist_ok=True)
    out_file.write_text(json.dumps(plan, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")
    print(f"runtime_merge_plan.v1 written: {out_file}")
    print(f"plan_id={plan['plan_id']}")
    print(f"operations={len(operations)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
