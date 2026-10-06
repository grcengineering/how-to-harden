#!/usr/bin/env bash
# HTH Cloudflare Control 2.5: Gate Access Policies on User Risk Score
# Profile: L3 | NIST: AC-2(12) | CIS: 13.1
# https://howtoharden.com/guides/cloudflare/#25-gate-access-policies-on-user-risk-score
#
# Read-only audit (Enterprise plans) of both halves of the control:
#   Step 1 -- at least one risk behavior is enabled. Every behavior is disabled
#             by default, and a risk score gate enforces nothing until one is.
#   Step 2 -- at least one Access policy acts on a High user risk score: an
#             Allow policy that Excludes High, a Block (deny) policy that
#             Includes High, or an Allow policy whose Require lists risk levels
#             without High (rule shape {"user_risk_score": {"user_risk_score":
#             [...]}}, Access policy rules API).
# Fails when either half is missing, or when the behaviors or any
# application's policies cannot be read. Every page of applications is read.
source "$(dirname "$0")/common.sh"

banner "2.5: Gate Access Policies on User Risk Score"
should_apply 3 || { increment_skipped; summary; exit 0; }
info "2.5 Checking risk behaviors..."

# HTH Guide Excerpt: begin api-audit-risk-behaviors
BEHAVIORS=$(cf_get "/accounts/${CF_ACCOUNT_ID}/zt_risk_scoring/behaviors") || {
  fail "2.5 Unable to read risk behaviors (Enterprise plan required)"
  increment_failed
  summary
  exit 0
}
TOTAL=$(echo "${BEHAVIORS}" | jq '.result.behaviors // {} | length')
ENABLED=$(echo "${BEHAVIORS}" | jq '[.result.behaviors // {} | to_entries[] | select(.value.enabled == true)] | length')
echo "${BEHAVIORS}" | jq -r '.result.behaviors // {} | to_entries[]
  | "  - \(.value.name // .key): \(if .value.enabled then "enabled" else "disabled" end) (\(.value.risk_level))"'

# Access policies that act on a High user risk score
APPS=$(cf_get_all "/accounts/${CF_ACCOUNT_ID}/access/apps") || {
  fail "2.5 Unable to retrieve Access applications"
  increment_failed
  summary
  exit 0
}
RISK_GATE_JQ='
def risk_levels(rules): [rules | .[]? | objects
  | (try .user_risk_score.user_risk_score catch null) // empty | .[]?];
[.result[] | (.decision // "allow") as $d
  | select(
      ($d == "allow" and (risk_levels(.exclude) | index("high")) != null)
      or ($d == "deny" and (risk_levels(.include) | index("high")) != null)
      or ($d == "allow" and (risk_levels(.require) | length) > 0
          and (risk_levels(.require) | index("high")) == null))
] | length'
GATED=0
FETCH_ERR=0
while IFS= read -r app_line; do
  APP_ID=$(echo "${app_line}" | jq -r '.id')
  APP_NAME=$(echo "${app_line}" | jq -r '.name // .id')
  POLICIES=$(cf_get_all "/accounts/${CF_ACCOUNT_ID}/access/apps/${APP_ID}/policies") || {
    fail "2.5 Could not read policies for application '${APP_NAME}'"
    FETCH_ERR=1
    continue
  }
  HITS=$(echo "${POLICIES}" | jq "${RISK_GATE_JQ}") || {
    fail "2.5 Could not parse policies for application '${APP_NAME}'"
    FETCH_ERR=1
    continue
  }
  if [ "${HITS}" -gt 0 ]; then
    info "2.5 Application '${APP_NAME}': ${HITS} policy(s) act on a High user risk score"
    GATED=$((GATED + 1))
  fi
done < <(echo "${APPS}" | jq -c '.result[]')
# HTH Guide Excerpt: end api-audit-risk-behaviors

if [ "${FETCH_ERR}" = "1" ]; then
  fail "2.5 Audit incomplete -- one or more application policy lists could not be read"
  increment_failed
elif [ "${ENABLED}" = "0" ]; then
  fail "2.5 No risk behavior is enabled -- user risk scores cannot change"
  increment_failed
elif [ "${GATED}" = "0" ]; then
  fail "2.5 ${ENABLED} risk behavior(s) enabled, but no Access policy excludes or blocks a High user risk score"
  increment_failed
else
  pass "2.5 ${ENABLED} of ${TOTAL} risk behavior(s) enabled; ${GATED} application(s) gate on user risk score"
  increment_applied
fi

summary
