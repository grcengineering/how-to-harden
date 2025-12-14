---
layout: guide
title: "Gusto Hardening Guide"
vendor: "Gusto"
slug: "gusto"
tier: "5"
category: "Payroll"
description: "Payroll security for admin controls, partner integrations, and bank account protection"
last_updated: "2025-12-14"
---


## Overview

Gusto is a payroll and benefits platform for small-medium businesses. REST API and partner integrations access employee SSN, bank accounts, compensation, and tax information. Compromised access enables payroll fraud and exposes highly sensitive PII.

### Intended Audience
- Security engineers managing payroll systems
- Gusto administrators
- GRC professionals assessing payroll compliance
- Third-party risk managers evaluating HR integrations

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API Security](#2-api-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### ClickOps Implementation

**Step 1: Enable 2-Step Verification**
1. Navigate to: **Settings → Security**
2. Enable: **Require 2-step verification**
3. Configure for all admins

**Step 2: Configure Login Security**
1. Enable login notifications
2. Configure trusted devices
3. Review active sessions

---

### 1.2 Admin Access Controls

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define Admin Roles**
| Role | Permissions |
|------|-------------|
| Primary Admin | Full access |
| Full Admin | Most admin functions |
| Limited Admin | Specific access |
| No Access | Employee only |

**Step 2: Configure Admin Permissions**
1. Navigate to: **Team → Admins**
2. Limit full admin count
3. Use limited admin for specific tasks

---

## 2. API Security

### 2.1 Partner Integration Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Manage Gusto partner integrations securely.

#### Rationale
**Attack Scenario:** Compromised API partner access enables bank account modification; payroll fraud redirects employee payments.

#### ClickOps Implementation

**Step 1: Review Connected Apps**
1. Navigate to: **Settings → Connected Apps**
2. Review all partner integrations
3. Remove unused connections

**Step 2: Integration Best Practices**
1. Limit integration permissions
2. Audit data access
3. Review quarterly

---

## 3. Data Security

### 3.1 Protect Payroll Data

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### ClickOps Implementation

**Step 1: Limit Data Access**
1. Restrict who can view payroll
2. Limit SSN visibility
3. Protect bank account data

**Step 2: Approval Workflows**
1. Require approval for payroll changes
2. Enable bank account change verification
3. Configure payment notifications

---

### 3.2 Document Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### ClickOps Implementation

**Step 1: Document Access**
1. Limit who can view tax documents
2. Restrict W-2/1099 access
3. Configure download permissions

---

## 4. Monitoring & Detection

### 4.1 Activity Monitoring

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Review Activity**
1. Monitor admin logins
2. Track payroll changes
3. Alert on bank account updates

#### Detection Focus

```sql
-- Detect bank account changes
SELECT admin_email, employee_name, change_type
FROM gusto_activity
WHERE action = 'bank_account_change'
  AND timestamp > NOW() - INTERVAL '7 days';

-- Detect unusual admin activity
SELECT admin_email, action, COUNT(*) as actions
FROM gusto_activity
WHERE timestamp > NOW() - INTERVAL '24 hours'
GROUP BY admin_email, action
HAVING COUNT(*) > 50;
```

---

## Appendix A: Edition Compatibility

| Control | Simple | Plus | Premium |
|---------|--------|------|---------|
| 2-Step Verification | ✅ | ✅ | ✅ |
| Admin Roles | ✅ | ✅ | ✅ |
| API Access | Limited | ✅ | ✅ |
| Priority Support | ❌ | ❌ | ✅ |

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial Gusto hardening guide | How to Harden Community |
