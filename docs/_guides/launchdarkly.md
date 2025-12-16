---
layout: guide
title: "LaunchDarkly Hardening Guide"
vendor: "LaunchDarkly"
slug: "launchdarkly"
tier: "4"
category: "DevOps"
description: "Feature flag security for SDK keys, environment access, and approval workflows"
last_updated: "2025-12-14"
---


## Overview

LaunchDarkly manages feature flags controlling application behavior across environments. REST API, SDK keys, and webhook integrations control feature rollouts. Compromised access enables feature manipulation, environment privilege escalation, or extraction of targeting rules revealing business logic.

### Intended Audience
- Security engineers managing feature flag systems
- DevOps/Platform administrators
- GRC professionals assessing release management
- Third-party risk managers evaluating deployment integrations

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [SDK & API Security](#2-sdk--api-security)
3. [Environment Security](#3-environment-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Account settings → Security → SAML**
2. Configure SAML IdP
3. Enable: **Require SSO**

**Step 2: Configure SCIM**
1. Enable SCIM provisioning
2. Configure user/group sync
3. Set deprovisioning behavior

---

### 1.2 Role-Based Access Control

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define Custom Roles**

| Role | Permissions |
|------|-------------|
| Admin | Full access |
| Writer | Create/modify flags |
| Reader | View only |
| No access | Blocked |

**Step 2: Configure Project/Environment Access**
1. Navigate to: **Account settings → Roles**
2. Create environment-specific roles
3. Apply least privilege

---

## 2. SDK & API Security

### 2.1 Secure SDK Keys

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Protect LaunchDarkly SDK keys.

#### Rationale
**Attack Scenario:** Exposed SDK key enables flag enumeration; mobile SDK key in client bundle allows targeting rule extraction.

#### Implementation

**SDK Key Types:**

| Key Type | Exposure Risk | Use Case |
|----------|---------------|----------|
| SDK Key | Server-side only | Backend services |
| Mobile Key | Client-side safe | Mobile apps |
| Client-side ID | Client-side safe | Browser apps |

**Step 1: Rotate Keys**
1. Navigate to: **Project settings → Environments**
2. Reset SDK keys periodically
3. Update applications

---

### 2.2 API Token Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### ClickOps Implementation

**Step 1: Audit Access Tokens**
1. Navigate to: **Account settings → Authorization → Access tokens**
2. Review all tokens
3. Remove unused tokens

**Step 2: Create Scoped Tokens**
1. Create tokens with custom roles
2. Limit to specific projects/environments
3. Set expiration dates

---

## 3. Environment Security

### 3.1 Environment Segmentation

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-3

#### ClickOps Implementation

**Step 1: Configure Environment Settings**
1. Navigate to: **Project settings → Environments**
2. Configure:
   - Require comments for changes
   - Require review for production
   - Enable change history

**Step 2: Approval Workflows (Enterprise)**
1. Configure approval requirements
2. Set minimum approvers
3. Define bypass conditions

---

### 3.2 Flag Security

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CM-7

#### Implementation

**Step 1: Tag Sensitive Flags**
1. Tag flags controlling security features
2. Apply additional review requirements
3. Audit changes

**Step 2: Targeting Rule Protection**
1. Limit who can view targeting rules
2. Audit rule changes
3. Monitor for enumeration

---

## 4. Monitoring & Detection

### 4.1 Audit Log

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Access Audit Log**
1. Navigate to: **Account settings → Audit log**
2. Review changes
3. Configure SIEM export

#### Detection Focus

```sql
-- Detect production flag changes
SELECT user_email, flag_key, action
FROM launchdarkly_audit_log
WHERE environment = 'production'
  AND action IN ('updateFlag', 'toggleFlag')
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect bulk flag modifications
SELECT user_email, COUNT(*) as changes
FROM launchdarkly_audit_log
WHERE action LIKE '%Flag%'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_email
HAVING COUNT(*) > 10;
```

---

## Appendix A: Edition Compatibility

| Control | Pro | Enterprise |
|---------|-----|------------|
| SAML SSO | ✅ | ✅ |
| SCIM | ❌ | ✅ |
| Custom Roles | ✅ | ✅ |
| Approval Workflows | ❌ | ✅ |

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial LaunchDarkly hardening guide | How to Harden Community |
