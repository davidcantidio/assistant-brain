from __future__ import annotations

import json
import re
import unittest
from pathlib import Path

from domains.governance.contracts_v2_adapter import DualContractReader


class TestContractV2Compatibility(unittest.TestCase):
    def setUp(self) -> None:
        self.root = Path(__file__).resolve().parents[2]
        self.fixtures = self.root / "tests/fixtures/contracts/v2"

    def test_dual_reader_adapts_v1_to_v2_and_tracks_telemetry(self) -> None:
        reader = DualContractReader()
        decision_v1 = {
            "schema_version": "1.4",
            "decision_id": "DEC-20260302-LEGACY",
            "decision_key": "f8:weekly:hold",
            "status": "PENDING",
            "created_at": "2026-03-02T12:00:00Z",
            "approver_operator_id": "primary-01",
            "approval_evidence_ref": "artifacts/phase-f8/weekly-governance/2026-W09.md",
            "last_command_id": "CMD-LEGACY-01",
            "challenge_id": "CH-LEGACY-01",
            "challenge_status": "PENDING",
            "challenge_expires_at": "2026-03-02T12:05:00Z",
            "side_effect_class": "operational",
            "explicit_human_approval": True,
        }
        adapted = reader.read_decision(decision_v1)
        self.assertEqual(adapted["contract_version"], "v2")
        self.assertEqual(adapted["schema_version"], "2.0")
        self.assertEqual(reader.telemetry.v1_read_count, 1)
        self.assertEqual(reader.telemetry.v2_read_count, 0)
        self.assertRegex(str(adapted["payload_digest"]), r"^[a-f0-9]{64}$")

    def test_dual_reader_keeps_v2_payload_and_tracks_v2_reads(self) -> None:
        reader = DualContractReader()
        payload = json.loads((self.fixtures / "decision.valid.json").read_text(encoding="utf-8"))
        read_back = reader.read_decision(payload)
        self.assertEqual(read_back["contract_version"], "v2")
        self.assertEqual(reader.telemetry.v1_read_count, 0)
        self.assertEqual(reader.telemetry.v2_read_count, 1)

    def test_v2_fixtures_have_required_fields(self) -> None:
        required_map = {
            "decision.valid.json": {
                "schema_version",
                "contract_version",
                "decision_id",
                "idempotency_key",
                "author",
                "evidence_refs",
                "command_id",
                "challenge",
                "occurred_at",
                "payload_digest",
            },
            "work_order.valid.json": {
                "schema_version",
                "contract_version",
                "work_order_id",
                "idempotency_key",
                "author",
                "evidence_refs",
                "command_id",
                "challenge",
                "occurred_at",
                "payload_digest",
            },
            "task_event.valid.json": {
                "schema_version",
                "contract_version",
                "event_id",
                "idempotency_key",
                "author",
                "evidence_refs",
                "command_id",
                "challenge",
                "occurred_at",
                "payload_digest",
            },
        }
        for file_name, required in required_map.items():
            payload = json.loads((self.fixtures / file_name).read_text(encoding="utf-8"))
            self.assertTrue(required.issubset(payload.keys()), msg=f"missing keys in {file_name}")
            self.assertEqual(payload["schema_version"], "2.0")
            self.assertEqual(payload["contract_version"], "v2")
            self.assertTrue(re.fullmatch(r"[a-f0-9]{64}", str(payload["payload_digest"])))


if __name__ == "__main__":
    unittest.main()
