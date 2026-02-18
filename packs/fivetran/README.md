# Fivetran Hardening Code Pack

Runnable security hardening artifacts for [Fivetran](https://howtoharden.com/guides/fivetran/). Implements controls from the Fivetran hardening guide across authentication, access control, connector security, and monitoring.

## What's Included

| Component | Count | Description |
|-----------|-------|-------------|
| Terraform | 10 | Per-control `.tf` files for controls 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 4.1, 4.2, 4.3 |

## Prerequisites

- Fivetran account with **Account Administrator** role
- API key and API secret with appropriate permissions (`Account Settings > API Config`)
- [Terraform](https://www.terraform.io/) >= 1.0 with the [fivetran/fivetran provider](https://registry.terraform.io/providers/fivetran/fivetran/latest) (for Terraform)
- SAML 2.0 compatible identity provider (for SSO controls)

## Quick Start

### Terraform (Declarative)

```bash
cd packs/fivetran/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set fivetran_api_key and fivetran_api_secret

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
| L1 -- Baseline | `1` | SAML SSO, session timeout, RBAC, connector security, destination security, activity logging, sync monitoring |
| L2 -- Hardened | `2` | L1 + SSO enforcement, JIT provisioning, team structure, SCIM, network security, data governance |
| L3 -- Maximum Security | `3` | L1 + L2 + PrivateLink, strictest session timeouts (all controls at maximum settings) |

Set `profile_level` (Terraform variable) once. Every resource respects it.

## Directory Structure

```
fivetran/
├── README.md
└── terraform/                                                  # Per-control Terraform files
    ├── providers.tf                                            # Provider configuration
    ├── variables.tf                                            # Input variables
    ├── outputs.tf                                              # Output values
    ├── terraform.tfvars.example                                # Example variable values
    ├── hth-fivetran-1.01-configure-saml-sso.tf
    ├── hth-fivetran-1.02-restrict-authentication-to-sso.tf
    ├── hth-fivetran-1.03-configure-jit-provisioning.tf
    ├── hth-fivetran-1.04-configure-session-timeout.tf
    ├── hth-fivetran-2.01-configure-rbac.tf
    ├── hth-fivetran-2.02-configure-team-structure.tf
    ├── hth-fivetran-2.03-configure-scim-provisioning.tf
    ├── hth-fivetran-3.01-secure-connector-credentials.tf
    ├── hth-fivetran-3.02-configure-network-security.tf
    ├── hth-fivetran-3.03-configure-destination-security.tf
    ├── hth-fivetran-4.01-configure-activity-logging.tf
    ├── hth-fivetran-4.02-configure-sync-monitoring.tf
    └── hth-fivetran-4.03-data-governance.tf
```

## Naming Convention

All files follow: `hth-{vendor}-{section}-{control-title}.{ext}`

- **Terraform**: `hth-fivetran-1.01-configure-saml-sso.tf`
- **Shared files**: `providers.tf`, `variables.tf`, `outputs.tf`

## Terraform Coverage

Each control with Terraform support has its own `.tf` file:

| Control | File | Profile | Description |
|---------|------|---------|-------------|
| 1.1 | `hth-fivetran-1.01-configure-saml-sso.tf` | L1 | SAML SSO configuration via API |
| 1.2 | `hth-fivetran-1.02-restrict-authentication-to-sso.tf` | L2 | SAML-only authentication enforcement |
| 1.3 | `hth-fivetran-1.03-configure-jit-provisioning.tf` | L2 | Just-In-Time user provisioning |
| 1.4 | `hth-fivetran-1.04-configure-session-timeout.tf` | L1 | Session timeout configuration |
| 2.1 | `hth-fivetran-2.01-configure-rbac.tf` | L1 | Role-based access control + admin audit |
| 2.2 | `hth-fivetran-2.02-configure-team-structure.tf` | L2 | Team creation and user assignment |
| 2.3 | `hth-fivetran-2.03-configure-scim-provisioning.tf` | L2 | SCIM token generation and setup guide |
| 3.1 | `hth-fivetran-3.01-secure-connector-credentials.tf` | L1 | Managed connectors with least-privilege |
| 3.2 | `hth-fivetran-3.02-configure-network-security.tf` | L2 | IP allowlisting and SSH tunnel guidance |
| 3.3 | `hth-fivetran-3.03-configure-destination-security.tf` | L1 | Destination config with TLS validation |
| 4.1 | `hth-fivetran-4.01-configure-activity-logging.tf` | L1 | Webhook-based activity log streaming |
| 4.2 | `hth-fivetran-4.02-configure-sync-monitoring.tf` | L1 | Sync failure alerts and health checks |
| 4.3 | `hth-fivetran-4.03-data-governance.tf` | L2 | Column blocking and hashing for PII |

## Compliance Coverage

| Framework | Controls Mapped |
|-----------|----------------|
| SOC 2 | CC6.1, CC6.2, CC6.6, CC6.7, CC7.2 |
| NIST 800-53 | AC-2, AC-3, AC-6, AC-6(1), AC-12, AC-17, AU-2, CA-7, IA-2, IA-8, SC-8, SC-12 |
| CIS Controls | 3.1, 3.11, 5.3, 5.4, 6.2, 6.3, 8.2, 12.5, 13.5 |

## Related

- [Fivetran Hardening Guide](https://howtoharden.com/guides/fivetran/) -- Full guide with ClickOps + Code implementations
- [How to Harden](https://howtoharden.com) -- All vendor hardening guides
- [Code Packs Overview](../README.md) -- Architecture and schema documentation
