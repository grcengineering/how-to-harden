---
layout: guide
title: "Tableau Hardening Guide"
vendor: "Tableau"
slug: "tableau"
tier: "4"
category: "Data"
description: "BI platform security for site roles, data source credentials, and embed controls"
version: "0.2.1"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

Tableau provides business intelligence and data visualization with connections to enterprise data sources. REST API, embedded credentials in workbooks, and data source connections access sensitive business data. Compromised access exposes executive dashboards, financial reports, and aggregated business intelligence.

### Intended Audience
- Security engineers managing BI platforms
- Tableau administrators
- GRC professionals assessing data governance
- Third-party risk managers evaluating analytics integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Tableau security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Data Source Security](#2-data-source-security)
3. [Content Security](#3-content-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Choose a Phishing-Resistant Authentication Type

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
MFA is already contractually mandatory on Tableau Cloud, so the decision left to you is *which* factor and *which* authentication type. Migrate off the built-in Tableau-with-MFA default onto a federated authentication type backed by your corporate identity provider and a phishing-resistant factor.

#### Rationale
**Why This Matters:**
- Since **1 February 2022**, Salesforce contractually requires MFA for all Tableau Cloud users regardless of authentication type — enabling MFA is not the control, choosing a strong factor and a federated authentication type is
- The default authentication type, **Tableau with MFA**, keeps a local TableauID credential store alongside your corporate directory, so offboarding, password policy, and conditional access are enforced in two places instead of one
- One-time codes and push approvals are defeated by real-time relay phishing; hardware security keys and passkeys are not
- A single compromised login can expose executive dashboards, financial reports, and the connected enterprise data sources behind them, so the factor choice is the difference between a blocked phish and a full BI compromise
- Session timeout limits the window an attacker can ride a hijacked or unattended session

**Attack Prevented:** Credential theft, real-time relay phishing, MFA bypass, session hijacking, orphaned local accounts

#### ClickOps Implementation

**Step 1: Choose the Authentication Type**

Tableau Cloud supports five authentication types. Only the first is local; the rest federate to an external identity provider:

| Authentication type | Notes |
|---------------------|-------|
| Tableau with MFA | Built-in TableauID accounts with mandatory MFA — **the default, and the type to migrate away from** |
| Google | Federated via OpenID Connect |
| OpenID Connect | Generic OIDC federation to your IdP |
| Salesforce | Federated via OpenID Connect |
| SAML | SAML 2.0 federation to your IdP |

1. Navigate to: **Settings → Authentication**
2. Select the federated authentication type your organization standardizes on and configure the IdP metadata

> **MFA is not optional, and not the finish line:** MFA has been contractually required for all Tableau Cloud users since 2022-02-01 regardless of authentication type. Treat any guidance that frames "turn on MFA" as the control as out of date — the live decisions are the factor strength and getting off local TableauID accounts ([Tableau Cloud authentication](https://help.tableau.com/current/online/en-us/security_auth.htm)).

**Step 2: Enforce a Phishing-Resistant Factor and Migrate Users**
1. Configure the MFA policy at the IdP, requiring hardware security keys or passkeys for administrators at minimum
2. Migrate existing TableauID users to the federated authentication type and retain only a documented break-glass account
3. Configure session timeout

---

### 1.2 Implement Site Roles

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Assign least-privilege site roles and project-level permissions so each user receives only the access their function requires.

#### Rationale
**Why This Matters:**
- Tableau site roles (Viewer through Site Administrator Creator) determine who can view, publish, or administer content and data sources
- Over-broad roles let ordinary users publish, download, or reconfigure content and reach data sources they should never touch
- Project-level permissions and permission templates contain the blast radius if any single account is compromised
- Separating administrator roles from creator and viewer roles enforces separation of duties

**Attack Prevented:** Privilege escalation, unauthorized data access, lateral movement, insider misuse

#### ClickOps Implementation

**Step 1: Define Site Roles**

| Role | Permissions |
|------|-------------|
| Cloud Administrator | Tenant-level administration in Tableau Cloud Manager — sits **above** the site roles below and spans every site in the tenant (see [1.3](#13-govern-the-tableau-cloud-manager-tenant-layer)) |
| Site Administrator Creator | Full site access |
| Site Administrator Explorer | Admin without publish |
| Creator | Create/publish content |
| Explorer | View and interact |
| Viewer | View only |

**Step 2: Configure Project Permissions**
1. Navigate to: **Explore → Projects**
2. Configure project-level permissions
3. Use permission templates

#### Code Implementation

{% include pack-code.html vendor="tableau" section="1.2" %}

---

### 1.3 Govern the Tableau Cloud Manager Tenant Layer

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-2, AC-6, AU-2

#### Description
Treat Tableau Cloud Manager (TCM) as a distinct privilege tier above the site roles: inventory who holds the Cloud Administrator role, keep that list minimal, and monitor the tenant events that record TCM changes.

#### Rationale
**Why This Matters:**
- TCM administers the tenant rather than a single site, so a Cloud Administrator's reach spans every site — including sites whose own Site Administrators never granted them anything
- The Cloud Administrator role is what the TCM REST API requires, which means a compromised Cloud Administrator credential is a programmatic tenant-wide credential, not just a console login
- A site-scoped access review is structurally blind to this layer: reviewing Site Administrator Creators tells you nothing about who can administer the tenant above them
- TCM changes, including role assignments and license monitoring, are recorded as **tenant events** in the Activity Log, so this layer has its own audit surface that must be collected deliberately

**Attack Prevented:** Privilege escalation above the site boundary, undetected tenant-wide administrative changes, programmatic tenant compromise via the TCM REST API, blind spots in site-scoped access reviews

#### Prerequisites
- A Tableau Cloud tenant administered through Tableau Cloud Manager
- Cloud Administrator role to view or change TCM configuration

#### ClickOps Implementation

**Step 1: Inventory Cloud Administrators**
1. In **Tableau Cloud Manager**, review every identity holding the **Cloud Administrator** role
2. Reduce the list to the minimum set, and require the phishing-resistant factor from [1.1](#11-choose-a-phishing-resistant-authentication-type) on each
3. Record the list as a distinct review item separate from your per-site administrator review

**Step 2: Monitor Tenant Events**
1. Collect **tenant events** from the Activity Log, which record TCM changes including role assignments and license monitoring (see [4.2](#42-collect-the-activity-log))
2. Alert on any Cloud Administrator role assignment

> **Documentation note:** the authoritative description of tenant events and the Cloud Administrator requirement used here is the Activity Log documentation ([Activity Log overview](https://help.tableau.com/current/online/en-us/activity_log_overview.htm)). A dedicated Tableau Cloud Manager reference page could not be located during this revision, so no separate TCM URL is cited.

#### Validation & Testing
Assign the Cloud Administrator role to a test identity and confirm the assignment appears as a tenant event in the Activity Log. Confirm the resulting list of Cloud Administrators matches your documented inventory.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST 800-53 | AC-2, AC-6, AU-2 |

---

## 2. Data Source Security

### 2.1 Secure Data Source Connections

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Protect data source credentials and connections.

#### Rationale
**Why This Matters:**
- Workbooks and data sources can embed database credentials that travel with the file and can be extracted from the packaged workbook
- Dedicated service accounts with least-privilege database grants limit what an extracted credential can reach
- OAuth and prompt-for-credentials connections avoid storing long-lived secrets inside published content entirely
- Published data sources centralize connection governance instead of scattering credentials across many workbooks

**Attack Prevented:** Credential extraction, embedded secret theft, direct database access, application-control bypass

**Attack Scenario:** Embedded database credentials are extracted from a downloaded workbook, and the attacker connects to the database directly — bypassing every application-level control Tableau enforces.

#### ClickOps Implementation

**Step 1: Use Service Accounts**
1. Create dedicated service accounts
2. Limit database permissions
3. Use published data sources

**Step 2: Credential Management**
1. Avoid embedding passwords in workbooks
2. Use OAuth where available
3. Prompt users for credentials

---

### 2.2 Row-Level Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-3

#### Description
Apply user filters and data source filters so each user sees only the rows of data they are authorized to view within a shared workbook.

#### Rationale
**Why This Matters:**
- Without row-level security, any user with access to a dashboard can see every row in the underlying data, including other regions, departments, or customers
- User-based filters scope query results to the authenticated user, enforcing data segregation inside a single shared workbook
- Applying filters at the data source prevents bypass by downloading or re-pointing the workbook
- Testing filters with different user identities verifies the control actually withholds unauthorized rows

**Attack Prevented:** Unauthorized data exposure, cross-tenant data leakage, over-broad data access

#### Implementation

**Step 1: Choose a Row-Level Security Approach**

Tableau documents four row-level security options. Pick the strongest one your data platform supports rather than defaulting to the most convenient:

| Approach | Notes |
|----------|-------|
| Manual user filter | Users are mapped to values by hand inside a workbook. Convenient but high-maintenance, and every workbook must be updated separately |
| Dynamic filter using a security field | A calculated field matches the signed-in user against a security field in the data. More secure than manual mapping because it does not depend on a per-workbook list |
| Data policy on a virtual connection | Requires Data Management on Tableau Server or Tableau Cloud. Tableau describes this as **the recommended approach in most situations** — it is centralized, reusable, and does not carry the same risk of exposure through improperly secured permissions |
| Row-level security in the database | Enforced by the data source itself, so it cannot be bypassed at the Tableau layer |

1. Where Data Management is licensed, implement a **data policy on a virtual connection** as the default choice
2. Otherwise, implement a **dynamic filter** driven by a security field rather than a manually mapped user filter
3. For extract-based implementations, Tableau recommends keeping the extract to two tables — the data table, and a reference or entitlements table holding user identities and their security groups

**Step 2: Configure Data Source Filters**
1. Apply the filter at the data source rather than the worksheet, so it cannot be bypassed by downloading or re-pointing the workbook
2. Test with different user identities and confirm unauthorized rows are actually withheld
3. Document the filter logic and the entitlements table that backs it

Sources: [Row-level security options overview](https://help.tableau.com/current/server/en-us/rls_options_overview.htm), [Restrict access at the data row level](https://help.tableau.com/current/pro/desktop/en-us/publish_userfilters.htm).

---

## 3. Content Security

### 3.1 Workbook Protection

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Lock project-level permissions, remove broad "All Users" grants, and encrypt extracts at rest to protect published workbook content.

#### Rationale
**Why This Matters:**
- Default or inherited "All Users" permissions can silently expose sensitive workbooks to the entire site
- Locking permissions to the project prevents content owners from re-opening access through per-workbook overrides
- Limiting extract downloads stops users from exfiltrating full data extracts to unmanaged devices
- Encrypting extracts at rest protects cached data if the underlying storage is accessed directly

**Attack Prevented:** Unauthorized content access, data exfiltration, exposure of data at rest

#### ClickOps Implementation

**Step 1: Configure Permissions**
1. Set project-level defaults
2. Lock permissions to project
3. Remove "All Users" permissions

**Step 2: Extract Security**
1. Configure extract refresh security
2. Limit extract downloads
3. Encrypt extracts at rest

#### Code Implementation

{% include pack-code.html vendor="tableau" section="3.1" %}

---

### 3.2 Embedding Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-21

#### Description
Restrict embedding to allowed domains via Connected Apps and constrain trusted-authentication ticket lifespan and trusted hosts.

#### Rationale
**Why This Matters:**
- Connected Apps and trusted authentication issue tokens or tickets that grant access to embedded views without an interactive login
- Restricting allowed domains prevents attacker-controlled sites from embedding and abusing your authenticated views
- Short ticket lifespans and a limited set of trusted hosts shrink the window and surface for token replay or forgery
- Monitoring trusted-authentication usage surfaces abuse of the embedding trust relationship

**Attack Prevented:** Token replay, clickjacking, unauthorized embedding, cross-domain content theft

#### Implementation

**Step 1: Connected Apps (Tableau Cloud)**
1. Navigate to: **Settings → Connected Apps**
2. Configure allowed domains
3. Set session timeout

**Step 2: Trusted Authentication**
1. Configure trusted hosts
2. Limit ticket lifespan
3. Monitor trusted authentication usage

#### Code Implementation

{% include pack-code.html vendor="tableau" section="3.2" %}

---

## 4. Monitoring & Detection

### 4.1 Enable Admin Views

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Use Tableau Admin Views to monitor view traffic, data source access, and user activity for security-relevant events.

#### Rationale
**Why This Matters:**
- Admin Views surface who accessed which views and data sources, providing the audit trail needed to detect misuse
- Without monitoring, credential abuse, data scraping, and unauthorized access go undetected until after damage is done
- Reviewing traffic to views and data source access establishes a behavioral baseline so anomalies stand out
- Activity records support incident investigation and compliance evidence for access-auditing requirements

**Attack Prevented:** Undetected data access, credential abuse, insider data scraping, delayed breach detection

#### ClickOps Implementation

**Step 1: Access Admin Views**
1. Navigate to: **Status → Traffic to Views**
2. Monitor data source access
3. Review user activity

#### Detection Focus

Admin Views answer "who looked at what" but do not carry the event-level detail security teams need. Pair them with the Activity Log ([4.2](#42-collect-the-activity-log)) and prioritize:

- **Login failures followed by a success** from the same identity — a credential-stuffing or password-spray outcome
- **Permission changes** on projects, workbooks, and data sources, especially any grant to a broad group
- **Spikes in traffic to a single view or data source** by one user, which is the shape of data scraping
- **First-time access** to a sensitive data source by an identity with no prior history against it
- **Cloud Administrator role assignments** recorded as tenant events (see [1.3](#13-govern-the-tableau-cloud-manager-tenant-layer))

---

### 4.2 Collect the Activity Log

**Profile Level:** L2 (Walk)
**NIST 800-53:** AU-2, AU-6, AU-11

#### Description
Collect the Tableau Cloud Activity Log — tenant events from Tableau Cloud Manager and site events covering logins, permission changes, and content interactions — and extend retention beyond the standard window via the REST API or an S3 destination.

#### Rationale
**Why This Matters:**
- The Activity Log carries event-level security detail that Admin Views do not: login successes and failures, permission changes, and content interactions
- **Standard retention is 14 days**, which is shorter than most incident-discovery timelines — by the time a compromise is noticed, the evidence has aged out
- Advanced Management, Tableau Enterprise, or Tableau+ raises retention to **365 days** when events are retrieved through the REST API, turning the Activity Log into usable forensic evidence
- Tenant events are the only record of Tableau Cloud Manager changes, including role assignments and license monitoring, so skipping them leaves the highest privilege tier unaudited

**Attack Prevented:** Evidence loss through log expiry, undetected permission tampering, unattributed data access, unaudited tenant-level administrative change

#### Prerequisites
- Cloud Administrator role
- Advanced Management, Tableau Enterprise, or Tableau+ for 365-day retention

#### ClickOps Implementation

**Step 1: Understand the Two Event Classes**

| Event class | What it records |
|-------------|-----------------|
| Tenant events | Tableau Cloud Manager changes, including role assignments and license monitoring |
| Site events | Login success and failure, permission changes, and content interactions within a site |

**Step 2: Choose a Retention and Delivery Path**

| Option | Retention | Update latency |
|--------|-----------|----------------|
| Standard | 14 days | 1 day |
| REST API with Advanced Management / Tableau Enterprise / Tableau+ | 365 days | Under 15 minutes |
| Site events delivered to a customer-owned Amazon S3 bucket | Per your bucket lifecycle policy | — |

1. Retrieve events through the **REST API** for the longer retention window and the sub-15-minute update latency
2. Where continuous delivery is preferred, configure site events to land in an **S3 bucket** you own and apply your own lifecycle retention
3. Forward collected events into your SIEM and build the detections listed in [4.1](#41-enable-admin-views)

> **Access requirement:** the **Cloud Administrator** role is required to work with the Activity Log ([Activity Log overview](https://help.tableau.com/current/online/en-us/activity_log_overview.htm)).

#### Code Implementation

{% include pack-code.html vendor="tableau" section="4.2" %}

#### Validation & Testing
Generate a known event — a failed login, then a permission change — and confirm both appear in the collected Activity Log within the expected latency. Confirm events older than 14 days are still retrievable if you are licensed for extended retention.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST 800-53 | AU-2, AU-6, AU-11 |

---

## Appendix A: Edition Compatibility

| Control | Tableau Cloud | Tableau Server |
|---------|---------------|----------------|
| SAML SSO | ✅ | ✅ |
| Site Roles | ✅ | ✅ |
| Row-Level Security | ✅ | ✅ |
| Admin Views | ✅ | ✅ |

---

## Appendix B: References

**Official Tableau Documentation:**
- [Tableau Help](https://help.tableau.com/)
- [Tableau Cloud Security Overview](https://help.tableau.com/current/online/en-us/to_security.htm) — the Cloud-applicable security anchor
- [Tableau Cloud Authentication](https://help.tableau.com/current/online/en-us/security_auth.htm)
- [Activity Log Overview](https://help.tableau.com/current/online/en-us/activity_log_overview.htm)
- [Row-Level Security Options Overview](https://help.tableau.com/current/server/en-us/rls_options_overview.htm)
- [Tableau Server Security Hardening Checklist](https://help.tableau.com/current/server/en-us/security_harden.htm) — **Tableau Server (Windows) only.** This checklist covers operating-system, TLS, and service-account hardening for a self-managed Server deployment; it is not applicable to Tableau Cloud as written. Cloud readers should use the Cloud security overview above instead.

**API & Developer Tools:**
- [REST API Reference](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api.htm)
- [Tableau Security Bulletins](https://community.tableau.com/s/security-bulletins)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001:2022, ISO 27017, ISO 27018 -- via [Salesforce Compliance Site](https://compliance.salesforce.com/en)
- Tableau Cloud is covered under Salesforce's umbrella certifications including SOC reports, ISO certifications, and FedRAMP (Government Cloud)

**Security Incidents:**
- (2025) Multiple critical Tableau Server vulnerabilities disclosed, including CVE-2025-26496 (CVSS 9.6) allowing remote code execution and CVE-2025-52446 (CVSS 8.0) enabling arbitrary SQL execution. Patched in Tableau Server versions 2025.1.4, 2024.2.13, and 2023.3.20.
- (2018-2023) Brigham and Women's Hospital research data inadvertently exposed via a publicly accessible Tableau link, disclosing patient PII and health information. Accessible from February 2018 to June 2023.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.1 | ai-drafted | Added first Code Packs (Tableau REST API + Tableau Cloud Manager API, Python stdlib): 1.2 site-role audit (Get Users on Site), 3.1 project-permission audit (Query Projects contentPermissions + Query Project Permissions + Query Groups, flagging ManagedByOwner projects and "All Users" grants), 3.2 direct-trust Connected Apps audit (unrestrictedEmbedding / empty domainSafelist), 4.2 Activity Log export via the TCM Platform Data endpoints (pat/login, tenants/{tenantId}/activitylog list + download-URL exchange). All endpoints verified against the Tableau REST API and Cloud Manager API references. | Claude Code (Fable 5) |
| 2026-08-08 | 0.2.0 | ai-drafted | Currency pass. **1.1:** retitled and reframed — MFA has been contractually required for all Tableau Cloud users since 2022-02-01 regardless of authentication type, so the control is now choosing a phishing-resistant factor and migrating off local TableauID accounts rather than "enabling MFA"; the five documented authentication types added (Tableau with MFA as the built-in default, Google, OpenID Connect, Salesforce, SAML). **1.2:** Cloud Administrator added to the role table as the tenant tier above Site Administrator Creator. **New 1.3:** Tableau Cloud Manager tenant layer — Cloud Administrator inventory and tenant-event monitoring; citations anchored on the Activity Log documentation because no dedicated TCM reference page could be located. **2.1:** Attack Scenario prose tightened (placement already conformed to the repo convention). **2.2:** the empty "Implement User Filters" step replaced with the four documented row-level security options (manual user filter, dynamic security-field filter, virtual-connection data policy as Tableau's recommended default, database RLS) plus the two-table extract guidance. **4.1:** the bare Detection Focus heading populated with Activity Log-derived detection guidance. **New 4.2:** Activity Log collection — tenant vs site events, 14-day standard retention against 365 days via the REST API with Advanced Management/Tableau Enterprise/Tableau+, S3 delivery for site events, 1-day vs sub-15-minute latency, Cloud Administrator required. **Appendix B:** the Server hardening checklist annotated as Tableau Server (Windows) only and not Cloud-applicable as written; Cloud security overview, authentication, Activity Log, and RLS-options anchors added; Salesforce compliance links confined to the compliance-frameworks line. Attempted and NOT applied: a Tableau Cloud "security checklist for publishing data" page — two candidate URLs returned HTTP 404 and the page could not be located, so it is not cited. Not surveyed this pass: Tier 3/4 research, and Tableau Server-specific hardening | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | ai-drafted | Initial Tableau hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
