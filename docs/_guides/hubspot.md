---
layout: guide
title: "HubSpot Hardening Guide"
vendor: "HubSpot"
slug: "hubspot"
tier: "2"
category: "CRM"
description: "CRM security for private apps, OAuth scopes, and data export controls"
last_updated: "2025-12-14"
---


## Overview

HubSpot serves **247,939+ paying customers** with **38% global marketing automation market share**. The App Marketplace hosts **1,500+ integrations** accessing customer PII, sales pipeline data, and marketing campaign information. OAuth grants from marketplace apps create broad CRM access that persists even after app uninstallation without explicit revocation.

### Intended Audience
- Security engineers hardening CRM systems
- Marketing operations administrators
- GRC professionals assessing CRM compliance
- Third-party risk managers evaluating marketing integrations

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers HubSpot security configurations including authentication, marketplace app governance, API security, and data protection controls.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Marketplace App Security](#2-marketplace-app-security)
3. [API & Integration Security](#3-api--integration-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML SSO with MFA for all HubSpot access.

#### ClickOps Implementation (Enterprise)

**Step 1: Configure SAML SSO**
1. Navigate to: **Settings → Account Management → Security → Single Sign-On**
2. Click **Set up single sign-on**
3. Configure:
   - **Identity provider:** Your IdP
   - **Sign-on URL:** IdP endpoint
   - **Certificate:** Upload IdP certificate

**Step 2: Enforce SSO**
1. Enable: **Require SSO**
2. Configure: **Session timeout:** 8 hours

**Step 3: Configure Two-Factor Authentication**
1. Navigate to: **Settings → Account Management → Security → Two-factor authentication**
2. Enable: **Require 2FA for all users**

---

### 1.2 Implement User Permission Sets

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure permission sets limiting access to CRM data and features.

#### ClickOps Implementation

**Step 1: Create Role-Based Permission Sets**
1. Navigate to: **Settings → Users & Teams → Permission Sets**
2. Create sets:

**Marketing User:**
- Email: Full access
- Forms: Full access
- Contacts: View assigned only
- Reports: View only

**Sales User:**
- Deals: Full access (assigned)
- Contacts: View/Edit assigned
- Emails: Send only
- Reports: View assigned

**Super Admin:**
- Full access (limit to 2-3 users)
- Required for security settings

**Step 2: Assign Permission Sets**
1. Navigate to: **Users → Select user → Permissions**
2. Assign appropriate permission set
3. Configure team-based restrictions

---

## 2. Marketplace App Security

### 2.1 Implement App Approval Workflow

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### Description
Require approval for marketplace app installations.

#### Rationale
**Why This Matters:**
- 1,500+ marketplace apps with varying security
- Apps access customer PII and sales data
- OAuth tokens persist after app uninstall

**Attack Scenario:** Compromised marketplace app extracts customer contact lists for targeted phishing; OAuth tokens enable persistent API access.

#### ClickOps Implementation

**Step 1: Configure App Installation Policy**
1. Navigate to: **Settings → Integrations → Connected Apps**
2. Configure: **Who can install apps:** Super Admins only

**Step 2: Review Existing Apps**
1. Navigate to: **Settings → Integrations → Connected Apps**
2. For each app, review:
   - Permissions/scopes requested
   - Installation date
   - Active users
3. Remove unused apps

**Step 3: Create App Evaluation Checklist**
- [ ] Review OAuth scopes requested
- [ ] Check vendor security certifications
- [ ] Evaluate data access requirements
- [ ] Document business justification
- [ ] Verify app is from verified publisher

---

### 2.2 Audit OAuth Grants

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5(13)

#### Description
Regularly audit OAuth grants to marketplace apps.

#### ClickOps Implementation

**Step 1: Review Connected Apps**
1. Navigate to: **Settings → Integrations → Connected Apps**
2. Document all connected apps and their scopes

**Step 2: Revoke Unnecessary Grants**
1. For unused apps: **Uninstall** and **Revoke access**
2. Note: Uninstalling alone doesn't revoke OAuth tokens

**Step 3: User-Level OAuth Review**
1. Have users review their authorized apps:
   - **Profile → Integrations → Connected Apps**
2. Revoke personal app authorizations

---

## 3. API & Integration Security

### 3.1 Secure Private App Tokens

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Manage private app access tokens with appropriate restrictions.

#### ClickOps Implementation

**Step 1: Create Scoped Private Apps**
1. Navigate to: **Settings → Integrations → Private Apps**
2. Create app with minimum scopes:
   - Select only required APIs
   - Document purpose
   - Set meaningful name

**Step 2: Token Security**
- Store tokens in secrets manager
- Never commit tokens to code
- Rotate tokens quarterly

**Step 3: Audit Existing Tokens**
```bash
# List private apps via API
curl -X GET "https://api.hubapi.com/integrations/v1/apps" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

---

### 3.2 Configure API Rate Limiting Awareness

**Profile Level:** L1 (Baseline)

#### Description
Design integrations with HubSpot's rate limits in mind.

#### Rate Limits

| App Type | Rate Limit |
|----------|-----------|
| Private Apps | 100 requests / 10 seconds |
| OAuth Apps | 100 requests / 10 seconds per portal |
| Burst | 150 requests / 10 seconds |

#### Monitoring
```python
# Monitor rate limit headers
response = requests.get(url, headers=headers)
remaining = response.headers.get('X-HubSpot-RateLimit-Remaining')
daily_remaining = response.headers.get('X-HubSpot-RateLimit-Daily-Remaining')
```

---

## 4. Data Security

### 4.1 Configure GDPR & Privacy Settings

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SI-12

#### Description
Enable GDPR compliance features for data privacy.

#### ClickOps Implementation

**Step 1: Enable GDPR Tools**
1. Navigate to: **Settings → Privacy & Consent → Data Privacy**
2. Enable:
   - **Require legal basis for contacts:** Yes
   - **Track consent history:** Yes

**Step 2: Configure Data Retention**
1. Navigate to: **Settings → Privacy & Consent → Data Retention**
2. Configure retention policies:
   - Contact retention period
   - Activity log retention
   - Deletion workflows

---

### 4.2 Export and Data Access Controls

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-3

#### Description
Control bulk data export capabilities.

#### ClickOps Implementation

**Step 1: Restrict Export Permissions**
1. Navigate to: **Permission Sets**
2. For non-admin users:
   - Disable: **Export contacts**
   - Disable: **Export reports**

**Step 2: Monitor Exports**
1. Review activity logs for export events
2. Alert on bulk exports

---

## 5. Monitoring & Detection

### 5.1 Enable Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### Description
Monitor HubSpot activity through audit logs.

#### ClickOps Implementation (Enterprise)

**Step 1: Access Audit Logs**
1. Navigate to: **Settings → Account Management → Security → Security Activity**
2. Review:
   - Login activity
   - Security setting changes
   - User modifications

**Step 2: Export to SIEM**
1. Use HubSpot API to export audit events
2. Configure scheduled export

#### Detection Queries

```sql
-- Detect bulk contact access
SELECT user_id, COUNT(*) as view_count
FROM hubspot_activity_log
WHERE action = 'contact.view'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_id
HAVING COUNT(*) > 100;

-- Detect API key creation
SELECT *
FROM hubspot_activity_log
WHERE action = 'private_app.created'
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect permission changes
SELECT *
FROM hubspot_activity_log
WHERE action LIKE '%permission%'
  AND timestamp > NOW() - INTERVAL '7 days';
```

---

## 6. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | HubSpot Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO enforcement | 1.1 |
| CC6.2 | Permission sets | 1.2 |
| CC6.7 | Data privacy | 4.1 |

---

## Appendix A: Edition Compatibility

| Control | Free | Starter | Professional | Enterprise |
|---------|------|---------|--------------|------------|
| MFA | ✅ | ✅ | ✅ | ✅ |
| SSO (SAML) | ❌ | ❌ | ❌ | ✅ |
| Permission Sets | Basic | Basic | ✅ | ✅ |
| Audit Logs | ❌ | ❌ | ✅ | ✅ |
| Data Retention | ❌ | ❌ | ❌ | ✅ |

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial HubSpot hardening guide | How to Harden Community |
