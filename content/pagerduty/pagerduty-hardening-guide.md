# PagerDuty Hardening Guide

**Version:** 1.0
**Last Updated:** 2025-12-14
**Product Editions Covered:** PagerDuty (Professional, Business, Digital Operations)
**Authors:** How to Harden Community

---

## Overview

PagerDuty orchestrates incident response with integrations across monitoring, ticketing, and communication tools. REST API access, webhooks, and 700+ integrations create extensive attack surface. Compromised access reveals incident patterns, on-call schedules, and can suppress or manipulate alerts during active attacks.

### Intended Audience
- Security engineers managing incident response
- SRE/DevOps administrators
- GRC professionals assessing operations security
- Third-party risk managers evaluating alerting integrations

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API & Integration Security](#2-api--integration-security)
3. [Incident Security](#3-incident-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Account Settings → Single Sign-On**
2. Configure SAML IdP
3. Enable: **Require SSO**

**Step 2: Configure User Provisioning**
1. Enable SCIM provisioning
2. Configure JIT provisioning
3. Disable password authentication

---

### 1.2 Implement Role-Based Access

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define Roles**
| Role | Permissions |
|------|-------------|
| Account Owner | Full access (1 user) |
| Admin | User/team management |
| Manager | Team configuration |
| Responder | Incident response |
| Observer | Read-only |

**Step 2: Configure Team Permissions**
1. Navigate to: **People → Teams**
2. Configure team-specific permissions
3. Limit cross-team visibility

---

## 2. API & Integration Security

### 2.1 Secure API Keys

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Manage PagerDuty API keys securely.

#### Rationale
**Attack Scenario:** Compromised API key suppresses alerts during attack; on-call schedule manipulation delays incident response.

#### ClickOps Implementation

**Step 1: Audit API Keys**
1. Navigate to: **Integrations → API Access Keys**
2. Review all keys
3. Remove unused keys

**Step 2: Create Scoped Keys**
1. Use read-only keys where possible
2. Create service-specific keys
3. Document key purposes

---

### 2.2 Integration Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### ClickOps Implementation

**Step 1: Review Integrations**
1. Navigate to: **Services → Service Directory**
2. Audit all service integrations
3. Remove unused integrations

**Step 2: Secure Webhook Endpoints**
1. Use HTTPS only
2. Validate webhook signatures
3. Implement IP allowlisting

---

## 3. Incident Security

### 3.1 Protect Incident Data

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### ClickOps Implementation

**Step 1: Configure Incident Visibility**
1. Limit incident details in notifications
2. Avoid sensitive data in alerts
3. Use secure channels for details

**Step 2: Secure Runbooks**
1. Protect runbook credentials
2. Use secret references (not plaintext)
3. Audit runbook access

---

### 3.2 Event Rules Security

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SI-4

#### Implementation

**Step 1: Protect Event Rules**
1. Navigate to: **Automation → Event Rules**
2. Audit suppression rules
3. Alert on rule modifications

**Step 2: Monitor Rule Changes**
1. Track who modifies rules
2. Require approval for suppression rules
3. Audit rule effectiveness

---

## 4. Monitoring & Detection

### 4.1 Audit Logs

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Access Audit Records**
1. Navigate to: **Analytics → Audit Records**
2. Review login events
3. Monitor configuration changes

#### Detection Focus

```sql
-- Detect alert suppression manipulation
SELECT user_email, action, target
FROM pagerduty_audit_log
WHERE action LIKE '%suppress%'
  OR action LIKE '%rule%'
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect unusual API activity
SELECT api_key, endpoint, COUNT(*) as requests
FROM api_log
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY api_key, endpoint
HAVING COUNT(*) > 500;
```

---

## Appendix A: Edition Compatibility

| Control | Professional | Business | Digital Operations |
|---------|--------------|----------|-------------------|
| SAML SSO | ✅ | ✅ | ✅ |
| SCIM | ❌ | ✅ | ✅ |
| Audit Records | Limited | ✅ | ✅ |
| Custom Roles | ❌ | ✅ | ✅ |

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial PagerDuty hardening guide | How to Harden Community |
