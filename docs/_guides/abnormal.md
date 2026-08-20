---
layout: guide
title: "Abnormal AI Hardening Guide"
vendor: "Abnormal AI"
slug: "abnormal"
tier: "2"
category: "Security"
description: "Email security platform hardening for Abnormal AI including SSO configuration, admin access, API token security, audit logging, and posture management"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Abnormal AI (formerly Abnormal Security) is an AI-powered email security platform providing advanced threat detection. As a platform analyzing email communications and detecting sophisticated attacks, Abnormal security configurations directly impact threat visibility and response capabilities.

### Intended Audience
- Security engineers managing email security
- IT administrators configuring Abnormal
- SOC analysts managing threat detection
- GRC professionals assessing email security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Abnormal portal security including SSO, admin access, API token security, audit logging, and security-posture monitoring.

**A note on sources and console paths:** Abnormal's administrative knowledge base is customer-gated, so the publicly verifiable Tier 1 anchor for this guide is the Abnormal REST API OpenAPI specification. Where this guide names a portal menu path, treat it as indicative rather than authoritative — the exact labels may differ in your tenant. API-level facts (endpoints, hosts, token handling) are verified against the published specification.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Integration Security](#3-integration-security)
4. [Monitoring & Logging](#4-monitoring--logging)
5. [Posture Management](#5-posture-management)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO for Abnormal portal access.

#### Rationale
**Why This Matters:**
- Centralizes Abnormal portal authentication in your corporate IdP, applying MFA and conditional access on every login
- Local password logins bypass IdP controls and are prime targets for credential stuffing and phishing
- SSO enables centralized deprovisioning so departed admins lose access immediately, eliminating orphaned accounts with standing access
- The portal exposes email threat detection, remediation actions, and tenant-wide message visibility — a single compromised login could disable protections or read flagged messages

**Attack Prevented:** Credential theft, phishing, password reuse, orphaned-account access

#### Prerequisites
- Abnormal admin access
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. In the Abnormal portal, open the single sign-on settings (typically under **Settings**; the exact path may vary by tenant, and Abnormal's administrative knowledge base is customer-gated)
2. Enable SAML authentication

**Step 2: Configure SAML**
1. Configure IdP settings:
   - Entity ID
   - SSO URL
   - Certificate
2. Configure Abnormal in IdP

**Step 3: Test and Enforce**
1. Test SSO authentication
2. Enable SSO enforcement
3. Configure fallback access

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all Abnormal users.

#### Rationale
**Why This Matters:**
- A second factor blocks attackers who already hold a valid password from completing a login
- Phishing-resistant methods (FIDO2/WebAuthn) for admins defeat real-time phishing proxies and push-fatigue attacks
- The Abnormal console controls email security policy and remediation — MFA prevents a single stolen credential from disabling defenses
- Enforcing MFA at the IdP applies uniformly to all SSO users without per-application gaps

**Attack Prevented:** Credential stuffing, password spraying, phishing, MFA push fatigue

#### ClickOps Implementation

**Step 1: Configure via IdP**
1. Enable MFA in identity provider
2. All SSO users subject to IdP MFA
3. Use phishing-resistant methods for admins

---

## 2. Access Controls

### 2.1 Configure User Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege for portal access.

#### Rationale
**Why This Matters:**
- Least-privilege roles ensure analysts and operators can only see and change what their job actually requires
- Read-only roles for analysts prevent accidental or malicious changes to detection and remediation policy
- Limiting elevated roles shrinks the blast radius if any single account is compromised
- The portal surfaces sensitive email metadata and content, so over-broad roles expand who can access it

**Attack Prevented:** Privilege escalation, insider misuse, lateral movement, accidental policy change

#### ClickOps Implementation

**Step 1: Review Roles**
1. In the Abnormal portal, open user management (typically under **Settings**; the exact path may vary by tenant, and Abnormal's administrative knowledge base is customer-gated)
2. Review available roles
3. Assign minimum necessary role

**Step 2: Apply Least Privilege**
1. Use read-only for analysts
2. Limit admin access
3. Regular access reviews

#### Automating the Access Review

The Abnormal REST API exposes the role and user inventory read-only, which is enough to automate the review even though role assignment itself is a portal action:

1. Call `GET /roles` to enumerate the roles defined in the tenant
2. Call `GET /users` to enumerate users and their assigned roles
3. Export the result on a fixed cadence (monthly for L1, weekly for L2) and diff it against the previous export and against your IdP group membership
4. Alert on any user present in Abnormal but absent from the expected IdP group, and on any role elevation that did not come from a change request

Authenticate these calls with the Bearer token described in [3.1](#31-secure-and-inventory-api-tokens) — a token used only for read-only review, not for remediation.

---

### 2.2 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect admin accounts.

#### Rationale
**Why This Matters:**
- Admin accounts can change security policy, disable detections, and access tenant-wide email data, so fewer admins means fewer high-value targets
- Requiring MFA and monitoring on admins raises the cost of compromising these privileged accounts
- Maintaining an inventory of admins enables timely deprovisioning and detection of unauthorized additions
- A compromised admin could silently weaken email defenses, allowing follow-on phishing and business email compromise to land

**Attack Prevented:** Admin account takeover, privilege abuse, undetected policy tampering, business email compromise

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review admin accounts
2. Document admin access

**Step 2: Apply Restrictions**
1. Limit admins to required personnel
2. Require MFA
3. Monitor admin activity

#### Automating the Admin Inventory

Automate the admin inventory rather than rebuilding it by hand each quarter:

1. Call `GET /users` and filter to accounts holding elevated roles returned by `GET /roles`
2. Store each export and diff successive runs — an admin appearing between two runs without a corresponding change request is the finding you are looking for
3. Cross-check the admin list against the IdP group that is supposed to grant Abnormal administration, and treat any account present in Abnormal but not in that group as an exception to close

---

## 3. Integration Security

### 3.1 Secure and Inventory API Tokens

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11, 5.4 |
| NIST 800-53 | IA-5, SC-12 |

#### Description
Abnormal's REST API authenticates with a Bearer token generated in the Abnormal portal. Store that token as a secret, restrict where it can be used from, point it at the correct regional host, and review the tenant's token inventory on a cadence.

#### Rationale
**Why This Matters:**
- A single Bearer token grants programmatic access to threat cases, user and role data, and remediation surfaces — it bypasses interactive login and any MFA enforced at the IdP
- Tokens leak the way all long-lived secrets leak: into CI configuration, scripts, ticket comments, and laptops — so the storage decision matters more than the generation step
- Abnormal recommends IP allowlisting as a second layer, which means a stolen token is not sufficient on its own if calls must also originate from a known egress point
- Tokens accumulate silently; without a periodic inventory, credentials issued for a decommissioned integration keep working indefinitely
- Calling the wrong regional host is a data-residency finding, not just a connectivity error

**Attack Prevented:** Token theft and replay, supply-chain compromise of an integration, over-privileged programmatic access, orphaned credentials for retired integrations, inadvertent cross-region data transfer

#### Prerequisites
- Abnormal portal access sufficient to generate API tokens
- A secrets manager or equivalent secure storage for the token

#### ClickOps Implementation

**Step 1: Generate and Store the Token**
1. Generate the API token from the Abnormal portal (the exact path may vary by tenant; Abnormal's administrative knowledge base is customer-gated)
2. Store it in a secrets manager, never in source control, CI configuration files, or a shared document
3. Issue a separate token per integration so one leak does not require rotating everything

**Step 2: Target the Correct Regional Host**
1. Use `https://api.abnormalplatform.com` as the default base host
2. **EU customers must call `https://eu.rest.abnormalsecurity.com` instead** — using the default host for an EU tenant is a data-residency problem as well as a broken integration

**Step 3: Add IP Allowlisting**
1. Restrict API access to the egress IPs of the systems that legitimately call Abnormal — the vendor recommends this as a second layer on top of the Bearer token
2. Keep the allowlist current as CI runners and SOAR platforms change egress

**Step 4: Review the Token Inventory**
1. Call `GET /soar/tokens` to enumerate the tokens that exist in the tenant
2. Reconcile every token against a named owner and a live integration
3. Revoke anything you cannot account for, and rotate on a defined schedule rather than only after an incident

---

## 4. Monitoring & Logging

### 4.1 Export Audit Logs to Your SIEM

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2, 8.9 |
| NIST 800-53 | AU-2, AU-6, AU-9 |

#### Description
Abnormal exposes tenant audit logs through the REST API. Pull them on a schedule into your SIEM so administrative activity in the platform is retained and correlated outside the platform itself.

#### Rationale
**Why This Matters:**
- Abnormal administrators can change detection policy, run remediation across the mail tenant, and read flagged message content — none of that is visible to your SOC unless the audit trail is exported
- Logs held only in the vendor's console are subject to the vendor's retention window and to tampering by anyone who compromises the console; an independent copy survives both
- Correlating Abnormal administrative events with IdP sign-ins and mail-platform activity is what turns "an admin ran a remediation" into "an admin ran a remediation twenty minutes after an anomalous login from a new country"
- Without export, a compromised admin account can weaken email defenses and leave no evidence your team ever sees

**Attack Prevented:** Undetected policy tampering, insider misuse of remediation capability, evidence loss through retention expiry or console-side deletion, delayed breach detection

#### Prerequisites
- An API token per [3.1](#31-secure-and-inventory-api-tokens), scoped to read-only use
- A SIEM or log platform able to poll an HTTP endpoint on a schedule

#### ClickOps Implementation

**Step 1: Establish the Collection Job**
1. Configure a scheduled collector (SIEM data input, SOAR job, or scheduled function) that calls `GET /auditlogs` with the Bearer token from 3.1
2. Use the correct regional base host — `https://api.abnormalplatform.com`, or `https://eu.rest.abnormalsecurity.com` for EU tenants
3. Page through results and checkpoint on the last retrieved record so restarts neither duplicate nor skip events

**Step 2: Retain and Protect the Copy**
1. Write the events into a retention tier that meets your compliance obligation, independent of Abnormal's own retention
2. Restrict who can delete from that tier — the point of the export is that it is not deletable by whoever compromised the console

**Step 3: Alert on the Events That Matter**
1. Build detections for administrative changes: role assignment, integration changes, and detection or policy modification
2. Alert on token creation and on bulk remediation actions
3. Review the audit stream during access reviews (2.1) so the two controls reinforce each other

---

## 5. Posture Management

### 5.1 Monitor Security Posture Drift

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 4.2 |
| NIST 800-53 | CM-2, CM-6, CM-3 |

#### Description
Abnormal's Security Posture Management (SPM) surface tracks configuration state in the connected mail platform and records changes to it. Query it on a cadence so drift in the mail tenant's security configuration is caught by process rather than by accident.

#### Rationale
**Why This Matters:**
- Most email compromises begin with a configuration change, not an exploit: a new mail-forwarding rule, a weakened authentication policy, an added transport rule, a privilege grant
- SPM keeps a timeline per posture item, so the question "when did this change, and did anyone approve it?" has an answer that does not depend on the mail platform's own audit retention
- Polling the posture catalog and querying current state turns configuration monitoring into something a SOAR playbook can run continuously, instead of a quarterly manual review
- Drift detection covers the mail platform Abnormal is connected to, which is precisely the system whose misconfiguration Abnormal's own detections assume is not happening

**Attack Prevented:** Silent mail-tenant misconfiguration, attacker-created forwarding and transport rules, unauthorized privilege changes in the connected platform, slow-burn configuration drift

#### Prerequisites
- An API token per [3.1](#31-secure-and-inventory-api-tokens)
- A connected mail platform (Microsoft 365 or Google Workspace)

#### ClickOps Implementation

**Step 1: Learn What Is Tracked**
1. Call `GET /spm-v2/posture-catalog` to enumerate the posture items available in your tenant
2. Decide which items are security-relevant for your environment and record that as the monitored set

**Step 2: Query Current State on a Cadence**
1. Call `POST /spm-v2/postures/query` to retrieve current posture state for the monitored set
2. Store each run and diff successive runs — the diff is the drift report
3. Use `GET /spm-v2/reports/summary` for the roll-up view that goes to management

**Step 3: Investigate Changes**
1. For any changed item, call `GET /spm-v2/postures/{id}/timeline` to establish when it changed
2. Reconcile the change against a change request; treat unexplained changes as incidents, not as documentation gaps
3. Correlate the timing against the audit log stream from [4.1](#41-export-audit-logs-to-your-siem)

---

### 5.2 Verify Tenant Security Settings

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
The REST API exposes the tenant's own security configuration through `GET /security-settings`. Use it as an independent verification and drift check on the Abnormal tenant itself, alongside the mail-platform posture monitoring in 5.1.

#### Rationale
**Why This Matters:**
- 5.1 watches the connected mail platform; this control watches Abnormal's own configuration, which is a different blast radius and needs its own baseline
- Reading configuration programmatically removes the "someone will check the console" dependency that makes configuration reviews the first thing to lapse
- A recorded baseline makes an unauthorized change detectable as a diff rather than requiring someone to notice a setting looks wrong
- Verification through the API is independent of console access, so it still works when the question is whether console access itself was misused

**Attack Prevented:** Undetected weakening of tenant security configuration, configuration drift between reviews, post-compromise persistence via settings changes

#### Prerequisites
- An API token per [3.1](#31-secure-and-inventory-api-tokens)

#### ClickOps Implementation

**Step 1: Capture a Baseline**
1. Call `GET /security-settings` and store the response as the approved baseline, with a date and an approver
2. **Honest caveat:** the public specification documents the endpoint, but the detail of the settings schema it returns is thin publicly — build your baseline from what your own tenant actually returns rather than from an assumed field list

**Step 2: Re-Check and Diff**
1. Re-run the call on the same cadence as your posture queries and diff against the stored baseline
2. Route any diff into the same investigation path as 5.1 drift findings

**Step 3: Re-Baseline Deliberately**
1. Update the stored baseline only through an approved change, never automatically from the latest response — auto-accepting the current state defeats the control

---

### 5.3 Track Compromised-Vendor Cases

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 15.1, 15.4 |
| NIST 800-53 | SR-3, SR-6 |

#### Description
Abnormal tracks email from compromised third-party vendors as a distinct case class, retrievable through `GET /vendor-cases`. Pull these into your supply-chain risk process rather than leaving them in the analyst queue.

#### Rationale
**Why This Matters:**
- Email from a genuinely compromised vendor arrives from a legitimate domain with a real relationship history behind it, which is exactly why it defeats reputation-based filtering and lands with users who have every reason to trust it
- A compromised-vendor case is a supply-chain signal about a specific counterparty, not just a message to remediate — it should reach whoever owns that vendor relationship
- Treating these cases as a distinct class lets you spot repeated compromise at the same vendor, which is a procurement and contract question rather than an email question
- Invoice and payment fraud typically arrives on this exact path, making these cases materially higher-impact than generic phishing

**Attack Prevented:** Vendor email compromise, invoice and payment fraud, supply-chain phishing riding on established trust relationships

#### Prerequisites
- An API token per [3.1](#31-secure-and-inventory-api-tokens)

#### ClickOps Implementation

**Step 1: Retrieve Vendor Cases**
1. Call `GET /vendor-cases` on a schedule and store the results alongside your other case data
2. Key each case to the vendor record in your third-party risk inventory

**Step 2: Route Them Correctly**
1. Notify the internal owner of the affected vendor relationship, not only the SOC
2. For finance-adjacent vendors, trigger out-of-band verification of any recent payment-detail change

**Step 3: Look for Patterns**
1. Track repeat cases per vendor over time
2. Escalate repeated compromise into the vendor risk review, since it is evidence about that vendor's own security posture

---

### 5.4 Govern the AI Security Mailbox and Reporting Loop

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 14.6, 17.4 |
| NIST 800-53 | IR-4, IR-6, SI-4 |

#### Description
User-reported phishing flows into Abnormal's AI Security Mailbox. Monitor the unanalyzed queue so submissions do not sit unprocessed, and use the reporting endpoint to feed misclassifications back to the vendor.

#### Rationale
**Why This Matters:**
- Report-phish buttons only work if reports are actually processed; a growing unanalyzed queue means users are doing the right thing and the organization is not
- Reports that rot are worse than no reporting program, because users learn their submissions go nowhere and stop reporting the one that mattered
- Campaign-level visibility shows whether a single reported message is one user's problem or the visible edge of a campaign already sitting in other mailboxes
- Feeding misclassifications back is what keeps detection quality improving instead of degrading quietly as attacker technique moves

**Attack Prevented:** Phishing that lands because a user report went unprocessed, campaign spread through unremediated mailboxes, erosion of the human reporting channel, persistent misclassification of an active technique

#### Prerequisites
- An API token per [3.1](#31-secure-and-inventory-api-tokens)
- A deployed user-reporting path (AI Security Mailbox or equivalent report button)

#### ClickOps Implementation

**Step 1: Monitor the Unanalyzed Queue**
1. Call `GET /abuse_mailbox/not_analyzed` on a schedule
2. Alert when the queue exceeds an agreed depth or age threshold — this is a service-level check on your own reporting program
3. Assign an owner for working the queue down, not just for watching it

**Step 2: Work at Campaign Level**
1. Call `GET /abusecampaigns` to see reported activity grouped as campaigns rather than as isolated messages
2. Confirm remediation covered every recipient in a campaign, not only the user who reported it

**Step 3: Close the Feedback Loop**
1. Submit misclassified messages — both missed threats and false positives — via `POST /detection360/reports`
2. Track submissions and outcomes so the reporting loop is measurable rather than anecdotal

---

## 6. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Abnormal Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | User roles | [2.1](#21-configure-user-roles) |
| CC6.6 | API token security | [3.1](#31-secure-and-inventory-api-tokens) |
| CC7.2 | Audit log export | [4.1](#41-export-audit-logs-to-your-siem) |
| CC7.1 | Posture drift monitoring | [5.1](#51-monitor-security-posture-drift) |
| CC9.2 | Vendor case tracking | [5.3](#53-track-compromised-vendor-cases) |

### NIST 800-53 Rev 5 Mapping

| Control | Abnormal Control | Guide Section |
|---------|------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-6 | User roles | [2.1](#21-configure-user-roles) |
| IA-5 | API token security | [3.1](#31-secure-and-inventory-api-tokens) |
| AU-6 | Audit log export | [4.1](#41-export-audit-logs-to-your-siem) |
| CM-6 | Posture and settings verification | [5.1](#51-monitor-security-posture-drift), [5.2](#52-verify-tenant-security-settings) |
| SR-6 | Compromised-vendor cases | [5.3](#53-track-compromised-vendor-cases) |
| IR-4 | User-reported phishing handling | [5.4](#54-govern-the-ai-security-mailbox-and-reporting-loop) |

---

## Appendix A: References

**Primary Technical Reference (Tier 1):**
- [Abnormal REST API v1.4.3 (SwaggerHub)](https://app.swaggerhub.com/apis-docs/abnormal-security/abx/1.4.3) — the OpenAPI specification, published 2024-04-26, is the publicly verifiable source for endpoints, hosts, and authentication in this guide
- [API Version Index (SwaggerHub)](https://app.swaggerhub.com/apis/abnormal-security/abx)

**Customer-Gated Documentation:**
- [Knowledge Base (customer portal)](https://abnormalsecurity.my.site.com/knowledgebase/s/) — the administrative documentation behind the portal console paths; requires a customer login
- [REST API Integration Guide](https://abnormalsecurity.my.site.com/knowledgebase/s/article/Abnormal-REST-API-Integration)

**Policy and Legal:**
- [Information Security Policy](https://legal.abnormalsecurity.com/legal-hub/abnormal-security-information-security-policy-19ee8b0f)
- [Legal Hub](https://legal.abnormalsecurity.com/)

**Compliance Artifacts (attestations, not hardening guidance):**
- SOC 2 Type 2, ISO 27001, ISO 27701, ISO 42001 — reports are requested through Abnormal's Trust Center at [abnormal.ai/trust-center](https://abnormal.ai/trust-center) and its NDA-gated [Security Hub](https://security.abnormal.ai/). These are evidence of the vendor's own program; they are not configuration documentation and are not used as sources for the controls above.
- [ISO 42001 Certification Announcement](https://abnormal.ai/blog/iso-42001-ai-certification)

**Threat Research:**
- [Threat Reports Library](https://abnormal.ai/resources/category/threat-reports)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | ai-drafted | Renamed vendor to Abnormal AI (legacy name retained on first use); rewrote 3.1 as API token hardening (Bearer token storage, vendor-recommended IP allowlisting, EU regional host, `GET /soar/tokens` inventory); added automated access-review steps to 2.1/2.2; added new sections 4 (Monitoring & Logging — audit log export) and 5 (Posture Management — SPM drift, tenant security settings, compromised-vendor cases, AI Security Mailbox governance), renumbering Compliance Quick Reference to 6; softened unverified portal menu paths in 1.1/2.1/3.1; merged duplicate Appendix A/B, promoted the OpenAPI spec (v1.4.1 → current v1.4.3) as the Tier 1 anchor and demoted Trust Center/Security Hub to a compliance-artifacts note. Most additions map previously unmapped API surface rather than post-June product changes. Tier 3/4 research sweep out of scope this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | ai-drafted | Initial guide with SSO and access controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
