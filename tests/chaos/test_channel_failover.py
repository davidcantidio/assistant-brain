from __future__ import annotations

import unittest

from event_ledger import InMemoryEventLedger  # type: ignore[import-not-found]
from ops_api.service import HITLService


class TestChannelFailoverChaos(unittest.TestCase):
    def test_primary_channel_outage_uses_fallback_channel(self) -> None:
        service = HITLService(ledger=InMemoryEventLedger())
        payload = {
            "decision_id": "DEC-CHAOS-001",
            "command_id": "CMD-CHAOS-001",
            "operator_id": "backup-breakglass-01",
            "channel": "telegram",
            "challenge_id": "CH-CHAOS-001",
            "signature_or_proof": "valid-proof",
            "evidence_ref": "INCIDENTS/DEGRADED-MODE-PROCEDURE.md",
            "side_effect_class": "operational",
            "explicit_human_approval": True,
            "primary_unavailable": True,
            "fallback_channel": "slack",
        }
        result = service.handle_action("approve", payload)
        self.assertEqual(result.status, "APPROVED")
        self.assertEqual(result.ledger_status, "appended")


if __name__ == "__main__":
    unittest.main()
