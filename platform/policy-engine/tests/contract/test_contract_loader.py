from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from policy_engine.domain.contract_loader import load_contract, load_contract_from_path


class TestContractLoader(unittest.TestCase):
    def setUp(self) -> None:
        self.root = Path(__file__).resolve().parents[4]

    def test_load_runtime_contract(self) -> None:
        manifest = load_contract(self.root, "runtime")
        self.assertEqual(manifest.schema_version, "1.0")
        self.assertEqual(manifest.domain, "runtime")
        self.assertGreater(len(manifest.rules), 0)

    def test_load_governance_and_trading_contracts(self) -> None:
        governance_manifest = load_contract(self.root, "governance")
        trading_manifest = load_contract(self.root, "trading")
        self.assertEqual(governance_manifest.domain, "governance")
        self.assertEqual(trading_manifest.domain, "trading")
        self.assertGreater(len(governance_manifest.rules), 0)
        self.assertGreater(len(trading_manifest.rules), 0)

    def test_duplicate_rule_id_raises(self) -> None:
        payload = {
            "schema_version": "1.0",
            "domain": "runtime",
            "rules": [
                {
                    "rule_id": "RUNTIME-1",
                    "domain": "runtime",
                    "severity": "high",
                    "category": "runtime_contract",
                    "implementation": "required_files",
                    "enabled": True,
                    "evidence_refs": ["README.md"],
                    "remediation_hint": "hint",
                },
                {
                    "rule_id": "RUNTIME-1",
                    "domain": "runtime",
                    "severity": "high",
                    "category": "runtime_contract",
                    "implementation": "required_files",
                    "enabled": True,
                    "evidence_refs": ["README.md"],
                    "remediation_hint": "hint",
                },
            ],
        }

        with tempfile.TemporaryDirectory(prefix="contract-loader-") as tmp:
            path = Path(tmp) / "runtime.v1.yaml"
            path.write_text(
                json.dumps(payload, ensure_ascii=True, indent=2) + "\n", encoding="utf-8"
            )
            with self.assertRaisesRegex(ValueError, "duplicated rule_id"):
                load_contract_from_path(path)

    def test_invalid_domain_raises(self) -> None:
        payload = {
            "schema_version": "1.0",
            "domain": "runtime",
            "rules": [
                {
                    "rule_id": "RUNTIME-1",
                    "domain": "security",
                    "severity": "high",
                    "category": "runtime_contract",
                    "implementation": "required_files",
                    "enabled": True,
                    "evidence_refs": ["README.md"],
                    "remediation_hint": "hint",
                }
            ],
        }

        with tempfile.TemporaryDirectory(prefix="contract-loader-") as tmp:
            path = Path(tmp) / "runtime.v1.yaml"
            path.write_text(
                json.dumps(payload, ensure_ascii=True, indent=2) + "\n", encoding="utf-8"
            )
            with self.assertRaisesRegex(ValueError, "does not match manifest domain"):
                load_contract_from_path(path)


if __name__ == "__main__":
    unittest.main()
