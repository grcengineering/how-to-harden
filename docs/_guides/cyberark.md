---
layout: guide
title: "CyberArk Hardening Guide"
vendor: "CyberArk"
slug: "cyberark"
tier: "1"
category: "Identity"
description: "Privileged access management hardening for vaults, PSM, and credential rotation"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

CyberArk is a Privileged Access Management (PAM) platform that protects credentials for **half of Fortune 500 companies** across 10,000+ organizations. As the central vault for privileged credentials, API tokens, session recordings, and SSH keys, CyberArk compromise enables immediate access to the most sensitive enterprise systems. Secrets management integrations with HashiCorp Vault, AWS Secrets Manager, and Azure Key Vault extend the attack surface beyond the vault itself.

### Intended Audience
- Security engineers managing PAM infrastructure
- IT administrators configuring CyberArk
- GRC professionals assessing privileged access compliance
- Third-party risk managers evaluating secrets management

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers CyberArk-specific security configurations including vault hardening, API security, session management, secrets rotation, and integration security with external secrets managers.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Vault Security](#2-vault-security)
3. [API & Integration Security](#3-api--integration-security)
4. [Session Management](#4-session-management)
5. [Secrets Rotation](#5-secrets-rotation)
6. [Monitoring & Detection](#6-monitoring--detection)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Multi-Factor Authentication for All Access

**Profile Level:** L1 (Baseline)
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1), IA-2(6)

#### Description
Require MFA for all CyberArk console access, including PVWA (Password Vault Web Access), PSM (Privileged Session Manager), and API authentication.

#### Rationale
**Why This Matters:**
- CyberArk stores the most sensitive credentials in the enterprise
- Single-factor compromise = access to all privileged accounts
- MFA is mandatory for compliance (PCI DSS, SOX, HIPAA)

**Attack Prevented:** Credential theft, phishing, password spray

**Attack Scenario:** Attacker phishes CyberArk admin credentials, gains access to entire credential vault, extracts domain admin passwords.

#### ClickOps Implementation

**Step 1: Configure LDAP/RADIUS MFA Integration**
1. Navigate to: **PVWA → Administration → Options → Authentication Methods**
2. Configure RADIUS integration:
   - **Primary server:** Your MFA RADIUS endpoint
   - **Shared secret:** (stored securely)
   - **Timeout:** 60 seconds
3. Enable for user types: All

**Step 2: Enforce MFA for Specific User Types**
1. Navigate to: **PVWA → Administration → Platform Configuration**
2. For each platform:
   - Enable: **Require MFA for connection**
   - Configure MFA prompt timing

**Step 3: Configure for Privilege Cloud**
1. Navigate to: **Identity Administration → Authentication**
2. Configure:
   - **MFA enforcement:** Required
   - **Factors:** TOTP, Push, FIDO2
   - **Remember device:** Disabled (L2/L3)

#### Validation & Testing
1. [ ] Attempt PVWA login with password only - should fail
2. [ ] Complete login with password + MFA - should succeed
3. [ ] Verify MFA logged in audit trail
4. [ ] Test PSM connection with MFA requirement

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2(1), IA-2(6) | MFA for privileged accounts |
| **PCI DSS** | 8.3.1 | MFA for administrative access |
| **SOX** | ITGC | Access control for financial systems |

---

### 1.2 Implement Vault-Level Access Controls

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure granular safe-level permissions ensuring users only access credentials required for their role. Implement approval workflows for sensitive safes.

#### ClickOps Implementation

**Step 1: Design Safe Structure**

Organize safes into logical categories (Infrastructure, Applications, Emergency) with appropriate approval requirements for each tier.

**Step 2: Configure Safe Permissions**
1. Navigate to: **PVWA → Policies → Access Control (Safes)**
2. For each safe, configure:
   - **Members:** Specific groups only
   - **Permissions:** Minimum required (Use, Retrieve, List)
   - **Require approval:** For sensitive safes

**Step 3: Create Approval Workflow**
1. Navigate to: **PVWA → Policies → Master Policy**
2. Configure:
   - **Require dual control:** Enabled for DomainAdmins safe
   - **Approvers:** Security team group
   - **Approval timeout:** 4 hours

#### Code Implementation

{% include pack-code.html vendor="cyberark" section="1.2" %}

---

### 1.3 Configure Break-Glass Procedures

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CP-2

#### Description
Implement emergency access procedures for critical scenarios when normal authentication is unavailable.

#### ClickOps Implementation

**Step 1: Create Break-Glass Safe**
1. Create safe: `Emergency-BreakGlass`
2. Store emergency credentials:
   - Master user recovery credentials
   - Emergency admin accounts
   - Critical infrastructure access

**Step 2: Configure Dual Control**
1. Require approval from 2 different approvers
2. Set expiration: 1 hour
3. Enable enhanced logging

**Step 3: Physical Security**
1. Store break-glass credentials in physical safe
2. Distribute parts to different individuals
3. Document recovery procedure

---

## 2. Vault Security

### 2.1 Harden Vault Server Configuration

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-8, SC-28

#### Description
Configure secure vault server settings including encryption, communication security, and component hardening.

#### ClickOps Implementation

**Step 1: Verify Encryption Settings**
1. Check DBParm.ini and verify AES256 encryption is configured with appropriate key age settings.

**Step 2: Configure Secure Communication**
1. Enable TLS 1.2/1.3 only
2. Disable legacy protocols
3. Configure certificate validation

**Step 3: Harden Operating System**
- Remove unnecessary services
- Configure Windows Firewall
- Enable audit logging

#### Code Implementation

{% include pack-code.html vendor="cyberark" section="2.1" %}

---

### 2.2 Implement Vault High Availability

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CP-9, CP-10

#### Description
Configure disaster recovery and high availability for vault infrastructure.

#### Implementation

**DR Configuration:**
1. Configure vault replication to DR site
2. Test failover quarterly
3. Document recovery procedures
4. Verify backup integrity

Use `PAReplicate.exe` to verify replication status and test DR failover in non-production environments.

---

## 3. API & Integration Security

### 3.1 Secure API Authentication

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5, SC-8

#### Description
Secure CyberArk API access using certificate-based authentication, API key rotation, and IP restrictions.

#### Rationale
**Why This Matters:**
- API tokens provide programmatic access to credential vault
- Stolen API tokens enable mass credential extraction
- Long-lived tokens create persistent risk

**Attack Scenario:** Stolen API token accessing credential vault enables extraction of all privileged passwords and SSH keys.

#### ClickOps Implementation

**Step 1: Enable Certificate-Based API Authentication**
1. Navigate to: **PVWA → Administration → Options → API Settings**
2. Configure:
   - **Certificate authentication:** Enabled
   - **Client certificate required:** Yes
   - **CA validation:** Enabled

**Step 2: Create API-Specific Application Identity**
1. Navigate to: **PVWA → Applications → Application Identity**
2. Create application with:
   - **Allowed machines:** Specific IPs/hostnames
   - **Certificate:** Required
   - **Hash:** Enable for script authentication

**Step 3: Configure API Rate Limiting**

Configure rate limiting in PVConfiguration.xml to limit concurrent requests, set request timeouts, and enable rate limiting for API endpoints.

#### Code Implementation

{% include pack-code.html vendor="cyberark" section="3.1" %}

---

### 3.2 Restrict Integration Permissions

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-6

#### Description
Limit integration accounts to minimum required permissions. Service accounts should only access specific safes needed for their function.

#### ClickOps Implementation

**Step 1: Create Purpose-Specific Integration Users**

Create dedicated service accounts for each integration (Jenkins, Ansible, Terraform, SIEM) with access restricted to only the safes required for their function.

**Step 2: Configure Minimal Permissions**
For each integration:
1. Grant access to specific safes only
2. Limit to `UseAccounts` permission (no admin rights)
3. Enable audit logging for all actions

---

### 3.3 Integrate with External Secrets Managers

**Profile Level:** L2 (Hardened)
**NIST 800-53:** IA-5(7)

#### Description
Securely configure integrations with HashiCorp Vault, AWS Secrets Manager, and Azure Key Vault.

{% include pack-code.html vendor="cyberark" section="3.3" %}

---

## 4. Session Management

### 4.1 Configure PSM Session Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-12, AU-14

#### Description
Secure Privileged Session Manager (PSM) sessions with recording, monitoring, and termination controls.

#### ClickOps Implementation

**Step 1: Enable Session Recording**
1. Navigate to: **PVWA → Administration → Platform Configuration**
2. For each platform:
   - **Enable recording:** Yes
   - **Recording format:** Universal (searchable)
   - **Storage:** Secure location with encryption

**Step 2: Configure Session Monitoring**
1. Navigate to: **PSM → Live Sessions**
2. Enable:
   - **Real-time monitoring:** Security team access
   - **Session suspension:** On suspicious activity
   - **Session termination:** Immediate capability

**Step 3: Set Session Timeouts**

Configure session duration limits (8 hours maximum), idle timeouts (30 minutes), and warning intervals (5 minutes before timeout) in the platform configuration.

#### Code Implementation

{% include pack-code.html vendor="cyberark" section="4.1" %}

---

### 4.2 Implement Just-In-Time Access

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-2(6)

#### Description
Configure time-limited access requests with automatic credential rotation after use.

#### ClickOps Implementation

**Step 1: Configure Time-Limited Access**
1. Navigate to: **PVWA → Policies → Master Policy**
2. Enable:
   - **Exclusive access:** Enabled
   - **One-time password:** Enabled
   - **Auto-rotate after retrieval:** Enabled

**Step 2: Configure Access Request Workflow**
1. Create request workflow:
   - User requests access
   - Approver reviews justification
   - Time-limited access granted
   - Credentials rotate after session

---

## 5. Secrets Rotation

### 5.1 Configure Automatic Password Rotation

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5(1)

#### Description
Enable CPM (Central Policy Manager) to automatically rotate privileged credentials based on policy.

#### ClickOps Implementation

**Step 1: Configure Rotation Policy**
1. Navigate to: **PVWA → Policies → Platform Configuration**
2. For each platform, configure:
   - **Password change interval:** 30 days (L1) / 7 days (L2)
   - **Verification interval:** Daily
   - **Reconcile interval:** Weekly

**Step 2: Configure Password Complexity**

Set minimum length to 20 characters, require uppercase, lowercase, numbers, and special characters. Exclude characters that may cause parsing issues in scripts.

#### Code Implementation

{% include pack-code.html vendor="cyberark" section="5.1" %}

---

### 5.2 Monitor Rotation Failures

**Profile Level:** L1 (Baseline)

#### Description
Alert on password rotation failures to prevent credential staleness.

Query for rotation failures via SIEM or direct database reporting to identify accounts where CPM status indicates failure, ordered by most recent failure date.

{% include pack-code.html vendor="cyberark" section="5.2" %}

---

## 6. Monitoring & Detection

### 6.1 Enable Comprehensive Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### Description
Configure CyberArk audit logging and forward to SIEM for security monitoring.

#### Detection Use Cases

**Anomaly 1: Mass Credential Retrieval** -- Detect users retrieving more than 20 passwords within a one-hour window, indicating potential credential harvesting.

**Anomaly 2: After-Hours Access** -- Flag logon and password retrieval events occurring outside business hours (before 6 AM or after 8 PM) and on weekends.

**Anomaly 3: Failed Authentication Spike** -- Identify brute force attempts by detecting more than 5 failed logon attempts from a single user or IP within a 15-minute window.

{% include pack-code.html vendor="cyberark" section="6.1" %}

---

## 7. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | CyberArk Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | MFA enforcement | 1.1 |
| CC6.2 | Safe permissions | 1.2 |
| CC7.2 | Audit logging | 6.1 |

### NIST 800-53 Mapping

| Control | CyberArk Control | Guide Section |
|---------|------------------|---------------|
| IA-2(6) | MFA for privileged | 1.1 |
| AC-6 | Least privilege safes | 1.2 |
| IA-5(1) | Password rotation | 5.1 |
| AU-14 | Session recording | 4.1 |

---

## Appendix A: References

**Official CyberArk Documentation:**
- [Trust Center](https://www.cyberark.com/trust/)
- [Trust Center (SafeBase Portal)](https://trust.cyberark.com/)
- [Product Security and Vulnerability Disclosure](https://www.cyberark.com/product-security/)
- [CyberArk Labs Security Advisories](https://labs.cyberark.com/cyberark-labs-security-advisories/)
- [Documentation Portal (All Products)](https://docs.cyberark.com)
- [Privilege Cloud Security Fundamentals](https://docs.cyberark.com/privilege-cloud-standard/latest/en/content/security/security%20fundamentals-introduction.htm)
- [Privilege Cloud Connector Hardening](https://docs.cyberark.com/privilege-cloud-standard/latest/en/content/privilege%20cloud/privcloud-hardening-overview.htm)
- [Technical Best Practices](https://docs.cyberark.com/privilege-cloud-standard/latest/en/content/getstarted/best-pactices.htm)

**API Documentation:**
- [CyberArk API Documentation Portal](https://api-docs.cyberark.com/)
- [REST API Overview](https://www.cyberark.com/rest-api/)

**Compliance Frameworks:**
- [CyberArk Compliance (SOC 2, ISO 27001, FedRAMP)](https://www.cyberark.com/trust/compliance/)
- [Corporate Security White Paper](https://www.cyberark.com/resources/white-papers/cyberark-corporate-security-white-paper-standards-and-practices)
- [Blueprint for Identity Security Success](https://www.cyberark.com/resources/white-papers/cyberark-blueprint-for-identity-security-success-whitepaper)

**Security Vulnerabilities:**
- [CVE Details — CyberArk](https://www.cvedetails.com/vulnerability-list/vendor_id-18857/Cyberark.html)
- [Addressing Recent Vulnerabilities (Blog)](https://www.cyberark.com/resources/product-insights-blog/addressing-recent-vulnerabilities-and-our-commitment-to-security)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial CyberArk hardening guide | Claude Code (Opus 4.5) |
