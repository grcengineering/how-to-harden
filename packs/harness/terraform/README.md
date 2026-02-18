# Harness Hardening Code Pack - Terraform

Terraform configuration for hardening [Harness](https://www.harness.io/) software delivery platform security controls, following the [How to Harden Harness Guide](https://howtoharden.com/guides/harness/).

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- Harness account with admin access
- Harness API key (PAT or SAT) with account-level permissions
- SAML 2.0 compatible identity provider (for SSO controls)

## Quick Start

```bash
# 1. Clone and navigate to this directory
cd packs/harness/terraform/

# 2. Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# 3. Edit terraform.tfvars with your values
#    At minimum, set: harness_account_id, harness_platform_api_key

# 4. Initialize Terraform
terraform init

# 5. Preview changes
terraform plan

# 6. Apply hardening controls
terraform apply
```

## Profile Levels

Controls are applied cumulatively based on the `profile_level` variable:

| Level | Name | Description |
|-------|------|-------------|
| 1 | Baseline (L1) | Essential controls for all organizations |
| 2 | Hardened (L2) | Adds IP allowlisting, org hierarchy, secret access controls, pipeline governance |
| 3 | Maximum Security (L3) | Adds artifact digest verification policies |

```bash
# Apply L1 (default)
terraform apply -var="profile_level=1"

# Apply L2 (includes all L1 controls)
terraform apply -var="profile_level=2"

# Apply L3 (includes all L1+L2 controls)
terraform apply -var="profile_level=3"
```

## Controls Implemented

### Section 1: Authentication & SSO

| File | Control | Level |
|------|---------|-------|
| `hth-harness-1.01-configure-saml-sso.tf` | SAML SSO configuration with IdP-linked user groups | L1 |
| `hth-harness-1.02-enforce-two-factor-authentication.tf` | MFA enforcement via SSO and service account setup | L1 |
| `hth-harness-1.03-configure-ip-allowlisting.tf` | IP-based access restrictions | L2 |

### Section 2: Access Controls

| File | Control | Level |
|------|---------|-------|
| `hth-harness-2.01-configure-rbac.tf` | Least-privilege roles and resource groups | L1 |
| `hth-harness-2.02-configure-org-project-hierarchy.tf` | Organization and project isolation | L2 |
| `hth-harness-2.03-limit-admin-access.tf` | Restricted admin group and role binding | L1 |

### Section 3: Secret Management

| File | Control | Level |
|------|---------|-------|
| `hth-harness-3.01-configure-secret-manager.tf` | External secret manager connectors (Vault, AWS, GCP) | L1 |
| `hth-harness-3.02-configure-secret-access.tf` | Scoped secret access roles and resource groups | L2 |

### Section 4: Pipeline Security

| File | Control | Level |
|------|---------|-------|
| `hth-harness-4.01-configure-pipeline-governance.tf` | OPA governance policies and policy sets | L2 |
| `hth-harness-4.02-configure-audit-trail.tf` | Audit viewer roles, compliance group, log exporter | L1 |

## Provider Authentication

Set credentials via environment variables (recommended for production):

```bash
export TF_VAR_harness_account_id="your-account-id"
export TF_VAR_harness_platform_api_key="pat.your-account-id.your-key..."
```

Or set them in `terraform.tfvars` (never commit this file).

## Secret Manager Options

The `secret_manager_type` variable selects which external secret manager to configure:

| Type | Resource Created |
|------|-----------------|
| `builtin` | None (uses Harness built-in secret manager) |
| `vault` | `harness_platform_connector_vault` |
| `aws` | `harness_platform_connector_aws_secret_manager` |
| `gcp` | `harness_platform_connector_gcp_secret_manager` |

## References

- [Harness Terraform Provider](https://registry.terraform.io/providers/harness/harness/latest/docs)
- [Harness RBAC Documentation](https://developer.harness.io/docs/platform/role-based-access-control/)
- [Harness Policy As Code](https://developer.harness.io/docs/platform/governance/policy-as-code/harness-governance-overview/)
- [Harness Security Hardening for CI](https://developer.harness.io/docs/continuous-integration/secure-ci/security-hardening/)
- [How to Harden Harness Guide](https://howtoharden.com/guides/harness/)
