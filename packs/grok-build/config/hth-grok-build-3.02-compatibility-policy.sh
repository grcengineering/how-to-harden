#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-build-3.2
#   guide: https://howtoharden.com/guides/grok-build/#32-review-rules-skills-plugins-and-hooks-before-granting-trust
#   profile: L1
#   mode: read-only
#   requires: bash; bun; HTH_CANDIDATE_POLICY for verify
#   changes: prints candidate compatibility settings or reads supplied TOML; no trust decisions
#   source: https://docs.x.ai/build/settings/reference#cursor--claude-compatibility-scanners
# HTH Guide Excerpt: begin compatibility-policy
set -euo pipefail
command -v bun >/dev/null || { echo 'PRECONDITION: Bun is required.' >&2; exit 2; }
export HTH_GROK_ACTION="${1:-render}"
bun - <<'JS'
const action = process.env.HTH_GROK_ACTION;
const kinds = ["skills", "rules", "agents", "mcps", "hooks"];
if (action === "render") {
  console.log("# Merge into root-owned /etc/grok/requirements.toml; audit native .grok/.agents sources separately.");
  for (const vendor of ["cursor", "claude"]) console.log(`\n[compat.${vendor}]\n${kinds.map(kind => `${kind} = false`).join("\n")}`);
} else if (action === "verify") {
  const path = process.env.HTH_CANDIDATE_POLICY;
  if (!path) { console.error("PRECONDITION: supply HTH_CANDIDATE_POLICY."); process.exit(2); }
  let p;
  try { p = Bun.TOML.parse(await Bun.file(path).text()); }
  catch { console.error("PRECONDITION: supplied policy is unreadable or invalid TOML."); process.exit(2); }
  const ok = ["cursor", "claude"].every(vendor => kinds.every(kind => p.compat?.[vendor]?.[kind] === false));
  console.log(JSON.stringify({candidate_fields_match: ok, not_proven: ["native rules and extensions disabled", "trusted folder state", "hook availability", "package provenance", "effective pins"]}));
  process.exit(ok ? 0 : 1);
} else { console.error("Usage: compatibility-policy.sh [render|verify]"); process.exit(2); }
JS
# HTH Guide Excerpt: end compatibility-policy
