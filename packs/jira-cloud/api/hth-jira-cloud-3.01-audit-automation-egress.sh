#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: jira-cloud-3.1
#   guide:   https://howtoharden.com/guides/jira-cloud/#31-restrict-automation-rule-scope-and-outgoing-web-requests
#   profile: L2
#   mode:    read-only
#   requires: JIRA_EMAIL, JIRA_API_TOKEN(Atlassian API token of an Administer Jira user), JIRA_CLOUD_ID, HTH_EGRESS_COMPONENT_TYPES(needed for a verdict), HTH_APPROVED_RULE_UUIDS(optional)
# =============================================================================
# HTH Jira Cloud Control 3.1: Restrict Automation Rule Scope and Outgoing Web Requests
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 3.3, 4.8, 8.2 | NIST 800-53 AC-4, AU-2, SC-7, SI-4 | ISO 27001:2022 A.8.12, A.8.15, A.8.16
# Source: https://howtoharden.com/guides/jira-cloud/#31-restrict-automation-rule-scope-and-outgoing-web-requests
# Dependencies: bash (3.2+), curl, jq
#
# READ-ONLY. Two documented APIs, GET only:
#   Jira Cloud REST API v3 (swagger-v3.v3.json):
#     GET /rest/api/3/mypermissions?permissions=ADMINISTER
#   Automation REST API (https://developer.atlassian.com/cloud/automation/rest/api-group-rule-management/),
#   base https://api.atlassian.com/automation/public/{product}/{cloudid}/rest/v1
#   ({product} is jira or confluence; find {cloudid} at https://<site>.atlassian.net/_edge/tenant_info):
#     GET /rule/summary?limit=100          (cursor pages via links.next)
#     GET /rule/{ruleUuid}?redactSensitiveFields=true
# redactSensitiveFields=true asks the API to redact sensitive fields "such as
# the hidden header values in the send web request action", so a credential
# stored in a rule never reaches this script. The same API can disable a rule
# (PUT /rule/{ruleUuid}/state) or narrow its scope (PUT /rule/{ruleUuid}/rule-scope);
# this pack only reports. Automation's Global configuration switches have no API.
#
# CREDENTIALS. The Automation API takes HTTP basic <email>:<API token>
# ("api.atlassian.com will only accept API tokens"; "Forge and OAuth2 apps
# cannot access this REST resource"). Atlassian does not say whether a token
# *with scopes* is accepted here. If it is refused with 401/403, use a token
# without scopes that belongs to a Jira admin, with the shortest expiry offered.
# The pack first confirms through the Jira REST API that the token's owner holds
# *Administer Jira*, so a non-admin's partial rule list is never reported as
# the whole site.
#
# WHY YOU SUPPLY THE EGRESS COMPONENT TYPES. Each rule component carries a
# `type` identifier, and the API reference does not publish them: "To get a
# component's type, export a rule containing the component." This pack will not
# guess them. Its first run prints every action type in use; open one rule per
# type in the console, note which types send data out (Send web request, Send
# customized email, Slack, Microsoft Teams, Twilio, Amazon SNS), and set
#   HTH_EGRESS_COMPONENT_TYPES="<type>,<type>,..."
# Every type you list must be used by at least one rule on the site. A type that
# matches no rule is usually a misspelling, so it prints a WARN and blocks a
# COMPLIANT result (exit 2); findings are still reported (exit 1).
# Rules you have reviewed and kept (guide Step 3) go in HTH_APPROVED_RULE_UUIDS.
#
# Exit codes: 0 no unreviewed egress rule | 1 finding |
#             2 precondition, failed call, egress types not yet supplied,
#               or a listed egress type that matches no rule.
# A failed call is never reported as a clean result.
# =============================================================================

set -euo pipefail

need() { [ -n "${!1:-}" ] || { echo "PRECONDITION: set $1 - $2" >&2; exit 2; }; }
need JIRA_EMAIL "the Atlassian account email that owns JIRA_API_TOKEN"
need JIRA_API_TOKEN "an Atlassian API token (see CREDENTIALS above)"
need JIRA_CLOUD_ID "the site's cloud ID (https://<site>.atlassian.net/_edge/tenant_info)"
AUTOMATION_PRODUCT="${AUTOMATION_PRODUCT:-jira}"
case "${AUTOMATION_PRODUCT}" in
  jira|confluence) ;;
  *) echo "PRECONDITION: AUTOMATION_PRODUCT must be jira or confluence (documented values)" >&2; exit 2 ;;
esac
JIRA_API_BASE="${JIRA_API_BASE:-https://api.atlassian.com/ex/jira/${JIRA_CLOUD_ID}}"
JIRA_API_BASE="${JIRA_API_BASE%/}"
AUTOMATION_API_BASE="https://api.atlassian.com/automation/public/${AUTOMATION_PRODUCT}/${JIRA_CLOUD_ID}/rest/v1"
case "${JIRA_API_BASE}" in
  https://*) ;;
  *) echo "PRECONDITION: JIRA_API_BASE must be an https:// URL; basic auth is never sent over plain HTTP" >&2; exit 2 ;;
esac
case "${JIRA_CLOUD_ID}" in
  *[!0-9A-Za-z-]*) echo "PRECONDITION: JIRA_CLOUD_ID must be the site's cloud ID (letters, digits, hyphens)" >&2; exit 2 ;;
esac
case "${JIRA_EMAIL}${JIRA_API_TOKEN}" in
  *\"*|*\\*) echo "PRECONDITION: JIRA_EMAIL or JIRA_API_TOKEN contains a quote or backslash" >&2; exit 2 ;;
esac
EGRESS_TYPES="${HTH_EGRESS_COMPONENT_TYPES:-}"
APPROVED="${HTH_APPROVED_RULE_UUIDS:-}"
case "${EGRESS_TYPES}" in
  *[!0-9A-Za-z._:,-]*) echo "PRECONDITION: HTH_EGRESS_COMPONENT_TYPES may hold only component type identifiers, comma-separated" >&2; exit 2 ;;
esac
case "${APPROVED}" in
  *[!0-9A-Fa-f,-]*) echo "PRECONDITION: HTH_APPROVED_RULE_UUIDS must be comma-separated rule UUIDs" >&2; exit 2 ;;
esac

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/hth-jira-cloud-301.XXXXXX")" \
  || { echo "PRECONDITION: cannot create a temp directory under ${TMPDIR:-/tmp}" >&2; exit 2; }
trap 'rm -rf "${WORK}"' EXIT
BODY="${WORK}/body.json"

# One GET against base $1. Anything other than a 2xx JSON body stops the run
# with exit 2, so a failed call can never be mistaken for an empty result.
http_get() {
  local base="$1" path="$2" code rc
  set +e
  code=$(curl -sS --max-time 60 -o "${BODY}" -w '%{http_code}' \
    -K <(printf 'user = "%s:%s"\n' "${JIRA_EMAIL}" "${JIRA_API_TOKEN}") \
    -H 'Accept: application/json' \
    "${base}${path}")
  rc=$?
  set -e
  if [ "${rc}" -ne 0 ]; then
    echo "PRECONDITION: GET ${path} - no HTTP response (curl exit ${rc})" >&2; exit 2
  fi
  case "${code}" in
    2??) ;;
    401|403) echo "PRECONDITION: GET ${path} returned HTTP ${code} - token invalid, expired, missing a scope, or (Automation API) a scoped token it does not accept" >&2; exit 2 ;;
    *) echo "PRECONDITION: GET ${path} returned HTTP ${code}: $(jq -r '[(.errorMessages // [])[], ((.errors // []) | if type == "array" then .[].title else empty end)] | join("; ")' "${BODY}" 2>/dev/null || true)" >&2
       exit 2 ;;
  esac
  jq -e 'type == "object" or type == "array"' "${BODY}" >/dev/null 2>&1 \
    || { echo "PRECONDITION: GET ${path} returned a body that is not JSON" >&2; exit 2; }
}

require_admin() {
  http_get "${JIRA_API_BASE}" "/rest/api/3/mypermissions?permissions=ADMINISTER"
  if [ "$(jq -r '.permissions.ADMINISTER.havePermission // false' "${BODY}")" != "true" ]; then
    echo "PRECONDITION: the token's owner does not hold the Administer Jira global permission," >&2
    echo "  so the rule list could be partial. Use a Jira admin's token." >&2
    exit 2
  fi
}

# Every rule summary, following links.next ("?cursor=...&limit=100") to the end.
list_rules() {
  local next="?limit=100" pages=0
  : > "${WORK}/summaries.jsonl"
  while [ -n "${next}" ]; do
    http_get "${AUTOMATION_API_BASE}" "/rule/summary${next}"
    jq -e 'has("data") and (.data | type == "array")' "${BODY}" >/dev/null 2>&1 \
      || { echo "PRECONDITION: GET /rule/summary did not return a .data array" >&2; exit 2; }
    jq -c '.data[]' "${BODY}" >> "${WORK}/summaries.jsonl"
    next=$(jq -r '.links.next // ""' "${BODY}")
    case "${next}" in
      '') ;;
      '?'*) ;;
      https://*\?*) next="?${next#*\?}" ;;   # links were absolute URLs before August 2025
      *) echo "PRECONDITION: unexpected links.next format from /rule/summary" >&2; exit 2 ;;
    esac
    pages=$((pages + 1))
    [ "${pages}" -lt 500 ] || { echo "PRECONDITION: /rule/summary still paging after 500 pages" >&2; exit 2; }
  done
  jq -s '.' "${WORK}/summaries.jsonl" > "${WORK}/summaries.json"
}

# One compact line per rule: state, trigger, actor, scope count, and the set of
# ACTION component types found anywhere in its component tree.
describe_rules() {
  local uuid expected
  expected=$(jq 'length' "${WORK}/summaries.json")
  : > "${WORK}/rules.jsonl"
  while read -r uuid; do
    case "${uuid}" in ''|*[!0-9A-Fa-f-]*) echo "PRECONDITION: /rule/summary returned a malformed rule uuid" >&2; exit 2 ;; esac
    http_get "${AUTOMATION_API_BASE}" "/rule/${uuid}?redactSensitiveFields=true"
    jq -e '.rule | type == "object"' "${BODY}" >/dev/null 2>&1 \
      || { echo "PRECONDITION: GET /rule/${uuid} returned no rule payload" >&2; exit 2; }
    jq -c --arg u "${uuid}" '
      .rule as $r
      | { uuid: $u,
          name: ($r.name // "(unnamed)"),
          state: ($r.state // "UNKNOWN"),
          trigger: ($r.trigger.type // "unknown"),
          actor: ($r.actor.type // "unknown"),
          author: (($r.authorAccountId // "") | .[-6:]),
          scopes: (($r.ruleScopeARIs // []) | length),
          actions: ([ $r.components[]? | recurse(.children[]?, .conditions[]?)
                      | select(.component == "ACTION") | .type ] | unique),
          connections: ([ .connections[]? | "\(.authType // "?")/\(.connectionTargetKey // "?")" ] | unique) }' \
      "${BODY}" >> "${WORK}/rules.jsonl"
  done < <(jq -r '.[].uuid' "${WORK}/summaries.json")
  jq -s '.' "${WORK}/rules.jsonl" > "${WORK}/rules.json"
  if [ "$(jq 'length' "${WORK}/rules.json")" -ne "${expected}" ]; then
    echo "PRECONDITION: described $(jq 'length' "${WORK}/rules.json") of ${expected} rules" >&2; exit 2
  fi
}

# HTH Guide Excerpt: begin automation-egress-audit
# Guide Step 1: inventory every rule, and every ENABLED rule that contains an
# action which sends data out of Jira. Guide Step 3: rules you reviewed and kept
# are listed in HTH_APPROVED_RULE_UUIDS and reported as approved, not as findings.
audit() {
  require_admin
  list_rules
  describe_rules

  echo "Jira Cloud 3.1 - automation rule inventory and egress audit"
  echo "  rules: $(jq 'length' "${WORK}/rules.json") (enabled $(jq '[.[] | select(.state == "ENABLED")] | length' "${WORK}/rules.json"))"
  if [ "$(jq 'length' "${WORK}/rules.json")" -eq 0 ]; then
    echo "COMPLIANT: the site has no automation rules."
    return 0
  fi
  echo "  action component types in ENABLED rules (type: rules):"
  jq -r '[.[] | select(.state == "ENABLED") | .actions[]] | group_by(.) | .[] | "    \(.[0]): \(length)"' "${WORK}/rules.json"
  echo "  connections in ENABLED rules (authType/target: rules):"
  jq -r '[.[] | select(.state == "ENABLED") | .connections[]] | group_by(.) | .[] | "    \(.[0]): \(length)"' "${WORK}/rules.json"

  if [ -z "${EGRESS_TYPES}" ]; then
    echo "PRECONDITION: set HTH_EGRESS_COMPONENT_TYPES to the egress action types above (see header)." >&2
    echo "  Atlassian does not publish component type identifiers, so this pack will not guess which ones send data out." >&2
    exit 2
  fi
  if [ "$(jq -rn --arg egress "${EGRESS_TYPES}" '$egress | split(",") | map(select(length > 0)) | length')" -eq 0 ]; then
    echo "PRECONDITION: HTH_EGRESS_COMPONENT_TYPES names no component type (only separators)." >&2
    exit 2
  fi

  # A listed type that no rule on the site uses (enabled or disabled) is usually a
  # misspelling. It matches nothing, so it would hide the very rules it was meant to catch.
  local unmatched
  unmatched=$(jq -r --arg egress "${EGRESS_TYPES}" '
    ($egress | split(",") | map(select(length > 0)) | unique) as $out
    | ([ .[].actions[] ] | unique) as $seen
    | [ $out[] | select(. as $t | $seen | index($t) == null) ] | join(", ")' "${WORK}/rules.json")

  jq --arg egress "${EGRESS_TYPES}" --arg approved "${APPROVED}" '
    ($egress | split(",") | map(select(length > 0))) as $out
    | ($approved | ascii_downcase | split(",") | map(select(length > 0))) as $ok
    | [ .[] | select(.state == "ENABLED")
        | . as $rule
        | ([.actions[] | select(. as $a | $out | index($a) != null)]) as $hits
        | select($hits | length > 0)
        | "\(if ($ok | index($rule.uuid | ascii_downcase)) != null then "APPROVED" else "FINDING" end): \"\(.name)\" (\(.uuid)) sends data out via \($hits | join(", ")) - trigger \(.trigger), actor \(.actor), scopes \(.scopes), author ...\(.author)" ]' \
    "${WORK}/rules.json" > "${WORK}/lines.json"

  jq -r '.[]' "${WORK}/lines.json"
  if [ -n "${unmatched}" ]; then
    echo "WARN: HTH_EGRESS_COMPONENT_TYPES lists ${unmatched}, which matches no action type used by any rule on this site." >&2
    echo "  Types in use: $(jq -r '[ .[].actions[] ] | unique | join(", ")' "${WORK}/rules.json")" >&2
  fi
  local n
  n=$(jq '[.[] | select(startswith("FINDING"))] | length' "${WORK}/lines.json")
  if [ "${n}" -gt 0 ]; then
    echo "${n} enabled rule(s) send data out and are not on the reviewed list. Record destination, owner and justification, or disable them (guide Steps 1 and 3)."
    return 1
  fi
  if [ -n "${unmatched}" ]; then
    echo "PRECONDITION: no clean verdict while a listed egress type matches no rule. Correct its spelling from the types in use, or remove it if this site has no rule that uses it." >&2
    exit 2
  fi
  echo "COMPLIANT: every enabled rule with an egress action is on the reviewed list."
}
# HTH Guide Excerpt: end automation-egress-audit

audit
