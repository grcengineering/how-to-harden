#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-build-2.1
#   guide: https://howtoharden.com/guides/grok-build/#21-lock-bypass-and-bound-interactive-and-headless-approvals
#   profile: L1
#   mode: read-only
#   requires: bash; bun; HTH_CANDIDATE_POLICY for verify
#   changes: prints a candidate policy or reads supplied TOML; never launches Grok
#   source: https://docs.x.ai/build/enterprise#security-controls
# HTH Guide Excerpt: begin permission-policy
set -euo pipefail
command -v bun >/dev/null || { echo 'PRECONDITION: Bun is required.' >&2; exit 2; }
export HTH_GROK_ACTION="${1:-render}"
bun - <<'JS'
const action = process.env.HTH_GROK_ACTION;
if (action === "render") {
  console.log(`# Merge into root-owned /etc/grok/requirements.toml, not ~/.grok/requirements.toml.
[ui]
permission_mode = "ask"
disable_bypass_permissions_mode = true
remember_tool_approvals = false

[features]
worktree_inherits_main_approvals = false

[sandbox]
auto_allow_bash = false`);
} else if (action === "verify") {
  const path = process.env.HTH_CANDIDATE_POLICY;
  if (!path) { console.error("PRECONDITION: supply HTH_CANDIDATE_POLICY."); process.exit(2); }
  let p;
  try { p = Bun.TOML.parse(await Bun.file(path).text()); }
  catch { console.error("PRECONDITION: supplied policy is unreadable or invalid TOML."); process.exit(2); }
  const ok = p.ui?.permission_mode === "ask" && p.ui?.disable_bypass_permissions_mode === true &&
    p.ui?.remember_tool_approvals === false && p.features?.worktree_inherits_main_approvals === false &&
    p.sandbox?.auto_allow_bash === false;
  console.log(JSON.stringify({candidate_fields_match: ok, not_proven: ["root-owned installed source", "effective pins", "saved approval state", "runtime bypass rejection"]}));
  process.exit(ok ? 0 : 1);
} else { console.error("Usage: permission-policy.sh [render|verify]"); process.exit(2); }
JS
# HTH Guide Excerpt: end permission-policy
