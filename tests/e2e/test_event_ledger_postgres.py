from __future__ import annotations

import os
import sys
import unittest
import uuid
from pathlib import Path

EVENT_LEDGER_SRC = Path(__file__).resolve().parents[2] / "platform/event-ledger/src"
if str(EVENT_LEDGER_SRC) not in sys.path:
    sys.path.append(str(EVENT_LEDGER_SRC))

from event_ledger import LedgerEvent, PostgresEventLedger, ReplayRejectedError  # type: ignore[import-not-found]


@unittest.skipUnless(
    os.environ.get("OPENCLAW_EVENT_LEDGER_DSN"),
    "OPENCLAW_EVENT_LEDGER_DSN is required for Postgres integration test",
)
class TestEventLedgerPostgres(unittest.TestCase):
    def setUp(self) -> None:
        dsn = os.environ["OPENCLAW_EVENT_LEDGER_DSN"]
        self.ledger = PostgresEventLedger(dsn=dsn)
        migrations = Path(__file__).resolve().parents[2] / "platform/event-ledger/migrations"
        self.ledger.apply_migrations(migrations)

    def test_append_duplicate_and_replay_rejection(self) -> None:
        unique = uuid.uuid4().hex
        event = LedgerEvent(
            event_id=f"evt-{unique}",
            stream_id=f"decision:{unique}",
            idempotency_key=f"cmd-{unique}",
            replay_key=f"decision:{unique}:cmd-{unique}:approve:1",
            command_id=f"cmd-{unique}",
            author="primary-01",
            evidence_ref="tests/e2e/test_event_ledger_postgres.py",
            channel="telegram",
            action="approve",
            occurred_at="2026-03-02T12:00:00Z",
            payload_digest="3d7c6a5f3f2be7a3f0ae2cb98e9a8063aa9d1e5c0b38e9070f57e81d5bd5d4af",
            payload_json={"result": "approved"},
        )
        inserted = self.ledger.append_event(event)
        self.assertEqual(inserted.status, "appended")

        duplicate = self.ledger.append_event(event)
        self.assertEqual(duplicate.status, "duplicate")

        with self.assertRaises(ReplayRejectedError):
            self.ledger.append_event(
                LedgerEvent(
                    event_id=f"evt-{uuid.uuid4().hex}",
                    stream_id=f"decision:{unique}",
                    idempotency_key=f"cmd-{unique}",
                    replay_key=f"decision:{unique}:cmd-{unique}:approve:2",
                    command_id=f"cmd-{unique}",
                    author="primary-01",
                    evidence_ref="tests/e2e/test_event_ledger_postgres.py",
                    channel="telegram",
                    action="approve",
                    occurred_at="2026-03-02T12:00:01Z",
                    payload_digest="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                    payload_json={"result": "tampered"},
                )
            )

        stream = self.ledger.read_stream(f"decision:{unique}")
        self.assertGreaterEqual(len(stream), 1)


if __name__ == "__main__":
    unittest.main()
