---
layout: guide
title: "Miro Hardening Guide"
vendor: "Miro"
slug: "miro"
tier: "4"
category: "Productivity"
description: "Visual collaboration security for board sharing, app controls, and export restrictions"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

Miro is a visual collaboration platform for whiteboards, diagrams, and design sessions. REST API, OAuth integrations, and public board sharing handle sensitive planning documents and architecture diagrams. Compromised access exposes strategic planning, product roadmaps, and internal processes.

### Intended Audience
- Security engineers managing collaboration tools
- Miro team administrators
- GRC professionals assessing visual collaboration security
- Third-party risk managers evaluating design tool integrations


### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries


### Scope
This guide covers Miro security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Board & Content Security](#2-board--content-security)
3. [Integration Security](#3-integration-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### ClickOps Implementation

**Step 1: Configure SAML SSO (Enterprise)**
1. Navigate to: **Company Settings → Security → SAML SSO**
2. Configure SAML IdP
3. Enable: **Enforce SSO**

**Step 2: Enable 2FA (Non-SSO)**
1. Navigate to: **Company Settings → Security**
2. Enable: **Require 2FA**

---

### 1.2 Team Access Controls

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define Team Roles**

| Role | Permissions |
|------|-------------|
| Admin | Full team management |
| Member | Create/edit boards |
| Guest | Board-specific access |

**Step 2: Configure Team Settings**
1. Navigate to: **Team Settings**
2. Configure member permissions
3. Set guest access policies

---

## 2. Board & Content Security

### 2.1 Configure Sharing Defaults

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-21

#### Description
Control board sharing to prevent data exposure.

#### Rationale
**Attack Scenario:** Public boards containing architecture diagrams indexed by search engines; competitive intelligence exposed.

#### ClickOps Implementation

**Step 1: Disable Public Sharing**
1. Navigate to: **Company Settings → Security → Board sharing**
2. Disable: **Allow public boards**
3. Review existing public boards

**Step 2: Configure Default Permissions**
1. Set default share settings
2. Restrict external access
3. Configure domain restrictions

---

### 2.2 Board Export Controls

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-21

#### ClickOps Implementation

**Step 1: Restrict Exports**
1. Navigate to: **Company Settings → Security**
2. Configure: **Export restrictions**
3. Limit high-resolution exports

---

## 3. Integration Security

### 3.1 Manage Apps

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### ClickOps Implementation

**Step 1: Audit Installed Apps**
1. Navigate to: **Company Settings → Apps**
2. Review all installed apps
3. Remove unused apps

**Step 2: Restrict App Installation**
1. Configure: **App installation policy**
2. Require admin approval
3. Audit app permissions

---

### 3.2 API Token Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Implementation

**Step 1: Manage Access Tokens**
1. Navigate to: **Profile → Apps & integrations**
2. Audit personal access tokens
3. Revoke unused tokens

**Step 2: OAuth App Security**
1. Review authorized apps
2. Limit OAuth scopes
3. Rotate tokens periodically

---

## 4. Monitoring & Detection

### 4.1 Audit Logs (Enterprise)

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Company Settings → Security → Audit logs**
2. Review activity events
3. Configure SIEM integration

#### Detection Focus

{% include pack-code.html vendor="miro" section="4.1" %}

---

## Appendix A: Edition Compatibility

| Control | Team | Business | Enterprise |
|---------|------|----------|------------|
| SAML SSO | ❌ | ❌ | ✅ |
| SCIM | ❌ | ❌ | ✅ |
| Audit Logs | ❌ | ❌ | ✅ |
| Domain Restrictions | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official Miro Documentation:**
- [Miro Trust Center](https://trust.miro.com/)
- [Miro Help Center](https://help.miro.com/hc/en-us)
- [Miro Enterprise Security](https://miro.com/enterprise-security/)
- [Enterprise Guard Deployment Guide](https://help.miro.com/hc/en-us/articles/17120515162386-Enterprise-Guard-Deployment-Guide-Introduction)

**API Documentation:**
- [Miro Developer Portal](https://developers.miro.com/)
- [Miro REST API Reference](https://developers.miro.com/reference)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3, ISO/IEC 27001, ISO 42001 — via [Miro Trust Center](https://trust.miro.com/)
- [Miro Security Policy (PDF)](https://miro.com/legal/documents/Miro-Security-Policy.pdf)

**Security Incidents:**
- No major public security incidents identified for Miro. Monitor the [Miro Trust Center](https://trust.miro.com/) for current advisories.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial Miro hardening guide | Claude Code (Opus 4.5) |
