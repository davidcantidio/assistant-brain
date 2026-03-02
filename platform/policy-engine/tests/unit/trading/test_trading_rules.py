from __future__ import annotations

import unittest
from pathlib import Path

from policy_engine.domain.contract_loader import load_contract
from policy_engine.domain.policy_rule import PolicyContext
from policy_engine.rules.trading import build_trading_rules


class TestTradingRules(unittest.TestCase):
    def setUp(self) -> None:
        self.root = Path(__file__).resolve().parents[5]

    def test_trading_rules_are_built_from_contract(self) -> None:
        manifest = load_contract(self.root, "trading")
        rules = build_trading_rules(manifest)
        self.assertGreater(len(rules), 0)
        self.assertTrue(all(rule.domain == "trading" for rule in rules))

    def test_trading_rule_evaluation_returns_expected_shape(self) -> None:
        manifest = load_contract(self.root, "trading")
        rules = build_trading_rules(manifest)
        context = PolicyContext(root=self.root)
        outcome = rules[-1].evaluate(context)
        self.assertIsInstance(outcome.passed, bool)


if __name__ == "__main__":
    unittest.main()
