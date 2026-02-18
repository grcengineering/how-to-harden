# Microsoft Entra ID Hardening Code Pack - Terraform

> Part of [How to Harden](https://howtoharden.com) -- community-developed SaaS security hardening guides.

This Terraform code pack implements the security controls from the [Microsoft Entra ID Hardening Guide](https://howtoharden.com/guides/microsoft-entra-id/).

## Provider

Uses the [hashicorp/azuread](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs) Terraform provider (`~> 2.0`).

## Prerequisites

- Terraform >= 1.0
- Azure AD tenant with appropriate admin roles
- Microsoft Entra ID P1 license (Conditional Access)
- Microsoft Entra ID P2 license (Identity Protection, PIM -- required for L2+ controls)
- Authentication configured via Azure CLI (`az login`), managed identity, or service principal environment variables

## Quick Start

```bash
# Clone and navigate to the pack
cd packs/microsoft-entra-id/terraform/

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your tenant-specific values

# Initialize and apply
terraform init
terraform plan
terraform apply
```

## Profile Levels

Controls are applied cumulatively based on the `profile_level` variable:

| Level | Name | Description |
|-------|------|-------------|
| **1** | Baseline | Essential controls for all organizations |
| **2** | Hardened | Adds device compliance, risk policies, PIM |
| **3** | Maximum Security | Strictest controls for regulated industries |

```bash
# Apply L1 (default)
terraform apply -var="profile_level=1"

# Apply L2 (includes L1)
terraform apply -var="profile_level=2"
```

## Controls Implemented

### L1 -- Baseline

| File | Control | Description |
|------|---------|-------------|
| `hth-microsoft-entra-id-1.01-enforce-phishing-resistant-mfa.tf` | 1.1 | Authentication methods policy with FIDO2, Authenticator number matching, SMS disabled |
| `hth-microsoft-entra-id-1.02-configure-emergency-access-accounts.tf` | 1.2 | Break-glass accounts with Global Admin role and CA exclusion group |
| `hth-microsoft-entra-id-2.01-block-legacy-authentication.tf` | 2.1 | Conditional Access policy blocking Basic Auth, POP, IMAP, SMTP AUTH |
| `hth-microsoft-entra-id-2.02-require-mfa-for-all-users.tf` | 2.2 | Conditional Access policy requiring MFA for all interactive sign-ins |
| `hth-microsoft-entra-id-4.01-restrict-user-consent-to-applications.tf` | 4.1 | Disable user OAuth consent, require admin approval |
| `hth-microsoft-entra-id-5.01-enable-sign-in-and-audit-logging.tf` | 5.1 | Diagnostic settings reference for log export (requires azurerm provider) |

### L2 -- Hardened (profile_level >= 2)

| File | Control | Description |
|------|---------|-------------|
| `hth-microsoft-entra-id-2.03-require-compliant-devices-for-admins.tf` | 2.3 | Require Intune-compliant or Hybrid AAD joined devices for admin access |
| `hth-microsoft-entra-id-2.04-block-high-risk-sign-ins.tf` | 2.4 | Block high-risk and remediate medium-risk sign-ins via Identity Protection |
| `hth-microsoft-entra-id-3.01-enable-just-in-time-access.tf` | 3.1 | PIM eligible assignments for Global Administrator role |
| `hth-microsoft-entra-id-3.02-configure-access-reviews.tf` | 3.2 | Access review configuration reference (requires Graph API or admin center) |
| `hth-microsoft-entra-id-4.02-review-and-restrict-application-permissions.tf` | 4.2 | Application permission audit data sources and high-risk permission list |

## Controls Requiring Manual Configuration

Some Entra ID features have limited Terraform provider support. These controls include configuration references and instructions for manual setup:

- **3.2 Access Reviews** -- Configure via Entra admin center: Identity governance > Access reviews
- **4.1 Admin Consent Workflow** -- Configure reviewers via: Applications > Enterprise applications > Consent and permissions
- **5.1 Diagnostic Settings** -- Requires the `azurerm` provider; uncomment the resource block and add the provider

## File Structure

```
packs/microsoft-entra-id/terraform/
  providers.tf                                                      # AzureAD provider configuration
  variables.tf                                                      # All input variables with validation
  outputs.tf                                                        # Control verification outputs
  terraform.tfvars.example                                          # Example variable values
  README.md                                                         # This file
  hth-microsoft-entra-id-1.01-enforce-phishing-resistant-mfa.tf     # Control 1.1 (L1)
  hth-microsoft-entra-id-1.02-configure-emergency-access-accounts.tf # Control 1.2 (L1)
  hth-microsoft-entra-id-2.01-block-legacy-authentication.tf        # Control 2.1 (L1)
  hth-microsoft-entra-id-2.02-require-mfa-for-all-users.tf         # Control 2.2 (L1)
  hth-microsoft-entra-id-2.03-require-compliant-devices-for-admins.tf # Control 2.3 (L2)
  hth-microsoft-entra-id-2.04-block-high-risk-sign-ins.tf          # Control 2.4 (L2)
  hth-microsoft-entra-id-3.01-enable-just-in-time-access.tf        # Control 3.1 (L2)
  hth-microsoft-entra-id-3.02-configure-access-reviews.tf          # Control 3.2 (L2)
  hth-microsoft-entra-id-4.01-restrict-user-consent-to-applications.tf # Control 4.1 (L1)
  hth-microsoft-entra-id-4.02-review-and-restrict-application-permissions.tf # Control 4.2 (L2)
  hth-microsoft-entra-id-5.01-enable-sign-in-and-audit-logging.tf  # Control 5.1 (L1)
```

## Testing Before Enforcement

Use Conditional Access report-only mode to test policies before enforcement:

```bash
# Deploy in report-only mode
terraform apply \
  -var="legacy_auth_policy_state=enabledForReportingButNotEnforced" \
  -var="mfa_policy_state=enabledForReportingButNotEnforced" \
  -var="high_risk_policy_state=enabledForReportingButNotEnforced"

# Review sign-in logs for impact, then enforce
terraform apply \
  -var="legacy_auth_policy_state=enabled" \
  -var="mfa_policy_state=enabled" \
  -var="high_risk_policy_state=enabled"
```

## Authentication

The AzureAD provider supports multiple authentication methods:

```bash
# Option 1: Azure CLI (interactive)
az login
terraform apply

# Option 2: Service principal (CI/CD)
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
export ARM_TENANT_ID="..."
terraform apply

# Option 3: Managed identity (Azure-hosted runners)
# No environment variables needed -- uses the VM's managed identity
```

## License

MIT -- See [LICENSE](../../../LICENSE) for details.
