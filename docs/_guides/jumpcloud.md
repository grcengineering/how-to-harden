---
layout: guide
title: "JumpCloud Hardening Guide"
vendor: "JumpCloud"
slug: "jumpcloud"
tier: "2"
category: "Identity"
description: "Cloud directory and identity management hardening for JumpCloud SSO, MFA, and device management"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

JumpCloud is a cloud-based directory platform providing identity management, SSO, MFA, and device management for **over 200,000 organizations**. As a unified directory replacing traditional Active Directory, JumpCloud security configurations directly impact access control across all integrated resources including systems, applications, and networks.

### Intended Audience
- Security engineers managing JumpCloud deployments
- IT administrators configuring directory policies
- GRC professionals assessing identity controls
- Third-party risk managers evaluating directory services

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers JumpCloud Admin Portal security, MFA policies, conditional access, device management, and system policies.

---

## Table of Contents

1. [Admin Account Security](#1-admin-account-security)
2. [Multi-Factor Authentication](#2-multi-factor-authentication)
3. [Conditional Access](#3-conditional-access)
4. [Device & System Management](#4-device--system-management)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Admin Account Security

### 1.1 Secure Admin Portal Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Secure JumpCloud Admin Portal access with MFA and role-based access controls. Admin accounts with unrestricted access are high-value targets.

#### Rationale
**Why This Matters:**
- Admin Portal controls all identity and access settings
- Compromised admin can disable security controls
- MFA for admins is critical but often overlooked

#### ClickOps Implementation

**Step 1: Enable Admin MFA**
1. Navigate to: **JumpCloud Admin Portal** → **Security** → **MFA for Admins**
2. Enable **Require MFA for Admin Portal**
3. Configure allowed MFA methods:
   - **TOTP Authenticator:** Recommended
   - **WebAuthn:** Highly recommended
   - **JumpCloud Go:** Recommended

**Step 2: Configure Admin Roles**
1. Navigate to: **Settings** → **Admin Roles**
2. Review default roles:
   - **Administrator:** Full access (limit to 2-3)
   - **Manager:** User and group management
   - **Help Desk:** Password reset, limited user view
   - **Read Only:** View-only access
3. Create custom roles for specific functions
4. Assign minimum required permissions

**Step 3: Audit Admin Accounts**
1. Navigate to: **Admins**
2. Review all administrator accounts
3. Remove unnecessary admin access
4. Verify all admins have MFA enrolled

**Time to Complete:** ~30 minutes

---

### 1.2 Implement Least Privilege Administration

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Implement tiered administration following the principle of least privilege.

#### Implementation

**Tier 0 (Critical):**
- Full Administrator role
- Limit to 2-3 trusted admins
- Require strongest MFA (WebAuthn/hardware keys)

**Tier 1 (Standard Admin):**
- Manager role for user/group management
- Day-to-day administration tasks

**Tier 2 (Support):**
- Help Desk role for password resets
- Read Only for auditors

---

## 2. Multi-Factor Authentication

### 2.1 Enforce Organization-Wide MFA

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all user authentication to protected resources including the User Portal, applications, and systems.

#### Rationale
**Why This Matters:**
- MFA blocks 99.9% of automated attacks
- JumpCloud supports multiple MFA methods
- Organization-wide enforcement prevents gaps

#### ClickOps Implementation

**Step 1: Enable User MFA**
1. Navigate to: **Security** → **MFA**
2. Enable **Require MFA for User Portal**
3. Configure enforcement:
   - **All Users:** Recommended for most organizations
   - **User Groups:** For phased rollout

**Step 2: Configure Allowed Methods**
1. Select allowed MFA methods:
   - **TOTP:** Enabled (Google Authenticator, Authy)
   - **WebAuthn (Security Keys):** Enabled
   - **WebAuthn (Platform):** Enabled (Touch ID, Windows Hello)
   - **JumpCloud Go:** Enabled (recommended)
   - **SMS/Voice:** Disable if possible (less secure)
2. Set **Default MFA Method** preference

**Step 3: Enable JumpCloud Go**
1. Navigate to: **Security** → **JumpCloud Go**
2. Enable JumpCloud Go for passwordless authentication
3. This uses device authenticators with biometrics

**Time to Complete:** ~20 minutes

---

### 2.2 Configure MFA for System Access

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for system login (Windows, macOS, Linux) and SSH access.

#### ClickOps Implementation

**Step 1: Enable MFA for Systems**
1. Navigate to: **Security** → **MFA**
2. Enable **Require MFA for System Login**
3. Configure per-OS settings:
   - **Windows:** Enable MFA at Windows logon
   - **macOS:** Enable MFA at macOS login
   - **Linux:** Enable MFA for SSH

**Step 2: Configure SSH MFA**
1. For Linux systems, configure JumpCloud agent
2. Enable **MFA Required** for SSH connections
3. Users will need to complete MFA after password

---

## 3. Conditional Access

### 3.1 Configure Conditional Access Policies

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.4 |
| NIST 800-53 | AC-2(11) |

#### Description
Configure conditional access policies to enforce context-aware security controls based on location, device, and risk signals.

#### Rationale
**Why This Matters:**
- Context-aware access enables Zero Trust
- Block access from risky locations or devices
- Dynamically adjust MFA requirements

#### ClickOps Implementation

**Step 1: Create Conditional Access Policy**
1. Navigate to: **Security** → **Conditional Access**
2. Click **Create New Policy**
3. Configure policy conditions:
   - **Location:** Define trusted/untrusted locations
   - **Device Trust:** Require managed devices
   - **User Groups:** Apply to specific groups

**Step 2: Define Policy Actions**
1. Configure actions based on conditions:
   - **Allow access:** From trusted locations
   - **Require MFA:** From unknown locations
   - **Block access:** From blocked countries
2. Set policy priority

**Example Policy: Block Untrusted Locations**
```
Name: Block High-Risk Countries
Conditions:
  - Location NOT IN: [US, CA, UK, trusted countries]
Actions:
  - Block access
Apply to: All Users (except emergency accounts)
```

**Example Policy: Require MFA Outside Office**
```
Name: Require MFA - Remote Access
Conditions:
  - Location NOT IN: [Corporate IP ranges]
Actions:
  - Require MFA
Apply to: All Users
```

**Time to Complete:** ~45 minutes

---

### 3.2 Configure Device Trust

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | AC-2(11) |

#### Description
Configure device trust to verify endpoint compliance before granting access to protected resources.

#### ClickOps Implementation

**Step 1: Enable Device Trust**
1. Navigate to: **Security** → **Conditional Access**
2. Create policy with device conditions
3. Configure:
   - **Require JumpCloud Agent:** Verify device is managed
   - **Require encryption:** Verify disk encryption
   - **Require updated OS:** Verify minimum OS version

**Step 2: Create Device Trust Policy**
1. Integrate with conditional access
2. Block access from non-compliant devices
3. Or require additional authentication

---

## 4. Device & System Management

### 4.1 Configure System Policies

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-7 |

#### Description
Configure JumpCloud system policies to enforce security settings across managed devices.

#### ClickOps Implementation

**Step 1: Access System Policies**
1. Navigate to: **Device Management** → **Policies**
2. Review available policy types

**Step 2: Configure Security Policies**
Create and apply these essential policies:

**Screen Lock Policy:**
1. Create new policy for screen lock
2. Configure:
   - **Lock after inactivity:** 5 minutes
   - **Require password:** Yes
3. Apply to all systems

**Full Disk Encryption Policy:**
1. Create policy for FDE
2. Configure:
   - **Windows:** BitLocker
   - **macOS:** FileVault
   - **Linux:** LUKS
3. Enforce encryption with key escrow

**Firewall Policy:**
1. Create policy enabling firewall
2. Configure:
   - **Windows Firewall:** Enabled
   - **macOS Firewall:** Enabled
3. Apply to all systems

**System Updates Policy:**
1. Create policy for OS updates
2. Configure update schedule
3. Enforce critical security patches

**Time to Complete:** ~1 hour

---

### 4.2 Configure LDAP & RADIUS Security

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10 |
| NIST 800-53 | SC-8 |

#### Description
Secure JumpCloud's cloud LDAP and RADIUS services for directory and network authentication.

#### ClickOps Implementation

**Step 1: Configure Cloud LDAP**
1. Navigate to: **Settings** → **Cloud LDAP**
2. Review bound applications
3. Use dedicated service accounts for LDAP binds
4. Enable TLS for LDAP connections

**Step 2: Configure Cloud RADIUS**
1. Navigate to: **Settings** → **Cloud RADIUS**
2. Configure for WiFi/VPN authentication
3. Require MFA for RADIUS authentication
4. Configure shared secrets securely

---

## 5. Monitoring & Detection

### 5.1 Enable Directory Insights

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-6 |

#### Description
Enable JumpCloud Directory Insights for comprehensive audit logging and security monitoring.

#### ClickOps Implementation

**Step 1: Access Directory Insights**
1. Navigate to: **Reports** → **Directory Insights**
2. Review available log types:
   - Admin events
   - User authentication
   - System events
   - SSO events

**Step 2: Configure Log Export**
1. Navigate to: **Settings** → **Directory Insights**
2. Configure SIEM integration:
   - AWS S3
   - Azure Blob Storage
   - Webhook (generic SIEM)
3. Configure retention period

**Time to Complete:** ~30 minutes

---

### 5.2 Key Events to Monitor

| Event Type | Detection Use Case |
|------------|-------------------|
| Admin login | Unauthorized admin access |
| Admin changes | Policy modifications |
| MFA bypass | Security control circumvention |
| Failed authentication | Brute force attempts |
| New device enrollment | Unauthorized device |
| Policy changes | Configuration drift |

---

## 6. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | JumpCloud Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.1 | Admin MFA | [1.1](#11-secure-admin-portal-access) |
| CC6.1 | User MFA | [2.1](#21-enforce-organization-wide-mfa) |
| CC6.2 | Admin roles | [1.2](#12-implement-least-privilege-administration) |
| CC6.6 | Conditional access | [3.1](#31-configure-conditional-access-policies) |
| CC7.2 | Directory Insights | [5.1](#51-enable-directory-insights) |

### NIST 800-53 Rev 5 Mapping

| Control | JumpCloud Control | Guide Section |
|---------|-------------------|---------------|
| IA-2(1) | MFA enforcement | [2.1](#21-enforce-organization-wide-mfa) |
| AC-6(1) | Least privilege | [1.2](#12-implement-least-privilege-administration) |
| AC-2(11) | Conditional access | [3.1](#31-configure-conditional-access-policies) |
| CM-7 | System policies | [4.1](#41-configure-system-policies) |
| AU-2 | Logging | [5.1](#51-enable-directory-insights) |

---

## Appendix A: Plan Compatibility

| Feature | Free | Core | Platform | Platform Plus |
|---------|------|------|----------|---------------|
| User MFA | ✅ (10 users) | ✅ | ✅ | ✅ |
| Admin MFA | ✅ | ✅ | ✅ | ✅ |
| Conditional Access | ❌ | ❌ | ✅ | ✅ |
| System Policies | Limited | ✅ | ✅ | ✅ |
| Directory Insights | ❌ | ❌ | ✅ | ✅ |
| JumpCloud Go | ❌ | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official JumpCloud Documentation:**
- [JumpCloud Support](https://jumpcloud.com/support)
- [MFA for Admins](https://jumpcloud.com/support/mfa-for-admins)
- [Conditional Access](https://jumpcloud.com/support/configure-a-conditional-access-policy)
- [Best Practices: Secure Your Organization](https://jumpcloud.com/support/best-practices-secure-your-organization)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with admin security, MFA, and conditional access | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
