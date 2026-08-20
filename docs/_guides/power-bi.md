---
layout: guide
title: "Power BI Hardening Guide"
vendor: "Power BI"
slug: "power-bi"
tier: "5"
category: "Data"
description: "Microsoft BI security for tenant settings, gateway credentials, and embed controls"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

Microsoft Power BI provides business intelligence with data connections across enterprise sources. REST API, embed tokens, and dataflows access sensitive business data. Compromised access exposes executive dashboards, financial reports, and aggregated business intelligence through the Microsoft 365 ecosystem.

### Intended Audience
- Security engineers managing BI platforms
- Power BI administrators
- GRC professionals assessing analytics security
- Third-party risk managers evaluating Microsoft integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Power BI security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Content Security](#2-content-security)
3. [Data Source Security](#3-data-source-security)
4. [Monitoring & Detection](#4-monitoring--detection)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Conditional Access

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require Microsoft Entra ID Conditional Access policies (MFA and device compliance) for all Power BI access and enable Microsoft Purview Information Protection sensitivity labels on tenant content.

#### Rationale
**Why This Matters:**
- Conditional Access enforces MFA and device-compliance checks on every Power BI sign-in, closing the gap that password-only authentication leaves open
- Power BI inherits Microsoft Entra ID identity, so policies set centrally apply uniformly across the Microsoft 365 ecosystem instead of per-report
- Sensitivity labels travel with exported reports and datasets, keeping protection in place when content leaves the service
- Executive dashboards and financial reports are high-value targets, and unconditional access lets a single stolen credential reach all of them

**Attack Prevented:** Credential theft, phishing, MFA bypass, access from unmanaged or non-compliant devices

#### ClickOps Implementation

**Step 1: Configure Conditional Access (Microsoft Entra ID)**
1. Navigate to: **[Microsoft Entra admin center](https://entra.microsoft.com) → Protection → Conditional Access**
2. Create policy targeting the Power BI Service cloud app
3. Require MFA
4. Configure device compliance

> **Product rename:** the directory service formerly called Azure Active Directory is now **Microsoft Entra ID**, administered at `entra.microsoft.com`. Older Power BI documentation and console screenshots still say "Azure AD"; the identity and the policies are the same.

**Step 2: Enable Sensitivity Labels**
1. Navigate to: **[Fabric admin portal](https://app.fabric.microsoft.com) → Settings (gear) → Admin portal → Tenant settings**
2. Under **Information protection**, enable: **Allow users to apply sensitivity labels for content**
3. Configure label inheritance

Power BI's tenant administration now lives in the **Microsoft Fabric admin portal** — Power BI is one workload inside Fabric, and every tenant setting referenced in this guide is reached the same way ([Fabric admin overview](https://learn.microsoft.com/en-us/fabric/admin/admin-overview)).

---

### 1.2 Workspace Access Controls

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Assign least-privilege workspace roles (Admin, Member, Contributor, Viewer) per team and limit external sharing so users receive only the access their function requires.

#### Rationale
**Why This Matters:**
- Granular workspace roles enforce least privilege, so a Viewer cannot publish or alter datasets and a Contributor cannot reassign permissions
- Per-team workspaces contain the blast radius of a compromised account to that team's content rather than the whole tenant
- Restricting external sharing at the workspace level prevents sensitive reports from leaking to guests or unmanaged identities
- Over-broad Admin and Member grants are a common path to privilege escalation and unauthorized data exposure

**Attack Prevented:** Privilege escalation, unauthorized data modification, lateral movement, oversharing to external users

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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-21

#### Description
Control report and dashboard sharing.

#### Rationale
**Why This Matters:**
- Disabling Publish to web prevents reports from being exposed anonymously on the public internet where anyone with the link can read them
- Restricting external sharing keeps business intelligence inside the organization's identity boundary
- Limiting and auditing export formats stops data from being copied out of governed reports into ungoverned spreadsheets
- Default-open sharing settings are a common cause of accidental financial and customer-data exposure in Power BI

**Attack Prevented:** Anonymous public data exposure, data exfiltration via export, oversharing to external users

**Attack Scenario:** Public publish to web exposes financial reports; embed tokens enable unauthorized dashboard access.

#### ClickOps Implementation

**Step 1: Tenant Settings**
1. Navigate to: **[Fabric admin portal](https://app.fabric.microsoft.com) → Settings (gear) → Admin portal → Tenant settings → Export and sharing settings**
2. Configure:
   - **Publish to web:** Disabled (or, if the mission requires it, restricted to specific security groups with the **Only users who can create embed codes** allow-list option)
   - **Users can invite guest users to collaborate through item sharing and permissions:** Disabled unless externally required
   - **Guest users can browse and access Fabric content:** Disabled unless externally required

> **Setting renamed:** the tenant setting once labelled "Share content externally" is now **Users can invite guest users to collaborate through item sharing and permissions**. There is no "Allow external users to edit" setting — guest capability is governed by the guest-access settings enumerated in [2.5](#25-restrict-entra-b2b-guest-access-to-fabric-content) ([Export and sharing tenant settings](https://learn.microsoft.com/en-us/fabric/admin/service-admin-portal-export-sharing)).

**Step 2: Export Controls**

Each export path is an independent tenant setting under **Export and sharing settings**. Disable or scope to a security group every one your organization does not need:

| Setting | What it permits |
|---------|-----------------|
| Export to Excel | Exporting underlying and summarized data to `.xlsx` |
| Export reports as .csv | Exporting visual data to `.csv` |
| Download reports | Downloading the `.pbix` file, including its model |
| Copy and paste visuals | Copying a visual image and its data to the clipboard |
| Export reports as PowerPoint presentations or PDF documents | Static full-report exports |
| Export reports as MHTML documents | Paginated-report MHTML export |
| Export reports as Word documents | Paginated-report Word export |
| Export reports as XML documents | Paginated-report XML export |
| Export reports as image files | Rendering reports to image files |
| Print dashboards and reports | Printing rendered content |
| Users can work with semantic models in Excel using a live connection | Analyze in Excel live connections |
| Allow users to download data from notebooks and SQL editors | Notebook and SQL editor result downloads |

1. Set each export setting to **Disabled**, or **Enabled for a specific security group**, per your data-handling policy
2. Audit export activity in the unified audit log (see [4.1](#41-activity-log))

---

### 2.2 Embed Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-21

#### Description
Secure embedded analytics by using the app-owns-data pattern with a service principal, enforcing row-level security, setting short token expirations, and restricting who can generate embed tokens.

#### Rationale
**Why This Matters:**
- The app-owns-data pattern with a service principal keeps master credentials out of client code and centralizes embed authorization
- Row-level security ensures an embed token only returns the rows the end user is entitled to, even though the app authenticates as a single identity
- Short-lived embed tokens limit the window in which an intercepted or leaked token can be replayed
- Unrestricted embed-token generation lets any developer mint access to sensitive dashboards outside governed sharing controls

**Attack Prevented:** Embed token theft and replay, cross-user and cross-tenant data leakage, unauthorized dashboard access

#### Implementation

**Step 1: Secure Embed Tokens**
1. Use app owns data pattern with service principal
2. Implement row-level security
3. Set token expiration

**Step 2: Embed Controls**
1. Navigate to: **[Fabric admin portal](https://app.fabric.microsoft.com) → Settings (gear) → Admin portal → Tenant settings → Developer settings**
2. Scope **Embed content in apps** to the specific security groups that own embedding workloads
3. Restrict service principal API access as described in [2.3](#23-restrict-service-principal-api-access)

---

### 2.3 Restrict Service Principal API Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CISA SCuBA | MS.POWERBI.4.1v1, MS.POWERBI.4.2v1 |
| NIST 800-53 | AC-3, AC-6, IA-5 |

#### Description
Scope the Fabric developer tenant settings that grant service principals access to Fabric and Power BI APIs — and to workspace, connection, and deployment-pipeline creation — to named security groups rather than the whole organization.

#### Rationale
**Why This Matters:**
- A service principal with Fabric API access is a non-interactive identity that no Conditional Access policy or MFA prompt stands in front of, so its blast radius is whatever the tenant setting allows
- **Service principals can call Fabric public APIs** is enabled for the entire organization by default for new customers, meaning any application registration in the tenant can begin calling Fabric APIs without an administrator ever making a decision
- Scoping to a security group turns API access into a reviewable list of automation identities instead of an open door for every app registration in Entra ID
- Service principal profiles multiply one principal into many customer-facing identities, so leaving profile creation unrestricted compounds whatever a single leaked credential can reach

**Attack Prevented:** Non-interactive credential abuse, unauthorized programmatic data access, tenant-wide API reconnaissance, privilege escalation through an over-permissioned automation identity

#### ClickOps Implementation

**Step 1: Scope API Access**
1. Navigate to: **[Fabric admin portal](https://app.fabric.microsoft.com) → Settings (gear) → Admin portal → Tenant settings → Developer settings**
2. For **Service principals can call Fabric public APIs**, select **Specific security groups** and name only the groups holding approved automation identities

> **Default is open:** this setting is enabled for the entire organization by default for new customers. Leaving it at the default satisfies no baseline — SCuBA MS.POWERBI.4.1v1 requires it be restricted to specific security groups ([Developer tenant settings](https://learn.microsoft.com/en-us/fabric/admin/service-admin-portal-developer)).

**Step 2: Scope Resource Creation and Profiles**
1. For **Service principals can create workspaces, connections, and deployment pipelines**, confirm it is disabled or scoped to a named security group (it is disabled by default)
2. For **Service principals can access read-only admin APIs** and the service principal profile settings, apply the same security-group scoping (SCuBA MS.POWERBI.4.2v1)

#### Validation & Testing
Re-open each developer tenant setting and confirm it reads **Enabled for a specific security group** with an explicit group list — not **Enabled for the entire organization**. Then confirm an application registration outside those groups receives an authorization failure when it calls a Fabric API.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| CISA SCuBA Power BI | MS.POWERBI.4.1v1 — Service principals with access to APIs SHOULD be restricted to specific security groups |
| CISA SCuBA Power BI | MS.POWERBI.4.2v1 — Service principals creating and using profiles SHOULD be restricted to specific security groups |
| NIST 800-53 | AC-3, AC-6, IA-5 |

---

### 2.4 Block ResourceKey Authentication

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CISA SCuBA | MS.POWERBI.5.1v1 |
| NIST 800-53 | IA-2, IA-5 |

#### Description
Block ResourceKey-based authentication, the key-only path used by streaming and PUSH datasets, unless a specific documented use case requires it.

#### Rationale
**Why This Matters:**
- ResourceKey authentication authorizes a caller with a static key alone — no user identity, no Entra ID token, and therefore nothing for Conditional Access or MFA to evaluate
- A leaked resource key lets anyone push arbitrary rows into a streaming or PUSH dataset, poisoning the dashboards and alerts built on top of it
- Because the key is not tied to a user, activity performed with it is far harder to attribute during an investigation
- Blocking it forces streaming ingestion onto identity-backed authentication paths that can be revoked centrally

**Attack Prevented:** Static-key replay, unauthenticated data injection into streaming datasets, dashboard and alert poisoning, unattributable ingestion

#### ClickOps Implementation

**Step 1: Block the Setting**
1. Navigate to: **[Fabric admin portal](https://app.fabric.microsoft.com) → Settings (gear) → Admin portal → Tenant settings → Developer settings**
2. Enable: **Block ResourceKey Authentication**

> **Organization-wide only:** this setting applies to the entire organization and cannot be scoped to a security group ([Developer tenant settings](https://learn.microsoft.com/en-us/fabric/admin/service-admin-portal-developer)). If a streaming or PUSH dataset genuinely requires ResourceKey authentication, that exception is tenant-wide — document it and compensate by restricting who can create streaming datasets.

#### Validation & Testing
Attempt an API call against a streaming dataset using only its resource key and confirm it is rejected. Re-check the tenant setting after any Fabric release that touches developer settings.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| CISA SCuBA Power BI | MS.POWERBI.5.1v1 — ResourceKey-based authentication SHOULD be blocked unless a specific use case (e.g., streaming and/or PUSH datasets) merits its use |
| NIST 800-53 | IA-2, IA-5 |

---

### 2.5 Restrict Entra B2B Guest Access to Fabric Content

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CISA SCuBA | MS.POWERBI.2.1v1, MS.POWERBI.3.1v1 |
| NIST 800-53 | AC-3, AC-21 |

#### Description
Disable — or scope to named security groups — the five Fabric tenant settings that grant Microsoft Entra B2B guest users the ability to browse, share, invite into, and consume tenant content.

#### Rationale
**Why This Matters:**
- Guest access is governed by several independent tenant settings, so disabling one and assuming the rest followed leaves an open path an administrator believes is closed
- The invite setting lets an ordinary user create a new external identity in your tenant, turning content sharing into directory growth no one reviewed
- Cross-tenant semantic model sharing lets a guest work with your models from inside *their own* tenant, moving the data outside every boundary your Conditional Access policies cover
- SCuBA treats guest access and external invitation as two separate policies precisely because they fail independently

**Attack Prevented:** Unauthorized external data access, uncontrolled guest identity sprawl, cross-tenant data leakage, oversharing to unmanaged identities

#### ClickOps Implementation

**Step 1: Review the Guest Settings**
1. Navigate to: **[Fabric admin portal](https://app.fabric.microsoft.com) → Settings (gear) → Admin portal → Tenant settings → Export and sharing settings**
2. Evaluate each of the following and disable, or scope to a named security group, every one the mission does not require:

| Setting | Effect if enabled |
|---------|-------------------|
| Guest users can access Fabric | Guests may sign in to the tenant's Fabric experience |
| Guest users can browse and access Fabric content | Guests may navigate and open content rather than only follow direct links |
| Users can invite guest users to collaborate through item sharing and permissions | Ordinary users may create new external identities in the directory |
| Show Fabric items in OneLake catalog to guest users | Guests may discover items through the catalog |
| Guest users can work with shared semantic models in their own tenants | Guests may consume your semantic models from their own tenant (off by default) |

**Step 2: Align with Entra ID External Collaboration**
1. In the **[Microsoft Entra admin center](https://entra.microsoft.com)**, confirm external collaboration settings restrict who may invite guests
2. Ensure Conditional Access policies covering the Power BI Service also apply to guest and external user types

#### Validation & Testing
Sign in as a test B2B guest and confirm the guest cannot browse Fabric content, cannot discover items in the catalog, and cannot consume shared semantic models from a second tenant. Re-run after any Fabric release that adds a guest-facing setting.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| CISA SCuBA Power BI | MS.POWERBI.2.1v1 — Guest user access to the Power BI tenant SHOULD be disabled unless the agency mission requires the capability |
| CISA SCuBA Power BI | MS.POWERBI.3.1v1 — The Invite external users to your organization feature SHOULD be disabled unless agency mission requires the capability |
| NIST 800-53 | AC-3, AC-21 |

---

### 2.6 Govern External Data Sharing (OneLake)

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-3, AC-21, SC-7 |

#### Description
Restrict the Fabric tenant settings that let users share OneLake data outward across tenant boundaries, and scope both who may share and who may accept shared data to named security groups.

#### Rationale
**Why This Matters:**
- External data sharing operates on OneLake data itself rather than on a rendered report, so what leaves the boundary is the underlying data, not a view of it
- Recipients can view, build on, and — depending on configuration — further share the data from inside their own tenants, so the second hop is outside your visibility entirely
- Because sharing is initiated by users rather than administrators, an unscoped setting means every user is a potential data-export channel
- Scoping both the sharing side and the accepting side keeps a documented list of which teams may participate in cross-tenant data flows

**Attack Prevented:** Cross-tenant data exfiltration, uncontrolled onward sharing, third-party data sprawl, insider data export

#### ClickOps Implementation

**Step 1: Scope External Data Sharing**
1. Navigate to: **[Fabric admin portal](https://app.fabric.microsoft.com) → Settings (gear) → Admin portal → Tenant settings → Export and sharing settings**
2. For **External data sharing**, disable it or scope it to the specific security groups permitted to share OneLake data externally
3. Configure the companion setting governing **which users can accept external data shares** to the same narrow set

**Step 2: Review Active Shares**
1. Inventory existing external data shares and the tenants receiving them
2. Confirm each share has a documented business owner and a review date

> **No baseline coverage:** external data sharing postdates the current CISA ScubaGear Power BI baseline, which contains no policy for it. Treat this control as vendor-documented guidance ([Export and sharing tenant settings](https://learn.microsoft.com/en-us/fabric/admin/service-admin-portal-export-sharing)) rather than a baseline requirement.

#### Validation & Testing
Confirm the tenant setting reads **Disabled** or **Enabled for a specific security group**, then attempt to create an external share as a user outside those groups and confirm the option is unavailable.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| CISA SCuBA Power BI | No policy — the capability postdates the current baseline |
| NIST 800-53 | AC-3, AC-21, SC-7 |

---

## 3. Data Source Security

### 3.1 Gateway Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Limit on-premises data gateway administrators, review stored data source credentials, use dedicated service accounts with minimal database permissions, and rotate those credentials regularly.

#### Rationale
**Why This Matters:**
- The gateway stores credentials to on-premises databases, so a compromised gateway admin can reach every connected source
- Limiting gateway administrators reduces the number of identities that can repoint connections or read stored credentials
- Service accounts scoped to least-privilege database permissions cap what a leaked credential can actually do
- Regular credential rotation shrinks the value of any credential that is captured or exposed

**Attack Prevented:** Credential theft, lateral movement into on-premises databases, standing-credential abuse, privilege escalation

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

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-3

#### Description
Define and test row-level security (RLS) roles so users only see the dataset rows they are authorized to view, then validate enforcement with the "View as" feature.

#### Rationale
**Why This Matters:**
- RLS enforces data segregation inside a shared dataset, so one report can serve many audiences without exposing each other's rows
- Without RLS, any user with report access can see all underlying records, including other regions, teams, or customers
- Testing with "View as" catches misconfigured filters before they leak data in production
- RLS is the primary control preventing horizontal data exposure in multi-tenant or multi-team dashboards

**Attack Prevented:** Unauthorized data access, horizontal data exposure across tenants and teams, broken access control

#### Implementation

**Step 1: Define RLS Roles**

{% include pack-code.html vendor="power-bi" section="3.2" %}

**Step 2: Test RLS**
1. Use "View as" feature
2. Test with different users
3. Audit RLS effectiveness

---

## 4. Monitoring & Detection

### 4.1 Activity Log

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Enable and retain the Power BI activity log (or the Microsoft 365 unified audit log) to record user and admin actions such as sharing, exports, and access changes.

#### Rationale
**Why This Matters:**
- Activity logs provide the audit trail needed to detect suspicious sharing, mass exports, or unexpected admin changes
- Without retained logs, incident responders cannot reconstruct what data was accessed or exfiltrated and when
- Centralizing in the Microsoft 365 unified audit log correlates Power BI events with the rest of the tenant's activity
- Adequate retention satisfies compliance evidence requirements and supports forensic investigation

**Attack Prevented:** Undetected data exfiltration, insider abuse, delayed breach detection, audit-trail gaps

#### ClickOps Implementation

**Step 1: Access Activity Log**
1. Navigate to: **[Fabric admin portal](https://app.fabric.microsoft.com) → Settings (gear) → Admin portal → Audit logs**
2. Fabric links out to the **Microsoft Purview portal**, which is where the unified audit log is searched and retained
3. Configure log retention in Purview per your evidence-retention policy

> **Portal moved:** audit search no longer lives in a "Microsoft 365 Compliance" portal — Fabric and Power BI audit events are searched in the **Microsoft Purview portal** ([Fabric admin overview](https://learn.microsoft.com/en-us/fabric/admin/admin-overview)).

#### Detection Focus

{% include pack-code.html vendor="power-bi" section="4.1" %}

---

## 5. Compliance Quick Reference

### CISA SCuBA Power BI Baseline Mapping

CISA publishes a Secure Configuration Baseline for Power BI as part of the M365 SCuBA program, assessed by the [ScubaGear](https://github.com/cisagov/ScubaGear) tool. The table below maps the current ScubaGear Power BI baseline's eight policies to this guide. Policy statements are quoted from the baseline; the shipping revision string is not asserted here because the published document does not carry an unambiguous version identifier.

| Policy ID | Policy statement | Guide coverage |
|-----------|------------------|----------------|
| MS.POWERBI.1.1v1 | The Publish to Web feature SHOULD be disabled unless the agency mission requires the capability | [2.1](#21-configure-sharing-defaults) |
| MS.POWERBI.2.1v1 | Guest user access to the Power BI tenant SHOULD be disabled unless the agency mission requires the capability | [2.5](#25-restrict-entra-b2b-guest-access-to-fabric-content) |
| MS.POWERBI.3.1v1 | The Invite external users to your organization feature SHOULD be disabled unless agency mission requires the capability | [2.5](#25-restrict-entra-b2b-guest-access-to-fabric-content) |
| MS.POWERBI.4.1v1 | Service principals with access to APIs SHOULD be restricted to specific security groups | [2.3](#23-restrict-service-principal-api-access) |
| MS.POWERBI.4.2v1 | Service principals creating and using profiles SHOULD be restricted to specific security groups | [2.3](#23-restrict-service-principal-api-access) |
| MS.POWERBI.5.1v1 | ResourceKey-based authentication SHOULD be blocked unless a specific use case (e.g., streaming and/or PUSH datasets) merits its use | [2.4](#24-block-resourcekey-authentication) |
| MS.POWERBI.6.1v1 | Python and R interactions SHOULD be disabled | **Gap** — no control in this guide yet |
| MS.POWERBI.7.1v1 | Sensitivity labels SHOULD be enabled for Power BI and employed for sensitive data per enterprise data protection policies | [1.1](#11-enforce-conditional-access) |

**Known gap:** MS.POWERBI.6.1v1 (Python and R visual interactions) has no corresponding control in this guide. The relevant tenant settings sit under **Admin portal → Tenant settings → R and Python visuals settings**; a full control covering them is a candidate for the next revision.

### NIST 800-53 Rev 5 Mapping

| Control | Power BI Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | Conditional Access with MFA | [1.1](#11-enforce-conditional-access) |
| AC-3, AC-6 | Workspace roles | [1.2](#12-workspace-access-controls) |
| AC-21 | Sharing and export defaults | [2.1](#21-configure-sharing-defaults) |
| AC-21 | Embed security | [2.2](#22-embed-security) |
| AC-3, AC-6, IA-5 | Service principal API scoping | [2.3](#23-restrict-service-principal-api-access) |
| IA-2, IA-5 | ResourceKey authentication blocked | [2.4](#24-block-resourcekey-authentication) |
| AC-3, AC-21 | Guest access restrictions | [2.5](#25-restrict-entra-b2b-guest-access-to-fabric-content) |
| AC-3, AC-21, SC-7 | External data sharing governance | [2.6](#26-govern-external-data-sharing-onelake) |
| IA-5 | Gateway credential security | [3.1](#31-gateway-security) |
| AC-3 | Row-level security | [3.2](#32-row-level-security) |
| AU-2, AU-3 | Activity log | [4.1](#41-activity-log) |

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
- [Power BI Documentation](https://learn.microsoft.com/en-us/power-bi/)
- [Microsoft Fabric admin overview](https://learn.microsoft.com/en-us/fabric/admin/admin-overview) — the admin portal that now hosts every Power BI tenant setting
- [Export and sharing tenant settings](https://learn.microsoft.com/en-us/fabric/admin/service-admin-portal-export-sharing)
- [Developer tenant settings](https://learn.microsoft.com/en-us/fabric/admin/service-admin-portal-developer)
- [Power BI Security Whitepaper](https://learn.microsoft.com/en-us/power-bi/guidance/white-paper-powerbi-security)
- [Compliance and Data Privacy](https://learn.microsoft.com/en-us/power-platform/admin/wp-compliance-data-privacy)

**Benchmarks & Baselines:**
- [CISA ScubaGear — Power BI Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/powerbi.md)

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
| 2026-08-08 | 0.2.0 | draft | Currency pass. **Admin surface:** every tenant-setting path re-pointed to the Microsoft Fabric admin portal (app.fabric.microsoft.com → Settings → Admin portal → Tenant settings). **1.1:** Azure AD renamed to Microsoft Entra ID throughout with the Entra admin center path; sensitivity labels re-pathed to Fabric. **2.1:** stale setting names corrected — "Share content externally" is now "Users can invite guest users to collaborate through item sharing and permissions", and the non-existent "Allow external users to edit" replaced with "Guest users can browse and access Fabric content"; export controls expanded into the full enumerated table of export tenant settings; stray `Attack Scenario` normalized into the rationale block. **2.2:** developer settings re-pathed. **New 2.3:** service principal API access, including the enabled-by-default "Service principals can call Fabric public APIs" setting. **New 2.4:** Block ResourceKey Authentication (org-wide only). **New 2.5:** Entra B2B guest access — the five named guest tenant settings. **New 2.6:** external data sharing (OneLake), flagged as postdating the baseline. **4.1:** audit search corrected to the Microsoft Purview portal. **New §5 Compliance Quick Reference:** all eight CISA SCuBA Power BI baseline policies mapped, with MS.POWERBI.6.1v1 (Python/R interactions) recorded as an open gap. **Appendix B:** Microsoft Trust Center and the powerbi.microsoft.com security marketing page removed; Fabric admin, export/sharing, developer-settings, and ScubaGear baseline docs added. Still owed and NOT asserted this pass: the shipping ScubaGear baseline revision string (the published document carries no unambiguous version identifier) and whether CIS Microsoft 365 Foundations v7.0.0 contains a Power BI section. Not surveyed: Tier 3/4 research | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Power BI hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
