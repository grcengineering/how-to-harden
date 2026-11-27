---
layout: guide
title: "Make Hardening Guide"
vendor: "Make"
slug: "make"
tier: "3"
category: "Productivity"
description: "Make workflows connect accounts, credentials and sensitive execution data"
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

**Product Editions Covered:** Make.com production organizations; Enterprise-only controls are labeled

## Overview

Make workflows connect accounts, credentials and sensitive execution data. Configure identity centrally, review what a scenario publishes, and verify that audit data can be read without exporting unnecessary details.

### Intended Audience

Platform administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Baseline controls for the documented deployment.
- **L2 (Walk):** Add verified controls where the workload needs stronger isolation.
- **L3 (Run):** Add controls warranted by higher-risk workflows and contractual requirements.

### Scope

Covers Make.com EU1/EU2/US1/US2 production organizations and documented setup. Code packs intentionally exclude Celonis OEM zones and custom deployment domains.

---

## Table of Contents

1. [Identity](#1-identity)
2. [Scenario Data and Public Exposure](#2-scenario-data-and-public-exposure)
3. [Monitoring](#3-monitoring)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

---

## 1. Identity

### 1.1 Use enterprise single sign-on and verified domain enrollment

**Profile Level:** L1 (Crawl)

#### Description

Set up Enterprise SSO with an approved IdP; claim the corporate domain where users must be routed to enterprise enrollment.

#### Rationale

- A claimed domain steers associated sign-in and registration to SSO. It does not prove the effective permissions assigned to an existing or newly provisioned user.

#### Prerequisites

Enterprise organization admin, IdP and DNS owners, approved namespace and recovery.

#### ClickOps Implementation

1. In **Organization → SSO**, configure the approved SAML or OIDC identity provider and test it with a pilot.
2. Follow Make’s documented domain claim procedure, publish the provided DNS verification record with the domain owner, and verify the domain. Review default team and role provisioning before enabling it.

Source: [Vendor configuration reference](https://help.make.com/single-sign-on).

#### Code Implementation

Domain claim and SSO policy require Console/IdP evidence; no automated configuration is included.

#### Validation & Testing

Test sign-in with an assigned pilot and verify a new approved corporate test identity follows the expected enterprise path. Check role mappings and non-SSO exceptions separately.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Unintended assignments or authentication failures can lock users out or grant initial access to a broad team.

#### Rollback Procedure

Use the approved identity recovery path; revert only the intended SSO mapping or domain change after recording impact.

---

## 2. Scenario Data and Public Exposure

### 2.1 Turn off public sharing for internal scenarios

**Profile Level:** L1 (Crawl)

#### Description

Disable Public scenario page for internal or sensitive workflows. Review dormant scenarios as well as active ones.

#### Rationale

- Anyone with a public link can view and copy a scenario. Turning off public sharing does not retrieve copies already made and turning it back on can reuse the prior URL.

#### Prerequisites

Scenario owner and reviewer, disclosure policy and synthetic scenario.

#### ClickOps Implementation

1. Open the intended scenario in Scenario Builder, choose **Share**, then turn off **Public scenario page**.
2. Inventory active and inactive scenarios and review approved public exceptions individually. Review exposed data separately if a link was previously public.

Source: [Vendor configuration reference](https://help.make.com/scenario-sharing).

#### Code Implementation

The API pack returns the first 25 active scenarios and lists any ID with isShared set. The official CLI alternative lists one selected team and filters available response fields without printing names or blueprints. Verify coverage and the actual toggle in the Console.

{% include pack-code.html vendor="make" section="2.1" %}

#### Validation & Testing

Verify the previously known synthetic public URL is no longer accessible anonymously. Compare inventory candidates to the Console toggle; do not infer an organization is compliant from a partial result.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

External links stop serving the scenario. Existing recipient copies may persist.

#### Rollback Procedure

Re-enable public display only under explicit publication approval; do not assume it generates a new link.

---
### 2.2 Keep sensitive execution payloads out of run logs

**Profile Level:** L2 (Walk)

#### Description

Enable Keep data confidential for scenarios processing approved sensitive categories where troubleshooting can work without raw payloads.

#### Rationale

- Make describes withholding processed data from execution logs when enabled. This is distinct from payload handling in connections, destination apps or incomplete executions.

#### Prerequisites

Scenario owner, synthetic input, downstream troubleshooting plan and change approval.

#### ClickOps Implementation

1. Open the scenario gear menu → **Scenario settings**. Enable **Keep data confidential**.
2. Review incomplete execution storage, webhooks and downstream app logging independently.

Source: [Vendor configuration reference](https://help.make.com/scenario-settings).

#### Code Implementation

Use Console and synthetic runtime verification. No inferred blueprint setting is used.

#### Validation & Testing

Run a benign synthetic record. Confirm a run entry exists but its execution log does not contain payloads; confirm intended workflow outcome separately.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Debugging execution issues is more limited. The setting is not evidence that earlier payloads were removed.

#### Rollback Procedure

Restore payload visibility only with approved retention and privacy review during a bounded debugging window.

---

## 3. Monitoring

### 3.1 Review enterprise organization audit events

**Profile Level:** L2 (Walk)

#### Description

Review sensitive changes to scenarios, connections, keys and roles using Make Enterprise audit logs. Use a dedicated scope-limited token for automated sampling.

#### Rationale

- Scenario runtime history is not an administrative audit log. A successful audit API sample does not prove completeness or access to all detail fields.

#### Prerequisites

Enterprise audit entitlement, organization Owner or Admin approved for audit access, and an API token scoped to `audit-logs:read`.

#### ClickOps Implementation

1. Go to the organization dashboard and open **Audit Logs**. Confirm an approved synthetic scenario or settings change appears with the intended scope.
2. Where automation is needed, create a dedicated token with the current v2 scope for the correct production zone and organization.

Source: [Vendor configuration reference](https://help.make.com/audit-logs).

#### Code Implementation

Use the v2 organization audit endpoint, not the deprecated organization audit route. The pack reports only event-type counts; it does not export actor details or follow cursors.

{% include pack-code.html vendor="make" section="3.1" %}

#### Validation & Testing

Check the expected synthetic event and timestamp in the Console; the pack emits category counts from up to 20 recent visible events. An empty response is not a configuration pass.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Audit records can include actors and detail. Avoid retaining unnecessary content; expired credentials can interrupt audit collection.

#### Rollback Procedure

Rotate or revoke unused tokens and restore collection only with an appropriately scoped replacement.

---

## 4. Compliance Quick Reference

These mappings indicate how settings can contribute to a control objective; they do not establish conformity or operation over a period.

| HTH control | NIST SP 800-53 Rev. 5 | Evidence to retain |
| --- | --- | --- |
| 1.1 | IA-2, AC-2 | SSO test and verified domain |
| 2.1 | AC-3 | Sharing toggle and formerly public synthetic URL |
| 2.2 | AU-9 | Synthetic run payload absence |
| 3.1 | AU-2, AU-6 | Approved audit event and scope |

## Appendix A: Automation and Evidence

The Make API scripts default to read-only and never run a scenario. Restrict each token to its endpoint scope and correct tenant role. The official make-cli support here is limited to a scenario inventory, not Enterprise SSO or audit v2 enforcement. No live Make account was used.

## Appendix B: References

- [SSO domain claim](https://help.make.com/domain-claim)
- [Scenario list API](https://developers.make.com/api-documentation/api-reference/scenarios.md)
- [Audit Logs API v2](https://developers.make.com/api-documentation/api-reference/audit-logs.md)
- [Official Make CLI](https://developers.make.com/make-cli)
- [Organization roles](https://help.make.com/organizations)

## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial platform controls and documented verification packs | How to Harden Community |

## Contributing

Report inaccurate or outdated guidance through the [issue tracker](https://github.com/grcengineering/how-to-harden/issues).
