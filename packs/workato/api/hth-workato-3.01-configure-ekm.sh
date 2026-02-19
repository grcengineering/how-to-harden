#!/usr/bin/env bash
# HTH Workato Control 3.01: Enable Encryption Key Management (EKM)
# Profile: L3 | NIST: SC-12, SC-28
# https://howtoharden.com/guides/workato/#31-enable-encryption-key-management-ekm

# HTH Guide Excerpt: begin api-create-kms-key
# Create a KMS key for Workato EKM
aws kms create-key \
  --description "Workato EKM - Workspace encryption key" \
  --key-usage ENCRYPT_DECRYPT \
  --origin AWS_KMS \
  --tags TagKey=Application,TagValue=Workato TagKey=Environment,TagValue=Production

# Enable automatic key rotation
aws kms enable-key-rotation --key-id KEY_ID

# Verify key rotation is enabled
aws kms get-key-rotation-status --key-id KEY_ID
# HTH Guide Excerpt: end api-create-kms-key
