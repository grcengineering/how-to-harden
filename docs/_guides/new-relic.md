---
layout: guide
title: "New Relic Hardening Guide"
vendor: "New Relic"
slug: "new-relic"
tier: "5"
category: "Data"
description: "Observability security for API keys, license keys, and log obfuscation"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---


## Overview

New Relic is an observability platform ingesting application performance, infrastructure, and log data. REST API, License Keys, and 400+ integrations collect telemetry from production environments. Compromised access exposes application architecture, performance patterns, and potentially sensitive log data.

### Intended Audience
- Security engineers managing observability platforms
- DevOps/SRE administrators
- GRC professionals assessing monitoring security
- Third-party risk managers evaluating APM integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers New Relic security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API & Key Security](#2-api--key-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML single sign-on with multi-factor authentication for all New Relic access, federating authentication to your corporate identity provider.

#### Rationale
**Why This Matters:**
- Centralizes New Relic authentication in your corporate IdP so MFA, conditional access, and session policies apply to every login
- Local New Relic passwords bypass IdP controls and are prime targets for credential stuffing and phishing
- IdP-driven provisioning lets you deprovision departed users centrally, eliminating orphaned accounts with standing access to telemetry
- New Relic holds application architecture, performance data, and logs that can reveal sensitive operational detail — a single compromised login can expose all of it

**Attack Prevented:** Credential theft, phishing, MFA bypass, orphaned-account access

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Administration → Authentication domains**
2. Configure SAML IdP
3. Enable: **SSO required**

**Step 2: Enable MFA**
1. Configure MFA through IdP
2. Or enable New Relic MFA
3. Require for all users

{% include pack-code.html vendor="new-relic" section="1.1" %}

---

### 1.2 Role-Based Access

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Assign users to groups mapped to least-privilege roles and account scopes so each person can access only the telemetry and administrative functions their job requires.

#### Rationale
**Why This Matters:**
- Overly broad default access lets any user view all telemetry and change configurations far beyond their role
- Least-privilege roles and group-based assignment contain the blast radius if a single account is compromised
- Separating admin, standard, restricted, and read-only roles prevents accidental or malicious changes to monitoring and alerting
- Mapping groups to roles from your IdP keeps access consistent and auditable as teams change

**Attack Prevented:** Privilege escalation, lateral movement, unauthorized configuration change, excessive data exposure

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

{% include pack-code.html vendor="new-relic" section="1.2" %}

---

## 2. API & Key Security

### 2.1 Secure API Keys

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Manage New Relic API keys securely.

#### Rationale
**Attack Scenario:** Exposed License Key enables data injection; User Key exposure allows configuration changes and data access.

**Why This Matters:**
- API keys are long-lived credentials; a leaked User Key grants programmatic access to query data and modify account configuration
- License and Insert Keys authorize data ingestion, so exposure lets attackers inject false telemetry to mask real activity or run up usage costs
- Unique keys per service plus periodic rotation limit how long a leaked key stays useful and narrow what each key can reach
- Least-privilege key scoping ensures a single compromised key cannot reach the entire account

**Attack Prevented:** API key leakage, telemetry injection, unauthorized configuration change, data exfiltration

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

{% include pack-code.html vendor="new-relic" section="2.1" %}

---

### 2.2 License Key Protection

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Rotate New Relic License Keys on a regular schedule and after any suspected exposure — generating new keys, updating agents, then deactivating the old keys.

#### Rationale
**Why This Matters:**
- License Keys authorize data ingestion and are widely distributed across agents, configs, and CI pipelines, making leaks likely over time
- A leaked License Key lets attackers inject fabricated telemetry or run up ingest costs against your account
- Regular rotation and deactivation of old keys bounds the window in which any exposed key remains usable
- Updating agents before deactivating old keys avoids monitoring gaps that could hide an ongoing incident

**Attack Prevented:** License key leakage, telemetry injection, ingest cost abuse, persistent unauthorized access

#### ClickOps Implementation

**Step 1: Rotate License Keys**
1. Navigate to: **Administration → License keys**
2. Generate new keys
3. Update agents
4. Deactivate old keys

{% include pack-code.html vendor="new-relic" section="2.2" %}

---

## 3. Data Security

### 3.1 Configure Data Obfuscation

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Protect sensitive data in logs and traces.

#### Rationale
**Why This Matters:**
- Application logs and traces routinely capture secrets, tokens, PII, and other sensitive values that should never be stored in an observability platform
- Obfuscation rules mask matching patterns at ingest so sensitive data never lands in queryable storage
- Drop filters remove entire sensitive log entries, reducing both exposure and retention of regulated data
- Minimizing sensitive data in telemetry shrinks the impact if New Relic access is compromised and supports compliance obligations

**Attack Prevented:** Sensitive data exposure, secret/credential leakage via logs, PII disclosure, compliance violations

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

{% include pack-code.html vendor="new-relic" section="3.1" %}

---

### 3.2 Data Retention

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SI-12

#### Description
Review and tune data retention periods for each telemetry data type so data is kept only as long as operationally and legally required.

#### Rationale
**Why This Matters:**
- Indefinitely retained telemetry expands the volume of sensitive data exposed by any account compromise
- Setting retention per data type enforces data minimization and aligns storage with legal and regulatory requirements
- Shorter retention for sensitive data types reduces the window in which historical logs and traces can be exfiltrated
- Documented retention settings support audit and compliance reviews

**Attack Prevented:** Excessive data exposure, compliance violations, retention of regulated data beyond policy

#### ClickOps Implementation

**Step 1: Review Data Retention**
1. Navigate to: **Data management → Data retention**
2. Review retention per data type
3. Adjust as needed

{% include pack-code.html vendor="new-relic" section="3.2" %}

---

## 4. Monitoring & Detection

### 4.1 NrAuditEvent

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Use NrAuditEvent queries to monitor and alert on account configuration changes, access management activity, and other security-relevant administrative events in New Relic.

#### Rationale
**Why This Matters:**
- NrAuditEvent records administrative actions such as role changes, key creation, and user management that indicate misuse or compromise
- Without active monitoring of audit events, malicious configuration changes and unauthorized access go undetected
- Alerting on high-risk events enables rapid response before an attacker can entrench or exfiltrate data
- Retained audit query results provide the forensic trail needed to investigate incidents

**Attack Prevented:** Undetected privilege changes, stealthy account compromise, configuration tampering, delayed incident response

#### Detection Queries

{% include pack-code.html vendor="new-relic" section="4.1" %}

---

## Appendix A: Edition Compatibility

| Control | Free | Standard | Pro | Enterprise |
|---------|------|----------|-----|------------|
| SAML SSO | ❌ | ❌ | ❌ | ✅ |
| Custom Roles | ❌ | ❌ | ✅ | ✅ |
| Audit Events | ✅ | ✅ | ✅ | ✅ |
| Log Obfuscation | ✅ | ✅ | ✅ | ✅ |

---

## Appendix B: References

**Official New Relic Documentation:**
- [New Relic Security Overview](https://newrelic.com/security)
- [New Relic Product Documentation](https://docs.newrelic.com/)
- [Security and Privacy Documentation](https://docs.newrelic.com/docs/security/overview/)
- [Compliance and Certifications](https://newrelic.com/security/compliance-certifications)

**API Documentation:**
- [New Relic APIs Introduction](https://docs.newrelic.com/docs/apis/intro-apis/introduction-new-relic-apis/)
- [NerdGraph (GraphQL) API](https://docs.newrelic.com/docs/apis/nerdgraph/get-started/introduction-new-relic-nerdgraph/)
- [New Relic SDKs and Agents](https://docs.newrelic.com/docs/new-relic-solutions/new-relic-one/install-configure/install-new-relic/)

**Compliance Frameworks:**
- SOC 1, SOC 2, ISO 27001, ISO 42001, FedRAMP, HIPAA, PCI DSS, TISAX — via [New Relic Compliance and Certifications](https://newrelic.com/security/compliance-certifications)
- [New Relic Regulatory Audits Documentation](https://docs.newrelic.com/docs/security/security-privacy/compliance/regulatory-audits-new-relic-services/)

**Security Incidents:**
- No major public security incidents identified for New Relic. Monitor [New Relic Security](https://newrelic.com/security) for current advisories.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial New Relic hardening guide | Claude Code (Opus 4.5) |
