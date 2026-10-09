#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-dots-4.3
#   guide:   https://howtoharden.com/guides/chatgpt-dots/#43-treat-managed-mcp-hooks-for-dots-as-fail-open-telemetry-not-enforcement
#   profile: L3
#   mode:    read-only
#   requires: awk, grep; emit: HTH_HOOK_SERVER, HTH_HOOK_TOOL, HTH_HOOK_MATCHER(optional), HTH_HOOK_TIMEOUT(optional, default 30), HTH_MANAGED_HOOKS_ONLY(optional); verify: a saved copy of the Global requirements TOML
# =============================================================================
# HTH ChatGPT Dots Control 4.3: Treat managed MCP hooks for dots as fail-open
#   telemetry, not enforcement
# Profile Level: L3 (Run)
# Frameworks: CIS Controls v8 8.2; NIST 800-53 SI-4, AU-12;
#   SOC 2 CC7.2; no benchmark equivalent yet
# Dependencies: awk, grep
#
# Sources (every key and quoted sentence below comes from these pages, fetched
# 2026-10-08):
#   https://learn.chatgpt.com/docs/hooks   (mcp_tool fields, matcher, PreToolUse)
#   https://learn.chatgpt.com/docs/enterprise/agent-security
#   https://learn.chatgpt.com/docs/enterprise/cloud-local-access
#   https://learn.chatgpt.com/docs/enterprise/managed-configuration  (TOML form)
#   https://learn.chatgpt.com/docs/config-file/config-reference  (requirements.toml)
#
# WHY `mode: read-only`. Nothing in this file writes to OpenAI or to disk. `emit`
# prints a TOML fragment for Admin Console > Agent Security > (select a policy) >
# Global > Requirements. No UI control for hooks is documented there (Agent
# Security names dedicated controls only for approval policies and web search
# modes), and the policy API the docs mention has no published contract (the
# Admin API spec cites a "public API PUT" for policy-stack saves but publishes no
# route), so a human pastes it. `verify` lints a copy of that TOML you saved.
#
# ── TRAP 1: hooks fail open ──────────────────────────────────────────────────
# "An explicit supported denial can block an action, but a PreToolUse callback
# error, timeout, or malformed response can fail the hook without blocking the
# tool." The Hooks page adds "Errors, missing servers, and unavailable tools
# don't block the operation" and "Treat tool hooks as a useful guardrail, not a
# complete enforcement boundary." Anyone who degrades your MCP service removes
# the block. A shorter timeout bounds the stall; it does not close the gap.
#
# ── TRAP 2: only mcp_tool handlers reach dots ────────────────────────────────
# "Command/shell, prompt, and agent handlers; hooks from local configuration,
# plugins, or local directories; environment-scoped hooks; and SessionEnd MCP
# hooks are not supported with cloud orchestration". `verify` reports any other
# handler type as not applying to dots. Hooks also need "managed policy and
# remote hooks" enabled for the workspace; no toggle name is documented.
#
# ── TRAP 3: the server must already be connected ─────────────────────────────
# `server` is the "Required name of an already-connected MCP server", and hooks
# "don't start or reconnect servers". A typo or a disconnected server is just
# another fail-open path.
#
# ── TRAP 4: the TOML form is derived, and two pages disagree ─────────────────
# The Hooks page prints the mcp_tool example in JSON only; the TOML below follows
# its documented "Equivalent inline TOML" pattern ([[hooks.<Event>]] /
# [[hooks.<Event>.hooks]]). Agent Security lists "Managed hooks | hooks,
# allow_managed_hooks_only" as Global fields, but the Configuration Reference's
# "Configured through TOML" list for Work Cloud and dots omits hooks, and its
# requirements `hooks` key says it "Requires a managed hook directory" (a Codex
# rule for command scripts). Whether cloud mcp_tool-only hooks need managed_dir
# is undocumented, so this pack does not emit it. If Agent Security rejects the
# fragment on save, record the validation message.
#
# ── TRAP 5: the event fields are documented for Codex ────────────────────────
# `input` placeholders read "a dotted field from the hook event". The PreToolUse
# fields used below (session_id, tool_name, tool_use_id, tool_input) are
# documented for Codex hooks; the field set the cloud orchestrator sends for dots
# is not. Hosted tools such as WebSearch never reach PreToolUse, and hooks do not
# "cover every internal subagent path". Your MCP tool must tolerate missing fields.
#
# ── TRAP 6: allow_managed_hooks_only does nothing documented for dots ────────
# It "skips user, project, session, and plugin hooks", which cloud orchestration
# already ignores. Emit it only to cover local-only Work and Codex threads that
# run under the same policy.
#
# ── TRAP 7: not an audit trail ───────────────────────────────────────────────
# "MCP hooks do not provide a complete Compliance API audit trail." Agent Security
# UI saves show up as AUDIT_LOG WORKSPACE_SET_POLICY (codex.agent_policy) with no
# hook contents; codex.policy_stack saves record only the changed key path
# ["hooks","PreToolUse"] (arrays of tables are compared at their containing key),
# never the values.
#
# ── TRAP 8: a feature pin can switch every hook off ──────────────────────────
# "Admins can force hooks off the same way in `requirements.toml` with
# `[features].hooks = false`" (Hooks page; `codex_hooks` is a deprecated alias).
# The Configuration Reference's "Local computer access with Work Cloud
# compatibility limits" table rates "features / `feature_requirements`" only
# "Partial", so whether the dots orchestrator honours the pin is undocumented.
# `verify` fails any file that pins hooks off rather than guessing.
#
# Usage:  emit          -> print the Global requirements hook fragment
#         verify FILE   -> lint the hooks in a saved copy of Global requirements
# Exit codes: 0 ok | 1 finding | 2 precondition
# =============================================================================

set -euo pipefail

ACTION="${1:-verify}"

# HTH Guide Excerpt: begin emit-managed-mcp-hook
# Print a PreToolUse mcp_tool hook for Agent Security > Global > Requirements.
#   HTH_HOOK_SERVER   name of an MCP server already connected for the workspace
#   HTH_HOOK_TOOL     tool on that server that answers allow/deny
#   HTH_HOOK_MATCHER  regex on tool name; unset = every supported tool call
#   HTH_HOOK_TIMEOUT  seconds, default 30 (the documented default is 600)
#   HTH_MANAGED_HOOKS_ONLY=1  also emit allow_managed_hooks_only = true
if [ "$ACTION" = "emit" ]; then
  [ -n "${HTH_HOOK_SERVER:-}" ] || { echo "PRECONDITION: set HTH_HOOK_SERVER to the name of an already-connected MCP server" >&2; exit 2; }
  [ -n "${HTH_HOOK_TOOL:-}" ] || { echo "PRECONDITION: set HTH_HOOK_TOOL to the tool on that server that returns the decision" >&2; exit 2; }
  TIMEOUT="${HTH_HOOK_TIMEOUT:-30}"
  for v in "$HTH_HOOK_SERVER" "$HTH_HOOK_TOOL"; do
    printf '%s' "$v" | grep -E '^[A-Za-z0-9_.-]+$' >/dev/null || {
      echo "ERROR: '$v' — use letters, digits, '_', '.' or '-' only" >&2; exit 2; }
  done
  printf '%s' "$TIMEOUT" | grep -E '^[1-9][0-9]*$' >/dev/null || {
    echo "ERROR: HTH_HOOK_TIMEOUT must be a positive integer (seconds)" >&2; exit 2; }
  case "${HTH_HOOK_MATCHER:-}" in
    *"'"*) echo "ERROR: HTH_HOOK_MATCHER cannot contain a single quote (emitted as a TOML literal string)" >&2; exit 2 ;;
  esac

  if [ "${HTH_MANAGED_HOOKS_ONLY:-0}" = "1" ]; then
    printf 'allow_managed_hooks_only = true\n\n'
  fi
  printf '[[hooks.PreToolUse]]\n'
  if [ -n "${HTH_HOOK_MATCHER:-}" ]; then
    printf "matcher = '%s'\n" "$HTH_HOOK_MATCHER"
  fi
  printf '\n[[hooks.PreToolUse.hooks]]\n'
  printf 'type = "mcp_tool"\n'
  printf 'server = "%s"\n' "$HTH_HOOK_SERVER"
  printf 'tool = "%s"\n' "$HTH_HOOK_TOOL"
  printf '%s\n' 'input = { session_id = "${session_id}", tool_name = "${tool_name}", tool_use_id = "${tool_use_id}", tool_input = "${tool_input}" }'
  printf 'timeout = %s\n' "$TIMEOUT"
  printf 'statusMessage = "Checking tool call against workspace policy"\n'
  exit 0
fi
# HTH Guide Excerpt: end emit-managed-mcp-hook

# HTH Guide Excerpt: begin verify-managed-mcp-hooks
# Lint the hook handlers in a saved copy of the Global requirements TOML.
# Passing means "configured", never "enforced": prove the block with a deny-all
# tool, then prove fail-open by taking the MCP service offline.
toml_flatten() {   # prints "<section>\t<key>\t<value>"; section is "" at top level
  awk -v SQ="'" '
    function strip(s,   i, c, q, out, esc) {
      q = ""; out = ""; esc = 0
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (q == "\"") { out = out c; if (esc) esc = 0; else if (c == "\\") esc = 1; else if (c == "\"") q = ""; continue }
        if (q == SQ)   { out = out c; if (c == SQ) q = ""; continue }
        if (c == "#") break
        if (c == "\"" || c == SQ) q = c
        out = out c
      }
      return out
    }
    function depth(s,   i, c, q, d, esc) {
      q = ""; d = 0; esc = 0
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (q == "\"") { if (esc) esc = 0; else if (c == "\\") esc = 1; else if (c == "\"") q = ""; continue }
        if (q == SQ)   { if (c == SQ) q = ""; continue }
        if (c == "\"" || c == SQ) q = c
        else if (c == "[") d++
        else if (c == "]") d--
      }
      return d
    }
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function emit() { printf "%s\t%s\t%s\n", sect, key, trim(val); key = ""; val = "" }
    BEGIN { sect = ""; n = 0; mls = ""; arr = 0; TQ = SQ SQ SQ }
    {
      line = $0; sub(/\r$/, "", line)
      if (mls != "") {
        p = index(line, mls)
        if (p > 0) { val = val " " substr(line, 1, p - 1); mls = ""; emit() } else val = val " " line
        next
      }
      if (arr > 0) { s = strip(line); val = val " " s; arr += depth(s); if (arr <= 0) { arr = 0; emit() }; next }
      s = trim(strip(line))
      if (s == "") next
      if (substr(s, 1, 1) == "[") { n++; sect = s "#" n; next }
      eq = index(s, "="); if (eq == 0) next
      key = trim(substr(s, 1, eq - 1))
      rest = trim(substr(line, index(line, "=") + 1))
      d3 = substr(rest, 1, 3)
      if (d3 == "\"\"\"" || d3 == TQ) {
        body = substr(rest, 4); p = index(body, d3)
        if (p > 0) { val = substr(body, 1, p - 1); emit() } else { val = body; mls = d3 }
        next
      }
      val = trim(strip(rest))
      if (substr(val, 1, 1) == "[") { arr = depth(val); if (arr > 0) next }
      emit()
    }
  ' "$1"
}

if [ "$ACTION" = "verify" ]; then
  FILE="${2:-${HTH_REQUIREMENTS_FILE:-}}"
  [ -n "$FILE" ] && [ -r "$FILE" ] || { echo "PRECONDITION: pass a saved copy of the Global requirements TOML" >&2; exit 2; }
  FLAT=$(mktemp "${TMPDIR:-/tmp}/hth-dots-403.XXXXXX"); trap 'rm -f "$FLAT"' EXIT
  toml_flatten "$FILE" > "$FLAT"

  # One record per handler: event, type, server, tool, timeout ("-" when absent).
  HANDLERS=$(awk -F'\t' -v SQ="'" '
    function get(id, k) { return (f[id, k] != "" ? f[id, k] : "-") }
    $1 ~ /^\[\[hooks\.[A-Za-z]+\.hooks\]\]#/ {
      id = $1
      if (!(id in event)) { ev = id; sub(/^\[\[hooks\./, "", ev); sub(/\.hooks\]\]#.*/, "", ev); event[id] = ev; ids[++m] = id }
      v = $3; gsub("^[\"" SQ "]|[\"" SQ "]$", "", v); f[id, $2] = v
    }
    END { for (i = 1; i <= m; i++) { id = ids[i]
            printf "%s\t%s\t%s\t%s\t%s\n", event[id], get(id, "type"), get(id, "server"), get(id, "tool"), get(id, "timeout") } }
  ' "$FLAT")

  if awk -F'\t' '$1 ~ /^\[\[hooks\.[A-Za-z]+\]\]#/ && $2 == "hooks" { f = 1 } END { exit !f }' "$FLAT"; then
    echo "UNVERIFIED: handlers written as an inline array (hooks = [...]) — review them by hand" >&2; exit 2
  fi
  # The same handlers written as a [hooks] table with event-named array keys, or
  # as a top-level hooks / hooks.<Event> key, are valid TOML this lint does not parse.
  if awk -F'\t' '($1 ~ /^\[[ \t]*hooks[ \t]*\]#/ && $3 ~ /^\[/) ||
                 ($1 == "" && ($2 == "hooks" || $2 ~ /^hooks\./)) { f = 1 } END { exit !f }' "$FLAT"; then
    echo "UNVERIFIED: hooks written as an inline table or array ([hooks] / hooks = ...) — review them by hand" >&2; exit 2
  fi

  GOOD=0; FAILS=0
  # Hooks page: "Admins can force hooks off the same way in requirements.toml
  # with [features].hooks = false." codex_hooks is the deprecated alias (TRAP 8).
  if awk -F'\t' '
       function off(v) { gsub(/[ \t]/, "", v); return v == "false" }
       ($1 ~ /^\[[ \t]*features[ \t]*\]#/ && ($2 == "hooks" || $2 == "codex_hooks") && off($3)) ||
       ($1 == "" && ($2 == "features.hooks" || $2 == "features.codex_hooks") && off($3)) ||
       ($1 == "" && $2 == "features" && $3 ~ /(^|[{,[:space:]])(codex_)?hooks[[:space:]]*=[[:space:]]*false([[:space:]]*[,}]|$)/) { f = 1 }
       END { exit !f }' "$FLAT"; then
    echo "  FAIL: [features].hooks (or codex_hooks) = false force-disables hooks in this same file (Hooks page); remove it"; FAILS=1
  fi
  while IFS=$'\t' read -r ev type server tool timeout; do
    [ -n "$ev" ] || continue
    case "$type" in
      mcp_tool)
        if [ "$ev" = "SessionEnd" ]; then
          echo "  FAIL: SessionEnd mcp_tool hook — not supported with cloud orchestration"; FAILS=1
        elif [ "$server" = "-" ] || [ "$tool" = "-" ]; then
          echo "  FAIL: $ev mcp_tool hook is missing server or tool (both are required)"; FAILS=1
        else
          [ "$timeout" = "-" ] && timeout="600 (documented default)"
          echo "  PASS: $ev mcp_tool hook -> server=$server tool=$tool timeout=$timeout"
          [ "$ev" = "PreToolUse" ] && GOOD=1
        fi ;;
      *) echo "  NOTE: $ev handler type '$type' is not supported with cloud orchestration; it does not run for dots" ;;
    esac
  done <<< "$HANDLERS"

  if awk -F'\t' '$1 == "" && $2 == "allow_managed_hooks_only" { f = 1 } END { exit !f }' "$FLAT"; then
    echo "  INFO: allow_managed_hooks_only is set; it has no documented effect on dots"
  fi
  if [ "$GOOD" = 0 ]; then
    echo "  FAIL: no PreToolUse mcp_tool hook is configured, so nothing can block a dot's tool call"; FAILS=1
  fi
  exit "$FAILS"
fi
# HTH Guide Excerpt: end verify-managed-mcp-hooks

echo "usage: $0 emit | verify FILE" >&2
exit 2
