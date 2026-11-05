#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-1.4
#   guide:   https://howtoharden.com/guides/ona/#14-harden-service-accounts-and-personal-access-tokens
#   profile: L2
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional); HTH_PROFILE_LEVEL >= 2; sibling common.sh
# =============================================================================
# HTH Ona Control 1.4: Harden Service Accounts and Personal Access Tokens
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 5.4, 16.9
# Source: https://howtoharden.com/guides/ona/#14-harden-service-accounts-and-personal-access-tokens
# Dependencies: Bash, curl, jq; sibling common.sh; HTH_PROFILE_LEVEL >= 2
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# `gitpod-io/ona` ships `ona_service_account` plus an EPHEMERAL
# `ona_service_account_token`, so Terraform can mint a bounded service account.
# It has NO personal-access-token resource at all, and ephemeral resources are
# by definition not in state — so Terraform cannot enumerate what already exists.
# This control is a lifetime inventory, not a provisioning step: the question is
# "which credential in this organization never expires", and only the List*
# methods answer it.
#
# ── TRAP 1: this pack never mints or reads a token value ─────────────────────
# `CreateServiceAccountToken` and `CreatePersonalAccessToken` return the secret
# ONCE, and `ServiceAccountService/CreateServiceAccountAccessToken` mints a
# short-lived impersonation token. None of them is called here. The read paths
# return metadata only.
#
# ── TRAP 2: ListServiceAccountTokens REQUIRES IMPERSONATION ──────────────────
# Verbatim from the method page: "Requires impersonation: First obtain a
# short-lived access token via CreateServiceAccountAccessToken, then use it to
# call this method. The service account ID is derived from the caller's
# identity." The request message carries only `pagination` — there is no
# serviceAccountId to pass. A human personal access token therefore cannot
# enumerate another account's tokens. This pack does NOT mint an impersonation
# token to work around that (TRAP 1); it reports the half it can prove and exits
# 2 rather than pretending an unenumerated set is clean.
#
# ── TRAP 3: suspended service accounts are hidden by default ─────────────────
# `Filter.includeSuspended` — "includes suspended (soft-deleted) service accounts
# in the response. By default, suspended service accounts are excluded." A
# suspended account cannot authenticate, but leaving it out of the inventory
# makes the count disagree with the console. This pack asks for them and
# separates the two populations.
#
# ── TRAP 4: readOnly absent means READ-WRITE ─────────────────────────────────
# `PersonalAccessToken.readOnly` verbatim: "When true, the token can only be used
# for read operations. Mutations will be denied at the data layer." Proto3 omits
# false, so a token with no `readOnly` key is a full read-write credential. That
# is the dangerous default and `// false` is the only correct read.
#
# ── TRAP 5: validUntil is Required on create but can still read back absent ──
# `CreateServiceAccountRequest.validUntil` is documented Required: Yes, so the
# contract forbids an indefinite service account. `validFor` on both
# token-create methods is OPTIONAL, so an unbounded TOKEN is still expressible.
# Absence on the read path is not an error — it is "no expiry", the worst value.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (incl. un-enumerable tokens)
# =============================================================================

set +x
set -euo pipefail
# Download the complete api directory; common.sh is required.
# Use same-domain tokens. Custom HTTPS bases also require matching
# ONA_REVIEWED_API_BASE. Stdout is staged until completion; keep it private.
# shellcheck source=packs/ona/api/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
ona_init 2
FINDINGS=0
SA_TOKENS_ENUMERABLE=1
SA_ACTIVE_COUNT=0

# HTH Guide Excerpt: begin service-account-and-pat-lifetime-audit
# Inventory pass. Three populations, one question each: does this credential
# have an end date, and is it broader than it needs to be?
audit_service_accounts() {
  # TRAP 3: ask for suspended accounts explicitly, then split them out.
  paginate "ServiceAccountService/ListServiceAccounts" \
           '{"filter":{"includeSuspended":true}}' "serviceAccounts"
  local sas="${PAGE_ITEMS}" total suspended sysmanaged nolimit
  total=$(jq 'length' <<<"${sas}")
  suspended=$(jq '[.[] | select((.suspended // false) == true)] | length' <<<"${sas}")
  sysmanaged=$(jq '[.[] | select((.systemManaged // false) == true)] | length' <<<"${sas}")
  echo "  service accounts: total=${total} suspended=${suspended} systemManaged=${sysmanaged}"
  SA_ACTIVE_COUNT=$((total - suspended))

  # TRAP 5: absent validUntil == no expiry.
  nolimit=$(jq '[.[] | select((.suspended // false) == false) | select((.validUntil // "") == "")] | length' <<<"${sas}")
  jq -r '.[] | select((.suspended // false) == false)
         | "    - id=…\(((.id // "unknown")[-6:])) validUntil=\(.validUntil // "(none — never expires)") systemManaged=\(.systemManaged // false)"' <<<"${sas}"
  if [ "${nolimit}" -gt 0 ]; then
    echo "FINDING: ${nolimit} active service account(s) have no validUntil — they never expire."
    FINDINGS=$((FINDINGS + 1))
  fi
}

audit_service_account_tokens() {
  # TRAP 2: probe once without the strict classifier so an impersonation refusal
  # is reported as an evidence gap rather than crashing the sweep.
  api "ServiceAccountService/ListServiceAccountTokens" '{"pagination":{"pageSize":100}}'
  if [ "${RPC_CODE}" != "200" ]; then
    SA_TOKENS_ENUMERABLE=0
    echo "  service account tokens: NOT ENUMERABLE (HTTP ${RPC_CODE} $(rpc_err)) — $(rpc_msg)"
    echo "    ListServiceAccountTokens derives the account from the CALLER's identity and needs a"
    echo "    service-account impersonation token. This pack refuses to mint one, so service-account"
    echo "    token expiry is UNPROVEN here — read it in the console, or re-run authenticated AS the"
    echo "    service account (ONA_TOKEN = that account's own token)."
    return 0
  fi
  paginate "ServiceAccountService/ListServiceAccountTokens" '{}' "tokens"
  local toks="${PAGE_ITEMS}" total noexp
  total=$(jq 'length' <<<"${toks}")
  noexp=$(jq '[.[] | select((.expiresAt // "") == "")] | length' <<<"${toks}")
  echo "  service account tokens (for the calling identity): total=${total} without expiresAt=${noexp}"
  jq -r '.[] | "    - id=…\(((.id // "unknown")[-6:])) expiresAt=\(.expiresAt // "(none — never expires)") lastUsed=\(.lastUsed // "(never)")"' <<<"${toks}"
  if [ "${noexp}" -gt 0 ]; then
    echo "FINDING: ${noexp} service account token(s) have no expiresAt."
    FINDINGS=$((FINDINGS + 1))
  fi
}

audit_pats() {
  paginate "UserService/ListPersonalAccessTokens" '{}' "personalAccessTokens"
  local pats="${PAGE_ITEMS}" total noexp rw stale
  total=$(jq 'length' <<<"${pats}")
  noexp=$(jq '[.[] | select((.expiresAt // "") == "")] | length' <<<"${pats}")
  # TRAP 4: absent readOnly == read-write.
  rw=$(jq '[.[] | select((.readOnly // false) == false)] | length' <<<"${pats}")
  stale=$(jq '[.[] | select((.lastUsed // "") == "")] | length' <<<"${pats}")
  echo "  personal access tokens: total=${total} read-write=${rw} without expiresAt=${noexp} never-used=${stale}"
  jq -r '.[] | "    - id=…\(((.id // "unknown")[-6:])) readOnly=\(.readOnly // false) expiresAt=\(.expiresAt // "(none — never expires)") lastUsed=\(.lastUsed // "(never)")"' <<<"${pats}"
  if [ "${noexp}" -gt 0 ]; then
    echo "FINDING: ${noexp} personal access token(s) have no expiresAt."
    echo "  A read-write PAT with no end date is a standing key to the whole organization API."
    FINDINGS=$((FINDINGS + 1))
  fi
}

audit() {
  resolve_org
  echo "Ona 1.4 — service account and personal access token lifetimes"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"
  audit_service_accounts
  audit_service_account_tokens
  audit_pats

  if [ "${FINDINGS}" -gt 0 ]; then
    echo "RESULT: ${FINDINGS} finding group(s) — unbounded credentials exist in this organization."
    ona_complete
    return 1
  fi
  # The impersonation gap only matters when there is something behind it: with zero
  # active service accounts there are no service-account tokens to miss, so the
  # audit is complete even though the method refused.
  if [ "${SA_TOKENS_ENUMERABLE}" -eq 0 ] && [ "${SA_ACTIVE_COUNT}" -gt 0 ]; then
    echo "RESULT: every credential this token could read is bounded, but the ${SA_ACTIVE_COUNT} active"
    echo "        service account(s) above have tokens this identity cannot enumerate (TRAP 2)."
    echo "        Exiting 2: the audit is incomplete, not clean."
    ona_complete
    return 2
  fi
  if [ "${SA_TOKENS_ENUMERABLE}" -eq 0 ]; then
    echo "  (the impersonation refusal above hides nothing: this organization has no active"
    echo "   service accounts, so there are no service-account tokens to enumerate)"
  fi
  echo "COMPLIANT: every service account, service-account token and personal access token has an expiry."
  ona_complete
  return 0
}
# HTH Guide Excerpt: end service-account-and-pat-lifetime-audit

audit
