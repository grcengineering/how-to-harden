# Ping Identity Hardening Code Pack -- Terraform

> Part of the [How to Harden](https://howtoharden.com) open-source SaaS security guides.

This Terraform code pack implements the hardening controls from the [Ping Identity Hardening Guide](https://howtoharden.com/guides/ping-identity/) using the [`pingidentity/pingone`](https://registry.terraform.io/providers/pingidentity/pingone/latest/docs) provider.

## Quick Start

```bash
# 1. Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# 2. Edit with your PingOne environment values
#    At minimum: client_id, client_secret, environment_id

# 3. Initialize Terraform
terraform init

# 4. Preview changes
terraform plan

# 5. Apply hardening controls
terraform apply
```

## Profile Levels

Controls are gated by `profile_level` (1-3). Higher levels include all lower-level controls.

| Level | Name | Description |
|-------|------|-------------|
| **L1** | Baseline | Essential controls for all organizations |
| **L2** | Hardened | Adds IP restrictions, DaVinci security, encrypted SAML, consent management |
| **L3** | Maximum Security | Strictest controls: ECDSA signing, staging environments, no refresh tokens |

```bash
# Apply L1 (default)
terraform apply -var="profile_level=1"

# Apply L2
terraform apply -var="profile_level=2"

# Apply L3
terraform apply -var="profile_level=3"
```

## Controls Implemented

| File | Control | Profile | Description |
|------|---------|---------|-------------|
| `hth-ping-identity-1.01-*` | 1.1 | L1 | Phishing-resistant MFA (FIDO2/WebAuthn) |
| `hth-ping-identity-1.02-*` | 1.2 | L1 | Least-privilege admin roles |
| `hth-ping-identity-1.03-*` | 1.3 | L2 | IP-based access restrictions |
| `hth-ping-identity-2.01-*` | 2.1 | L1 | SAML federation trust hardening |
| `hth-ping-identity-2.03-*` | 2.3 | L1 | Certificate lifecycle management |
| `hth-ping-identity-3.01-*` | 3.1 | L1 | Secure OAuth settings (PKCE, token lifetimes) |
| `hth-ping-identity-3.02-*` | 3.2 | L1 | Token revocation (risk-based) |
| `hth-ping-identity-3.03-*` | 3.3 | L2 | OAuth consent management |
| `hth-ping-identity-4.01-*` | 4.1 | L2 | DaVinci orchestration security |
| `hth-ping-identity-4.02-*` | 4.2 | L2 | Version control for DaVinci flows |
| `hth-ping-identity-5.01-*` | 5.1 | L1 | Comprehensive audit logging and SIEM integration |
| `hth-ping-identity-6.01-*` | 6.1 | L1 | SP connection hardening |
| `hth-ping-identity-6.02-*` | 6.2 | L1 | API client management (SCIM, Admin, Reporting) |

## Prerequisites

- Terraform >= 1.0
- PingOne environment with a worker application for API access
- Worker application needs Environment Admin role for full deployment
- PingOne Plus or Enterprise edition recommended (FIDO2 and DaVinci require Plus+)

## Provider Authentication

The provider authenticates via a PingOne worker application:

```bash
# Option 1: terraform.tfvars (do NOT commit to git)
pingone_client_id     = "your-client-id"
pingone_client_secret = "your-secret"
pingone_environment_id = "your-env-id"

# Option 2: Environment variables (recommended for CI/CD)
export TF_VAR_pingone_client_id="your-client-id"
export TF_VAR_pingone_client_secret="your-secret"
export TF_VAR_pingone_environment_id="your-env-id"
```

## Edition Compatibility

| Control | PingOne Essentials | PingOne Plus | PingOne Enterprise |
|---------|-------------------|--------------|-------------------|
| MFA | Yes | Yes | Yes |
| FIDO2 | No | Yes | Yes |
| DaVinci | No | Limited | Yes |
| Risk-Based Auth | No | No | Yes |
| API Access | Limited | Yes | Yes |

## File Structure

```
packs/ping-identity/terraform/
  providers.tf                                          # Provider configuration
  variables.tf                                          # All input variables
  outputs.tf                                            # Verification outputs
  terraform.tfvars.example                              # Example values
  README.md                                             # This file
  hth-ping-identity-1.01-enforce-phishing-resistant-mfa.tf
  hth-ping-identity-1.02-implement-least-privilege-admin-roles.tf
  hth-ping-identity-1.03-configure-ip-based-access-restrictions.tf
  hth-ping-identity-2.01-harden-saml-federation-trust.tf
  hth-ping-identity-2.03-certificate-lifecycle-management.tf
  hth-ping-identity-3.01-configure-secure-oauth-settings.tf
  hth-ping-identity-3.02-implement-token-revocation.tf
  hth-ping-identity-3.03-oauth-consent-management.tf
  hth-ping-identity-4.01-secure-davinci-flows.tf
  hth-ping-identity-4.02-version-control-for-flows.tf
  hth-ping-identity-5.01-configure-comprehensive-audit-logging.tf
  hth-ping-identity-6.01-sp-connection-hardening.tf
  hth-ping-identity-6.02-api-client-management.tf
```

## Compliance Mappings

| Framework | Controls Covered |
|-----------|-----------------|
| **SOC 2** | CC6.1 (MFA), CC6.2 (RBAC), CC6.6 (IP restrictions), CC7.2 (Audit logging) |
| **NIST 800-53** | IA-2(1), IA-2(6), AC-6, AC-3, SC-7, SC-12, SC-23, AU-2, AU-3, CM-3 |
| **PCI DSS** | 8.3.1 (MFA for admin), 10.2 (Audit trails) |
| **ISO 27001** | A.9.2 (Access management), A.12.4 (Logging), A.14.1 (Crypto) |
