#!/usr/bin/env bash
# HTH AWS IAM Identity Center Pack -- Shared utilities
# Source this file: source "$(dirname "$0")/common.sh"
#
# Required environment variables:
#   AWS_REGION            -- AWS region where IAM Identity Center is enabled
#
# Optional environment variables:
#   AWS_PROFILE           -- Named AWS CLI profile to use
#   AWS_SSO_INSTANCE_ARN  -- SSO instance ARN (auto-detected if not set)
#   AWS_IDENTITY_STORE_ID -- Identity Store ID (auto-detected if not set)
#   HTH_PROFILE_LEVEL     -- 1 (Baseline), 2 (Hardened), 3 (Maximum Security) [default: 1]
#
# https://howtoharden.com/guides/aws-iam-identity-center/

set -euo pipefail

# Required environment variables
: "${AWS_REGION:?Set AWS_REGION (e.g., us-east-1)}"

HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# ---------------------------------------------------------------------------
# Auto-detect SSO instance ARN and Identity Store ID if not provided
# ---------------------------------------------------------------------------
if [ -z "${AWS_SSO_INSTANCE_ARN:-}" ]; then
  info_raw() { echo -e "${BLUE}[INFO]${NC} $1"; }
  info_raw "Auto-detecting IAM Identity Center instance..."
  AWS_SSO_INSTANCE_ARN=$(aws sso-admin list-instances \
    --query 'Instances[0].InstanceArn' --output text \
    --region "${AWS_REGION}" 2>/dev/null) || {
    echo -e "${RED}[FAIL]${NC} Cannot detect SSO instance -- set AWS_SSO_INSTANCE_ARN manually"
    exit 1
  }
  AWS_IDENTITY_STORE_ID=$(aws sso-admin list-instances \
    --query 'Instances[0].IdentityStoreId' --output text \
    --region "${AWS_REGION}" 2>/dev/null) || {
    echo -e "${RED}[FAIL]${NC} Cannot detect Identity Store -- set AWS_IDENTITY_STORE_ID manually"
    exit 1
  }
  unset -f info_raw
fi

export AWS_SSO_INSTANCE_ARN AWS_IDENTITY_STORE_ID

# ---------------------------------------------------------------------------
# CLI wrappers -- thin wrappers around AWS CLI for SSO/Identity Store calls
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
  echo -e "${BLUE}  How to Harden -- AWS IAM Identity Center API Hardening${NC}"
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

summary() {
  echo ""
  echo -e "${BLUE}================================================================${NC}"
  echo -e "${BLUE}  Summary${NC}"
  echo -e "${GREEN}  Applied: ${CONTROLS_APPLIED}${NC}"
  echo -e "${YELLOW}  Skipped: ${CONTROLS_SKIPPED}${NC}"
  echo -e "${RED}  Failed:  ${CONTROLS_FAILED}${NC}"
  echo -e "${BLUE}================================================================${NC}"
}
