# Snowflake Hardening Code Pack

Runnable security hardening artifacts for [Snowflake](https://howtoharden.com/guides/snowflake/). Implements controls from the Snowflake hardening guide across authentication, network security, OAuth governance, data security, and monitoring.

## What's Included

| Component | Count | Description |
|-----------|-------|-------------|
| Terraform | 5 | Per-control `.tf` files for controls 1.1, 1.3, 2.1, 3.1, 4.1 |
| API Scripts | 5 | Per-control hardening scripts using `snowsql` |
| Sigma Rules | 3 | Platform-agnostic SIEM detection rules |

## Prerequisites

- Snowflake account with **ACCOUNTADMIN** or **SECURITYADMIN** role
- [snowsql](https://docs.snowflake.com/en/user-guide/snowsql) CLI installed (for API scripts)
- Authentication via RSA key-pair (preferred) or password
- [Terraform](https://www.terraform.io/) >= 1.0 with the [Snowflake-Labs/snowflake provider](https://registry.terraform.io/providers/Snowflake-Labs/snowflake/latest) (for Terraform)
- `bash`, `jq` (for API scripts)

## Quick Start

### 1. API Scripts (Audit and Harden)

```bash
cd packs/snowflake/api

export SNOWFLAKE_ACCOUNT="xy12345.us-east-1"
export SNOWFLAKE_USER="your_admin_user"
export SNOWFLAKE_PRIVATE_KEY="/path/to/rsa_key.p8"  # or SNOWFLAKE_PASSWORD
export HTH_PROFILE_LEVEL=1  # 1=Baseline, 2=Hardened, 3=Maximum

# Apply individual controls
bash hth-snowflake-1.01-enforce-mfa.sh
bash hth-snowflake-1.03-implement-rbac.sh
bash hth-snowflake-2.01-implement-network-policies.sh
bash hth-snowflake-3.01-restrict-oauth-scopes.sh
bash hth-snowflake-5.01-enable-audit-logging.sh

# Apply all controls at once
for f in hth-snowflake-*.sh; do bash "$f"; done
```

### 2. Terraform (Declarative)

```bash
cd packs/snowflake/terraform

terraform init
terraform plan -var="profile_level=1" -var="snowflake_account=xy12345.us-east-1" -var="snowflake_user=admin"
terraform apply -var="profile_level=1"   # Apply L1 (Baseline)
terraform apply -var="profile_level=2"   # Apply L1 + L2 (Hardened)
```

### 3. Sigma Rules (SIEM Detection)

Convert Sigma rules to your SIEM's native format using [sigma-cli](https://github.com/SigmaHQ/sigma-cli):

```bash
# Convert all rules to Splunk
sigma convert -t splunk siem/sigma/

# Convert all rules to Elastic Lucene
sigma convert -t elastic_lucene siem/sigma/

# Convert a single detection rule
sigma convert -t splunk siem/sigma/hth-snowflake-1.01-mfa-bypass-attempt.yml
```

## Profile Levels

Controls are gated by cumulative profile levels:

| Level | Variable Value | What Gets Applied |
|-------|---------------|-------------------|
| L1 -- Baseline | `1` | MFA enforcement, RBAC with custom roles, network policies, OAuth scope restriction, audit logging |
| L2 -- Hardened | `2` | L1 + private connectivity, external OAuth, column-level masking, row access policies |
| L3 -- Maximum Security | `3` | L1 + L2 + data sharing restrictions, advanced monitoring |

Set `HTH_PROFILE_LEVEL` (API scripts) or `profile_level` (Terraform variable) once. Every script and resource respects it.

## Directory Structure

```
snowflake/
├── README.md
├── api/                                                  # Per-control SQL scripts
│   ├── common.sh                                         # Shared utilities (snowsql wrapper)
│   ├── hth-snowflake-1.01-enforce-mfa.sh
│   ├── hth-snowflake-1.03-implement-rbac.sh
│   ├── hth-snowflake-2.01-implement-network-policies.sh
│   ├── hth-snowflake-3.01-restrict-oauth-scopes.sh
│   └── hth-snowflake-5.01-enable-audit-logging.sh
├── terraform/                                            # Per-control Terraform files
│   ├── providers.tf                                      # Provider configuration
│   ├── variables.tf                                      # Input variables
│   ├── hth-snowflake-1.01-enforce-mfa.tf
│   ├── hth-snowflake-1.03-implement-rbac.tf
│   ├── hth-snowflake-2.01-implement-network-policies.tf
│   ├── hth-snowflake-3.01-restrict-oauth-scopes.tf
│   └── hth-snowflake-4.01-column-masking.tf
└── siem/sigma/                                           # Sigma detection rules
    ├── hth-snowflake-1.01-mfa-bypass-attempt.yml
    ├── hth-snowflake-2.01-network-policy-modified.yml
    └── hth-snowflake-5.01-bulk-data-export.yml
```

## Naming Convention

All files follow: `hth-{vendor}-{section}-{control-title}.{ext}`

- **Terraform**: `hth-snowflake-1.01-enforce-mfa.tf`
- **API Scripts**: `hth-snowflake-1.01-enforce-mfa.sh`
- **Sigma Rules**: `hth-snowflake-1.01-mfa-bypass-attempt.yml`
- **Shared files**: `common.sh`, `providers.tf`, `variables.tf`

## Controls

### Section 1 -- Authentication & Access Controls (3 controls)

| # | Control | Level |
|---|---------|-------|
| 1.1 | Enforce MFA for All Users | L1 |
| 1.2 | Service Account Key-Pair Auth | L1 |
| 1.3 | RBAC with Custom Roles | L1 |

### Section 2 -- Network Access Controls (2 controls)

| # | Control | Level |
|---|---------|-------|
| 2.1 | Implement Network Policies | L1 |
| 2.2 | Enable Private Connectivity | L2 |

### Section 3 -- OAuth & Integration Security (2 controls)

| # | Control | Level |
|---|---------|-------|
| 3.1 | Restrict OAuth Token Scope and Lifetime | L1 |
| 3.2 | Implement External OAuth | L2 |

### Section 4 -- Data Security (3 controls)

| # | Control | Level |
|---|---------|-------|
| 4.1 | Column-Level Security with Masking | L2 |
| 4.2 | Row Access Policies | L2 |
| 4.3 | Restrict Data Sharing | L1 |

### Section 5 -- Monitoring & Detection (2 controls)

| # | Control | Level |
|---|---------|-------|
| 5.1 | Comprehensive Audit Logging | L1 |
| 5.2 | Forward Logs to SIEM | L1 |

## Terraform Coverage

| Control | File | Description |
|---------|------|-------------|
| 1.1 | `hth-snowflake-1.01-enforce-mfa.tf` | Authentication policy + service account example |
| 1.3 | `hth-snowflake-1.03-implement-rbac.tf` | Custom role hierarchy + grants |
| 2.1 | `hth-snowflake-2.01-implement-network-policies.tf` | Network policies + account attachment |
| 3.1 | `hth-snowflake-3.01-restrict-oauth-scopes.tf` | OAuth integration + blocked roles |
| 4.1 | `hth-snowflake-4.01-column-masking.tf` | Dynamic masking + row access policies |

## Compliance Coverage

| Framework | Controls Mapped |
|-----------|----------------|
| SOC 2 | CC6.1, CC6.2, CC6.6, CC7.2 |
| NIST 800-53 | AC-3, AC-6, AC-21, AU-2, AU-3, AU-6, IA-2, IA-5, SC-7, SC-28 |
| ISO 27001 | A.9.2, A.9.4, A.12.4, A.13.1 |
| PCI DSS v4.0 | 7.2, 8.3, 8.4, 10.2 |

## Related

- [Snowflake Hardening Guide](https://howtoharden.com/guides/snowflake/) -- Full guide with ClickOps + Code implementations
- [How to Harden](https://howtoharden.com) -- All vendor hardening guides
- [Code Packs Overview](../README.md) -- Architecture and schema documentation
