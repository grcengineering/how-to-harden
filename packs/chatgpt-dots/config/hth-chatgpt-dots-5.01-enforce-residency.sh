#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-dots-5.1
#   guide:   https://howtoharden.com/guides/chatgpt-dots/#51-keep-dots-out-of-workspaces-and-populations-that-require-residency-ekm-or-zero-retention
#   profile: L3
#   mode:    read-only
#   requires: awk, grep; emit: HTH_CONFIRM_US_CODEX_RESIDENCY=yes; verify: saved copies of the requirements TOML of every Agent Security cloud policy
# =============================================================================
# HTH ChatGPT Dots Control 5.1: Keep dots out of workspaces and populations that
#   require residency, EKM, or zero retention
# Profile Level: L3 (Run)
# Frameworks: CIS Controls v8 3.1, 3.7; NIST 800-53 SA-9(5), SI-12, AC-3;
#   SOC 2 C1.1, P4.1; GDPR Art. 44; no benchmark equivalent yet
# Dependencies: awk, grep
#
# Sources (every key and quoted sentence below comes from these pages, fetched
# 2026-10-08 unless marked):
#   https://learn.chatgpt.com/docs/config-file/config-reference  (enforce_residency)
#   https://learn.chatgpt.com/docs/enterprise/agent-security
#   https://learn.chatgpt.com/docs/enterprise/cloud-local-access
#   https://learn.chatgpt.com/docs/enterprise/dots-admin-guide
#   https://help.openai.com/en/articles/20001554-manage-dots-in-chatgpt-workspaces
#     (403 to curl; from the research ledger's real-browser read — TRAP 4)
#
# WHAT THIS PACK COVERS. The control itself is a role boundary: no role a
# regulated user holds may grant "Use dots (Beta)". No API writes that permission,
# so it stays ClickOps (verify membership with the 1.01 group-membership pack).
# This pack handles the separate, optional lever beside it: enforce_residency in
# an Agent Security cloud policy, which blocks dots' local computer access.
#
# WHY `mode: read-only`. Nothing in this file writes to OpenAI or to disk. `emit`
# prints one TOML line for Admin Console > Agent Security > (a cloud policy) >
# Requirements; the policy API the docs mention has no published contract.
# `verify` lints copies of your cloud policies' TOML that you saved yourself.
#
# ── TRAP 1: it does not keep dots out of anything ────────────────────────────
# "This safeguard does not set workspace residency or, by itself, disable Work
# Cloud or dots. Eligible workspaces can still opt in to dots after acknowledging
# the beta residency limitations; local access remains blocked." "During the
# Enterprise beta, dots do not support data residency or inference residency",
# and "Neither experience provides strict zero data retention." Dots' cloud
# coordination and cloud computers keep processing data without residency.
#
# ── TRAP 2: one policy blocks the whole workspace, and it changes Codex ───────
# "If any cloud policy enables enforce_residency, Allow local computer access is
# unavailable for both Work and dots." It is not scoped to the policy's users.
# The key also does what its name says: "Require Codex service traffic to use a
# supported data residency. Currently accepts `us`." `emit` therefore refuses to
# run until HTH_CONFIRM_US_CODEX_RESIDENCY=yes.
#
# ── TRAP 3: only a cloud policy counts ───────────────────────────────────────
# The trigger is "any cloud policy", managed in Agent Security ("Open Agent
# Security in the Admin Console to review and manage cloud requirements"). The
# docs name only cloud policies as the trigger; a device's own requirements.toml
# is not documented to have this effect, so feeding `verify` a device file
# proves nothing.
#
# ── TRAP 4: the documented blocker conflicts ─────────────────────────────────
# learn.chatgpt.com names enforce_residency as the blocker. Help article 20001554
# instead says "Local computer access is unavailable in workspaces with Codex or
# ChatGPT Work policies that target a specific operating system." Confirm in a
# live tenant that Allow local computer access shows as unavailable after saving.
#
# ── TRAP 5: moot where dots cannot run at all ────────────────────────────────
# "Dots are unavailable for FedRAMP workspaces, workspaces with EKM, and
# workspaces with inference residency set to AE (UAE)." The control matters in
# the other workspaces, where regulated users sit beside dots users.
#
# Usage:  emit               -> print the enforce_residency line
#         verify FILE [...]  -> check saved copies of every cloud policy
# Exit codes: 0 ok (verify: set to "us", or not set) | 1 finding (a value other
#   than "us") | 2 precondition
# =============================================================================

set -euo pipefail

ACTION="${1:-verify}"

# HTH Guide Excerpt: begin emit-enforce-residency
# Print the requirement that blocks Allow local computer access for Work and dots
# workspace-wide. It also requires US residency for Codex service traffic.
if [ "$ACTION" = "emit" ]; then
  if [ "${HTH_CONFIRM_US_CODEX_RESIDENCY:-}" != "yes" ]; then
    echo "PRECONDITION: enforce_residency also requires US residency for Codex service traffic." >&2
    echo "Set HTH_CONFIRM_US_CODEX_RESIDENCY=yes once that is intended for this policy's users." >&2
    exit 2
  fi
  printf 'enforce_residency = "us"\n'
  exit 0
fi
# HTH Guide Excerpt: end emit-enforce-residency

# HTH Guide Excerpt: begin verify-enforce-residency
# Check saved copies of every Agent Security cloud policy's requirements TOML.
# The lever is optional (guide 5.1 Step 3): reports SET when at least one policy
# sets enforce_residency = "us", NOT SET (exit 0) when none does, and fails only
# on a value other than "us".
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
  shift || true
  [ "$#" -gt 0 ] || { echo "PRECONDITION: pass saved copies of every cloud policy's requirements TOML" >&2; exit 2; }
  SET=0; FAILS=0
  for FILE in "$@"; do
    [ -r "$FILE" ] || { echo "PRECONDITION: cannot read $FILE" >&2; exit 2; }
    if v=$(toml_flatten "$FILE" | awk -F'\t' '$1 == "" && $2 == "enforce_residency" { print $3; f = 1 } END { exit !f }'); then
      v=$(printf '%s' "$v" | tr -d "\"'")
      if [ "$v" = "us" ]; then
        echo "  SET:  $FILE -> enforce_residency = \"us\""; SET=1
      else
        echo "  FAIL: $FILE -> enforce_residency = \"$v\" (only \"us\" is accepted)"; FAILS=1
      fi
    else
      echo "  --    $FILE -> enforce_residency not set"
    fi
  done
  [ "$FAILS" = 0 ] || exit 1
  if [ "$SET" = 1 ]; then
    echo "  PASS: Allow local computer access should show as unavailable for Work and dots, workspace-wide"
    echo "        (dots themselves stay available; confirm the role boundary separately; TRAP 4 conflict)"
  else
    echo "  NOT SET: no cloud policy sets enforce_residency (optional lever; keep Allow local computer access"
    echo "        Off through roles instead — control 3.4)"
  fi
  exit 0
fi
# HTH Guide Excerpt: end verify-enforce-residency

echo "usage: $0 emit | verify FILE [FILE...]" >&2
exit 2
