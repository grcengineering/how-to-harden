---
layout: guide
title: "Wiz Hardening Guide"
vendor: "Wiz"
slug: "wiz"
tier: "2"
category: "Security"
description: "Cloud security platform hardening for connector security and RBAC controls"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---


## Overview

Wiz provides agentless cloud security to **40-50% of Fortune 100** through API access to cloud environments. While the agentless architecture minimizes agent-based risks, OAuth tokens and cloud connector credentials could expose comprehensive cloud security posture data and SBOM information across major financial institutions and enterprises. Wiz's deep visibility into cloud configurations makes it a high-value target.

### Intended Audience
- Security engineers managing CSPM tools
- Cloud security architects
- GRC professionals assessing cloud security
- Third-party risk managers evaluating security tools

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Wiz-specific security configurations including authentication, cloud connector security, API access controls, and data protection.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Cloud Connector Security](#2-cloud-connector-security)
3. [API Security](#3-api-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML SSO with MFA for all Wiz console access.

#### Rationale
**Why This Matters:**
- Wiz has visibility into all cloud infrastructure
- Compromised access exposes vulnerability data
- Attack planning facilitated by exposed security posture

**Attack Scenario:** Compromised OAuth token reveals infrastructure vulnerabilities and misconfigurations across customer's entire cloud estate.

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Settings → Authentication → SAML Configuration**
2. Configure:
   - **IdP Entity ID:** From your identity provider
   - **SSO URL:** IdP login endpoint
   - **Certificate:** Upload IdP certificate
3. Enable: **Enforce SAML authentication**

**Step 2: Disable Local Accounts**
1. Navigate to: **Settings → Authentication**
2. Disable: **Allow local authentication**
3. Keep 1 break-glass account (documented, monitored)

**Step 3: Configure Session Security**
1. Navigate to: **Settings → Authentication → Session Settings**
2. Configure:
   - **Session timeout:** 4 hours
   - **Idle timeout:** 30 minutes

#### Code Implementation

{% include pack-code.html vendor="wiz" section="1.1" %}

---

### 1.2 Implement Role-Based Access Control

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure Wiz roles with least-privilege access.

#### Rationale
**Why This Matters:**
- Wiz aggregates vulnerability, misconfiguration, and attack-path data across the entire cloud estate, so broad default access exposes all of it to every user
- Least-privilege roles ensure analysts, developers, and auditors see only what their job requires, shrinking the blast radius of a single compromised account
- Project-based access scopes findings to specific teams and environments, preventing lateral visibility across tenants and business units
- Restricting Admin to a small, tightly controlled set limits who can alter platform settings, connectors, and integrations

**Attack Prevented:** Privilege escalation, insider data harvesting, lateral reconnaissance, unauthorized configuration changes

#### ClickOps Implementation

**Step 1: Define Role Strategy**

| Role | Permissions |
|------|-------------|
| Admin | Full platform access (limit to 2-3) |
| Security Analyst | View issues, run queries, NO settings |
| Developer | View assigned projects only |
| Auditor | Read-only access, reports |
| Integration | API access for specific use cases |

**Step 2: Configure Custom Roles**
1. Navigate to: **Settings → Access Control → Roles**
2. Create custom roles with minimum permissions
3. Assign to user groups

**Step 3: Implement Project-Based Access**
1. Navigate to: **Settings → Projects**
2. Create projects for different teams/environments
3. Assign users to specific projects only

#### Code Implementation

{% include pack-code.html vendor="wiz" section="1.2" %}

---

## 2. Cloud Connector Security

### 2.1 Secure Cloud Connector Configuration

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5, AC-6

#### Description
Harden cloud connector IAM permissions to minimum required.

#### Rationale
**Why This Matters:**
- Wiz connectors have read access to cloud resources
- Over-privileged connectors expand attack surface
- Compromised connector credentials enable reconnaissance

#### AWS Connector Best Practices

**Step 1: Use Read-Only Policy**

{% include pack-code.html vendor="wiz" section="2.1" %}

**Step 2: Enable AWS CloudTrail for Connector**
1. Monitor Wiz connector API calls
2. Alert on unusual patterns
3. Review access regularly

**Step 3: Use External ID** (see the Code Pack above for the trust policy JSON)

#### Azure Connector Best Practices

**Step 1: Use Reader Role**
1. Assign Reader role at management group level
2. Avoid Contributor or Owner roles
3. Use managed identity where possible

**Step 2: Restrict App Registration Permissions**
1. Create dedicated app registration
2. Grant only Microsoft Graph read permissions
3. Document and monitor app usage

#### GCP Connector Best Practices

**Step 1: Use Viewer Role**
1. Assign Viewer role at organization level
2. Create service account with minimal permissions
3. Enable service account key rotation

---

### 2.2 Connector Credential Rotation

**Profile Level:** L2 (Walk)
**NIST 800-53:** IA-5(1)

#### Description
Implement regular rotation of cloud connector credentials.

#### Rationale
**Why This Matters:**
- Cloud connector credentials grant Wiz standing read access to your entire cloud environment, making long-lived secrets a durable target if leaked
- Regular rotation bounds the window during which a stolen IAM external ID, Azure app secret, or GCP service-account key remains usable
- Scheduled rotation forces removal of forgotten or unused credentials that would otherwise persist indefinitely
- A rotation cadence creates an audit trail and clear ownership around connector secrets

**Attack Prevented:** Credential theft reuse, long-lived secret abuse, stale-credential persistence, connector hijacking

#### Implementation

| Cloud | Credential Type | Rotation |
|-------|----------------|----------|
| AWS | IAM Role | External ID rotation annually |
| Azure | App Registration | Secret rotation quarterly |
| GCP | Service Account Key | Key rotation quarterly |

#### Code Implementation

{% include pack-code.html vendor="wiz" section="2.2" %}

---

## 3. API Security

### 3.1 Service Account Management

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Secure Wiz API service accounts.

#### Rationale
**Why This Matters:**
- Wiz API service accounts read sensitive vulnerability and posture data programmatically, so a shared or over-scoped account exposes that data to every integration holding it
- Purpose-specific accounts with minimum scopes ensure a compromised SIEM or ticketing integration cannot pivot beyond its intended permissions
- Quarterly credential rotation limits the lifetime of any leaked API token
- Separate accounts per integration make abuse attributable and revocation surgical

**Attack Prevented:** API token theft, over-privileged integration abuse, data exfiltration, credential sprawl

#### ClickOps Implementation

**Step 1: Create Purpose-Specific Service Accounts**
1. Navigate to: **Settings → Service Accounts**
2. Create accounts for:
   - SIEM integration (read-only)
   - Ticketing integration (limited write)
   - Automation (specific scopes)

**Step 2: Configure Minimum Scopes**

| Integration | Required Scopes |
|-------------|----------------|
| SIEM | `read:issues`, `read:vulnerabilities` |
| Ticketing | `read:issues`, `write:comments` |
| Automation | Specific to use case |

**Step 3: Rotate Credentials**
1. Set rotation schedule: Quarterly
2. Update integrations with new credentials
3. Revoke old credentials

#### Code Implementation

{% include pack-code.html vendor="wiz" section="3.1" %}

---

### 3.2 API Access Monitoring

**Profile Level:** L2 (Walk)
**NIST 800-53:** AU-6

#### Description
Monitor API usage for anomalies.

#### Rationale
**Why This Matters:**
- API abuse — bulk pulls of findings, unusual query volume, or off-hours access — is often the first signal of a compromised service-account token
- Monitoring establishes a behavioral baseline so anomalous extraction of vulnerability data is detected before it becomes a breach
- Alerting on usage spikes enables rapid token revocation, shrinking the exfiltration window
- Visibility into API activity supports incident response and provides compliance evidence

**Attack Prevented:** Stealthy data exfiltration, compromised-token abuse, undetected reconnaissance, bulk scraping

#### Implementation

{% include pack-code.html vendor="wiz" section="3.2" %}

---

## 4. Data Security

### 4.1 Configure Data Export Controls

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-3

#### Description
Control export of security findings and vulnerability data.

#### Rationale
**Why This Matters:**
- Wiz findings and vulnerability reports are effectively a map of exploitable weaknesses across your cloud, so uncontrolled export hands attackers a ready-made target list
- Restricting bulk export to Admins and logging every export limits who can remove this data and creates accountability
- Expiring, password-protected, internal-only share links prevent sensitive reports from leaking through forwarded or public URLs
- Alerting on large exports surfaces insider data theft or a compromised account exfiltrating posture data

**Attack Prevented:** Bulk data exfiltration, insider theft, leaked report links, attack-surface disclosure

#### ClickOps Implementation

**Step 1: Restrict Export Permissions**
1. Limit bulk export to Admin role only
2. Log all export activities
3. Alert on large exports

**Step 2: Configure Report Sharing**
1. Navigate to: **Settings → Reports**
2. Configure:
   - Internal sharing only
   - Expiration on shared links
   - Password protection

#### Code Implementation

{% include pack-code.html vendor="wiz" section="4.1" %}

---

## 5. Monitoring & Detection

### 5.1 Audit Logging

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Enable Wiz audit logging and forward authentication, configuration-change, and API-access events to your SIEM for correlation and alerting.

#### Rationale
**Why This Matters:**
- Audit logs are the primary record of who accessed Wiz, what they changed, and which API calls ran, so without them a compromise is invisible and unforensicable
- Forwarding events to a SIEM enables correlation with cloud and identity telemetry, catching attack patterns that span systems
- Capturing authentication and configuration changes detects unauthorized role grants, connector edits, and disabled controls in near real time
- Centralized, exported logs survive tampering or deletion within the Wiz console itself

**Attack Prevented:** Undetected account compromise, audit-trail tampering, stealthy configuration changes, delayed breach detection

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Settings → Audit Log**
2. Review:
   - Authentication events
   - Configuration changes
   - API access

**Step 2: Export to SIEM**
1. Configure webhook or API integration
2. Forward all audit events
3. Create correlation rules

#### Detection Queries

{% include pack-code.html vendor="wiz" section="5.1" %}

---

## 6. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Wiz Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO enforcement | 1.1 |
| CC6.2 | RBAC | 1.2 |
| CC6.7 | Data export controls | 4.1 |

---

## Appendix A: References

## Appendix B: References

**Official Wiz Documentation:**
- [Trust Center](https://www.wiz.io/trust-center)
- [Trust Center (SafeBase)](https://trust.wiz.io/)
- [Documentation Portal](https://docs.wiz.io/) (login required)
- [Resource Center](https://www.wiz.io/resources)
- [Wiz Research](https://www.wiz.io/research)
- [Cloud Threat Landscape — Incidents](https://threats.wiz.io/all-incidents)
- [CVE Vulnerability Database](https://www.wiz.io/vulnerability-database)

**API Documentation:**
- API endpoint: `https://api.<REGION>.app.wiz.io/graphql` (GraphQL)
- [Wiz GitHub Organization](https://github.com/wiz-sec)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3, ISO 27001, ISO 27017, ISO 27018, ISO 27701, HIPAA, PCI, FedRAMP Moderate — via [Trust Center](https://trust.wiz.io/)
- [Wiz for Government (FedRAMP)](https://www.wiz.io/verticals/government)

**Security Incidents:**
- No major public incidents involving Wiz as a victim identified

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Wiz hardening guide | Claude Code (Opus 4.5) |
