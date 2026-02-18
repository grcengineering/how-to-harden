# =============================================================================
# HTH CyberArk Control 3.3: Integrate with External Secrets Managers
# Profile Level: L2 (Hardened)
# Frameworks: NIST IA-5(7)
# Source: https://howtoharden.com/guides/cyberark/#33-integrate-with-external-secrets-managers
# =============================================================================

# HTH Guide Excerpt: begin terraform
# L2+: Configure Conjur policy for HashiCorp Vault integration
resource "null_resource" "conjur_vault_integration_policy" {
  count = var.profile_level >= 2 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X POST \
        "${var.conjur_appliance_url}/policies/${var.conjur_account}/policy/root" \
        -H "Authorization: Token token=\"${var.conjur_api_key}\"" \
        -H "Content-Type: application/x-yaml" \
        -d '
---
- !policy
  id: integrations/hashicorp-vault
  body:
    - !host
      id: vault-sync
      annotations:
        description: HashiCorp Vault integration for secrets synchronization
        authn/api-key: true
    - !permit
      role: !host vault-sync
      privileges: [read, execute]
      resource: !variable secrets/*
    - !grant
      role: !group integrations/readers
      member: !host vault-sync
'
    EOT
  }

  triggers = {
    policy_version = "v1"
  }
}

# L2+: Configure Conjur policy for AWS Secrets Manager integration
resource "null_resource" "conjur_aws_integration_policy" {
  count = var.profile_level >= 2 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X POST \
        "${var.conjur_appliance_url}/policies/${var.conjur_account}/policy/root" \
        -H "Authorization: Token token=\"${var.conjur_api_key}\"" \
        -H "Content-Type: application/x-yaml" \
        -d '
---
- !policy
  id: integrations/aws-secrets-manager
  body:
    - !host
      id: aws-sync
      annotations:
        description: AWS Secrets Manager integration for secrets synchronization
        authn/api-key: true
    - !permit
      role: !host aws-sync
      privileges: [read]
      resource: !variable secrets/aws/*
    - !grant
      role: !group integrations/readers
      member: !host aws-sync
'
    EOT
  }

  triggers = {
    policy_version = "v1"
  }
}

# L3: Configure Conjur policy restricting integration sync to specific secrets
resource "null_resource" "conjur_restricted_sync_policy" {
  count = var.profile_level >= 3 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X POST \
        "${var.conjur_appliance_url}/policies/${var.conjur_account}/policy/root" \
        -H "Authorization: Token token=\"${var.conjur_api_key}\"" \
        -H "Content-Type: application/x-yaml" \
        -d '
---
- !policy
  id: integrations/restrictions
  body:
    - !deny
      role: !group integrations/readers
      privileges: [read, execute]
      resource: !variable secrets/critical/*
    - !deny
      role: !group integrations/readers
      privileges: [read, execute]
      resource: !variable secrets/break-glass/*
'
    EOT
  }

  depends_on = [
    null_resource.conjur_vault_integration_policy,
    null_resource.conjur_aws_integration_policy
  ]

  triggers = {
    profile_level = var.profile_level
  }
}
# HTH Guide Excerpt: end terraform
