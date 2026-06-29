---
layout: guide
title: "Qualys Hardening Guide"
vendor: "Qualys"
slug: "qualys"
tier: "2"
category: "Security"
description: "Vulnerability management platform hardening for Qualys VMDR including user access, scanning configuration, and policy compliance"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---

## Overview

Qualys is a leading cloud-based vulnerability management and compliance platform protecting **millions of assets** across enterprises worldwide. As a critical security tool with deep access to infrastructure, Qualys configurations directly impact vulnerability visibility and remediation effectiveness. Proper hardening ensures security data integrity and prevents unauthorized access to sensitive vulnerability information.

### Intended Audience
- Security engineers managing vulnerability programs
- IT administrators configuring Qualys
- GRC professionals using Policy Compliance
- SOC analysts managing vulnerability data

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Qualys platform security including user management, scanning configuration, policy compliance, and Security Configuration Assessment (SCA).

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

#### ClickOps Implementation

**Step 1: Create Dedicated Scan Accounts**
1. Create dedicated service accounts for scanning
2. Grant minimum required permissions:
   - Read access for vulnerability scanning
   - Admin only if compliance required
3. Do not use admin/root accounts

**Step 2: Configure Credential Vaults**
1. Navigate to: **Scans** → **Authentication** → **Vault**
2. Configure credential vault integration:
   - CyberArk
   - HashiCorp Vault
   - Thycotic
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

### 3.1 Configure CIS Benchmark Assessments

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Configure Policy Compliance for CIS Benchmark assessments.

#### Rationale
**Why This Matters:**
- Qualys covers more CIS benchmarks than competitors
- System hardening reduces attack surface
- Improves security posture from 51% to 80% average

#### ClickOps Implementation

**Step 1: Enable Policy Compliance**
1. Navigate to: **Policy Compliance** → **Policies**
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
- [Qualys Documentation](https://www.qualys.com/documentation/)
- [Get Started with VM/VMDR](https://docs.qualys.com/en/vm/latest/welcome_to_vm.htm)
- [Scanning Basics](https://docs.qualys.com/en/vm/latest/scans/scanning_basics.htm)
- [VMDR Datasheet](https://www.qualys.com/docs/vmdr-datasheet.pdf)
- [VMDR Complete Advantage Blog](https://blog.qualys.com/product-tech/2025/02/24/from-vulnerability-scanning-to-risk-management-the-complete-vmdr-advantage)
- [Policy Compliance Datasheet](https://cdn2.qualys.com/docs/mktg/policy-compliance-datasheet.pdf)
- [Security Configuration Assessment Guide (PDF)](https://www.qualys.com/docs/qualys-security-configuration-assessment-guide.pdf)

**API & Developer Resources:**
- [Qualys API Documentation](https://www.qualys.com/documentation/)

**Compliance & Certifications:**
- SOC 2 Type II, ISO 27001, CSA STAR Level 2 -- via [Qualys Certifications](https://success.qualys.com/support/s/standards)

**Security Incidents:**
- **Accellion FTA Breach (2021):** Qualys confirmed data was accessed via a zero-day vulnerability in the Accellion FTA file transfer appliance used by Qualys. Production environments and customer data on the Qualys Cloud Platform were not affected.
- **Salesloft/Drift Supply Chain Attack (September 2025):** Attackers exfiltrated OAuth tokens from breached Salesloft/Drift infrastructure and accessed some data in Qualys's Salesforce environment (leads and contacts). No impact to Qualys production environments, codebase, or customer platform data. Mandiant was engaged for investigation.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with access controls, scanning, and policy compliance | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
