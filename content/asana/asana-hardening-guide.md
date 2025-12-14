# Asana Hardening Guide

**Version:** 1.0
**Last Updated:** 2025-12-14
**Product Editions Covered:** Asana (Premium, Business, Enterprise)
**Authors:** How to Harden Community

---

## Overview

Asana manages project and task management with team collaboration features. REST API, OAuth apps, and integrations access project data, task assignments, and workflow automation. Compromised access exposes project timelines, resource allocation, and strategic initiatives.

### Intended Audience
- Security engineers managing productivity tools
- Asana administrators
- GRC professionals assessing project management security
- Third-party risk managers evaluating workflow integrations

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Workspace & Project Security](#2-workspace--project-security)
3. [Integration Security](#3-integration-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### ClickOps Implementation

**Step 1: Configure SAML SSO (Enterprise)**
1. Navigate to: **Admin Console → Security → Authentication**
2. Configure SAML IdP
3. Enable: **Require SAML**

**Step 2: Enable 2FA (Non-SSO)**
1. Navigate to: **Admin Console → Security**
2. Enable: **Require 2FA**

---

### 1.2 Division-Based Access

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Configure Divisions (Enterprise)**
1. Navigate to: **Admin Console → Divisions**
2. Create organizational divisions
3. Configure cross-division access

**Step 2: Team Permissions**
1. Create teams for departments
2. Set project permissions by team
3. Limit cross-team visibility

---

## 2. Workspace & Project Security

### 2.1 Configure Sharing Defaults

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-21

#### Description
Control project and workspace sharing.

#### Rationale
**Attack Scenario:** Guest access to sensitive projects exposes strategic initiatives; public links to projects leak timeline information.

#### ClickOps Implementation

**Step 1: Guest Access Controls**
1. Navigate to: **Admin Console → Security → Guest settings**
2. Configure:
   - Domain restrictions for guests
   - Guest invitation policies
   - Guest access expiration

**Step 2: Project Defaults**
1. Set default project visibility
2. Restrict public project creation
3. Configure comment-only access

---

### 2.2 Data Controls

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-28

#### ClickOps Implementation

**Step 1: Configure Export Restrictions**
1. Navigate to: **Admin Console → Security**
2. Limit export capabilities
3. Audit bulk exports

---

## 3. Integration Security

### 3.1 Manage Apps

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### ClickOps Implementation

**Step 1: Audit Connected Apps**
1. Navigate to: **Admin Console → Apps**
2. Review all connected apps
3. Remove unused apps

**Step 2: App Installation Policy**
1. Configure: **App approval settings**
2. Require admin approval
3. Review OAuth scopes

---

### 3.2 Personal Access Tokens

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Implementation

**Step 1: Token Management**
1. Navigate to: **My Profile Settings → Apps → Developer apps**
2. Audit personal access tokens
3. Revoke unused tokens

**Step 2: Service Account Tokens**
1. Create dedicated service accounts
2. Limit token permissions
3. Document integrations

---

## 4. Monitoring & Detection

### 4.1 Admin Audit Log

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Admin Console → Settings → Admin audit log**
2. Review activity events
3. Export for SIEM

#### Detection Focus

```sql
-- Detect bulk project access
SELECT user_email, project_count
FROM asana_audit_log
WHERE action = 'project_view'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_email
HAVING project_count > 50;

-- Detect guest additions
SELECT admin_email, guest_email, project_name
FROM asana_audit_log
WHERE action = 'guest_added'
  AND timestamp > NOW() - INTERVAL '7 days';
```

---

## Appendix A: Edition Compatibility

| Control | Premium | Business | Enterprise |
|---------|---------|----------|------------|
| SAML SSO | ❌ | ❌ | ✅ |
| SCIM | ❌ | ❌ | ✅ |
| Audit Logs | ❌ | ❌ | ✅ |
| Divisions | ❌ | ❌ | ✅ |

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial Asana hardening guide | How to Harden Community |
