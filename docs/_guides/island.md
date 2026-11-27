---
layout: guide
title: "Island Enterprise Browser Hardening Guide"
vendor: "Island Enterprise Browser"
slug: "island"
tier: "1"
category: "Security"
description: "Island Enterprise Browser applies customer-managed policy inside supported browser sessions."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Island Enterprise Browser applies customer-managed policy inside supported browser sessions. Its browser controls do not automatically prevent direct API access or access from other clients.

### Intended Audience

Tenant administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Establish the essential controls before production rollout.
- **L2 (Walk):** Stage the additional restrictions with a representative pilot and a recovery path.
- **L3 (Run):** Validate applicability, evidence retention, and approval requirements for regulated use.

### Scope

This guide addresses customer-controlled settings, not the vendor's internal service security. Feature availability depends on the contract and tenant. Settings were checked against documentation; no live tenant was tested or modified.

## Table of Contents

1. [Identity and lifecycle](#1-identity-and-lifecycle)
2. [Session boundaries and audit](#2-session-boundaries-and-audit)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Identity and lifecycle

### 1.1 Scope federated access to approved groups

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-2, IA-8 |

#### Description

Federate the Enterprise Browser to the approved IdP and use a pilot population before broader deployment. Enforce your organization’s multifactor policy at the IdP rather than inferring it from successful federation.

#### Rationale

**Why This Matters:**

- An unscoped application assignment can defeat otherwise narrow browser policy. Just-in-time creation means a successful sign-in may provision an account.

#### Prerequisites

Island Admin, Entra app configuration permissions, expected tenant identifiers and a reviewed recovery path.

#### ClickOps Implementation

1. Add the **Island** gallery app in **Entra ID > Enterprise apps**. Assign approved pilot users/groups.
2. Open **Single sign-on > SAML**, use the actual metadata for your Island tenant, and verify the persistent identifier mapping against the vendor-supported configuration.
3. Follow the vendor-side onboarding procedure documented by Microsoft; do not reuse sample identifiers or send private keys.

**Automation:** An exact public Island SAML configuration API was not verified.

#### Validation & Testing

Verify approved sign-in with a fresh test session and check that an unassigned identity cannot get access in the intended configuration. Review IdP MFA results and Island JIT behavior separately.

#### Monitoring & Maintenance

Review access groups, signing certificate expiry and local recovery access regularly.

#### Operational Impact & Rollback

Restore the prior trusted metadata from the tested recovery path if federated access fails during rollout.

**Sources:** [Entra and Island SAML configuration](https://learn.microsoft.com/en-us/entra/identity/saas-apps/island-tutorial).

### 1.2 Test automated offboarding before broad provisioning

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6 |

#### Description

Use scoped user/group provisioning to disable access for removed users. Coordinate tenant setup with Island; do not assume switching on SCIM replaces JIT or kills all existing sessions.

#### Rationale

**Why This Matters:**

- Users removed from the source directory can retain access if provisioning is unhealthy, incorrectly scoped or blocked by accidental-deletion protection.

#### Prerequisites

Island Admin, eligible Entra administrator, actual Island tenant URL/token, and one reversible test identity.

#### ClickOps Implementation

1. In **Entra ID > Enterprise apps > Island > Provisioning**, create a pilot configuration with the Island tenant URL and secret obtained through the supported setup.
2. Select **Test Connection**, scope to the pilot assignments, and enable failure notifications and accidental-deletion prevention. Verify user and group mappings.
3. Use on-demand provisioning before starting wider sync.

**Automation:** The configured Entra provisioning flow is supported; a portable Island management-policy mutation pack was not verified.

#### Validation & Testing

Provision and then remove a pilot assignment. Confirm the result in Entra provisioning logs and Island. Separately validate new sign-in, active sessions and any non-federated routes.

#### Monitoring & Maintenance

Check provisioning errors and quarantine status; reconcile pending removals promptly.

#### Operational Impact & Rollback

Pause a mis-scoped job, reconcile actual target account changes and restore only approved users. Do not broadly disable deletion protection.

**Sources:** [Documented Island provisioning workflow](https://learn.microsoft.com/en-us/entra/identity/saas-apps/island-provisioning-tutorial).

## 2. Session boundaries and audit

### 2.1 Review last-mile rules for sensitive destinations

**Profile Level:** L2 (Walk)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-3, AC-4 |

#### Description

Limit actions such as copy/paste, downloads, uploads and capture according to the application and approved device/user contexts. Keep application-layer access controls rather than relying on browser-only policy.

#### Rationale

**Why This Matters:**

- A least-privilege session can reduce accidental exposure during sensitive SaaS access, but only on the paths where the browser policy actually applies.

#### Prerequisites

Management Console access, sensitive-app inventory, representative device and role contexts, and synthetic test content.

#### ClickOps Implementation

1. In Island Management Console locate the policies for a selected sensitive destination. Use the current tenant’s policy editor and vendor documentation to confirm the controls available; exact menu labels were not independently verified.
2. Define explicit permitted actions for the user and device context. Restrict data transfer to personal destinations and pilot allowed workflows before broader deployment.
3. Document alternative clients and apply independent SaaS/IdP controls where browser restrictions cannot apply.

**Automation:** Public Island descriptions substantiate these control capabilities, not exact tenant API schema or click paths.

#### Validation & Testing

Test with benign synthetic data as an approved pilot. Confirm required work remains possible and that the browser blocks the prohibited action for the intended destination. Verify a separately approved client path is not mistakenly counted as covered.

#### Monitoring & Maintenance

Review exceptions, client coverage, and policy ordering after application or device changes.

#### Operational Impact & Rollback

Restrict rollback to the specific rule and audience; confirm other browser and source-app protections remain in effect.

**Sources:** [Island last-mile policy and event capabilities](https://www.island.io/resource/using-your-browser-as-an-auditing-support-tool). [Island session policy context](https://www.island.io/article/least-privilege-browser-policy).

### 2.2 Verify browser and administrator events arrive at the SIEM

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-2, AU-6, AU-9 |

#### Description

Route the minimum allowed user and administrative audit data through an approved integration. Verify expected events and lag without printing user identifiers or event content by default.

#### Rationale

**Why This Matters:**

- Without a connected audit pipeline, a quiet search can be mistaken for absence of control drift.

#### Prerequisites

Island Management Console admin, approved data flow, separate restricted Splunk index for Island logs, and Island’s compatible Splunk add-on.

#### ClickOps Implementation

1. Use the Island Management Console’s audit views to confirm a known event. If using Splunk, set up Island’s published add-on under the approved tenant integration procedure and confirm the destination index and the event stream.
2. Generate benign, distinguishable pilot user and admin events and compare the destination into which they arrive.
3. Restrict access and retention for user activity; only export the event types needed.

#### Code Implementation

{% include pack-code.html vendor="island" section="2.2" %}

#### Validation & Testing

Replace the sample index name in the pack with the dedicated Island index confirmed locally. Compare event count and latest time against the pilot and Management Console. Inspect separate stream coverage where expected; this aggregate does not prove every event arrived.

#### Monitoring & Maintenance

Alert on missing expected events or excessive ingestion lag. Periodically recheck scope, retention and privilege.

#### Operational Impact & Rollback

The pack is a read-only aggregate. If export is misrouted, repair or pause the connector without deleting underlying audit evidence.

**Sources:** [Island-published Splunk add-on](https://splunkbase.splunk.com/app/6336). [Island audit capability](https://www.island.io/resource/using-your-browser-as-an-auditing-support-tool).

## 3. Compliance Quick Reference

These are thematic NIST mappings, not a benchmark, certification, or evidence of implementation.

| Control | NIST SP 800-53 Rev. 5 |
|---|---|
| 1.1 Scope federated access to approved groups | AC-2, IA-8 |
| 1.2 Test automated offboarding before broad provisioning | AC-2, AC-6 |
| 2.1 Review last-mile rules for sensitive destinations | AC-3, AC-4 |
| 2.2 Verify browser and administrator events arrive at the SIEM | AU-2, AU-6, AU-9 |

## Appendix A: Automation and applicability

The SPL pack queries an operator-confirmed dedicated Splunk index; it assumes no vendor default index, sourcetype, or private API. Island documents management and log API availability, but public exact tenant route/schema, first-party CLI/SDK, Terraform provider and GraphQL were not verified. Management Console, extension and mobile/desktop client parity are not assumed. No Island-specific CIS, STIG or SCuBA control was established.

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial tenant hardening controls and read-only verification | How to Harden Community |

## Contributing

Submit corrections and sanitized verification evidence through [GitHub](https://github.com/grcengineering/how-to-harden). Never attach tenant exports or secrets.
