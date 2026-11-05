#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-build-3.1
#   guide: https://howtoharden.com/guides/grok-build/#31-review-mcp-origins-and-restrict-server-authority
#   profile: L1
#   mode: read-only
#   requires: bash; bun; HTH_MCP_SERVER_NAME; HTH_CANDIDATE_POLICY for verify
#   changes: prints a candidate disabled-server pin or reads supplied TOML; never connects to a server
#   source: https://docs.x.ai/build/features/mcp-servers
# HTH Guide Excerpt: begin disable-mcp-source
set -euo pipefail
command -v bun >/dev/null || { echo 'PRECONDITION: Bun is required.' >&2; exit 2; }
export HTH_GROK_ACTION="${1:-render}"
bun - <<'JS'
const action = process.env.HTH_GROK_ACTION;
const name = process.env.HTH_MCP_SERVER_NAME ?? "";
if (!/^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$/.test(name)) { console.error("PRECONDITION: supply a reviewed HTH_MCP_SERVER_NAME (letters, digits, _ or -)."); process.exit(2); }
if (action === "render") {
  console.log(`# Merge into root-owned /etc/grok/requirements.toml.
# Disables this known server; this is not a universal MCP allowlist.
[mcp_servers.${name}]
enabled = false

[compat.cursor]
mcps = false

[compat.claude]
mcps = false`);
} else if (action === "verify") {
  const path = process.env.HTH_CANDIDATE_POLICY;
  if (!path) { console.error("PRECONDITION: supply HTH_CANDIDATE_POLICY."); process.exit(2); }
  let p;
  try { p = Bun.TOML.parse(await Bun.file(path).text()); }
  catch { console.error("PRECONDITION: supplied policy is unreadable or invalid TOML."); process.exit(2); }
  const ok = p.mcp_servers?.[name]?.enabled === false && p.compat?.cursor?.mcps === false && p.compat?.claude?.mcps === false;
  console.log(JSON.stringify({candidate_fields_match: ok, not_proven: ["all MCP sources inventoried", "other servers disabled", "server package and endpoint integrity", "OAuth revocation", "effective pins"]}));
  process.exit(ok ? 0 : 1);
} else { console.error("Usage: disable-mcp-source.sh [render|verify]"); process.exit(2); }
JS
# HTH Guide Excerpt: end disable-mcp-source
