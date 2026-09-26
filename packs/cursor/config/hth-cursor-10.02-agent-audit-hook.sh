#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-10.2
#   guide:   https://howtoharden.com/guides/cursor/#102-monitor-for-suspicious-agent-activity
#   profile: L2
#   mode:    mutating
#   requires: jq; writes ~/.cursor/hooks/ and ~/.cursor/hooks.json (user scope)
# =============================================================================
# HTH Cursor Control 10.2: Monitor for Suspicious Agent Activity
# Profile Level: L2 (Walk) | NIST 800-53: AU-6, SI-4
# Source: https://howtoharden.com/guides/cursor/#102-monitor-for-suspicious-agent-activity
#
# Cursor's audit log does not record agent actions — "We do not log agent
# responses or generated code content. Instead, we recommend using hooks to log
# prompts and code." (https://cursor.com/docs/enterprise/compliance-and-monitoring).
# This installs a user-scope audit hook on afterShellExecution,
# afterMCPExecution and afterFileEdit that appends one JSON line per agent
# action to ~/.cursor/hth-agent-audit.jsonl, with `suspicious: true` on the
# indicators this control names: fetch/exec pipes, reverse shells, writes to
# shell startup files, and edits to mcp.json / hooks.json. Ship the file to your
# SIEM with your endpoint agent and alert on `suspicious`.
#
# Recorded: time, event, user_email, workspace_roots, command / MCP server+tool
# / edited path, duration, sandbox. NOT recorded: command output, MCP results or
# edit contents — those can hold secrets.
#
# For fleet-wide, non-removable deployment, place the same files at the
# Enterprise hooks path through MDM (see 11.2 / 11.3).
#
# Exit codes: 0 installed and self-test passed | 1 self-test failed |
# 2 precondition
# =============================================================================

set -uo pipefail
command -v jq >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin cli-install-audit-hook
CURSOR_DIR="${HOME}/.cursor"
HOOK="${CURSOR_DIR}/hooks/hth-agent-audit.sh"
mkdir -p "${CURSOR_DIR}/hooks"
cat > "$HOOK" <<'HOOKSCRIPT'
#!/usr/bin/env bash
# HTH 10.2 — append one JSON line per agent action; never records outputs or contents.
LOG="${HTH_AGENT_AUDIT_LOG:-${HOME}/.cursor/hth-agent-audit.jsonl}"
INPUT=$(cat)
printf '%s' "$INPUT" | jq -c '
  def sus($s): ($s // "") | test("(curl|wget)[^|;]*\\|\\s*(ba|z|da)?sh\\b|base64\\s+(-d|-D|--decode)|/dev/tcp/|\\bnc(at)?\\s[^;|]*-e\\s|\\.(zshenv|zshrc|zprofile|bashrc|bash_profile|profile)\\b|cursor-tunnel");
  def susfile($p): ($p // "") | test("/\\.(zshenv|zshrc|zprofile|bashrc|bash_profile|profile)$|/\\.cursor/(mcp|hooks)\\.json$");
  {
    ts: (now | todate),
    event: .hook_event_name,
    user_email: .user_email,
    workspace_roots: .workspace_roots,
    command: .command,
    mcp_server: .mcp_server_name,
    mcp_tool: .tool_name,
    file_path: .file_path,
    duration_ms: .duration,
    sandbox: .sandbox,
    suspicious: (sus(.command) or susfile(.file_path))
  } | with_entries(select(.value != null))' >> "$LOG" 2>/dev/null \
  || printf '{"ts":"%s","event":"hth-audit-hook-error"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOG"
exit 0
HOOKSCRIPT
chmod 700 "$HOOK"

HOOKS_JSON="${CURSOR_DIR}/hooks.json"
[ -f "$HOOKS_JSON" ] || printf '{"version":1,"hooks":{}}\n' > "$HOOKS_JSON"
jq -e . "$HOOKS_JSON" >/dev/null 2>&1 || { echo "ERROR: $HOOKS_JSON is not valid JSON — fix it first"; exit 2; }
NEW_JSON=$(jq --arg cmd "$HOOK" '
  .version = (.version // 1)
  | reduce ("afterShellExecution","afterMCPExecution","afterFileEdit") as $e (.;
      .hooks[$e] = (((.hooks[$e] // []) | map(select(.command != $cmd))) + [{command: $cmd}]))
' "$HOOKS_JSON") || { echo "ERROR: could not update $HOOKS_JSON"; exit 2; }
printf '%s\n' "$NEW_JSON" > "$HOOKS_JSON"
echo "Installed $HOOK for afterShellExecution, afterMCPExecution, afterFileEdit in $HOOKS_JSON"
# HTH Guide Excerpt: end cli-install-audit-hook

# HTH Guide Excerpt: begin cli-test-audit-hook
# Self-test into a scratch log: a startup-file write is flagged, `npm test` is not,
# and the command output is never written
FAILED=0
TEST_LOG="$(mktemp "${TMPDIR:-/tmp}/hth-audit-test.XXXXXX")" || exit 2
jq -nc '{hook_event_name:"afterShellExecution", command:"echo x >> ~/.zshenv", output:"SECRET-OUTPUT", duration:5, sandbox:false}' \
  | HTH_AGENT_AUDIT_LOG="$TEST_LOG" bash "$HOOK"
jq -nc '{hook_event_name:"afterShellExecution", command:"npm test", output:"ok", duration:900, sandbox:true}' \
  | HTH_AGENT_AUDIT_LOG="$TEST_LOG" bash "$HOOK"
if [ "$(sed -n 1p "$TEST_LOG" | jq -r '.suspicious')" = "true" ]; then echo "  PASS: startup-file write flagged"; else echo "  FAIL: startup-file write not flagged"; FAILED=1; fi
if [ "$(sed -n 2p "$TEST_LOG" | jq -r '.suspicious')" = "false" ]; then echo "  PASS: npm test not flagged"; else echo "  FAIL: npm test flagged"; FAILED=1; fi
if grep -q 'SECRET-OUTPUT' "$TEST_LOG"; then echo "  FAIL: command output leaked into the log"; FAILED=1; else echo "  PASS: command output not recorded"; fi
rm -f "$TEST_LOG"
exit "$FAILED"
# HTH Guide Excerpt: end cli-test-audit-hook
