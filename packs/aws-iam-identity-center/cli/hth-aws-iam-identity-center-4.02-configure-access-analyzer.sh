#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: aws-iam-identity-center-4.2
#   guide:   https://howtoharden.com/guides/aws-iam-identity-center/#42-configure-access-analyzer
#   profile: L2
#   mode:    mutating
#   requires: AWS_REGION; AWS credentials with sso:ListInstances, access-analyzer:ListAnalyzers, access-analyzer:ListFindings (plus access-analyzer:CreateAnalyzer only for --apply)
# =============================================================================
# HTH AWS IAM Identity Center Control 4.2: Configure Access Analyzer
# Profile: L2 | NIST: AC-6 | Frameworks: SOC 2 CC6.1, ISO 27001 A.9.2.5
# https://howtoharden.com/guides/aws-iam-identity-center/#42-configure-access-analyzer
# Dependencies: aws (CLI v2), jq
#
# Usage: bash <this file>            -- audit only (read-only calls)
#        bash <this file> --apply    -- audit, and create an analyzer if none exists
#
# WHY `mode: mutating` DESPITE A READ-ONLY DEFAULT. An earlier revision called
# `accessanalyzer create-analyzer` automatically whenever it found no active
# analyzer -- an undeclared write inside what read like an audit. The write now
# fires only when you pass --apply, but the file CAN change account state, so it
# declares mutating. Run it with no arguments to collect evidence.
#
# ONLY EXTERNAL-ACCESS ANALYZERS COUNT. The analyzer type enum also has
# ACCOUNT_UNUSED_ACCESS, ORGANIZATION_UNUSED_ACCESS and *_INTERNAL_ACCESS. This
# control is about unintended external/cross-account access, and ListFindings "is
# supported only for external access analyzers". An account holding only an
# unused-access analyzer used to print "[PASS] Found 1 active Access Analyzer(s)".
source "$(dirname "$0")/common.sh"

APPLY=false
if [ "${1:-}" = "--apply" ]; then APPLY=true; fi

banner "4.2: Configure Access Analyzer"

should_apply 2 || { increment_skipped; summary; }
info "4.2 Verifying IAM Access Analyzer configuration..."

# HTH Guide Excerpt: begin cli-check-access-analyzer
# Find ACTIVE external-access analyzers (type ACCOUNT or ORGANIZATION).
ANALYZERS=$(aws_json accessanalyzer list-analyzers) || {
  fail "4.2 Failed to list analyzers (access-analyzer:ListAnalyzers)"
  increment_failed
  summary
}

EXTERNAL_ARNS=""; EXTERNAL_COUNT=0; ORG_ANALYZER=false
while IFS=$'\t' read -r NAME TYPE STATUS ARN; do
  [ -n "${NAME}" ] || continue
  case "${TYPE}" in
    ACCOUNT|ORGANIZATION)
      if [ "${STATUS}" = "ACTIVE" ]; then
        info "4.2   Active external-access analyzer: ${NAME} (type: ${TYPE})"
        EXTERNAL_COUNT=$((EXTERNAL_COUNT + 1))
        EXTERNAL_ARNS="${EXTERNAL_ARNS} ${ARN}"
        if [ "${TYPE}" = "ORGANIZATION" ]; then ORG_ANALYZER=true; fi
      else
        warn "4.2   Analyzer '${NAME}' is ${STATUS} -- should be ACTIVE"
      fi ;;
    *)
      info "4.2   Analyzer '${NAME}' is type ${TYPE} -- does not cover external access, not counted" ;;
  esac
done < <(echo "${ANALYZERS}" | jq -r '(.analyzers // [])[] | [.name, .type, .status, .arn] | @tsv')
# HTH Guide Excerpt: end cli-check-access-analyzer

if [ "${EXTERNAL_COUNT}" -eq 0 ]; then
  if [ "${APPLY}" != "true" ]; then
    fail "4.2 No active external-access analyzer -- re-run with --apply to create one, or see the Terraform pack"
    increment_failed
    summary
  fi
  # HTH Guide Excerpt: begin cli-create-access-analyzer
  # --apply only: create an organization analyzer, falling back to account scope
  # when this is not the management or delegated-administrator account.
  info "4.2 --apply: creating organization-level Access Analyzer..."
  CREATE_RESULT=$(aws_json accessanalyzer create-analyzer \
    --analyzer-name "hth-org-access-analyzer" --type ORGANIZATION) || {
    warn "4.2 Organization-level analyzer failed -- trying account-level..."
    CREATE_RESULT=$(aws_json accessanalyzer create-analyzer \
      --analyzer-name "hth-account-access-analyzer" --type ACCOUNT) || {
      fail "4.2 Failed to create Access Analyzer (access-analyzer:CreateAnalyzer)"
      increment_failed
      summary
    }
  }
  NEW_ARN=$(echo "${CREATE_RESULT}" | jq -r '.arn // empty')
  if [ -n "${NEW_ARN}" ]; then
    pass "4.2 Created Access Analyzer: ${NEW_ARN##*/}"
    increment_applied
  else
    fail "4.2 Analyzer creation returned empty ARN"
    increment_failed
  fi
  # HTH Guide Excerpt: end cli-create-access-analyzer
  summary
fi

pass "4.2 Found ${EXTERNAL_COUNT} active external-access analyzer(s)"
if [ "${ORG_ANALYZER}" = "true" ]; then
  pass "4.2 Organization-level analyzer is active (recommended for cross-account visibility)"
else
  warn "4.2 No organization-level analyzer -- consider an ORGANIZATION analyzer for cross-account visibility"
fi
increment_applied

# HTH Guide Excerpt: begin cli-check-findings
# Review ACTIVE findings on each external-access analyzer; a failed read is a failure.
for ARN in ${EXTERNAL_ARNS}; do
  FINDINGS=$(aws_json accessanalyzer list-findings --analyzer-arn "${ARN}" \
    --filter '{"status": {"eq": ["ACTIVE"]}}') || {
    fail "4.2 Cannot list findings for '${ARN##*/}' (access-analyzer:ListFindings)"
    increment_failed; continue
  }
  FINDING_COUNT=$(echo "${FINDINGS}" | jq '(.findings // []) | length')
  if [ "${FINDING_COUNT}" -gt 0 ]; then
    warn "4.2 Analyzer '${ARN##*/}' has ${FINDING_COUNT} active finding(s) -- review for over-permissive access"
  else
    pass "4.2 Analyzer '${ARN##*/}' has no active findings"
  fi
done
# HTH Guide Excerpt: end cli-check-findings

summary
