---
layout: guide
title: "ADP Hardening Guide"
vendor: "ADP"
slug: "adp"
tier: "3"
category: "HR/Finance"
description: "Payroll platform security for API connections, SSO, and data access controls"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---


## Overview

ADP processes payroll for **640,000+ companies** worldwide with access to W-2 data, SSN, salary, and bank account information. The 2024 Broadcom/BSH breach and 2016 credential stuffing incident ("flowjacking") demonstrate partner ecosystem and registration code vulnerabilities. Regional partner compromise exposed employee data; attackers used stolen W-2 data for tax fraud.

### Intended Audience
- Security engineers managing payroll systems
- HR technology administrators
- GRC professionals assessing payroll compliance
- Third-party risk managers evaluating HR integrations

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers ADP security configurations including authentication, access controls, and integration security.

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

**Profile Level:** L1 (Crawl)
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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure ADP roles with segregation of duties for payroll functions.

#### Rationale
**Why This Matters:**
- Payroll functions span sensitive operations — running payroll, changing tax withholding, and editing bank account details — that no single person should control end to end
- Segregation of duties ensures one individual cannot both create a fraudulent payee and approve payment to it
- Least-privilege roles confine each user to the data they need, so a compromised HR account cannot also manipulate payroll runs
- Dual approval on large payrolls and bank-account changes adds a human checkpoint against insider fraud and account takeover

**Attack Prevented:** Insider payroll fraud, privilege escalation, unauthorized bank-account redirection, fraudulent payee creation

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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Harden API integrations with ADP Marketplace partners.

#### Rationale
**Why This Matters:**
- ADP Marketplace integrations and API connections can read W-2, salary, SSN, and bank data — an over-scoped or stale connection is a direct path to bulk PII exfiltration
- The 2024 BSH partner compromise shows a breached integration partner can expose employee payroll data even when ADP itself is not breached
- OAuth scopes set to the minimum required limit the blast radius if a partner's credentials are stolen
- Rotating API credentials and monitoring API usage surface anomalous bulk reads before large-scale data theft completes

**Attack Prevented:** Third-party partner compromise, API credential theft, over-scoped data access, bulk PII exfiltration

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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Implement controls to prevent W-2 data theft.

#### Rationale
**Why This Matters:**
- W-2 forms contain the SSN, wages, and address an attacker needs to file fraudulent tax returns and claim refunds in an employee's name
- The 2016 "flowjacking" attack stole W-2 data through the self-service registration workflow and used it for tax-refund fraud
- Restricting W-2 access to authorized personnel and alerting on generation and download limits both insider abuse and credential-theft impact
- Heightened auditing during tax season catches abnormal access patterns when W-2 fraud risk peaks

**Attack Prevented:** W-2 theft, tax-refund fraud, identity theft, unauthorized PII access

#### Implementation

1. Restrict W-2 access to authorized personnel only
2. Enable alerts for W-2 generation and download
3. Audit W-2 access during tax season
4. Configure fraud alerts for unusual W-2 patterns

---

## 4. Monitoring & Detection

### 4.1 Audit Logging

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Enable comprehensive audit logging across ADP for authentication, access, and payroll-change events, and forward the logs to your SIEM for monitoring and retention.

#### Rationale
**Why This Matters:**
- Without complete audit logs, credential stuffing, insider abuse, and fraudulent payroll changes go undetected and cannot be reconstructed after the fact
- Logging authentication and W-2 access events enables detection of the credential-stuffing pattern behind the 2016 flowjacking attack
- Forwarding logs to a SIEM enables alerting on anomalies such as bulk W-2 downloads or off-hours bank-account changes
- Retained audit trails are required for SOX, SOC 2, and tax-fraud investigations and incident response

**Attack Prevented:** Undetected credential stuffing, insider fraud, account takeover, unlogged data exfiltration

#### Detection Focus Areas

---

## 5. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | ADP Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | MFA enforcement | 1.1 |
| CC6.2 | Role-based access | 1.2 |

---

## Appendix B: References

**Official ADP Documentation:**
- [ADP Data Security](https://www.adp.com/about-adp/data-security.aspx)
- [Data Security Best Practices](https://www.adp.com/about-adp/data-security/best-practices.aspx)
- [Security Alerts](https://www.adp.com/about-adp/data-security/alerts.aspx)
- [Data Security Client Resources](https://www.adp.com/about-adp/data-security/client-resources.aspx)
- [ADP Support](https://support.adp.com/)

**API & Developer Tools:**
- [ADP Developer Resources](https://developers.adp.com/)
- [ADP Marketplace](https://apps.adp.com/)
- [ADP API Central](https://www.adp.com/what-we-offer/integrations/api-central.aspx)
- [Workforce Now API Catalog](https://developers.adp.com/articles/guides/adp-workforce-now-api-catalog)

**Compliance Frameworks:**
- SOC 1 Type II and SOC 2 Type II reports (available to customers under NDA) — via [Data Security](https://www.adp.com/about-adp/data-security.aspx)
- ISO 9001, ISO/IEC 27001, ISO/IEC 27701 (select services and locations)
- PCI DSS, Sarbanes-Oxley compliance
- OpenID Connect and OAuth 2.0 for API authentication

**Security Incidents:**
- **2016 — Flowjacking / W-2 Tax Fraud:** Attackers used stolen credentials and publicly available registration codes to access employee W-2 data at multiple ADP customer companies for tax fraud. ADP itself was not breached; the attack exploited the self-service registration workflow. ([Norton Rose Fulbright Analysis](https://www.nortonrosefulbright.com/en-us/knowledge/publications/52719313/security-issue-could-impact-adp-customers))
- **September 2024 — BSH Partner Ransomware (Broadcom):** El Dorado ransomware group compromised Business Systems House (BSH), a Middle Eastern ADP partner, exposing Broadcom employee payroll data. ADP stated only "a small subset" of clients in certain Middle Eastern countries were affected. ([The Register Report](https://www.theregister.com/2025/05/16/broadcom_employee_data_stolen_by/))

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial ADP hardening guide | Claude Code (Opus 4.5) |
