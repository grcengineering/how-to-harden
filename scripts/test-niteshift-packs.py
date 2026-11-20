"""Offline contract tests; never contacts Niteshift or starts a task."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

import yaml

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / "packs/niteshift"
GEN = PACK / "config/hth-niteshift-3.02-paused-automation.sh"
CLI = PACK / "cli/hth-niteshift-2.02-service-status.sh"


class NiteshiftPacks(unittest.TestCase):
    def test_internal_manifest(self):
        config = yaml.safe_load((PACK / "config/hth-niteshift-2.02-internal-services.yml").read_text())
        self.assertNotIn("tunnels", config)
        service, = config["services"]
        self.assertNotIn("port", service)
        self.assertNotIn("auth", service)
        self.assertFalse(service["autostart"])
        self.assertEqual(service["restart"], "no")

    def test_candidate_is_paused_and_numeric_handle_is_string(self):
        for handle in ("123", "maintenance-bot", "a" * 63):
            with self.subTest(handle=handle):
                result = subprocess.run(["bash", GEN, handle], check=True, text=True, capture_output=True)
                _, frontmatter, prompt = result.stdout.split("---", 2)
                cfg = yaml.safe_load(frontmatter)
                self.assertEqual(cfg["schemaVersion"], 1)
                self.assertEqual(cfg["runAs"]["serviceAccount"], handle)
                self.assertEqual(cfg["status"], "paused")
                trigger, = cfg["triggers"]
                self.assertEqual(trigger["status"], "paused")
                self.assertEqual(trigger["source"], "schedule")
                self.assertIn("Do not edit files", prompt)

    def test_invalid_handles_print_no_candidate(self):
        for args in ([], ["a", "b"], ["a" * 64], ["x\nstatus: active"], ["a--b"], ["A"]):
            with self.subTest(args=args):
                result = subprocess.run(["bash", GEN, *args], text=True, capture_output=True)
                self.assertEqual(result.returncode, 2)
                self.assertEqual(result.stdout, "")

    def test_cli_status_only_and_exit_propagation(self):
        with tempfile.TemporaryDirectory() as workspace:
            fake = Path(workspace) / "ns"
            fake.write_text("#!/bin/sh\nprintf '%s\\n' \"$@\"\nexit 9\n")
            fake.chmod(0o700)
            result = subprocess.run(["/bin/bash", CLI], env={**os.environ, "PATH": workspace},
                                    capture_output=True, text=True)
            self.assertEqual(result.stdout.splitlines(), ["services", "status"])
            self.assertEqual(result.returncode, 9)
            fake.unlink()
            result = subprocess.run(["/bin/bash", CLI], env={"PATH": workspace},
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)


if __name__ == "__main__":
    unittest.main()
