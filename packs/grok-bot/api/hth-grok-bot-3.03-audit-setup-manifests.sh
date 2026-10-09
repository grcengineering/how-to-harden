#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-bot-3.3
#   guide:   https://howtoharden.com/guides/grok-bot/#33-govern-team-setup-scripts-and-keep-credentials-in-team-secrets
#   profile: L2
#   mode:    mutating
#   requires: CURSOR_ADMIN_API_KEY(Team API key; read:* to verify, admin:* to enforce; Enterprise), HTH_MANIFEST_FILE(optional for verify, required for enforce), HTH_REVIEWED_MANIFEST_IDS(optional, comma-separated), curl, jq
# =============================================================================
# HTH Grok Bot Control 3.3: Govern Team Setup Scripts and Keep Credentials in Team Secrets
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls v8 2.7, 4.1, 10.1; NIST 800-53 CM-3, CM-5, SI-4, IA-5(7);
#             SOC 2 CC8.1, CC6.1; ISO 27001:2022 A.8.9, A.8.32, A.5.17
# Sources (transcribed from, fetched 2026-10-08):
#   https://cursor.com/docs/account/teams/admin-api#list-grok-bot-setup-manifests
#   https://cursor.com/docs/account/teams/admin-api#upsert-grok-bot-setup-manifest
#   https://docs.x.ai/grok-bot/teams-and-enterprises (Team Secrets)
#   https://docs.x.ai/grok-bot/private-networks (manifest JSON view; the
#     `tailscale up --auth-key "$TS_AUTHKEY"` pattern; re-checked 2026-10-09)
#   https://tailscale.com/kb/1085/auth-keys (tskey- key prefix)
#   https://developers.cloudflare.com/cloudflare-one/access-controls/service-credentials/service-tokens/
#     (cfast_ Client Secret prefix, from August 26, 2026)
# Dependencies: curl, jq, ./common.sh
#
# Usage: bash hth-grok-bot-3.03-audit-setup-manifests.sh [verify | enforce [--apply]]
#   verify            list every TEAM manifest, flag credential-shaped literals,
#                     flag manifests outside HTH_REVIEWED_MANIFEST_IDS, and diff
#                     the manifest in HTH_MANIFEST_FILE against its live copy
#   enforce --apply   PUT /grok-bot/setup-manifests/:manifestId with the
#                     reviewed file, only when that manifest is missing or
#                     differs from the live copy, refusing a file that itself
#                     carries a credential-shaped literal. The dry run prints
#                     script ids and lengths, never script text.
#   HTH_MANIFEST_FILE is the Admin API shape:
#     {"id": "toolchain", "scripts": [{"id": "node", "setup": "...", "check": "..."}]}
#
# ── TRAP 1: two documented JSON shapes for one manifest ─────────────────────
# The Admin API body is {"scripts": [{id, setup, check}]} with manifestId in the
# path, and the list returns {"id", "scripts"}. The dashboard's JSON editor
# documents {"manifestId": ..., "entries": [{id, setup, check}]}. This pack uses
# the Admin API shape only, and refuses a file that has `entries` instead of
# guessing that the two are interchangeable.
#
# ── TRAP 2: half the control is dashboard-only ──────────────────────────────
# Team Secrets: "They are not available through the Admin API" and "are managed
# from the dashboard only". Group Setup Scripts have no route either. Neither
# can be read or set here; review both in the dashboard. No audit event is
# documented for Team Secrets changes.
#
# ── TRAP 3: the credential scan is a heuristic ──────────────────────────────
# The vendor's rule is "Do not paste secret values into scripts"; secrets belong
# in Team Secrets and are referenced by name ("$MY_LICENSE_KEY"). The patterns
# below catch common literal shapes (AWS access key ids, PEM private keys,
# GitHub and Slack tokens, Tailscale tskey- auth keys, Cloudflare Access cfast_
# client secrets, credentials in URLs, key=value assignments, literal
# Authorization headers, and secret flags passed as a separate argument, such as
# `tailscale up --auth-key tskey-…` or `cloudflared access tcp
# --service-token-secret <value>`, the exact failure the private-networks page
# warns about). A flag whose value is an environment reference
# (--auth-key "$TS_AUTHKEY") passes. A clean scan is not proof of absence.
# Matches are reported by pattern name only, and no dry run prints script text,
# so a literal the scan MISSED still never reaches a log.
#
# ── TRAP 4: writes can race ─────────────────────────────────────────────────
# The upsert "Returns 409 when the manifest changed during the request"; a team
# stores at most 100 manifests; ids are 1-128 characters "starting with a letter
# or number, then letters, numbers, ., _, or -". Script text is never logged in
# audit events (grok_bot_team_setup_manifest records ids, revision and counts).
#
# Exit codes: 0 no finding in the team manifests (the RESULT line names Team
# Secrets and group Setup Scripts as not proven, TRAP 2) | 1 finding, dry run
# with changes, or a write refused after a finding | 2 precondition
# =============================================================================

set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# TRAP 3: pattern names -> regexes (jq/Oniguruma); applied to setup and check text.
CRED_SCAN='
  def cred_hits:
    . as $s
    | [ {k: "aws-access-key-id",   re: "AKIA[0-9A-Z]{16}",                       f: ""},
        {k: "pem-private-key",     re: "-----BEGIN [A-Z ]*PRIVATE KEY-----",     f: ""},
        {k: "github-token",        re: "gh[pousr]_[A-Za-z0-9]{36,}",             f: ""},
        {k: "github-fine-grained", re: "github_pat_[A-Za-z0-9_]{20,}",           f: ""},
        {k: "slack-token",         re: "xox[abprs]-[A-Za-z0-9-]{10,}",           f: ""},
        {k: "tailscale-auth-key",  re: "tskey-[A-Za-z0-9-]{10,}",                f: ""},
        {k: "cloudflare-access-secret", re: "cfast_[A-Za-z0-9]{40,}",            f: ""},
        {k: "url-credentials",     re: "://[^/\\s:@$]+:[^/\\s@$]+@",             f: ""},
        {k: "literal-flag",        re: "--?(auth-?key|api-?key|token|secret|password|passwd|service-token-secret)[\"'"'"']?\\s+[\"'"'"']?[^\\s\"'"'"'$]{12,}", f: "i"},
        {k: "literal-assignment",  re: "(password|passwd|secret|token|api[_-]?key|auth[_-]?key)[\"'"'"']?\\s*[=:]\\s*[\"'"'"']?[A-Za-z0-9/+_.~-]{12,}", f: "i"},
        {k: "literal-auth-header", re: "authorization:\\s*(bearer|basic)\\s+[A-Za-z0-9._~+/=-]{12,}", f: "i"} ]
    | map(select(.re as $re | .f as $f | $s | test($re; $f))) | map(.k);
'

LIVE_MANIFESTS=""   # JSON array, filled by verify

list_manifests() { # all pages of GET /grok-bot/setup-manifests -> JSON array
  local out cursor="" next q pages=0
  out="$(gb_tmp manifests)"
  while :; do
    # A team stores at most 100 manifests, so a handful of pages at limit=100 (TRAP G).
    pages=$((pages + 1))
    if [ "${pages}" -gt 10 ]; then
      echo "PRECONDITION: more than 10 pages of setup manifests (a team stores at most 100)" >&2
      exit 2
    fi
    q="limit=100"
    if [ -n "${cursor}" ]; then q="${q}&cursor=$(jq -rn --arg c "${cursor}" '$c|@uri')"; fi
    gb_get team "/grok-bot/setup-manifests?${q}"
    gb_require "GET /grok-bot/setup-manifests" 200
    gb_shape '(.manifests | type == "array")
              and all(.manifests[]; (.id | type == "string") and (.scripts | type == "array"))' "GET /grok-bot/setup-manifests"
    jq -c '.manifests[]' "${GB_BODY_FILE}" >> "${out}"
    next=$(jq -r '.nextCursor // ""' "${GB_BODY_FILE}")
    if [ -z "${next}" ]; then break; fi
    if [ "${next}" = "${cursor}" ]; then
      echo "PRECONDITION: GET /grok-bot/setup-manifests returned the same nextCursor twice" >&2
      exit 2
    fi
    cursor="${next}"
  done
  jq -s -c '.' "${out}"
}

# Normalized scripts of one manifest, for comparing a live copy with the file.
manifest_scripts() { jq -S -c '.scripts | map(with_entries(select(.value != null)))'; }

reviewed_manifest() { # HTH_MANIFEST_FILE, validated against the documented shape
  local f="${HTH_MANIFEST_FILE:-}"
  if [ ! -r "${f}" ]; then echo "PRECONDITION: HTH_MANIFEST_FILE is not a readable file" >&2; exit 2; fi
  if jq -e 'has("entries") or has("manifestId")' "${f}" >/dev/null 2>&1; then
    echo "PRECONDITION: ${f} uses the dashboard JSON shape (manifestId/entries); write it as {\"id\", \"scripts\"} (TRAP 1)" >&2
    exit 2
  fi
  if ! jq -e '
      def okid: type == "string" and test("^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$");
      (.id | okid) and (.scripts | type == "array" and length > 0)
      and all(.scripts[]; (.id | okid) and (.setup | type == "string" and length > 0)
                          and ((has("check") | not) or (.check | type == "string")))' "${f}" >/dev/null 2>&1; then
    echo "PRECONDITION: ${f} is not {\"id\": <1-128 chars>, \"scripts\": [{\"id\", \"setup\" (non-empty), \"check\"?}]}" >&2
    exit 2
  fi
  jq -c '{id, scripts: [.scripts[] | {id, setup} + (if has("check") then {check} else {} end)]}' "${f}"
}

# HTH Guide Excerpt: begin verify-setup-manifests
verify() {
  local manifests hits unreviewed want live
  manifests=$(list_manifests)
  LIVE_MANIFESTS="${manifests}"
  echo "Grok Bot 3.3 — team setup manifests: $(jq 'length' <<<"${manifests}")"
  jq -r '.[] | "    - \(.id): \([.scripts[].id] | join(", "))"' <<<"${manifests}"

  # Credential-shaped literals in setup or check text (TRAP 3). Names only.
  hits=$(jq -r "${CRED_SCAN}"'
    .[] | .id as $m | .scripts[]
    | .id as $s | ([(.setup // ""), (.check // "")] | map(cred_hits) | add | unique) as $h
    | select($h | length > 0)
    | "    \($m)/\($s): \($h | join(", "))"' <<<"${manifests}")
  if [ -n "${hits}" ]; then
    echo "${hits}"
    gb_finding "credential-shaped literals in team setup scripts — move them to Team Secrets and reference them by name"
  fi

  if [ -n "${HTH_REVIEWED_MANIFEST_IDS:-}" ]; then
    unreviewed=$(jq -r --arg ok "${HTH_REVIEWED_MANIFEST_IDS}" \
      '($ok | split(",") | map(gsub("^\\s+|\\s+$"; ""))) as $r | .[] | select(.id as $i | $r | index($i) | not) | .id' <<<"${manifests}")
    if [ -n "${unreviewed}" ]; then
      gb_finding "manifests outside HTH_REVIEWED_MANIFEST_IDS: $(echo "${unreviewed}" | tr '\n' ' ')"
    fi
  fi

  if [ -n "${HTH_MANIFEST_FILE:-}" ]; then
    want=$(reviewed_manifest)
    live=$(jq -c --arg id "$(jq -r '.id' <<<"${want}")" '[.[] | select(.id == $id)] | first // null' <<<"${manifests}")
    if [ "${live}" = "null" ]; then
      gb_finding "reviewed manifest '$(jq -r '.id' <<<"${want}")' is not deployed"
    elif [ "$(manifest_scripts <<<"${live}")" != "$(manifest_scripts <<<"${want}")" ]; then
      gb_finding "live manifest '$(jq -r '.id' <<<"${want}")' differs from ${HTH_MANIFEST_FILE}"
    fi
  fi
  echo "  NOT VERIFIABLE BY API: Team Secrets and group Setup Scripts (dashboard only, TRAP 2)"
  GB_UNPROVEN="Team Secrets and group Setup Scripts (dashboard only, TRAP 2)"
}
# HTH Guide Excerpt: end verify-setup-manifests

# HTH Guide Excerpt: begin enforce-setup-manifest
enforce() {
  local want id body hits live
  want=$(reviewed_manifest)
  id=$(jq -r '.id' <<<"${want}")
  # Never upload a literal secret: that is the failure this control exists to stop.
  hits=$(jq -r "${CRED_SCAN}"'.scripts[] | .id as $s
    | ([(.setup // ""), (.check // "")] | map(cred_hits) | add | unique) as $h
    | select($h | length > 0) | "    \($s): \($h | join(", "))"' <<<"${want}")
  if [ -n "${hits}" ]; then
    echo "${hits}" >&2
    echo "PRECONDITION: ${HTH_MANIFEST_FILE} carries credential-shaped literals — refusing to upload it" >&2
    exit 2
  fi
  # Upload only when the reviewed manifest is missing or differs: a no-op save
  # bumps the revision, fires the 3.3 Sigma rule and cannot clear any other finding.
  live=$(jq -c --arg id "${id}" '[.[] | select(.id == $id)] | first // null' <<<"${LIVE_MANIFESTS}")
  if [ "${live}" != "null" ] && [ "$(manifest_scripts <<<"${live}")" = "$(manifest_scripts <<<"${want}")" ]; then
    echo "  reviewed manifest '${id}' already matches the live copy — nothing to upload."
    echo "  The remaining finding(s) need manual remediation: fix the flagged manifests, or remove manifests outside HTH_REVIEWED_MANIFEST_IDS, in the dashboard or in their own reviewed files."
    return 0
  fi
  body=$(jq -c '{scripts}' <<<"${want}")
  if [ "${GB_APPLY}" -ne 1 ]; then
    # Script text is never printed, so a literal the scan missed stays out of CI logs (TRAP 3).
    gb_plan PUT "/grok-bot/setup-manifests/${id}"
    jq -r '.scripts[] | "    \(.id): setup \(.setup | length) chars, check \((.check // "") | length) chars"' <<<"${want}"
    return 0
  fi
  gb_put team "/grok-bot/setup-manifests/${id}" "${body}"
  gb_require_2xx "PUT /grok-bot/setup-manifests/${id}"
  echo "  PUT /grok-bot/setup-manifests/${id} -> scripts=$(jq -c '[.manifest.scripts[]?.id]' "${GB_BODY_FILE}")"
  echo "  Running computers pick up manifest changes on a periodic refresh, roughly daily;"
  echo "  recreate a computer (or have the member reset it) to apply the change immediately."
}
# HTH Guide Excerpt: end enforce-setup-manifest

gb_parse_mode "$@"
gb_main verify enforce
