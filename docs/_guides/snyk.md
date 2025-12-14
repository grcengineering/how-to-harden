---
layout: guide
title: "Snyk Hardening Guide"
vendor: "Snyk"
slug: "snyk"
tier: "5"
category: "Security"
description: "AppSec platform security for service accounts, SCM integrations, and Broker configs"
last_updated: "2025-12-14"
---


## Overview

Snyk provides developer security for vulnerability scanning across code, dependencies, containers, and IaC. REST API, CLI tokens, and SCM integrations access source code repositories and vulnerability data. Compromised access exposes vulnerability findings and potentially enables code access through integrations.

### Intended Audience
- Security engineers managing AppSec tools
- DevSecOps administrators
- GRC professionals assessing development security
- Third-party risk managers evaluating security scanning tools

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Integration Security](#2-integration-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### ClickOps Implementation

**Step 1: Configure SAML SSO (Business/Enterprise)**
1. Navigate to: **Settings → SSO**
2. Configure SAML IdP
3. Enable: **Require SSO**

**Step 2: Enable MFA (Non-SSO)**
1. Configure MFA through account settings
2. Enforce for all users

---

### 1.2 Role-Based Access

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define Roles**
| Role | Permissions |
|------|-------------|
| Group Admin | Full organization access |
| Org Admin | Organization management |
| Org Collaborator | View and test projects |
| Org Custom | Custom permissions |

**Step 2: Configure Organization Access**
1. Navigate to: **Settings → Members**
2. Assign appropriate roles
3. Use least privilege

---

## 2. Integration Security

### 2.1 Secure Service Account Tokens

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Manage Snyk service account tokens securely.

#### Rationale
**Attack Scenario:** Exposed API token enables vulnerability data export; attackers gain insight into exploitable vulnerabilities before patches.

#### ClickOps Implementation

**Step 1: Audit Service Accounts**
1. Navigate to: **Settings → Service accounts**
2. Review all service accounts
3. Remove unused accounts

**Step 2: Token Best Practices**
1. Create tokens per CI/CD pipeline
2. Set token expiration
3. Use least privilege roles

---

### 2.2 SCM Integration Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### ClickOps Implementation

**Step 1: Review Integrations**
1. Navigate to: **Settings → Integrations**
2. Review SCM connections
3. Limit repository access

**Step 2: Broker Configuration (Enterprise)**
1. Use Snyk Broker for private repos
2. Configure accept.json filters
3. Limit exposed endpoints

---

## 3. Data Security

### 3.1 Project Visibility

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-21

#### ClickOps Implementation

**Step 1: Configure Project Settings**
1. Set appropriate project visibility
2. Limit who can view vulnerability details
3. Control issue sharing

**Step 2: Report Access**
1. Limit report generation
2. Control export permissions
3. Audit report access

---

### 3.2 Ignore Policy

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CM-7

#### Implementation

**Step 1: Ignore Workflow**
1. Require reason for ignores
2. Set ignore expiration
3. Audit ignored vulnerabilities

---

## 4. Monitoring & Detection

### 4.1 Audit Logs (Enterprise)

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Settings → Audit logs**
2. Review user activities
3. Export for SIEM

#### Detection Focus

```sql
-- Detect bulk vulnerability exports
SELECT user_email, action, project_count
FROM snyk_audit_log
WHERE action = 'export'
  AND timestamp > NOW() - INTERVAL '24 hours'
GROUP BY user_email
HAVING project_count > 10;

-- Detect service account creation
SELECT admin_email, service_account_name, created_at
FROM snyk_audit_log
WHERE action = 'service_account.create'
  AND timestamp > NOW() - INTERVAL '7 days';
```

---

## Appendix A: Edition Compatibility

| Control | Free | Team | Business | Enterprise |
|---------|------|------|----------|------------|
| SAML SSO | ❌ | ❌ | ✅ | ✅ |
| SCIM | ❌ | ❌ | ❌ | ✅ |
| Audit Logs | ❌ | ❌ | ❌ | ✅ |
| Service Accounts | ❌ | ❌ | ✅ | ✅ |

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial Snyk hardening guide | How to Harden Community |
