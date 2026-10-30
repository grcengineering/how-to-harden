#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-desktop-5.1
#   guide: https://howtoharden.com/guides/devin-desktop/#51-verify-managed-device-policy
#   profile: L2
#   mode: read-only
#   requires: python3
# HTH Devin Desktop 5.1: Verify Managed Device Policy
# Profile Level: L2 | NIST 800-53: CM-6
# Verified against official documentation: 2026-10-29; no live product validation.

# HTH Guide Excerpt: begin verify-managed-policy
set -euo pipefail
# Source: https://docs.devin.ai/desktop/enterprise-policies
# Read-only Linux policy verification. No client launch, networking, or secret output.
# Usage: bash this-file.sh --expected reviewed-baseline.json [--policy /etc/vscode/policy.json]
# A fixture path checks only that fixture. Runtime/team-policy precedence still needs UI proof.
python3 - "$@" <<'PYCODE'
import argparse, json, os, stat, sys
from pathlib import Path
p = argparse.ArgumentParser(description="Compare Linux Devin Desktop device policy to an approved baseline")
p.add_argument("--expected", type=Path, required=True)
p.add_argument("--policy", type=Path, default=Path("/etc/vscode/policy.json"))
a = p.parse_args()
def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate JSON key")
        result[key] = value
    return result
def read(path):
    if path.is_symlink():
        raise ValueError("symlinks are not accepted")
    if not path.is_file() or path.stat().st_size > 1024 * 1024:
        raise ValueError("missing, nonregular, or oversized file")
    value = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique_object)
    if not isinstance(value, dict):
        raise ValueError("policy must be an object")
    return value
try:
    expected, actual = read(a.expected), read(a.policy)
    allowed = {"AllowedExtensions": str, "ExtensionGalleryServiceUrl": str,
               "UpdateMode": str, "TelemetryLevel": str, "EnableFeedback": bool}
    if not expected or any(k not in allowed or type(v) is not allowed[k] for k,v in expected.items()):
        raise ValueError("baseline requires supported keys and exact documented types")
    if "AllowedExtensions" in expected:
        ext = json.loads(expected["AllowedExtensions"], object_pairs_hook=unique_object)
        if not isinstance(ext, dict) or ext.get("*") is not False:
            raise ValueError("baseline extension allowlist must explicitly deny wildcard")
        if any(type(v) is not bool and v != "stable" for v in ext.values()):
            raise ValueError("invalid extension allowlist value")
    if "UpdateMode" in expected and expected["UpdateMode"] not in ("none", "manual", "start", "default"):
        raise ValueError("invalid UpdateMode")
    if "TelemetryLevel" in expected and expected["TelemetryLevel"] not in ("all", "error", "crash", "off"):
        raise ValueError("invalid TelemetryLevel")
except (OSError, UnicodeError, ValueError):
    print("UNKNOWN: unreadable/invalid policy or baseline; no values printed", file=sys.stderr)
    sys.exit(2)
failed = False
for key, desired in expected.items():
    got = actual.get(key)
    matches = type(got) is type(desired) and got == desired
    if key == "AllowedExtensions" and type(got) is str:
        try:
            observed = json.loads(got, object_pairs_hook=unique_object)
            matches = (isinstance(observed, dict) and observed.keys() == ext.keys()
                       and all(type(observed[k]) is type(ext[k]) and observed[k] == ext[k] for k in ext))
        except (ValueError, TypeError):
            matches = False
    print(("PASS: " if matches else "FAIL: ") + key)
    failed |= not matches
info = a.policy.stat()
secure_permissions = info.st_uid == 0 and not (info.st_mode & (stat.S_IWGRP | stat.S_IWOTH))
print(("PASS: " if secure_permissions else "FAIL: ") + "root-owned policy not group/world-writable")
failed |= not secure_permissions
print("Scope: disk configuration only; verify locked settings and server overrides in the running client")
sys.exit(1 if failed else 0)
PYCODE
# HTH Guide Excerpt: end verify-managed-policy
