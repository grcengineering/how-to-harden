#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: aws-iam-identity-center-4.3
#   guide:   https://howtoharden.com/guides/aws-iam-identity-center/#43-use-a-customer-managed-kms-key-for-identity-center-data
#   profile: L3
#   mode:    read-only
#   requires: AWS_REGION; AWS credentials with sso:ListInstances, sso:DescribeInstance
# =============================================================================
# HTH AWS IAM Identity Center Control 4.3: Use a Customer Managed KMS Key
# Profile: L3 | NIST: SC-12, SC-13, SC-28 | Frameworks: CIS Controls 3.11
# https://howtoharden.com/guides/aws-iam-identity-center/#43-use-a-customer-managed-kms-key-for-identity-center-data
# Dependencies: aws (CLI v2), jq
#
# READ-ONLY ON PURPOSE. The write (`aws sso-admin update-instance --instance-arn <arn>
# --encryption-configuration KeyType=CUSTOMER_MANAGED_KEY,KmsKeyArn=...`) carries
# the guide's lockout warning: if the key is later deleted, disabled, or its policy
# stops IAM Identity Center from using it, administrators and users are locked out.
# Complete the guide's Steps 1-3 (key, deletion guard, break-glass path) first.
source "$(dirname "$0")/common.sh"

banner "4.3: Use a Customer Managed KMS Key"

should_apply 3 || { increment_skipped; summary; }

# HTH Guide Excerpt: begin cli-audit-kms-key
# DescribeInstance reports EncryptionConfigurationDetails:
#   KeyType          AWS_OWNED_KMS_KEY | CUSTOMER_MANAGED_KEY
#   EncryptionStatus UPDATING | ENABLED | UPDATE_FAILED
INSTANCE=$(sso_admin describe-instance) || {
  fail "4.3 Cannot describe the IAM Identity Center instance (sso:DescribeInstance)"
  increment_failed
  summary
}
KEY_TYPE=$(echo "${INSTANCE}" | jq -r '.EncryptionConfigurationDetails.KeyType // empty')
ENC_STATUS=$(echo "${INSTANCE}" | jq -r '.EncryptionConfigurationDetails.EncryptionStatus // empty')

case "${KEY_TYPE}:${ENC_STATUS}" in
  CUSTOMER_MANAGED_KEY:ENABLED)
    pass "4.3 Identity Center data is encrypted with a customer managed KMS key (ENABLED)"
    increment_applied ;;
  CUSTOMER_MANAGED_KEY:UPDATING)
    warn "4.3 Customer managed key configured but encryption is still UPDATING -- re-run to confirm"
    increment_applied ;;
  CUSTOMER_MANAGED_KEY:UPDATE_FAILED)
    fail "4.3 Customer managed key update FAILED: $(echo "${INSTANCE}" \
      | jq -r '.EncryptionConfigurationDetails.EncryptionStatusReason // "no reason given"')"
    increment_failed ;;
  AWS_OWNED_KMS_KEY:*)
    fail "4.3 Identity Center uses the default AWS-owned key -- no customer managed key (SC-28)"
    increment_failed ;;
  *)
    fail "4.3 Encryption configuration not reported (KeyType='${KEY_TYPE}', status='${ENC_STATUS}') -- cannot verify"
    increment_failed ;;
esac
# HTH Guide Excerpt: end cli-audit-kms-key

summary
