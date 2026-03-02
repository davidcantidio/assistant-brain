from __future__ import annotations

import threading
from dataclasses import dataclass

from event_ledger.postgres import AppendResult, LedgerEvent, ReplayRejectedError


@dataclass
class _StoredEvent:
    event: LedgerEvent


class InMemoryEventLedger:
    def __init__(self) -> None:
        self._events_by_idempotency: dict[str, _StoredEvent] = {}
        self._streams: dict[str, list[LedgerEvent]] = {}
        self._lock = threading.Lock()

    def append_event(self, event: LedgerEvent) -> AppendResult:
        with self._lock:
            existing = self._events_by_idempotency.get(event.idempotency_key)
            if existing is None:
                self._events_by_idempotency[event.idempotency_key] = _StoredEvent(event=event)
                self._streams.setdefault(event.stream_id, []).append(event)
                return AppendResult(status="appended", event_id=event.event_id)

            current = existing.event
            if (
                current.stream_id == event.stream_id
                and current.command_id == event.command_id
                and current.payload_digest == event.payload_digest
            ):
                return AppendResult(status="duplicate", event_id=current.event_id)

            raise ReplayRejectedError(
                "unauthorized replay detected for idempotency_key="
                f"{event.idempotency_key} (existing_event_id={current.event_id})"
            )

    def read_stream(self, stream_id: str, *, limit: int = 100) -> list[dict[str, object]]:
        with self._lock:
            stream_events = list(self._streams.get(stream_id, []))[:limit]
        out: list[dict[str, object]] = []
        for event in stream_events:
            out.append(
                {
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
                    "payload_json": event.payload_json,
                }
            )
        return out
