# Keeper Security Hardening Code Pack -- Terraform

> Part of [How to Harden](https://howtoharden.com) | [Full Guide](https://howtoharden.com/guides/keeper/)

Terraform configuration for hardening Keeper Security enterprise deployments. Implements controls from the [HTH Keeper Security Hardening Guide](https://howtoharden.com/guides/keeper/) using the [Keeper Secrets Manager Terraform provider](https://registry.terraform.io/providers/Keeper-Security/secretsmanager/latest/docs).

## Quick Start

```bash
# 1. Copy example variables
cp terraform.tfvars.example terraform.tfvars

# 2. Edit with your values
#    (at minimum: keeper_credential, security_config_folder_uid)

# 3. Plan and apply
terraform init
terraform plan
terraform apply
```

## Profile Levels

Profiles are cumulative -- L2 includes all L1 controls, L3 includes all L1+L2 controls.

```bash
# L1 Baseline -- essential controls for all organizations
terraform apply -var="profile_level=1"

# L2 Hardened -- adds IP allowlisting, SSO, export restrictions
terraform apply -var="profile_level=2"

# L3 Maximum Security -- dual 2FA, strictest controls
terraform apply -var="profile_level=3"
```

## Controls Implemented

| File | Control | Level | Frameworks |
|------|---------|-------|------------|
| `hth-keeper-1.01-protect-administrator-accounts.tf` | 1.1 Protect Admin Accounts | L1 | CIS 5.4, NIST AC-6 |
| `hth-keeper-1.02-ip-allowlisting-admins.tf` | 1.2 IP Allowlisting for Admins | L2 | CIS 13.5, NIST AC-17/SC-7 |
| `hth-keeper-1.03-administrative-event-alerts.tf` | 1.3 Administrative Event Alerts | L1 | CIS 8.11, NIST SI-4 |
| `hth-keeper-2.01-master-password-requirements.tf` | 2.1 Master Password Requirements | L1 | CIS 5.2, NIST IA-5 |
| `hth-keeper-2.02-enforce-two-factor-authentication.tf` | 2.2 Enforce 2FA | L1 | CIS 6.5, NIST IA-2(1) |
| `hth-keeper-2.03-sharing-export-restrictions.tf` | 2.3 Sharing & Export Restrictions | L1 | CIS 3.3, NIST AC-3 |
| `hth-keeper-2.04-restrict-browser-extensions.tf` | 2.4 Browser Extension Restrictions | L2 | CIS 2.5, NIST CM-7 |
| `hth-keeper-3.01-biometric-authentication.tf` | 3.1 Biometric Authentication | L1 | CIS 6.5, NIST IA-2 |
| `hth-keeper-3.02-account-recovery.tf` | 3.2 Account Recovery | L1 | CIS 5.2, NIST IA-5 |
| `hth-keeper-4.01-saml-sso.tf` | 4.1 SAML SSO | L2 | CIS 6.3/12.5, NIST IA-2/IA-8 |
| `hth-keeper-4.02-just-in-time-provisioning.tf` | 4.2 JIT Provisioning | L2 | CIS 5.3, NIST AC-2 |
| `hth-keeper-5.01-audit-logging.tf` | 5.1 Audit Logging | L1 | CIS 8.2, NIST AU-2 |
| `hth-keeper-5.02-security-audit.tf` | 5.2 Security Audit Monitoring | L1 | CIS 4.1, NIST CA-7 |
| `hth-keeper-5.03-breachwatch.tf` | 5.3 BreachWatch Integration | L1 | CIS 16.4, NIST SI-4 |

## Architecture Notes

The Keeper Secrets Manager Terraform provider (`Keeper-Security/secretsmanager`) manages vault records (secrets, logins, credentials). Enterprise enforcement policies (master password requirements, 2FA enforcement, IP allowlisting, sharing restrictions) are configured through:

1. **Keeper Admin Console** -- GUI-based configuration
2. **Keeper Commander CLI** -- `pip3 install keepercommander`
3. **Keeper Terraform Provider** (`Keeper-Security/keeper`) -- for `keeper_role_enforcements` resources

This code pack uses the Secrets Manager provider to:
- Store break-glass admin credentials securely in the vault
- Create auditable configuration records for each hardening control
- Document enforcement policy settings alongside the infrastructure code
- Provide `local-exec` provisioners with step-by-step Admin Console instructions

For full Terraform-native enforcement policy management, consider supplementing with the [Keeper Enterprise provider](https://registry.terraform.io/providers/Keeper-Security/keeper/latest/docs).

## Prerequisites

- Terraform >= 1.0
- Keeper Enterprise or Enterprise Plus license
- Keeper Secrets Manager application with one-time access token
- Shared folders created in Keeper vault for configuration records

## Plan Compatibility

| Feature | Business | Enterprise | Enterprise Plus |
|---------|----------|------------|-----------------|
| Role Enforcement | Basic | Full | Full |
| SSO Connect Cloud | -- | Yes | Yes |
| SCIM Provisioning | -- | Yes | Yes |
| BreachWatch | Add-on | Add-on | Included |
| Advanced Reporting | Basic | Full | Full |
| SIEM Integration | -- | Yes | Yes |

## References

- [Keeper Security Trust Center](https://trust.keeper.io/)
- [Keeper Enterprise Documentation](https://docs.keeper.io/en/enterprise-guide)
- [Enforcement Policies Reference](https://docs.keeper.io/en/enterprise-guide/roles/enforcement-policies)
- [Keeper Commander CLI](https://docs.keeper.io/en/keeper-commander/overview)
- [Keeper Secrets Manager](https://docs.keeper.io/en/secrets-manager/overview)
- [Terraform Provider (Secrets Manager)](https://registry.terraform.io/providers/Keeper-Security/secretsmanager/latest/docs)
- [Terraform Provider (Enterprise)](https://registry.terraform.io/providers/Keeper-Security/keeper/latest/docs)
