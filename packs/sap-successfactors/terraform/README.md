# SAP SuccessFactors Hardening Code Pack -- Terraform

Terraform code pack for the [SAP SuccessFactors Hardening Guide](https://howtoharden.com/guides/sap-successfactors/) on How to Harden.

## Provider

This pack uses the [SAP BTP Terraform Provider](https://registry.terraform.io/providers/SAP/btp/latest/docs) to manage SuccessFactors security configurations via the SAP Business Technology Platform.

## Prerequisites

- SAP BTP global account with a subaccount running SuccessFactors
- SAP BTP user with Subaccount Administrator privileges
- Terraform >= 1.0
- SAP BTP provider >= 1.0

## Quick Start

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

## Profile Levels

Profiles are cumulative. L2 includes all L1 controls. L3 includes all L1+L2 controls.

| Level | Name | Description |
|-------|------|-------------|
| L1 | Baseline | SSO enforcement, RBP, OData OAuth, token governance, data privacy, audit logging |
| L2 | Hardened | Adds IAS subscription, auditor role, IP-restricted API, 8h refresh tokens, field masking, SIEM integration |
| L3 | Maximum Security | Adds X.509/mTLS auth, no refresh tokens, data residency enforcement, alert notification |

```bash
# Apply L1 (default)
terraform apply -var="profile_level=1"

# Apply L2
terraform apply -var="profile_level=2"

# Apply L3
terraform apply -var="profile_level=3"
```

## Controls

| File | Control | Level |
|------|---------|-------|
| `hth-sap-successfactors-1.01-configure-sso-with-mfa.tf` | 1.1 Configure SSO with MFA | L1 |
| `hth-sap-successfactors-1.02-role-based-permissions.tf` | 1.2 Role-Based Permissions (RBP) | L1 |
| `hth-sap-successfactors-2.01-secure-odata-api-access.tf` | 2.1 Secure OData API Access | L1 |
| `hth-sap-successfactors-2.02-oauth-token-management.tf` | 2.2 OAuth Token Management | L1 |
| `hth-sap-successfactors-3.01-configure-data-privacy.tf` | 3.1 Configure Data Privacy | L1 |
| `hth-sap-successfactors-4.01-audit-logging.tf` | 4.1 Audit Logging | L1 |

## File Structure

```
terraform/
  providers.tf                                          # SAP BTP provider config
  variables.tf                                          # All input variables
  outputs.tf                                            # Verification outputs
  terraform.tfvars.example                              # Example variable values
  hth-sap-successfactors-1.01-configure-sso-with-mfa.tf
  hth-sap-successfactors-1.02-role-based-permissions.tf
  hth-sap-successfactors-2.01-secure-odata-api-access.tf
  hth-sap-successfactors-2.02-oauth-token-management.tf
  hth-sap-successfactors-3.01-configure-data-privacy.tf
  hth-sap-successfactors-4.01-audit-logging.tf
```

## Environment Variables

For production use, set credentials via environment variables instead of `terraform.tfvars`:

```bash
export TF_VAR_btp_username="admin@company.com"
export TF_VAR_btp_password="your-password"
```
