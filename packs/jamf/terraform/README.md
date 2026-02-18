# Jamf Pro Hardening Code Pack - Terraform

Terraform configurations for the [Jamf Pro Hardening Guide](https://howtoharden.com/guides/jamf/) on How to Harden.

## Provider

This pack uses the community [deploymenttheory/jamfpro](https://registry.terraform.io/providers/deploymenttheory/jamfpro/latest/docs) Terraform provider.

## Prerequisites

- Terraform >= 1.0
- Jamf Pro instance with API access enabled
- OAuth2 API client credentials (Settings > API Integrations)
- API client must have sufficient privileges to create accounts, profiles, and webhooks

## Quick Start

```bash
cd packs/jamf/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Jamf Pro credentials and settings
terraform init
terraform plan
terraform apply
```

## Profile Levels

| Level | Name | Description |
|-------|------|-------------|
| 1 | Baseline | Essential controls for all organizations |
| 2 | Hardened | Adds CIS benchmarks, update deferral, extended SIEM logging |
| 3 | Maximum Security | Strictest firewall rules, all incoming blocked, signed app restrictions |

Levels are cumulative: L2 includes all L1 controls, L3 includes all L1+L2 controls.

```bash
# Apply L1 baseline controls
terraform apply -var="profile_level=1"

# Apply L2 hardened controls (includes L1)
terraform apply -var="profile_level=2"
```

## Controls Implemented

| File | Control | Level | Frameworks |
|------|---------|-------|------------|
| `hth-jamf-1.01-secure-console-access.tf` | RBAC roles and service accounts | L1 | CIS 5.4, NIST AC-6(1) |
| `hth-jamf-1.02-secure-api-access.tf` | Dedicated API integrations with scoped privileges | L1 | CIS 3.11, NIST SC-12 |
| `hth-jamf-2.01-configure-password-policies.tf` | Device password policy profile | L1 | CIS 5.2, NIST IA-5 |
| `hth-jamf-2.02-configure-filevault-encryption.tf` | FileVault enforcement with key escrow | L1 | CIS 3.11, NIST SC-28 |
| `hth-jamf-2.03-configure-firewall.tf` | macOS firewall with stealth mode | L1 | CIS 4.4, NIST SC-7 |
| `hth-jamf-2.04-configure-software-updates.tf` | Automatic updates with L2 deferral | L1 | CIS 7.3, NIST SI-2 |
| `hth-jamf-3.01-deploy-cis-benchmark-profiles.tf` | Gatekeeper, screen saver, SSH profiles | L2 | CIS 4.1, NIST CM-6 |
| `hth-jamf-3.02-monitor-cis-compliance.tf` | CIS compliance extension attribute and smart groups | L2 | CIS 4.1, NIST CA-7 |
| `hth-jamf-4.01-enable-audit-logging.tf` | SIEM webhook integration for audit events | L1 | CIS 8.2, NIST AU-2 |

## Authentication

Set credentials via environment variables (recommended for CI/CD):

```bash
export TF_VAR_jamfpro_instance_fqdn="yourorg.jamfcloud.com"
export TF_VAR_jamfpro_client_id="your-client-id"
export TF_VAR_jamfpro_client_secret="your-client-secret"
```

Or in `terraform.tfvars` (never commit this file):

```hcl
jamfpro_instance_fqdn = "yourorg.jamfcloud.com"
jamfpro_client_id     = "your-client-id"
jamfpro_client_secret = "your-client-secret"
```

## Resources Created

### L1 (Baseline)

- 3 API roles (Help Desk, Deployment, Security)
- 2 service accounts (Help Desk, Deployment)
- 1 API integration for security automation
- 4 macOS configuration profiles (password, FileVault, firewall, software updates)
- 1 disk encryption configuration
- 3 smart computer groups (FileVault, firewall, OS compliance)
- 3 webhooks (admin login, policy change, enrollment) -- if SIEM URL configured

### L2 (Hardened) -- adds to L1

- 1 hardened API integration with shorter token lifetime
- 1 software update deferral profile
- 3 CIS benchmark profiles (Gatekeeper, screen saver, remote login)
- 1 CIS compliance extension attribute
- 3 CIS compliance smart groups
- 3 additional SIEM webhooks (check-in, push, mobile enrollment)

### L3 (Maximum Security) -- adds to L1+L2

- Firewall blocks all incoming connections
- Signed app auto-allow disabled
- All L2 controls with strictest settings

## File Structure

```text
packs/jamf/terraform/
  providers.tf                                    # Provider configuration
  variables.tf                                    # All variable declarations
  outputs.tf                                      # Verification outputs
  terraform.tfvars.example                        # Example variable values
  README.md                                       # This file
  hth-jamf-1.01-secure-console-access.tf          # RBAC roles & accounts
  hth-jamf-1.02-secure-api-access.tf              # API integrations
  hth-jamf-2.01-configure-password-policies.tf    # Password policy profile
  hth-jamf-2.02-configure-filevault-encryption.tf # FileVault enforcement
  hth-jamf-2.03-configure-firewall.tf             # Firewall profile
  hth-jamf-2.04-configure-software-updates.tf     # Software update profile
  hth-jamf-3.01-deploy-cis-benchmark-profiles.tf  # CIS benchmark profiles
  hth-jamf-3.02-monitor-cis-compliance.tf         # CIS compliance monitoring
  hth-jamf-4.01-enable-audit-logging.tf           # SIEM webhooks
```
