---
layout: guide
title: "LastPass Business Hardening Guide"
vendor: "LastPass"
slug: "lastpass"
tier: "2"
category: "Identity"
description: "Enterprise password manager hardening for LastPass Business including MFA policies, admin controls, and security dashboard"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

LastPass is a widely-deployed enterprise password manager protecting credentials for **millions of users** across businesses worldwide. As a central vault for sensitive credentials, API keys, and secure notes, LastPass security configurations directly impact credential hygiene and breach prevention. Following the 2022 security incidents, proper hardening has become critical for organizations continuing to use the platform.

### Intended Audience
- Security engineers managing password management
- IT administrators configuring LastPass Business
- GRC professionals assessing credential security
- Third-party risk managers evaluating password managers

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers LastPass Business admin policies, MFA configuration, security dashboard utilization, and integration security.

---

## Table of Contents

1. [Authentication & MFA](#1-authentication--mfa)
2. [Admin Policies](#2-admin-policies)
3. [Security Dashboard](#3-security-dashboard)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Authentication & MFA

### 1.1 Require Multi-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all users accessing their LastPass vault.

#### Rationale
**Why This Matters:**
- Password vault contains all stored credentials
- MFA prevents unauthorized access from stolen master passwords
- CISA recommends FIDO2-based MFA as gold standard

#### ClickOps Implementation

**Step 1: Enable MFA Policy**
1. Navigate to: **Admin Dashboard** → **Settings** → **Policies**
2. Search for **Require Multi-Factor Authentication**
3. Enable the policy
4. Configure settings:
   - Apply to all users
   - No exceptions for admin accounts

**Step 2: Configure Allowed MFA Methods**
1. Navigate to: **Policies** → Search for **multifactor**
2. Configure allowed methods:
   - **LastPass Authenticator:** Push notifications (recommended)
   - **FIDO2/WebAuthn:** Hardware keys (most secure)
   - **Google Authenticator:** TOTP app
   - **YubiKey:** Hardware token
3. Disable less secure methods if possible:
   - SMS (vulnerable to SIM swap)
   - Email (vulnerable to account compromise)

**Step 3: Set MFA Prompting Frequency**
1. Configure how often MFA is required:
   - **Every login:** Most secure
   - **Every 30 days:** Balanced
   - **Trust device:** Least secure
2. For L2/L3, require MFA at every login

**Time to Complete:** ~20 minutes

---

### 1.2 Configure SSO Integration

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Integrate LastPass with your identity provider for centralized authentication.

#### ClickOps Implementation

**Step 1: Configure Federated Login**
1. Navigate to: **Admin Dashboard** → **Settings** → **Federated Login**
2. Select identity provider:
   - Active Directory
   - Microsoft Entra ID
   - Google Workspace
   - Okta

**Step 2: Configure Directory Sync**
1. Install LastPass AD Connector (for on-prem)
2. Or configure cloud directory sync
3. Configure sync settings:
   - User provisioning
   - Group synchronization
   - Automatic deprovisioning

**Step 3: Test and Enable**
1. Test with pilot group
2. Verify SSO authentication
3. Roll out to organization

---

### 1.3 Configure Trusted Devices

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.7 |
| NIST 800-53 | AC-17 |

#### Description
Configure trusted device policies to control vault access.

#### ClickOps Implementation

**Step 1: Configure Device Trust Policy**
1. Navigate to: **Policies** → Search for **trusted device**
2. Configure:
   - Maximum trusted devices per user
   - Device trust duration
   - Require re-verification period

**Step 2: Configure Device Restrictions**
1. Consider restricting to:
   - Managed devices only
   - Specific OS versions
   - Corporate networks only (L3)

---

## 2. Admin Policies

### 2.1 Enable Master Password Requirements

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2 |
| NIST 800-53 | IA-5 |

#### Description
Configure master password requirements for all LastPass users.

#### ClickOps Implementation

**Step 1: Configure Password Policy**
1. Navigate to: **Admin Dashboard** → **Settings** → **Policies**
2. Search for **master password**
3. Configure requirements:
   - **Minimum length:** 16+ characters (critical for vault security)
   - **Require complexity:** Mixed case, numbers, symbols
   - **Password iterations:** 600,000+ (PBKDF2)
4. Enable **Prevent master password from containing account email**

**Step 2: Configure Password Change Requirements**
1. Optionally require periodic password changes
2. Modern guidance suggests strong passwords without forced rotation
3. Require change if compromise suspected

---

### 2.2 Configure Sharing Restrictions

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control how credentials can be shared within and outside the organization.

#### ClickOps Implementation

**Step 1: Configure Sharing Policies**
1. Navigate to: **Policies** → Search for **sharing**
2. Configure:
   - **Sharing with personal accounts:** Disable or restrict
   - **Sharing outside organization:** Disable (L2) or require approval
   - **Hide passwords:** Enable to prevent viewing shared passwords

**Step 2: Configure Emergency Access**
1. Navigate to: **Policies** → Search for **emergency access**
2. Configure:
   - Allow/disallow emergency access
   - Set wait period (if allowed)
   - Require admin approval

---

### 2.3 Restrict Personal Account Linking

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Prevent users from linking personal LastPass accounts to business accounts.

#### ClickOps Implementation

**Step 1: Configure Linking Policy**
1. Navigate to: **Policies** → Search for **personal account**
2. Enable **Prohibit linking personal accounts**
3. This prevents data migration between personal and business vaults

**Step 2: Communicate Policy**
1. Notify users of restriction
2. Provide guidance for separate account management
3. Document approved workflows

---

### 2.4 Configure Admin Permission Levels

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Implement least privilege for LastPass administration.

#### ClickOps Implementation

**Step 1: Review Admin Roles**
1. Navigate to: **Admin Dashboard** → **Users**
2. Review available permission levels:
   - **Super Admin:** Full access (limit to 2-3)
   - **Admin:** User and policy management
   - **Helpdesk Admin:** Password resets only
   - **User:** Standard access

**Step 2: Assign Minimum Roles**
1. Reserve Super Admin for essential personnel
2. Use Helpdesk Admin for Tier 1 support
3. Document admin assignments

**Step 3: Regular Access Review**
1. Quarterly review of admin access
2. Remove unnecessary privileges
3. Document changes

---

## 3. Security Dashboard

### 3.1 Monitor Security Score

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | SI-4 |

#### Description
Use the Security Dashboard to monitor organization password health.

#### ClickOps Implementation

**Step 1: Access Security Dashboard**
1. Navigate to: **Admin Dashboard** → **Reporting** → **Security Dashboard**
2. Review overall security score
3. Identify areas for improvement

**Step 2: Review Key Metrics**
1. Monitor:
   - **Master password strength:** Organization average
   - **Reused passwords:** Number of duplicates
   - **Weak passwords:** Below strength threshold
   - **Old passwords:** Not changed in 90+ days
   - **MFA adoption:** Percentage enrolled

**Step 3: Set Improvement Targets**
1. Establish security score targets
2. Create remediation plan for weak areas
3. Track progress over time

---

### 3.2 Enable Dark Web Monitoring

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.4 |
| NIST 800-53 | SI-4 |

#### Description
Enable dark web monitoring to detect compromised credentials.

#### ClickOps Implementation

**Step 1: Enable Monitoring**
1. Navigate to: **Policies** → Search for **dark web monitoring**
2. Enable **Dark Web Monitoring** for business accounts

**Step 2: Configure Alerts**
1. Configure notification recipients
2. Set up incident response procedures
3. Document credential rotation process

**Step 3: Respond to Alerts**
1. When credential detected, immediately rotate
2. Investigate how credential was compromised
3. Update security awareness training

---

### 3.3 Audit Weak and Reused Passwords

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2 |
| NIST 800-53 | IA-5 |

#### Description
Regularly audit and remediate weak and reused passwords.

#### ClickOps Implementation

**Step 1: Generate Report**
1. Navigate to: **Reporting** → **Security Reports**
2. Generate weak password report
3. Generate reused password report

**Step 2: Notify Users**
1. Send notifications to affected users
2. Provide password change guidance
3. Set remediation deadline

**Step 3: Track Remediation**
1. Monitor Security Dashboard for improvements
2. Follow up with non-compliant users
3. Consider policy enforcement

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logging

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and review audit logs for security events.

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Admin Dashboard** → **Reporting** → **Activity Log**
2. Review logged events:
   - Login attempts
   - Password changes
   - Sharing activity
   - Admin actions

**Step 2: Export Logs**
1. Export logs for retention
2. Configure SIEM integration if available
3. Set up automated exports

**Key Events to Monitor:**
- Failed login attempts (brute force)
- Master password changes
- Emergency access requests
- Sharing to external users
- Admin privilege changes

---

### 4.2 Configure Login Alerts

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | SI-4 |

#### Description
Enable alerts for suspicious login activity.

#### ClickOps Implementation

**Step 1: Configure Alert Policies**
1. Navigate to: **Policies** → Search for **alerts**
2. Enable relevant alerts:
   - Login from new device
   - Login from new location
   - Failed login attempts
   - Master password change

**Step 2: Configure Notification**
1. Set notification recipients
2. Configure escalation for critical alerts
3. Test alert delivery

---

### 4.3 Implement Geofencing

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Restrict LastPass access based on geographic location.

#### ClickOps Implementation

**Step 1: Configure Geofencing**
1. Navigate to: **Policies** → Search for **geofencing**
2. Configure allowed countries/regions
3. Configure blocked countries

**Step 2: Configure Response**
1. Set action for violations:
   - Block access
   - Require additional MFA
   - Alert administrators

**Security Note:** Location spoofing can bypass geofencing. Use in combination with other controls, not as sole protection.

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | LastPass Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | MFA enforcement | [1.1](#11-require-multi-factor-authentication) |
| CC6.1 | Master password policy | [2.1](#21-enable-master-password-requirements) |
| CC6.2 | Admin roles | [2.4](#24-configure-admin-permission-levels) |
| CC6.6 | Sharing restrictions | [2.2](#22-configure-sharing-restrictions) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | LastPass Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | MFA | [1.1](#11-require-multi-factor-authentication) |
| IA-5 | Password policy | [2.1](#21-enable-master-password-requirements) |
| AC-3 | Sharing controls | [2.2](#22-configure-sharing-restrictions) |
| AC-6(1) | Least privilege | [2.4](#24-configure-admin-permission-levels) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |

---

## Appendix A: Plan Compatibility

| Feature | Teams | Business | Enterprise |
|---------|-------|----------|------------|
| MFA | Basic | ✅ | ✅ |
| Admin Policies | Limited | 100+ | 100+ |
| Directory Sync | ❌ | ✅ | ✅ |
| Federated Login | ❌ | ❌ | ✅ |
| Security Dashboard | Basic | ✅ | ✅ |
| Dark Web Monitoring | ❌ | ✅ | ✅ |
| Advanced Reporting | ❌ | ✅ | ✅ |

---

## Appendix B: Post-Breach Considerations

Following the 2022 LastPass security incidents, consider:

1. **Assess Risk:** Determine if your vault data was affected
2. **Rotate Credentials:** Change all stored passwords, especially for critical systems
3. **Increase Master Password Strength:** Use 16+ character passwords
4. **Increase Iterations:** Ensure PBKDF2 iterations are 600,000+
5. **Enable MFA:** If not already enabled
6. **Consider Alternatives:** Evaluate if LastPass meets your risk tolerance

---

## Appendix C: References

**Official LastPass Documentation:**
- [LastPass Trust Center](https://www.lastpass.com/trust-center)
- [LastPass Support](https://support.lastpass.com/)
- [Admin Best Practices](https://support.lastpass.com/s/document-item?language=en_US&bundleId=lastpass&topicId=LastPass/admin_best_practices.html)
- [Three Admin Policies to Enable Today](https://blog.lastpass.com/posts/three-lastpass-admin-policies-to-enable-today)
- [How to Enforce Strong Password Policies](https://blog.lastpass.com/posts/how-to-enforce-strong-password-policies)
- [How to Set Up Multi-Factor Authentication](https://blog.lastpass.com/posts/how-to-set-up-multi-factor-authentication-to-protect-your-business)
- [Enable MFA for Admins](https://support.lastpass.com/s/document-item?language=en_US&bundleId=lastpass&topicId=LastPass/Enable_Multifactor_Authentication_Admins.html)

**API & Developer Resources:**
- [LastPass Enterprise API](https://support.lastpass.com/s/document-item?language=en_US&bundleId=lastpass&topicId=LastPass/api_enterprise.html)
- [Unified Admin Controls for User Management](https://www.lastpass.com/features/user-management)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3, ISO 27001, ISO 27701, BSI C5, FIDO2 Server Certified -- via [LastPass Trust Center](https://www.lastpass.com/trust-center) and [LastPass Compliance Center](https://compliance.lastpass.com/)

**Security Incidents:**
- **August 2022:** Threat actor compromised a developer's laptop, gaining access to LastPass's development environment and stealing source code and internal system secrets.
- **November-December 2022:** Using information from the first breach, the attacker targeted a DevOps engineer's home computer via a third-party media software vulnerability, installed a keylogger, captured credentials, and exfiltrated encrypted customer vault backups along with unencrypted metadata (website URLs, email addresses, billing info). See [Appendix B](#appendix-b-post-breach-considerations) for remediation guidance.
- **March 2023:** Investigation confirmed no threat actor activity since October 2022. LastPass increased PBKDF2 iterations and implemented additional security controls.
- **2025:** Federal investigators linked approximately $150M in cryptocurrency theft to credentials stolen in the 2022 LastPass breach.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with MFA, policies, and security dashboard | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
