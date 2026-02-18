# JFrog Artifactory Hardening Code Pack

Terraform configuration for hardening JFrog Artifactory based on the [How to Harden JFrog guide](https://howtoharden.com/guides/jfrog/).

## Prerequisites

- Terraform >= 1.0
- JFrog Artifactory Pro or Enterprise edition
- JFrog access token with admin permissions
- JFrog Xray enabled (for Section 4 controls)

## Quick Start

```bash
# 1. Copy example variables
cp terraform.tfvars.example terraform.tfvars

# 2. Edit with your values
#    At minimum, set: artifactory_url, artifactory_access_token

# 3. Initialize Terraform
terraform init

# 4. Preview changes
terraform plan

# 5. Apply hardening controls
terraform apply
```

## Profile Levels

| Level | Name | Description |
|-------|------|-------------|
| L1 | Baseline | Essential controls for all organizations |
| L2 | Hardened | Adds artifact signing, immutable repos, strict CVE blocking |
| L3 | Maximum Security | Strictest controls for regulated industries |

Profile levels are cumulative. L2 includes all L1 controls. L3 includes all L1 and L2 controls.

```bash
# Apply L1 (default)
terraform apply -var="profile_level=1"

# Apply L2
terraform apply -var="profile_level=2"

# Apply L3
terraform apply -var="profile_level=3"
```

## Controls Implemented

| File | Control | Level | Description |
|------|---------|-------|-------------|
| `hth-jfrog-1.01-enforce-sso-with-mfa.tf` | 1.1 | L1 | SAML SSO with MFA, disable anonymous access |
| `hth-jfrog-1.02-implement-permission-targets.tf` | 1.2 | L1 | Granular repository permissions (read/write/deploy) |
| `hth-jfrog-1.03-secure-api-keys-and-tokens.tf` | 1.3 | L1 | Scoped tokens with expiry enforcement |
| `hth-jfrog-2.01-configure-repository-layout-security.tf` | 2.1 | L1 | Hardened local repository settings |
| `hth-jfrog-2.02-remote-repository-security.tf` | 2.2 | L1 | Secure remote repository proxy settings |
| `hth-jfrog-2.03-prevent-dependency-confusion.tf` | 2.3 | L1 | Virtual repo with internal-first resolution |
| `hth-jfrog-3.01-enable-artifact-signing.tf` | 3.1 | L2 | GPG signing key and signed release repository |
| `hth-jfrog-3.02-immutable-artifacts.tf` | 3.2 | L2 | Immutable release repos, block re-deployment |
| `hth-jfrog-4.01-configure-xray-policies.tf` | 4.1 | L1 | Xray security policies and watches |
| `hth-jfrog-4.02-cve-remediation-workflow.tf` | 4.2 | L1 | License compliance policies |
| `hth-jfrog-5.01-audit-logging.tf` | 5.1 | L1 | Webhook-based audit event forwarding |

## Edition Compatibility

| Control | OSS | Pro | Enterprise |
|---------|-----|-----|------------|
| SSO (SAML) | No | Yes | Yes |
| Access Tokens | Basic | Yes | Yes |
| Xray Scanning | No | Add-on | Yes |
| Audit Webhooks | No | Yes | Yes |

## Provider Documentation

- [JFrog Artifactory Provider](https://registry.terraform.io/providers/jfrog/artifactory/latest/docs)
- [JFrog Security Best Practices](https://jfrog.com/help/r/jfrog-artifactory-documentation/security-best-practices)
