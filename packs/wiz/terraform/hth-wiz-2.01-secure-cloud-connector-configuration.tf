# =============================================================================
# HTH Wiz Control 2.1: Secure Cloud Connector Configuration
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5, AC-6
# Source: https://howtoharden.com/guides/wiz/#21-secure-cloud-connector-configuration
# =============================================================================

# HTH Guide Excerpt: begin terraform
# AWS connector with least-privilege IAM role (read-only)
# The IAM role referenced here should grant only:
#   ec2:Describe*, s3:GetBucketLocation, s3:GetBucketPolicy,
#   s3:ListAllMyBuckets, iam:GetAccountSummary, iam:ListRoles
# with an external ID condition on the trust policy.
resource "wiz_connector_aws" "hardened" {
  count = var.aws_connector_role_arn != "" ? 1 : 0

  name    = var.aws_connector_name
  enabled = true

  auth_params = jsonencode({
    "customerRoleARN" = var.aws_connector_role_arn
  })

  extra_config = jsonencode({
    "optedInRegions"       = var.aws_connector_regions
    "excludedAccounts"     = var.aws_connector_excluded_accounts
    "skipOrganizationScan" = false
  })
}

# GCP connector with Viewer role (read-only, organization-level)
resource "wiz_connector_gcp" "hardened" {
  count = var.gcp_connector_organization_id != "" ? 1 : 0

  name    = var.gcp_connector_name
  enabled = true

  auth_params = jsonencode({
    "isManagedIdentity" = true
    "organization_id"   = var.gcp_connector_organization_id
  })

  extra_config = jsonencode({
    "projects"              = []
    "excludedProjects"      = var.gcp_connector_excluded_projects
    "includedFolders"       = []
    "excludedFolders"       = []
    "auditLogMonitorEnabled" = true
  })
}
# HTH Guide Excerpt: end terraform
