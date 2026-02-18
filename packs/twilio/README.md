# Twilio Hardening Code Pack

Runnable security hardening artifacts for [Twilio](https://howtoharden.com/guides/twilio/). Implements all 7 controls from the Twilio hardening guide across authentication, access controls, and API security.

## What's Included

| Component | Count | Description |
|-----------|-------|-------------|
| Terraform | 7 | Per-control `.tf` files for controls 1.1, 1.2, 2.1, 2.2, 2.3, 3.1, 3.2 |

## Prerequisites

- Twilio account with **Owner** or **Administrator** access
- Account SID and Auth Token (Console > Account Info)
- [Terraform](https://www.terraform.io/) >= 1.0 with the [twilio/twilio provider](https://registry.terraform.io/providers/twilio/twilio/latest) (for Terraform)

## Quick Start

### Terraform (Declarative)

```bash
cd packs/twilio/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set twilio_account_sid and twilio_auth_token

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
| L1 -- Baseline | `1` | SSO validation, 2FA enforcement validation, user role audit, admin access limits, API key creation |
| L2 -- Hardened | `2` | L1 + subaccount isolation, per-subaccount API keys, webhook security validation |
| L3 -- Maximum Security | `3` | L1 + L2 (all controls enforced at strictest settings) |

Set `profile_level` (Terraform variable) once. Every resource respects it.

## Directory Structure

```
twilio/
├── README.md
└── terraform/                                            # Per-control Terraform files
    ├── providers.tf                                      # Provider configuration
    ├── variables.tf                                      # Input variables
    ├── outputs.tf                                        # Output values
    ├── terraform.tfvars.example                          # Example variable values
    ├── hth-twilio-1.01-configure-saml-sso.tf             # SSO validation
    ├── hth-twilio-1.02-enforce-two-factor-auth.tf        # 2FA enforcement validation
    ├── hth-twilio-2.01-configure-user-roles.tf           # Role assignment validation
    ├── hth-twilio-2.02-configure-subaccounts.tf          # Subaccount isolation
    ├── hth-twilio-2.03-limit-admin-access.tf             # Admin access restriction
    ├── hth-twilio-3.01-configure-api-key-security.tf     # API key management
    └── hth-twilio-3.02-configure-webhook-security.tf     # Webhook security validation
```

## Naming Convention

All files follow: `hth-{vendor}-{section}-{control-title}.{ext}`

- **Terraform**: `hth-twilio-1.01-configure-saml-sso.tf`
- **Shared files**: `providers.tf`, `variables.tf`, `outputs.tf`

## Controls

### Section 1 -- Authentication (2 controls)

| # | Control | Level |
|---|---------|-------|
| 1.1 | Configure SAML Single Sign-On | L1 |
| 1.2 | Enforce Two-Factor Authentication | L1 |

### Section 2 -- Access Controls (3 controls)

| # | Control | Level |
|---|---------|-------|
| 2.1 | Configure User Roles | L1 |
| 2.2 | Configure Subaccounts | L2 |
| 2.3 | Limit Admin Access | L1 |

### Section 3 -- API Security (2 controls)

| # | Control | Level |
|---|---------|-------|
| 3.1 | Configure API Key Security | L1 |
| 3.2 | Configure Webhook Security | L2 |

## Terraform Coverage

Each control has its own `.tf` file:

| Control | File | Description |
|---------|------|-------------|
| 1.1 | `hth-twilio-1.01-configure-saml-sso.tf` | SAML SSO configuration validation |
| 1.2 | `hth-twilio-1.02-enforce-two-factor-auth.tf` | 2FA enforcement validation |
| 2.1 | `hth-twilio-2.01-configure-user-roles.tf` | Least-privilege role validation |
| 2.2 | `hth-twilio-2.02-configure-subaccounts.tf` | Subaccount isolation (L2+) |
| 2.3 | `hth-twilio-2.03-limit-admin-access.tf` | Admin access restriction |
| 3.1 | `hth-twilio-3.01-configure-api-key-security.tf` | API key creation and management |
| 3.2 | `hth-twilio-3.02-configure-webhook-security.tf` | Webhook signature and HTTPS validation |

## Provider Notes

The `twilio/twilio` Terraform provider (v0.18.x) supports resource management for API keys and subaccounts. SSO/SAML, 2FA enforcement, and user role management are Console-only operations and are implemented as validation checkpoints using `null_resource` provisioners.

## Compliance Coverage

| Framework | Controls Mapped |
|-----------|----------------|
| SOC 2 | CC6.1, CC6.2, CC6.7 |
| NIST 800-53 | IA-2, IA-2(1), IA-8, AC-6, AC-6(1), SC-8, SC-12 |
| CIS Controls | 3.11, 5.4, 6.3, 6.5, 12.5 |

## Related

- [Twilio Hardening Guide](https://howtoharden.com/guides/twilio/) -- Full guide with ClickOps + Code implementations
- [How to Harden](https://howtoharden.com) -- All vendor hardening guides
- [Code Packs Overview](../README.md) -- Architecture and schema documentation
