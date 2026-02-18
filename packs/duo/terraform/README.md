# Duo Security Terraform Code Pack

Terraform hardening artifacts for [Cisco Duo Security](https://howtoharden.com/guides/duo/). Implements controls from the Duo hardening guide across admin security, authentication policies, user management, device trust, application security, and monitoring.

## Architecture

This code pack uses two complementary approaches:

| Layer | Provider / Tool | Purpose |
|-------|----------------|---------|
| Policy Engine | CiscoDevNet/ise (~> 0.7) | ISE network access policies, device admin policies, identity source sequences, endpoint groups, authorization profiles |
| Duo Native | null_resource + Duo Admin API | Global policy, bypass audits, phishing-resistant MFA, enrollment config, SIEM integration, Trust Monitor |

Cisco ISE is the policy engine behind Duo's network access decisions. Duo-native settings (admin panel, global policy, user management) are managed via the Duo Admin API through `null_resource` provisioners.

## Prerequisites

- Cisco ISE instance with **ERS API enabled** and admin credentials
- Duo Admin Panel access with **Admin API** application configured
- [Terraform](https://www.terraform.io/) >= 1.0 with the [CiscoDevNet/ise provider](https://registry.terraform.io/providers/CiscoDevNet/ise/latest)
- `bash`, `curl`, `python3` (for Duo Admin API provisioners)

## Quick Start

```bash
cd packs/duo/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set ISE and Duo credentials

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
| L1 -- Baseline | `1` | Admin audit, credential hygiene, global MFA policy, bypass elimination, inactive account management, enrollment security, device registration monitoring, Windows RDP hardening, SIEM logging |
| L2 -- Hardened | `2` | L1 + phishing-resistant MFA (Verified Push, WebAuthn), authorized networks, trusted endpoints, application-tiered policies, session hijacking protection |
| L3 -- Maximum Security | `3` | L1 + L2 + strictest enforcement (WebAuthn-only, all weak methods disabled) |

Set `profile_level` once. Every resource respects it.

## Terraform Coverage

Each control has its own `.tf` file:

| Control | File | Level | Description |
|---------|------|-------|-------------|
| 1.1 | `hth-duo-1.1-secure-admin-panel-access.tf` | L1 | Admin account audit, role-based access, admin MFA |
| 1.2 | `hth-duo-1.2-protect-admin-credentials.tf` | L1 | Credential hygiene validation |
| 2.1 | `hth-duo-2.1-configure-global-policy.tf` | L1 | Global MFA enforcement + ISE policy set |
| 2.2 | `hth-duo-2.2-eliminate-bypass-access.tf` | L1 | Bypass user audit and elimination |
| 2.3 | `hth-duo-2.3-require-phishing-resistant-mfa.tf` | L2 | Verified Push, WebAuthn, disable weak methods |
| 2.4 | `hth-duo-2.4-configure-authorized-networks.tf` | L2 | Network-aware policies + ISE device groups |
| 3.1 | `hth-duo-3.1-manage-inactive-accounts.tf` | L1 | Inactive and pending account audit |
| 3.2 | `hth-duo-3.2-configure-user-enrollment.tf` | L1 | Enrollment link security + ISE identity group |
| 4.1 | `hth-duo-4.1-configure-trusted-endpoints.tf` | L2 | Device trust + ISE endpoint groups and auth profiles |
| 4.2 | `hth-duo-4.2-monitor-device-registration.tf` | L1 | Device registration tracking + ISE custom attributes |
| 5.1 | `hth-duo-5.1-configure-application-policies.tf` | L2 | Tiered application policies + ISE policy sets |
| 5.2 | `hth-duo-5.2-secure-windows-logon-rdp.tf` | L1 | Windows Logon/RDP hardening + ISE device admin policy |
| 6.1 | `hth-duo-6.1-enable-logging-and-alerting.tf` | L1 | SIEM integration + Trust Monitor + ISE identity source |
| 6.3 | `hth-duo-6.3-session-hijacking-protection.tf` | L2 | Session timeout + re-authentication + ISE conditions |

## Directory Structure

```
duo/terraform/
├── README.md
├── providers.tf                                    # CiscoDevNet/ise provider config
├── variables.tf                                    # Input variables with validation
├── outputs.tf                                      # Output values for verification
├── terraform.tfvars.example                        # Example variable values
├── hth-duo-1.1-secure-admin-panel-access.tf        # Admin audit + role-based access
├── hth-duo-1.2-protect-admin-credentials.tf        # Credential hygiene check
├── hth-duo-2.1-configure-global-policy.tf          # Global MFA enforcement
├── hth-duo-2.2-eliminate-bypass-access.tf           # Bypass user elimination
├── hth-duo-2.3-require-phishing-resistant-mfa.tf   # Verified Push + WebAuthn (L2)
├── hth-duo-2.4-configure-authorized-networks.tf    # Network-aware policies (L2)
├── hth-duo-3.1-manage-inactive-accounts.tf         # Inactive account audit
├── hth-duo-3.2-configure-user-enrollment.tf        # Enrollment security
├── hth-duo-4.1-configure-trusted-endpoints.tf      # Device trust (L2)
├── hth-duo-4.2-monitor-device-registration.tf      # Device registration tracking
├── hth-duo-5.1-configure-application-policies.tf   # Tiered app policies (L2)
├── hth-duo-5.2-secure-windows-logon-rdp.tf         # Windows/RDP hardening
├── hth-duo-6.1-enable-logging-and-alerting.tf      # SIEM + Trust Monitor
└── hth-duo-6.3-session-hijacking-protection.tf     # Session protection (L2)
```

## Naming Convention

All files follow: `hth-duo-{section.number}-{kebab-case-slug}.tf`

- **Section 1**: Admin Account Security
- **Section 2**: Authentication Policies
- **Section 3**: User Management
- **Section 4**: Device Trust
- **Section 5**: Application Security
- **Section 6**: Monitoring & Detection

## Compliance Coverage

| Framework | Controls Mapped |
|-----------|----------------|
| CIS Controls | 1.4, 3.11, 4.1, 5.3, 5.4, 6.3, 6.4, 6.5, 8.2, 13.5 |
| NIST 800-53 | AC-2, AC-2(11), AC-3, AC-6(1), AC-17, AU-2, AU-6, CM-8, IA-2, IA-2(1), IA-2(6), IA-5, SC-12, SC-23 |

## Related

- [Duo Security Hardening Guide](https://howtoharden.com/guides/duo/) -- Full guide with ClickOps + Code implementations
- [How to Harden](https://howtoharden.com) -- All vendor hardening guides
- [Code Packs Overview](../../README.md) -- Architecture and schema documentation
