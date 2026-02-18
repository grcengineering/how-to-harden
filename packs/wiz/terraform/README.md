# Wiz Hardening Code Pack -- Terraform

Declarative security hardening for [Wiz](https://howtoharden.com/guides/wiz/) using the [AxtonGrams/wiz Terraform provider](https://registry.terraform.io/providers/AxtonGrams/wiz/latest/docs). Implements 8 controls from the Wiz hardening guide across authentication, cloud connector security, API security, data protection, and monitoring.

## Prerequisites

- Wiz tenant with **Global Admin** access
- Service account with appropriate scopes (`Settings > Service Accounts`)
- [Terraform](https://www.terraform.io/) >= 1.0 with the [AxtonGrams/wiz provider](https://registry.terraform.io/providers/AxtonGrams/wiz/latest)

## Quick Start

```bash
cd packs/wiz/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set wiz_url and credentials

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
| L1 -- Baseline | `1` | SSO enforcement, RBAC, cloud connector hardening, service account management, audit logging |
| L2 -- Hardened | `2` | L1 + credential rotation monitoring, API access monitoring, data export controls |
| L3 -- Maximum Security | `3` | L1 + L2 (reserved for future strictest controls) |

Set `profile_level` once. Every resource respects it.

## Controls

| # | Control | Level | File |
|---|---------|-------|------|
| 1.1 | Enforce SSO with MFA | L1 | `hth-wiz-1.01-enforce-sso-with-mfa.tf` |
| 1.2 | Implement RBAC | L1 | `hth-wiz-1.02-implement-rbac.tf` |
| 2.1 | Secure Cloud Connector Configuration | L1 | `hth-wiz-2.01-secure-cloud-connector-configuration.tf` |
| 2.2 | Connector Credential Rotation | L2 | `hth-wiz-2.02-connector-credential-rotation.tf` |
| 3.1 | Service Account Management | L1 | `hth-wiz-3.01-service-account-management.tf` |
| 3.2 | API Access Monitoring | L2 | `hth-wiz-3.02-api-access-monitoring.tf` |
| 4.1 | Data Export Controls | L2 | `hth-wiz-4.01-configure-data-export-controls.tf` |
| 5.1 | Audit Logging | L1 | `hth-wiz-5.01-audit-logging.tf` |

## Directory Structure

```
wiz/terraform/
├── README.md
├── providers.tf                                      # Provider configuration
├── variables.tf                                      # Input variables
├── outputs.tf                                        # Output values
├── terraform.tfvars.example                          # Example variable values
├── hth-wiz-1.01-enforce-sso-with-mfa.tf             # SAML SSO with MFA
├── hth-wiz-1.02-implement-rbac.tf                   # Role-based access control
├── hth-wiz-2.01-secure-cloud-connector-configuration.tf  # Cloud connector hardening
├── hth-wiz-2.02-connector-credential-rotation.tf    # Credential rotation (L2)
├── hth-wiz-3.01-service-account-management.tf       # Service account management
├── hth-wiz-3.02-api-access-monitoring.tf            # API access monitoring (L2)
├── hth-wiz-4.01-configure-data-export-controls.tf   # Data export controls (L2)
└── hth-wiz-5.01-audit-logging.tf                    # Audit logging
```

## Naming Convention

All files follow: `hth-wiz-{section.number}-{kebab-case-slug}.tf`

## Compliance Coverage

| Framework | Controls Mapped |
|-----------|----------------|
| SOC 2 | CC6.1, CC6.2, CC6.7 |
| NIST 800-53 | AC-3, AC-6, AU-2, AU-3, AU-6, IA-2(1), IA-5, IA-5(1) |

## Related

- [Wiz Hardening Guide](https://howtoharden.com/guides/wiz/) -- Full guide with ClickOps + Code implementations
- [How to Harden](https://howtoharden.com) -- All vendor hardening guides
