---
layout: guide
title: "Looker Hardening Guide"
vendor: "Looker"
slug: "looker"
tier: "5"
category: "Analytics"
description: "Google BI security for model access, embed secrets, and database connections"
last_updated: "2025-12-14"
---


## Overview

Looker (Google Cloud) provides business intelligence with LookML modeling and data exploration. REST API, embed secrets, and database connections access enterprise data warehouses. Compromised access exposes business metrics, customer analytics, and data warehouse credentials.

### Intended Audience
- Security engineers managing BI platforms
- Looker administrators
- GRC professionals assessing analytics security
- Third-party risk managers evaluating Google Cloud integrations

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Content Security](#2-content-security)
3. [Database Connection Security](#3-database-connection-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Admin → Authentication → SAML**
2. Configure SAML IdP
3. Enable: **Bypass login page**

**Step 2: Google OAuth**
1. Navigate to: **Admin → Authentication → Google**
2. Enable Google OAuth
3. Configure domain restrictions

---

### 1.2 Role-Based Access

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define Roles**

| Role | Permissions |
|------|-------------|
| Admin | Full access |
| Developer | Model development |
| User | Explore and save |
| Viewer | View only |

**Step 2: Configure Model Sets**
1. Navigate to: **Admin → Roles**
2. Create custom roles
3. Assign model/permission sets

---

## 2. Content Security

### 2.1 Configure Folder Permissions

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3

#### Description
Control content access through folder hierarchy.

#### Rationale
**Attack Scenario:** Open folder permissions expose executive dashboards; shared folder access leaks competitive metrics.

#### ClickOps Implementation

**Step 1: Folder Structure**
```
Content Organization:
├── Shared (company-wide)
├── Group Folders (team-specific)
│   ├── Finance (restricted)
│   └── Marketing (team access)
└── Personal Folders (individual)
```

**Step 2: Configure Access**
1. Navigate to: **Browse → Folder → Manage Access**
2. Set appropriate permissions
3. Limit "View" access default

---

### 2.2 Embed Security

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-21

#### Implementation

**Step 1: Manage Embed Secrets**
1. Navigate to: **Admin → Platform → Embed**
2. Rotate embed secrets
3. Configure embed domain allowlist

**Step 2: SSO Embed**
1. Use signed embed URLs
2. Set short session lengths
3. Implement user attributes

---

## 3. Database Connection Security

### 3.1 Secure Database Connections

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### ClickOps Implementation

**Step 1: Connection Security**
1. Navigate to: **Admin → Database → Connections**
2. Use SSL/TLS connections
3. Configure service account with read-only

**Step 2: PDT Credentials**
1. Limit PDT write permissions
2. Use separate credentials
3. Restrict temp schema access

---

### 3.2 Query Cost Controls

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CM-7

#### Implementation

**Step 1: Configure Limits**
1. Navigate to: **Admin → General → Query**
2. Set query timeout
3. Configure row limits

---

## 4. Monitoring & Detection

### 4.1 System Activity

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Access System Activity**
1. Navigate to: **Admin → System Activity**
2. Review dashboards:
   - User Activity
   - Query Performance
   - Content Usage

#### Detection Focus

```sql
-- Detect bulk query activity
SELECT user_id, COUNT(*) as query_count
FROM history
WHERE created_at > CURRENT_TIMESTAMP - INTERVAL '1 hour'
GROUP BY user_id
HAVING COUNT(*) > 100;

-- Detect unusual data access
SELECT user_id, look_id, dashboard_id
FROM history
WHERE source = 'api'
  AND created_at > CURRENT_TIMESTAMP - INTERVAL '24 hours';
```

---

## Appendix A: Edition Compatibility

| Control | Standard | Enterprise | Embed |
|---------|----------|------------|-------|
| SAML SSO | ✅ | ✅ | ✅ |
| Custom Roles | ✅ | ✅ | ✅ |
| System Activity | ✅ | ✅ | ✅ |
| SSO Embed | ❌ | ❌ | ✅ |

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial Looker hardening guide | How to Harden Community |
