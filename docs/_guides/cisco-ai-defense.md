---
layout: guide
title: "Cisco AI Defense Hardening Guide"
vendor: "Cisco AI Defense"
slug: "cisco-ai-defense"
tier: "1"
category: "Security"
description: "Harden the Cisco AI Defense Runtime management plane in Security Cloud Control."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden the Cisco AI Defense Runtime management plane in Security Cloud Control. Coverage concerns application connections, runtime guardrails, and administrative separation; not Cisco Secure Access, Cisco Umbrella, SDK behavior, or active model testing.

### Intended Audience

Tenant administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Establish the essential controls before production rollout.
- **L2 (Walk):** Stage the additional restrictions with a representative pilot and a recovery path.
- **L3 (Run):** Validate applicability, evidence retention, and approval requirements for regulated use.

### Scope

This guide addresses customer-controlled settings, not the vendor's internal service security. Feature availability depends on the contract and tenant. Settings were checked against documentation; no live tenant was tested or modified.

## Table of Contents

1. [Access and application coverage](#1-access-and-application-coverage)
2. [Guardrails and review](#2-guardrails-and-review)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Access and application coverage

### 1.1 Separate control-plane administration

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6 |

#### Description

Restrict AI Defense and Security Cloud Control administrative roles to approved users and groups. Separate management credentials from application inspection credentials.

#### Rationale

**Why This Matters:**

- An inspection integration should not possess a credential that administers the tenant.

#### Prerequisites

SCC organization admin, approved role matrix and tested recovery access.

#### ClickOps Implementation

1. Open the Security Cloud Control organization which owns the subscription and review user and admin group assignments.
2. Remove obsolete assignments after owner approval and reserve write-capable administration for named operators.
3. Use separate management and inspection credentials. Keep them in a secret manager and review holders before rotation.

#### Validation & Testing

Check each approved operator has only the necessary product access. Confirm the runtime app still uses its inspection credential after a management credential rotation.

#### Monitoring & Maintenance

Review role and credential owners on role changes and quarterly.

#### Operational Impact & Rollback

Restore only the affected role or keep the previous authorized token during a controlled credential cutover until verification passes.

**Sources:** [Cisco Security Cloud Control platform roles](https://developer.cisco.com/docs/security-cloud-control/). [Cisco management credentials and regional endpoints](https://developer.cisco.com/docs/ai-defense-management/getting-started/).

### 1.2 Reconcile runtime connections against approved applications

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-8, CA-7 |

#### Description

Inventory AI Defense Runtime connections and compare active or pending connections with the approved application inventory.

#### Rationale

**Why This Matters:**

- A disconnected, unregistered, or unintended connection can leave traffic unprotected or use the wrong data plane.

#### Prerequisites

Runtime application owners, production scope list, existing SaaS/private connector design.

#### ClickOps Implementation

1. In AI Defense Runtime, review Applications and their API or Gateway connections.
2. Record owner, environment, connection mode, and expected policy for each production application.
3. Investigate unexplained pending or disconnected entries and confirm planned connections before making changes.

#### Code Implementation

{% include pack-code.html vendor="cisco-ai-defense" section="1.2" %}

#### Validation & Testing

Compare the dashboard with the API sample. Trace one authorized staging request through the intended integration and check the associated application in Events if a policy event is expected.

#### Monitoring & Maintenance

Repeat after connector or model endpoint changes and track gaps against the application inventory.

#### Operational Impact & Rollback

Reinstate the previously approved connection if an approved change breaks a pilot workload; do not delete an unrecognized connection without ownership review.

**Sources:** [Cisco runtime setup demo](https://www.cisco.com/c/en/us/customer-success/video/demo/cisco-ai-defense-runtime.html). [Cisco AI Defense List Connections](https://developer.cisco.com/docs/ai-defense-management/list-connections/). [Cisco management credentials and regional endpoints](https://developer.cisco.com/docs/ai-defense-management/getting-started/).

## 2. Guardrails and review

### 2.1 Pilot guardrails and verify policy association

**Profile Level:** L2

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | SI-10, SI-4 |

#### Description

Configure runtime Security, Safety and Privacy guardrails suitable to the use case; assign the policy to the intended connections.

#### Rationale

**Why This Matters:**

- A policy object does not enforce anything on an unassociated connection; broad enforcement may cause disruptive false positives.

#### Prerequisites

Approved synthetic test inputs, known-good request corpus, staging connection and policy rollback owner.

#### ClickOps Implementation

1. Open Runtime policies and create or review a policy for the pilot application.
2. Set only the guardrails permitted for the workflow, using approved privacy and safety categories and the required action.
3. Associate the policy to the staging connection. Review results before any production rollout.

#### Validation & Testing

Check connection-to-policy association and observe the expected outcome on ordinary synthetic traffic that matches an approved privacy rule and on known-good requests. For API-based inspection verify the calling application handles the policy outcome as designed.

#### Monitoring & Maintenance

Review false positives and changed assignments before broadening scope.

#### Operational Impact & Rollback

Restore the previous connection policy and retest; do not globally disable Runtime to undo a single rule.

**Sources:** [Cisco runtime setup demo](https://www.cisco.com/c/en/us/customer-success/video/demo/cisco-ai-defense-runtime.html). [Cisco Management API release history](https://developer.cisco.com/docs/ai-defense-management/api-changelog/).

### 2.2 Review runtime events without exposing payloads

**Profile Level:** L2

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-6, SI-4 |

#### Description

Route review of runtime violations to a named SOC owner with defined evidence handling.

#### Rationale

**Why This Matters:**

- Detection without triage leaves policy gaps unresolved; raw event detail may contain sensitive information.

#### Prerequisites

Authorized event viewer, staging test and an approved destination for minimal incident metadata.

#### ClickOps Implementation

1. Open Runtime Events in the correct organization and select the pilot application and test window.
2. Review event outcome and connection for an approved synthetic privacy-rule test.
3. Define escalation and store only necessary event identifiers, timestamps, categories and outcomes.

#### Validation & Testing

A reviewed synthetic event is attributable to the correct application and rule; absence of an event on benign traffic is not a telemetry health test.

#### Monitoring & Maintenance

Track suspicious spikes, unknown event owners and last successful staging check.

#### Operational Impact & Rollback

Remove only the affected export or reviewer access if evidence handling is incorrect; preserve required logs.

**Sources:** [Cisco runtime setup demo](https://www.cisco.com/c/en/us/customer-success/video/demo/cisco-ai-defense-runtime.html). [Management API overview](https://developer.cisco.com/docs/ai-defense-management/overview/).

## 3. Compliance Quick Reference

These are thematic NIST mappings, not a benchmark, certification, or evidence of implementation.

| Control | NIST SP 800-53 Rev. 5 |
|---|---|
| 1.1 Separate control-plane administration | AC-2, AC-6 |
| 1.2 Reconcile runtime connections against approved applications | CM-8, CA-7 |
| 2.1 Pilot guardrails and verify policy association | SI-10, SI-4 |
| 2.2 Review runtime events without exposing payloads | AU-6, SI-4 |

## Appendix A: Automation and applicability

The pack reads only a single page of management connection metadata; it does not call Inspection, retrieve payloads, run validation or change policies. Verify the exact regional organization and use the tenant management API key, not a connection inspection key.

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial tenant hardening controls and read-only verification | How to Harden Community |

## Contributing

Submit corrections and sanitized verification evidence through [GitHub](https://github.com/grcengineering/how-to-harden). Never attach tenant exports or secrets.
