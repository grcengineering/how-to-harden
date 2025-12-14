---
layout: guide
title: "SAP SuccessFactors Hardening Guide"
vendor: "SAP SuccessFactors"
slug: "sap-successfactors"
tier: "3"
category: "HR"
description: "HCM security for permission groups, integration center, and data protection"
last_updated: "2025-12-14"
---


## Overview

SAP SuccessFactors is a global enterprise HCM with deep SAP ecosystem integration. OData and SOAP APIs, OAuth client configurations, and SAP Business Technology Platform connections handle employee master data, payroll, and performance records across multinationals. Sub-processor data flows create complex third-party risk.

### Intended Audience
- Security engineers managing HCM systems
- SAP administrators configuring SuccessFactors
- GRC professionals assessing HR compliance
- Third-party risk managers evaluating SAP integrations

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API Security](#2-api-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Configure SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Admin Center → Company Settings → Single Sign On**
2. Configure IdP metadata
3. Enable: **Enforce SSO**

**Step 2: Configure IDP-Initiated SSO**
1. Map SAML assertions to SF users
2. Configure attribute mapping
3. Enable session management

---

### 1.2 Role-Based Permissions (RBP)

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define Permission Roles**
| Role | Permissions |
|------|-------------|
| System Admin | Full access (limit users) |
| HR Admin | Employee data management |
| Manager | Team access only |
| Employee | Self-service only |

**Step 2: Configure Permission Groups**
1. Navigate to: **Admin Center → Manage Permission Roles**
2. Create permission groups
3. Assign target populations

---

## 2. API Security

### 2.1 Secure OData API Access

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Harden OData API integrations.

#### Rationale
**Attack Scenario:** Compromised OAuth client accesses Compound Employee API; sub-processor data flows expose global workforce data.

#### Implementation

**Step 1: Create Integration Users**
1. Navigate to: **Admin Center → Manage OAuth2 Client Applications**
2. Create dedicated OAuth clients per integration
3. Assign minimum required permissions

**Step 2: Configure API Permissions**
1. Limit OData entity access
2. Configure field-level restrictions
3. Enable audit logging

---

### 2.2 OAuth Token Management

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5(13)

#### Implementation

| Token Type | Expiration |
|------------|------------|
| Access Token | 1 hour |
| Refresh Token | 24 hours (L1) / 8 hours (L2) |

---

## 3. Data Security

### 3.1 Configure Data Privacy

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### ClickOps Implementation

**Step 1: Enable Data Protection**
1. Navigate to: **Admin Center → Data Protection & Privacy**
2. Configure:
   - Personal data handling
   - Consent management
   - Data retention

**Step 2: Field-Level Security**
1. Configure sensitive field masking
2. Restrict SSN/Tax ID visibility
3. Enable audit for sensitive data access

---

## 4. Monitoring & Detection

### 4.1 Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Enable Audit Trail**
1. Navigate to: **Admin Center → Audit Logging**
2. Enable comprehensive logging
3. Configure retention

#### Detection Focus

```sql
-- Detect bulk employee data access
SELECT user_id, api_endpoint, COUNT(*) as requests
FROM sf_audit_log
WHERE api_endpoint LIKE '%Employee%'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_id, api_endpoint
HAVING COUNT(*) > 100;
```

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial SAP SuccessFactors hardening guide | How to Harden Community |
