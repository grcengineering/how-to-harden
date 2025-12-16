---
layout: guide
title: "New Relic Hardening Guide"
vendor: "New Relic"
slug: "new-relic"
tier: "5"
category: "Observability"
description: "Observability security for API keys, license keys, and log obfuscation"
last_updated: "2025-12-14"
---


## Overview

New Relic is an observability platform ingesting application performance, infrastructure, and log data. REST API, License Keys, and 400+ integrations collect telemetry from production environments. Compromised access exposes application architecture, performance patterns, and potentially sensitive log data.

### Intended Audience
- Security engineers managing observability platforms
- DevOps/SRE administrators
- GRC professionals assessing monitoring security
- Third-party risk managers evaluating APM integrations

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API & Key Security](#2-api--key-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Administration → Authentication domains**
2. Configure SAML IdP
3. Enable: **SSO required**

**Step 2: Enable MFA**
1. Configure MFA through IdP
2. Or enable New Relic MFA
3. Require for all users

---

### 1.2 Role-Based Access

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define Roles**

| Role | Permissions |
|------|-------------|
| Admin | Full account access |
| User | Standard access |
| Restricted User | Limited data access |
| Read only | View only |

**Step 2: Configure Groups**
1. Navigate to: **Administration → Access management → Groups**
2. Create groups per team
3. Assign account/role combinations

---

## 2. API & Key Security

### 2.1 Secure API Keys

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Manage New Relic API keys securely.

#### Rationale
**Attack Scenario:** Exposed License Key enables data injection; User Key exposure allows configuration changes and data access.

#### Implementation

**Key Types:**

| Key Type | Purpose | Risk |
|----------|---------|------|
| License Key | Data ingestion | Medium |
| User Key | API access | High |
| Insert Key | Data insertion | Medium |

**Step 1: Audit API Keys**
1. Navigate to: **API keys**
2. Review all keys
3. Delete unused keys

**Step 2: Key Best Practices**
1. Create unique keys per service
2. Rotate keys periodically
3. Use least privilege

---

### 2.2 License Key Protection

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### ClickOps Implementation

**Step 1: Rotate License Keys**
1. Navigate to: **Administration → License keys**
2. Generate new keys
3. Update agents
4. Deactivate old keys

---

## 3. Data Security

### 3.1 Configure Data Obfuscation

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### Description
Protect sensitive data in logs and traces.

#### ClickOps Implementation

**Step 1: Enable Log Obfuscation**
1. Navigate to: **Logs → Obfuscation**
2. Create obfuscation rules
3. Configure:
   - Pattern matching
   - Replacement values
   - Apply to expressions

**Step 2: Configure Drop Filters**
1. Navigate to: **Logs → Drop filters**
2. Drop sensitive log entries
3. Audit filter effectiveness

---

### 3.2 Data Retention

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SI-12

#### ClickOps Implementation

**Step 1: Review Data Retention**
1. Navigate to: **Data management → Data retention**
2. Review retention per data type
3. Adjust as needed

---

## 4. Monitoring & Detection

### 4.1 NrAuditEvent

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### Detection Queries

```sql
-- Detect configuration changes
SELECT * FROM NrAuditEvent
WHERE actionIdentifier LIKE '%update%'
SINCE 24 hours ago

-- Detect API key creation
SELECT * FROM NrAuditEvent
WHERE actionIdentifier LIKE '%apiKey%'
SINCE 7 days ago

-- Detect user additions
SELECT * FROM NrAuditEvent
WHERE actionIdentifier LIKE '%user%'
SINCE 7 days ago
```

---

## Appendix A: Edition Compatibility

| Control | Free | Standard | Pro | Enterprise |
|---------|------|----------|-----|------------|
| SAML SSO | ❌ | ❌ | ❌ | ✅ |
| Custom Roles | ❌ | ❌ | ✅ | ✅ |
| Audit Events | ✅ | ✅ | ✅ | ✅ |
| Log Obfuscation | ✅ | ✅ | ✅ | ✅ |

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial New Relic hardening guide | How to Harden Community |
