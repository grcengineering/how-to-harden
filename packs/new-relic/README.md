# New Relic Hardening Code Pack

Runnable security hardening artifacts for [New Relic](https://howtoharden.com/guides/new-relic/). Implements controls from the New Relic hardening guide across authentication, API key security, data security, and monitoring.

## What's Included

| Component | Count | Description |
|-----------|-------|-------------|
| Terraform | 7 | Per-control `.tf` files for controls 1.1, 1.2, 2.1, 2.2, 3.1, 3.2, 4.1 |

## Prerequisites

- New Relic account with **Admin** access
- New Relic User API key (`NRAK-...`) with appropriate permissions
- New Relic account ID (numeric)
- [Terraform](https://www.terraform.io/) >= 1.0 with the [newrelic/newrelic provider](https://registry.terraform.io/providers/newrelic/newrelic/latest) (~> 3.0)

## Quick Start

### Terraform (Declarative)

```bash
cd packs/new-relic/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set newrelic_account_id and newrelic_api_key

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
| L1 -- Baseline | `1` | SSO bypass detection, role-based access monitoring, API key management, license key anomaly detection, data obfuscation, data retention monitoring, NrAuditEvent alerting |
| L2 -- Hardened | `2` | L1 + enhanced controls for security-sensitive environments |
| L3 -- Maximum Security | `3` | L1 + L2 + strictest controls for regulated industries |

Set `profile_level` (Terraform variable) once. Every resource respects it.

## Directory Structure

```
new-relic/
├── README.md
└── terraform/                                            # Per-control Terraform files
    ├── providers.tf                                      # Provider configuration
    ├── variables.tf                                      # Input variables
    ├── outputs.tf                                        # Output values
    ├── terraform.tfvars.example                          # Example variable values
    ├── hth-new-relic-1.1-enforce-sso-with-mfa.tf         # SSO bypass detection
    ├── hth-new-relic-1.2-role-based-access.tf            # Access control monitoring
    ├── hth-new-relic-2.1-secure-api-keys.tf              # API key management & monitoring
    ├── hth-new-relic-2.2-license-key-protection.tf       # License key anomaly detection
    ├── hth-new-relic-3.1-configure-data-obfuscation.tf   # Log obfuscation rules
    ├── hth-new-relic-3.2-data-retention.tf               # Data retention compliance
    └── hth-new-relic-4.1-nrauditevent-monitoring.tf      # Audit event alerting
```

## Naming Convention

All files follow: `hth-{vendor}-{section}.{control}-{control-title}.{ext}`

- **Terraform**: `hth-new-relic-2.1-secure-api-keys.tf`
- **Shared files**: `providers.tf`, `variables.tf`, `outputs.tf`

## Terraform Coverage

Each control with Terraform support has its own `.tf` file:

| Control | File | Resources | Description |
|---------|------|-----------|-------------|
| 1.1 | `hth-new-relic-1.1-enforce-sso-with-mfa.tf` | Alert policy + NRQL condition | Detects logins bypassing SAML SSO |
| 1.2 | `hth-new-relic-1.2-role-based-access.tf` | Alert policy + NRQL condition | Detects role/group/permission changes |
| 2.1 | `hth-new-relic-2.1-secure-api-keys.tf` | API access key + alert policy + NRQL condition | Managed ingest key + API key lifecycle alerting |
| 2.2 | `hth-new-relic-2.2-license-key-protection.tf` | Alert policy + NRQL condition | License key usage anomaly detection |
| 3.1 | `hth-new-relic-3.1-configure-data-obfuscation.tf` | Obfuscation expressions + rules + alert | Log data masking for sensitive patterns |
| 3.2 | `hth-new-relic-3.2-data-retention.tf` | Alert policy + 2 NRQL conditions | Data retention change detection + compliance |
| 4.1 | `hth-new-relic-4.1-nrauditevent-monitoring.tf` | Alert policy + 4 NRQL conditions | Configuration, API key, user, and deletion event detection |

### Provider Limitations

The New Relic Terraform provider does not currently support:

- **SAML SSO configuration** (Control 1.1) -- use UI or NerdGraph API
- **Authentication domain management** -- use UI or NerdGraph API
- **Role and group assignment** (Control 1.2) -- use NerdGraph `authorizationManagementGrantAccess` mutation
- **Data retention settings** (Control 3.2) -- use NerdGraph `dataManagementCustomizeRetentions` mutation
- **License key rotation** (Control 2.2) -- use NerdGraph API or UI

For controls without direct Terraform resource support, this pack deploys NRQL alert conditions as compensating detective controls.

## Compliance Coverage

| Framework | Controls Mapped |
|-----------|----------------|
| NIST 800-53 | AC-3, AC-6, AU-2, AU-3, IA-2(1), IA-5, SC-28, SI-12 |
| SOC 2 | CC6.1, CC6.2, CC7.2, CC7.3 |
| ISO 27001 | A.9.2, A.9.4, A.12.4 |
| PCI DSS v4.0 | 8.3, 10.2 |

## Key New Relic Terraform Resources Used

| Resource | Purpose |
|----------|---------|
| `newrelic_api_access_key` | Managed ingest/license key creation |
| `newrelic_alert_policy` | Alert policy grouping for each control |
| `newrelic_nrql_alert_condition` | NRQL-based detection conditions |
| `newrelic_obfuscation_expression` | Regex patterns for sensitive data |
| `newrelic_obfuscation_rule` | Log obfuscation rule application |

## Related

- [New Relic Hardening Guide](https://howtoharden.com/guides/new-relic/) -- Full guide with ClickOps + Code implementations
- [How to Harden](https://howtoharden.com) -- All vendor hardening guides
- [Code Packs Overview](../README.md) -- Architecture and schema documentation
