---
layout: guide
title: "SailPoint Hardening Guide"
vendor: "SailPoint"
slug: "sailpoint"
tier: "3"
category: "Identity"
description: "Identity governance security for certification campaigns, source configs, and API access"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

SailPoint is the **#1 IGA (Identity Governance and Administration) vendor** controlling provisioning/deprovisioning workflows across enterprises. SCIM connector tokens, governance APIs, and credential provider integrations (Vault, AWS Secrets Manager, CyberArk) create attack chains. Compromised access enables identity manipulation at scale including backdoor account creation.

### Intended Audience
- Security engineers managing identity governance
- IT administrators configuring SailPoint
- GRC professionals assessing identity compliance
- Third-party risk managers evaluating IGA integrations


### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries


### Scope
This guide covers SailPoint security configurations including authentication, access controls, and integration security.

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

---

## Appendix B: References

**Official SailPoint Documentation:**
- [SailPoint Documentation](https://documentation.sailpoint.com/)
- [Trust Center](https://www.sailpoint.com/why-us/trust)
- [Cybersecurity Trust Center](https://www.sailpoint.com/why-us/trust/cybersecurity)
- [Security Advisories](https://www.sailpoint.com/security-advisories)

**API & Developer Resources:**
- [SailPoint Developer Portal](https://developer.sailpoint.com/docs/api/v3/)

**Compliance & Certifications:**
- SOC 1 Type II, SOC 2 Type II, SOC 3, ISO 27001, ISO 15408, FedRAMP -- via [SailPoint Trust Center](https://www.sailpoint.com/why-us/trust/cybersecurity)

**Security Incidents:**
- **CVE-2024-10905 -- IdentityIQ Directory Traversal (December 2024):** A critical vulnerability (CVSS 10.0) in SailPoint IdentityIQ allowed unauthorized access to content stored within the application directory. Affected versions up to patch levels 8.4p2, 8.3p5, and 8.2p8. SailPoint released e-fixes for all impacted versions. No reports of exploitation in the wild at time of disclosure.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial SailPoint hardening guide | Claude Code (Opus 4.5) |
