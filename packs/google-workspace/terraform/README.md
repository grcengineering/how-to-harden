# Google Workspace Hardening - Terraform Code Pack

Terraform configuration for [Google Workspace](https://howtoharden.com/guides/google-workspace/) security hardening. Implements organizational infrastructure for all 9 controls from the Google Workspace hardening guide across authentication, network security, OAuth governance, data security, and monitoring.

## What's Included

| Component | Count | Description |
|-----------|-------|-------------|
| Terraform | 8 | Per-control `.tf` files for controls 1.1, 1.2, 1.3, 2.1, 3.1, 3.2, 4.1, 4.2, 5.1 |

## Prerequisites

- Google Workspace **Business Standard** or higher (Enterprise for DLP and Context-Aware Access)
- Service account with [domain-wide delegation](https://developers.google.com/workspace/guides/create-credentials)
- GCP project (for Access Context Manager, DLP, and BigQuery resources at L2+)
- [Terraform](https://www.terraform.io/) >= 1.0 with the [hashicorp/googleworkspace provider](https://registry.terraform.io/providers/hashicorp/googleworkspace/latest) (~> 0.7)

## Quick Start

```bash
cd packs/google-workspace/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set customer_id, credentials, domain, etc.

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
| L1 -- Baseline | `1` | MFA enforcement OU, delegated admin roles, Super Admin OU, OAuth governance groups, legacy app tracking, Drive sharing OUs, audit log BigQuery export, security alert groups |
| L2 -- Hardened | `2` | L1 + Context-Aware Access (managed device), Admin Console IP restrictions, OAuth restricted OU, no-external-sharing OU, DLP inspect templates, BigQuery detection views |
| L3 -- Maximum Security | `3` | L1 + L2 + security-key-only Super Admin OU, corporate-owned device access level, combined IP + device access level, regulated data DLP template |

Set `profile_level` once. Every resource respects it.

## Providers

This pack uses two Terraform providers:

| Provider | Purpose |
|----------|---------|
| `hashicorp/googleworkspace` ~> 0.7 | Workspace resources (users, groups, OUs, roles) |
| `hashicorp/google` ~> 5.0 | GCP resources (Access Context Manager, DLP, BigQuery) |

## Terraform Coverage

Each control has its own `.tf` file:

| Control | File | Level | Description |
|---------|------|-------|-------------|
| 1.1 | `hth-google-workspace-1.01-enforce-mfa.tf` | L1 | MFA enforcement OU + 2SV tracking group |
| 1.2 | `hth-google-workspace-1.02-restrict-super-admin.tf` | L1 | Delegated admin roles + Super Admin OU |
| 1.3 | `hth-google-workspace-1.03-configure-context-aware-access.tf` | L2 | Access Context Manager device policies |
| 2.1 | `hth-google-workspace-2.01-restrict-admin-ip-ranges.tf` | L2 | Admin Console IP allowlist access levels |
| 3.1 | `hth-google-workspace-3.01-enable-oauth-app-whitelisting.tf` | L1 | OAuth governance groups + restricted OU |
| 3.2 | `hth-google-workspace-3.02-disable-less-secure-apps.tf` | L1 | Legacy app tracking group + exception OU |
| 4.1 | `hth-google-workspace-4.01-restrict-external-drive-sharing.tf` | L1 | Drive sharing OUs + approver groups |
| 4.2 | `hth-google-workspace-4.02-enable-dlp.tf` | L2 | Cloud DLP inspect templates (PII + regulated) |
| 5.1 | `hth-google-workspace-5.01-enable-audit-logging.tf` | L1 | BigQuery export + detection views + alert groups |

## Important Notes

The `hashicorp/googleworkspace` provider manages organizational structure (users, groups, OUs, roles) but does **not** directly control all Admin Console settings. Several controls require complementary configuration:

| Setting | Terraform Manages | Admin Console / GAM Required |
|---------|-------------------|------------------------------|
| 2SV Enforcement | Tracking OU + group | Enforcement toggle per OU |
| Security Key Only | Super Admin OU | 2SV method restriction per OU |
| OAuth App Blocking | Governance groups | App access control default policy |
| Less Secure Apps | Tracking group | Organization-wide disable toggle |
| Drive Sharing | OU structure | Sharing settings per OU |
| DLP Rules | Inspect templates | Workspace DLP rule creation |

Use [GAM](https://github.com/GAM-team/GAM) or the [Admin SDK](https://developers.google.com/admin-sdk) for settings not covered by the Terraform provider.

## Directory Structure

```
google-workspace/terraform/
├── README.md
├── providers.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── hth-google-workspace-1.01-enforce-mfa.tf
├── hth-google-workspace-1.02-restrict-super-admin.tf
├── hth-google-workspace-1.03-configure-context-aware-access.tf
├── hth-google-workspace-2.01-restrict-admin-ip-ranges.tf
├── hth-google-workspace-3.01-enable-oauth-app-whitelisting.tf
├── hth-google-workspace-3.02-disable-less-secure-apps.tf
├── hth-google-workspace-4.01-restrict-external-drive-sharing.tf
├── hth-google-workspace-4.02-enable-dlp.tf
└── hth-google-workspace-5.01-enable-audit-logging.tf
```

## Naming Convention

All files follow: `hth-google-workspace-{section.control}-{kebab-case-slug}.tf`

- **Control files**: `hth-google-workspace-1.01-enforce-mfa.tf`
- **Shared files**: `providers.tf`, `variables.tf`, `outputs.tf`

## Compliance Coverage

| Framework | Controls Mapped |
|-----------|----------------|
| SOC 2 | CC6.1, CC6.2, CC6.6, CC7.2 |
| NIST 800-53 | AC-3, AC-6, AC-17, AC-22, AU-2, AU-3, AU-6, CM-7, IA-2, SC-7, SC-8, SC-28 |
| CIS Google Workspace | 1.1, 1.2, 2.1, 3.1, 5.1 |
| ISO 27001 | A.9.2, A.9.4, A.12.4 |

## Related

- [Google Workspace Hardening Guide](https://howtoharden.com/guides/google-workspace/) -- Full guide with ClickOps + Code implementations
- [How to Harden](https://howtoharden.com) -- All vendor hardening guides
- [Code Packs Overview](../../README.md) -- Architecture and schema documentation
