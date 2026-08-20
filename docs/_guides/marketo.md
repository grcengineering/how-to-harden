---
layout: guide
title: "Adobe Marketo Hardening Guide"
vendor: "Adobe Marketo"
slug: "marketo"
tier: "3"
category: "Marketing"
description: "Marketing automation security for API users, LaunchPoint services, and lead database"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

Adobe Marketo Engage is a B2B marketing automation platform managing lead databases, email campaigns, and CRM integrations. The REST API, together with LaunchPoint partner integrations, accesses prospect PII and behavioral data. Compromised API credentials enable lead database exfiltration and campaign manipulation for phishing distribution.

> **Deprecated — the SOAP API is gone.** Adobe states that **support for the Marketo SOAP API has ended**, effective **2026-07-31**. Earlier revisions of this guide treated SOAP as a live integration surface alongside REST; it is not. Treat any remaining SOAP integration or SOAP credential in your instance as a decommissioning item rather than something to harden. Source: [Marketo Engage release notes](https://experienceleague.adobe.com/en/docs/marketo/using/release-notes/current).

### Intended Audience
- Security engineers managing marketing platforms
- Marketing operations administrators
- GRC professionals assessing marketing compliance
- Third-party risk managers evaluating Adobe integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Adobe Marketo security configurations including authentication, access controls, and integration security.

> **Verification scope note (2026-08):** this revision was verified against Adobe Experience League and the Adobe Developer API documentation. Experience League serves a JavaScript landing shell for many paths, so article existence cannot be inferred from HTTP status — only pages whose rendered content was confirmed are cited. Of the Marketo admin paths in this guide, only **Admin → Users & Roles** was re-verified this pass. The **Admin → Single Sign-On**, **Admin → LaunchPoint**, **Admin → Field Management**, **Admin → Workspaces & Partitions**, and **Admin → Email → SPF/DKIM** paths reflect the last successful verification and were left unchanged rather than re-asserted; confirm the exact menu labels in your own instance.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API Security](#2-api-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML single sign-on with multi-factor authentication for all Marketo Engage access, so every login is brokered by your corporate identity provider rather than by a local Marketo password.

#### Rationale
**Why This Matters:**
- The Marketo lead database holds prospect PII and behavioural history at scale — a single compromised login exposes the whole record set, and there is no per-record barrier once an attacker is inside
- Marketo can send authenticated email as your organization, so a stolen login is a phishing platform with your brand's sender reputation already attached
- CRM synchronization means a Marketo compromise reaches beyond marketing: the integration exposes customer relationships and pipeline data held in the connected CRM
- Centralizing authentication in the IdP is what makes conditional access, phishing-resistant factors, and single-point deprovisioning possible; local Marketo logins bypass all three

**Attack Prevented:** Credential theft, phishing, password reuse, account takeover, orphaned-account access after departure

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Admin → Single Sign-On**
2. Configure:
   - SAML IdP metadata
   - Attribute mapping
   - JIT provisioning

**Step 2: Enforce MFA at the identity provider**
1. Enforce multi-factor authentication for the Marketo application in your identity provider or the Adobe Admin Console, depending on which identity model your instance uses
2. **Path not re-verified (2026-08):** an earlier revision of this guide instructed administrators to navigate to *Admin → Adobe Identity* and "enable Universal ID." That path could not be re-verified, and the instruction appears to conflate Marketo's **Universal ID** feature (which links one user's logins across multiple Marketo subscriptions) with the separate **Adobe IMS identity migration**. Adobe identity integration naming and placement may differ in your instance — confirm the current menu before following it
3. Whichever identity model applies, the MFA decision belongs to the identity provider fronting Marketo, not to a Marketo-local toggle

---

### 1.2 Implement Role-Based Access

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Define least-privilege roles in Marketo and assign each user only the Design Studio, Marketing Activities, Admin, and API permissions their job actually requires.

#### Rationale
**Why This Matters:**
- Marketo admins control the entire lead database, email sending, and API integrations, so over-provisioned accounts dramatically expand the blast radius of any single compromise
- Least-privilege roles keep designers, analysts, and standard users from exporting prospect lists or altering campaigns outside their remit
- Restricting Admin to a small handful of users limits who can create LaunchPoint services, mint API credentials, or change SSO settings
- Separating API access into its own permission prevents interactive accounts from being repurposed for bulk data extraction

**Attack Prevented:** Privilege escalation, insider data exfiltration, unauthorized campaign manipulation, lateral movement

#### ClickOps Implementation

**Step 1: Define Roles**

| Role | Permissions |
|------|-------------|
| Admin | Full access (2-3 users) |
| Marketing User | Create/edit campaigns |
| Designer | Email/landing page design |
| Analyst | Reporting only |
| Standard User | Limited access |

**Step 2: Configure Role Permissions**
1. Navigate to: **Admin → Users & Roles → Roles**
2. Create custom roles
3. Configure:
   - Access permissions (Design Studio, Marketing Activities)
   - Admin permissions
   - API access

---

### 1.3 Workspace Partitioning

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-4

#### Description
Segment access using workspaces and partitions.

#### Rationale
**Why This Matters:**
- Workspaces and lead partitions enforce data segregation so a user in one business unit or region cannot view or export another's prospect records
- Partitioning contains the damage from a compromised account to a single segment rather than exposing the entire lead database
- Regional partitions help meet data-residency and privacy obligations by isolating regulated leads from other teams
- Mapping partitions to workspaces prevents accidental cross-pollination of leads between brands or business units

**Attack Prevented:** Cross-segment data exposure, unauthorized lead access, data-residency violations, lateral movement between business units

#### ClickOps Implementation

**Step 1: Create Workspaces**
1. Navigate to: **Admin → Workspaces & Partitions**
2. Create workspaces per business unit/region
3. Assign users to appropriate workspaces

**Step 2: Configure Lead Partitions**
1. Create lead partitions for data segregation
2. Map partitions to workspaces
3. Configure partition assignment rules

---

## 2. API Security

### 2.1 Secure REST API Access

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Harden REST API integrations.

#### Rationale
**Attack Scenario:** Compromised API credentials enable lead database export; bulk extraction of prospect PII with behavioral data enables targeted phishing campaigns.

**Why This Matters:**
- Marketo REST APIs can read and export the entire lead database, making credential hygiene on Client ID and Secret pairs critical
- Dedicated API-only users provisioned through LaunchPoint keep automation credentials separate from interactive logins and easy to revoke
- Assigning each integration the minimum required role limits what a leaked token can reach to a single workspace or function
- Storing Client ID and Secret in a secrets manager rather than code or config prevents accidental exposure in repositories and logs

**Attack Prevented:** Credential theft, bulk PII exfiltration, API token abuse, phishing-list harvesting

#### ClickOps Implementation

**Step 1: Create API-Only Users**
1. Navigate to: **Admin → Users & Roles**
2. Create API-only user
3. Assign minimum required role

**Step 2: Configure LaunchPoint Services**
1. Navigate to: **Admin → LaunchPoint**
2. Create new service:
   - Service: Custom
   - API Only User: Select dedicated user
3. Document Client ID and Secret securely

**Step 3: Confirm no SOAP credentials remain provisioned**
1. Support for the Marketo SOAP API ended **2026-07-31** (see the Overview callout). Any SOAP integration still configured is, at best, broken automation and, at worst, an unmonitored credential nobody owns
2. Review LaunchPoint services and API-only users for entries created for SOAP integrations and decommission them — remove the service, then disable or delete the associated API-only user
3. Removing a dead integration's credential is the cheapest possible reduction in standing API access; do not leave it in place "in case it still works"
4. Source: [Marketo Engage release notes](https://experienceleague.adobe.com/en/docs/marketo/using/release-notes/current)

---

### 2.2 Webhook Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-8

#### Description
Secure Marketo webhook calls to external endpoints by enforcing HTTPS, validating signatures, allowlisting destination IPs, and minimizing the data each webhook transmits.

#### Rationale
**Why This Matters:**
- Webhooks push lead data from Marketo to external systems in real time, so an unencrypted or spoofable endpoint leaks prospect information in transit
- HTTPS and signature validation ensure payloads cannot be intercepted or forged by a man-in-the-middle
- IP allowlisting restricts which destinations Marketo will call, preventing redirection of sensitive data to attacker-controlled hosts
- Sending only the minimum fields, and using tokens for sensitive retrieval, limits exposure if a downstream endpoint is compromised

**Attack Prevented:** Man-in-the-middle interception, payload spoofing, data exfiltration to rogue endpoints, PII oversharing

#### Implementation

**Step 1: Secure Webhook Endpoints**
1. Use HTTPS only
2. Validate webhook signatures
3. Implement IP allowlisting

**Step 2: Limit Webhook Data**
1. Send minimum required fields
2. Avoid sending sensitive PII
3. Use tokens for sensitive data retrieval

---

### 2.3 Migrate API Authentication to the Authorization Header

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5, SC-8

#### Description
Move every Marketo REST integration off `access_token` query-parameter authentication and onto the HTTP `Authorization` header before Adobe's hard cutoff, so access tokens stop being written into URLs.

#### Rationale
**Why This Matters:**
- **This is a dated cutoff, not a recommendation.** Adobe has deprecated passing the Marketo REST access token as a query parameter, effective **2026-08-31**, and the deadline applies to **existing integrations as well as new ones**. Integrations that have not migrated stop authenticating
- A token in the query string is a token in the URL, and URLs are recorded everywhere a header is not: web server access logs, reverse proxy and load balancer logs, corporate egress proxies, browser history, and — if the URL is ever followed from a page — the HTTP `Referer` header sent to a third party
- Those logs are typically retained longer, replicated more widely, and protected less carefully than credential stores, so a query-parameter token has a far larger and longer-lived exposure surface than the same token carried in a header
- Tokens leaked this way leak silently: nothing about the integration fails, so there is no operational signal that the credential is sitting in a log aggregator with a broad readership

**Attack Prevented:** Access-token disclosure through access, proxy, and referrer logs; credential harvesting from log aggregation platforms; silent long-lived token exposure; integration outage at the deprecation deadline

#### ClickOps Implementation

**Step 1: Inventory how each integration authenticates**
1. List every REST integration against your Marketo instance — internal automation, LaunchPoint custom services, and vendor-built connectors alike
2. For each, determine whether it appends `access_token` to the request URL or sends an `Authorization` header
3. Vendor-built connectors are the ones most likely to be missed; ask the vendor for written confirmation rather than assuming

**Step 2: Migrate to header-based authentication**
1. Obtain the access token from the Identity endpoint as normal, then send it in the HTTP `Authorization` header on each API call instead of appending it to the URL
2. Sources: [Adobe Marketo APIs](https://developer.adobe.com/marketo-apis/) · [Identity API](https://developer.adobe.com/marketo-apis/api/identity)

**Step 3: Treat the deadline as a change-freeze milestone**
1. Complete migration ahead of **2026-08-31**; after that date unmigrated integrations fail, and an outage in marketing automation tends to be resolved under time pressure with whatever credential is nearest to hand
2. Rotate any token that was previously carried in query strings — assume it is present in logs you do not control

**Step 4: Purge the residue**
1. Search your own access, proxy, and application logs for `access_token=` and purge or restrict the matching entries
2. Add `access_token=` in a URL to your secret-scanning and log-hygiene rules so the pattern cannot quietly return

---

## 3. Data Security

### 3.1 Lead Database Protection

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Protect the Marketo lead database with field-level security and smart-list controls that restrict which sensitive fields appear on forms and who can bulk-export lead records.

#### Rationale
**Why This Matters:**
- The lead database is Marketo's crown jewel: prospect PII and behavioral data are exactly what attackers and malicious insiders want to bulk-export
- Field-level security keeps sensitive fields off public forms and out of reach of unauthorized editors, reducing accidental exposure
- Restricting smart-list export and access by role prevents any single user from downloading the entire prospect database
- Auditing list downloads creates a detection trail for abnormal bulk-extraction activity

**Attack Prevented:** Bulk lead exfiltration, insider data theft, unauthorized field disclosure, scraping of prospect PII

#### ClickOps Implementation

**Step 1: Configure Field-Level Security**
1. Navigate to: **Admin → Field Management**
2. Block sensitive fields from forms
3. Mark fields as hidden/read-only

**Step 2: Smart List Restrictions**
1. Limit bulk list export
2. Restrict smart list access by role
3. Audit list downloads

---

### 3.2 Email Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SI-3

#### Description
Configure SPF, DKIM, and DMARC for Marketo sending domains and govern email templates with editing restrictions and approval workflows.

#### Rationale
**Why This Matters:**
- SPF, DKIM, and DMARC authenticate Marketo as a legitimate sender, stopping attackers from spoofing your domain to launch phishing from a trusted source
- Marketo can send to your entire prospect and customer base, so a hijacked or unapproved template can distribute malicious content at scale
- Requiring approval and locking production templates prevents unauthorized or weaponized email from reaching recipients
- Proper email authentication protects deliverability and brand reputation while reducing the platform's value to phishers

**Attack Prevented:** Domain spoofing, phishing distribution, brand impersonation, malicious template injection

#### ClickOps Implementation

**Step 1: Configure Email Authentication**
1. Navigate to: **Admin → Email → SPF/DKIM**
2. Configure:
   - SPF records
   - DKIM signing
   - DMARC policy

**Step 2: Template Governance**
1. Restrict template editing
2. Require approval for production templates
3. Lock approved templates

**Step 3: Use archiving to shut down dormant sending**
1. Marketo's **Disable Campaigns on Archive** behaviour automatically disables and deschedules Smart Campaigns when their containing folder is archived
2. Archive the folder trees for retired programs and campaigns rather than leaving them dormant-but-live. A dormant Smart Campaign is a pre-built mass-send mechanism sitting in the instance; archiving removes the ability for a compromised or careless account to trigger it
3. Make archiving part of campaign end-of-life so the standing send capability shrinks as programs retire, instead of accumulating
4. Source: [Marketo Engage release notes](https://experienceleague.adobe.com/en/docs/marketo/using/release-notes/current)

---

## 4. Monitoring & Detection

### 4.1 Audit Trail

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Enable the Marketo Audit Trail and configure alerts to capture login history, asset and admin changes, failed logins, and API usage.

#### Rationale
**Why This Matters:**
- Without an audit trail, account compromise, data export, and configuration tampering go undetected and cannot be reconstructed during incident response
- Logging login history and failed logins surfaces credential-stuffing and brute-force attempts against the platform
- Tracking admin activities and asset changes reveals unauthorized role grants, LaunchPoint service creation, or campaign tampering
- Alerting on abnormal API usage provides early warning of bulk lead extraction through stolen credentials

**Attack Prevented:** Undetected account compromise, credential stuffing, unauthorized configuration changes, silent data exfiltration

#### ClickOps Implementation

**Step 1: Grant the Audit Trail permissions — the control fails silently without them**
1. Audit Trail access is permission-gated. A user without the permission does not see a restricted view; they see no Audit Trail at all, so a control assumed to be "enabled" can be invisible to the very people meant to read it
2. Navigate to: **Admin → Users & Roles → Roles → Edit Role → Access Admin**
3. Check **Access Audit Trail** and **Access Login History**
4. Assign that role to the users responsible for security review, then confirm each of them can actually open the trail
5. Source: [Enable Audit Trail](https://experienceleague.adobe.com/en/docs/marketo/using/product-docs/administration/audit-trail/enable-audit-trail)

**Step 2: Review the trail**
1. Navigate to: **Admin → Audit Trail**
2. Review:
   - Login history
   - Asset changes
   - Admin activities

**Step 3: Schedule an export — in-console retention is shorter than you think**
1. Marketo retains audit data for **6 months**, but only the most recent **30 days** are viewable in the console
2. Thirty days is shorter than the dwell time of a typical intrusion, so an incident discovered on a normal timeline may have its origin already outside the visible window. **A scheduled export to your own log store is therefore mandatory, not optional** — build it before you need it, because it cannot be created retroactively
3. Export on a cadence comfortably shorter than 30 days and retain according to your own incident-response requirements
4. Source: [Audit Trail overview](https://experienceleague.adobe.com/en/docs/marketo/using/product-docs/administration/audit-trail/audit-trail-overview)

**Step 4: Configure Alerts**
1. Set up admin notifications
2. Monitor failed logins
3. Track API usage

#### Detection Focus

- **Know the visible window.** Only 30 days are queryable in-console against 6 months of retention — any detection process that assumes deeper history in the UI will quietly return incomplete results. Detections that must look further back have to run against your exported copy
- **Know what the trail does not cover.** Audit Trail excludes **Web Personalization**, **Predictive Content**, and **Sales Insight** activity. Those surfaces need separate monitoring; do not treat Audit Trail coverage as instance-wide
- **Three activity streams to review every pass:** admin activity (role grants, LaunchPoint service creation, SSO changes), asset activity (campaign, email, and template changes), and login history (failed logins and unfamiliar access patterns)
- **Highest-value events:** creation of a LaunchPoint service or API-only user, role changes granting Access Admin, changes to email authentication settings, and Smart Campaign activation on previously dormant programs per [3.2](#32-email-security)
- **Verify the permission, not just the setting.** Because access is role-gated, an empty Audit Trail view during review means "you lack the permission" at least as often as it means "nothing happened" — confirm which before concluding the instance is quiet

---

### 4.2 Integration Monitoring

**Profile Level:** L2 (Walk)
**NIST 800-53:** AU-6, SI-4

#### Description
Monitor Marketo LaunchPoint integrations and API activity for anomalous behavior that signals a compromised service or credential.

#### Rationale
**Why This Matters:**
- LaunchPoint services and API integrations hold standing access to the lead database, making them high-value targets that warrant continuous monitoring
- Watching for unusual API call volumes or off-hours activity helps detect a compromised integration before large-scale data is exported
- Maintaining an inventory of active integrations catches rogue or forgotten LaunchPoint services that quietly expand the attack surface
- Correlating integration behavior against established baselines surfaces credential abuse that single-event logging would miss

**Attack Prevented:** Compromised integration abuse, stealthy API data exfiltration, rogue service persistence, credential misuse

---

## Appendix A: Edition Compatibility

| Control | Growth | Select | Prime | Ultimate |
|---------|--------|--------|-------|----------|
| SAML SSO | ✅ | ✅ | ✅ | ✅ |
| Workspaces | ❌ | ✅ | ✅ | ✅ |
| Audit Trail | ✅ | ✅ | ✅ | ✅ |
| API Access | Limited | ✅ | ✅ | ✅ |

---

## Appendix B: References

**Official Adobe Marketo Documentation:**
- [Marketo Engage release notes](https://experienceleague.adobe.com/en/docs/marketo/using/release-notes/current) — SOAP API end of support, REST query-parameter deprecation, Disable Campaigns on Archive
- [Audit Trail overview](https://experienceleague.adobe.com/en/docs/marketo/using/product-docs/administration/audit-trail/audit-trail-overview) — retention, visible window, exclusions
- [Enable Audit Trail](https://experienceleague.adobe.com/en/docs/marketo/using/product-docs/administration/audit-trail/enable-audit-trail) — the role permissions that gate access
- [Marketo Engage Product Documentation](https://experienceleague.adobe.com/en/docs/marketo/using/home)

**API Documentation:**
- [Adobe Marketo APIs](https://developer.adobe.com/marketo-apis/)
- [Marketo Identity API](https://developer.adobe.com/marketo-apis/api/identity) — access token acquisition

**Compliance Frameworks:**
- Adobe publishes attestation and certification reports for Marketo Engage through Adobe. Compliance-marketing and trust pages are deliberately not cited here; request the reports directly and assess them yourself.

**Security Incidents:**
- No major public security incidents specific to Adobe Marketo Engage identified. Adobe experienced a large-scale data breach in 2013 affecting Adobe Creative Cloud accounts (not Marketo). Track current advisories through Adobe's product security advisory feed and the [Marketo Engage release notes](https://experienceleague.adobe.com/en/docs/marketo/using/release-notes/current).

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass against Adobe Experience League and developer.adobe.com. **Support for the Marketo SOAP API ended 2026-07-31** — dropped SOAP as a live surface in the Overview and added a residual decommissioning step to 2.1. Added 2.3: REST `access_token` query-parameter authentication is deprecated for new *and existing* integrations effective **2026-08-31**, with migration to the `Authorization` header and the log/proxy/referrer leakage rationale. Expanded 4.1 with the role permissions that gate Audit Trail access (Admin → Users & Roles → Roles → Edit Role → Access Admin → Access Audit Trail / Access Login History — without them the control fails silently) and the retention reality (6 months retained, 30 days viewable in-console, scheduled export mandatory, Web Personalization / Predictive Content / Sales Insight excluded); populated Detection Focus. Added a Disable Campaigns on Archive step to 3.2. Fixed 1.1 for the cheat-sheet parser contract (added **Attack Prevented:** and upgraded the bare Why-This-Matters fragments) and added the missing **NIST 800-53:** line to 4.2; removed the empty Detection Queries and API Best Practices headings. Softened 1.1 Step 2 (the Adobe Identity / Universal ID path could not be re-verified and appears to conflate Universal ID with the Adobe IMS migration) and added a Scope-level verification note — only Admin → Users & Roles was re-verified this pass. Removed Adobe Trust Center, the trust-center whitepaper PDF, and both trust/compliance pages from Appendix B; corrected the 404ing developer sub-path to the /marketo-apis/ root plus the Identity API. Tier 2: no CIS Benchmark, DISA STIG, or CISA SCuBA baseline covers Marketo Engage. Tier 3/4 not surveyed this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Adobe Marketo hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
