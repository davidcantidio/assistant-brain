from __future__ import annotations

import unittest
from pathlib import Path

from policy_engine.domain.contract_loader import load_contract
from policy_engine.domain.policy_rule import PolicyContext
from policy_engine.rules.runtime import build_runtime_rules


class TestRuntimeRules(unittest.TestCase):
    def setUp(self) -> None:
        self.root = Path(__file__).resolve().parents[5]

    def test_runtime_rules_are_built_from_contract(self) -> None:
        manifest = load_contract(self.root, "runtime")
        rules = build_runtime_rules(manifest)
        self.assertGreater(len(rules), 0)
        self.assertTrue(all(rule.domain == "runtime" for rule in rules))

    def test_runtime_rule_evaluation_returns_expected_shape(self) -> None:
        manifest = load_contract(self.root, "runtime")
        rules = build_runtime_rules(manifest)
        context = PolicyContext(root=self.root)
        outcome = rules[0].evaluate(context)
        self.assertIsInstance(outcome.passed, bool)


if __name__ == "__main__":
    unittest.main()
