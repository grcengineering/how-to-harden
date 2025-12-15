---
layout: guide
title: "SailPoint Hardening Guide"
vendor: "SailPoint"
slug: "sailpoint"
tier: "3"
category: "IGA"
description: "Identity governance security for certification campaigns, source configs, and API access"
last_updated: "2025-12-14"
---


## Overview

SailPoint is the **#1 IGA (Identity Governance and Administration) vendor** controlling provisioning/deprovisioning workflows across enterprises. SCIM connector tokens, governance APIs, and credential provider integrations (Vault, AWS Secrets Manager, CyberArk) create attack chains. Compromised access enables identity manipulation at scale including backdoor account creation.

### Intended Audience
- Security engineers managing identity governance
- IT administrators configuring SailPoint
- GRC professionals assessing identity compliance
- Third-party risk managers evaluating IGA integrations

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Source Connector Security](#2-source-connector-security)
3. [Provisioning Security](#3-provisioning-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce MFA for Admin Access

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### Description
Require strong MFA for all SailPoint administrative access.

#### Rationale
**Why This Matters:**
- SailPoint controls identity provisioning enterprise-wide
- Admin compromise enables mass identity manipulation
- Governance APIs provide identity lifecycle control

**Attack Scenario:** Stolen SCIM token enables creation of backdoor accounts; API access modifies access certifications.

#### ClickOps Implementation (IdentityNow)

**Step 1: Configure SSO**
1. Navigate to: **Admin → Global Settings → Identity Profiles → SSO**
2. Configure SAML with your IdP
3. Require MFA at IdP level

**Step 2: Restrict Admin Access**
1. Navigate to: **Admin → Admins**
2. Limit admin count
3. Require additional verification for admin actions

---

### 1.2 Role-Based Administration

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-6

#### ClickOps Implementation

**Step 1: Define Admin Roles**
| Role | Permissions |
|------|-------------|
| Org Admin | Full platform access (2-3 users) |
| Source Admin | Manage specific sources |
| Cert Admin | Manage access certifications |
| Help Desk | Limited user management |

---

## 2. Source Connector Security

### 2.1 Secure SCIM Connectors

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Harden SCIM connector configurations.

#### Implementation

**Step 1: Audit Source Connections**
1. Navigate to: **Admin → Connections → Sources**
2. Review all active sources
3. Document credentials and permissions

**Step 2: Rotate SCIM Tokens**
| Source Type | Rotation Frequency |
|-------------|-------------------|
| HR Systems | Quarterly |
| Cloud Applications | Quarterly |
| Active Directory | Semi-annually |

---

## 3. Provisioning Security

### 3.1 Implement Provisioning Controls

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-2

#### ClickOps Implementation

**Step 1: Configure Provisioning Policies**
1. Require approval for privileged access
2. Implement time-limited access
3. Enable automatic deprovisioning

**Step 2: Monitor Provisioning Events**
1. Alert on privileged account creation
2. Alert on out-of-band provisioning
3. Alert on failed deprovisioning

---

## 4. Monitoring & Detection

### 4.1 Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### Detection Queries

```sql
-- Detect unusual account creation
SELECT created_by, COUNT(*) as account_count
FROM provisioning_events
WHERE action = 'CREATE'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY created_by
HAVING COUNT(*) > 10;

-- Detect certification modifications
SELECT admin_user, certification_name, action
FROM governance_events
WHERE action IN ('APPROVE_ALL', 'CERTIFICATION_MODIFY')
  AND timestamp > NOW() - INTERVAL '24 hours';
```

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial SailPoint hardening guide | How to Harden Community |
