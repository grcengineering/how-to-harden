# Datadog Hardening Code Pack

Runnable security hardening artifacts for [Datadog](https://howtoharden.com/guides/datadog/). Implements controls from the Datadog hardening guide across authentication, access control, key management, and audit monitoring.

## What's Included

| Component | Count | Description |
|-----------|-------|-------------|
| Terraform | 7 | Per-control `.tf` files for controls 1.1, 1.2, 1.3, 2.1, 3.1, 3.2, 4.1 |

## Prerequisites

- Datadog organization with **Admin** access
- API key and Application key with appropriate permissions (`Organization Settings > API Keys / Application Keys`)
- [Terraform](https://www.terraform.io/) >= 1.0 with the [datadog/datadog provider](https://registry.terraform.io/providers/DataDog/datadog/latest) (for Terraform)

## Quick Start

### Terraform (Declarative)

```bash
cd packs/datadog/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set datadog_api_key and datadog_app_key

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
| L1 -- Baseline | `1` | SAML SSO, session monitoring, RBAC, API key management, application key management, audit log monitoring |
| L2 -- Hardened | `2` | L1 + SAML strict mode, SAML change detection alerts |
| L3 -- Maximum Security | `3` | L1 + L2 (all controls enforced at strictest settings) |

Set `profile_level` (Terraform variable) once. Every resource respects it.

## Directory Structure

```
datadog/
├── README.md
└── terraform/                                            # Per-control Terraform files
    ├── providers.tf                                      # Provider configuration
    ├── variables.tf                                      # Input variables
    ├── outputs.tf                                        # Output values
    ├── terraform.tfvars.example                          # Example variable values
    ├── hth-datadog-1.01-configure-saml-sso.tf
    ├── hth-datadog-1.02-enable-saml-strict-mode.tf
    ├── hth-datadog-1.03-configure-session-security.tf
    ├── hth-datadog-2.01-configure-rbac.tf
    ├── hth-datadog-3.01-secure-api-keys.tf
    ├── hth-datadog-3.02-secure-application-keys.tf
    └── hth-datadog-4.01-configure-audit-logs.tf
```

## Naming Convention

All files follow: `hth-{vendor}-{section}-{control-title}.{ext}`

- **Terraform**: `hth-datadog-1.01-configure-saml-sso.tf`
- **Shared files**: `providers.tf`, `variables.tf`, `outputs.tf`

## Terraform Coverage

Each control with Terraform support has its own `.tf` file:

| Control | File | Description |
|---------|------|-------------|
| 1.1 | `hth-datadog-1.01-configure-saml-sso.tf` | SAML SSO organization settings |
| 1.2 | `hth-datadog-1.02-enable-saml-strict-mode.tf` | SAML strict mode enforcement (L2+) |
| 1.3 | `hth-datadog-1.03-configure-session-security.tf` | Session idle timeout monitoring |
| 2.1 | `hth-datadog-2.01-configure-rbac.tf` | Custom roles + admin assignment detection |
| 3.1 | `hth-datadog-3.01-secure-api-keys.tf` | Managed API keys + lifecycle monitoring |
| 3.2 | `hth-datadog-3.02-secure-application-keys.tf` | Managed app keys + lifecycle monitoring |
| 4.1 | `hth-datadog-4.01-configure-audit-logs.tf` | Org settings, user access, SAML monitoring |

## Compliance Coverage

| Framework | Controls Mapped |
|-----------|----------------|
| SOC 2 | CC6.1, CC6.2, CC6.6, CC6.7, CC7.2 |
| NIST 800-53 | AC-6, AC-12, AU-2, IA-2, IA-8, SC-12 |
| CIS Controls | 3.11, 5.4, 6.2, 6.3, 8.2, 12.5 |

## Related

- [Datadog Hardening Guide](https://howtoharden.com/guides/datadog/) -- Full guide with ClickOps + Code implementations
- [How to Harden](https://howtoharden.com) -- All vendor hardening guides
- [Code Packs Overview](../README.md) -- Architecture and schema documentation
