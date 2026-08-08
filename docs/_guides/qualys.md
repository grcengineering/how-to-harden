---
layout: guide
title: "Qualys Hardening Guide"
vendor: "Qualys"
slug: "qualys"
tier: "2"
category: "Security"
description: "Vulnerability management platform hardening for Qualys VMDR including user access, scanning configuration, and policy compliance"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

Qualys operates the **Enterprise TruRisk Platform** (formerly branded the Qualys Cloud Platform), a cloud-based vulnerability management, detection, response, and compliance suite protecting **millions of assets** across enterprises worldwide. As a critical security tool with deep access to infrastructure, Qualys configurations directly impact vulnerability visibility and remediation effectiveness. Proper hardening ensures security data integrity and prevents unauthorized access to sensitive vulnerability information.

### Intended Audience
- Security engineers managing vulnerability programs
- IT administrators configuring Qualys
- GRC professionals using Policy Compliance and Policy Audit
- SOC analysts managing vulnerability data

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Enterprise TruRisk Platform security including user management, API authentication, activity logging, scanning configuration, compliance assessment (Policy Compliance and Policy Audit), and Security Configuration Assessment (SCA).

---

## Table of Contents

1. [Access & Authentication](#1-access--authentication)
2. [Scanning Configuration](#2-scanning-configuration)
3. [Policy Compliance](#3-policy-compliance)
4. [Asset Management](#4-asset-management)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Access & Authentication

### 1.1 Configure SSO Authentication

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for Qualys platform.

#### Rationale
**Why This Matters:**
- Centralizes Qualys authentication in your corporate IdP, enforcing MFA, conditional access, and session policy on every login
- Local Qualys passwords bypass IdP controls and are prime targets for credential stuffing, phishing, and password reuse
- Centralized provisioning and deprovisioning removes departed users automatically, eliminating orphaned accounts with standing access to vulnerability data
- Qualys holds a complete map of every unpatched weakness across your estate, so a single compromised login hands an attacker a ready-made target list

**Attack Prevented:** Credential theft, phishing, password reuse, orphaned-account access

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Administration** → **User Management** → **Authentication**
2. Click **SAML Authentication**

**Step 2: Configure SAML**
1. Enable SAML authentication
2. Configure IdP settings:
   - IdP SSO URL
   - IdP Certificate
   - Entity ID
3. Download Qualys SP metadata

**Step 3: Configure IdP**
1. Create SAML application
2. Configure attribute mappings
3. Assign users/groups

**Step 4: Enable SSO Enforcement**
1. Test SSO authentication
2. Enable SSO for users
3. Disable password authentication

**Time to Complete:** ~1 hour

---

### 1.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all users, especially administrators.

#### Rationale
**Why This Matters:**
- Admin accounts without MFA pose significant risk
- Qualys admins have access to all vulnerability data
- MFA should be enforced via SSO/IdP

**Attack Prevented:** Credential theft, password reuse, phishing-driven account takeover, unauthorized access to vulnerability data

#### ClickOps Implementation

**Step 1: Configure MFA for Non-SSO Users**
1. Navigate to: **Administration** → **User Management** → **Users**
2. Enable 2FA requirement for each user
3. Or enforce through SSO/IdP

**Step 2: Protect Admin Accounts**
1. Ensure all admin accounts have MFA
2. Use strong passwords stored in vault
3. Consider hardware keys for admins

**Step 3: Verify Compliance**
1. Review user MFA status
2. Follow up with non-compliant users
3. Document exceptions

---

### 1.3 Implement Role-Based Access Control

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure granular roles for least privilege access.

#### Rationale
**Why This Matters:**
- Least-privilege roles ensure each user can only perform the actions their job requires, limiting the blast radius of any single compromised account
- Restricting the Manager (full admin) role to a small set of named personnel prevents over-broad control of scan configs, credentials, and platform settings
- Scoped roles keep read-only stakeholders from altering scan targets, deleting findings, or exporting sensitive vulnerability data
- Clear role boundaries make access reviews and audit attestation straightforward

**Attack Prevented:** Privilege escalation, insider misuse, unauthorized data export, lateral movement

#### ClickOps Implementation

**Step 1: Review Built-in Roles**
1. Navigate to: **Administration** → **User Management** → **Roles**
2. Review available roles:
   - **Manager:** Full administrative access
   - **Unit Manager:** Team management
   - **Scanner:** Scanning only
   - **Reader:** View only

**Step 2: Create Custom Roles**
1. Click **New Role**
2. Configure permissions:
   - Asset management
   - Scanning
   - Reporting
   - Policy compliance
3. Apply principle of least privilege

**Step 3: Assign Appropriate Roles**
1. Limit Manager to essential personnel (2-3)
2. Use Scanner for vulnerability teams
3. Use Reader for stakeholders

---


{% include pack-code.html vendor="qualys" section="1.3" %}

### 1.4 Configure IP Restrictions

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Restrict Qualys access to approved IP addresses.

#### Rationale
**Why This Matters:**
- Limiting access to known corporate and VPN egress ranges blocks logins from anywhere else, even when valid credentials are stolen
- Network-layer restrictions add a control independent of password and MFA strength, raising the bar for remote attackers
- Tighter restrictions on admin accounts shrink the exposed surface for the most powerful identities
- Reduces the value of phished or leaked credentials, since they cannot be used from attacker-controlled infrastructure

**Attack Prevented:** Credential stuffing from untrusted networks, remote account takeover, session hijacking

#### ClickOps Implementation

**Step 1: Configure IP Allowlist**
1. Navigate to: **Administration** → **User Management** → **Allowed IPs**
2. Add corporate network IPs
3. Add VPN egress IPs

**Step 2: Apply to User Accounts**
1. Configure IP restrictions per user
2. Apply stricter restrictions to admins
3. Test access restrictions

---

### 1.5 Govern API External IDs for Programmatic Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.7 |
| NIST 800-53 | IA-2, IA-5 |

#### Description
Assign and govern the per-user **API External ID**, the field that maps a Qualys user account to an external identity so the platform can accept OAuth/OIDC JWT-based API authentication for that user. Treat each External ID as a named, owned, revocable programmatic credential rather than a convenience setting.

#### Rationale
**Why This Matters:**
- API access to Qualys carries the same authority as the console user it is bound to, so an unscoped or over-privileged API user exposes the entire vulnerability inventory programmatically
- Mapping API identity to an external IdP subject moves API authentication behind the same lifecycle as human accounts, so a departed employee's or decommissioned integration's access dies with the IdP identity instead of living on as a static credential
- The External ID is case-sensitive and accepts alphanumeric strings, email addresses, or custom identifiers, which makes near-miss values easy to introduce and hard to audit unless a naming convention is enforced
- Recording an owner for every API-enabled account is what makes revocation possible during an incident; unattributed integration accounts are the ones that survive credential rotations

**Attack Prevented:** Orphaned integration credentials, unattributed API access, privilege escalation through over-scoped API users, persistence via API identity after IdP deprovisioning

#### ClickOps Implementation

**Step 1: Set the External ID on the API user**
1. Navigate to: **Users** → **New** → **Users** → **General Information**
2. Populate the **API External ID** field with the external identity that will present the JWT
3. Enter the value exactly — the field is case-sensitive, and alphanumeric strings, email addresses, and custom identifiers are all accepted

**Step 2: Scope the account to least privilege**
1. Assign the API user the narrowest role its integration actually requires (see [1.3](#13-implement-role-based-access-control)) — never the Manager role by default
2. Create one API user per integration so a single revocation does not break unrelated automation
3. Apply IP restrictions (see [1.4](#14-configure-ip-restrictions)) to API users whose callers have fixed egress addresses

**Step 3: Record ownership and review**
1. Document the named human owner, the consuming system, and the business justification for every account carrying an External ID
2. Re-verify External ID values against the IdP during access reviews — a stale or mistyped mapping either breaks the integration or silently binds it to the wrong identity
3. Clear the External ID and disable the account when the integration is retired

---

### 1.6 Monitor Activity and Change Logs

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2, 8.5 |
| NIST 800-53 | AU-2, AU-6, AU-11 |

#### Description
Review the Qualys Activity Log for authentication events and the QID change log for detection-content changes, and export both to your SIEM so platform abuse is detected rather than merely recorded.

#### Rationale
**Why This Matters:**
- The Activity Log records each login attempt with its success or failure state, the failure reason, the source IP address, the user agent, and the timestamp — enough detail to distinguish a forgotten password from credential stuffing against the subscription
- Source IP and user agent are what turn a failed-login count into an investigable event, since a spray from unfamiliar infrastructure looks nothing like a user fumbling MFA
- The QID change log records both user-initiated and system-initiated changes along with the username responsible and retains two years of history, which is what lets an auditor prove that a detection was not quietly suppressed
- Logs that live only in the console are reviewed only after an incident is already known; forwarding them to the SIEM is what makes alerting on anomalous logins possible in the first place

**Attack Prevented:** Undetected credential stuffing, unauthorized configuration change, detection tampering, insider abuse of vulnerability data

#### ClickOps Implementation

**Step 1: Review authentication activity**
1. Navigate to: **Administration** → **Activity Log**
2. Filter for login events and review the success/failure state, failure reason, source IP address, user agent, and timestamp on each
3. Investigate repeated failures against a single account, and any success from an IP range outside your allowlist (see [1.4](#14-configure-ip-restrictions))

**Step 2: Review detection-content changes**
1. Open the QID change log and review entries for both user-initiated and system-initiated changes
2. Confirm each user-initiated change is attributable to a named administrator and matches an approved request
3. Two years of change history are retained — use it to evidence detection continuity during audits

**Step 3: Export and alert**
1. Export or stream Activity Log data to your SIEM for retention beyond the console's window
2. Alert on failed-login bursts, logins from unexpected source IPs or user agents, role changes, and API user creation
3. Re-verify the export after any subscription or user-management change

---

## 2. Scanning Configuration

### 2.1 Secure Scan Credentials

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Securely manage credentials used for authenticated scanning.

#### Rationale
**Why This Matters:**
- Scan credentials have privileged access
- Compromised credentials can expose infrastructure
- Qualys encrypts credentials but proper management is critical

**Attack Prevented:** Scan-credential theft, privilege escalation via over-permissioned scan accounts, lateral movement from a compromised scanner, long-lived static secrets

#### ClickOps Implementation

**Step 1: Create Dedicated Scan Accounts**
1. Create dedicated service accounts for scanning
2. Grant minimum required permissions:
   - Read access for vulnerability scanning
   - Admin only if compliance required
3. Do not use admin/root accounts

**Step 2: Configure Credential Vaults**
1. Navigate to: **Scans** → **Authentication** → **Vault**
2. Configure a supported credential vault so Qualys retrieves secrets at scan time instead of storing them:
   - CyberArk PIM Suite
   - CyberArk AIM
   - Thycotic Secret Server
   - HashiCorp Vault
   - Azure Key Vault
   - Quest Vault
   - One Identity Safeguard (NSX)
3. Retrieve credentials dynamically

**Step 3: Rotate Credentials**
1. Establish rotation schedule
2. Update credentials in Qualys
3. Verify scanning still works

---


{% include pack-code.html vendor="qualys" section="2.1" %}

### 2.2 Configure Scan Options

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 7.1 |
| NIST 800-53 | RA-5 |

#### Description
Configure appropriate scan options for comprehensive coverage.

#### Rationale
**Why This Matters:**
- Comprehensive, well-tuned option profiles ensure full port and service coverage so vulnerabilities are not missed and left exposed
- Purpose-built profiles (authenticated, PCI) produce accurate findings that drive correct remediation priorities
- Scheduling scans outside peak windows prevents accidental disruption of production systems while preserving coverage
- Incomplete or misconfigured scans create blind spots that attackers exploit before defenders are aware of them

**Attack Prevented:** Undetected exposed services, coverage gaps, exploitation of unscanned assets

#### ClickOps Implementation

**Step 1: Configure Scan Profiles**
1. Navigate to: **Scans** → **Option Profiles**
2. Create profiles for different use cases:
   - Full vulnerability scan
   - Authenticated scan
   - PCI compliance scan

**Step 2: Configure Scan Settings**
1. Configure appropriate settings:
   - Port ranges
   - Performance settings
   - Authentication type
2. Balance thoroughness with impact

**Changed default — On-Host Script Execution (Platform 10.39.1, July 2026):** the option-profile checkbox **Allow the scanner to execute local scripts on target hosts** ships **disabled by default**. Enabling it requires BOTH the option-profile setting and a Windows NT authentication record, and it applies to vulnerability-management scans only (Policy Audit and PCI scans are unaffected). **Leave it disabled.** Enabling it grants the scanner remote script execution — effectively PowerShell — on every authenticated Windows target in scope, turning a scan credential compromise into fleet-wide code execution. If a specific assessment genuinely requires it, enable it on a dedicated option profile scoped to a named asset group, not on your standard profiles. Source: [VM/VMDR Platform 10.39.1 release notes](https://docs.qualys.com/en/vm/release-notes/qweb/release_10_39_1.htm).

**Step 3: Schedule Scans**
1. Configure scan schedules
2. Avoid production impact times
3. Ensure full coverage

---


{% include pack-code.html vendor="qualys" section="2.2" %}

### 2.3 Configure Agent Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 7.1 |
| NIST 800-53 | RA-5 |

#### Description
Securely configure Qualys Cloud Agents.

#### Rationale
**Why This Matters:**
- Secure agent distribution and integrity verification prevent attackers from deploying tampered or rogue agents into the environment
- Protecting activation keys stops unauthorized hosts from enrolling and impersonating managed assets
- Monitoring agent health surfaces disconnected or disabled agents that would otherwise create silent coverage gaps
- Compromised or spoofed agents could feed false telemetry and hide real vulnerabilities from the platform

**Attack Prevented:** Rogue agent enrollment, activation-key abuse, telemetry tampering, coverage evasion

#### ClickOps Implementation

**Step 1: Secure Agent Deployment**
1. Use secure distribution methods
2. Deploy with endpoint management
3. Verify agent integrity

**Step 2: Configure Agent Settings**
1. Navigate to: **Agents** → **Agent Configuration**
2. Configure:
   - Activation key security
   - Communication intervals
   - Local scanning options

**Step 3: Monitor Agent Status**
1. Monitor agent health
2. Alert on disconnected agents
3. Investigate failed deployments

---

## 3. Policy Compliance

Compliance assessment on the Enterprise TruRisk Platform spans two apps: the long-standing **Policy Compliance** app and **Policy Audit**, which Qualys now ships alongside it. The controls below apply to whichever app your subscription entitles; console paths differ between them, so confirm the path in your own tenant before scripting against it. Policy Audit 1.13 added a **policy changelog** that records control-level additions, modifications, and deletions within a policy — review it alongside the platform Activity Log (see [1.6](#16-monitor-activity-and-change-logs)) so a weakened baseline is caught as a change event rather than as a suddenly improved compliance score. Source: [Policy Audit 1.13 release notes](https://docs.qualys.com/en/vm/release-notes/mergedProjects/qualys_pa/pa/release_1_13.htm).

### 3.1 Configure CIS Benchmark Assessments

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Configure Policy Compliance or Policy Audit to assess systems against CIS Benchmark baselines on a schedule.

#### Rationale
**Why This Matters:**
- CIS Benchmarks encode the hardening settings that attackers most reliably exploit when left at their defaults, so assessing against them turns a hardening intention into a measurable state
- Automated, scheduled benchmark assessment catches drift between change windows, where manual review only ever produces a point-in-time snapshot
- Benchmark results give remediation teams a prioritized, vendor-neutral list of concrete settings rather than an abstract instruction to "harden the fleet"
- Documented exceptions keep deliberate deviations visible and reviewable instead of indistinguishable from unnoticed misconfiguration

**Attack Prevented:** Exploitation of insecure defaults, configuration drift, undocumented hardening exceptions, compliance gaps

#### ClickOps Implementation

**Step 1: Enable Policy Compliance**
1. Navigate to: **Policy Compliance** → **Policies** (or the equivalent **Policy Audit** policy list)
2. Review available CIS benchmarks
3. Select appropriate benchmarks for your environment

**Step 2: Configure Compliance Profiles**
1. Create compliance profile
2. Select CIS benchmark (Level 1 or Level 2)
3. Configure exceptions if needed

**Step 3: Run Compliance Scan**
1. Schedule compliance assessments
2. Review compliance reports
3. Prioritize remediation

---

### 3.2 Configure DISA STIG Assessments

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Configure DISA STIG assessments for government compliance.

#### Rationale
**Why This Matters:**
- Automated STIG assessment continuously verifies systems against mandated DoD hardening baselines instead of relying on manual point-in-time checks
- Detecting configuration drift early closes the misconfigurations that attackers most often exploit for initial access and persistence
- Documented findings and exceptions provide the evidence trail required for government and regulated-environment audits
- Unassessed STIG gaps leave known-weak default settings in place across the estate

**Attack Prevented:** Exploitation of insecure configurations, configuration drift, compliance gaps

#### ClickOps Implementation

**Step 1: Select STIG Templates**
1. Navigate to: **Policy Compliance** → **Templates**
2. Select DISA STIG templates:
   - Operating systems
   - Databases
   - Network devices
   - Applications

**Step 2: Create Compliance Policy**
1. Create policy from STIG template
2. Configure applicable findings
3. Document exceptions

**Step 3: Assess and Remediate**
1. Run STIG assessments
2. Generate compliance reports
3. Track remediation progress

---

### 3.3 Configure Security Configuration Assessment

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Use Qualys SCA for automated configuration assessment.

#### Rationale
**Why This Matters:**
- Automated, continuous configuration assessment catches hardening regressions far faster than periodic manual reviews
- Prioritizing findings by severity directs remediation effort to the misconfigurations that pose the greatest real risk
- Automated alerting ensures newly introduced weak configurations are flagged before they can be exploited
- Misconfigurations are among the most common root causes of breaches, and SCA makes them visible and measurable

**Attack Prevented:** Security misconfiguration, hardening drift, exploitation of insecure defaults

#### ClickOps Implementation

**Step 1: Enable SCA**
1. Navigate to: **Vulnerability Management** → **SCA**
2. Enable Security Configuration Assessment

**Step 2: Configure SCA Profiles**
1. Select benchmark profiles
2. Configure assessment frequency
3. Enable automated alerting

**Step 3: Review Results**
1. Review configuration findings
2. Prioritize by severity
3. Track hardening progress

---

## 4. Asset Management

### 4.1 Configure Asset Discovery

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 1.1 |
| NIST 800-53 | CM-8 |

#### Description
Configure comprehensive asset discovery for visibility.

#### Rationale
**Why This Matters:**
- You cannot protect or scan assets you do not know exist, so comprehensive discovery eliminates blind spots in coverage
- Combining network, cloud, agent, and passive discovery catches shadow IT and rogue devices that bypass standard provisioning
- Automated tagging enables accurate scan targeting so no asset class is silently excluded from assessment
- Alerting on new and unmanaged assets shortens the window in which an unmonitored device can be attacked

**Attack Prevented:** Shadow IT exposure, unmanaged-asset compromise, scanning blind spots

#### ClickOps Implementation

**Step 1: Configure Discovery Methods**
1. Navigate to: **Assets** → **Asset Discovery**
2. Configure:
   - Network scanning
   - Cloud connectors
   - Agent deployment
   - Passive discovery

**Step 2: Configure Asset Tagging**
1. Create asset tags for organization
2. Apply tags automatically
3. Use tags for scan targeting

**Step 3: Monitor for Rogue Assets**
1. Configure alerts for new assets
2. Flag unmanaged devices
3. Integrate with ITSM

---


{% include pack-code.html vendor="qualys" section="4.1" %}

### 4.2 Configure Cloud Connector Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 1.1 |
| NIST 800-53 | CM-8 |

#### Description
Securely configure cloud provider connectors.

#### Rationale
**Why This Matters:**
- Granting connectors only the minimum read permissions limits what an attacker can reach if the integration is compromised
- Scoped IAM roles, app registrations, and service accounts prevent the connector from becoming a path to broader cloud control-plane access
- Cross-account and least-privilege configuration contains the blast radius of any single leaked connector credential
- Over-permissioned cloud connectors are a high-value pivot point into the entire cloud environment

**Attack Prevented:** Cloud credential abuse, excessive-permission pivot, lateral movement into cloud accounts

#### ClickOps Implementation

**Step 1: AWS Connector**
1. Navigate to: **Assets** → **Connectors** → **AWS**
2. Create IAM role with minimum permissions
3. Configure cross-account access

**Step 2: Azure Connector**
1. Create app registration
2. Grant minimum required permissions
3. Configure connector

**Step 3: GCP Connector**
1. Create service account
2. Grant minimum roles
3. Configure connector

---


{% include pack-code.html vendor="qualys" section="4.2" %}

### 4.3 Configure Approval Workflows

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-3 |

#### Description
Configure approval workflows for automated remediation.

#### Rationale
**Why This Matters:**
- Requiring approval before automated remediation prevents unreviewed changes from disrupting production systems
- Maintenance windows and risk thresholds ensure high-impact actions only execute under controlled conditions
- Defined approvers, escalation, and timeout actions create accountability and an auditable change trail
- Unconstrained automated actions could be abused or misfire to cause outages or mask malicious changes

**Attack Prevented:** Unauthorized automated changes, change-control bypass, remediation-driven outages

#### ClickOps Implementation

**Step 1: Configure Workflows**
1. Navigate to: **Administration** → **Workflows**
2. Configure approval requirements:
   - Maintenance windows
   - Risk level thresholds
   - Automated vs. manual actions

**Step 2: Set Approval Roles**
1. Define approvers
2. Configure escalation
3. Set timeout actions

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Qualys Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-sso-authentication) |
| CC6.2 | RBAC | [1.3](#13-implement-role-based-access-control) |
| CC6.6 | IP restrictions | [1.4](#14-configure-ip-restrictions) |
| CC7.1 | Vulnerability scanning | [2.2](#22-configure-scan-options) |
| CC7.2 | Configuration assessment | [3.3](#33-configure-security-configuration-assessment) |

### NIST 800-53 Rev 5 Mapping

| Control | Qualys Control | Guide Section |
|---------|----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-sso-authentication) |
| IA-2(1) | MFA | [1.2](#12-enforce-multi-factor-authentication) |
| RA-5 | Vulnerability scanning | [2.2](#22-configure-scan-options) |
| CM-6 | Configuration assessment | [3.1](#31-configure-cis-benchmark-assessments) |
| CM-8 | Asset discovery | [4.1](#41-configure-asset-discovery) |

---

## Appendix A: References

**Official Qualys Documentation:**
- [Qualys Documentation](https://www.qualys.com/documentation/) — Enterprise TruRisk Platform documentation index
- [VM/VMDR Platform 10.39.1 Release Notes](https://docs.qualys.com/en/vm/release-notes/qweb/release_10_39_1.htm) — On-Host Script Execution default, API External ID, Activity Log detail
- [Policy Audit 1.13 Release Notes](https://docs.qualys.com/en/vm/release-notes/mergedProjects/qualys_pa/pa/release_1_13.htm) — policy changelog
- [Get Started with VM/VMDR](https://docs.qualys.com/en/vm/latest/welcome_to_vm.htm)
- [Scanning Basics](https://docs.qualys.com/en/vm/latest/scans/scanning_basics.htm)
- [VMDR Datasheet](https://www.qualys.com/docs/vmdr-datasheet.pdf)
- [VMDR Complete Advantage Blog](https://blog.qualys.com/product-tech/2025/02/24/from-vulnerability-scanning-to-risk-management-the-complete-vmdr-advantage)
- [Policy Compliance Datasheet](https://cdn2.qualys.com/docs/mktg/policy-compliance-datasheet.pdf)
- [Security Configuration Assessment Guide (PDF)](https://www.qualys.com/docs/qualys-security-configuration-assessment-guide.pdf)

**API & Developer Resources:**
- [Qualys API Documentation](https://www.qualys.com/documentation/)

**Security Incidents:**
- **Accellion FTA Breach (2021):** Qualys confirmed data was accessed via a zero-day vulnerability in the Accellion FTA file transfer appliance used by Qualys. Production environments and customer data on the Qualys Cloud Platform were not affected.
- **Salesloft/Drift Supply Chain Attack (September 2025):** Attackers exfiltrated OAuth tokens from breached Salesloft/Drift infrastructure and accessed some data in Qualys's Salesforce environment (leads and contacts). No impact to Qualys production environments, codebase, or customer platform data. Mandiant was engaged for investigation.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass: Enterprise TruRisk Platform / Policy Audit naming; new 1.5 API External ID and 1.6 activity and change logging; On-Host Script Execution changed-default callout in 2.2; corrected credential-vault list in 2.1; removed unsourced claims and added Attack Prevented in 3.1, 1.2, 2.1; dropped compliance-badge reference. Tier 3/4 research sweep out of scope this pass | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with access controls, scanning, and policy compliance | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
