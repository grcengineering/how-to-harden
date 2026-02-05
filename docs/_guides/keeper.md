---
layout: guide
title: "Keeper Security Hardening Guide"
vendor: "Keeper Security"
slug: "keeper"
tier: "2"
category: "Identity & Access Management"
description: "Enterprise password manager hardening for Keeper Security including role enforcement, MFA, and admin console security"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Keeper Security is a leading zero-knowledge password management platform protecting credentials for **millions of users** across enterprises. With its zero-knowledge security architecture, Keeper ensures that only users can decrypt their vault data. Proper enterprise configuration ensures administrative controls are properly applied while maintaining the security model.

### Intended Audience
- Security engineers managing password management
- IT administrators configuring Keeper Enterprise
- GRC professionals assessing credential security
- Third-party risk managers evaluating password managers

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Keeper Enterprise admin console security, role-based enforcement policies, MFA configuration, and SSO integration.

---

## Table of Contents

1. [Admin Console Security](#1-admin-console-security)
2. [Role-Based Enforcement Policies](#2-role-based-enforcement-policies)
3. [Authentication & MFA](#3-authentication--mfa)
4. [SSO Integration](#4-sso-integration)
5. [Monitoring & Compliance](#5-monitoring--compliance)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Admin Console Security

### 1.1 Protect Keeper Administrator Accounts

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Protect Keeper Administrator accounts as they have full control over the enterprise deployment.

#### Rationale
**Why This Matters:**
- Keeper support cannot elevate users to admin or reset admin passwords by design
- If all admins lose access, there's no recovery path
- At least two users should have Keeper Administrator role
- Break-glass accounts are essential

#### ClickOps Implementation

**Step 1: Ensure Redundant Admins**
1. Navigate to: **Admin Console** → **Admin** → **Roles**
2. Verify **Keeper Administrator** role has 2+ members
3. Ensure backup admin has different credentials
4. Document break-glass account procedures

**Step 2: Protect Admin Accounts**
1. Require MFA for all admin accounts
2. Use strong master passwords (20+ characters)
3. Store break-glass credentials securely (physical safe)

**Step 3: Limit Admin Access**
1. Apply principle of least privilege
2. Reduce total number of administrators
3. Use delegated admin roles where possible
4. Remove unnecessary admin privileges

**Time to Complete:** ~30 minutes

---

### 1.2 Configure IP Address Allowlisting for Admins

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17, SC-7 |

#### Description
Restrict admin access to approved IP addresses to prevent unauthorized administrative actions.

#### Rationale
**Why This Matters:**
- At minimum, users with admin privileges should be IP-restricted
- Prevents malicious insider attacks
- Protects against identity provider takeover vectors

#### ClickOps Implementation

**Step 1: Configure IP Allowlist**
1. Navigate to: **Admin Console** → **Admin** → **Roles**
2. Select admin role
3. Navigate to **Enforcement Policies** → **IP Allowlist**
4. Add allowed IP addresses:
   - Corporate network IPs
   - VPN egress IPs
   - Secure admin workstation IPs

**Step 2: Apply to Admin Roles**
1. Apply IP restrictions to:
   - Keeper Administrator role
   - All custom admin roles
2. Test access from allowed IPs
3. Verify blocked from other IPs

---

### 1.3 Enable Administrative Event Alerts

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | SI-4 |

#### Description
Configure alerts for administrative events to detect suspicious activity.

#### ClickOps Implementation

**Step 1: Configure Alerts**
1. Navigate to: **Admin Console** → **Reporting & Alerts**
2. Enable alerts for:
   - Admin login events
   - Role modifications
   - Policy changes
   - User provisioning/deprovisioning

**Step 2: Configure Notification Recipients**
1. Add security team email addresses
2. Configure alert thresholds
3. Integrate with SIEM if available

---

## 2. Role-Based Enforcement Policies

### 2.1 Configure Master Password Requirements

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2 |
| NIST 800-53 | IA-5 |

#### Description
Configure master password requirements through role enforcement policies.

#### ClickOps Implementation

**Step 1: Access Role Enforcement**
1. Navigate to: **Admin Console** → **Admin** → **Roles**
2. Select role to configure
3. Click **Enforcement Policies**

**Step 2: Configure Password Policy**
1. Navigate to **Master Password** section
2. Configure:
   - **Minimum length:** 16+ characters
   - **Complexity requirements:** Mixed case, numbers, symbols
   - **Maximum age:** Optional (modern guidance prefers strong passwords without forced rotation)
   - **Password history:** Prevent reuse

**Step 3: Apply to All Users**
1. Apply policy to all user roles
2. Allow grace period for compliance
3. Monitor compliance dashboard

---

### 2.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all users accessing their Keeper vault.

#### ClickOps Implementation

**Step 1: Configure 2FA Enforcement**
1. Navigate to: **Role** → **Enforcement Policies** → **Two-Factor Authentication**
2. Enable **Require 2FA**
3. Configure:
   - **Prompting frequency:** Every login (most secure)
   - **Allowed methods:** Select approved factors

**Step 2: Configure Allowed 2FA Methods**
1. Enable secure methods:
   - **Keeper DNA (Apple Watch):** Biometric
   - **TOTP Authenticator:** Google Authenticator, etc.
   - **FIDO2 WebAuthn:** Hardware keys (recommended)
   - **Duo Security:** If integrated
   - **RSA SecurID:** If integrated
2. Consider disabling:
   - SMS (vulnerable to SIM swap)

**Step 3: Configure Dual 2FA (L3)**
1. For SSO users, enable 2FA on both:
   - Identity provider side
   - Keeper side (additional layer)

---

### 2.3 Configure Sharing and Export Restrictions

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control how records can be shared and exported from Keeper.

#### ClickOps Implementation

**Step 1: Configure Sharing Policies**
1. Navigate to: **Role** → **Enforcement Policies** → **Sharing**
2. Configure:
   - **Allow sharing:** Within organization only (L2)
   - **Allow external sharing:** Disable or require approval
   - **One-time share:** Configure expiration

**Step 2: Configure Export Restrictions**
1. Navigate to: **Enforcement Policies** → **Export**
2. Configure:
   - **Allow export:** Disable for L2+ environments
   - **Allow printing:** Disable if not needed

---

### 2.4 Restrict Browser Extension Installation

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5 |
| NIST 800-53 | CM-7 |

#### Description
Control which browser extensions users can install to prevent malicious extensions from accessing vault data.

#### Rationale
**Why This Matters:**
- Browser extensions with elevated permissions can access information in websites
- Malicious extensions could capture vault data
- Limit to Keeper and approved extensions only

#### ClickOps Implementation

**Step 1: Configure Extension Policy**
1. Use device management (MDM) to:
   - Allow only Keeper browser extension
   - Block unapproved extensions
   - Remove unknown extensions

**Step 2: Document Approved Extensions**
1. Create whitelist of approved extensions
2. Communicate policy to users
3. Regular audit of installed extensions

---

## 3. Authentication & MFA

### 3.1 Configure Biometric Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2 |

#### Description
Configure biometric authentication options for improved security and usability.

#### ClickOps Implementation

**Step 1: Enable Biometrics**
1. Navigate to: **Role** → **Enforcement Policies** → **Biometrics**
2. Configure allowed biometric methods:
   - Windows Hello
   - Touch ID
   - Face ID
   - Android biometrics

**Step 2: Configure Biometric Policy**
1. Set biometric timeout
2. Require master password periodically
3. Configure fallback authentication

---

### 3.2 Configure Account Recovery

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2 |
| NIST 800-53 | IA-5 |

#### Description
Configure secure account recovery options.

#### ClickOps Implementation

**Step 1: Configure Recovery Methods**
1. Navigate to: **Role** → **Enforcement Policies** → **Account Recovery**
2. Enable appropriate recovery methods:
   - **Admin-assisted recovery:** Recommended for enterprise
   - **Self-service recovery:** With appropriate verification

**Step 2: Configure Recovery Approval**
1. For admin-assisted recovery:
   - Configure approval workflow
   - Require verification steps
   - Log all recovery events

---

## 4. SSO Integration

### 4.1 Configure SAML SSO

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Integrate Keeper with your SAML identity provider for centralized authentication.

#### Prerequisites
- [ ] Keeper SSO Connect Cloud license
- [ ] SAML 2.0 compatible identity provider

#### ClickOps Implementation

**Step 1: Configure SSO Connect Cloud**
1. Navigate to: **Admin Console** → **SSO Configuration**
2. Click **Add SSO Configuration**
3. Configure SAML settings:
   - Entity ID
   - SSO URL
   - Certificate

**Step 2: Configure Identity Provider**
1. Create SAML application in IdP
2. Upload Keeper metadata
3. Configure attribute mappings:
   - Email (required)
   - First name, last name (optional)
4. Configure groups for role mapping

**Step 3: Secure SSO Configuration**
1. **Critical:** Lock down IdP with MFA
2. Follow IdP security best practices
3. Ensure admin accounts are secured

---

### 4.2 Configure Just-in-Time Provisioning

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure automatic user provisioning through SSO.

#### ClickOps Implementation

**Step 1: Enable JIT Provisioning**
1. Navigate to: **SSO Configuration** → **Provisioning**
2. Enable **Just-in-Time provisioning**
3. Configure default role for new users

**Step 2: Configure SCIM (Alternative)**
1. For automated lifecycle management
2. Configure SCIM endpoint
3. Integrate with IdP SCIM

---

## 5. Monitoring & Compliance

### 5.1 Configure Audit Logging

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and review audit logs for security events.

#### ClickOps Implementation

**Step 1: Access Reporting**
1. Navigate to: **Admin Console** → **Reporting & Alerts**
2. Review available reports:
   - Login activity
   - Record access
   - Sharing activity
   - Admin actions

**Step 2: Configure SIEM Integration**
1. Navigate to: **Reporting & Alerts** → **SIEM Integration**
2. Configure export destination:
   - Splunk
   - Azure Sentinel
   - Custom webhook
3. Select events to stream

**Key Events to Monitor:**
- Failed login attempts
- 2FA changes
- Record sharing
- Admin privilege changes
- Policy modifications

---

### 5.2 Monitor Security Audit

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CA-7 |

#### Description
Use Security Audit to monitor organization password health.

#### ClickOps Implementation

**Step 1: Access Security Audit**
1. Navigate to: **Admin Console** → **Security Audit**
2. Review dashboard metrics:
   - Overall security score
   - Password strength distribution
   - Reused passwords
   - 2FA adoption

**Step 2: Identify Issues**
1. Review weak passwords
2. Identify reused credentials
3. Track 2FA compliance

**Step 3: Remediation**
1. Notify users with weak passwords
2. Set improvement targets
3. Track progress over time

---

### 5.3 BreachWatch Integration

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.4 |
| NIST 800-53 | SI-4 |

#### Description
Enable BreachWatch to detect compromised credentials.

#### ClickOps Implementation

**Step 1: Enable BreachWatch**
1. Navigate to: **Admin Console** → **BreachWatch**
2. Enable for organization
3. Configure alert settings

**Step 2: Respond to Alerts**
1. When credentials detected:
   - Notify affected users
   - Require password change
   - Investigate exposure source
2. Document incident response

---

## 6. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Keeper Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | 2FA enforcement | [2.2](#22-enforce-two-factor-authentication) |
| CC6.1 | Master password policy | [2.1](#21-configure-master-password-requirements) |
| CC6.2 | Admin protection | [1.1](#11-protect-keeper-administrator-accounts) |
| CC6.6 | IP allowlisting | [1.2](#12-configure-ip-address-allowlisting-for-admins) |
| CC7.2 | Audit logging | [5.1](#51-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Keeper Control | Guide Section |
|---------|----------------|---------------|
| IA-2(1) | MFA | [2.2](#22-enforce-two-factor-authentication) |
| IA-5 | Password policy | [2.1](#21-configure-master-password-requirements) |
| AC-6 | Least privilege | [1.1](#11-protect-keeper-administrator-accounts) |
| AU-2 | Audit logging | [5.1](#51-configure-audit-logging) |
| SI-4 | BreachWatch | [5.3](#53-breachwatch-integration) |

---

## Appendix A: Plan Compatibility

| Feature | Business | Enterprise | Enterprise Plus |
|---------|----------|------------|-----------------|
| Role Enforcement | Basic | ✅ | ✅ |
| SSO Connect Cloud | ❌ | ✅ | ✅ |
| SCIM Provisioning | ❌ | ✅ | ✅ |
| BreachWatch | Add-on | Add-on | ✅ |
| Advanced Reporting | Basic | ✅ | ✅ |
| SIEM Integration | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official Keeper Documentation:**
- [Security Benchmarks and Recommended Settings](https://docs.keeper.io/en/enterprise-guide/recommended-security-settings)
- [Enforcement Policies](https://docs.keeper.io/en/enterprise-guide/roles/enforcement-policies)
- [SSO Integration Guide](https://docs.keeper.io/en/enterprise-guide/sso-saml-integration)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with admin security, enforcement policies, and SSO | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
