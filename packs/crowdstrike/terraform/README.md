# CrowdStrike Falcon Hardening - Terraform Code Pack

Terraform implementation of security hardening controls from the [CrowdStrike Falcon Hardening Guide](https://howtoharden.com/guides/crowdstrike/). Covers sensor anti-tamper, prevention policy hardening, staged content deployment (post-July 2024 lesson), sensor update rollback, and response policy controls.

## What's Included

| Control | File | Profile | Description |
|---------|------|---------|-------------|
| 3.1 | `hth-crowdstrike-3.1-prevent-unauthorized-sensor-uninstall.tf` | L1 | Sensor update policies with uninstall protection (Windows, Linux, Mac) |
| 3.2 | `hth-crowdstrike-3.2-configure-prevention-policy-hardening.tf` | L1+ | Prevention policies with ML levels scaling by profile (Windows, Linux, Mac) |
| 3.3 | `hth-crowdstrike-3.3-implement-sensor-grouping-strategy.tf` | L1 | Host groups for canary, production-critical, production-standard, workstations |
| 4.1 | `hth-crowdstrike-4.1-implement-staged-content-deployment.tf` | L1 | Content update policies with tiered delay rings (canary/early-adopter/production/critical) |
| 4.2 | `hth-crowdstrike-4.2-configure-rollback-procedures.tf` | L2 | Sensor update policies with N-1 versioning and maintenance windows |
| 5.1 | `hth-crowdstrike-5.1-configure-detection-tuning.tf` | L1 | Real Time Response policies with capability restrictions by profile |

## Prerequisites

- CrowdStrike Falcon tenant with **Falcon Administrator** access
- API client with required scopes:
  - Prevention policies (Read & Write)
  - Sensor update policies (Read & Write)
  - Host groups (Read & Write)
  - Content Update Policy (Read & Write)
  - Response Policies (Read & Write)
  - Firewall management (Read & Write)
- [Terraform](https://www.terraform.io/) >= 1.0 with the [crowdstrike/crowdstrike provider](https://registry.terraform.io/providers/CrowdStrike/crowdstrike/latest)

## Quick Start

```bash
cd packs/crowdstrike/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set crowdstrike_client_id and crowdstrike_client_secret

terraform init
terraform plan -var="profile_level=1"   # Preview L1 changes
terraform apply -var="profile_level=1"  # Apply L1 (Baseline)
terraform apply -var="profile_level=2"  # Apply L1 + L2 (Hardened)
terraform apply -var="profile_level=3"  # Apply all controls
```

### Environment Variables (Recommended)

```bash
export TF_VAR_crowdstrike_client_id="your-client-id"
export TF_VAR_crowdstrike_client_secret="your-client-secret"
terraform plan
```

## Profile Levels

Controls are gated by cumulative profile levels:

| Level | Variable Value | What Gets Applied |
|-------|---------------|-------------------|
| L1 -- Baseline | `1` | Anti-tamper (uninstall protection), MODERATE ML prevention policies (Windows/Linux/Mac), host groups (canary, production-critical, production-standard, workstations), staged content deployment (3 rings), basic RTR policy (read-only response) |
| L2 -- Hardened | `2` | L1 + AGGRESSIVE ML levels, early-adopter host group, 4-ring content deployment, N-1 sensor update policies with maintenance windows, memory scanning, driver load prevention, vulnerable driver protection, RTR put/custom scripts |
| L3 -- Maximum Security | `3` | L1 + L2 + EXTRA_AGGRESSIVE ML levels, critical infrastructure sensor update policy, container drift prevention (Linux), full RTR exec capability |

## Host Tagging

This pack uses [SensorGroupingTags](https://falcon.crowdstrike.com/documentation/hosts/host-groups) for dynamic host group assignment. Tag hosts during sensor installation:

```bash
# Windows (installer flag)
CsInstall.exe /install /quiet /groupTag="canary"

# Linux
sudo /opt/CrowdStrike/falconctl -s --tags="SensorGroupingTags/canary"

# Mac
sudo /Applications/Falcon.app/Contents/Resources/falconctl grouping-tags set canary
```

Available tags used by this pack:
- `canary` -- Early update testing (1-5% of fleet)
- `early-adopter` -- Validation ring (L2+, ~10% of fleet)
- `production-critical` -- Domain controllers, databases, payment systems
- `production-standard` -- Application servers, web servers
- `workstation` -- End-user devices

## Content Update Rings (Post-July 2024)

The July 2024 CrowdStrike outage demonstrated the critical importance of staged content deployment. This pack implements tiered content update rings:

```
Canary (1-5%)          --> 0h delay   --> Early issue detection
Early Adopter (10%)    --> 4h delay   --> Validation (L2+)
Production (85%)       --> 24h delay  --> Stable deployment
Production-Critical    --> 48h delay  --> Maximum caution
```

## Controls Not Covered by Terraform

The following guide controls require API scripts, IdP configuration, or manual setup:

| Control | Reason |
|---------|--------|
| 1.1 MFA Enforcement | Configured via IdP (Okta/Azure AD) SSO settings |
| 1.2 RBAC | No Terraform resource for Falcon user/role management |
| 1.3 IP-Based Access Controls | Configured via IdP network policies |
| 2.1 API Client Management | API client creation uses OAuth2 management APIs |
| 2.2 API Rate Limiting | Monitoring-only; no configuration resource |
| 5.2 SIEM Event Forwarding | Streaming API configuration via API client |
| 6.1 Integration Risk Assessment | Process/documentation control |
| 6.2 SIEM/SOAR Integration Controls | Per-integration API client scoping |

## Directory Structure

```
crowdstrike/terraform/
├── README.md
├── providers.tf                                                # Provider configuration
├── variables.tf                                                # Input variables with profile_level
├── outputs.tf                                                  # Output values for verification
├── terraform.tfvars.example                                    # Example variable values
├── hth-crowdstrike-3.1-prevent-unauthorized-sensor-uninstall.tf
├── hth-crowdstrike-3.2-configure-prevention-policy-hardening.tf
├── hth-crowdstrike-3.3-implement-sensor-grouping-strategy.tf
├── hth-crowdstrike-4.1-implement-staged-content-deployment.tf
├── hth-crowdstrike-4.2-configure-rollback-procedures.tf
└── hth-crowdstrike-5.1-configure-detection-tuning.tf
```

## Compliance Coverage

| Framework | Controls Mapped |
|-----------|----------------|
| NIST 800-53 | SI-3 (Malware Protection), SI-4 (System Monitoring), CM-2 (Baseline Config), CM-3 (Change Control) |
| SOC 2 | CC6.1, CC6.2, CC7.2 |
| PCI DSS | 5.2 (Anti-Malware), 6.3 (Change Control) |

## Related

- [CrowdStrike Falcon Hardening Guide](https://howtoharden.com/guides/crowdstrike/) -- Full guide with ClickOps + Code implementations
- [How to Harden](https://howtoharden.com) -- All vendor hardening guides
- [CrowdStrike Terraform Provider](https://registry.terraform.io/providers/CrowdStrike/crowdstrike/latest/docs) -- Provider documentation
- [Code Packs Overview](../../README.md) -- Architecture and schema documentation
