from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


class TestGovernanceHardening(unittest.TestCase):
    def setUp(self) -> None:
        self.root = Path(__file__).resolve().parents[4]

    def test_decision_schema_requires_critical_hitl_financial_fields(self) -> None:
        schema_path = self.root / "ARC/schemas/decision.schema.json"
        payload = json.loads(schema_path.read_text(encoding="utf-8"))
        required = set(payload.get("required", []))

        required_fields = {
            "side_effect_class",
            "explicit_human_approval",
            "approval_evidence_ref",
            "approval_signature_valid",
            "challenge_id",
            "challenge_status",
            "challenge_expires_at",
            "last_command_id",
            "approver_operator_id",
            "approver_channel",
        }
        self.assertTrue(required_fields.issubset(required))

    def test_operator_allowlist_has_backup_enabled(self) -> None:
        operators_path = self.root / "SEC/allowlists/OPERATORS.yaml"
        text = operators_path.read_text(encoding="utf-8")

        backup_match = re.search(r'backup_operator_operator_id:\s*"([^"]+)"', text)
        self.assertIsNotNone(backup_match)
        backup_operator_id = backup_match.group(1)

        blocks = re.split(r"\n\s*-\s+operator_id:\s*", text)
        enabled_ids: list[str] = []
        for block in blocks[1:]:
            lines = block.splitlines()
            if not lines:
                continue
            operator_id = lines[0].strip().strip('"')
            enabled_match = re.search(r"\n\s+enabled:\s*(true|false)", "\n" + block)
            enabled = (enabled_match.group(1) == "true") if enabled_match else False
            if enabled:
                enabled_ids.append(operator_id)

        self.assertGreaterEqual(len(enabled_ids), 2)
        self.assertIn(backup_operator_id, enabled_ids)

    def test_weekly_governance_script_does_not_use_eval(self) -> None:
        script_path = self.root / "scripts/ci/run_phase_f8_weekly_governance.sh"
        text = script_path.read_text(encoding="utf-8")
        self.assertNotRegex(text, r"(?m)^\s*eval\s+")

    def test_critical_wrappers_remain_thin(self) -> None:
        wrappers = (
            "scripts/ci/check_phase_f8_weekly_governance.sh",
            "scripts/ci/eval_trading.sh",
        )
        for rel in wrappers:
            text = (self.root / rel).read_text(encoding="utf-8")
            line_count = text.count("\n")
            self.assertLessEqual(line_count, 60, msg=f"wrapper above limit: {rel} ({line_count})")


if __name__ == "__main__":
    unittest.main()
