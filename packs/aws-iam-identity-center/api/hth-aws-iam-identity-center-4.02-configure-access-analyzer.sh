#!/usr/bin/env bash
# HTH AWS IAM Identity Center Control 4.2: Configure Access Analyzer
# Profile: L2 | NIST: AC-6 | Frameworks: SOC 2 CC6.1, ISO 27001 A.9.2.5
# https://howtoharden.com/guides/aws-iam-identity-center/#42-configure-access-analyzer
source "$(dirname "$0")/common.sh"

banner "4.2: Configure Access Analyzer"

should_apply 2 || { increment_skipped; summary; exit 0; }
info "4.2 Verifying IAM Access Analyzer configuration..."

# HTH Guide Excerpt: begin api-check-access-analyzer
# Check for existing IAM Access Analyzer instances
info "4.2 Listing Access Analyzer instances..."
ANALYZERS=$(aws_json accessanalyzer list-analyzers 2>/dev/null) || {
  fail "4.2 Failed to list analyzers -- verify accessanalyzer:ListAnalyzers permission"
  increment_failed
  summary
  exit 0
}

ANALYZER_COUNT=$(echo "${ANALYZERS}" | jq '.analyzers | length' 2>/dev/null || echo "0")
ACTIVE_COUNT=0
ORG_ANALYZER=false

for i in $(seq 0 $((ANALYZER_COUNT - 1))); do
  ANALYZER=$(echo "${ANALYZERS}" | jq ".analyzers[${i}]")
  NAME=$(echo "${ANALYZER}" | jq -r '.name')
  STATUS=$(echo "${ANALYZER}" | jq -r '.status')
  TYPE=$(echo "${ANALYZER}" | jq -r '.type')

  if [ "${STATUS}" = "ACTIVE" ]; then
    ACTIVE_COUNT=$((ACTIVE_COUNT + 1))
    info "4.2   Active analyzer: ${NAME} (type: ${TYPE})"
    if [ "${TYPE}" = "ORGANIZATION" ]; then
      ORG_ANALYZER=true
    fi
  else
    warn "4.2   Analyzer '${NAME}' is ${STATUS} -- should be ACTIVE"
  fi
done
# HTH Guide Excerpt: end api-check-access-analyzer

if [ "${ACTIVE_COUNT}" -eq 0 ]; then
  warn "4.2 No active Access Analyzers found -- creating organization-level analyzer..."

  # HTH Guide Excerpt: begin api-create-access-analyzer
  # Create an organization-level Access Analyzer
  info "4.2 Creating organization-level Access Analyzer..."
  CREATE_RESULT=$(aws_json accessanalyzer create-analyzer \
    --analyzer-name "hth-org-access-analyzer" \
    --type ORGANIZATION 2>/dev/null) || {
    # Fall back to account-level if org-level fails (not org management account)
    warn "4.2 Organization-level analyzer failed -- trying account-level..."
    CREATE_RESULT=$(aws_json accessanalyzer create-analyzer \
      --analyzer-name "hth-account-access-analyzer" \
      --type ACCOUNT 2>/dev/null) || {
      fail "4.2 Failed to create Access Analyzer"
      increment_failed
      summary
      exit 0
    }
  }

  NEW_ARN=$(echo "${CREATE_RESULT}" | jq -r '.arn // empty' 2>/dev/null || true)
  if [ -n "${NEW_ARN}" ]; then
    pass "4.2 Created Access Analyzer: ${NEW_ARN}"
    increment_applied
  else
    fail "4.2 Analyzer creation returned empty ARN"
    increment_failed
  fi
  # HTH Guide Excerpt: end api-create-access-analyzer
else
  pass "4.2 Found ${ACTIVE_COUNT} active Access Analyzer(s)"
  if [ "${ORG_ANALYZER}" = "true" ]; then
    pass "4.2 Organization-level analyzer is active (recommended for cross-account visibility)"
  else
    warn "4.2 No organization-level analyzer -- consider upgrading from account-level to organization-level"
  fi
  increment_applied
fi

# HTH Guide Excerpt: begin api-check-findings
# Review active Access Analyzer findings
info "4.2 Checking for active findings..."
for i in $(seq 0 $((ANALYZER_COUNT - 1))); do
  ANALYZER=$(echo "${ANALYZERS}" | jq ".analyzers[${i}]")
  NAME=$(echo "${ANALYZER}" | jq -r '.name')
  ARN=$(echo "${ANALYZER}" | jq -r '.arn')
  STATUS=$(echo "${ANALYZER}" | jq -r '.status')

  [ "${STATUS}" != "ACTIVE" ] && continue

  FINDINGS=$(aws_json accessanalyzer list-findings \
    --analyzer-arn "${ARN}" \
    --filter '{"status": {"eq": ["ACTIVE"]}}' 2>/dev/null) || continue

  FINDING_COUNT=$(echo "${FINDINGS}" | jq '.findings | length' 2>/dev/null || echo "0")

  if [ "${FINDING_COUNT}" -gt 0 ]; then
    warn "4.2 Analyzer '${NAME}' has ${FINDING_COUNT} active finding(s) -- review for over-permissive access"
  else
    pass "4.2 Analyzer '${NAME}' has no active findings"
  fi
done
# HTH Guide Excerpt: end api-check-findings

summary
