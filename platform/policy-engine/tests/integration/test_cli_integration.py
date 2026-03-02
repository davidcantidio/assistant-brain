from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path


class TestPolicyCliIntegration(unittest.TestCase):
    def setUp(self) -> None:
        self.root = Path(__file__).resolve().parents[4]
        self.entrypoint = self.root / "policy-engine"

    def test_validate_consistency_outputs_json(self) -> None:
        with tempfile.TemporaryDirectory(prefix="policy-cli-") as tmp:
            out = Path(tmp) / "consistency.json"
            proc = subprocess.run(
                [
                    str(self.entrypoint),
                    "validate",
                    "--consistency",
                    "--root",
                    str(self.root),
                    "--output",
                    str(out),
                ],
                cwd=self.root,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(proc.returncode, 0)
            payload = json.loads(out.read_text(encoding="utf-8"))
            self.assertEqual(payload["status"], "PASS")
            self.assertEqual(payload["check"], "policy_convergence")


if __name__ == "__main__":
    unittest.main()
