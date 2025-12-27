---
layout: guide
title: "Notion Hardening Guide"
vendor: "Notion"
slug: "notion"
tier: "4"
category: "Productivity"
description: "Workspace security for sharing defaults, connection controls, and audit logging"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

Notion serves as a collaborative workspace containing documentation, wikis, databases, and project management. Public API, OAuth integrations, and public page sharing create data exposure risks. Compromised access exposes internal documentation, product roadmaps, and sensitive business processes.

### Intended Audience
- Security engineers managing collaboration tools
- Notion workspace administrators
- GRC professionals assessing documentation security
- Third-party risk managers evaluating productivity integrations

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
1. Navigate to: **Settings → Security & identity → SAML single sign-on**
2. Configure SAML IdP
3. Enable: **Enforce SAML**

**Step 2: Enable 2FA (Non-SSO)**
1. Navigate to: **Settings → My settings → Password & security**
2. Enable: **Two-step verification**

---

### 1.2 Workspace Access Controls

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Configure Member Roles**

| Role | Permissions |
|------|---------|----------|---------|--------|----|
| Workspace Owner | Full admin access |
| Admin | Manage settings/members |
| Member | Full content access |
| Guest | Specific pages only |

**Step 2: Configure Teamspace Permissions**
1. Create teamspaces for departments
2. Set default access levels
3. Restrict sensitive content

---

## 2. Sharing & Permissions

### 2.1 Configure Sharing Defaults

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-21

#### Description
Control sharing to prevent unintended data exposure.

#### Rationale
**Attack Scenario:** Accidentally public pages indexed by search engines; internal documentation exposed to competitors or attackers.

#### ClickOps Implementation

**Step 1: Disable Public Sharing**
1. Navigate to: **Settings → Security & identity → Security**
2. Disable: **Allow members to share pages publicly**
3. Review existing public pages

**Step 2: Configure Guest Access**
1. Navigate to: **Settings → Security & identity → Security**
2. Configure: **Guest sharing settings**
3. Limit guest invitations

---

### 2.2 External Collaboration Security

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-21

#### ClickOps Implementation

**Step 1: Domain Restrictions**
1. Configure allowed email domains
2. Restrict guest domains
3. Audit external collaborators

**Step 2: Link Sharing Controls**
1. Disable anonymous link access
2. Require authentication
3. Set link expiration

---

## 3. Integration Security

### 3.1 Manage Connections

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### ClickOps Implementation

**Step 1: Audit Integrations**
1. Navigate to: **Settings → Connections**
2. Review all connected apps
3. Remove unused integrations

**Step 2: Restrict Integration Installation**
1. Navigate to: **Settings → Security & identity → Security**
2. Configure: **Connection settings**
3. Require admin approval

---

### 3.2 API Token Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Implementation

**Step 1: Manage Internal Integrations**
1. Navigate to: **Settings → Connections → Develop or manage integrations**
2. Audit integration permissions
3. Limit content access scope

**Step 2: Token Best Practices**
1. Use internal integrations (not personal tokens)
2. Limit to specific pages/databases
3. Rotate tokens periodically

---

## 4. Monitoring & Detection

### 4.1 Audit Log (Enterprise)

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Access Audit Log**
1. Navigate to: **Settings → Security & identity → Audit log**
2. Review activity events
3. Export for SIEM integration

#### Detection Focus

```sql
-- Detect bulk exports
SELECT user_email, page_count
FROM notion_audit_log
WHERE action = 'export_workspace'
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect public page creation
SELECT user_email, page_title, visibility
FROM notion_audit_log
WHERE action = 'share_page_public'
  AND timestamp > NOW() - INTERVAL '7 days';
```

---

## Appendix A: Edition Compatibility

| Control | Plus | Business | Enterprise |
|---------|------|----------|------------|
| SAML SSO | ❌ | ❌ | ✅ |
| SCIM | ❌ | ❌ | ✅ |
| Audit Log | ❌ | ❌ | ✅ |
| Guest Restrictions | ✅ | ✅ | ✅ |

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial Notion hardening guide | Claude Code (Opus 4.5) |
