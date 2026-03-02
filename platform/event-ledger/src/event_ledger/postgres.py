from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

try:
    import psycopg
except ModuleNotFoundError:  # pragma: no cover - exercised in envs without psycopg
    psycopg = None  # type: ignore[assignment]


class ReplayRejectedError(RuntimeError):
    pass


@dataclass(frozen=True)
class LedgerEvent:
    event_id: str
    stream_id: str
    idempotency_key: str
    replay_key: str
    command_id: str
    author: str
    evidence_ref: str
    channel: str
    action: str
    occurred_at: str
    payload_digest: str
    payload_json: dict[str, object]


@dataclass(frozen=True)
class AppendResult:
    status: str
    event_id: str


class PostgresEventLedger:
    def __init__(self, dsn: str) -> None:
        self._dsn = dsn

    def _ensure_driver(self) -> None:
        if psycopg is None:
            raise RuntimeError("psycopg is required for PostgresEventLedger")

    def apply_migrations(self, migrations_dir: Path) -> None:
        self._ensure_driver()
        sql_files = sorted(migrations_dir.glob("*.sql"))
        if not sql_files:
            raise RuntimeError(f"no migrations found in {migrations_dir}")

        with psycopg.connect(self._dsn, autocommit=True) as conn:  # type: ignore[union-attr]
            with conn.cursor() as cur:
                for file_path in sql_files:
                    cur.execute(file_path.read_text(encoding="utf-8"))

    def append_event(self, event: LedgerEvent) -> AppendResult:
        self._ensure_driver()
        insert_sql = """
            INSERT INTO event_ledger (
                event_id,
                stream_id,
                idempotency_key,
                replay_key,
                command_id,
                author,
                evidence_ref,
                channel,
                action,
                occurred_at,
                payload_digest,
                payload_jsonb
            ) VALUES (
                %(event_id)s,
                %(stream_id)s,
                %(idempotency_key)s,
                %(replay_key)s,
                %(command_id)s,
                %(author)s,
                %(evidence_ref)s,
                %(channel)s,
                %(action)s,
                %(occurred_at)s,
                %(payload_digest)s,
                %(payload_jsonb)s::jsonb
            )
            ON CONFLICT (idempotency_key) DO NOTHING
            RETURNING event_id
        """
        select_sql = """
            SELECT event_id, stream_id, command_id, payload_digest
            FROM event_ledger
            WHERE idempotency_key = %(idempotency_key)s
            LIMIT 1
        """
        params = {
            "event_id": event.event_id,
            "stream_id": event.stream_id,
            "idempotency_key": event.idempotency_key,
            "replay_key": event.replay_key,
            "command_id": event.command_id,
            "author": event.author,
            "evidence_ref": event.evidence_ref,
            "channel": event.channel,
            "action": event.action,
            "occurred_at": event.occurred_at,
            "payload_digest": event.payload_digest,
            "payload_jsonb": json.dumps(event.payload_json, ensure_ascii=True),
        }

        with psycopg.connect(self._dsn, autocommit=True) as conn:  # type: ignore[union-attr]
            with conn.cursor() as cur:
                cur.execute(insert_sql, params)
                inserted = cur.fetchone()
                if inserted is not None:
                    return AppendResult(status="appended", event_id=str(inserted[0]))

                cur.execute(select_sql, {"idempotency_key": event.idempotency_key})
                existing = cur.fetchone()
                if existing is None:
                    raise RuntimeError("idempotency conflict without existing row")

                existing_event_id = str(existing[0])
                existing_stream_id = str(existing[1])
                existing_command_id = str(existing[2])
                existing_digest = str(existing[3])

                if (
                    existing_stream_id == event.stream_id
                    and existing_command_id == event.command_id
                    and existing_digest == event.payload_digest
                ):
                    return AppendResult(status="duplicate", event_id=existing_event_id)

                raise ReplayRejectedError(
                    "unauthorized replay detected for idempotency_key="
                    f"{event.idempotency_key} (existing_event_id={existing_event_id})"
                )

    def read_stream(self, stream_id: str, *, limit: int = 100) -> list[dict[str, Any]]:
        self._ensure_driver()
        query = """
            SELECT
                event_id,
                stream_id,
                idempotency_key,
                replay_key,
                command_id,
                author,
                evidence_ref,
                channel,
                action,
                occurred_at::text,
                payload_digest,
                payload_jsonb::text
            FROM event_ledger
            WHERE stream_id = %(stream_id)s
            ORDER BY sequence_id ASC
            LIMIT %(limit)s
        """
        rows: list[dict[str, Any]] = []
        with psycopg.connect(self._dsn, autocommit=True) as conn:  # type: ignore[union-attr]
            with conn.cursor() as cur:
                cur.execute(query, {"stream_id": stream_id, "limit": limit})
                for row in cur.fetchall():
                    rows.append(
                        {
                            "event_id": row[0],
                            "stream_id": row[1],
                            "idempotency_key": row[2],
                            "replay_key": row[3],
                            "command_id": row[4],
                            "author": row[5],
                            "evidence_ref": row[6],
                            "channel": row[7],
                            "action": row[8],
                            "occurred_at": row[9],
                            "payload_digest": row[10],
                            "payload_json": json.loads(str(row[11])),
                        }
                    )
        return rows
