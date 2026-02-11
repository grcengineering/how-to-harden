# Okta Hardening Code Pack

Runnable security hardening artifacts for [Okta](https://howtoharden.com/guides/okta/). Implements all 34 controls from the Okta hardening guide across authentication, network security, OAuth governance, session management, monitoring, integration risk, and operational security.

## What's Included

| Component | Count | Description |
|-----------|-------|-------------|
| YAML Controls | 34 | Machine-readable definitions with audit checks, remediation, and compliance mappings |
| Terraform Resources | 11 | Declarative modules for controls 1.1, 1.9, 1.10, 1.11, 2.1, 2.3, 3.4, 4.1, 4.2, 5.2, 5.4 |
| API Scripts | 8 | Section-specific hardening scripts (sections 1-5, 7) + read-only validator |
| SIEM Queries | 30 | Detection queries for Splunk, Elastic, and SQL-based SIEMs |
| IR Runbooks | 3 | Incident response scripts for compromised admin, malicious IdP, unauthorized MFA |
| Utilities | 1 | HAR file sanitizer for safe support ticket submission |

## Prerequisites

- Okta tenant with **Super Admin** access
- API token with appropriate permissions (`Security > API > Tokens`)
- [Terraform](https://www.terraform.io/) >= 1.0 with the [okta/okta provider](https://registry.terraform.io/providers/okta/okta/latest) (for Terraform modules)
- `bash`, `curl`, `jq` (for API scripts and validation)

## Quick Start

### 1. API Scripts (Audit and Harden)

```bash
cd packs/okta/api

export OKTA_DOMAIN="yourorg.okta.com"
export OKTA_API_TOKEN="your-ssws-token"
export HTH_PROFILE_LEVEL=1  # 1=Baseline, 2=Hardened, 3=Maximum

# Audit first — read-only, changes nothing
bash validate.sh

# Apply hardening section by section
bash 01-auth-controls.sh
bash 02-network-controls.sh
bash 03-oauth-security.sh
bash 04-session-mgmt.sh
bash 05-monitoring.sh
bash 07-operational.sh
```

### 2. Terraform (Declarative)

```bash
cd packs/okta/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set okta_domain and okta_api_token

terraform init
terraform plan -var="profile_level=1"   # Preview L1 changes
terraform apply -var="profile_level=1"  # Apply L1 (Baseline)
terraform apply -var="profile_level=2"  # Apply L1 + L2 (Hardened)
terraform apply -var="profile_level=3"  # Apply all controls
```

### 3. SIEM Queries

Import `siem/queries.yaml` into your SIEM platform. Queries are structured with severity levels, MITRE ATT&CK mappings, and platform-agnostic syntax adaptable to Splunk SPL, Elastic KQL, or SQL.

### 4. Incident Response

```bash
# Respond to a compromised admin account
bash scripts/incident-response/compromised-admin.sh

# Respond to a malicious IdP configuration
bash scripts/incident-response/malicious-idp.sh

# Respond to unauthorized MFA enrollment
bash scripts/incident-response/unauthorized-mfa.sh
```

### 5. HAR File Sanitizer

```bash
# Strip credentials from HAR files before sharing with support
bash scripts/har-sanitize.sh recording.har > recording-sanitized.har
```

## Profile Levels

Controls are gated by cumulative profile levels:

| Level | Variable Value | What Gets Applied |
|-------|---------------|-------------------|
| L1 -- Baseline | `1` | MFA enforcement, password policy, lockout, network zones, OAuth consent, session timeouts, logging, ThreatInsight, security notifications, NHI governance, HAR sanitization, access reviews |
| L2 -- Hardened | `2` | L1 + device-bound sessions, anonymizer blocking, SCIM hardening, OAuth allowlisting, session persistence disabled, Identity Threat Protection, behavior detection, change management, IR procedures |
| L3 -- Maximum Security | `3` | L1 + L2 + PIV/CAC smart card authentication, FIPS-compliant authenticators |

Set `HTH_PROFILE_LEVEL` (API scripts) or `profile_level` (Terraform variable) once. Every script and resource respects it.

## Directory Structure

```
okta/
├── README.md
├── controls/                        # 34 YAML control definitions
│   ├── 1.01-enforce-phishing-resistant-mfa.yaml
│   ├── 1.02-admin-role-separation.yaml
│   ├── ...
│   ├── 6.01-integration-risk-assessment.yaml
│   ├── 6.02-common-integrations-controls.yaml
│   └── 7.05-establish-identity-incident-response.yaml
├── terraform/                       # Terraform modules
│   ├── main.tf                      # Resources gated by profile_level
│   ├── variables.tf                 # Input variables including profile_level
│   ├── outputs.tf                   # Output values
│   ├── providers.tf                 # Provider configuration
│   └── terraform.tfvars.example     # Example variable values
├── api/                             # API hardening scripts
│   ├── common.sh                    # Shared utilities (logging, API calls, profile gating)
│   ├── validate.sh                  # Read-only audit across all sections
│   ├── 01-auth-controls.sh          # Section 1: Authentication (11 controls)
│   ├── 02-network-controls.sh       # Section 2: Network Security (3 controls)
│   ├── 03-oauth-security.sh         # Section 3: OAuth & Integrations (4 controls)
│   ├── 04-session-mgmt.sh           # Section 4: Session Management (3 controls)
│   ├── 05-monitoring.sh             # Section 5: Monitoring & Detection (6 controls)
│   └── 07-operational.sh            # Section 7: Operational Security (5 controls)
├── siem/                            # Detection queries
│   └── queries.yaml                 # 30 queries with severity and MITRE mappings
└── scripts/                         # Operational utilities
    ├── har-sanitize.sh              # Strip credentials from HAR files
    └── incident-response/
        ├── compromised-admin.sh     # Compromised admin account response
        ├── malicious-idp.sh         # Malicious IdP detection and response
        └── unauthorized-mfa.sh      # Unauthorized MFA enrollment response
```

## Controls

### Section 1 — Authentication (11 controls)

| # | Control | Level |
|---|---------|-------|
| 1.1 | Enforce Phishing-Resistant MFA | L1 |
| 1.2 | Admin Role Separation | L1 |
| 1.3 | Hardware-Bound Session Tokens | L2 |
| 1.4 | Password Policy | L1 |
| 1.5 | Account Lockout | L1 |
| 1.6 | Account Lifecycle Management | L1 |
| 1.7 | PIV/CAC Smart Card Auth | L3 |
| 1.8 | FIPS-Compliant Authenticators | L3 |
| 1.9 | Default Auth Policy Audit | L1 |
| 1.10 | Harden Self-Service Recovery | L1 |
| 1.11 | End-User Security Notifications | L1 |

### Section 2 — Network Security (3 controls)

| # | Control | Level |
|---|---------|-------|
| 2.1 | IP Zones and Network Policies | L1 |
| 2.2 | Admin Console IP Restriction | L1 |
| 2.3 | Anonymizer Blocking | L2 |

### Section 3 — OAuth & Integration Security (4 controls)

| # | Control | Level |
|---|---------|-------|
| 3.1 | OAuth Consent Policies | L1 |
| 3.2 | SCIM Provisioning Security | L2 |
| 3.3 | OAuth App Allowlisting | L2 |
| 3.4 | Non-Human Identity Governance | L1 |

### Section 4 — Session Management (3 controls)

| # | Control | Level |
|---|---------|-------|
| 4.1 | Session Timeouts | L1 |
| 4.2 | Disable Session Persistence | L2 |
| 4.3 | Admin Session Security | L1 |

### Section 5 — Monitoring & Detection (6 controls)

| # | Control | Level |
|---|---------|-------|
| 5.1 | Comprehensive System Logging | L1 |
| 5.2 | ThreatInsight | L1 |
| 5.3 | Identity Threat Protection | L2 |
| 5.4 | Behavior Detection Rules | L2 |
| 5.5 | Cross-Tenant Impersonation | L1 |
| 5.6 | HealthInsight Reviews | L1 |

### Section 6 — Integration Risk (2 controls)

| # | Control | Level |
|---|---------|-------|
| 6.1 | Integration Risk Assessment | L1 |
| 6.2 | Common Integrations Controls | L1 |

### Section 7 — Operational Security (5 controls)

| # | Control | Level |
|---|---------|-------|
| 7.1 | HAR File Sanitization | L1 |
| 7.2 | Security Advisory Monitoring | L1 |
| 7.3 | Regular Access Reviews | L1 |
| 7.4 | Change Management | L2 |
| 7.5 | Identity Incident Response | L2 |

## Terraform Coverage

The Terraform module manages the following controls declaratively:

| Control | Resource Type | Description |
|---------|--------------|-------------|
| 1.1 | `okta_policy_mfa` | Phishing-resistant MFA enrollment policy |
| 1.9 | `okta_policy_signon` | Default authentication policy hardening |
| 1.10 | `okta_policy_password` | Self-service recovery restrictions |
| 1.11 | `okta_template_email` | End-user security notification templates |
| 2.1 | `okta_network_zone` | IP-based network zone definitions |
| 2.3 | `okta_network_zone` | Anonymizer/proxy blocking zone |
| 3.4 | `okta_app_oauth` | Non-human identity scope restrictions |
| 4.1 | `okta_policy_signon` | Session timeout configuration |
| 4.2 | `okta_policy_signon` | Session persistence disabled |
| 5.2 | `okta_threat_insight_settings` | ThreatInsight action mode |
| 5.4 | `okta_behavior` | Behavior detection rule definitions |

Controls not covered by Terraform (2.2, 3.1, 3.2, 3.3, 4.3, 5.1, 5.3, 5.5, 5.6, 6.x, 7.x) require API scripts or manual configuration. Use the API scripts for full coverage.

## Compliance Coverage

| Framework | Controls Mapped |
|-----------|----------------|
| SOC 2 | CC6.1, CC6.2, CC6.6, CC7.2, CC7.3, CC8.1 |
| NIST 800-53 | AC-2, AC-3, AC-5, AC-6, AC-7, AC-12, AU-2, AU-6, CA-7, CM-3, CM-7, IA-2, IA-4, IA-5, IR-4, IR-6, RA-5, SC-7, SC-13, SC-23, SC-28, SI-4, SI-5, SI-12 |
| DISA STIG | V-273186 through V-273209 |
| ISO 27001 | A.9.2, A.9.4, A.12.4 |
| PCI DSS v4.0 | 8.3, 8.4, 10.2 |

## Related

- [Okta Hardening Guide](https://howtoharden.com/guides/okta/) -- Full guide with ClickOps + Code implementations
- [How to Harden](https://howtoharden.com) -- All vendor hardening guides
- [Code Packs Overview](../README.md) -- Architecture and schema documentation
