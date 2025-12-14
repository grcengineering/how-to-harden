# Dropbox Business Hardening Guide

**Version:** 1.0
**Last Updated:** 2025-12-14
**Product Editions Covered:** Dropbox Standard, Advanced, Enterprise
**Authors:** How to Harden Community

---

## Overview

Dropbox has **700+ million registered users** with enterprise file storage. The **2024 Dropbox Sign breach** exposed OAuth tokens, API keys, hashed passwords, and MFA data via compromised service account. Third-party app permissions and refresh tokens enable persistent file access. The 2022 GitHub breach resulted in 100+ code repositories stolen.

### Intended Audience
- Security engineers managing file storage
- IT administrators configuring Dropbox
- GRC professionals assessing collaboration compliance
- Third-party risk managers evaluating storage integrations

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Sharing & External Access](#2-sharing--external-access)
3. [Third-Party App Security](#3-third-party-app-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### Description
Require SSO with MFA for all Dropbox Business access.

#### Rationale
**Why This Matters:**
- 2024 Dropbox Sign breach exposed OAuth tokens and API keys
- Compromised accounts access sensitive documents
- Service account compromise enabled 2024 breach

**Real-World Incidents:**
- **2024 Dropbox Sign Breach:** Compromised service account exposed OAuth tokens, API keys, hashed passwords, and MFA data
- **2022 GitHub Breach:** 100+ code repositories stolen

#### ClickOps Implementation

**Step 1: Configure SSO**
1. Navigate to: **Admin Console → Settings → Single Sign-On**
2. Configure SAML with your IdP
3. Enable: **Require SSO**

**Step 2: Enforce MFA**
1. Navigate to: **Admin Console → Settings → Security**
2. Enable: **Require two-step verification for all members**

---

### 1.2 Configure Access Permissions

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Configure Team Folder Permissions**
1. Navigate to: **Admin Console → Content → Team Folders**
2. Set default permissions by team
3. Restrict admin folder access

---

## 2. Sharing & External Access

### 2.1 Restrict External Sharing

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-21

#### ClickOps Implementation

**Step 1: Configure Sharing Settings**
1. Navigate to: **Admin Console → Settings → Sharing**
2. Configure:
   - **External sharing:** Restricted or disabled
   - **Link permissions:** Team members only by default
   - **Password on links:** Required

**Step 2: Configure Link Expiration**
1. Enable: **Default expiration for shared links**
2. Set: Maximum 30 days (L2: 7 days)

---

## 3. Third-Party App Security

### 3.1 Manage Connected Apps

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### Rationale
**Why This Matters:**
- Third-party app refresh tokens are perpetual
- OAuth tokens persist after app uninstallation
- 2024 breach exposed OAuth tokens

#### ClickOps Implementation

**Step 1: Review Connected Apps**
1. Navigate to: **Admin Console → Settings → Apps**
2. Review all connected apps
3. Revoke unnecessary permissions

**Step 2: Restrict App Installation**
1. Configure: **Who can link third-party apps**
2. Require admin approval for new apps

---

## 4. Monitoring & Detection

### 4.1 Enable Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Access Activity Log**
1. Navigate to: **Admin Console → Activity**
2. Configure exports to SIEM
3. Enable alerts for sensitive events

#### Detection Queries

```sql
-- Detect bulk downloads
SELECT user_email, COUNT(*) as download_count
FROM dropbox_activity
WHERE action = 'file_download'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_email
HAVING COUNT(*) > 100;

-- Detect external sharing
SELECT user_email, shared_with, file_path
FROM dropbox_activity
WHERE action = 'share_link_create'
  AND is_external = true
  AND timestamp > NOW() - INTERVAL '24 hours';
```

---

## Appendix A: Edition Compatibility

| Control | Standard | Advanced | Enterprise |
|---------|----------|----------|------------|
| SSO (SAML) | ❌ | ✅ | ✅ |
| Audit Log | Basic | ✅ | ✅ |
| Device Approval | ❌ | ✅ | ✅ |
| Data Classification | ❌ | ❌ | ✅ |

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial Dropbox hardening guide | How to Harden Community |
