---
layout: guide
title: "Tenable Hardening Guide"
vendor: "Tenable"
slug: "tenable"
tier: "2"
category: "Security"
description: "Vulnerability management platform hardening for Tenable.io and Security Center including user access, scanning security, and agent configuration"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Tenable is a leading vulnerability management platform protecting **millions of assets** across enterprises worldwide. As a critical security tool with privileged access to infrastructure, Tenable configurations directly impact vulnerability visibility and security posture. Proper hardening ensures vulnerability data integrity and prevents unauthorized access to sensitive security information.

### Intended Audience
- Security engineers managing vulnerability programs
- IT administrators configuring Tenable
- GRC professionals using compliance features
- SOC analysts managing vulnerability data

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Tenable.io and Tenable Security Center security including administrator account protection, SAML SSO, credential management, and hardening assessment configuration.

---

## Table of Contents

1. [Administrator Security](#1-administrator-security)
2. [Authentication Configuration](#2-authentication-configuration)
3. [Scanning & Credential Security](#3-scanning--credential-security)
4. [Hardening Assessments](#4-hardening-assessments)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Administrator Security

### 1.1 Protect Administrator Accounts

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Administrator accounts have the highest level of access and pose significant security risk if compromised. Proper protection is essential.

#### Rationale
**Why This Matters:**
- Admins can create accounts, modify configs, delete data
- Compromised admin credentials can expose entire security program
- Destructive capabilities require additional protection

#### ClickOps Implementation

**Step 1: Protect Non-SSO Admin Accounts**
1. Navigate to: **Settings** → **Accounts** → **Users**
2. For non-SSO admin accounts:
   - Use strong passwords (20+ characters)
   - Store passwords in password vault
   - Enable MFA for each admin

**Step 2: Limit Admin Access**
1. Minimize number of administrators (2-3 for redundancy)
2. Use principle of least privilege
3. Create separate accounts for admin vs. daily use

**Step 3: Document Admin Accounts**
1. Maintain list of all admin accounts
2. Document business justification
3. Review quarterly

**Time to Complete:** ~30 minutes

---

### 1.2 Implement Role-Based Access Control

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Configure granular roles to implement least privilege access.

#### ClickOps Implementation

**Step 1: Review Built-in Roles**
1. Navigate to: **Settings** → **Accounts** → **Roles**
2. Review available roles:
   - **Administrator:** Full access
   - **Standard User:** Scanning and viewing
   - **Scan Operator:** Scanning only
   - **Read Only:** View only

**Step 2: Create Custom Roles**
1. Click **Create Role**
2. Configure granular permissions:
   - Asset access
   - Scan management
   - Report access
   - User management
3. Apply minimum necessary permissions

**Step 3: Assign Roles Appropriately**
1. Limit Administrator to essential personnel
2. Use Standard User for vulnerability teams
3. Use Read Only for stakeholders

---

### 1.3 Monitor Administrator Activity

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Monitor and audit administrator activities.

#### ClickOps Implementation

**Step 1: Access Activity Log**
1. Navigate to: **Settings** → **Activity Log**
2. Review logged events for admin users
3. Export logs for SIEM integration

**Step 2: Configure Alerts**
1. Set up alerts for:
   - Admin login events
   - Configuration changes
   - User creation/deletion
   - Role modifications

**Step 3: Regular Reviews**
1. Weekly review of admin activity
2. Investigate anomalies
3. Document findings

---

## 2. Authentication Configuration

### 2.1 Configure SAML Single Sign-On

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO for centralized identity management.

#### Rationale
**Why This Matters:**
- SAML provides single sign-on capability
- Improved security through IdP controls
- Centralized identity management
- Simplifies compliance auditing

#### ClickOps Implementation

**Step 1: Configure SAML in Tenable**
1. Navigate to: **Settings** → **SAML**
2. Enable SAML authentication
3. Configure:
   - IdP SSO URL
   - IdP Certificate
   - Entity ID

**Step 2: Configure Identity Provider**
1. Create SAML application in IdP
2. Configure attribute mappings:
   - NameID (email)
   - Groups (for role mapping)
3. Download IdP metadata

**Step 3: Enable for Users**
1. Enable SAML for each user
2. Disable password login option
3. Force SSO authentication

**Step 4: Test and Enforce**
1. Test SSO authentication
2. Verify role mapping
3. Enable enforcement

**Time to Complete:** ~1 hour

---

### 2.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all users, enforced through SSO or native settings.

#### ClickOps Implementation

**Step 1: Enable Native MFA (Non-SSO)**
1. Navigate to: **Settings** → **Accounts** → **Users**
2. Enable MFA requirement per user
3. Configure supported methods

**Step 2: Enforce via IdP (SSO)**
1. Configure MFA in IdP
2. Ensure all users subject to MFA
3. Use phishing-resistant methods for admins

---

### 2.3 Configure Session Security

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure session timeout and security settings.

#### ClickOps Implementation

**Step 1: Configure Session Timeout**
1. Navigate to: **Settings** → **Security**
2. Configure session settings:
   - Idle timeout: 15-30 minutes
   - Maximum session: 8 hours
3. Apply to all users

---

## 3. Scanning & Credential Security

### 3.1 Secure Scan Credentials

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Securely manage credentials used for authenticated scanning.

#### Rationale
**Why This Matters:**
- Your organization is responsible for securing scan credentials
- Tenable encrypts credentials when stored
- Best practices must align with risk appetite

#### ClickOps Implementation

**Step 1: Create Dedicated Scan Accounts**
1. Create service accounts for scanning
2. Grant minimum required permissions:
   - Read access for vulnerability scanning
   - Local admin only if required for patches
3. Never use domain admin accounts

**Step 2: Configure Credential Vaults**
1. Navigate to: **Scans** → **Credentials**
2. Configure vault integration:
   - CyberArk
   - HashiCorp Vault
   - Thycotic
3. Retrieve credentials dynamically

**Step 3: Credential Rotation**
1. Establish rotation schedule (90 days)
2. Automate rotation if possible
3. Verify scanning after rotation

---

### 3.2 Secure Agent Linking Keys

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 7.1 |
| NIST 800-53 | SC-12 |

#### Description
Securely manage Nessus Agent linking keys.

#### Rationale
**Why This Matters:**
- Linking keys associate agents to your instance
- Once linked, key regeneration doesn't affect existing agents
- Protect keys during initial deployment

#### ClickOps Implementation

**Step 1: Manage Linking Keys**
1. Navigate to: **Settings** → **Sensors** → **Linked Agents**
2. View linking key
3. Regenerate if compromised

**Step 2: Secure Deployment**
1. Use secure methods to distribute keys
2. Deploy via endpoint management
3. Remove keys from deployment scripts after use

**Step 3: Configure Agent Security**
1. Enable FIPS mode if required
2. Configure SSL ciphers
3. Enable local encryption

---

### 3.3 Configure Scan Security Settings

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 7.1 |
| NIST 800-53 | RA-5 |

#### Description
Configure appropriate scan settings for security and performance.

#### ClickOps Implementation

**Step 1: Configure Scan Policies**
1. Navigate to: **Scans** → **Policies**
2. Create policies for different use cases:
   - Full vulnerability assessment
   - Authenticated scanning
   - Compliance assessment

**Step 2: Configure Network Settings**
1. Configure appropriate scan intensity
2. Avoid production impact
3. Use maintenance windows

**Step 3: Enable Encryption**
1. Ensure all scanner communications encrypted
2. Use TLS for API communications
3. Configure secure protocols

---

## 4. Hardening Assessments

### 4.1 Configure CIS Benchmark Audits

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Configure compliance auditing using CIS Benchmarks.

#### Rationale
**Why This Matters:**
- Hardening standards are key to cyber security
- CIS benchmarks are well-documented standards
- Tenable supports CIS audit files

#### ClickOps Implementation

**Step 1: Enable Compliance Scanning**
1. Navigate to: **Scans** → **Policies** → **Compliance**
2. Select CIS Benchmark templates
3. Configure for your environment

**Step 2: Configure Audit Files**
1. Select appropriate CIS benchmark:
   - Level 1 (baseline)
   - Level 2 (hardened)
2. Customize for your environment
3. Document exceptions

**Step 3: Schedule Assessments**
1. Schedule compliance scans
2. Configure reporting
3. Track remediation

---

### 4.2 Configure DISA STIG Audits

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Configure DISA STIG assessments for government compliance.

#### ClickOps Implementation

**Step 1: Select STIG Audit Files**
1. Navigate to: **Scans** → **Policies** → **Compliance**
2. Select DISA STIG templates
3. Configure for applicable systems

**Step 2: Customize Settings**
1. Configure applicable findings
2. Document exceptions
3. Set severity levels

---

### 4.3 Monitor Hardening Posture

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Use dashboards to monitor hardening compliance posture.

#### ClickOps Implementation (Security Center)

**Step 1: Configure Dashboards**
1. Navigate to: **Dashboards**
2. Add hardening dashboard components:
   - Compliance score trends
   - Top failing checks
   - Remediation progress

**Step 2: Configure Alerts**
1. Set up alerts for:
   - Compliance score drops
   - Critical findings
   - New non-compliant assets

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Tenable Control | Guide Section |
|-----------|-----------------|---------------|
| CC6.1 | SSO/MFA | [2.1](#21-configure-saml-single-sign-on) |
| CC6.2 | RBAC | [1.2](#12-implement-role-based-access-control) |
| CC6.6 | Admin protection | [1.1](#11-protect-administrator-accounts) |
| CC7.1 | Vulnerability scanning | [3.3](#33-configure-scan-security-settings) |
| CC7.2 | Hardening assessment | [4.1](#41-configure-cis-benchmark-audits) |

### NIST 800-53 Rev 5 Mapping

| Control | Tenable Control | Guide Section |
|---------|-----------------|---------------|
| IA-2 | SSO | [2.1](#21-configure-saml-single-sign-on) |
| IA-2(1) | MFA | [2.2](#22-enforce-multi-factor-authentication) |
| AC-6 | Least privilege | [1.2](#12-implement-role-based-access-control) |
| RA-5 | Vulnerability scanning | [3.3](#33-configure-scan-security-settings) |
| CM-6 | Configuration assessment | [4.1](#41-configure-cis-benchmark-audits) |

---

## Appendix A: References

**Official Tenable Documentation:**
- [Trust and Assurance](https://www.tenable.com/trust/assurance)
- [Tenable Documentation](https://docs.tenable.com/)
- [Harden Nessus](https://docs.tenable.com/nessus/Content/HardenNessus.htm)
- [Tenable Vulnerability Management Security Best Practices Guide](https://docs.tenable.com/vulnerability-management/best-practices/security/Content/PDF/Tenable_Vulnerability_Management_Security_Best_Practices_Guide.pdf)
- [SAML Single Sign-On](https://docs.tenable.com/vulnerability-management/best-practices/security/Content/SingleSignOn.htm)
- [Add a SAML Configuration](https://docs.tenable.com/vulnerability-management/Content/Settings/SAML/AddSAMLConfiguration.htm)
- [Tenable Security Center Best Practices Guide](https://docs.tenable.com/security-center/best-practices/product/Content/PDF/Tenable_Security_Center_Best_Practices_Guide.pdf)

**API & Developer Tools:**
- [Tenable Developer Portal](https://developer.tenable.com/)
- [Tenable.io API Documentation](https://developer.tenable.com/)
- [Security Center API Reference](https://docs.tenable.com/security-center/Content/API.htm)

**Compliance Frameworks:**
- ISO 27001, SOC 2 Type II, FedRAMP (authorized products), CSA STAR -- via [Trust and Assurance](https://www.tenable.com/trust/assurance)
- Tenable supports customer compliance with CIS Controls, NIST, PCI DSS, HIPAA, and DISA STIG through its audit capabilities

**Security Incidents:**
- (2025-09) Tenable confirmed a data breach exposing customer contact details and support case information. Unauthorized actors accessed data in Tenable's Salesforce CRM via a compromised integration with the Salesloft Drift marketing application. Core vulnerability assessment products and the Tenable One platform were not affected. Tenable revoked credentials, rotated tokens, and removed the Drift integration.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with admin security, authentication, and hardening assessments | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
