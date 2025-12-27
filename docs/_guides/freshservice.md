---
layout: guide
title: "Freshservice Hardening Guide"
vendor: "Freshservice"
slug: "freshservice"
tier: "5"
category: "ITSM"
description: "ITSM security for API tokens, CMDB access, and change management controls"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

Freshservice is an IT service management (ITSM) platform handling IT tickets, asset management, and change management. REST API, OAuth apps, and Freshworks Marketplace integrations access IT infrastructure data. Compromised access exposes asset inventory, configuration data, and potentially privileged access workflows.

### Intended Audience
- Security engineers managing ITSM platforms
- Freshservice administrators
- GRC professionals assessing IT service security
- Third-party risk managers evaluating ITSM integrations

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API Security](#2-api-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Admin → Security → Single sign-on**
2. Configure SAML IdP
3. Enable: **Login with SSO only**

**Step 2: Enable 2FA**
1. Navigate to: **Admin → Security**
2. Enable: **Two-factor authentication**
3. Require for all agents

---

### 1.2 Role-Based Access

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define Roles**

| Role | Permissions |
|------|---------|----------|---------|--------|----|
| Admin | Full access |
| SD Agent | Service desk functions |
| Asset Manager | CMDB access |
| Change Manager | Change management |
| Requester | Submit tickets only |

**Step 2: Configure Agent Roles**
1. Navigate to: **Admin → Agent Roles**
2. Create custom roles
3. Assign minimum permissions

---

## 2. API Security

### 2.1 Secure API Keys

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Manage Freshservice API keys securely.

#### Rationale
**Attack Scenario:** Compromised API key exports CMDB; asset inventory and configuration data enable targeted attacks on infrastructure.

#### ClickOps Implementation

**Step 1: Audit API Keys**
1. Navigate to: **Profile → API Key**
2. Each agent has unique key
3. Limit who needs API access

**Step 2: Key Management**
1. Regenerate keys when agents leave
2. Use dedicated integration accounts
3. Monitor API usage

---

### 2.2 OAuth App Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### ClickOps Implementation

**Step 1: Review Connected Apps**
1. Navigate to: **Admin → Apps → Installed Apps**
2. Review all apps
3. Remove unused integrations

---

## 3. Data Security

### 3.1 Protect Asset Data

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### ClickOps Implementation

**Step 1: Configure CMDB Access**
1. Navigate to: **Admin → Asset Management**
2. Limit CMDB visibility
3. Restrict sensitive asset types

**Step 2: Ticket Security**
1. Configure ticket visibility
2. Limit agent group access
3. Protect sensitive tickets

---

### 3.2 Change Management Security

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CM-3

#### ClickOps Implementation

**Step 1: Approval Workflows**
1. Navigate to: **Admin → Workflow Automator**
2. Require CAB approval
3. Configure emergency change process

---

## 4. Monitoring & Detection

### 4.1 Audit Logs

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Admin → Audit Logs**
2. Review agent activities
3. Monitor configuration changes

#### Detection Focus

```sql
-- Detect bulk asset exports
SELECT agent_email, export_type, record_count
FROM freshservice_audit
WHERE action = 'export'
  AND module = 'asset'
  AND record_count > 100;

-- Detect unusual API activity
SELECT api_key, endpoint, COUNT(*) as calls
FROM api_log
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY api_key, endpoint
HAVING COUNT(*) > 500;
```

---

## Appendix A: Edition Compatibility

| Control | Starter | Growth | Pro | Enterprise |
|---------|---------|--------|-----|------------|
| SAML SSO | ❌ | ✅ | ✅ | ✅ |
| Custom Roles | ❌ | ❌ | ✅ | ✅ |
| Audit Logs | ❌ | ❌ | ✅ | ✅ |
| IP Restrictions | ❌ | ❌ | ❌ | ✅ |

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial Freshservice hardening guide | Claude Code (Opus 4.5) |
