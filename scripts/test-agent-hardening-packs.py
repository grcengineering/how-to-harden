#!/usr/bin/env python3
"""Hostile offline fixtures and fake first-party CLIs; no agent, network or tenant.

The two retained official schemas independently check candidate shape. Negative
tests model failures/bypasses that matter at the public pack entrypoints.
"""

import ast
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

import jsonschema
from referencing import Registry, Resource

ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "tests/fixtures/agent-hardening"
VERSIONS = {"opencode": "2.3.0", "hermes": "0.23.1", "pi": "1.5.2", "oh-my-pi": "18.20.2"}
HELPER = ROOT / "scripts/lib/agent_hardening.py"
SECRET = "PRIVATE_TEST_MARKER_never_print_this"


def runpack(product, number, *args, env=None):
    files = list((ROOT / "packs" / product).glob(f"*/hth-{product}-{number}-*.sh"))
    assert len(files) == 1, files
    clean = {k: v for k, v in os.environ.items() if not k.startswith(("HTH_", "HERMES_", "API_SERVER_", "GATEWAY_"))}
    for key in ("NODE_TLS_REJECT_UNAUTHORIZED", "GIT_SSL_NO_VERIFY", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY",
                "GITHUB_TOKEN", "GH_TOKEN", "SSH_AUTH_SOCK", "KUBECONFIG", "GOOGLE_APPLICATION_CREDENTIALS", "AZURE_CLIENT_SECRET"):
        clean.pop(key, None)
    clean.update(env or {})
    return subprocess.run(["bash", str(files[0]), *args], text=True, capture_output=True, env=clean, timeout=10)


def candidate(product, *args):
    r = runpack(product, "1.02", "--version", VERSIONS[product], *args)
    if r.returncode:
        raise AssertionError(r.stderr)
    return json.loads(r.stdout)


class PackTests(unittest.TestCase):
    def test_touched_vendor_match_requires_path_boundary(self):
        script = (ROOT / 'scripts/validate-packs.sh').read_text()
        start = script.index('def matches_key(line, key):')
        end = script.index('\nmine, in_fail', start)
        namespace = {'re': __import__('re')}
        exec(compile(ast.parse(script[start:end]), '<touched-filter>', 'exec'), namespace)
        match = namespace['matches_key']
        self.assertFalse(match('tableau/api/hth-tableau-1.sh: failure', 'pi/'))
        self.assertTrue(match('pi/config/hth-pi-1.sh: failure', 'pi/'))
        self.assertTrue(match('    pi/config/hth-pi-1.sh: failure', 'pi/'))

    def audit(self, product, text, *args):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "candidate.yaml"
            p.write_text(text)
            r = runpack(product, "5.01", "--version", VERSIONS[product], "--config", str(p), *args)
            self.assertEqual(p.read_text(), text, "audit must never rewrite a candidate")
            return r

    def test_baselines_round_trip_without_installing_anything(self):
        for product in VERSIONS:
            with self.subTest(product=product):
                r = self.audit(product, json.dumps(candidate(product)))
                self.assertEqual(r.returncode, 0, r.stderr)
                report = json.loads(r.stdout)
                self.assertTrue(report["matches_reviewed_baseline"])
                self.assertFalse(report["effective_policy_verified"])

    def test_two_independent_native_schema_snapshots(self):
        for product in ("opencode", "pi"):
            schema = json.loads((FIXTURES / f"{product}.schema.json").read_text())
            # Native schemas must not cause test-time remote reference resolution.
            def refs(value):
                if isinstance(value, dict):
                    for k, v in value.items():
                        if k == "$ref":
                            self.assertTrue(v.startswith("#") or v.startswith("https://models.dev/model-schema.json#"),
                                            "uncached schema ref would require a network lookup")
                        refs(v)
                elif isinstance(value, list):
                    for v in value:
                        refs(v)
            refs(schema)
            models = json.loads((FIXTURES / "models.schema.json").read_text())
            registry = Registry().with_resource("https://models.dev/model-schema.json", Resource.from_contents(models))
            jsonschema.validators.validator_for(schema)(schema, registry=registry).validate(candidate(product))

    def test_wrong_versions_no_candidate_output(self):
        for product, current in VERSIONS.items():
            for version in ("", "0.1.0", "99.0.0", current + "-rc.1", "v" + current, current + "\n"):
                with self.subTest(product=product, version=version):
                    r = runpack(product, "1.02", "--version", version)
                    self.assertEqual(r.returncode, 2)
                    self.assertEqual(r.stdout, "")
        for version in ("1.19.5", "2.2.2", "2.2.5"):
            self.assertNotEqual(runpack("opencode", "1.02", "--version", version).returncode, 0)

    def test_opencode_provider_exception_is_exact_and_audited(self):
        good = candidate("opencode", "--approved-provider", "anthropic")
        self.assertEqual(self.audit("opencode", json.dumps(good), "--approved-provider", "anthropic").returncode, 0)
        self.assertEqual(self.audit("opencode", json.dumps(good)).returncode, 1)
        for value in ("*", "anthropic*", "anthropic?", "opencode#org_example", SECRET + "/*"):
            r = runpack("opencode", "1.02", "--version", "2.3.0", "--approved-provider", value)
            self.assertEqual(r.returncode, 2)
            self.assertNotIn(SECRET, r.stderr + r.stdout)

    def test_opencode_later_wildcard_allow_and_reordered_rules_fail(self):
        for change in ("wildcard", "reorder", "v1"):
            data = candidate("opencode", "--approved-provider", "anthropic")
            if change == "wildcard":
                data["policies"].append({"action": "plugin.use", "resource": "*", "effect": "allow"})
            elif change == "reorder":
                data["policies"] = list(reversed(data["policies"]))
            else:
                data["permission"] = {"bash": "allow"}
                del data["permissions"]
            self.assertEqual(self.audit("opencode", json.dumps(data), "--approved-provider", "anthropic").returncode, 1)

    def test_unsafe_vendor_default_fixtures_are_rejected(self):
        for product in VERSIONS:
            raw = (FIXTURES / f"{product}.unsafe.json").read_text()
            r = self.audit(product, raw)
            self.assertEqual(r.returncode, 1)
            self.assertNotIn(SECRET, r.stdout + r.stderr)

    def test_hermes_allowlist_approvers_and_yolo_changes_fail(self):
        for target in ("allowlist", "approvers", "yolo", "redaction", "forwarding"):
            data = candidate("hermes")
            if target == "allowlist": data["command_allowlist"] = ["rm"]
            if target == "approvers": data["approvals"]["approvers"] = ["*"]
            if target == "yolo": data["approvals"]["mode"] = "off"
            if target == "redaction": data["security"]["redact_secrets"] = False
            if target == "forwarding": data["terminal"]["credential_files"] = [SECRET]
            self.assertEqual(self.audit("hermes", json.dumps(data)).returncode, 1)

    def test_pi_tool_trust_and_executable_resource_expansion_fail(self):
        for key, value in (("defaultTools", ["read", "bash"]), ("defaultProjectTrust", "always"),
                           ("packages", [SECRET]), ("extensions", ["./host-code.ts"]),
                           ("defaultTools", ["+codemode"])):
            data = candidate("pi"); data[key] = value
            self.assertEqual(self.audit("pi", json.dumps(data)).returncode, 1)

    def test_omp_alternate_execution_and_mcp_expansion_fail(self):
        for target in ("eval", "task", "computer.control", "mode", "mcp", "redaction", "telemetry"):
            data = candidate("oh-my-pi")
            if target in ("eval", "task", "computer.control"): data["tools"]["approval"][target] = "allow"
            if target == "mode": data["tools"]["approvalMode"] = "yolo"
            if target == "mcp": data["mcp"]["enableProjectConfig"] = True
            if target == "redaction": data["secrets"]["enabled"] = False
            if target == "telemetry": data["telemetry"]["otlpExportEnabled"] = True
            self.assertEqual(self.audit("oh-my-pi", json.dumps(data)).returncode, 1)

    def test_bool_and_number_are_not_interchangeable(self):
        for product, key in (("hermes", "security"), ("oh-my-pi", "secrets")):
            data = candidate(product)
            field = "redact_secrets" if product == "hermes" else "enabled"
            data[key][field] = 1
            self.assertEqual(self.audit(product, json.dumps(data)).returncode, 1)

    def test_parse_failures_never_echo_secret_lines(self):
        for raw in ('{"secret":"' + SECRET + '","secret":2}', '{"value":"' + SECRET,
                    '!!python/object/apply:os.system ["' + SECRET + '"]',
                    'a: &anchor [1]\nb: *anchor\n', 'a: 1\na: "' + SECRET + '"\n',
                    '1: "' + SECRET + '"\n', 'true\n', '[' + SECRET):
            for product in VERSIONS:
                r = self.audit(product, raw)
                self.assertEqual(r.returncode, 2, (product, r.stdout, r.stderr))
                self.assertNotIn(SECRET, r.stdout + r.stderr)

    def test_extra_secret_key_is_a_finding_without_disclosure(self):
        data = candidate("pi"); data[SECRET] = SECRET
        r = self.audit("pi", json.dumps(data))
        self.assertEqual(r.returncode, 1)
        self.assertNotIn(SECRET, r.stdout + r.stderr)

    def test_native_yaml_without_tags_or_aliases_is_accepted(self):
        import yaml
        for product in ("hermes", "oh-my-pi"):
            r = self.audit(product, yaml.safe_dump(candidate(product)))
            self.assertEqual(r.returncode, 0, r.stderr)

    def test_symlink_fifo_and_oversized_files_are_not_read(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d); target = p / "real.json"; target.write_text(json.dumps(candidate("pi")))
            link = p / "link.json"; link.symlink_to(target)
            fifo = p / "pipe"; os.mkfifo(fifo)
            huge = p / "huge"; huge.write_bytes(b" " * (1024 * 1024 + 1))
            for f in (link, fifo, huge):
                r = runpack("pi", "5.01", "--version", "1.5.2", "--config", str(f))
                self.assertEqual(r.returncode, 2)

    def test_clean_environment_still_declares_omissions(self):
        for product in VERSIONS:
            r = runpack(product, "3.01", "--version", VERSIONS[product])
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertFalse(json.loads(r.stdout)["effective_policy_verified"])
            self.assertIn("credential stores", r.stdout)

    def test_environment_findings_never_print_values(self):
        cases = [("pi", "3.01", {"AWS_SECRET_ACCESS_KEY": SECRET}),
                 ("hermes", "3.01", {"HERMES_YOLO_MODE": "true"}),
                 ("hermes", "2.02", {"GATEWAY_ALLOW_ALL_USERS": "true"}),
                 ("hermes", "2.02", {"API_SERVER_ENABLED": "true"}),
                 ("hermes", "2.02", {"API_SERVER_ENABLED": "true", "API_SERVER_KEY": SECRET, "API_SERVER_CORS_ORIGINS": "*"}),
                 ("opencode", "2.02", {"NODE_TLS_REJECT_UNAUTHORIZED": "0"})]
        for product, number, env in cases:
            r = runpack(product, number, "--version", VERSIONS[product], env=env)
            self.assertEqual(r.returncode, 1, r.stderr)
            self.assertNotIn(SECRET, r.stdout + r.stderr)

    def test_inventory_does_not_follow_or_read_resources(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d); outside = p / SECRET; outside.mkdir(); (outside / SECRET).write_text(SECRET)
            workspace = p / "workspace"; workspace.mkdir(); (workspace / ".pi").symlink_to(outside)
            r = runpack("pi", "3.02", "--version", "1.5.2", "--workspace", str(workspace))
            self.assertEqual(r.returncode, 0)
            self.assertEqual(json.loads(r.stdout)["review_required"], [{"surface": ".pi", "symlink": True}])
            self.assertNotIn(SECRET, r.stdout)
            self.assertIn("ancestors", r.stdout)

    def test_launch_plan_never_executes_even_an_executable_supplied_as_binary(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d); fake = p / "must-not-run"; marker = p / "executed"
            fake.write_text(f"#!/bin/sh\ntouch '{marker}'\n"); fake.chmod(0o700)
            overlay = p / "overlay.yml"; overlay.write_text(json.dumps(candidate("oh-my-pi")))
            for product in VERSIONS:
                args = ["--version", VERSIONS[product], "--workspace", d, "--state-dir", d, "--binary", str(fake)]
                if product == "oh-my-pi": args += ["--config", str(overlay)]
                r = runpack(product, "2.01", *args)
                self.assertEqual(r.returncode, 0, r.stderr)
                plan = json.loads(r.stdout)
                self.assertFalse(plan["executes"]); self.assertTrue(plan["requires_whole_process_isolation"])
                self.assertFalse(marker.exists())
                self.assertEqual(runpack(product, "2.01", *args, "--execute").returncode, 2)

    def test_pi_plan_closes_independent_resource_and_session_paths(self):
        with tempfile.TemporaryDirectory() as d:
            r = runpack("pi", "2.01", "--version", "1.5.2", "--workspace", d, "--state-dir", d, "--binary", "/reviewed/pi")
            argv = json.loads(r.stdout)["argv"]
            for flag in ("--no-approve", "--no-extensions", "--no-skills", "--no-prompt-templates", "--no-context-files", "--no-mcp", "--no-session"):
                self.assertIn(flag, argv)
            self.assertEqual(argv[argv.index("--session-dir") + 1], str(Path(d).resolve()))
            self.assertEqual(argv[argv.index("--tools") + 1], "read,grep,find,ls")
            for extra in ("--approve", "--skill", "-e", "--yolo"):
                self.assertEqual(runpack("pi", "2.01", "--version", "1.5.2", "--workspace", d,
                                         "--state-dir", d, "--binary", "/reviewed/pi", extra, SECRET).returncode, 2)

    def test_launch_product_binding_cannot_be_changed_by_extra_product_flag(self):
        with tempfile.TemporaryDirectory() as d:
            r = runpack("pi", "2.01", "--product", "opencode", "--version", "1.5.2", "--workspace", d,
                        "--state-dir", d, "--binary", "/reviewed/pi")
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertIn("--no-mcp", json.loads(r.stdout)["argv"])

    def test_omp_plan_requires_good_absolute_overlay(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "config.yml"; p.write_text('{"tools":{"approvalMode":"yolo"}}')
            args = ["--version", "18.20.2", "--workspace", d, "--state-dir", d, "--binary", "/reviewed/omp"]
            self.assertEqual(runpack("oh-my-pi", "2.01", *args, "--config", str(p)).returncode, 2)
            self.assertEqual(runpack("oh-my-pi", "2.01", *args, "--config", "relative.yml").returncode, 2)

    def test_native_diagnostics_preview_has_no_side_effects(self):
        for product in VERSIONS:
            args = ["--version", VERSIONS[product], "--binary", "/does/not/exist"]
            if product == "pi": args += ["--provider", "anthropic"]
            r = runpack(product, "5.02", *args)
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertFalse(json.loads(r.stdout)["executes"])

    def test_mock_native_diagnostics_are_fixed_and_private(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d); fake = p / "native"; calls = p / "args.jsonl"
            fake.write_text(f"#!{sys.executable}\nimport json,sys\nwith open({str(calls)!r},'a') as f:f.write(json.dumps(sys.argv[1:])+'\\n')\nprint({SECRET!r})\n")
            fake.chmod(0o700)
            for product in VERSIONS:
                args = ["--version", VERSIONS[product], "--binary", str(fake), "--execute"]
                if product == "pi": args += ["--provider", "anthropic"]
                r = runpack(product, "5.02", *args)
                self.assertEqual(r.returncode, 0, r.stderr)
                self.assertNotIn(SECRET, r.stdout + r.stderr)
                self.assertFalse(json.loads(r.stdout)["effective_policy_verified"])
            actual = [json.loads(x) for x in calls.read_text().splitlines()]
            self.assertEqual(actual, [["service", "status"], ["doctor"],
                                     ["auth", "check", "--json", "--no-refresh", "--provider", "anthropic"],
                                     ["config", "get", "tools.approvalMode", "--json"],
                                     ["config", "get", "secrets.enabled", "--json"],
                                     ["config", "get", "mcp.enableProjectConfig", "--json"]])

    def test_mock_native_error_output_is_suppressed_and_nonzero(self):
        with tempfile.TemporaryDirectory() as d:
            fake = Path(d) / "native"; fake.write_text(f"#!/bin/sh\nprintf '%s' '{SECRET}' >&2\nexit 9\n"); fake.chmod(0o700)
            r = runpack("hermes", "5.02", "--version", "0.23.1", "--binary", str(fake), "--execute")
            self.assertEqual(r.returncode, 1)
            self.assertNotIn(SECRET, r.stderr + r.stdout)

    def test_mock_native_version_preview_and_exact_match(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d); fake = p / "native"; marker = p / "called"
            for product, version in VERSIONS.items():
                fake.write_text(f"#!/bin/sh\ntouch '{marker}'\nprintf '%s\\n' '{version}'\n"); fake.chmod(0o700)
                r = runpack(product, "1.01", env={"HTH_BINARY": str(fake)})
                self.assertEqual(r.returncode, 0); self.assertFalse(marker.exists())
                r = runpack(product, "1.01", env={"HTH_BINARY": str(fake), "HTH_EXECUTE": "1"})
                self.assertEqual(r.returncode, 0, r.stderr); marker.unlink()
                fake.write_text(f"#!/bin/sh\nprintf '%s\\n' '{SECRET}'\n"); fake.chmod(0o700)
                r = runpack(product, "1.01", env={"HTH_BINARY": str(fake), "HTH_EXECUTE": "1"})
                self.assertEqual(r.returncode, 2)
                self.assertNotIn(SECRET, r.stdout + r.stderr)


if __name__ == "__main__":
    unittest.main(verbosity=2)
