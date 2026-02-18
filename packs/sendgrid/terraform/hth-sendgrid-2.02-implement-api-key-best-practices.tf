# =============================================================================
# HTH SendGrid Control 2.2: Implement API Key Best Practices
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.11, NIST SC-12
# Source: https://howtoharden.com/guides/sendgrid/#22-implement-api-key-best-practices
# =============================================================================
#
# NOTE: API key storage, rotation, and secret scanning are operational practices
# that live outside of the SendGrid Terraform provider. This file documents the
# recommended approach and provides outputs for integration with secret managers.
#
# Best practices enforced by this code pack:
#   1. Keys are created via Terraform (Control 2.1) with named purposes
#   2. Key values are marked sensitive and available only in outputs
#   3. Rotation: destroy + recreate the sendgrid_api_key resource
#   4. Store output values in your secret manager (Vault, AWS Secrets Manager, etc.)

# HTH Guide Excerpt: begin terraform
# API key best practices are enforced through:
#   - Named, purpose-specific keys (see hth-sendgrid-2.01)
#   - Sensitive output values for secret manager integration
#   - Rotation via Terraform lifecycle: taint and re-apply
#
# Recommended .gitignore additions:
#   terraform.tfvars
#   *.tfstate
#   *.tfstate.backup
#   .terraform/
#
# Rotation procedure:
#   1. terraform taint 'sendgrid_api_key.managed["key_name"]'
#   2. terraform apply
#   3. Update secret manager with new key value from output
# HTH Guide Excerpt: end terraform
