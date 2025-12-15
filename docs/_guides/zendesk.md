---
layout: guide
title: "Zendesk Hardening Guide"
vendor: "Zendesk"
slug: "zendesk"
tier: "4"
category: "Support"
description: "Support platform security for API tokens, app marketplace, and ticket redaction"
last_updated: "2025-12-14"
---


## Overview

Zendesk handles customer support data including tickets, chat transcripts, and customer PII. OAuth apps, webhooks, and Zendesk Marketplace integrations extend functionality but increase attack surface. API tokens enable bulk ticket export; compromised integrations access customer communication history.

### Intended Audience
- Security engineers managing support platforms
- Zendesk administrators
- GRC professionals assessing customer data compliance
- Third-party risk managers evaluating support integrations

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API & App Security](#2-api--app-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Admin Center → Account → Security → Single sign-on**
2. Configure SAML settings
3. Enable: **Require SSO**

**Step 2: Enable 2FA**
1. Navigate to: **Admin Center → Account → Security → Two-factor authentication**
2. Enable: **Require two-factor authentication**
3. Configure backup codes

---

### 1.2 Implement Role-Based Access

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define Custom Roles**
| Role | Permissions |
|------|-------------|
| Admin | Full access (limited users) |
| Team Lead | Manage team, view reports |
| Agent | Handle tickets only |
| Light Agent | Comment only (no ticket actions) |

**Step 2: Configure Role Permissions**
1. Navigate to: **Admin Center → People → Team → Roles**
2. Create custom roles
3. Assign minimum permissions

---

### 1.3 Configure IP Restrictions

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-6

#### ClickOps Implementation

**Step 1: Enable IP Restrictions**
1. Navigate to: **Admin Center → Account → Security → Advanced**
2. Configure: **IP restrictions**
3. Add allowed IP ranges

---

## 2. API & App Security

### 2.1 Secure API Token Management

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Manage Zendesk API tokens securely.

#### Rationale
**Attack Scenario:** Stolen API token enables bulk ticket export; customer PII and support history exfiltrated for social engineering.

#### ClickOps Implementation

**Step 1: Audit API Tokens**
1. Navigate to: **Admin Center → Apps and integrations → APIs → Zendesk API**
2. Review all active tokens
3. Remove unused tokens

**Step 2: Create Scoped Tokens**
1. Use OAuth apps for granular permissions
2. Set token expiration
3. Document token purposes

---

### 2.2 Marketplace App Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### ClickOps Implementation

**Step 1: Review Installed Apps**
1. Navigate to: **Admin Center → Apps and integrations → Apps → Zendesk Support apps**
2. Review all installed apps
3. Remove unused apps

**Step 2: Configure App Permissions**
1. Review OAuth scopes per app
2. Require admin approval for new apps
3. Audit app access regularly

---

## 3. Data Security

### 3.1 Configure Data Redaction

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### ClickOps Implementation

**Step 1: Enable Ticket Redaction**
1. Navigate to: **Admin Center → Account → Security → Advanced**
2. Configure: **Redaction**
3. Enable automatic credit card redaction

**Step 2: Configure Deletion Schedules**
1. Set up ticket archiving
2. Configure attachment deletion
3. Enable GDPR deletion workflows

---

### 3.2 Secure Attachments

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### ClickOps Implementation

**Step 1: Configure Attachment Settings**
1. Limit attachment file types
2. Set size limits
3. Enable malware scanning

**Step 2: Access Control**
1. Require authentication for attachments
2. Configure secure attachment URLs
3. Set expiration on attachment links

---

## 4. Monitoring & Detection

### 4.1 Enable Audit Logs

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Admin Center → Account → Audit logs**
2. Review authentication events
3. Monitor configuration changes

#### Detection Focus

```sql
-- Detect bulk ticket exports
SELECT user_email, action, COUNT(*) as exports
FROM zendesk_audit_log
WHERE action = 'ticket_export'
  AND timestamp > NOW() - INTERVAL '24 hours'
GROUP BY user_email, action
HAVING COUNT(*) > 10;

-- Detect API abuse
SELECT api_token, endpoint, COUNT(*) as requests
FROM api_log
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY api_token, endpoint
HAVING COUNT(*) > 1000;
```

---

## Appendix A: Edition Compatibility

| Control | Team | Growth | Professional | Enterprise |
|---------|------|--------|--------------|------------|
| SAML SSO | ❌ | ❌ | ✅ | ✅ |
| IP Restrictions | ❌ | ❌ | ✅ | ✅ |
| Audit Logs | ❌ | ❌ | ❌ | ✅ |
| Custom Roles | ❌ | ❌ | ❌ | ✅ |

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial Zendesk hardening guide | How to Harden Community |
