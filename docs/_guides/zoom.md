---
layout: guide
title: "Zoom Hardening Guide"
vendor: "Zoom"
slug: "zoom"
tier: "2"
category: "Collaboration"
description: "Video conferencing security for meeting policies, recording controls, and app marketplace"
last_updated: "2025-12-14"
---


## Overview

Zoom commands **55.91% global market share** with **70% of Fortune 100** as customers. The App Marketplace, OAuth tokens (access valid 14 days, refresh perpetual), and SDK integrations create supply chain risk. Recent CVE-2025-49457 (CVSS 9.6) demonstrates ongoing vulnerability management challenges. Customer Managed Key (CMK) provides encryption control for sensitive communications.

### Intended Audience
- Security engineers managing collaboration tools
- IT administrators configuring Zoom
- GRC professionals assessing video collaboration compliance
- Third-party risk managers evaluating SDK integrations

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Zoom security configurations including authentication, meeting security, Marketplace app governance, and encryption controls.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Meeting Security](#2-meeting-security)
3. [Marketplace App Security](#3-marketplace-app-security)
4. [Data Security & Encryption](#4-data-security--encryption)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML/OIDC SSO with MFA for all Zoom access.

#### ClickOps Implementation

**Step 1: Configure SAML SSO (Business/Enterprise)**
1. Navigate to: **Admin → Advanced → Security → Single Sign-On**
2. Click **Enable Single Sign-On**
3. Configure:
   - **Sign-in page URL:** IdP login endpoint
   - **Sign-out page URL:** IdP logout endpoint
   - **Certificate:** Upload IdP certificate
   - **Service Provider Entity ID:** From Zoom

**Step 2: Enforce SSO Login**
1. Navigate to: **Admin → Advanced → Security**
2. Enable: **Only allow users to sign in with SSO**
3. Disable: **Allow users to sign in with work email**

**Step 3: Configure Two-Factor Authentication**
1. Navigate to: **Admin → Advanced → Security → Security**
2. Enable: **Sign in with Two-Factor Authentication**
3. Configure: **All users in your account**

---

### 1.2 Configure User Management

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### Description
Implement role-based access and user provisioning.

#### ClickOps Implementation

**Step 1: Configure Roles**
1. Navigate to: **Admin → User Management → Roles**
2. Create/modify roles:

| Role | Permissions |
|------|-------------|
| Member | Host meetings, basic features |
| Admin | Manage users, settings |
| Owner | Full account control (1 user only) |

**Step 2: Enable SCIM Provisioning**
1. Navigate to: **Admin → Advanced → Integration**
2. Enable: **SCIM token**
3. Configure IdP to sync users via SCIM

**Step 3: Configure Auto-Provisioning**
1. Navigate to: **Admin → Advanced → Security**
2. Enable: **Automatic provisioning for SSO users**
3. Set default role and group

---

## 2. Meeting Security

### 2.1 Enforce Meeting Password and Waiting Room

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3

#### Description
Require passwords and waiting rooms to prevent unauthorized meeting access.

#### ClickOps Implementation

**Step 1: Configure Account-Level Settings**
1. Navigate to: **Admin → Account Management → Account Settings → Security**
2. Enable and lock:
   - **Require a passcode when scheduling new meetings:** Locked
   - **Require a passcode for participants joining by phone:** Locked
   - **Waiting Room:** Locked (enabled by default)

**Step 2: Configure Meeting Authentication**
1. Navigate to: **Admin → Account Settings → Security**
2. Enable: **Only authenticated users can join meetings**
3. Configure: Authentication methods (SSO, Zoom account)

**Step 3: Disable Risky Features**
1. Navigate to: **Admin → Account Settings → Meeting**
2. Disable (or lock as disabled):
   - **Allow participants to rename themselves:** Disabled
   - **Allow removed participants to rejoin:** Disabled
   - **File transfer:** Disable or restrict to hosts

---

### 2.2 Meeting Encryption Settings

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-8

#### Description
Configure end-to-end encryption for sensitive meetings.

#### ClickOps Implementation

**Step 1: Enable E2EE**
1. Navigate to: **Admin → Account Settings → Security**
2. Enable: **End-to-end encrypted meetings**
3. Configure: **Default encryption type:** Enhanced encryption (or E2EE for L3)

**Step 2: Verify E2EE in Meetings**
- Green shield icon indicates E2EE
- Verify security code with participants for high-sensitivity meetings

---

### 2.3 Configure Zoom Phone Security (If Used)

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-8

#### Description
Secure Zoom Phone configurations.

#### ClickOps Implementation

1. Navigate to: **Admin → Phone System Management**
2. Configure:
   - **Call recording:** Require consent
   - **Voicemail encryption:** Enable
   - **Emergency calling:** Configure E911

---

## 3. Marketplace App Security

### 3.1 Implement App Approval Workflow

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### Description
Control Zoom App Marketplace installations.

#### Rationale
**Why This Matters:**
- Marketplace apps access meeting data and recordings
- OAuth tokens have long validity (access: 14 days, refresh: perpetual)
- Compromised apps can access all user meetings

#### ClickOps Implementation

**Step 1: Configure App Installation Policy**
1. Navigate to: **Admin → Advanced → App Marketplace**
2. Configure:
   - **Pre-approve apps:** Enable
   - **Who can install:** Admins only

**Step 2: Review Installed Apps**
1. Navigate to: **Admin → Advanced → App Marketplace → Manage**
2. Review each app:
   - Permissions/scopes
   - Installation date
   - Active users
3. Remove unused apps

**Step 3: Restrict App Categories**
1. Block categories not needed:
   - Games
   - Social
   - Productivity (if not required)

---

### 3.2 OAuth Token Management

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5(13)

#### Description
Manage OAuth tokens for marketplace apps.

#### Key Settings

| Token Type | Default Validity | Recommendation |
|------------|-----------------|----------------|
| Access Token | 14 days | N/A (Zoom managed) |
| Refresh Token | Perpetual | Monitor usage, revoke unused |

#### User-Level Revocation
1. Users: **Profile → Apps → Uninstall**
2. Admins: **Admin → App Marketplace → Remove access**

---

## 4. Data Security & Encryption

### 4.1 Configure Customer Managed Key (CMK)

**Profile Level:** L3 (Maximum Security)
**NIST 800-53:** SC-12

#### Description
Use customer-managed encryption keys for meeting content.

#### ClickOps Implementation (Enterprise)

**Step 1: Enable CMK**
1. Navigate to: **Admin → Advanced → Security → Data at Rest Encryption**
2. Enable: **Customer Managed Key**
3. Configure key in your cloud KMS (AWS KMS, Azure Key Vault)

**Step 2: Configure Key Rotation**
1. Set key rotation in cloud KMS
2. Document key recovery procedures

---

### 4.2 Configure Recording Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### Description
Secure meeting recordings.

#### ClickOps Implementation

**Step 1: Recording Settings**
1. Navigate to: **Admin → Account Settings → Recording**
2. Configure:
   - **Recording consent:** Required
   - **Cloud recording:** Password protect
   - **Download restriction:** Authenticated users only

**Step 2: Recording Access**
1. Configure: **Who can access cloud recordings**
2. Enable: **Viewer authentication required**
3. Set: **Default expiration:** 30 days (L2)

---

## 5. Monitoring & Detection

### 5.1 Enable Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### Description
Configure Zoom audit logging.

#### ClickOps Implementation

**Step 1: Access Reports**
1. Navigate to: **Admin → Account Management → Reports**
2. Review:
   - Sign in/out activity
   - Meeting reports
   - Webinar reports

**Step 2: Operation Logs (Enterprise)**
1. Navigate to: **Admin → Account Management → Reports → Activity**
2. Export operation logs
3. Forward to SIEM

#### Detection Queries

```sql
-- Detect unusual meeting creation
SELECT user_id, COUNT(*) as meeting_count
FROM zoom_meetings
WHERE created_at > NOW() - INTERVAL '1 hour'
GROUP BY user_id
HAVING COUNT(*) > 20;

-- Detect recording access anomalies
SELECT user_id, recording_id, access_time
FROM recording_access_log
WHERE user_id NOT IN (SELECT host_id FROM meetings WHERE id = recording_id);
```

---

## 6. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Zoom Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO enforcement | 1.1 |
| CC6.6 | Meeting security | 2.1 |
| CC6.7 | Encryption | 4.1 |

### HIPAA Considerations

- Enable E2EE for healthcare meetings
- Configure recording consent
- Use CMK for data at rest
- Sign BAA with Zoom

---

## Appendix A: Edition Compatibility

| Control | Basic | Pro | Business | Enterprise |
|---------|-------|-----|----------|------------|
| MFA | ✅ | ✅ | ✅ | ✅ |
| SSO (SAML) | ❌ | ❌ | ✅ | ✅ |
| E2EE | ✅ | ✅ | ✅ | ✅ |
| CMK | ❌ | ❌ | ❌ | ✅ |
| Audit Logs | ❌ | ❌ | ✅ | ✅ |

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial Zoom hardening guide | How to Harden Community |
