#!/usr/bin/env python3
"""Offline runner-pack boundary tests. No real CLI, credentials or tenant calls."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / "packs/anthropic-claude"


class RunnerPacks(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.bin = self.home / "claude"
        self.calls = self.home / "calls.json"
        self.bin.write_text("""#!/bin/sh
set -eu
printf '%s\\n' "$@" > "$TEST_CALLS"
printf '%s\\n' "${SELF_HOSTED_RUNNER_ENVIRONMENT_SECRET+x}" "${SELF_HOSTED_RUNNER_POOL_SECRET+x}" "${SELF_HOSTED_RUNNER_DEBUG_TOKEN_DIR+x}" > "$TEST_ENV"
case "$1:$2" in
 self-hosted-runner:--help)
  printf '%s\\n' "${TEST_HELP---environment-secret-file --capacity --drain-grace-sec --confine-repo-settings --health-port}" ;;
 self-hosted-runner:decode-token)
  if [ "${TEST_NATIVE_FAIL:-}" = 1 ]; then
   printf '%s\\n' 'NOT-A-REAL-TOKEN private-claim' >&2
   exit 1
  fi
  printf '%s\\n' "$TEST_CLAIMS" ;;
esac
""")
        self.bin.chmod(0o700)
        self.env = {
            "PATH": os.environ["PATH"], "HOME": str(self.home),
            "TEST_CALLS": str(self.calls), "TEST_ENV": str(self.home / "env-flags"),
            "CLAUDE_RUNNER_CLAUDE_BIN": str(self.bin),
            "HTH_EXPECTED_ENVIRONMENT_ID": "ccpool_example",
            "HTH_EXPECTED_ACTOR_SUB": "user:example",
            "CLAUDE_CODE_SESSION_ACCESS_TOKEN": "sk-ant-cc-fixture-only",
        }
        self.claims = {
            "iss": "ccr", "aud": ["ccpool_example"],
            "ccr:role": "session_worker", "exp": int(time.time()) + 300,
            "act": {"sub": "user:example", "email": "private-claim@example.invalid"},
        }

    def run_pack(self, kind, filename, **updates):
        env = self.env | {"TEST_CLAIMS": json.dumps(self.claims)} | updates
        return subprocess.run(["bash", str(PACK / kind / filename)],
                              env=env, capture_output=True, text=True, timeout=30)

    def identity(self, **updates):
        return self.run_pack("cli", "hth-anthropic-claude-7.15-session-identity.sh",
                             **updates)

    def test_default_never_invokes_native(self):
        for name in ("hth-anthropic-claude-7.14-runner-capabilities.sh",
                     "hth-anthropic-claude-7.15-session-identity.sh"):
            result = self.run_pack("cli", name)
            self.assertEqual(result.returncode, 2, result.stderr)
            self.assertFalse(self.calls.exists())

    def test_capabilities_use_only_help_and_reject_incomplete_help(self):
        name = "hth-anthropic-claude-7.14-runner-capabilities.sh"
        result = self.run_pack("cli", name, HTH_RUN_NATIVE_CHECK="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls.read_text().splitlines(),
                         ["self-hosted-runner", "--help"])
        for help_text in ("General Claude help", "--capacity --health-port"):
            result = self.run_pack("cli", name, HTH_RUN_NATIVE_CHECK="1", TEST_HELP=help_text)
            self.assertEqual(result.returncode, 2)

    def test_identity_matches_without_disclosing_token_or_claims(self):
        for actor in ("user:example", "agent:example"):
            self.claims["act"]["sub"] = actor
            result = self.identity(HTH_RUN_NATIVE_CHECK="1", HTH_EXPECTED_ACTOR_SUB=actor)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(self.calls.read_text().splitlines(),
                             ["self-hosted-runner", "decode-token"])
            for secret in ("sk-ant-cc-fixture-only", "private-claim", "ccpool_example", actor):
                self.assertNotIn(secret, result.stdout + result.stderr)

    def test_native_rejection_cannot_become_an_identity_match(self):
        result = self.identity(HTH_RUN_NATIVE_CHECK="1", TEST_NATIVE_FAIL="1")
        self.assertEqual(result.returncode, 1)
        self.assertNotIn("NOT-A-REAL-TOKEN", result.stdout + result.stderr)
        self.assertNotIn("private-claim", result.stdout + result.stderr)

    def test_wrong_or_malformed_claims_fail_closed(self):
        cases = [
            ("iss", "other"), ("iss", None),
            ("aud", ["ccpool_other"]), ("aud", "ccpool_example"),
            ("aud", None), ("aud", {}),
            ("ccr:role", "runner"), ("ccr:role", "environment"),
            ("exp", 0), ("exp", str(int(time.time()) + 300)),
            ("act", {"sub": "user:other"}), ("act", {}), ("act", []),
        ]
        for key, value in cases:
            with self.subTest(key=key, value=value):
                claims = self.claims | {key: value}
                result = self.identity(HTH_RUN_NATIVE_CHECK="1", TEST_CLAIMS=json.dumps(claims))
                self.assertEqual(result.returncode, 1)
                self.assertNotIn("IDENTITY MATCHED", result.stdout)
        for raw in ("not json", "null", "[]", "{}"):
            result = self.identity(HTH_RUN_NATIVE_CHECK="1", TEST_CLAIMS=raw)
            self.assertEqual(result.returncode, 1)

    def test_missing_independent_boundary_never_invokes_native(self):
        for updates in ({"HTH_EXPECTED_ACTOR_SUB": ""},
                        {"HTH_EXPECTED_ENVIRONMENT_ID": ""},
                        {"HTH_EXPECTED_ACTOR_SUB": "user:example; touch sentinel"},
                        {"HTH_EXPECTED_ENVIRONMENT_ID": "ccpool_example\nother"}):
            result = self.identity(HTH_RUN_NATIVE_CHECK="1", **updates)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(self.calls.exists())

    def test_hosted_or_unrecognized_token_prefix_is_rejected_before_native(self):
        for token in ("sk-ant-si-fixture-only", "unrecognized-fixture"):
            result = self.identity(HTH_RUN_NATIVE_CHECK="1", CLAUDE_CODE_SESSION_ACCESS_TOKEN=token)
            self.assertEqual(result.returncode, 1)
            self.assertFalse(self.calls.exists())
            self.assertNotIn(token, result.stdout + result.stderr)

    def test_emitter_does_not_run_and_launcher_has_fixed_arguments(self):
        result = self.run_pack("config", "hth-anthropic-claude-7.14-self-hosted-runner.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.calls.exists())
        launcher = self.home / "launch.sh"
        launcher.write_text(result.stdout)
        work_order = self.home / "work order;$(touch sentinel)"
        work_order.write_text("SYNTHETIC-WORK-ORDER")
        env = self.env | {
            "HTH_RUNNER_WORK_ORDER_FILE": str(work_order),
            "SELF_HOSTED_RUNNER_ENVIRONMENT_SECRET": "SYNTHETIC-BROAD-SECRET",
            "SELF_HOSTED_RUNNER_POOL_SECRET": "SYNTHETIC-OLD-SECRET",
            "SELF_HOSTED_RUNNER_DEBUG_TOKEN_DIR": "/tmp/synthetic-debug",
        }
        run = subprocess.run(["bash", str(launcher)], env=env, cwd=self.home,
                             text=True, capture_output=True, timeout=30)
        self.assertEqual(run.returncode, 0, run.stderr)
        call = {"argv": self.calls.read_text().splitlines()}
        flags = (self.home / "env-flags").read_text().splitlines()
        for key, value in zip(("value_secret_present", "old_secret_present", "debug_tokens_present"), flags):
            call[key] = bool(value)
        self.assertEqual(call["argv"], ["self-hosted-runner", "--environment-secret-file",
                         str(work_order), "--base-dir", "/workspace", "--capacity", "1",
                         "--drain-grace-sec", "0", "--confine-repo-settings", "enforce",
                         "--health-port", "0"])
        self.assertFalse(call["value_secret_present"])
        self.assertFalse(call["old_secret_present"])
        self.assertFalse(call["debug_tokens_present"])
        self.assertFalse((self.home / "sentinel").exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
