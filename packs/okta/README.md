# Okta Hardening Code Pack

Runnable security hardening artifacts for [Okta](https://howtoharden.com/guides/okta/). Implements all 34 controls from the Okta hardening guide across authentication, network security, OAuth governance, session management, monitoring, integration risk, and operational security.

## What's Included

| Component | Count | Description |
|-----------|-------|-------------|
| YAML Controls | 34 | Machine-readable definitions with audit checks, remediation, and compliance mappings |
| Terraform | 11 | Per-control `.tf` files for controls 1.1, 1.9, 1.10, 1.11, 2.1, 2.3, 3.4, 4.1, 4.2, 5.2, 5.4 |
| API Scripts | 22 | Per-control hardening scripts + read-only validator |
| Sigma Rules | 24 | Platform-agnostic SIEM detection rules (Splunk, Elastic, Microsoft 365 Defender) |
| IR Runbooks | 3 | Incident response scripts for compromised admin, malicious IdP, unauthorized MFA |
| Utilities | 1 | HAR file sanitizer for safe support ticket submission |

## Prerequisites

- Okta tenant with **Super Admin** access
- API token with appropriate permissions (`Security > API > Tokens`)
- [Terraform](https://www.terraform.io/) >= 1.0 with the [okta/okta provider](https://registry.terraform.io/providers/okta/okta/latest) (for Terraform)
- `bash`, `curl`, `jq` (for API scripts and validation)

## Quick Start

### 1. API Scripts (Audit and Harden)

```bash
cd packs/okta/api

export OKTA_DOMAIN="yourorg.okta.com"
export OKTA_API_TOKEN="your-ssws-token"
export HTH_PROFILE_LEVEL=1  # 1=Baseline, 2=Hardened, 3=Maximum

# Audit first — read-only, changes nothing
bash hth-okta-validate.sh

# Apply individual controls
bash hth-okta-1.01-enforce-phishing-resistant-mfa.sh
bash hth-okta-1.04-configure-password-policy.sh
bash hth-okta-2.01-configure-network-zones.sh

# Apply all controls at once
for f in hth-okta-*.sh; do [ "$f" != "hth-okta-validate.sh" ] && bash "$f"; done
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

### 3. Sigma Rules (SIEM Detection)

Convert Sigma rules to your SIEM's native format using [sigma-cli](https://github.com/SigmaHQ/sigma-cli):

```bash
# Convert all rules to Splunk
sigma convert -t splunk siem/sigma/

# Convert all rules to Elastic Lucene
sigma convert -t elastic_lucene siem/sigma/

# Convert a single control's detection rule
sigma convert -t splunk siem/sigma/hth-okta-1.01-enforce-phishing-resistant-mfa.yml
```

### 4. Incident Response

```bash
# Respond to a compromised admin account
bash scripts/incident-response/hth-okta-ir-compromised-admin.sh

# Respond to a malicious IdP configuration
bash scripts/incident-response/hth-okta-ir-malicious-idp.sh

# Respond to unauthorized MFA enrollment
bash scripts/incident-response/hth-okta-ir-unauthorized-mfa.sh
```

### 5. HAR File Sanitizer

```bash
# Strip credentials from HAR files before sharing with support
bash scripts/hth-okta-har-sanitize.sh recording.har > recording-sanitized.har
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
├── controls/                                          # 34 YAML control definitions
│   ├── hth-okta-1.01-enforce-phishing-resistant-mfa.yaml
│   ├── hth-okta-1.02-admin-role-separation.yaml
│   ├── ...
│   └── hth-okta-7.05-establish-identity-incident-response.yaml
├── terraform/                                         # Per-control Terraform files
│   ├── providers.tf                                   # Provider configuration
│   ├── variables.tf                                   # Input variables
│   ├── outputs.tf                                     # Output values
│   ├── terraform.tfvars.example                       # Example variable values
│   ├── hth-okta-1.01-enforce-phishing-resistant-mfa.tf
│   ├── hth-okta-1.09-audit-default-auth-policy.tf
│   ├── ...
│   └── hth-okta-5.04-behavior-detection.tf
├── api/                                               # Per-control API scripts
│   ├── common.sh                                      # Shared utilities
│   ├── hth-okta-validate.sh                           # Read-only audit
│   ├── hth-okta-1.01-enforce-phishing-resistant-mfa.sh
│   ├── hth-okta-1.02-admin-role-separation.sh
│   ├── ...
│   └── hth-okta-7.03-access-reviews.sh
├── siem/sigma/                                        # Sigma detection rules
│   ├── hth-okta-1.01-enforce-phishing-resistant-mfa.yml
│   ├── hth-okta-1.09-audit-default-auth-policy.yml
│   ├── ...
│   └── hth-okta-7.04-implement-change-management-e.yml
└── scripts/                                           # Operational utilities
    ├── hth-okta-har-sanitize.sh
    └── incident-response/
        ├── hth-okta-ir-compromised-admin.sh
        ├── hth-okta-ir-malicious-idp.sh
        └── hth-okta-ir-unauthorized-mfa.sh
```

## Naming Convention

All files follow: `hth-{vendor}-{section}-{control-title}.{ext}`

- **Controls**: `hth-okta-1.01-enforce-phishing-resistant-mfa.yaml`
- **Terraform**: `hth-okta-1.01-enforce-phishing-resistant-mfa.tf`
- **API Scripts**: `hth-okta-1.01-enforce-phishing-resistant-mfa.sh`
- **Sigma Rules**: `hth-okta-1.01-enforce-phishing-resistant-mfa.yml`
- **Multi-rule controls**: Suffix `-b`, `-c`, etc. (e.g., `hth-okta-1.10-...-b.yml`)
- **Shared files**: `common.sh`, `providers.tf`, `variables.tf`, `outputs.tf`

## Controls

### Section 1 -- Authentication (11 controls)

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

### Section 2 -- Network Security (3 controls)

| # | Control | Level |
|---|---------|-------|
| 2.1 | IP Zones and Network Policies | L1 |
| 2.2 | Admin Console IP Restriction | L1 |
| 2.3 | Anonymizer Blocking | L2 |

### Section 3 -- OAuth & Integration Security (4 controls)

| # | Control | Level |
|---|---------|-------|
| 3.1 | OAuth Consent Policies | L1 |
| 3.2 | SCIM Provisioning Security | L2 |
| 3.3 | OAuth App Allowlisting | L2 |
| 3.4 | Non-Human Identity Governance | L1 |

### Section 4 -- Session Management (3 controls)

| # | Control | Level |
|---|---------|-------|
| 4.1 | Session Timeouts | L1 |
| 4.2 | Disable Session Persistence | L2 |
| 4.3 | Admin Session Security | L1 |

### Section 5 -- Monitoring & Detection (6 controls)

| # | Control | Level |
|---|---------|-------|
| 5.1 | Comprehensive System Logging | L1 |
| 5.2 | ThreatInsight | L1 |
| 5.3 | Identity Threat Protection | L2 |
| 5.4 | Behavior Detection Rules | L2 |
| 5.5 | Cross-Tenant Impersonation | L1 |
| 5.6 | HealthInsight Reviews | L1 |

### Section 6 -- Integration Risk (2 controls)

| # | Control | Level |
|---|---------|-------|
| 6.1 | Integration Risk Assessment | L1 |
| 6.2 | Common Integrations Controls | L1 |

### Section 7 -- Operational Security (5 controls)

| # | Control | Level |
|---|---------|-------|
| 7.1 | HAR File Sanitization | L1 |
| 7.2 | Security Advisory Monitoring | L1 |
| 7.3 | Regular Access Reviews | L1 |
| 7.4 | Change Management | L2 |
| 7.5 | Identity Incident Response | L2 |

## Terraform Coverage

Each control with Terraform support has its own `.tf` file:

| Control | File | Description |
|---------|------|-------------|
| 1.1 | `hth-okta-1.01-enforce-phishing-resistant-mfa.tf` | FIDO2 authenticator + signon policy |
| 1.9 | `hth-okta-1.09-audit-default-auth-policy.tf` | Default policy + MFA catch-all |
| 1.10 | `hth-okta-1.10-harden-self-service-recovery.tf` | Recovery restrictions + password policy |
| 1.11 | `hth-okta-1.11-enable-security-notifications.tf` | Org config + notification provisioners |
| 2.1 | `hth-okta-2.01-configure-network-zones.tf` | Corporate + blocklist IP zones |
| 2.3 | `hth-okta-2.03-block-anonymizers.tf` | Anonymizer + country block zones |
| 3.4 | `hth-okta-3.04-govern-non-human-identities.tf` | Service OAuth app + API scopes |
| 4.1 | `hth-okta-4.01-configure-session-timeouts.tf` | Session timeout policy + rule |
| 4.2 | `hth-okta-4.02-disable-session-persistence.tf` | Non-persistent session policy |
| 5.2 | `hth-okta-5.02-configure-threatinsight.tf` | ThreatInsight block mode |
| 5.4 | `hth-okta-5.04-behavior-detection.tf` | Location + device behaviour rules |

Controls not covered by Terraform require API scripts or manual configuration.

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
