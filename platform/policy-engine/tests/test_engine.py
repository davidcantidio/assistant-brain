from __future__ import annotations

import shutil
import tempfile
import unittest
from pathlib import Path

from policy_engine.engine import run_domain


class TestPolicyEngine(unittest.TestCase):
    def setUp(self) -> None:
        self.root = Path(__file__).resolve().parents[3]

    def test_runtime_domain_passes(self) -> None:
        result = run_domain("runtime", self.root)
        self.assertEqual(result.status, "PASS")
        self.assertEqual(result.domain, "runtime")
        self.assertGreater(result.total_rules, 0)
        self.assertEqual(result.total_rules, result.passed_rules + result.failed_rules)

    def test_security_domain_passes(self) -> None:
        result = run_domain("security", self.root)
        self.assertEqual(result.status, "PASS")
        self.assertEqual(result.domain, "security")
        self.assertGreater(result.total_rules, 0)
        self.assertEqual(result.total_rules, result.passed_rules + result.failed_rules)

    def test_governance_domain_passes(self) -> None:
        result = run_domain("governance", self.root)
        self.assertEqual(result.status, "PASS")
        self.assertEqual(result.domain, "governance")
        self.assertGreater(result.total_rules, 0)
        self.assertEqual(result.total_rules, result.passed_rules + result.failed_rules)

    def test_trading_domain_passes(self) -> None:
        result = run_domain("trading", self.root)
        self.assertEqual(result.status, "PASS")
        self.assertEqual(result.domain, "trading")
        self.assertGreater(result.total_rules, 0)
        self.assertEqual(result.total_rules, result.passed_rules + result.failed_rules)

    def test_all_domain_passes(self) -> None:
        result = run_domain("all", self.root)
        self.assertEqual(result.status, "PASS")
        self.assertEqual(result.domain, "all")
        self.assertGreater(result.total_rules, 0)
        self.assertEqual(result.total_rules, result.passed_rules + result.failed_rules)

    def test_runtime_domain_fails_when_required_files_missing(self) -> None:
        with tempfile.TemporaryDirectory(prefix="policy-engine-runtime-") as tmp:
            isolated_root = Path(tmp)
            contract_dir = isolated_root / "platform/policy-engine/contracts"
            contract_dir.mkdir(parents=True, exist_ok=True)
            shutil.copy2(
                self.root / "platform/policy-engine/contracts/runtime.v1.yaml",
                contract_dir / "runtime.v1.yaml",
            )

            result = run_domain("runtime", isolated_root)
            self.assertEqual(result.status, "FAIL")
            self.assertGreater(result.failed_rules, 0)
            self.assertEqual(result.total_rules, result.passed_rules + result.failed_rules)


if __name__ == "__main__":
    unittest.main()
