---
layout: guide
title: "Dropbox Hardening Guide"
vendor: "Dropbox"
slug: "dropbox"
tier: "3"
category: "Data"
description: "Cloud storage security for sharing policies, linked apps, and admin controls"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

Dropbox has **700+ million registered users** with enterprise file storage. The **2024 Dropbox Sign breach** exposed OAuth tokens, API keys, hashed passwords, and MFA data via compromised service account. Third-party app permissions and refresh tokens enable persistent file access. The 2022 GitHub breach resulted in 100+ code repositories stolen.

### Intended Audience
- Security engineers managing file storage
- IT administrators configuring Dropbox
- GRC professionals assessing collaboration compliance
- Third-party risk managers evaluating storage integrations


### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries


### Scope
This guide covers Dropbox security configurations including authentication, access controls, and integration security.

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

{% include pack-code.html vendor="dropbox" section="4.1" %}

---

## Appendix A: Edition Compatibility

| Control | Standard | Advanced | Enterprise |
|---------|----------|----------|------------|
| SSO (SAML) | ❌ | ✅ | ✅ |
| Audit Log | Basic | ✅ | ✅ |
| Device Approval | ❌ | ✅ | ✅ |
| Data Classification | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Dropbox Documentation:**
- [Trust Center](https://trust.dropbox.com/)
- [Help Center](https://help.dropbox.com/)
- [Certifications & Compliance](https://www.dropbox.com/business/trust/compliance/certifications-compliance)
- [Security Whitepaper (PDF)](https://aem.dropbox.com/cms/content/dam/dropbox/www/en-us/business/trust/dropbox-security-whitepaper.pdf)

**API & Developer Documentation:**
- [Dropbox HTTP API Overview](https://www.dropbox.com/developers/documentation/http/overview)
- [Dropbox Developer Center](https://www.dropbox.com/developers)

**Compliance Frameworks:**
- SOC 2 Type II (Ernst & Young LLP audited), ISO 27001, ISO 27017, ISO 27018, ISO 22301, ISO 27701 — via [Trust Center](https://trust.dropbox.com/)
- CSA STAR Level 2 Certification and Attestation
- GDPR, HIPAA compliant

**Security Incidents:**
- **2024 Dropbox Sign Breach:** Compromised service account exposed OAuth tokens, API keys, hashed passwords, and MFA data for Dropbox Sign (formerly HelloSign) users.
- **2022 GitHub Repository Breach:** Phishing attack against Dropbox employees resulted in 130 private code repositories being accessed and copied.
- **2012 Password Breach:** Credentials stolen from a third-party site used to access a Dropbox employee account, leading to exposure of approximately 68 million user email addresses and hashed passwords (disclosed publicly in 2016).

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial Dropbox hardening guide | Claude Code (Opus 4.5) |
