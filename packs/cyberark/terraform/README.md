# CyberArk Hardening Code Pack - Terraform

> Terraform configuration for applying [How to Harden CyberArk](https://howtoharden.com/guides/cyberark/) security controls.

## Provider

| Name | Source | Version |
|------|--------|---------|
| conjur | `cyberark/conjur` | `~> 0.6` |

## Prerequisites

- Terraform >= 1.0
- CyberArk PVWA with REST API access
- CyberArk Conjur appliance (for secrets management controls)
- API authentication token with administrative privileges
- `python3` available locally (used by validation provisioners)
- `curl` available locally (used by API provisioners)

## Quick Start

```bash
cd packs/cyberark/terraform/

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize and apply
terraform init
terraform plan
terraform apply
```

## Profile Levels

| Level | Name | Description |
|-------|------|-------------|
| 1 | Baseline | Essential controls for all organizations |
| 2 | Hardened | Adds JIT access, vault HA, enhanced detection, aggressive rotation |
| 3 | Maximum Security | TLS 1.3 only, one-time passwords, forensic logging, immutable audit |

```bash
# Apply L1 (default)
terraform apply -var="profile_level=1"

# Apply L2
terraform apply -var="profile_level=2"

# Apply L3
terraform apply -var="profile_level=3"
```

## Controls

| File | Control | Level | Frameworks |
|------|---------|-------|------------|
| `hth-cyberark-1.01-enforce-mfa.tf` | Enforce MFA for All Access | L1 | NIST IA-2(1), PCI DSS 8.3.1 |
| `hth-cyberark-1.02-vault-level-access-controls.tf` | Vault-Level Access Controls | L1 | NIST AC-3, AC-6 |
| `hth-cyberark-1.03-break-glass-procedures.tf` | Break-Glass Procedures | L1 | NIST CP-2 |
| `hth-cyberark-2.01-harden-vault-server.tf` | Harden Vault Server | L1 | NIST SC-8, SC-28 |
| `hth-cyberark-2.02-vault-high-availability.tf` | Vault High Availability | L2 | NIST CP-9, CP-10 |
| `hth-cyberark-3.01-secure-api-authentication.tf` | Secure API Authentication | L1 | NIST IA-5, SC-8 |
| `hth-cyberark-3.02-restrict-integration-permissions.tf` | Restrict Integration Permissions | L1 | NIST AC-6 |
| `hth-cyberark-3.03-external-secrets-integration.tf` | External Secrets Integration | L2 | NIST IA-5(7) |
| `hth-cyberark-4.01-psm-session-security.tf` | PSM Session Security | L1 | NIST AC-12, AU-14 |
| `hth-cyberark-4.02-just-in-time-access.tf` | Just-In-Time Access | L2 | NIST AC-2(6) |
| `hth-cyberark-5.01-automatic-password-rotation.tf` | Automatic Password Rotation | L1 | NIST IA-5(1) |
| `hth-cyberark-5.02-monitor-rotation-failures.tf` | Monitor Rotation Failures | L1 | NIST IA-5(1) |
| `hth-cyberark-6.01-comprehensive-audit-logging.tf` | Comprehensive Audit Logging | L1 | NIST AU-2, AU-3 |

## Sensitive Variables

Use environment variables for secrets in production:

```bash
export TF_VAR_conjur_api_key="your-conjur-api-key"
export TF_VAR_pvwa_auth_token="your-pvwa-token"
```

## Architecture Notes

This code pack uses `null_resource` with `local-exec` provisioners to interact with the CyberArk PVWA REST API and Conjur API. This approach is necessary because the CyberArk Conjur Terraform provider focuses on secrets retrieval rather than platform configuration. The provisioners call the PVWA REST API to configure vault settings, safe permissions, session policies, rotation schedules, and audit logging.

Resources that apply only at higher profile levels use `count = var.profile_level >= N ? 1 : 0` for conditional deployment.
