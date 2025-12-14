---
layout: guide
title: "ADP Hardening Guide"
vendor: "ADP"
slug: "adp"
tier: "3"
category: "HR/Payroll"
description: "Payroll platform security for API connections, SSO, and data access controls"
last_updated: "2025-12-14"
---


## Overview

ADP processes payroll for **640,000+ companies** worldwide with access to W-2 data, SSN, salary, and bank account information. The 2024 Broadcom/BSH breach and 2016 credential stuffing incident ("flowjacking") demonstrate partner ecosystem and registration code vulnerabilities. Regional partner compromise exposed employee data; attackers used stolen W-2 data for tax fraud.

### Intended Audience
- Security engineers managing payroll systems
- HR technology administrators
- GRC professionals assessing payroll compliance
- Third-party risk managers evaluating HR integrations

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API & Integration Security](#2-api--integration-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce MFA for All Access

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### Description
Require MFA for all ADP access, especially administrator and payroll processor accounts.

#### Rationale
**Why This Matters:**
- ADP contains highly sensitive PII (SSN, bank accounts)
- Payroll fraud potential is extremely high
- 2016 "flowjacking" attack stole W-2 data via credential stuffing

**Real-World Incidents:**
- **2016 Flowjacking:** Attackers used stolen credentials and registration codes to steal W-2 data for tax fraud
- **2024 BSH Breach:** Regional partner compromise exposed Broadcom employee data

#### ClickOps Implementation

**Step 1: Configure SSO with MFA**
1. Navigate to: **Admin Portal → Security → Single Sign-On**
2. Configure SAML SSO with your IdP
3. Require MFA at IdP level for ADP application

**Step 2: Enable ADP-Native MFA**
1. Navigate to: **Admin Portal → Security → Multi-Factor Authentication**
2. Enable: **Require MFA for all users**
3. Configure authentication methods

---

### 1.2 Implement Role-Based Access

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure ADP roles with segregation of duties for payroll functions.

#### ClickOps Implementation

**Step 1: Define Role Structure**
| Role | Permissions |
|------|-------------|
| Payroll Administrator | Full payroll access (limit to 2-3) |
| Payroll Processor | Run payroll, NO tax changes |
| HR Administrator | Employee data, NO payroll |
| Employee Self-Service | Own data only |

**Step 2: Implement Segregation of Duties**
- Separate payroll setup from payroll approval
- Separate bank account changes from payroll processing
- Require dual approval for large payrolls

---

## 2. API & Integration Security

### 2.1 Secure ADP API Connections

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Harden API integrations with ADP Marketplace partners.

#### Implementation

**Step 1: Audit Connected Apps**
1. Navigate to: **Admin Portal → Integrations**
2. Review all connected applications
3. Document data access for each

**Step 2: Configure OAuth Scopes**
1. Limit integrations to minimum scopes
2. Rotate API credentials quarterly
3. Monitor API usage

---

## 3. Data Security

### 3.1 Protect W-2 and Tax Data

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### Description
Implement controls to prevent W-2 data theft.

#### Implementation

1. Restrict W-2 access to authorized personnel only
2. Enable alerts for W-2 generation and download
3. Audit W-2 access during tax season
4. Configure fraud alerts for unusual W-2 patterns

---

## 4. Monitoring & Detection

### 4.1 Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### Detection Focus Areas

```sql
-- Detect unusual payroll changes
SELECT user_id, action, employee_id
FROM adp_audit_log
WHERE action IN ('bank_account_change', 'direct_deposit_change')
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect bulk W-2 access
SELECT user_id, COUNT(*) as w2_access_count
FROM adp_audit_log
WHERE action = 'w2_view'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_id
HAVING COUNT(*) > 10;
```

---

## 5. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | ADP Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | MFA enforcement | 1.1 |
| CC6.2 | Role-based access | 1.2 |

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial ADP hardening guide | How to Harden Community |
