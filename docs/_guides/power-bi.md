---
layout: guide
title: "Power BI Hardening Guide"
vendor: "Power BI"
slug: "power-bi"
tier: "5"
category: "Data"
description: "Microsoft BI security for tenant settings, gateway credentials, and embed controls"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

Microsoft Power BI provides business intelligence with data connections across enterprise sources. REST API, embed tokens, and dataflows access sensitive business data. Compromised access exposes executive dashboards, financial reports, and aggregated business intelligence through the Microsoft 365 ecosystem.

### Intended Audience
- Security engineers managing BI platforms
- Power BI administrators
- GRC professionals assessing analytics security
- Third-party risk managers evaluating Microsoft integrations


### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries


### Scope
This guide covers Power BI security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Content Security](#2-content-security)
3. [Data Source Security](#3-data-source-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Conditional Access

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### ClickOps Implementation

**Step 1: Configure Conditional Access (Azure AD)**
1. Navigate to: **Azure AD → Conditional Access**
2. Create policy for Power BI
3. Require MFA
4. Configure device compliance

**Step 2: Enable Sensitivity Labels**
1. Navigate to: **Power BI Admin Portal → Tenant settings**
2. Enable: **Information protection**
3. Configure label inheritance

---

### 1.2 Workspace Access Controls

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define Workspace Roles**

| Role | Permissions |
|------|-------------|
| Admin | Full workspace control |
| Member | Edit and publish |
| Contributor | Edit only |
| Viewer | View only |

**Step 2: Configure Workspace Settings**
1. Create workspaces per team
2. Assign minimum required roles
3. Limit external sharing

---

## 2. Content Security

### 2.1 Configure Sharing Defaults

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-21

#### Description
Control report and dashboard sharing.

#### Rationale
**Attack Scenario:** Public publish to web exposes financial reports; embed tokens enable unauthorized dashboard access.

#### ClickOps Implementation

**Step 1: Tenant Settings**
1. Navigate to: **Power BI Admin Portal → Tenant settings**
2. Configure:
   - **Publish to web:** Disabled
   - **Share content externally:** Restricted
   - **Allow external users to edit:** Disabled

**Step 2: Export Controls**
1. Configure: **Export data** settings
2. Limit export formats
3. Audit export activity

---

### 2.2 Embed Security

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-21

#### Implementation

**Step 1: Secure Embed Tokens**
1. Use app owns data pattern with service principal
2. Implement row-level security
3. Set token expiration

**Step 2: Embed Controls**
1. Navigate to: **Tenant settings → Developer settings**
2. Restrict who can embed
3. Limit embed token generation

---

## 3. Data Source Security

### 3.1 Gateway Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### ClickOps Implementation

**Step 1: Manage Gateway Users**
1. Navigate to: **Settings → Manage gateways**
2. Limit gateway admins
3. Review data source credentials

**Step 2: Data Source Credentials**
1. Use service accounts
2. Limit database permissions
3. Rotate credentials periodically

---

### 3.2 Row-Level Security

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-3

#### Implementation

**Step 1: Define RLS Roles**
```dax
[Region] = USERPRINCIPALNAME()
-- Or use security groups
PATHCONTAINS("Finance", USERPRINCIPALNAME())
```

**Step 2: Test RLS**
1. Use "View as" feature
2. Test with different users
3. Audit RLS effectiveness

---

## 4. Monitoring & Detection

### 4.1 Activity Log

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Access Activity Log**
1. Navigate to: **Power BI Admin Portal → Audit logs**
2. Or use: **Microsoft 365 Compliance → Audit**
3. Configure log retention

#### Detection Focus

```kql
// Detect report exports
PowerBIActivity

| where Activity == "ExportReport"
| summarize count() by UserId
| where count_ > 10

// Detect embed token generation
PowerBIActivity

| where Activity == "GenerateEmbedToken"
| project TimeGenerated, UserId, ReportId
```

---

## Appendix A: Edition Compatibility

| Control | Pro | Premium |
|---------|-----|---------|
| Conditional Access | ✅ | ✅ |
| Sensitivity Labels | ✅ | ✅ |
| Audit Logs | ✅ | ✅ |
| BYOK Encryption | ❌ | ✅ |

---

## Appendix B: References

**Official Microsoft Documentation:**
- [Microsoft Trust Center](https://www.microsoft.com/en-us/trust-center)
- [Power BI Security](https://powerbi.microsoft.com/en-us/security/)
- [Power BI Documentation](https://learn.microsoft.com/en-us/power-bi/)
- [Power BI Security Whitepaper](https://learn.microsoft.com/en-us/power-bi/guidance/white-paper-powerbi-security)
- [Compliance and Data Privacy](https://learn.microsoft.com/en-us/power-platform/admin/wp-compliance-data-privacy)

**API Documentation:**
- [Power BI REST API Reference](https://learn.microsoft.com/en-us/rest/api/power-bi/)

**Compliance Frameworks:**
- SOC 1 Type II, SOC 2 Type II, ISO 27001, ISO 27018, FedRAMP, HIPAA BAA, PCI DSS, FINRA, IL6, EU Model Clauses, UK G-Cloud, and 100+ additional standards — via [Microsoft Trust Center](https://www.microsoft.com/en-us/trust-center)

**Security Incidents:**
- No major public security incidents specific to Power BI have been identified. Power BI security is managed as part of the broader Microsoft 365 / Azure ecosystem. Refer to the [Microsoft Security Response Center](https://msrc.microsoft.com/) for Microsoft-wide security advisories.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial Power BI hardening guide | Claude Code (Opus 4.5) |
