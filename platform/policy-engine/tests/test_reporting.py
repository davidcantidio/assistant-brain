from __future__ import annotations

import json
import unittest

from policy_engine.domain.models import PolicyMetrics, PolicyRunResult, RuleResult
from policy_engine.reporting.json_report import to_json


class TestJsonReport(unittest.TestCase):
    def test_json_report_has_expected_fields(self) -> None:
        result = PolicyRunResult(
            schema_version="2.0",
            run_id="policy-run-1",
            status="PASS",
            domain="security",
            total_rules=3,
            passed_rules=3,
            failed_rules=0,
            violations=(),
            rule_results=(
                RuleResult(
                    rule_id="SEC-1",
                    status="PASS",
                    severity="high",
                    runtime_ms=2,
                    category="security",
                    evidence_ref="SEC/SEC-POLICY.md",
                ),
            ),
            metrics=PolicyMetrics(
                pass_rate=100.0,
                contradiction_count=0,
                rule_runtime_ms_total=2,
            ),
        )
        payload = json.loads(to_json(result))
        self.assertEqual(payload["status"], "PASS")
        self.assertEqual(payload["failed_rules"], 0)
        self.assertIn("rule_results", payload)
        self.assertIn("metrics", payload)


if __name__ == "__main__":
    unittest.main()
