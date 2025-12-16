---
layout: guide
title: "Smartsheet Hardening Guide"
vendor: "Smartsheet"
slug: "smartsheet"
tier: "5"
category: "Productivity"
description: "Work management security for sharing defaults, connector controls, and activity logging"
last_updated: "2025-12-14"
---


## Overview

Smartsheet is a collaborative work management platform for projects, workflows, and data collection. REST API, OAuth apps, and connectors access project data and business processes. Compromised access exposes project timelines, resource allocation, and potentially sensitive form submissions.

### Intended Audience
- Security engineers managing work management platforms
- Smartsheet administrators
- GRC professionals assessing project management security
- Third-party risk managers evaluating workflow integrations

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Sharing & Permissions](#2-sharing--permissions)
3. [Integration Security](#3-integration-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### ClickOps Implementation

**Step 1: Configure SAML SSO (Enterprise)**
1. Navigate to: **Admin Center → Security Controls → SAML**
2. Configure SAML IdP
3. Enable: **Require SAML**

**Step 2: Enable MFA**
1. Configure MFA through IdP
2. Or enable Smartsheet MFA
3. Require for all users

---

### 1.2 User Types and Roles

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define User Types**

| Type | Permissions |
|------|-------------|
| System Admin | Full admin access |
| Group Admin | Manage specific groups |
| Licensed User | Create and share |
| Resource Viewer | View resources only |

**Step 2: Configure Groups**
1. Navigate to: **Admin Center → User Management → Groups**
2. Create department groups
3. Assign permissions by group

---

## 2. Sharing & Permissions

### 2.1 Configure Sharing Defaults

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-21

#### Description
Control sheet and workspace sharing.

#### Rationale
**Attack Scenario:** Public links to project sheets expose sensitive timelines; form submissions accessible to unauthorized users.

#### ClickOps Implementation

**Step 1: Global Sharing Settings**
1. Navigate to: **Admin Center → Security Controls**
2. Configure:
   - **Published item restrictions**
   - **External sharing policies**
   - **Default sharing permissions**

**Step 2: Workspace Controls**
1. Create workspaces per team
2. Set workspace sharing defaults
3. Restrict external sharing

---

### 2.2 Form Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-21

#### ClickOps Implementation

**Step 1: Form Access Controls**
1. Limit who can view form submissions
2. Restrict form sharing
3. Configure submission notifications

---

## 3. Integration Security

### 3.1 Connector Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### ClickOps Implementation

**Step 1: Review Connectors**
1. Navigate to: **Admin Center → Integrations**
2. Review all connected apps
3. Remove unused connectors

**Step 2: API Access**
1. Navigate to: **Personal Settings → API Access**
2. Audit access tokens
3. Revoke unused tokens

---

### 3.2 Premium App Security

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CM-7

#### ClickOps Implementation

**Step 1: Control Premium Apps**
1. Navigate to: **Admin Center → Premium Apps**
2. Enable/disable by app
3. Configure access permissions

---

## 4. Monitoring & Detection

### 4.1 Activity Log (Enterprise)

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Access Activity Log**
1. Navigate to: **Admin Center → Security Controls → Activity Log**
2. Review user activities
3. Export for SIEM integration

#### Detection Focus

```sql
-- Detect bulk sharing changes
SELECT user_email, sheet_name, action
FROM smartsheet_activity
WHERE action LIKE '%share%'
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect unusual export activity
SELECT user_email, export_count
FROM smartsheet_activity
WHERE action = 'export'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_email
HAVING export_count > 20;
```

---

## Appendix A: Edition Compatibility

| Control | Pro | Business | Enterprise |
|---------|-----|----------|------------|
| SAML SSO | ❌ | ❌ | ✅ |
| Activity Log | ❌ | ❌ | ✅ |
| Group Admin | ❌ | ❌ | ✅ |
| External Sharing Controls | ❌ | ✅ | ✅ |

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial Smartsheet hardening guide | How to Harden Community |
