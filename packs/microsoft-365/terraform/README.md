# Microsoft 365 Hardening Code Pack - Terraform

Terraform configuration for hardening Microsoft 365 tenants via Azure AD (Entra ID) APIs. Part of the [How to Harden](https://howtoharden.com) project.

**Guide:** [Microsoft 365 Hardening Guide](https://howtoharden.com/guides/microsoft-365/)

## Provider

This pack uses the [`hashicorp/azuread`](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs) provider (`~> 2.0`). Microsoft 365 security controls (Conditional Access, app consent, directory roles) are configured through Azure AD / Entra ID APIs.

## Prerequisites

1. **Azure AD Tenant** with Microsoft 365 E3 or E5 licenses
2. **App Registration** (service principal) with the following Microsoft Graph API permissions:
   - `Policy.ReadWrite.ConditionalAccess`
   - `Application.ReadWrite.All`
   - `Directory.ReadWrite.All`
   - `RoleManagement.ReadWrite.Directory` (for PIM at L2+)
3. **Terraform** >= 1.0
4. **Entra ID P1** license minimum (P2 for PIM and risk-based policies)

## Quick Start

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your tenant values
terraform init
terraform plan
terraform apply
```

## Profile Levels

Profiles are cumulative: L2 includes all L1 controls, L3 includes all L1+L2 controls.

| Level | Name | Description |
|-------|------|-------------|
| **L1** | Baseline | MFA for all users, block legacy auth, break-glass accounts, restrict user consent, audit logging, risky sign-in protection |
| **L2** | Hardened | Adds PIM, phishing-resistant auth strength, named locations, country blocking, sensitivity label groups, SIEM integration, high-risk blocking, user risk remediation |
| **L3** | Maximum Security | Adds MFA from untrusted locations only, auto-labeling scope, external domain allow-listing, unverified publisher blocking |

## Controls

| File | Control | Level |
|------|---------|-------|
| `hth-microsoft-365-1.1-enforce-phishing-resistant-mfa.tf` | Enforce MFA + phishing-resistant auth strength | L1 (L2 for auth strength) |
| `hth-microsoft-365-1.2-block-legacy-authentication.tf` | Block legacy auth protocols (POP3, IMAP, SMTP AUTH) | L1 |
| `hth-microsoft-365-1.3-privileged-identity-management.tf` | PIM eligible role assignments | L2 |
| `hth-microsoft-365-1.4-break-glass-emergency-access.tf` | Emergency access accounts with Global Admin | L1 |
| `hth-microsoft-365-2.1-configure-named-locations.tf` | Trusted IPs, country blocking, location-based policies | L2 |
| `hth-microsoft-365-3.1-restrict-user-consent.tf` | Disable user OAuth consent, admin workflow | L1 |
| `hth-microsoft-365-3.2-review-app-permissions.tf` | Restrict app registration, audit service principals | L2 |
| `hth-microsoft-365-4.1-sensitivity-labels-dlp.tf` | Groups for sensitivity labels and DLP scoping | L2 |
| `hth-microsoft-365-4.2-external-sharing-restrictions.tf` | External sharing groups, unmanaged device restrictions | L1 (L2 for device policy) |
| `hth-microsoft-365-5.1-enable-unified-audit-logging.tf` | Audit reviewer groups, SIEM app registration | L1 (L2 for SIEM) |
| `hth-microsoft-365-5.2-configure-security-alerts.tf` | Risk-based Conditional Access, security ops groups | L1 (L2 for high-risk blocking) |

## Important Notes

Some Microsoft 365 controls cannot be fully managed through the `azuread` Terraform provider alone:

- **SharePoint Online sharing** -- Use `Set-SPOTenant` via PowerShell
- **Exchange Online audit logging** -- Use `Set-AdminAuditLogConfig` via PowerShell
- **Sensitivity labels and DLP policies** -- Use Microsoft Purview PowerShell or Graph API
- **Defender for Office 365 alerts** -- Use Security & Compliance PowerShell

These controls are documented in their respective `.tf` files with PowerShell commands in comments. The Terraform files create the prerequisite Azure AD groups and Conditional Access policies that support these controls.

## Sensitive Values

Never commit `terraform.tfvars` to version control. Use environment variables for secrets:

```bash
export TF_VAR_client_secret="your-app-secret"
export TF_VAR_break_glass_account_passwords='["password1","password2"]'
```

## License

MIT -- See [LICENSE](../../../LICENSE) in the repository root.
