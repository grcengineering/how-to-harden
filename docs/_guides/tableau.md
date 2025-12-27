---
layout: guide
title: "Tableau Hardening Guide"
vendor: "Tableau"
slug: "tableau"
tier: "4"
category: "Analytics"
description: "BI platform security for site roles, data source credentials, and embed controls"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

Tableau provides business intelligence and data visualization with connections to enterprise data sources. REST API, embedded credentials in workbooks, and data source connections access sensitive business data. Compromised access exposes executive dashboards, financial reports, and aggregated business intelligence.

### Intended Audience
- Security engineers managing BI platforms
- Tableau administrators
- GRC professionals assessing data governance
- Third-party risk managers evaluating analytics integrations

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Data Source Security](#2-data-source-security)
3. [Content Security](#3-content-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### ClickOps Implementation

**Step 1: Configure SAML SSO (Tableau Cloud)**
1. Navigate to: **Settings → Authentication**
2. Configure SAML IdP
3. Enable: **SAML single sign-on**

**Step 2: Enable MFA**
1. Configure MFA through IdP
2. Enforce for all users
3. Configure session timeout

---

### 1.2 Implement Site Roles

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define Site Roles**

| Role | Permissions |
|------|---------|----------|---------|--------|----|
| Site Administrator Creator | Full site access |
| Site Administrator Explorer | Admin without publish |
| Creator | Create/publish content |
| Explorer | View and interact |
| Viewer | View only |

**Step 2: Configure Project Permissions**
1. Navigate to: **Explore → Projects**
2. Configure project-level permissions
3. Use permission templates

---

## 2. Data Source Security

### 2.1 Secure Data Source Connections

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Protect data source credentials and connections.

#### Rationale
**Attack Scenario:** Embedded database credentials extracted from workbooks; direct database access bypasses application-level controls.

#### ClickOps Implementation

**Step 1: Use Service Accounts**
1. Create dedicated service accounts
2. Limit database permissions
3. Use published data sources

**Step 2: Credential Management**
1. Avoid embedding passwords in workbooks
2. Use OAuth where available
3. Prompt users for credentials

---

### 2.2 Row-Level Security

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-3

#### Implementation

**Step 1: Implement User Filters**
```
# User filter calculation
[Region] = USERNAME()

# Or use groups
ISMEMBEROF('Finance')
```

**Step 2: Configure Data Source Filters**
1. Create user-based filters
2. Test with different users
3. Document filter logic

---

## 3. Content Security

### 3.1 Workbook Protection

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### ClickOps Implementation

**Step 1: Configure Permissions**
1. Set project-level defaults
2. Lock permissions to project
3. Remove "All Users" permissions

**Step 2: Extract Security**
1. Configure extract refresh security
2. Limit extract downloads
3. Encrypt extracts at rest

---

### 3.2 Embedding Security

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-21

#### Implementation

**Step 1: Connected Apps (Tableau Cloud)**
1. Navigate to: **Settings → Connected Apps**
2. Configure allowed domains
3. Set session timeout

**Step 2: Trusted Authentication**
1. Configure trusted hosts
2. Limit ticket lifespan
3. Monitor trusted authentication usage

---

## 4. Monitoring & Detection

### 4.1 Enable Admin Views

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Access Admin Views**
1. Navigate to: **Status → Traffic to Views**
2. Monitor data source access
3. Review user activity

#### Detection Focus

```sql
-- Detect bulk data downloads
SELECT user_name, workbook_name, download_count
FROM admin_insights
WHERE action = 'Download'
  AND timestamp > NOW() - INTERVAL '24 hours'
GROUP BY user_name, workbook_name
HAVING download_count > 10;

-- Detect unusual access patterns
SELECT user_name, site_role, view_count
FROM traffic_to_views
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_name, site_role
HAVING view_count > 100;
```

---

## Appendix A: Edition Compatibility

| Control | Tableau Cloud | Tableau Server |
|---------|---------------|----------------|
| SAML SSO | ✅ | ✅ |
| Site Roles | ✅ | ✅ |
| Row-Level Security | ✅ | ✅ |
| Admin Views | ✅ | ✅ |

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial Tableau hardening guide | Claude Code (Opus 4.5) |
