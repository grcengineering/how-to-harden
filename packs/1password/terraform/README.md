# 1Password Hardening Code Pack - Terraform

> **Source Guide:** [How to Harden 1Password](https://howtoharden.com/guides/1password/)
> **Provider:** [1Password/onepassword](https://registry.terraform.io/providers/1Password/onepassword/latest/docs) `~> 2.0`

## Overview

This Terraform code pack implements the [HTH 1Password Business Hardening Guide](https://howtoharden.com/guides/1password/) controls as infrastructure-as-code. It creates a hardened vault structure, documents admin-level policy configurations, and stores audit records for compliance tracking.

### What This Pack Manages Directly

- **Vaults** -- Creates a least-privilege vault structure (Infrastructure, Team Shared, Executive, Security, Break Glass)
- **Audit Records** -- Stores hardening configuration as secure notes for compliance tracking
- **SCIM Bridge Config** -- Documents SCIM provisioning setup and verifies bridge health

### What Requires Admin Console Configuration

The 1Password Terraform provider (`1Password/onepassword`) manages items and vaults. The following controls are **admin-level settings** that must be configured via the 1Password Admin Console, and this pack documents/verifies them:

- SSO/SAML configuration (Control 1.1)
- SCIM provisioning setup (Control 1.2)
- Master password policy (Control 2.1)
- Firewall rules (Control 2.2)
- Team member policies (Control 2.3)
- Role-based access (Control 2.4)
- Item sharing policies (Control 3.2)
- Audit logging / Events API (Control 4.1)
- Security dashboard review (Control 4.2)

## Prerequisites

- 1Password Business or Enterprise plan
- [1Password CLI](https://developer.1password.com/docs/cli/) (`op`) installed (recommended)
- 1Password Service Account token with vault management permissions
- Terraform >= 1.0

## Quick Start

```bash
# 1. Clone and navigate to the pack
cd packs/1password/terraform/

# 2. Copy example variables
cp terraform.tfvars.example terraform.tfvars

# 3. Edit with your values (NEVER commit terraform.tfvars)
vim terraform.tfvars

# 4. Initialize and apply
terraform init
terraform plan
terraform apply
```

## Profile Levels

Profiles are cumulative -- L2 includes all L1 controls, L3 includes all L1+L2.

```bash
# L1: Baseline -- essential controls for all organizations
terraform apply -var="profile_level=1"

# L2: Hardened -- adds firewall, SCIM, sharing restrictions
terraform apply -var="profile_level=2"

# L3: Maximum Security -- strictest controls for regulated industries
terraform apply -var="profile_level=3"
```

| Control | L1 | L2 | L3 |
|---------|----|----|-----|
| 1.1 SSO Configuration | Verify | Verify | Verify |
| 1.2 SCIM Provisioning | -- | Verify + Document | Verify + Document |
| 2.1 Password Policy | Document (10+) | Document (12+) | Document (14+) |
| 2.2 Firewall Rules | -- | Document | Document + IP allowlist |
| 2.3 Team Policies | Document | Restrict vault creation | Disable external sharing |
| 2.4 Role-Based Access | Document | Quarterly review | Monthly review + custom roles |
| 3.1 Vault Permissions | 2 vaults | 4 vaults | 5 vaults (+ break glass) |
| 3.2 Sharing Policies | -- | Restrict guest sharing | Disable or strict expiry |
| 4.1 Audit Logging | Document | SIEM integration | All event types |
| 4.2 Security Dashboard | Monthly review | Bi-weekly review | Weekly review |

## File Structure

```text
packs/1password/terraform/
  providers.tf                                          # Provider configuration
  variables.tf                                          # All input variables
  outputs.tf                                            # Output values
  terraform.tfvars.example                              # Example variable values
  README.md                                             # This file
  hth-1password-1.1-configure-sso-with-identity-provider.tf
  hth-1password-1.2-configure-scim-provisioning.tf
  hth-1password-2.1-configure-account-password-policy.tf
  hth-1password-2.2-configure-firewall-rules.tf
  hth-1password-2.3-configure-team-member-policies.tf
  hth-1password-2.4-implement-role-based-access.tf
  hth-1password-3.1-configure-vault-permissions.tf
  hth-1password-3.2-configure-item-sharing-policies.tf
  hth-1password-4.1-enable-audit-logging.tf
  hth-1password-4.2-monitor-security-dashboard.tf
```

## Security Notes

- **Never commit `terraform.tfvars`** -- it contains secrets
- Use environment variables for sensitive values: `TF_VAR_op_service_account_token`
- The Service Account token should have minimum required permissions
- Review `terraform plan` output before every `terraform apply`
- Store Terraform state securely (encrypted S3 backend recommended)
