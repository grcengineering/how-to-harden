#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-7.2
#   guide:   https://howtoharden.com/guides/cursor/#72-scan-for-secrets-in-code-before-ai-processing
#   profile: L2
#   mode:    mutating
#   requires: jq; run from the project root (writes .cursor/hooks/ and .cursor/hooks.json)
# =============================================================================
# HTH Cursor Control 7.2: Scan for Secrets in Code Before AI Processing
# Profile Level: L2 (Walk) | NIST 800-53: IA-5
# Source: https://howtoharden.com/guides/cursor/#72-scan-for-secrets-in-code-before-ai-processing
#
# Installs a project hook that runs on `beforeReadFile` (Agent) and
# `beforeTabFileRead` (Tab) and DENIES the read when the file content carries a
# credential, so the content never reaches a model
# (https://cursor.com/docs/hooks — "Use for access control to block sensitive
# files from being sent to the model"). Both are permission hooks: Cursor blocks
# on invalid JSON, and `failClosed: true` makes a crash or timeout block too
# instead of the default fail-open.
#
# Project hooks only run in a TRUSTED workspace (same doc), so this depends on
# Workspace Trust (7.1). Commit .cursor/hooks.json and .cursor/hooks/ and put
# them under CODEOWNERS review (6.2).
#
# Detection is deliberately narrow — high-confidence credential formats only
# (private-key headers, AWS access key ids, GitHub tokens, OpenAI/Anthropic keys,
# Slack tokens). It complements, and does not replace, a repository secret
# scanner in pre-commit and CI.
#
# Exit codes: 0 installed and self-test passed | 1 self-test failed |
# 2 precondition (jq missing, invalid existing hooks.json)
# =============================================================================

set -uo pipefail
command -v jq >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin cli-install-secret-read-hook
# Write the hook script (fails closed: any parse error returns deny)
HOOK=".cursor/hooks/hth-deny-secret-reads.sh"
mkdir -p .cursor/hooks
cat > "$HOOK" <<'HOOKSCRIPT'
#!/usr/bin/env bash
# HTH 7.2 — deny Agent/Tab file reads whose content carries a credential.
set -o pipefail
deny() {
  if [ "${EVENT:-}" = "beforeTabFileRead" ]; then printf '{"permission":"deny"}\n'
  else jq -nc --arg m "$1" '{permission:"deny", user_message:$m}' 2>/dev/null \
       || printf '{"permission":"deny"}\n'; fi
  exit 0
}
command -v jq >/dev/null 2>&1 || { printf '{"permission":"deny"}\n'; exit 0; }
INPUT=$(cat) || deny "HTH 7.2 hook could not read its input; read blocked"
EVENT=$(printf '%s' "$INPUT" | jq -r '.hook_event_name // ""' 2>/dev/null) || deny "HTH 7.2 hook received invalid JSON; read blocked"
VERDICT=$(printf '%s' "$INPUT" | jq -r '(.content // "") |
  if test("-----BEGIN ([A-Z]+ )?PRIVATE KEY-----|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{36,}|sk-(proj|ant)-[A-Za-z0-9_-]{20,}|xox[abprs]-[A-Za-z0-9-]{10,}")
  then "deny" else "allow" end' 2>/dev/null) || deny "HTH 7.2 hook could not scan the file; read blocked"
case "$VERDICT" in
  allow) printf '{"permission":"allow"}\n' ;;
  deny)  deny "Blocked by HTH 7.2: this file appears to contain a credential. Move the secret out of the file." ;;
  *)     deny "HTH 7.2 hook produced no verdict; read blocked" ;;
esac
HOOKSCRIPT
chmod 700 "$HOOK"

# Register it for Agent reads and Tab reads with failClosed, idempotently
HOOKS_JSON=".cursor/hooks.json"
[ -f "$HOOKS_JSON" ] || printf '{"version":1,"hooks":{}}\n' > "$HOOKS_JSON"
jq -e . "$HOOKS_JSON" >/dev/null 2>&1 || { echo "ERROR: $HOOKS_JSON is not valid JSON — fix it first"; exit 2; }
NEW_JSON=$(jq --arg cmd "$HOOK" '
  .version = (.version // 1)
  | .hooks.beforeReadFile    = (((.hooks.beforeReadFile    // []) | map(select(.command != $cmd))) + [{command: $cmd, failClosed: true}])
  | .hooks.beforeTabFileRead = (((.hooks.beforeTabFileRead // []) | map(select(.command != $cmd))) + [{command: $cmd, failClosed: true}])
' "$HOOKS_JSON") || { echo "ERROR: could not update $HOOKS_JSON"; exit 2; }
printf '%s\n' "$NEW_JSON" > "$HOOKS_JSON"
echo "Installed $HOOK for beforeReadFile and beforeTabFileRead (failClosed) in $HOOKS_JSON"
# HTH Guide Excerpt: end cli-install-secret-read-hook

# HTH Guide Excerpt: begin cli-test-secret-read-hook
# Self-test: a credential is denied, clean content is allowed, bad input is denied
FAILED=0
KEY_HEADER="-----BEGIN RSA PRIV""ATE KEY-----"
check() { # check <expected> <label> <json-input>
  local got
  got=$(printf '%s' "$3" | bash "$HOOK" | jq -r '.permission' 2>/dev/null)
  if [ "$got" = "$1" ]; then echo "  PASS: $2 -> $got"; else echo "  FAIL: $2 -> ${got:-no output} (expected $1)"; FAILED=1; fi
}
echo "=== Hook self-test ==="
check deny  "private key in content" "$(jq -nc --arg c "$KEY_HEADER" '{hook_event_name:"beforeReadFile", file_path:"/w/id_rsa", content:$c}')"
check allow "ordinary source file"   "$(jq -nc '{hook_event_name:"beforeReadFile", file_path:"/w/app.py", content:"print(1)"}')"
check deny  "malformed hook input"   "not json"
exit "$FAILED"
# HTH Guide Excerpt: end cli-test-secret-read-hook
