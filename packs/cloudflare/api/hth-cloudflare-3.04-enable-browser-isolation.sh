#!/usr/bin/env bash
# HTH Cloudflare Control 3.4: Enable Browser Isolation
# Profile: L3 | NIST: SI-3 | CIS: 10.5
# https://howtoharden.com/guides/cloudflare/#34-enable-browser-isolation-l3
#
# Requires the Browser Isolation add-on. Looks for an enabled HTTP Isolate
# rule; creates one only with HTH_APPLY=1. The rule isolates the "Security
# Risks" content category (32: New Domains 169, Newly Seen Domains 177, Parked
# & For Sale Domains 128) -- the expression Cloudflare documents for isolating
# high-risk content -- and uses the v2 isolation controls, which only apply
# when "version" is "v2".
# An existing isolate rule satisfies the control only when it also carries the
# guide's Step 2 settings (biso_admin_controls, Gateway rules API):
#   v2: copy remote_only|disabled; paste and download remote_only|disabled;
#       upload and printing disabled (an absent v2 field means enabled)
#   v1 (or no version): dcp, dd, du and dp all true
# If isolate rules exist but none carries them, the pack reports it and does
# not write: it never edits an existing rule.
source "$(dirname "$0")/common.sh"

banner "3.4: Enable Browser Isolation"
should_apply 3 || { increment_skipped; summary; exit 0; }
info "3.4 Checking Browser Isolation policies..."

# HTH Guide Excerpt: begin api-create-isolation-policy
# Create Gateway HTTP policy with isolate action for risky sites
EXISTING=$(cf_get "/accounts/${CF_ACCOUNT_ID}/gateway/rules") || {
  fail "3.4 Unable to retrieve Gateway rules"
  increment_failed
  summary
  exit 0
}

HARDENED_JQ='def one_of($vals): . as $v | $vals | index($v) != null;
def hardened:
  (.rule_settings.biso_admin_controls // {}) as $c
  | if $c.version == "v2" then
      (($c.copy // "enabled") | one_of(["remote_only", "disabled"]))
      and (($c.paste // "enabled") | one_of(["remote_only", "disabled"]))
      and (($c.download // "enabled") | one_of(["remote_only", "disabled"]))
      and ($c.upload == "disabled") and ($c.printing == "disabled")
    else
      ($c.dcp == true and $c.dd == true and $c.du == true and $c.dp == true)
    end;'
ISOLATE_RULES=$(echo "${EXISTING}" | jq '[.result[] | select(.action == "isolate" and .enabled == true)] | length')
HARDENED_RULES=$(echo "${EXISTING}" | jq "${HARDENED_JQ}"'
  [.result[] | select(.action == "isolate" and .enabled == true) | select(hardened)] | length')

if [ "${ISOLATE_RULES}" -gt 0 ] && [ "${HARDENED_RULES}" -gt 0 ]; then
  pass "3.4 ${ISOLATE_RULES} enabled browser isolation rule(s); ${HARDENED_RULES} block paste, downloads, uploads and printing"
  increment_applied
  summary
  exit 0
fi
if [ "${ISOLATE_RULES}" -gt 0 ]; then
  echo "${EXISTING}" | jq -r '.result[] | select(.action == "isolate" and .enabled == true) | "  - \(.name)"'
  fail "3.4 ${ISOLATE_RULES} enabled isolation rule(s), but none disables paste, downloads, uploads and printing (Step 2) -- set them in the rule's isolation settings"
  increment_failed
  summary
  exit 0
fi

may_write "create the HTTP rule 'HTH: Isolate High-Risk Content'" || {
  fail "3.4 No enabled browser isolation rule"
  increment_failed
  summary
  exit 0
}

info "3.4 Creating browser isolation policy for high-risk content..."
RESPONSE=$(cf_post "/accounts/${CF_ACCOUNT_ID}/gateway/rules" '{
  "name": "HTH: Isolate High-Risk Content",
  "action": "isolate",
  "filters": ["http"],
  "traffic": "any(http.request.uri.content_category[*] in {32 169 177 128})",
  "enabled": true,
  "precedence": 5,
  "rule_settings": {
    "biso_admin_controls": {
      "version": "v2",
      "copy": "remote_only",
      "paste": "disabled",
      "download": "disabled",
      "upload": "disabled",
      "printing": "disabled",
      "keyboard": "enabled"
    }
  }
}') || {
  fail "3.4 Failed to create browser isolation rule"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-create-isolation-policy

SUCCESS=$(echo "${RESPONSE}" | jq -r '.success')
if [ "${SUCCESS}" = "true" ]; then
  pass "3.4 Browser isolation policy created"
  increment_applied
else
  fail "3.4 Isolation rule creation failed (requires Browser Isolation license)"
  echo "${RESPONSE}" | jq '.errors'
  increment_failed
fi

summary
