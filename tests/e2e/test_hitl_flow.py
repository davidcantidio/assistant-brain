from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor
import unittest

from event_ledger import InMemoryEventLedger  # type: ignore[import-not-found]
from ops_api.service import HITLService, ReplayRejectedError


class TestHITLFlow(unittest.TestCase):
    def setUp(self) -> None:
        self.ledger = InMemoryEventLedger()
        self.service = HITLService(ledger=self.ledger)

    def _base_payload(self) -> dict[str, object]:
        return {
            "decision_id": "DEC-TEST-001",
            "command_id": "CMD-TEST-001",
            "operator_id": "primary-01",
            "channel": "telegram",
            "challenge_id": "CH-TEST-001",
            "signature_or_proof": "valid-proof",
            "evidence_ref": "artifacts/phase-f8/weekly-governance/2026-W09.md",
            "side_effect_class": "operational",
            "explicit_human_approval": True,
        }

    def test_hitl_flow_primary_and_fallback_channels(self) -> None:
        approve_payload = self._base_payload()
        approved = self.service.handle_action("approve", approve_payload)
        self.assertEqual(approved.status, "APPROVED")
        self.assertEqual(approved.ledger_status, "appended")
        stream = self.ledger.read_stream("decision:DEC-TEST-001")
        telemetry = stream[0]["payload_json"]["contract_read_telemetry"]
        self.assertGreaterEqual(int(telemetry["v1_read_count"]), 1)

        reject_payload = self._base_payload()
        reject_payload["command_id"] = "CMD-TEST-002"
        reject_payload["channel"] = "telegram"
        reject_payload["primary_unavailable"] = True
        reject_payload["fallback_channel"] = "slack"
        rejected = self.service.handle_action("reject", reject_payload)
        self.assertEqual(rejected.status, "REJECTED")
        stream = self.ledger.read_stream("decision:DEC-TEST-001")
        self.assertEqual(stream[1]["channel"], "slack")

    def test_replay_rejection_for_same_command_id_with_different_payload(self) -> None:
        payload = self._base_payload()
        self.service.handle_action("approve", payload)
        with self.assertRaises(ReplayRejectedError):
            self.service.handle_action(
                "kill",
                {
                    **payload,
                    "signature_or_proof": "different-proof",
                },
            )

    def test_concurrent_duplicate_command_is_reconciled_idempotently(self) -> None:
        payload = self._base_payload()
        payload["command_id"] = "CMD-TEST-004"

        def execute() -> str:
            result = self.service.handle_action("approve", dict(payload))
            return result.ledger_status

        with ThreadPoolExecutor(max_workers=2) as executor:
            results = list(executor.map(lambda _: execute(), range(2)))

        self.assertCountEqual(results, ["appended", "duplicate"])
        stream = self.ledger.read_stream("decision:DEC-TEST-001")
        self.assertEqual(len(stream), 1)

    def test_financial_side_effect_requires_explicit_human_approval(self) -> None:
        payload = self._base_payload()
        payload["command_id"] = "CMD-TEST-003"
        payload["side_effect_class"] = "financial"
        payload["explicit_human_approval"] = False
        with self.assertRaisesRegex(ValueError, "financial side effect requires explicit_human_approval"):
            self.service.handle_action("approve", payload)


if __name__ == "__main__":
    unittest.main()
