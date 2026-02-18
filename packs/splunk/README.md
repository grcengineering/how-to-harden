# Splunk Hardening Code Pack

Runnable security hardening artifacts for [Splunk](https://howtoharden.com/guides/splunk/). Implements controls from the Splunk Cloud hardening guide across authentication, access controls, data security, and monitoring.

## What's Included

| Component | Count | Description |
|-----------|-------|-------------|
| Terraform | 8 | Per-control `.tf` files for controls 1.1, 1.2, 2.1, 2.2, 3.1, 3.2, 4.1 |

## Prerequisites

- Splunk Cloud or Splunk Enterprise instance with **admin** access
- Authentication token or admin credentials with appropriate permissions
- [Terraform](https://www.terraform.io/) >= 1.0 with the [splunk/splunk provider](https://registry.terraform.io/providers/splunk/splunk/latest) (~> 1.4)
- Network access to Splunk management port (typically 8089)

## Quick Start

### Terraform (Declarative)

```bash
cd packs/splunk/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set splunk_url and authentication credentials

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
| L1 -- Baseline | `1` | SAML SSO, local admin fallback, RBAC roles, index access controls, security/audit indexes, search limits, HEC SSL, audit alerts |
| L2 -- Hardened | `2` | L1 + restricted power/auditor roles, threat intel index, hardened search limits, TLS 1.2 enforcement, config change alerts, sensitive index access alerts |
| L3 -- Maximum Security | `3` | L1 + L2 + maximum search restrictions, TLS 1.3 enforcement |

Set `profile_level` (Terraform variable) once. Every resource respects it.

## Directory Structure

```
splunk/
├── README.md
└── terraform/                                         # Per-control Terraform files
    ├── providers.tf                                   # Provider configuration
    ├── variables.tf                                   # Input variables
    ├── outputs.tf                                     # Output values
    ├── terraform.tfvars.example                       # Example variable values
    ├── hth-splunk-1.1-configure-saml-sso.tf
    ├── hth-splunk-1.2-configure-local-admin-fallback.tf
    ├── hth-splunk-2.1-configure-rbac.tf
    ├── hth-splunk-2.2-configure-index-access.tf
    ├── hth-splunk-3.1-configure-search-security.tf
    ├── hth-splunk-3.2-configure-encryption.tf
    └── hth-splunk-4.1-configure-audit-logging.tf
```

## Naming Convention

All files follow: `hth-{vendor}-{section}.{subsection}-{control-title}.{ext}`

- **Terraform**: `hth-splunk-1.1-configure-saml-sso.tf`
- **Shared files**: `providers.tf`, `variables.tf`, `outputs.tf`

## Terraform Coverage

Each control with Terraform support has its own `.tf` file:

| Control | File | Description |
|---------|------|-------------|
| 1.1 | `hth-splunk-1.1-configure-saml-sso.tf` | SAML SSO via authentication.conf |
| 1.2 | `hth-splunk-1.2-configure-local-admin-fallback.tf` | Emergency local admin account |
| 2.1 | `hth-splunk-2.1-configure-rbac.tf` | Security analyst, restricted power, auditor roles |
| 2.2 | `hth-splunk-2.2-configure-index-access.tf` | Security, audit trail, threat intel indexes |
| 3.1 | `hth-splunk-3.1-configure-search-security.tf` | Search quotas and concurrency limits |
| 3.2 | `hth-splunk-3.2-configure-encryption.tf` | HEC SSL, TLS 1.2/1.3 enforcement |
| 4.1 | `hth-splunk-4.1-configure-audit-logging.tf` | Audit trail inputs and alert saved searches |

## Compliance Coverage

| Framework | Controls Mapped |
|-----------|----------------|
| CIS Controls | 3.3, 3.11, 5.4, 6.3, 8.2, 12.5 |
| NIST 800-53 | AC-3, AC-6, AU-2, IA-2, IA-8, SC-8, SC-28 |

## Key Splunk Terraform Resources Used

| Resource | Purpose |
|----------|---------|
| `splunk_authentication_users` | Local user/admin account management |
| `splunk_authorization_roles` | Role-based access control |
| `splunk_indexes` | Index creation and configuration |
| `splunk_global_http_event_collector` | HEC endpoint configuration |
| `splunk_configs_conf` | General conf file management (authentication.conf, limits.conf, server.conf, web.conf) |
| `splunk_saved_searches` | Audit alert saved searches |

## Related

- [Splunk Hardening Guide](https://howtoharden.com/guides/splunk/) -- Full guide with ClickOps + Code implementations
- [How to Harden](https://howtoharden.com) -- All vendor hardening guides
- [Code Packs Overview](../README.md) -- Architecture and schema documentation
