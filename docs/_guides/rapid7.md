---
layout: guide
title: "Rapid7 Hardening Guide"
vendor: "Rapid7"
slug: "rapid7"
tier: "2"
category: "Security & Compliance"
description: "Vulnerability management platform hardening for Rapid7 InsightVM and Command Platform including SSO, console security, and user management"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Rapid7 is a leading cybersecurity platform providing vulnerability management, SIEM, and threat detection for **thousands of organizations** worldwide. As a critical security tool with privileged access to infrastructure vulnerability data, Rapid7 configurations directly impact security visibility and incident response capabilities.

### Intended Audience
- Security engineers managing vulnerability programs
- IT administrators configuring Rapid7 products
- GRC professionals using compliance features
- SOC analysts managing InsightVM and InsightIDR

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Rapid7 Insight Platform and InsightVM Security Console security including SAML SSO, user management, console hardening, and Command Platform administration.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Console Security](#2-console-security)
3. [User & Access Management](#3-user--access-management)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure Command Platform SSO

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO for centralized authentication to the Rapid7 Command Platform.

#### Rationale
**Why This Matters:**
- Centralizes identity management across Rapid7 products
- Enforces organizational MFA policies
- Simplifies user provisioning and deprovisioning
- Required for enterprise security compliance

#### Prerequisites
- [ ] Rapid7 Insight Platform subscription
- [ ] Command Platform Administrator role
- [ ] SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Command Platform** → **Administration** → **Platform Settings**
2. Click **SSO Settings** tab
3. Locate Authentication Settings section

**Step 2: Upload SAML Certificate**
1. Obtain X.509 certificate from your IdP
2. Certificate must be base64-encoded with DER encoding
3. Upload certificate to Command Platform

**Step 3: Configure Identity Provider**
1. Create SAML application in IdP (Okta, Azure, etc.)
2. Configure required attribute mappings:
   - **FirstName:** User's first name
   - **LastName:** User's last name
   - **Email:** User's email address
3. Map these labels exactly as shown

**Step 4: Complete Configuration**
1. Enter IdP SSO URL
2. Enter Entity ID
3. Test SSO authentication
4. Enable SSO enforcement

**Time to Complete:** ~1 hour

---

### 1.2 Configure InsightVM Console SSO

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO directly on InsightVM Security Console for local authentication.

#### ClickOps Implementation

**Step 1: Access SAML Configuration**
1. Navigate to: **Administration** → **Authentication: 2FA and SSO**
2. Click **Configure SAML Source**

**Step 2: Upload IdP Metadata**
1. Download IdP metadata XML file
2. Click **Choose File** and select metadata
3. Click **Save**

**Step 3: Configure Base Entity URL**
1. If ACS URL includes hostname/FQDN:
   - Set Base Entity URL: `https://<console-hostname>:3780`
2. Restart console services after applying

**Step 4: Enable SAML Authorization**
1. Navigate to: **Administration** → **User Management**
2. For each user, set **SAML Authorization Method** → **SAML**
3. Ensure email addresses match exactly (case-sensitive)

**Important:** Enabling Command Platform Login disables local authentication after 60-day grace period.

---

### 1.3 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all Rapid7 platform users.

#### ClickOps Implementation

**Step 1: Configure via IdP (Recommended)**
1. Enable MFA in your identity provider
2. All SSO users subject to IdP MFA policies
3. Use phishing-resistant methods for admins

**Step 2: Enable Console 2FA**
1. Navigate to: **Administration** → **Authentication: 2FA and SSO**
2. Configure two-factor authentication settings
3. Require 2FA for all console users

**Step 3: Verify Enforcement**
1. Test login with MFA
2. Verify no bypass is possible
3. Document MFA methods

---

## 2. Console Security

### 2.1 Secure Console Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Secure network access to the InsightVM Security Console.

#### ClickOps Implementation

**Step 1: Configure HTTPS**
1. Console uses HTTPS by default on port 3780
2. Install valid TLS certificate
3. Replace self-signed certificate

**Step 2: Restrict Network Access**
1. Limit console access to management networks
2. Use firewall rules to restrict:
   - Port 3780 (Web interface)
   - Port 40814 (Scan engine communication)
3. Block public internet access

**Step 3: Configure Session Settings**
1. Navigate to: **Administration** → **Security Console Configuration**
2. Set session timeout (15-30 minutes recommended)
3. Enable session lockout after failed attempts

---

### 2.2 Harden Console Installation

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Apply hardening configurations to the Security Console server.

#### ClickOps Implementation

**Step 1: Update Console Regularly**
1. Navigate to: **Administration** → **Updates**
2. Check for available updates
3. Apply updates during maintenance windows

**Step 2: Configure TLS Settings**
1. Disable weak ciphers
2. Enforce TLS 1.2 or higher
3. Configure strong cipher suites

**Step 3: Secure Operating System**
1. Apply OS security patches
2. Disable unnecessary services
3. Configure host-based firewall

---

### 2.3 Configure Scan Engine Security

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 7.1 |
| NIST 800-53 | RA-5 |

#### Description
Secure scan engine configurations and communications.

#### ClickOps Implementation

**Step 1: Secure Engine Communication**
1. Navigate to: **Administration** → **Scan Engines**
2. Review all connected engines
3. Ensure encrypted communication

**Step 2: Manage Pairing Keys**
1. Generate unique pairing keys for each engine
2. Rotate keys if compromised
3. Remove inactive engines

**Step 3: Configure Engine Placement**
1. Deploy engines in appropriate network segments
2. Ensure engines can reach scan targets
3. Use distributed engines for segmented networks

---

## 3. User & Access Management

### 3.1 Implement Role-Based Access Control

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure granular roles for least privilege access.

#### ClickOps Implementation

**Step 1: Review Built-in Roles**
1. Navigate to: **Administration** → **User Management**
2. Review available roles:
   - **Global Administrator:** Full platform access
   - **Asset Owner:** View assigned assets
   - **User:** Standard scanning capabilities
   - **Security Manager:** Security configuration

**Step 2: Create Custom Roles**
1. Navigate to: **Administration** → **Roles**
2. Click **Create Role**
3. Configure permissions:
   - Site access
   - Scan management
   - Report access
   - Configuration rights

**Step 3: Assign Minimum Required Roles**
1. Limit Global Administrator to 2-3 users
2. Use custom roles for specific functions
3. Document role assignments

---

### 3.2 Manage Administrator Accounts

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Protect and limit administrator account access.

#### Rationale
**Why This Matters:**
- Admin accounts can modify all configurations
- Compromised admin access exposes vulnerability data
- Minimize admin accounts to reduce risk

#### ClickOps Implementation

**Step 1: Inventory Admin Accounts**
1. Navigate to: **Administration** → **User Management**
2. Filter by administrator roles
3. Document all admin accounts

**Step 2: Apply Least Privilege**
1. Remove unnecessary admin access
2. Create separate accounts for admin vs. daily tasks
3. Review quarterly

**Step 3: Protect Admin Credentials**
1. Use strong, unique passwords (20+ characters)
2. Store in password vault
3. Enable MFA for all admins

---

### 3.3 Configure Audit Logging

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs for security events.

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Administration** → **Audit Log**
2. Review logged events:
   - User logins
   - Configuration changes
   - Scan activities
   - Report generation

**Step 2: Configure Log Retention**
1. Set retention period (minimum 90 days)
2. Export logs for long-term storage
3. Integrate with SIEM

**Step 3: Monitor Key Events**
1. Admin login events
2. User provisioning/deprovisioning
3. Role modifications
4. Console configuration changes

---

## 4. Monitoring & Compliance

### 4.1 Configure Vulnerability Scanning Security

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 7.1 |
| NIST 800-53 | RA-5 |

#### Description
Secure vulnerability scanning configurations.

#### ClickOps Implementation

**Step 1: Secure Scan Credentials**
1. Navigate to: **Administration** → **Shared Credentials**
2. Use least privilege for scan accounts
3. Never use domain admin credentials

**Step 2: Configure Credential Vault Integration**
1. Integrate with CyberArk or HashiCorp Vault
2. Retrieve credentials dynamically
3. Rotate credentials regularly

**Step 3: Protect Credential Storage**
1. Rapid7 encrypts stored credentials
2. Limit who can view/edit credentials
3. Audit credential access

---

### 4.2 Configure Compliance Assessment

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Enable policy compliance scanning for hardening verification.

#### ClickOps Implementation

**Step 1: Configure Policy Scans**
1. Navigate to: **Policies** → **Create Policy**
2. Select compliance framework:
   - CIS Benchmarks
   - DISA STIGs
   - Custom policies

**Step 2: Schedule Assessments**
1. Configure scan schedules
2. Target appropriate assets
3. Set up notifications

**Step 3: Track Remediation**
1. Review compliance results
2. Assign remediation tasks
3. Monitor improvement trends

---

### 4.3 Configure InsightIDR Integration

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | SI-4 |

#### Description
Integrate InsightVM with InsightIDR for security monitoring.

#### ClickOps Implementation

**Step 1: Enable Platform Integration**
1. Both products use Command Platform
2. Data automatically shared
3. Verify integration status

**Step 2: Configure Alerts**
1. Set up alerts for critical vulnerabilities
2. Configure detection rules
3. Enable automated responses

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Rapid7 Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-command-platform-sso) |
| CC6.2 | RBAC | [3.1](#31-implement-role-based-access-control) |
| CC6.6 | Console security | [2.1](#21-secure-console-access) |
| CC7.1 | Vulnerability scanning | [4.1](#41-configure-vulnerability-scanning-security) |
| CC7.2 | Audit logging | [3.3](#33-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Rapid7 Control | Guide Section |
|---------|----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-command-platform-sso) |
| IA-2(1) | MFA | [1.3](#13-enforce-multi-factor-authentication) |
| AC-6 | Least privilege | [3.1](#31-implement-role-based-access-control) |
| RA-5 | Vulnerability scanning | [4.1](#41-configure-vulnerability-scanning-security) |
| CM-6 | Compliance assessment | [4.2](#42-configure-compliance-assessment) |

---

## Appendix A: References

**Official Rapid7 Documentation:**
- [Configure SSO access to InsightVM Security Console](https://docs.rapid7.com/insightvm/configuring-sso/)
- [Configure SSO for Command Platform](https://docs.rapid7.com/insight/single-sign-on/)
- [Configure Azure as SAML source](https://docs.rapid7.com/insightvm/azure-saml-config/)
- [Troubleshooting SAML SSO](https://docs.rapid7.com/insightvm/troubleshooting-sso/)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, console security, and user management | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
