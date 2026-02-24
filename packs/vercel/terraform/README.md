# Vercel Hardening Code Pack -- Terraform

> Part of the [How to Harden](https://howtoharden.com) project by [GRC Engineering](https://grc.engineering)

Terraform implementation of the [Vercel Hardening Guide](https://howtoharden.com/guides/vercel/). Applies security controls for authentication, RBAC, deployment protection, WAF, network security, secrets management, and monitoring.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [Vercel Terraform Provider](https://registry.terraform.io/providers/vercel/vercel/latest/docs) >= 2.0
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
| L1 | Baseline | SAML SSO, team roles, fork protection, env var security, log drains, attack challenge mode |
| L2 | Hardened | Access Groups, WAF with OWASP rulesets, IP blocking, rate limiting, sensitive env policy, deployment retention |
| L3 | Maximum Security | Secure Compute, trusted IPs, automation bypass disabled, strictest deployment controls |

```bash
# Apply L1 (default)
terraform apply -var="profile_level=1"

# Apply L2 (includes L1)
terraform apply -var="profile_level=2"

# Apply L3 (includes L1 + L2)
terraform apply -var="profile_level=3"
```

## Controls Implemented

| File | Section | Level | Description |
|------|---------|-------|-------------|
| `hth-vercel-1.01-enforce-sso-with-saml.tf` | 1.1 | L1 | SAML SSO enforcement (Enterprise) |
| `hth-vercel-1.03-enforce-least-privilege-rbac.tf` | 1.3 | L1/L2 | Team RBAC + Access Groups |
| `hth-vercel-2.01-configure-deployment-protection.tf` | 2.1 | L1/L2/L3 | Deployment protection, preview security, trusted IPs |
| `hth-vercel-2.02-harden-git-integration.tf` | 2.2 | L1/L2 | Fork protection, verified commits |
| `hth-vercel-3.01-enable-waf-managed-rulesets.tf` | 3.1 | L2 | WAF with OWASP managed rulesets |
| `hth-vercel-3.02-ip-blocking-rate-limiting.tf` | 3.2 | L1/L2 | IP blocking and rate limiting rules |
| `hth-vercel-4.01-enable-secure-compute.tf` | 4.1 | L3 | Secure Compute private network |
| `hth-vercel-4.02-ddos-attack-challenge-mode.tf` | 4.2 | L1 | Attack Challenge Mode |
| `hth-vercel-6.01-environment-variable-security.tf` | 6.1 | L1/L2 | Env var security, sensitive policy, IP privacy |
| `hth-vercel-6.02-deployment-retention-policy.tf` | 6.2 | L2 | Deployment retention and expiration |
| `hth-vercel-8.01-configure-log-drains-siem.tf` | 8.1 | L1/L2 | Log drains for SIEM integration |

## CLI & API Packs

Controls not configurable via Terraform have CLI and API implementations:

| Directory | Section | Description |
|-----------|---------|-------------|
| `cli/hth-vercel-1.04-*` | 1.4 | API token audit and OIDC verification |
| `cli/hth-vercel-5.01-*` | 5.1 | Security response headers (vercel.json) |
| `cli/hth-vercel-7.01-*` | 7.1 | Subdomain takeover detection |
| `cli/hth-vercel-7.02-*` | 7.2 | TLS and certificate verification |
| `cli/hth-vercel-8.03-*` | 8.3 | Cron job secret management |
| `api/hth-vercel-1.02-*` | 1.2 | Directory Sync (SCIM) audit |
| `api/hth-vercel-2.03-*` | 2.3 | Rolling releases configuration |
| `api/hth-vercel-8.02-*` | 8.2 | Audit log and SIEM streaming |

## Edition Compatibility

| Control | Hobby | Pro | Enterprise |
|---------|-------|-----|------------|
| SAML SSO (1.1) | -- | Add-on | Yes |
| RBAC + Access Groups (1.3) | Basic | Extended | Full |
| Deployment Protection (2.1) | Standard | + Password | + Trusted IPs |
| WAF Managed Rulesets (3.1) | -- | -- | Yes |
| WAF Custom Rules (3.2) | 3 rules | 40 rules | 1,000 rules |
| Secure Compute (4.1) | -- | -- | Yes ($6.5K/yr) |
| Attack Challenge Mode (4.2) | Yes | Yes | Yes |
| Log Drains (8.1) | -- | Yes | Yes |

## Sensitive Values

Never commit secrets to version control. Use environment variables:

```bash
export TF_VAR_vercel_api_token="your-token-here"
export TF_VAR_preview_password="your-preview-password"
export TF_VAR_log_drain_secret="your-webhook-secret"
```

## File Structure

```text
packs/vercel/
  terraform/
    providers.tf                                  # Provider configuration (v2.0+)
    variables.tf                                  # All variable declarations
    outputs.tf                                    # Output values for verification
    terraform.tfvars.example                      # Example variable values
    hth-vercel-1.01-enforce-sso-with-saml.tf      # Control 1.1: SAML SSO
    hth-vercel-1.03-enforce-least-privilege-rbac.tf # Control 1.3: RBAC
    hth-vercel-2.01-configure-deployment-protection.tf # Control 2.1: Deployment protection
    hth-vercel-2.02-harden-git-integration.tf     # Control 2.2: Git integration
    hth-vercel-3.01-enable-waf-managed-rulesets.tf # Control 3.1: WAF
    hth-vercel-3.02-ip-blocking-rate-limiting.tf  # Control 3.2: IP blocking
    hth-vercel-4.01-enable-secure-compute.tf      # Control 4.1: Secure Compute
    hth-vercel-4.02-ddos-attack-challenge-mode.tf # Control 4.2: DDoS protection
    hth-vercel-6.01-environment-variable-security.tf # Control 6.1: Env var security
    hth-vercel-6.02-deployment-retention-policy.tf # Control 6.2: Retention policy
    hth-vercel-8.01-configure-log-drains-siem.tf  # Control 8.1: Log drains
    README.md                                     # This file
  cli/
    hth-vercel-1.04-harden-api-token-lifecycle.sh # Control 1.4: Token audit
    hth-vercel-5.01-security-response-headers.sh  # Control 5.1: Security headers
    hth-vercel-7.01-prevent-subdomain-takeover.sh # Control 7.1: DNS audit
    hth-vercel-7.02-harden-tls-certificate-config.sh # Control 7.2: TLS verification
    hth-vercel-8.03-cron-job-security.sh          # Control 8.3: Cron secrets
  api/
    hth-vercel-1.02-configure-directory-sync.sh   # Control 1.2: SCIM audit
    hth-vercel-2.03-configure-rolling-releases.sh # Control 2.3: Rolling releases
    hth-vercel-8.02-audit-logging-siem-streaming.sh # Control 8.2: Audit logs
```
