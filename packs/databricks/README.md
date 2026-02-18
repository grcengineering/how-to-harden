# Databricks Hardening Code Pack

Runnable security hardening artifacts for [Databricks](https://howtoharden.com/guides/databricks/). Implements controls from the Databricks hardening guide across authentication, Unity Catalog governance, cluster security, secrets management, and monitoring.

## What's Included

| Component | Count | Description |
|-----------|-------|-------------|
| Terraform | 10 | Per-control `.tf` files for controls 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 3.1, 3.2, 4.1, 4.2, 5.1 |

## Prerequisites

- Databricks workspace with **Admin** access
- Personal access token or service principal token with workspace admin permissions
- [Terraform](https://www.terraform.io/) >= 1.0 with the [databricks/databricks provider](https://registry.terraform.io/providers/databricks/databricks/latest) (for Terraform)
- Databricks Premium or Enterprise edition (IP Access Lists, Unity Catalog features)

## Quick Start

### Terraform (Declarative)

```bash
cd packs/databricks/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set databricks_workspace_url and databricks_token

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
| L1 -- Baseline | `1` | SSO enforcement, service principals, Unity Catalog governance, audit logging, cluster policies, secret scopes, security monitoring |
| L2 -- Hardened | `2` | L1 + IP access lists, data masking, network isolation, external secret store, results download disabled |
| L3 -- Maximum Security | `3` | L1 + L2 + notebook export disabled, strictest workspace restrictions |

Set `profile_level` (Terraform variable) once. Every resource respects it.

## Directory Structure

```
databricks/
├── README.md
└── terraform/                                            # Per-control Terraform files
    ├── providers.tf                                      # Provider configuration
    ├── variables.tf                                      # Input variables
    ├── outputs.tf                                        # Output values
    ├── terraform.tfvars.example                          # Example variable values
    ├── hth-databricks-1.01-enforce-sso-with-mfa.tf
    ├── hth-databricks-1.02-service-principal-security.tf
    ├── hth-databricks-1.03-ip-access-lists.tf
    ├── hth-databricks-2.01-data-governance.tf
    ├── hth-databricks-2.02-data-masking.tf
    ├── hth-databricks-2.03-audit-logging.tf
    ├── hth-databricks-3.01-cluster-policies.tf
    ├── hth-databricks-3.02-network-isolation.tf
    ├── hth-databricks-4.01-secret-scopes.tf
    ├── hth-databricks-4.02-external-secret-store.tf
    └── hth-databricks-5.01-security-monitoring.tf
```

## Naming Convention

All files follow: `hth-{vendor}-{section}-{control-title}.{ext}`

- **Terraform**: `hth-databricks-1.01-enforce-sso-with-mfa.tf`
- **Shared files**: `providers.tf`, `variables.tf`, `outputs.tf`

## Terraform Coverage

Each control with Terraform support has its own `.tf` file:

| Control | File | Description |
|---------|------|-------------|
| 1.1 | `hth-databricks-1.01-enforce-sso-with-mfa.tf` | Workspace conf for SSO enforcement |
| 1.2 | `hth-databricks-1.02-service-principal-security.tf` | Service principals + RBAC permissions |
| 1.3 | `hth-databricks-1.03-ip-access-lists.tf` | IP allowlist + blocklist (L2+) |
| 2.1 | `hth-databricks-2.01-data-governance.tf` | Unity Catalog workspace settings |
| 2.2 | `hth-databricks-2.02-data-masking.tf` | Table access control for masking (L2+) |
| 2.3 | `hth-databricks-2.03-audit-logging.tf` | Audit log configuration + export controls |
| 3.1 | `hth-databricks-3.01-cluster-policies.tf` | Hardened cluster policy + permissions |
| 3.2 | `hth-databricks-3.02-network-isolation.tf` | Network isolation policy (L2+) |
| 4.1 | `hth-databricks-4.01-secret-scopes.tf` | Databricks-backed secret scopes + ACLs |
| 4.2 | `hth-databricks-4.02-external-secret-store.tf` | Azure Key Vault-backed scope (L2+) |
| 5.1 | `hth-databricks-5.01-security-monitoring.tf` | Workspace security settings + detection queries |

Controls not covered by Terraform (Unity Catalog SQL grants, data masking functions, detection queries) require Databricks SQL or CLI.

## Compliance Coverage

| Framework | Controls Mapped |
|-----------|----------------|
| SOC 2 | CC6.1, CC6.2, CC6.6, CC6.7, CC7.2, CC7.3 |
| NIST 800-53 | AC-3, AC-3(7), AU-2, AU-3, CM-7, IA-2(1), IA-5, SC-7, SC-28, SI-4 |
| ISO 27001 | A.9.2, A.9.4, A.12.4 |
| PCI DSS v4.0 | 8.3, 8.4, 10.2 |

## Edition Compatibility

| Control | Standard | Premium | Enterprise |
|---------|----------|---------|------------|
| SSO (SAML) | -- | Yes | Yes |
| Unity Catalog | Yes | Yes | Yes |
| IP Access Lists | -- | Yes | Yes |
| Customer-Managed VPC | -- | Yes | Yes |
| Private Link | -- | -- | Yes |

## Related

- [Databricks Hardening Guide](https://howtoharden.com/guides/databricks/) -- Full guide with ClickOps + Code implementations
- [How to Harden](https://howtoharden.com) -- All vendor hardening guides
- [Code Packs Overview](../README.md) -- Architecture and schema documentation
