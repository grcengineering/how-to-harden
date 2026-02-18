# Oracle HCM Cloud Hardening -- Terraform Code Pack

Declarative security hardening for [Oracle HCM Cloud](https://howtoharden.com/guides/oracle-hcm/) using the `oracle/oci` Terraform provider. Implements 8 controls from the Oracle HCM Cloud hardening guide across authentication, API security, data protection, and monitoring.

## Prerequisites

- Oracle Cloud Infrastructure (OCI) tenancy with administrator access
- Oracle Identity Cloud Service (IDCS) domain configured for HCM
- [Terraform](https://www.terraform.io/) >= 1.0 with the [oracle/oci provider](https://registry.terraform.io/providers/oracle/oci/latest) (~> 5.0)
- OCI API signing key configured (`~/.oci/config`)

## Quick Start

```bash
cd packs/oracle-hcm/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set OCI credentials and IDCS domain

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
| L1 -- Baseline | `1` | SSO with MFA, security roles, security profiles, password policy, OAuth client hardening, data encryption (Oracle-managed), data retention lifecycle, audit alarms |
| L2 -- Hardened | `2` | L1 + HDL access restrictions, API network perimeter, customer-managed encryption (CMEK), DSAR export bucket, API rate monitoring, off-hours activity alerts |
| L3 -- Maximum Security | `3` | L1 + L2 + FIDO2-only authentication, HSM key protection, dedicated API service account, HDL upload event detection |

Set `profile_level` once. Every resource respects it.

## Terraform Coverage

Each control has its own `.tf` file:

| Control | File | Profile | Description |
|---------|------|---------|-------------|
| 1.1 | `hth-oracle-hcm-1.01-enforce-sso-with-mfa.tf` | L1 | MFA factor settings + SSO sign-on policy |
| 1.2 | `hth-oracle-hcm-1.02-implement-security-roles.tf` | L1 | IDCS groups for role-based access |
| 1.3 | `hth-oracle-hcm-1.03-configure-security-profiles.tf` | L1 | IAM policies + password policy |
| 2.1 | `hth-oracle-hcm-2.01-secure-rest-api-access.tf` | L1 | OAuth client + API sign-on policy |
| 2.2 | `hth-oracle-hcm-2.02-hdl-security.tf` | L2 | HDL group + access policy + event rules |
| 3.1 | `hth-oracle-hcm-3.01-configure-data-encryption.tf` | L1 | Vault + encryption key + secure bucket |
| 3.2 | `hth-oracle-hcm-3.02-data-retention-and-purge.tf` | L1 | Lifecycle policies + log analytics |
| 4.1 | `hth-oracle-hcm-4.01-enable-audit-policies.tf` | L1 | Audit config + alarms + notifications |
| 4.2 | `hth-oracle-hcm-4.02-monitor-integration-activity.tf` | L2 | API rate + off-hours + event rules |

## Directory Structure

```
oracle-hcm/terraform/
  providers.tf                                    # OCI provider configuration
  variables.tf                                    # Input variables with profile_level
  outputs.tf                                      # Output values for verification
  terraform.tfvars.example                        # Example variable values
  README.md                                       # This file
  hth-oracle-hcm-1.01-enforce-sso-with-mfa.tf    # Control 1.1: SSO + MFA
  hth-oracle-hcm-1.02-implement-security-roles.tf # Control 1.2: IDCS groups
  hth-oracle-hcm-1.03-configure-security-profiles.tf # Control 1.3: IAM policies
  hth-oracle-hcm-2.01-secure-rest-api-access.tf  # Control 2.1: OAuth client
  hth-oracle-hcm-2.02-hdl-security.tf            # Control 2.2: HDL restrictions
  hth-oracle-hcm-3.01-configure-data-encryption.tf # Control 3.1: Encryption
  hth-oracle-hcm-3.02-data-retention-and-purge.tf # Control 3.2: Retention
  hth-oracle-hcm-4.01-enable-audit-policies.tf   # Control 4.1: Audit + alarms
  hth-oracle-hcm-4.02-monitor-integration-activity.tf # Control 4.2: Monitoring
```

## Naming Convention

All files follow: `hth-oracle-hcm-{section}.{control}-{kebab-case-slug}.tf`

## Compliance Coverage

| Framework | Controls Mapped |
|-----------|----------------|
| NIST 800-53 | AC-3, AC-6, AC-6(1), AU-2, AU-3, AU-6, IA-2(1), IA-5, SC-8, SC-28, SI-4, SI-12 |

## Related

- [Oracle HCM Cloud Hardening Guide](https://howtoharden.com/guides/oracle-hcm/) -- Full guide with ClickOps + Code implementations
- [How to Harden](https://howtoharden.com) -- All vendor hardening guides
- [Code Packs Overview](../../README.md) -- Architecture and schema documentation
