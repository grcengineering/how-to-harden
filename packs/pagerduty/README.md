# PagerDuty Hardening Code Pack

Runnable security hardening artifacts for [PagerDuty](https://howtoharden.com/guides/pagerduty/). Implements controls from the PagerDuty hardening guide across authentication, user management, access controls, and monitoring.

## What's Included

| Component | Count | Description |
|-----------|-------|-------------|
| Terraform | 7 | Per-control `.tf` files for controls 1.1, 1.3, 2.1, 2.2, 3.1, 3.2, 4.1 |

## Prerequisites

- PagerDuty **Professional, Business, or Enterprise** plan
- API token with account-level access (`Integrations > API Access Keys`)
- [Terraform](https://www.terraform.io/) >= 1.0 with the [PagerDuty/pagerduty provider](https://registry.terraform.io/providers/PagerDuty/pagerduty/latest) (for Terraform)
- `bash`, `curl`, `jq` (for API-based audit checks within Terraform provisioners)

## Quick Start

### Terraform (Declarative)

```bash
cd packs/pagerduty/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set pagerduty_api_token and other values

terraform init
terraform plan -var="profile_level=1"   # Preview L1 changes
terraform apply -var="profile_level=1"  # Apply L1 (Baseline)
terraform apply -var="profile_level=2"  # Apply L1 + L2 (Hardened)
terraform apply -var="profile_level=3"  # Apply all controls
```

## Profile Levels

Controls are gated by cumulative profile levels:

| Level | Variable Value | What Gets Applied |
|-------|---------------|-------------------|
| L1 -- Baseline | `1` | SAML SSO guidance, account owner fallback audit, user provisioning, RBAC teams, admin count audit, audit logging + SIEM webhook |
| L2 -- Hardened | `2` | L1 + SCIM provisioning validation, observer role assignments |
| L3 -- Maximum Security | `3` | L1 + L2 (all controls applied at maximum strictness) |

Set `profile_level` (Terraform variable) once. Every resource respects it.

## Directory Structure

```
pagerduty/
├── README.md
└── terraform/                                            # Per-control Terraform files
    ├── providers.tf                                      # Provider configuration
    ├── variables.tf                                      # Input variables
    ├── outputs.tf                                        # Output values
    ├── terraform.tfvars.example                          # Example variable values
    ├── hth-pagerduty-1.01-configure-saml-sso.tf
    ├── hth-pagerduty-1.03-configure-account-owner-fallback.tf
    ├── hth-pagerduty-2.01-configure-user-provisioning.tf
    ├── hth-pagerduty-2.02-configure-scim-provisioning.tf
    ├── hth-pagerduty-3.01-configure-role-based-access.tf
    ├── hth-pagerduty-3.02-limit-admin-access.tf
    └── hth-pagerduty-4.01-configure-audit-logging.tf
```

## Naming Convention

All files follow: `hth-{vendor}-{section}-{control-title}.{ext}`

- **Terraform**: `hth-pagerduty-1.01-configure-saml-sso.tf`
- **Shared files**: `providers.tf`, `variables.tf`, `outputs.tf`

## Controls

### Section 1 -- Authentication & SSO (3 controls)

| # | Control | Level |
|---|---------|-------|
| 1.1 | Configure SAML Single Sign-On | L1 |
| 1.2 | Manage SSO Certificate Rotation | L1 |
| 1.3 | Configure Account Owner Fallback | L1 |

### Section 2 -- User Management (2 controls)

| # | Control | Level |
|---|---------|-------|
| 2.1 | Configure User Provisioning | L1 |
| 2.2 | Configure SCIM Provisioning | L2 |

### Section 3 -- Access Controls (2 controls)

| # | Control | Level |
|---|---------|-------|
| 3.1 | Configure Role-Based Access | L1 |
| 3.2 | Limit Admin Access | L1 |

### Section 4 -- Monitoring & Security (1 control)

| # | Control | Level |
|---|---------|-------|
| 4.1 | Configure Audit Logging | L1 |

## Terraform Coverage

Each control with Terraform support has its own `.tf` file:

| Control | File | Description |
|---------|------|-------------|
| 1.1 | `hth-pagerduty-1.01-configure-saml-sso.tf` | SAML SSO configuration guidance + API validation |
| 1.3 | `hth-pagerduty-1.03-configure-account-owner-fallback.tf` | Account owner identification + credential hygiene audit |
| 2.1 | `hth-pagerduty-2.01-configure-user-provisioning.tf` | SAML on-demand provisioning validation |
| 2.2 | `hth-pagerduty-2.02-configure-scim-provisioning.tf` | SCIM endpoint validation + setup guidance (L2) |
| 3.1 | `hth-pagerduty-3.01-configure-role-based-access.tf` | Team creation + observer role assignment |
| 3.2 | `hth-pagerduty-3.02-limit-admin-access.tf` | Admin count audit + enforcement |
| 4.1 | `hth-pagerduty-4.01-configure-audit-logging.tf` | Audit log webhook + SIEM integration |

Controls not covered by Terraform (1.2 SSO Certificate Rotation) require manual configuration via the PagerDuty UI.

## Compliance Coverage

| Framework | Controls Mapped |
|-----------|----------------|
| CIS Controls | 3.11, 5.3, 5.4, 6.3, 8.2, 12.5 |
| NIST 800-53 | AC-2, AC-6, AC-6(1), AU-2, IA-2, IA-8, SC-12 |

## Related

- [PagerDuty Hardening Guide](https://howtoharden.com/guides/pagerduty/) -- Full guide with ClickOps + Code implementations
- [How to Harden](https://howtoharden.com) -- All vendor hardening guides
- [Code Packs Overview](../README.md) -- Architecture and schema documentation
