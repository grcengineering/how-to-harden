# Orca Security Hardening Code Pack - Terraform

Terraform configuration for hardening Orca Security based on the [How to Harden Orca Security Guide](https://howtoharden.com/guides/orca/).

## Provider

Uses the official [orcasecurity/orcasecurity](https://registry.terraform.io/providers/orcasecurity/orcasecurity/latest/docs) Terraform provider (`~> 0.5`).

## Profile Levels

Controls are deployed based on the selected profile level. Levels are cumulative.

| Level | Name | Description |
|-------|------|-------------|
| 1 | Baseline | SSO groups, RBAC custom roles, admin group, cloud account security, monitoring alerts |
| 2 | Hardened | Adds business unit scoping, API key monitoring, automated notifications |
| 3 | Maximum Security | Adds restricted production business unit, API key inventory view |

## Controls

| File | Control | Level |
|------|---------|-------|
| `hth-orca-1.01-configure-saml-sso.tf` | 1.1 Configure SAML SSO | L1 |
| `hth-orca-1.02-enforce-mfa.tf` | 1.2 Enforce MFA | L1 |
| `hth-orca-2.01-configure-rbac.tf` | 2.1 Configure RBAC | L1 |
| `hth-orca-2.02-configure-account-scope.tf` | 2.2 Configure Account Scope | L2 |
| `hth-orca-2.03-limit-admin-access.tf` | 2.3 Limit Admin Access | L1 |
| `hth-orca-3.01-configure-cloud-account-security.tf` | 3.1 Cloud Account Security | L1 |
| `hth-orca-3.02-configure-api-security.tf` | 3.2 Configure API Security | L2 |

## Quick Start

```bash
# 1. Copy example variables
cp terraform.tfvars.example terraform.tfvars

# 2. Edit with your values
#    - Set orca_api_token (or use TF_VAR_orca_api_token env var)
#    - Configure user IDs and permissions
#    - Choose profile_level (1, 2, or 3)

# 3. Initialize and apply
terraform init
terraform plan
terraform apply
```

## Authentication

The provider requires two values:

| Variable | Environment Variable | Description |
|----------|---------------------|-------------|
| `orca_api_endpoint` | `ORCASECURITY_API_ENDPOINT` | API endpoint (default: `https://api.orcasecurity.io`) |
| `orca_api_token` | `ORCASECURITY_API_TOKEN` | API token from Settings > API Keys |

For production, use environment variables:

```bash
export TF_VAR_orca_api_token="your-api-token"
terraform apply
```

## Resources Created

### L1 (Baseline) - Always Applied

- `orcasecurity_group.sso_users` - SSO user group for SAML attribute mapping
- `orcasecurity_custom_sonar_alert.mfa_not_enforced` - MFA gap detection
- `orcasecurity_custom_role.security_analyst` - Read-only analyst role
- `orcasecurity_custom_role.viewer` - Minimal viewer role
- `orcasecurity_custom_sonar_alert.excessive_permissions` - Overprivileged user detection
- `orcasecurity_group.platform_admins` - Restricted admin group
- `orcasecurity_custom_sonar_alert.excessive_admins` - Admin count monitoring
- `orcasecurity_trusted_cloud_account.trusted` - Trusted integration accounts
- `orcasecurity_custom_sonar_alert.overprivileged_integration` - Integration permission monitoring
- `orcasecurity_discovery_view.cloud_accounts_inventory` - Cloud accounts inventory view

### L2 (Hardened) - Added at Profile Level 2+

- `orcasecurity_business_unit.scoped_environment` - Scoped visibility business unit
- `orcasecurity_custom_sonar_alert.stale_api_keys` - Stale API key detection
- `orcasecurity_automation.api_key_alert` - Email notifications for API findings

### L3 (Maximum Security) - Added at Profile Level 3

- `orcasecurity_business_unit.restricted_production` - Restricted production business unit
- `orcasecurity_discovery_view.api_key_inventory` - API key inventory view

## Important Notes

- **SAML SSO** must be configured through the Orca UI (Settings > Authentication > SSO). The Terraform provider does not manage IdP settings directly. This pack creates the supporting SSO group.
- **MFA** is enforced through your identity provider, not Orca directly. This pack monitors for gaps in MFA coverage.
- **API tokens** should be stored in a secrets manager and rotated regularly. Never commit tokens to version control.

## References

- [Orca Security Knowledge Base](https://docs.orcasecurity.io/)
- [Orca Terraform Provider Docs](https://registry.terraform.io/providers/orcasecurity/orcasecurity/latest/docs)
- [How to Harden - Orca Security Guide](https://howtoharden.com/guides/orca/)
