---
layout: guide
title: "Assembled Workforce Management Hardening Guide"
vendor: "Assembled Workforce Management"
slug: "assembled-wfm"
platform: "Assembled"
platform_slug: "assembled"
product: "Workforce Management"
tier: "2"
category: "Productivity"
description: "Restrict Assembled WFM BPO access, reports, schedules, exports and Chrome tracking; collect documented schedule-change evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-16"
---

This is a product guide within the [Assembled platform](/guides/assembled/). Apply the hub's identity, API and integration controls first.

## Overview

Workforce Management contains staff schedules, attendance/performance data and BPO planning. Its important boundaries are whose records people can see, what they can change, and where workforce data is exported. BPO management is covered here because it uses WFM sites, roles and scheduling data rather than a separate identity plane.

### Intended Audience

- WFM and BPO administrators
- Security engineers managing workforce-data access
- Report and audit evidence owners

### How to Use This Guide

L1 (Crawl) restricts everyday data and schedule access. L2 (Walk) adds export governance, tracking minimization and schedule-change review. Use named test users in separate sites before broad rollout.

### Scope

WFM console, BPO/site data boundaries, Google Sheets exports, Chrome website tracking and scheduling history. Native role and SSO policy is inherited from the hub. Schedule forecasts, staffing mathematics and generic infrastructure hardening are outside scope.

**Validation boundary:** Documentation and offline fixtures only; no tenant or credentials were supplied. Console paths were not walked in a customer account, and API/SDK/SIEM packs were not exercised against a live deployment. See the [source coverage and validation ledger](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/assembled-source-coverage.md) and [maturity definitions](https://github.com/grcengineering/how-to-harden/blob/main/VERSIONS.md#maturity-statuses--the-matrix).

## Table of Contents

1. [Access Controls](#1-access-controls)
2. [Data & Integration Security](#2-data--integration-security)
3. [Monitoring & Detection](#3-monitoring--detection)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

## 1. Access Controls

### 1.1 Isolate BPO and Site Access

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-3 |

#### Description

Combine least-privilege roles with Restricted sites for external workforce populations. Ordinary site filters are not an authorization boundary.

#### Rationale

**Why This Matters:**

- BPO supervisors should not see another supplier’s people.
- Site restrictions govern data scope while the role governs permitted actions.

**Attack Prevented:** Cross-BPO workforce-data disclosure and unauthorized approvals.

#### Prerequisites

An Assembled administrator; test accounts with the affected roles.

#### ClickOps Implementation

1. Create the needed sites in **Configure > Attributes > Sites**.
2. Open **Manage team > People management > [person]** and set **Site** where applicable. In **Restricted sites**, select every allowed site, then **Save changes**.
3. For a parent site include its child sites explicitly. Keep an unrestricted administrator for recovery; do not restrict your own admin account as a trial.

Source: [Restricted sites](https://support.assembled.com/hc/en-us/articles/17167908394125-Restricted-sites) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([Restricted sites](https://support.assembled.com/hc/en-us/articles/17167908394125-Restricted-sites), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. Sign in as a BPO test user and check Staffing timeline, People management, scorecards and Schedule requests. Other sites must stay inaccessible when changing filters or links.
2. Check aggregate/forecast pages separately. Restricted users lose access to some non-site-filterable data by default; support can change that behavior. Confirm your tenant has no unintended exception.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

An account restricted to sites cannot remove its own restriction; an unrestricted person must restore access. These limits do not constrain inbound MCP access granted through the hub control.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

### 1.2 Restrict Reports by Team and Queue

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-3 |

#### Description

Use role-level report filters so viewers can inspect only their assigned teams or queues. This restriction applies to reports, not all Assembled pages.

#### Rationale

**Why This Matters:**

- Performance reports expose individual workforce information.
- A report filter must not be mistaken for a company-wide data boundary.

**Attack Prevented:** Excessive visibility into other teams’ performance data.

#### Prerequisites

Role administrator; Pro or Enterprise for custom roles; correct profile queue/team assignments.

#### ClickOps Implementation

1. Open **Manage team > Roles and permissions > [role] > Report > All reports**.
2. Under **Data access filter restrictions for all reports**, choose **Restrict reports data access**. Enable **Restrict access by queues**, **Restrict access by teams**, or both, then **Save changes**.

Source: [Roles and permissions](https://support.assembled.com/hc/en-us/articles/4414692774285-Roles-and-permissions) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([Roles and permissions](https://support.assembled.com/hc/en-us/articles/4414692774285-Roles-and-permissions), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. With a test viewer, try a report for an unassigned queue/team and verify it is unavailable.
2. Test Staffing timeline and MCP separately; report restrictions do not configure those surfaces.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

Test with the affected team before rollout. Record the prior setting and restore it through the same documented path if the change blocks approved work.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

### 1.3 Separate Schedule Editing and Publishing Duties

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Limit who can change schedules, publish them, restore historical versions or upload schedule data. Use per-event permissions where different event types need different approval paths.

#### Rationale

**Why This Matters:**

- Unrestricted schedule writes can disrupt staffing or alter sensitive absence records.
- Publishing and restore permissions can affect many people at once.

**Attack Prevented:** Unauthorized schedule changes and bulk operational disruption.

#### Prerequisites

An Assembled administrator; test accounts with the affected roles.

#### ClickOps Implementation

1. Open **Manage team > Roles and permissions > [role] > Schedule**.
2. Review **Edit schedules** and **Publish schedules**. Where needed, choose **Can edit schedules with custom permissions** and assign **Can edit**, **Can request changes**, or **Has no edit access** per event type.
3. Restrict **Restore schedules**, **Schedule uploads** and **Apply templates** to approved operators, and save changes.

Source: [Roles and permissions](https://support.assembled.com/hc/en-us/articles/4414692774285-Roles-and-permissions) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([Roles and permissions](https://support.assembled.com/hc/en-us/articles/4414692774285-Roles-and-permissions), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. Verify a basic user can request an approved event change without directly publishing it.
2. Verify unauthorized users cannot bulk upload, restore or publish schedules. Keep a known-good history reference for recovery.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

Narrow permissions can slow urgent staffing edits. Provide an approved escalation path. Restoring a historical version can revert multiple people and later changes; inspect its scope first.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

## 2. Data & Integration Security

### 2.1 Constrain Recurring Google Sheets Exports

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-3 |

#### Description

Keep workforce exports in dedicated restricted destinations and remove unused recurring exports. Sharing an export folder with the Assembled service identity grants Editor access to that destination.

#### Rationale

**Why This Matters:**

- Exports create another copy outside WFM access controls.
- A recurring job can continue disclosing data after its original need ends.

**Attack Prevented:** Persistent workforce-data exposure through shared spreadsheets.

#### Prerequisites

An Assembled administrator; test accounts with the affected roles.

#### ClickOps Implementation

1. On **Report > Team performance**, **Report > Support volume > Forecasted vs actual**, or **Report > BPO billing**, inspect the report filters and required export scope.
2. Use a dedicated destination folder or spreadsheet in Drive with a restricted reader list. Share only that destination with **cal@assembledhq.com** as Editor when a supported export is needed.
3. Open **Configure > Third-party integrations > Google Sheets > Edit recurring exports**. Use each job’s options menu to **Pause** or **Delete** jobs whose purpose or destination is no longer approved.

Source: [Google Sheets exports](https://support.assembled.com/hc/en-us/articles/27204929306381-Google-Sheets-exports) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([Google Sheets exports](https://support.assembled.com/hc/en-us/articles/27204929306381-Google-Sheets-exports), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. Inspect the spreadsheet’s actual sharing ACL and exported rows; WFM permissions do not govern the copied data.
2. Confirm a paused/deleted job stops future updates and handle already-exported copies under the destination retention policy.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

Pausing a recurring export affects downstream reporting. The public API does not document management of these jobs; do not create guessed export endpoints.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

### 2.2 Minimize Chrome Website Tracking

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Enable website tracking only for an approved workforce use case and keep its approved-site list narrow. The feature tracks active website addresses for adherence rather than specific page paths.

#### Rationale

**Why This Matters:**

- Tracking expands the workforce data collected by the browser extension.
- Overbroad productive-site mappings can distort adherence evidence.

**Attack Prevented:** Excessive employee activity collection and misleading activity attribution.

#### Prerequisites

Admin for approved-site changes, extension installed only for approved users, and applicable employee privacy authorization.

#### ClickOps Implementation

1. In **Configure > Third-party integrations**, inspect the **Assembled Chrome extension** card and its **Track approved websites** switch. Turn it off if tracking is not approved.
2. When approved, use **Configure > Agent states > Track website** to add only the required website addresses and review their mappings through **Edit agent state mappings**.
3. Treat subdomains separately. Do not duplicate contact-platform websites that already provide their own more specific agent states.

Source: [Website tracking with the Assembled Chrome extension](https://support.assembled.com/hc/en-us/articles/42088963628045-Website-tracking-with-the-Assembled-Chrome-extension) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([Website tracking with the Assembled Chrome extension](https://support.assembled.com/hc/en-us/articles/42088963628045-Website-tracking-with-the-Assembled-Chrome-extension), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. Confirm unapproved websites appear as **Untracked website**, with no page-path collection claimed by this feature.
2. After editing the site list, test new activity; historic state/adherence data does not change.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

Test with the affected team before rollout. Record the prior setting and restore it through the same documented path if the change blocks approved work.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

## 3. Monitoring & Detection

### 3.1 Collect and Review Scheduling History

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AU-6 |

#### Description

Review who changed schedules and collect the documented event-change feed for retained evidence. This is a schedule audit feed, not a tenant-wide authentication or administrative audit stream.

#### Rationale

**Why This Matters:**

- Unexpected bulk schedule changes can disrupt service or conceal earlier edits.
- Independent retention helps reviewers compare operational changes with approvals.

**Attack Prevented:** Undetected schedule tampering and unapproved bulk updates.

#### Prerequisites

An Assembled administrator; test accounts with the affected roles.

#### ClickOps Implementation

1. Open **Schedule > Staffing timeline > More actions** (caret beside **Configure staffing**) **> Scheduling history**.
2. Select an entry and inspect affected people, events and actor. Use the history for review; do not select restore during an audit.
3. Send suspicious changes to the schedule owner for comparison with approved templates, imports and staffing operations.

Source: [Scheduling history](https://support.assembled.com/hc/en-us/articles/46702243244941-Scheduling-history) (checked 2026-11-16).

#### Code Implementation

The read-only collector calls paginated **GET /v0/event_changes** with `ASSEMBLED_START_TIME` and `ASSEMBLED_END_TIME` in Unix seconds (at most 31 days per run). It emits NDJSON containing event ID, modification time, actor ID and change type, omitting names, email addresses and free-text descriptions. Redirect output into a private temporary file and atomically promote it only after exit 0. It requires the sibling `packs/assembled/api/common.py`; download the full pack tree. The SIEM pack runs in Splunk after ingestion, not in Assembled.

{% include pack-code.html vendor="assembled-wfm" section="3.1" %}

#### Validation & Testing

1. Make a harmless approved schedule edit in a test environment and compare its actor/time with the history and API collection.
2. Collect overlapping time windows and deduplicate on event-change `id`. Store output privately and retain a checkpoint only after successful complete collection.
3. The Splunk query requires your own ingestion of the collector NDJSON under `assembled:event_changes`, with event timestamps extracted from numeric `modified_at` and a search time range that includes the collected window. Tune the example threshold of 25 changes per actor per five minutes; legitimate template/bulk work also matches.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

Exports can contain sensitive actor identifiers. A malformed page or changing total fails the collection without a partial report. Empty output with exit 0 means no changes returned for the requested window, not that other audit surfaces were quiet.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

## 7. Compliance Quick Reference

These are implementation evidence mappings, not a product certification or an assertion of compliance. No Assembled-specific CIS Benchmark, DISA STIG, SCuBA, NSA, or ACSC baseline was found in the bounded searches recorded in the ledger; benchmark coverage remains unverified. SOC 2 and ISO mappings above are thematic, without invented numbered requirements.

| NIST SP 800-53 Rev. 5 area | Evidence in this guide |
|--------------------------|------------------------|
| AC-2, AC-3, AC-6 | Approved identities, roles, data access and integration privileges where applicable |
| IA-2, AC-12 | Authentication and session controls where applicable |
| AU-6, CM-3, SI-12 | Audit review, change control and retention where applicable |

## Appendix A: Edition and Feature Compatibility

| Capability | Documented availability |
|------------|-------------------------|
| Custom roles | Pro or Enterprise |
| BPO planning and BPO billing | BPO management, separately billed |
| Google Sheets exports | Permissions differ by report; BPO billing needs BPO management |
| Chrome website tracking | Admin-managed; Chrome extension and user profile required |
| Schedule-change REST feed | API key required; API plan entitlement not specified in reference |


## Appendix B: References

- [Restricted sites](https://support.assembled.com/hc/en-us/articles/17167908394125-Restricted-sites)
- [Roles and permissions](https://support.assembled.com/hc/en-us/articles/4414692774285-Roles-and-permissions)
- [Google Sheets exports](https://support.assembled.com/hc/en-us/articles/27204929306381-Google-Sheets-exports)
- [Website tracking with the Assembled Chrome extension](https://support.assembled.com/hc/en-us/articles/42088963628045-Website-tracking-with-the-Assembled-Chrome-extension)
- [Scheduling history](https://support.assembled.com/hc/en-us/articles/46702243244941-Scheduling-history)
- [Event changes API](https://docs.assembled.com/#event-changes)

- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)
- [Research boundary and validation results](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/assembled-source-coverage.md)

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-16 | 0.1.0 | ai-drafted | Initial WFM/BPO access, export and tracking controls; schedule collector and Splunk detection | Codex (GPT-6) |

## Contributing

Report outdated paths or product behavior through [GitHub issues](https://github.com/grcengineering/how-to-harden/issues). Propose corrections using the [contribution guidelines](https://github.com/grcengineering/how-to-harden/blob/main/CONTRIBUTING.md). Do not attach credentials or customer data to a public issue.
