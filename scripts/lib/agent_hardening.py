#!/usr/bin/env python3
"""Offline candidate checks and explicit native diagnostics for four coding agents.

No configuration is installed. A matching candidate is not effective-policy proof.
Keep native flags and baseline values tied to docs/research/agent-source-coverage-2026-11.md.
"""

from __future__ import annotations

import argparse
import copy
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys

REVIEWED = {"opencode": "2.3.0", "hermes": "0.23.1", "pi": "1.5.2", "oh-my-pi": "18.20.2"}
LIMIT = 1024 * 1024


class InputError(Exception):
    """A deliberately value-free error, safe for reports about secret-bearing input."""


class Parser(argparse.ArgumentParser):
    def error(self, message):
        raise InputError("invalid arguments; use --help (never supply credentials as arguments)")


def version_gate(product, version):
    # Reject prereleases, fuzzy matches and future versions until explicitly reviewed.
    if version != REVIEWED[product]:
        raise InputError("unreviewed product version; reconcile upstream and the pack before use")


def exact_id(value):
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.:-]{0,127}", value):
        raise InputError("approved provider must be an exact ID without wildcards")
    return value


def baseline(product, provider=None):
    if provider is not None:
        exact_id(provider)
        if product != "opencode":
            raise InputError("provider exceptions are supported only for the OpenCode candidate")
    if product == "opencode":
        rules = [{"action": a, "resource": "*", "effect": "deny"} for a in (
            "provider.use", "integration.connect", "integration.use", "mcp.use",
            "skill.use", "plugin.use", "websearch.use")]
        if provider:
            # Bare provider integration permits its configured/environment credential;
            # personal connected accounts with #account suffixes stay denied.
            rules += [{"action": a, "resource": provider, "effect": "allow"} for a in (
                "provider.use", "integration.connect", "integration.use")]
        rules += [{"action": "tool.use", "resource": r, "effect": "deny"} for r in (
            "shell:*", "edit:*", "subagent:*", "external_directory:*", "webfetch:*",
            "read:*.env", "read:*.env.*", "read:*.ssh/*", "read:*.aws/*")]
        return {"$schema": "https://opencode.ai/config.json", "policies": rules,
                "permissions": [{"action": "*", "resource": "*", "effect": "ask"}]}
    if product == "hermes":
        return {"approvals": {"mode": "manual", "cron_mode": "deny", "single_query_mode": "deny",
                              "unattended_mode": "deny", "approvers": [], "mcp_reload_confirm": True,
                              "destructive_slash_confirm": True},
                "command_allowlist": [], "security": {"redact_secrets": True},
                "terminal": {"backend": "docker", "env_passthrough": [], "docker_forward_env": [],
                             "credential_files": []},
                "gateway": {"allow_all_users": False}, "checkpoints": {"enabled": True}}
    if product == "pi":
        return {"$schema": "https://pi.dev/schemas/settings.schema.json", "defaultProjectTrust": "never",
                "defaultTools": ["read", "grep", "find", "ls"], "packages": [], "extensions": [],
                "skills": [], "prompts": []}
    return {"tools": {"approvalMode": "always-ask-cached", "approval": {
        "bash": "deny", "eval": "deny", "task": "deny", "browser": "deny", "computer": "deny",
        "computer.control": "deny"}}, "skills": {"enabled": False}, "enabledProviders": [],
        "mcp": {"enableProjectConfig": False}, "secrets": {"enabled": True},
        "telemetry": {"otlpExportEnabled": False}}


def fragment(product, section, provider):
    data = baseline(product, provider)
    if section == "all":
        return data
    keys = {
        "opencode": {"4.1": ["policies", "permissions"], "4.2": ["policies"]},
        "hermes": {"4.1": ["approvals", "command_allowlist"], "4.2": ["security", "checkpoints"]},
        "pi": {"4.1": ["defaultTools"], "4.2": ["defaultProjectTrust", "packages", "extensions", "skills", "prompts"]},
        "oh-my-pi": {"4.1": ["tools"], "4.2": ["secrets", "telemetry"]},
    }
    if section not in keys[product]:
        raise InputError("unknown fragment section")
    return {k: copy.deepcopy(data[k]) for k in keys[product][section]}


def regular_bytes(path):
    # Do not follow a final symlink or read a FIFO/device. Paths are operator-selected.
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    with os.fdopen(fd, "rb") as stream:
        info = os.fstat(stream.fileno())
        if not stat.S_ISREG(info.st_mode) or info.st_size > LIMIT:
            raise InputError("input must be a regular configuration file under 1 MiB")
        data = stream.read(LIMIT + 1)
        if len(data) > LIMIT:
            raise InputError("configuration exceeds size limit")
        return data.decode("utf-8")


def unique_pairs(pairs):
    result = {}
    for key, value in pairs:
        if not isinstance(key, str) or key in result:
            raise InputError("duplicate or non-string configuration key")
        result[key] = value
    return result


def load_config(path, product):
    raw = regular_bytes(path)
    if product in {"opencode", "pi"} or raw.lstrip().startswith("{"):
        # Intentionally no approximate JSONC stripping: use strict JSON for audit.
        data = json.loads(raw, object_pairs_hook=unique_pairs,
                          parse_constant=lambda _: (_ for _ in ()).throw(InputError("invalid JSON constant")))
    else:
        import yaml

        class StrictLoader(yaml.SafeLoader):
            pass

        def mapping(loader, node):
            return unique_pairs([(loader.construct_object(k), loader.construct_object(v)) for k, v in node.value])

        StrictLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, mapping)
        # Configuration candidates do not require YAML aliases, anchors or tags.
        if any(isinstance(t, (yaml.tokens.AliasToken, yaml.tokens.AnchorToken, yaml.tokens.TagToken))
               for t in yaml.scan(raw)):
            raise InputError("YAML aliases, anchors and explicit tags are unsupported")
        data = yaml.load(raw, Loader=StrictLoader)
    if not isinstance(data, dict):
        raise InputError("configuration root must be an object")
    return data


def equal_typed(a, b):
    # Python's True == 1 must not make an incorrectly typed config pass.
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return a.keys() == b.keys() and all(equal_typed(a[k], b[k]) for k in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(equal_typed(x, y) for x, y in zip(a, b))
    return a == b


def audit(product, path, provider):
    data, expected = load_config(path, product), baseline(product, provider)
    # Emit only known rule identifiers, never input keys, values, paths or parser errors.
    findings = ["baseline-field-" + k.replace("$", "") for k in expected
                if k not in data or not equal_typed(data[k], expected[k])]
    if set(data) - set(expected):
        findings.append("unreviewed-extra-fields")
    return {"scope": "candidate-file-only", "matches_reviewed_baseline": not findings,
            "effective_policy_verified": False, "findings": findings}


def environment(product, scope):
    findings = []
    truthy = {"1", "true", "yes", "on"}
    if scope in {"all", "network"}:
        if os.environ.get("NODE_TLS_REJECT_UNAUTHORIZED") == "0" or os.environ.get("GIT_SSL_NO_VERIFY", "").lower() in truthy:
            findings.append("tls-verification-disabled")
        if product == "hermes":
            if os.environ.get("GATEWAY_ALLOW_ALL_USERS", "").lower() in truthy:
                findings.append("gateway-open-access")
            if os.environ.get("API_SERVER_ENABLED", "").lower() in truthy:
                if not os.environ.get("API_SERVER_KEY"):
                    findings.append("api-key-missing")
                if os.environ.get("API_SERVER_HOST", "127.0.0.1") != "127.0.0.1":
                    findings.append("api-non-loopback-bind")
                if "*" in os.environ.get("API_SERVER_CORS_ORIGINS", ""):
                    findings.append("api-wildcard-cors")
    if scope in {"all", "credentials"}:
        names = ("AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "GITHUB_TOKEN", "GH_TOKEN", "SSH_AUTH_SOCK",
                 "KUBECONFIG", "GOOGLE_APPLICATION_CREDENTIALS", "AZURE_CLIENT_SECRET")
        if any(os.environ.get(k) for k in names):
            findings.append("ambient-credential-or-agent-access")
        if product == "hermes" and os.environ.get("HERMES_YOLO_MODE", "").lower() in truthy:
            findings.append("hermes-yolo-environment")
    return {"scope": "current-process-environment-only", "effective_policy_verified": False,
            "findings": findings, "unexamined": ["service environment", "credential stores", "network enforcement"]}


def absolute_directory(value):
    p = Path(value)
    if not p.is_absolute() or not p.is_dir():
        raise InputError("workspace and state directory must be existing absolute directories")
    return str(p.resolve())


def inventory(product, workspace):
    workspace = Path(absolute_directory(workspace))
    paths = {
        "opencode": ["opencode.json", "opencode.jsonc", ".opencode", "AGENTS.md", ".agents"],
        "hermes": [".hermes", "AGENTS.md", "SOUL.md", ".env"],
        "pi": [".pi", ".agents", "AGENTS.md", "AGENTS.override.md", "CLAUDE.md"],
        "oh-my-pi": [".omp", ".claude", ".codex", ".gemini", ".mcp.json", "mcp.json", "AGENTS.md", "CLAUDE.md", "WATCHDOG.yml"],
    }
    present = []
    for relative in paths[product]:
        p = workspace / relative
        try:
            info = p.lstat()
        except FileNotFoundError:
            continue
        present.append({"surface": relative, "symlink": stat.S_ISLNK(info.st_mode)})
    return {"scope": "named-workspace-top-level-only", "review_required": present,
            "unexamined": ["ancestors", "user and managed config", "package code", "MCP servers", "file contents"]}


def launch_plan(args):
    workspace, state = absolute_directory(args.workspace), absolute_directory(args.state_dir)
    if not args.binary or not Path(args.binary).is_absolute():
        raise InputError("an absolute reviewed binary path is required")
    if args.product == "pi":
        argv = [args.binary, "--no-approve", "--no-extensions", "--no-skills", "--no-prompt-templates",
                "--no-context-files", "--no-themes", "--no-mcp", "--no-session", "--session-dir", state,
                "--tools", "read,grep,find,ls", "--print", "Review this workspace and report findings."]
    elif args.product == "oh-my-pi":
        if not args.config or not Path(args.config).is_absolute():
            raise InputError("an absolute reviewed overlay path is required")
        if not audit(args.product, args.config, None)["matches_reviewed_baseline"]:
            raise InputError("overlay does not match the reviewed candidate")
        argv = [args.binary, "--config", str(Path(args.config).resolve()), "--approval-mode", "always-ask-cached",
                "--no-extensions", "--no-skills", "--no-lsp", "--no-session", "--tools", "read"]
    elif args.product == "opencode":
        argv = [args.binary, "--standalone", workspace]
    else:
        argv = [args.binary, "chat"]
    return {"mode": "preview-only", "argv": argv, "cwd": workspace, "state_directory": state,
            "executes": False, "requires_whole_process_isolation": True,
            "required_before_launch": ["deploy reviewed config", "empty environment plus approved task credentials",
                                       "mount only task data", "enforce egress outside agent", "inspect all discovery roots"],
            "state_selectors": {"pi": "PI_CODING_AGENT_DIR", "oh-my-pi": "PI_CODING_AGENT_DIR",
                                "hermes": "HERMES_HOME", "opencode": "dedicated OS account"}[args.product]}


def diagnostics(args):
    if not args.binary or not Path(args.binary).is_absolute():
        raise InputError("an absolute reviewed binary path is required")
    commands = {
        "opencode": [["service", "status"]], "hermes": [["doctor"]],
        "pi": [["auth", "check", "--json", "--no-refresh"]],
        "oh-my-pi": [["config", "get", k, "--json"] for k in
                      ("tools.approvalMode", "secrets.enabled", "mcp.enableProjectConfig")],
    }[args.product]
    if args.product == "pi":
        if not args.provider:
            raise InputError("Pi auth diagnostics require an exact provider ID")
        commands[0] += ["--provider", exact_id(args.provider)]
    argv = [[args.binary, *cmd] for cmd in commands]
    if not args.execute:
        return {"mode": "preview-only", "argv": argv, "executes": False}
    # User explicitly opts in; only fixed first-party read commands are allowed.
    # Raw output is never copied to stdout/stderr, including on subprocess failure.
    completed = []
    for cmd in argv:
        result = subprocess.run(cmd, capture_output=True, timeout=30, check=False)
        completed.append({"command_index": len(completed), "exit_code": result.returncode})
    return {"mode": "native-diagnostic", "commands": completed, "effective_policy_verified": False,
            "raw_output_suppressed": True, "manual_effective_state_review_required": True}


def native_version(args):
    if not args.binary or not Path(args.binary).is_absolute():
        raise InputError("an absolute reviewed binary path is required")
    if not args.execute:
        return {"mode": "preview-only", "argv": [args.binary, "--version"], "executes": False,
                "reviewed_version": REVIEWED[args.product]}
    result = subprocess.run([args.binary, "--version"], capture_output=True, timeout=30, check=False)
    if result.returncode or len(result.stdout) > 4096:
        raise InputError("native version command failed")
    match = re.fullmatch(r"(?:(?:OpenCode|Hermes Agent|hermes|pi|omp)\s+)?v?([0-9]+\.[0-9]+\.[0-9]+)\s*",
                         result.stdout.decode("utf-8"), re.I)
    if not match or match[1] != REVIEWED[args.product]:
        raise InputError("unrecognized or unreviewed native version")
    return {"product": args.product, "reviewed_version": REVIEWED[args.product], "version_matches": True,
            "binary_executed": True}


def main(argv=None):
    parser = Parser(description=__doc__, allow_abbrev=False)
    parser.add_argument("mode", choices=["emit", "audit", "environment", "inventory", "launch", "diagnostics", "version"])
    parser.add_argument("--product", required=True, choices=REVIEWED)
    parser.add_argument("--version", required=True, help="exact reviewed stable version; no network lookup")
    parser.add_argument("--section", default="all")
    parser.add_argument("--approved-provider")
    parser.add_argument("--config")
    parser.add_argument("--scope", choices=["all", "network", "credentials"], default="all")
    parser.add_argument("--workspace")
    parser.add_argument("--state-dir")
    parser.add_argument("--binary")
    parser.add_argument("--provider")
    parser.add_argument("--execute", action="store_true", help="native diagnostics only; never applies configuration")
    args = parser.parse_args(argv)
    version_gate(args.product, args.version)
    if args.execute and args.mode not in {"diagnostics", "version"}:
        raise InputError("only fixed native reads support execution")
    if args.mode == "emit":
        result = fragment(args.product, args.section, args.approved_provider)
    elif args.mode == "audit":
        if not args.config:
            raise InputError("an explicit candidate configuration path is required")
        result = audit(args.product, args.config, args.approved_provider)
    elif args.mode == "environment":
        result = environment(args.product, args.scope)
    elif args.mode == "inventory":
        result = inventory(args.product, args.workspace)
    elif args.mode == "launch":
        result = launch_plan(args)
    elif args.mode == "diagnostics":
        result = diagnostics(args)
    else:
        result = native_version(args)
    print(json.dumps(result, indent=2, ensure_ascii=True))
    if args.mode == "audit" and not result["matches_reviewed_baseline"]:
        return 1
    if args.mode == "environment" and result["findings"]:
        return 1
    if args.mode == "diagnostics" and any(c["exit_code"] != 0 for c in result.get("commands", [])):
        return 1
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (InputError, OSError, ValueError, TypeError, ImportError, RecursionError, subprocess.SubprocessError):
        print("ERROR: input, dependency or native diagnostic invalid; no effective-policy conclusion", file=sys.stderr)
        sys.exit(2)
    except Exception:
        # YAML/parser exceptions can contain source lines with secrets; never echo them.
        print("ERROR: configuration could not be safely evaluated", file=sys.stderr)
        sys.exit(2)
