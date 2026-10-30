#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: deepwiki-2.2
#   guide: https://howtoharden.com/guides/deepwiki/#22-isolate-public-research-from-authenticated-agent-tools
#   profile: L2
#   mode: read-only
#   requires: python3, dedicated MCP JSON file path
# HTH DeepWiki 2.2: Audit an isolated public-research MCP profile
# Profile Level: L2 (Walk) | NIST 800-53: AC-6, CM-7
# Sources (available; checked 2026-10-29):
#   https://docs.devin.ai/work-with-devin/deepwiki-mcp
#   https://docs.devin.ai/work-with-devin/devin-mcp
# HTH policy: exactly one server, no headers/env/commands/unknown settings.
# Never prints values from the supplied file, including malformed JSON errors.
# This checks this file only, NOT client built-ins, plugins or inherited config.
# Exit: 0 narrow file policy passed; 1 finding; 2 input could not be assessed.

# HTH Guide Excerpt: begin audit-public-research-profile
set -euo pipefail
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/dedicated-mcp.json" >&2
  exit 2
fi
command -v python3 >/dev/null 2>&1 || { echo "PRECONDITION: python3 required" >&2; exit 2; }
python3 - "$1" <<'PY'
import json
import sys

def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate key")
        result[key] = value
    return result

try:
    with open(sys.argv[1], encoding="utf-8") as source:
        raw = source.read(1024 * 1024 + 1)
    if len(raw) > 1024 * 1024:
        raise ValueError("oversized input")
    config = json.loads(raw, object_pairs_hook=unique_object)
except (OSError, UnicodeError, ValueError, RecursionError):
    print("UNKNOWN: file is unreadable, oversized, or invalid JSON", file=sys.stderr)
    sys.exit(2)

ok = isinstance(config, dict) and set(config) == {"mcpServers"}
servers = config.get("mcpServers") if isinstance(config, dict) else None
ok = ok and isinstance(servers, dict) and set(servers) == {"deepwiki"}
entry = servers.get("deepwiki") if isinstance(servers, dict) else None
if isinstance(entry, dict):
    # Exactly one URL spelling; reject ambiguous precedence and extra settings.
    ok = ok and set(entry) in ({"url"}, {"serverUrl"})
    endpoint = entry.get("url", entry.get("serverUrl"))
    ok = ok and endpoint == "https://mcp.deepwiki.com/mcp"
else:
    ok = False

if not ok:
    print("FINDING: profile is not an isolated, credential-free official DeepWiki configuration")
    sys.exit(1)
print("PASS: supplied file has only the credential-free official DeepWiki entry")
print("NOT PROVEN: effective client tools, inherited config, plugins, prompt safety, or server behavior")
PY
# HTH Guide Excerpt: end audit-public-research-profile
