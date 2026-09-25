#!/usr/bin/env bash
# HTH AWS IAM Identity Center Pack -- Shared utilities for the cli/ packs
# Source this file: source "$(dirname "$0")/common.sh"
#
# These packs drive the first-party AWS CLI v2 (`aws sso-admin`, `aws organizations`,
# `aws cloudtrail`, `aws accessanalyzer`) -- which is why they live under cli/, not api/.
# Every list operation they call has a botocore paginator, so the CLI's default
# auto-pagination returns the complete result set. Do not pass --no-paginate.
#
# Required environment variables:
#   AWS_REGION            -- AWS Region where IAM Identity Center is enabled (its home Region)
#
# Optional environment variables:
#   AWS_PROFILE           -- Named AWS CLI profile to use
#   AWS_SSO_INSTANCE_ARN  -- SSO instance ARN (auto-detected if not set)
#   AWS_IDENTITY_STORE_ID -- Identity Store ID (auto-detected if not set)
#   HTH_PROFILE_LEVEL     -- 1 (Crawl), 2 (Walk), 3 (Run) [default: 1]
#
# Exit codes (deterministic, shared by every pack that sources this file):
#   0 -- every check ran and none failed (WARN lines are advisory, not failures)
#   1 -- at least one check failed, or a call the audit depends on failed
#   2 -- precondition missing (no AWS_REGION, no IAM Identity Center instance, CLI absent)
# A call that fails is never read as "nothing found": an audit that scanned
# nothing must not report a PASS.
#
# https://howtoharden.com/guides/aws-iam-identity-center/

set -euo pipefail

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

precondition() {
  echo -e "${RED}[FAIL]${NC} Precondition: $1"
  exit 2
}

# Required environment variables
[ -n "${AWS_REGION:-}" ] || precondition "set AWS_REGION to the IAM Identity Center home Region (e.g., us-east-1)"
command -v aws >/dev/null 2>&1 || precondition "AWS CLI v2 not found on PATH"
command -v jq  >/dev/null 2>&1 || precondition "jq not found on PATH"

HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"

# ---------------------------------------------------------------------------
# Auto-detect SSO instance ARN and Identity Store ID if not provided
# ---------------------------------------------------------------------------
if [ -z "${AWS_SSO_INSTANCE_ARN:-}" ]; then
  echo -e "${BLUE}[INFO]${NC} Auto-detecting IAM Identity Center instance..."
  INSTANCE_JSON=$(aws sso-admin list-instances --region "${AWS_REGION}" --output json) \
    || precondition "cannot list IAM Identity Center instances (needs sso:ListInstances) -- or set AWS_SSO_INSTANCE_ARN"
  AWS_SSO_INSTANCE_ARN=$(echo "${INSTANCE_JSON}" | jq -r '.Instances[0].InstanceArn // empty')
  AWS_IDENTITY_STORE_ID=$(echo "${INSTANCE_JSON}" | jq -r '.Instances[0].IdentityStoreId // empty')
  # An account with no instance returns an empty list. That is a precondition,
  # not a clean result: there is nothing for these audits to inspect.
  [ -n "${AWS_SSO_INSTANCE_ARN}" ] \
    || precondition "no IAM Identity Center instance in ${AWS_REGION} -- check AWS_REGION is the home Region"
fi

export AWS_SSO_INSTANCE_ARN AWS_IDENTITY_STORE_ID

# ---------------------------------------------------------------------------
# CLI wrappers -- thin wrappers around AWS CLI for SSO/Identity Store calls
# sso_admin() appends --instance-arn, so use it only for operations whose
# request carries InstanceArn; call aws_json for the rest.
# ---------------------------------------------------------------------------
sso_admin() {
  aws sso-admin "$@" \
    --instance-arn "${AWS_SSO_INSTANCE_ARN}" \
    --region "${AWS_REGION}" \
    --output json
}

identity_store() {
  aws identitystore "$@" \
    --identity-store-id "${AWS_IDENTITY_STORE_ID}" \
    --region "${AWS_REGION}" \
    --output json
}

aws_json() {
  aws "$@" --region "${AWS_REGION}" --output json
}

# ---------------------------------------------------------------------------
# ISO-8601 duration (PT1H, PT4H30M, PT90M) -> seconds, in pure bash.
# Prints nothing and returns 1 on anything it cannot parse, so a caller can
# count an unparseable value as a failure instead of reading it as 0.
# ---------------------------------------------------------------------------
iso8601_seconds() {
  local d="$1" h=0 m=0 s=0
  [[ "${d}" =~ ^PT([0-9]+H)?([0-9]+M)?([0-9]+S)?$ ]] || return 1
  [ -n "${BASH_REMATCH[1]}" ] && h="${BASH_REMATCH[1]%H}"
  [ -n "${BASH_REMATCH[2]}" ] && m="${BASH_REMATCH[2]%M}"
  [ -n "${BASH_REMATCH[3]}" ] && s="${BASH_REMATCH[3]%S}"
  echo $(( 10#${h} * 3600 + 10#${m} * 60 + 10#${s} ))
}

# ---------------------------------------------------------------------------
# Profile level gate -- skip controls above current level
# Usage: should_apply 2 || return 0
# ---------------------------------------------------------------------------
should_apply() {
  local required_level=$1
  if [ "${HTH_PROFILE_LEVEL}" -lt "${required_level}" ]; then
    echo -e "${YELLOW}[SKIP]${NC} Requires L${required_level} (current: L${HTH_PROFILE_LEVEL})"
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------
info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
pass()  { echo -e "${GREEN}[PASS]${NC} $1"; }
fail()  { echo -e "${RED}[FAIL]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
banner() {
  echo ""
  echo -e "${BLUE}================================================================${NC}"
  echo -e "${BLUE}  How to Harden -- AWS IAM Identity Center CLI Audit${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}  Profile Level: L${HTH_PROFILE_LEVEL}${NC}"
  echo -e "${BLUE}================================================================${NC}"
  echo ""
}

# ---------------------------------------------------------------------------
# Counters for summary reporting
# ---------------------------------------------------------------------------
CONTROLS_APPLIED=0
CONTROLS_SKIPPED=0
CONTROLS_FAILED=0

increment_applied()  { CONTROLS_APPLIED=$((CONTROLS_APPLIED + 1)); }
increment_skipped()  { CONTROLS_SKIPPED=$((CONTROLS_SKIPPED + 1)); }
increment_failed()   { CONTROLS_FAILED=$((CONTROLS_FAILED + 1)); }

# Prints the counters and EXITS with the pack's verdict: 0 clean, 1 if any
# check failed. Every pack ends by calling it; nothing runs after it.
summary() {
  echo ""
  echo -e "${BLUE}================================================================${NC}"
  echo -e "${BLUE}  Summary${NC}"
  echo -e "${GREEN}  Applied: ${CONTROLS_APPLIED}${NC}"
  echo -e "${YELLOW}  Skipped: ${CONTROLS_SKIPPED}${NC}"
  echo -e "${RED}  Failed:  ${CONTROLS_FAILED}${NC}"
  echo -e "${BLUE}================================================================${NC}"
  [ "${CONTROLS_FAILED}" -eq 0 ] || exit 1
  exit 0
}
