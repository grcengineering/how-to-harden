#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-dots-4.2
#   guide:   https://howtoharden.com/guides/chatgpt-dots/#42-enforce-orchestrator-approval-and-web-search-limits-in-the-agent-security-global-baseline
#   profile: L2
#   mode:    read-only
#   requires: awk, grep; `verify` needs a saved copy of the Global requirements TOML; HTH_APPROVAL_POLICIES, HTH_WEB_SEARCH_MODES, HTH_APPROVALS_REVIEWERS, HTH_GUARDIAN_POLICY_FILE (all optional, emit only)
# =============================================================================
# HTH ChatGPT Dots Control 4.2: Enforce orchestrator approval and web-search
#   limits in the Agent Security Global baseline
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls v8 4.1; NIST 800-53 CM-6, CM-7, AC-4;
#   SOC 2 CC6.1, CC8.1; no benchmark equivalent yet
# Dependencies: awk, grep
#
# Sources (every key, value and quoted sentence below comes from these pages,
# fetched 2026-10-08):
#   https://learn.chatgpt.com/docs/enterprise/agent-security
#   https://learn.chatgpt.com/docs/config-file/config-reference  (requirements.toml)
#   https://learn.chatgpt.com/docs/enterprise/managed-configuration  (TOML examples)
#   https://learn.chatgpt.com/docs/web-search
#   https://learn.chatgpt.com/docs/sandboxing/auto-review
#   https://learn.chatgpt.com/docs/enterprise/dots-admin-guide
#   https://chatgpt.com/public/admin/api-reference  (Admin API v2.5.37; returns
#     403 to curl, so its contents come from the research ledger's real-browser read)
#
# WHY `mode: read-only`. Nothing in this file writes to OpenAI or to disk. `emit`
# prints a TOML fragment on stdout; a workspace admin applies it by hand in
# Admin Console > Agent Security > (select a policy) > Global > Requirements.
# `verify` lints a copy of that policy's TOML that you saved yourself.
#
# ── TRAP 1: the "policy API" has no published contract ──────────────────────
# Agent Security says "Use the policy API to manage Global settings" and asks you
# to "Test your scripts and Terraform integrations", but the public Admin API
# reference (v2.5.37, 106 paths, no PUT operation) has no policy route, even
# though its own WORKSPACE_SET_POLICY text cites Codex policy-stack saves "from
# the UI and public API PUT". The Configuration Reference adds "Support for a
# requirements.toml field does not by itself establish API compatibility." This
# pack therefore cannot push or pull the policy. Apply by hand, then re-verify
# against a freshly saved copy.
#
# ── TRAP 2: only two of these fields have UI controls ────────────────────────
# "only Allowed approval policies and Allowed web search modes have dedicated
# controls in the Agent Security UI. Configure the other fields through TOML."
# The docs do not name the UI label of the TOML entry point.
#
# ── TRAP 3: reaching dots is conditional, so test it ─────────────────────────
# "For Work with local access and dots, supported Global policy applies through
# the shared cloud orchestrator when managed policy is enabled." The approval
# values are Codex vocabulary, and the dots admin guide never mentions Agent
# Security. A dot's per-action confirmations come from its own automatic action
# review, Plugin controls and the "Use custom rules for dots" permission. These
# fields "do not configure shared cloud capability permissions" either (Cloud
# browser use, Cloud network access, Cloud computer use). Give a cloud-only dot a
# consequential task and confirm it asks for approval before relying on this.
#
# ── TRAP 4: an omitted key is unconstrained, and `never` must be absent ──────
# "Omitted keys remain unconstrained." A Global policy without
# allowed_approval_policies permits `never`, and "With approval_policy = "never",
# there is nothing to review." Listing `untrusted` only permits "the stricter
# policy derived from an untrusted project; it cannot be selected directly with
# approval_policy", and approval_policy = "untrusted" itself is retired.
#
# ── TRAP 5: cached search still carries injection risk ───────────────────────
# Documented values: disabled, cached, indexed, live. "disabled is always
# allowed; an empty list effectively allows only disabled." Cached mode "lowers
# —but doesn't remove—prompt injection risk". Web search is a hosted tool, so the
# tool hooks in control 4.3 never see it.
#
# ── TRAP 6: auto-review is not a guarantee, and its policy REPLACES ─────────
# Auto-review "is not a deterministic security guarantee". If auto_review is an
# allowed reviewer (explicitly, or because allowed_approvals_reviewers is
# omitted), set guardian_policy_config, which "takes precedence over local
# [auto_review].policy. Blank values are ignored." A blank value therefore leaves
# the member's local policy in charge.
# guardian_policy_config REPLACES the reviewer policy; it does not add to it.
# Auto-review: "Both [auto_review].policy and guardian_policy_config replace your
# current reviewer policy. They don't merge with policies bundled with your model
# or managed by your organization ... copy the complete current policy, keep
# every existing rule ... If you can't access the current policy, don't override
# it." Managed configuration agrees that it replaces "the tenant-specific
# section" while "the built-in reviewer template and output contract" remain.
# But that page's short example is NOT a complete policy, so pasting it alone
# drops every default Data Exfiltration, Credential Probing, Persistent Security
# Weakening and Destructive Actions rule. Start HTH_GUARDIAN_POLICY_FILE from the
# complete current reviewer policy, then append your tenant rules. The
# open-source default is openai/codex codex-rs/prompts/templates/guardian/policy.md;
# the vendor's link to codex-rs/core/src/guardian/policy.md returns 404 on main
# as of 2026-10-09. A model may bundle a different policy; if you cannot see the
# policy in force, do not override it.
# Dots: the Dots FAQs (help 20001529) send "customizing the Auto-review policy"
# to the Auto-review configuration page, and "Your dot cannot turn off required
# Auto-review checks". guardian_policy_config is the one field here with a
# documented tie to a dot's Auto-review; whether it binds a cloud-only dot, and
# whether a dot's Auto-review uses the public default, are undocumented.
#
# ── TRAP 7: the audit trail records saves, not contents ──────────────────────
# AUDIT_LOG WORKSPACE_SET_POLICY: "Agent Security save attempts use
# codex.agent_policy without additional action_data". Agent Security UI saves
# log attempts (read action_result) and never the TOML. codex.policy_stack saves
# record which TOML key paths changed but never their values. Either way, the
# only content check is re-running `verify` on a fresh copy.
#
# Usage:  emit          -> print the Global requirements fragment
#         verify FILE   -> lint a saved copy of the Global requirements TOML
# Exit codes: 0 ok | 1 finding | 2 precondition
# =============================================================================

set -euo pipefail

ACTION="${1:-verify}"

# HTH Guide Excerpt: begin emit-global-orchestrator-requirements
# Print the Global requirements for Agent Security. Override the defaults with
# comma-separated lists; `never` and `live` are refused outright.
#   HTH_APPROVAL_POLICIES    default "on-request"  (allowed: on-request, granular, untrusted)
#   HTH_WEB_SEARCH_MODES     default "cached"      (allowed: disabled, cached, indexed; "" = disabled only)
#   HTH_APPROVALS_REVIEWERS  default "user"        (allowed: user, auto_review)
#   HTH_GUARDIAN_POLICY_FILE the COMPLETE reviewer policy plus tenant rules (it
#                            replaces the default; see TRAP 6). Required when
#                            auto_review is allowed; emitted whenever it is set.
toml_array() {   # toml_array "<comma list>" "<allowed values, space separated>"
  # Split with parameter expansion, not a here-string: a here-string that cannot
  # create its temp file makes `read` fail silently and would emit [] (fail open).
  local item out="" rest="$1" seen=0
  while :; do
    case "$rest" in
      *,*) item="${rest%%,*}"; rest="${rest#*,}" ;;
      *)   item="$rest"; rest="" ;;
    esac
    item=$(printf '%s' "$item" | tr -d '[:space:]')
    if [ -n "$item" ]; then
      seen=1
      case " $2 " in
        *" $item "*) out="${out:+$out, }\"$item\"" ;;
        *) echo "ERROR: '$item' is not allowed here (allowed: $2)" >&2; return 2 ;;
      esac
    fi
    [ -n "$rest" ] || break
  done
  # A non-blank input that yielded nothing is a parsing failure, never "[]".
  if [ "$seen" = 0 ] && [ -n "$(printf '%s' "$1" | tr -d '[:space:],')" ]; then
    echo "ERROR: could not parse '$1'" >&2; return 2
  fi
  printf '[%s]' "$out"
}

if [ "$ACTION" = "emit" ]; then
  approvals=$(toml_array "${HTH_APPROVAL_POLICIES:-on-request}" "on-request granular untrusted") || exit 2
  search=$(toml_array "${HTH_WEB_SEARCH_MODES-cached}" "disabled cached indexed") || exit 2
  reviewers=$(toml_array "${HTH_APPROVALS_REVIEWERS:-user}" "user auto_review") || exit 2

  printf 'allowed_approval_policies = %s\n' "$approvals"
  printf 'allowed_web_search_modes = %s\n' "$search"
  printf 'allowed_approvals_reviewers = %s\n' "$reviewers"

  POLICY="${HTH_GUARDIAN_POLICY_FILE:-}"
  case "$reviewers" in
    *'"auto_review"'*)
      [ -n "$POLICY" ] || {
        echo "ERROR: auto_review is allowed, so set HTH_GUARDIAN_POLICY_FILE to the COMPLETE current reviewer policy plus your rules (TRAP 6)" >&2; exit 2; } ;;
    *)
      [ -n "$POLICY" ] || echo "NOTE: guardian_policy_config not emitted; a dot's Auto-review keeps OpenAI's built-in policy. Set HTH_GUARDIAN_POLICY_FILE only to a complete copy of the current policy (TRAP 6)." >&2 ;;
  esac
  if [ -n "$POLICY" ]; then
    [ -r "$POLICY" ] || { echo "ERROR: HTH_GUARDIAN_POLICY_FILE '$POLICY' is not readable" >&2; exit 2; }
    grep -q '[^[:space:]]' "$POLICY" || { echo "ERROR: $POLICY is blank, and blank values are ignored" >&2; exit 2; }
    if grep -q '"""' "$POLICY"; then
      echo "ERROR: $POLICY contains \"\"\", which would end the TOML string early" >&2; exit 2
    fi
    # Tripwire, not a gate: the default policy's section headings (policy.md).
    for h in "Data Exfiltration" "Credential Probing" "Persistent Security Weakening" "Destructive Actions"; do
      grep -q "### $h" "$POLICY" \
        || echo "WARN: $POLICY has no '### $h' section; a policy missing the default rules replaces them (TRAP 6)" >&2
    done
    printf '\nguardian_policy_config = """\n'
    sed 's/\\/\\\\/g' "$POLICY"     # TOML basic strings treat backslash as an escape
    printf '"""\n'
  fi
  exit 0
fi
# HTH Guide Excerpt: end emit-global-orchestrator-requirements

# HTH Guide Excerpt: begin verify-global-orchestrator-requirements
# Lint a saved copy of the Global requirements TOML (copy it out of Agent Security
# by hand; no API returns it). Reads top-level keys only.
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
top() { awk -F'\t' -v k="$2" '$1 == "" && $2 == k { print $3; f = 1 } END { exit !f }' "$1"; }
members() { grep -oE "\"[^\"]*\"|'[^']*'" | tr -d "\"'" || true; }

if [ "$ACTION" = "verify" ]; then
  FILE="${2:-${HTH_REQUIREMENTS_FILE:-}}"
  [ -n "$FILE" ] && [ -r "$FILE" ] || { echo "PRECONDITION: pass a saved copy of the Global requirements TOML" >&2; exit 2; }
  FLAT=$(mktemp "${TMPDIR:-/tmp}/hth-dots-402.XXXXXX"); trap 'rm -f "$FLAT"' EXIT
  toml_flatten "$FILE" > "$FLAT"
  FAILS=0

  if v=$(top "$FLAT" allowed_approval_policies); then
    if printf '%s' "$v" | members | grep -x never >/dev/null; then
      echo "  FAIL: allowed_approval_policies includes \"never\""; FAILS=1
    else echo "  PASS: allowed_approval_policies = $v"; fi
  else echo "  FAIL: allowed_approval_policies is not set, so it is unconstrained and \"never\" is allowed"; FAILS=1; fi

  if v=$(top "$FLAT" allowed_web_search_modes); then
    if printf '%s' "$v" | members | grep -x live >/dev/null; then
      echo "  FAIL: allowed_web_search_modes includes \"live\""; FAILS=1
    else echo "  PASS: allowed_web_search_modes = $v (disabled is always allowed)"; fi
  else echo "  FAIL: allowed_web_search_modes is not set, so it is unconstrained and \"live\" is allowed"; FAILS=1; fi

  AUTO=1
  if v=$(top "$FLAT" allowed_approvals_reviewers); then
    echo "  INFO: allowed_approvals_reviewers = $v"
    printf '%s' "$v" | members | grep -x auto_review >/dev/null || AUTO=0
  else echo "  INFO: allowed_approvals_reviewers is not set, so auto_review is allowed"; fi
  g=$(top "$FLAT" guardian_policy_config || true)
  if [ "$AUTO" = 1 ]; then
    if printf '%s' "$g" | tr -d "\"' \t" | grep . >/dev/null; then
      echo "  PASS: guardian_policy_config is set for automatic review (confirm it is a COMPLETE policy — TRAP 6)"
    else
      echo "  FAIL: auto_review is allowed but guardian_policy_config is missing or blank"; FAILS=1
    fi
  elif ! printf '%s' "$g" | tr -d "\"' \t" | grep . >/dev/null; then
    echo "  INFO: no guardian_policy_config; a dot's Auto-review keeps OpenAI's built-in policy (TRAP 6)"
  fi
  exit "$FAILS"
fi
# HTH Guide Excerpt: end verify-global-orchestrator-requirements

echo "usage: $0 emit | verify FILE" >&2
exit 2
