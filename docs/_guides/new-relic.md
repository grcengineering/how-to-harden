---
layout: guide
title: "New Relic Hardening Guide"
vendor: "New Relic"
slug: "new-relic"
tier: "5"
category: "Data"
description: "Observability security for API keys, license keys, and log obfuscation"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
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

> **Edition gate:** SAML SSO requires a paid New Relic edition — it is available on Standard, Pro, and Enterprise, not only Enterprise. ([Authentication domains: SAML SSO, SCIM, and more](https://docs.newrelic.com/docs/accounts/accounts-billing/new-relic-one-user-management/authentication-domains-saml-sso-scim-more/))

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

### 1.3 Tune Authentication Domain Session and Upgrade-Request Controls

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-11, AC-12, AC-2(1)

#### Description
Set the session duration and idle timeout on each New Relic authentication domain, and configure how user type upgrade requests are handled so users cannot silently escalate their own access.

#### Rationale
**Why This Matters:**
- Session length and idle timeout are configured per authentication domain, not globally — a domain left on permissive defaults keeps sessions alive on unattended and shared machines long after the user has walked away
- New Relic user type governs what a user can do, and the upgrade-request workflow is the path by which a basic user becomes a full platform user; leaving it on automatic approval turns self-service into self-granted privilege
- Setting the domain to require review puts a human between a request and the entitlement, and New Relic caps a user at a small number of requests per day, which blunts request-spam pressure on approvers
- Domains hold different populations — contractors, vendors, internal staff — so per-domain settings let you be strict where the risk is highest without breaking everyone else's workflow

**Attack Prevented:** Session hijacking on unattended devices, stale session reuse, self-service privilege escalation, approval fatigue

#### ClickOps Implementation

**Step 1: Set Session Controls**
1. Navigate to: **one.newrelic.com → Administration → Authentication domains**
2. Select the domain and configure its session duration and session idle timeout
3. Apply the shortest values your users can tolerate, and set them tighter for domains containing contractors or vendors

**Step 2: Gate User Upgrade Requests**
1. In the same authentication domain, set upgrade requests to **Require review** rather than automatic approval
2. Assign named reviewers who understand what a full platform user can reach
3. Note that New Relic limits a user to a small number of upgrade requests in a 24-hour window (6), so a rejected request cannot simply be retried indefinitely

**Step 3: Review**
1. Re-check these settings whenever a new authentication domain is created — a new domain does not inherit another domain's hardening

([Authentication domains: SAML SSO, SCIM, and more](https://docs.newrelic.com/docs/accounts/accounts-billing/new-relic-one-user-management/authentication-domains-saml-sso-scim-more/))

---

### 1.4 Automate Provisioning and Deprovisioning with SCIM

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-2, AC-2(4)

#### Description
Enable SCIM provisioning on the authentication domain so users and groups are created, updated, and — critically — deactivated in New Relic automatically from your identity provider.

#### Rationale
**Why This Matters:**
- SSO alone authenticates users but does not remove them: an account disabled in the IdP can remain present in New Relic, and any path that bypasses the SSO redirect keeps working against it
- SCIM makes deprovisioning automatic, which is the mechanism the SSO control's deprovisioning rationale actually depends on — without it, "deprovision centrally" is a manual process someone has to remember
- Group-based push from the IdP keeps New Relic role assignment in step with team membership instead of drifting after every reorganisation
- Automated provisioning also removes the manual account-creation step where over-privileged roles are most often assigned by copy-paste

**Attack Prevented:** Orphaned-account access after offboarding, standing access for departed staff, role drift, over-privileged manual provisioning

#### Prerequisites
- SCIM provisioning requires a Pro or Enterprise New Relic edition
- An IdP that supports SCIM 2.0 user and group provisioning

#### ClickOps Implementation

**Step 1: Enable SCIM on the Authentication Domain**
1. Navigate to: **one.newrelic.com → Administration → Authentication domains**
2. Select the domain and switch its source of users to SCIM provisioning
3. Generate the SCIM bearer token and configure your IdP's New Relic application with it

**Step 2: Scope What Is Pushed**
1. Push only the groups that need New Relic access, not the entire directory
2. Map each pushed group to the least-privilege New Relic role and account scope from [1.2](#12-role-based-access)

**Step 3: Verify Deprovisioning End to End**
1. Disable a test user in the IdP and confirm the corresponding New Relic user is deactivated
2. Treat the SCIM bearer token as a high-value credential — it can manage your entire user population

([Authentication domains: SAML SSO, SCIM, and more](https://docs.newrelic.com/docs/accounts/accounts-billing/new-relic-one-user-management/authentication-domains-saml-sso-scim-more/))

---

## 2. API & Key Security

### 2.1 Secure API Keys

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Manage New Relic API keys securely.

#### Rationale
**Why This Matters:**
- API keys are long-lived credentials; a leaked User Key grants programmatic access to query data and modify account configuration, and an exposed License Key lets an attacker inject telemetry into your account
- License and Insert Keys authorize data ingestion, so exposure lets attackers inject false telemetry to mask real activity or run up usage costs
- Unique keys per service plus periodic rotation limit how long a leaked key stays useful and narrow what each key can reach
- Least-privilege key scoping ensures a single compromised key cannot reach the entire account
- Key types are not interchangeable in their rotation story — browser keys are embedded in pages users can read, and a mobile app token cannot be deleted or duplicated at all, so exposure there is handled by app-level response rather than by rotating the credential

**Attack Prevented:** API key leakage, telemetry injection, unauthorized configuration change, data exfiltration

#### Implementation

**Key Types:**

| Key Type | Purpose | Risk | Notes |
|----------|---------|------|-------|
| License Key | Data ingestion | Medium | The recommended ingest credential; use this rather than an Insights insert key |
| User Key | API access (NerdGraph, REST) | High | Tied to a user; grants that user's query and configuration reach |
| Browser key | Browser agent data ingestion | Medium | Embedded in client-side page source and therefore publicly visible by design — never treat it as a secret |
| Mobile app token | Mobile agent data ingestion | Medium | Cannot be deleted or duplicated; if exposed, response is at the application level, not a key rotation |
| Insights insert key | Legacy event insertion | Medium | Legacy — New Relic recommends the License Key instead |
| Insights query key | Legacy query access | High | Superseded by NerdGraph for querying |

> **Deprecated key types.** Insights insert keys are legacy and New Relic recommends the License Key for ingest; Insights query keys have been superseded by NerdGraph for querying; and the old admin keys were migrated to user keys in December 2020. If your runbooks still reference admin keys or Insights keys, they are describing a key model New Relic has moved on from. ([New Relic API keys](https://docs.newrelic.com/docs/apis/intro-apis/new-relic-api-keys/))

**Step 1: Audit API Keys**
1. Navigate to: **[one.newrelic.com/api-keys](https://one.newrelic.com/api-keys)** (or **one.newrelic.com → Administration → API keys**)
2. Review all keys — owner, type, and last use
3. Delete unused keys, and retire any remaining Insights insert or query keys in favour of License Keys and NerdGraph

**Step 2: Key Best Practices**
1. Create unique keys per service
2. Rotate keys periodically
3. Use least privilege
4. Exclude browser keys and mobile app tokens from secret-scanning alert policies deliberately and with a documented reason, rather than letting them generate noise that trains responders to ignore key alerts

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

#### Prerequisites
- Log obfuscation requires the **Data Plus** ingest option. It is not an edition feature — an account on any edition without Data Plus does not have obfuscation rules available, and must fall back to drop filters and agent-side redaction. ([Log obfuscation UI](https://docs.newrelic.com/docs/logs/ui-data/obfuscation-ui/))

#### ClickOps Implementation

**Step 1: Enable Log Obfuscation**
1. Navigate to: **one.newrelic.com → All capabilities → Logs → Obfuscation**
2. Create obfuscation rules
3. Configure:
   - Pattern matching
   - Replacement values
   - Apply to expressions

**Step 2: Configure Drop Filters**
1. Navigate to: **one.newrelic.com → All capabilities → Logs → Drop filter rules**
2. Drop sensitive log entries
3. Audit filter effectiveness

> **Without Data Plus, this control is not optional — it is unavailable.** If obfuscation is out of reach, keep sensitive values out of logs at the source (application-side redaction) and use drop filter rules for whole entries. Do not assume the data is masked because the guide lists the control.

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
1. Navigate to: **one.newrelic.com → Administration → Data management → Manage data retention**
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
| SAML SSO | ❌ | ✅ | ✅ | ✅ |
| SCIM provisioning | ❌ | ❌ | ✅ | ✅ |
| Custom Roles | ❌ | ❌ | ✅ | ✅ |
| Audit Events | ✅ | ✅ | ✅ | ✅ |
| Log Obfuscation | Data Plus | Data Plus | Data Plus | Data Plus |

**Notes:**
- SAML SSO requires a paid edition — Standard, Pro, or Enterprise. SCIM provisioning requires Pro or Enterprise. ([Authentication domains: SAML SSO, SCIM, and more](https://docs.newrelic.com/docs/accounts/accounts-billing/new-relic-one-user-management/authentication-domains-saml-sso-scim-more/))
- Log obfuscation is gated by the **Data Plus** ingest option rather than by edition — adding Data Plus, not upgrading edition, is what makes it available. ([Log obfuscation UI](https://docs.newrelic.com/docs/logs/ui-data/obfuscation-ui/))

---

## Appendix B: References

**Official New Relic Documentation:**
- [New Relic Product Documentation](https://docs.newrelic.com/)
- [Security and Privacy Documentation](https://docs.newrelic.com/docs/security/overview/)
- [Authentication domains: SAML SSO, SCIM, and more](https://docs.newrelic.com/docs/accounts/accounts-billing/new-relic-one-user-management/authentication-domains-saml-sso-scim-more/)
- [New Relic API keys](https://docs.newrelic.com/docs/apis/intro-apis/new-relic-api-keys/)
- [Log obfuscation UI](https://docs.newrelic.com/docs/logs/ui-data/obfuscation-ui/)

**API Documentation:**
- [New Relic APIs Introduction](https://docs.newrelic.com/docs/apis/intro-apis/introduction-new-relic-apis/)
- [NerdGraph (GraphQL) API](https://docs.newrelic.com/docs/apis/nerdgraph/get-started/introduction-new-relic-nerdgraph/)
- [New Relic SDKs and Agents](https://docs.newrelic.com/docs/new-relic-solutions/new-relic-one/install-configure/install-new-relic/)

**Compliance Frameworks:**
- SOC 1, SOC 2, ISO 27001, ISO 42001, FedRAMP, HIPAA, PCI DSS, TISAX
- [New Relic Regulatory Audits Documentation](https://docs.newrelic.com/docs/security/security-privacy/compliance/regulatory-audits-new-relic-services/)

**Security Incidents:**
- No major public security incidents identified for New Relic. Monitor New Relic's security advisories for current information.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | ai-drafted | Currency pass: corrected the edition matrix (SAML SSO is any paid edition, not Enterprise-only; added a SCIM row; log obfuscation is gated by the Data Plus ingest option, not by edition) and stated the Data Plus prerequisite in 3.1; rebuilt the 2.1 key-type table with browser keys and mobile app tokens and flagged the legacy Insights insert/query keys and the December 2020 admin-key migration; new controls 1.3 (authentication-domain session and upgrade-request controls) and 1.4 (SCIM provisioning); updated console navigation for 2.1, 3.1, and 3.2; removed marketing/Trust Center references from Appendix B. **Open question:** the "no major public security incidents" line in Appendix B could not be verified this pass and there are unconfirmed reports of a 2023 staging-environment intrusion — re-verify against a primary source when search budget allows. Tier 2: no CIS Benchmark, DISA STIG, or CISA SCuBA baseline covers New Relic. Tier 3/4 not surveyed this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | ai-drafted | Initial New Relic hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
