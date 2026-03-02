from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from policy_engine.application.convergence import OPENROUTER_RULE, validate_policy_convergence


class TestConvergence(unittest.TestCase):
    def setUp(self) -> None:
        self.root = Path(__file__).resolve().parents[3]

    def test_policy_convergence_passes(self) -> None:
        errors = validate_policy_convergence(self.root)
        self.assertEqual(errors, [])

    def test_policy_convergence_fails_with_forbidden_text(self) -> None:
        with tempfile.TemporaryDirectory(prefix="policy-convergence-") as tmp:
            root = Path(tmp)

            docs = (
                "README.md",
                "PRD/ROADMAP.md",
                "PRD/PRD-MASTER.md",
                "ARC/ARC-MODEL-ROUTING.md",
                "SEC/SEC-POLICY.md",
            )
            for rel in docs:
                path = root / rel
                path.parent.mkdir(parents=True, exist_ok=True)
                payload = OPENROUTER_RULE
                if rel == "README.md":
                    payload += "\nOpenRouter e adaptador cloud opcional, permanece desabilitado por default"
                path.write_text(payload + "\n", encoding="utf-8")

            providers = root / "SEC/allowlists/PROVIDERS.yaml"
            providers.parent.mkdir(parents=True, exist_ok=True)
            providers.write_text(
                "\n".join(
                    (
                        'cloud_adapter_default: "enabled"',
                        'cloud_adapter_enablement: "default_on"',
                        'cloud_adapter_primary: "openrouter"',
                    )
                )
                + "\n",
                encoding="utf-8",
            )

            errors = validate_policy_convergence(root)
            self.assertTrue(errors)
            self.assertTrue(any("forbidden openrouter text" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
