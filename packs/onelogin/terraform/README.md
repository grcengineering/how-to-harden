# OneLogin Hardening Code Pack - Terraform

Terraform configuration implementing the [OneLogin Hardening Guide](https://howtoharden.com/guides/onelogin/) from How to Harden.

## Quick Start

```bash
# 1. Copy example variables
cp terraform.tfvars.example terraform.tfvars

# 2. Edit with your OneLogin API credentials and settings
#    Generate API credentials at: Developers > API Credentials
vi terraform.tfvars

# 3. Initialize Terraform
terraform init

# 4. Review planned changes
terraform plan

# 5. Apply hardening controls
terraform apply
```

## Profile Levels

Controls are applied based on the `profile_level` variable:

| Level | Name | Description |
|-------|------|-------------|
| 1 | Baseline (L1) | Essential controls for all organizations |
| 2 | Hardened (L2) | Adds SmartFactor, device trust, IP allowlisting |
| 3 | Maximum Security (L3) | Strictest settings for regulated industries |

Levels are cumulative: L2 includes all L1 controls, L3 includes all L1+L2 controls.

```bash
# Apply L1 (default)
terraform apply -var="profile_level=1"

# Apply L2 hardened controls
terraform apply -var="profile_level=2"

# Apply L3 maximum security
terraform apply -var="profile_level=3"
```

## Controls Implemented

### Section 1: User Security Policies (L1)

| File | Control | Profile |
|------|---------|---------|
| `hth-onelogin-1.01-configure-password-policy.tf` | Password length, complexity, history, lockout | L1 |
| `hth-onelogin-1.02-configure-session-controls.tf` | Session and idle timeouts | L1 |
| `hth-onelogin-1.03-enable-self-service-password-reset.tf` | Secure self-service password reset | L1 |

### Section 2: Multi-Factor Authentication

| File | Control | Profile |
|------|---------|---------|
| `hth-onelogin-2.01-enforce-mfa-for-all-users.tf` | MFA enforcement with OTP auth required | L1 |
| `hth-onelogin-2.02-configure-smartfactor-authentication.tf` | Risk-based adaptive MFA | L2 |
| `hth-onelogin-2.03-require-phishing-resistant-mfa-for-admins.tf` | WebAuthn-only for admin accounts | L2 |

### Section 3: Admin & Access Controls

| File | Control | Profile |
|------|---------|---------|
| `hth-onelogin-3.01-implement-delegated-administration.tf` | Least-privilege custom roles | L1 |
| `hth-onelogin-3.02-configure-ip-address-allowlisting.tf` | Network-based login restriction | L2 |
| `hth-onelogin-3.03-protect-privileged-accounts.tf` | Enhanced admin account protections | L1 |

### Section 4: Session & Network Security

| File | Control | Profile |
|------|---------|---------|
| `hth-onelogin-4.01-configure-tls-requirements.tf` | HTTPS-only SAML endpoints | L1 |
| `hth-onelogin-4.02-configure-brute-force-protection.tf` | Account lockout settings | L1 |
| `hth-onelogin-4.03-configure-device-trust.tf` | Managed device requirements | L2 |

### Section 5: Monitoring & Compliance

| File | Control | Profile |
|------|---------|---------|
| `hth-onelogin-5.01-enable-audit-logging.tf` | SIEM webhook for event export | L1 |
| `hth-onelogin-5.02-configure-security-alerts.tf` | Security event alerting webhooks | L1 |

## Provider

This pack uses the [OneLogin Terraform Provider](https://registry.terraform.io/providers/onelogin/onelogin/latest/docs):

```hcl
source  = "onelogin/onelogin"
version = "~> 0.4"
```

## Authentication

Generate API credentials in the OneLogin admin console:

1. Navigate to **Developers** > **API Credentials**
2. Click **New Credential**
3. Select **Read/Write** scope
4. Copy the Client ID and Client Secret

Set credentials via environment variables (recommended for production):

```bash
export TF_VAR_onelogin_client_id="your-client-id"
export TF_VAR_onelogin_client_secret="your-client-secret"
```

## Prerequisites

- Terraform >= 1.0
- OneLogin admin account with API access
- OneLogin Advanced plan or higher (Expert plan required for SmartFactor at L2+)

## Plan Compatibility

| Feature | Starter | Advanced | Professional | Expert |
|---------|---------|----------|--------------|--------|
| Password Policy (1.1) | Basic | Full | Full | Full |
| MFA (2.1) | Basic | Full | Full | Full |
| SmartFactor (2.2) | -- | -- | -- | Full |
| Delegated Admin (3.1) | -- | -- | Full | Full |
| Custom Policies | -- | Full | Full | Full |
| SIEM Integration (5.1) | -- | -- | Full | Full |

## References

- [OneLogin Hardening Guide](https://howtoharden.com/guides/onelogin/)
- [OneLogin Terraform Provider Docs](https://registry.terraform.io/providers/onelogin/onelogin/latest/docs)
- [OneLogin Developer Portal](https://developers.onelogin.com/)
- [OneLogin API Documentation](https://developers.onelogin.com/api-docs/2/getting-started/dev-overview)
