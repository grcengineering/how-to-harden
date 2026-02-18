# Snyk Hardening Code Pack

Runnable security hardening artifacts for [Snyk](https://howtoharden.com/guides/snyk/). Implements controls from the Snyk hardening guide across authentication, integration security, data security, and monitoring.

## What's Included

| Component | Count | Description |
|-----------|-------|-------------|
| Terraform | 8 | Per-control `.tf` files for controls 1.1, 1.2, 2.1, 2.2, 3.1, 3.2, 4.1 |

## Prerequisites

- Snyk organization with **Org Admin** or **Group Admin** access
- Snyk API token with appropriate permissions (`Settings > General > Auth Token`)
- [Terraform](https://www.terraform.io/) >= 1.0 with the [snyk/snyk provider](https://registry.terraform.io/providers/snyk/snyk/latest) (for Terraform)
- Snyk Business or Enterprise plan (for SSO, Broker, and Audit Logs)

## Quick Start

### Terraform (Declarative)

```bash
cd packs/snyk/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set snyk_api_token and snyk_org_id

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
| L1 -- Baseline | `1` | SSO enforcement, role-based access, service account governance, SCM integration security, project visibility, vulnerability notifications, audit log monitoring |
| L2 -- Hardened | `2` | L1 + ignore policy governance (required reasons, expiration), Broker for private repos, stricter project visibility |
| L3 -- Maximum Security | `3` | L1 + L2 + all controls enforced at strictest settings for regulated industries |

Set `profile_level` (Terraform variable) once. Every resource respects it.

## Directory Structure

```
snyk/
├── README.md
└── terraform/                                          # Per-control Terraform files
    ├── providers.tf                                    # Provider configuration (snyk/snyk ~> 0.1)
    ├── variables.tf                                    # Input variables
    ├── outputs.tf                                      # Output values
    ├── terraform.tfvars.example                        # Example variable values
    ├── hth-snyk-1.01-enforce-sso-mfa.tf               # SSO with MFA enforcement
    ├── hth-snyk-1.02-role-based-access.tf              # Role-based access control
    ├── hth-snyk-2.01-secure-service-account-tokens.tf  # Service account governance
    ├── hth-snyk-2.02-scm-integration-security.tf       # SCM + Broker integration
    ├── hth-snyk-3.01-project-visibility.tf             # Project visibility settings
    ├── hth-snyk-3.02-ignore-policy.tf                  # Ignore policy governance (L2)
    └── hth-snyk-4.01-audit-logs-notifications.tf       # Notifications + audit log config
```

## Naming Convention

All files follow: `hth-{vendor}-{section}-{control-title}.{ext}`

- **Terraform**: `hth-snyk-1.01-enforce-sso-mfa.tf`
- **Shared files**: `providers.tf`, `variables.tf`, `outputs.tf`

## Terraform Coverage

Each control with Terraform support has its own `.tf` file:

| Control | File | Description |
|---------|------|-------------|
| 1.1 | `hth-snyk-1.01-enforce-sso-mfa.tf` | SSO enforcement + MFA requirement |
| 1.2 | `hth-snyk-1.02-role-based-access.tf` | Least-privilege role assignments |
| 2.1 | `hth-snyk-2.01-secure-service-account-tokens.tf` | Service account lifecycle governance |
| 2.2 | `hth-snyk-2.02-scm-integration-security.tf` | SCM integration + Broker setup |
| 3.1 | `hth-snyk-3.01-project-visibility.tf` | Project visibility restrictions |
| 3.2 | `hth-snyk-3.02-ignore-policy.tf` | Ignore expiration + reason requirements |
| 4.1 | `hth-snyk-4.01-audit-logs-notifications.tf` | Notification settings + audit log guidance |

Controls not covered by Terraform require API scripts or manual configuration.

## Provider Notes

The Snyk Terraform provider (`snyk/snyk`) is currently in **open beta** on the Terraform Registry. Some resources may have limited functionality compared to the full REST API. Where the provider lacks coverage, control files include REST API examples and reference the companion API scripts.

Key provider resources used:
- `snyk_organization` -- Organization-level settings and policies
- `snyk_integration` -- SCM and Broker integration configuration
- `snyk_notification_setting` -- Vulnerability and report notifications
- `data.snyk_organization` -- Read-only organization data source

## Compliance Coverage

| Framework | Controls Mapped |
|-----------|----------------|
| SOC 2 | CC6.1, CC6.6, CC7.2, CC7.3, CC8.1 |
| NIST 800-53 | AC-3, AC-6, AC-21, AU-2, AU-3, CM-7, IA-2, IA-5, RA-5, SI-4 |
| ISO 27001 | A.9.2, A.9.4, A.12.4, A.12.6 |
| PCI DSS v4.0 | 6.1, 8.3, 10.2 |

## Related

- [Snyk Hardening Guide](https://howtoharden.com/guides/snyk/) -- Full guide with ClickOps + Code implementations
- [How to Harden](https://howtoharden.com) -- All vendor hardening guides
- [Code Packs Overview](../README.md) -- Architecture and schema documentation
