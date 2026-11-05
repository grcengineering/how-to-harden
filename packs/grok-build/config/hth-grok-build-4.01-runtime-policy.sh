#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-build-4.1
#   guide: https://howtoharden.com/guides/grok-build/#41-limit-model-destinations-tools-and-unattended-execution
#   profile: L2
#   mode: read-only
#   requires: bash; bun; HTH_ALLOWED_MODEL_IDS_JSON; HTH_CANDIDATE_POLICY for verify
#   changes: prints candidate runtime settings or reads supplied TOML; no inference or network requests
#   source: https://docs.x.ai/build/settings/reference
# HTH Guide Excerpt: begin runtime-policy
set -euo pipefail
command -v bun >/dev/null || { echo 'PRECONDITION: Bun is required.' >&2; exit 2; }
export HTH_GROK_ACTION="${1:-render}"
bun - <<'JS'
const action = process.env.HTH_GROK_ACTION;
let models;
try { models = JSON.parse(process.env.HTH_ALLOWED_MODEL_IDS_JSON ?? ""); } catch {}
if (!Array.isArray(models) || !models.length || models.some(id => typeof id !== "string" || !/^[A-Za-z0-9][A-Za-z0-9._:/-]{0,127}$/.test(id)) || new Set(models).size !== models.length) {
  console.error("PRECONDITION: HTH_ALLOWED_MODEL_IDS_JSON must be a nonempty array of distinct approved model IDs, without globs."); process.exit(2);
}
if (action === "render") {
  console.log(`# Merge into root-owned /etc/grok/requirements.toml.
# Exact model IDs do not attest their base_url or prevent other tool/process networking.
[models]
allowed_models = ${JSON.stringify(models)}

[features]
web_fetch = false

[session]
load_envrc = false

[goal]
enabled = false

[subagents]
enabled = false`);
} else if (action === "verify") {
  const path = process.env.HTH_CANDIDATE_POLICY;
  if (!path) { console.error("PRECONDITION: supply HTH_CANDIDATE_POLICY."); process.exit(2); }
  let p;
  try { p = Bun.TOML.parse(await Bun.file(path).text()); }
  catch { console.error("PRECONDITION: supplied policy is unreadable or invalid TOML."); process.exit(2); }
  const allowed = p.models?.allowed_models;
  const ok = Array.isArray(allowed) && allowed.length === models.length && allowed.every(id => models.includes(id)) &&
    p.features?.web_fetch === false && p.session?.load_envrc === false && p.goal?.enabled === false && p.subagents?.enabled === false;
  console.log(JSON.stringify({candidate_fields_match: ok, not_proven: ["model endpoint identity", "provider IAM", "all egress paths", "existing background tasks stopped", "environment credential minimization", "effective pins"]}));
  process.exit(ok ? 0 : 1);
} else { console.error("Usage: runtime-policy.sh [render|verify]"); process.exit(2); }
JS
# HTH Guide Excerpt: end runtime-policy
