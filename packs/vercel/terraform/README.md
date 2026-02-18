# Vercel Hardening Code Pack -- Terraform

> Part of the [How to Harden](https://howtoharden.com) project by [GRC Engineering](https://grc.engineering)

Terraform implementation of the [Vercel Hardening Guide](https://howtoharden.com/guides/vercel/). Applies security controls for authentication, deployment protection, secrets management, and monitoring.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- Vercel API token with team admin permissions
- Vercel Pro or Enterprise plan (some controls require Enterprise)

## Quick Start

```bash
# 1. Clone and navigate to the code pack
cd packs/vercel/terraform/

# 2. Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# 3. Edit with your values (NEVER commit this file)
# Set at minimum: vercel_api_token, vercel_team_id, project_id

# 4. Initialize and apply
terraform init
terraform plan
terraform apply
```

## Profile Levels

| Level | Name | Description |
|-------|------|-------------|
| L1 | Baseline | SAML SSO, team roles, fork protection, env var security, log drains |
| L2 | Hardened | Preview password protection, IP allowlisting, WAF, sensitive env policy, IP privacy |
| L3 | Maximum Security | Automation bypass disabled, strictest deployment controls |

```bash
# Apply L1 (default)
terraform apply -var="profile_level=1"

# Apply L2 (includes L1)
terraform apply -var="profile_level=2"

# Apply L3 (includes L1 + L2)
terraform apply -var="profile_level=3"
```

## Controls Implemented

| File | Control | Level | Description |
|------|---------|-------|-------------|
| `hth-vercel-1.01-enforce-sso-with-mfa.tf` | 1.1 | L1 | SAML SSO enforcement (Enterprise) |
| `hth-vercel-1.02-team-access-controls.tf` | 1.2 | L1 | Role-based team member management |
| `hth-vercel-2.01-secure-deployments.tf` | 2.1 | L1/L2 | Production branch protection, preview security |
| `hth-vercel-2.02-git-integration-security.tf` | 2.2 | L1/L2 | Fork protection, verified commits |
| `hth-vercel-3.01-environment-variables.tf` | 3.1 | L1/L2 | Sensitive env var flags, team-level policy |
| `hth-vercel-3.02-access-token-security.tf` | 3.2 | L2/L3 | IP allowlisting, automation bypass control |
| `hth-vercel-4.01-audit-log-and-monitoring.tf` | 4.1 | L1/L2 | Log drains, WAF, IP privacy hardening |

## Edition Compatibility

| Control | Hobby | Pro | Enterprise |
|---------|-------|-----|------------|
| SAML SSO (1.1) | -- | -- | Yes |
| Team Roles (1.2) | -- | Yes | Yes |
| Deployment Protection (2.1) | -- | Yes | Yes |
| Trusted IPs (3.2) | -- | -- | Yes |
| Log Drains (4.1) | -- | Yes | Yes |
| WAF (4.1) | -- | Yes | Yes |

## Sensitive Values

Never commit secrets to version control. Use environment variables:

```bash
export TF_VAR_vercel_api_token="your-token-here"
export TF_VAR_preview_password="your-preview-password"
export TF_VAR_log_drain_secret="your-webhook-secret"
```

## File Structure

```text
packs/vercel/terraform/
  providers.tf                              # Provider configuration
  variables.tf                              # All variable declarations
  outputs.tf                                # Output values for verification
  terraform.tfvars.example                  # Example variable values (copy to .tfvars)
  hth-vercel-1.01-enforce-sso-with-mfa.tf   # Control 1.1: SSO enforcement
  hth-vercel-1.02-team-access-controls.tf   # Control 1.2: Team RBAC
  hth-vercel-2.01-secure-deployments.tf     # Control 2.1: Deployment security
  hth-vercel-2.02-git-integration-security.tf # Control 2.2: Git integration
  hth-vercel-3.01-environment-variables.tf  # Control 3.1: Env var security
  hth-vercel-3.02-access-token-security.tf  # Control 3.2: Token security
  hth-vercel-4.01-audit-log-and-monitoring.tf # Control 4.1: Logging & WAF
  README.md                                 # This file
```
