---
layout: guide
title: "Armis Centrix Hardening Guide"
vendor: "Armis Centrix"
slug: "armis-centrix"
tier: "1"
category: "Security"
description: "Harden the standalone Armis Centrix cyber exposure management tenant."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden the standalone Armis Centrix cyber exposure management tenant. ServiceNow completed its Armis acquisition in April 2026 and said Centrix remains available standalone; this does not cover ServiceNow instance configuration, third-party enforcement systems, or safety-critical assets.

### Intended Audience

Tenant administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Establish the essential controls before production rollout.
- **L2 (Walk):** Stage the additional restrictions with a representative pilot and a recovery path.
- **L3 (Run):** Validate applicability, evidence retention, and approval requirements for regulated use.

### Scope

This guide addresses customer-controlled settings, not the vendor's internal service security. Feature availability depends on the contract and tenant. Settings were checked against documentation; no live tenant was tested or modified.

## Table of Contents

1. [API access and integrations](#1-api-access-and-integrations)
2. [Detection policy and response](#2-detection-policy-and-response)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. API access and integrations

### 1.1 Constrain authentication and API scopes

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6, IA-5 |

#### Description

Use approved tenant credentials with v3 OAuth client credentials and the narrowest required scopes for automation.

#### Rationale

**Why This Matters:**

- A long-lived secret can mint bearer tokens; an integration that only reads should not be able to edit policies or integrations.

#### Prerequisites

Centrix tenant credentials and app owner; developer Vendor ID and approved secret store where required.

#### ClickOps Implementation

1. Open Settings > API Management in the Centrix tenant and reconcile existing keys to owners and operational purpose.
2. Separate monitoring credentials from configuration credentials and request only endpoint-specific OAuth scopes.
3. Rotate approved legacy credentials in stages and revoke the previous credential after dependent services are confirmed healthy.

#### Validation & Testing

Confirm the audit identity can perform its documented read using only the intended scope; validate write scopes are not granted without invoking a write.

#### Monitoring & Maintenance

Record credential owners and review access at least quarterly and on staff or vendor changes.

#### Operational Impact & Rollback

If a rotation breaks coverage, restore only the approved integration credential via the documented runbook while arranging replacement.

**Sources:** [Armis API v3 authentication](https://dev.armis.com/docs/authentication). [Armis API lifecycle FAQ](https://dev.armis.com/docs/faq).

### 1.2 Review integration health and collection scope

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-8, SI-4 |

#### Description

Reconcile third-party connections, their collector or broker assignment, and last successful collection.

#### Rationale

**Why This Matters:**

- An active connector can still be failing or collect from an unintended source.

#### Prerequisites

Connector inventory and responsible system owners; optional PERMISSION.SETTINGS.INTEGRATION.READ scope.

#### ClickOps Implementation

1. In Centrix, open the integrations inventory and select configured entries, not just the integration catalog.
2. Compare expected integrations against source identities, filters and associated collectors or brokers.
3. Investigate ERROR, WARNING or unexpectedly paused integrations; confirm that source-system credentials have only necessary privileges.

#### Validation & Testing

Review the last successful cycle for a representative integration and reconcile records in the intended source segment without copying raw asset details.

#### Monitoring & Maintenance

Review health state and last successful collection against per-integration freshness objectives.

#### Operational Impact & Rollback

Restore known-good filters and collector assignment for only the affected integration; verify duplicate records and coverage do not regress.

**Sources:** [Armis Integration Management](https://dev.armis.com/docs/integration-management).

## 2. Detection policy and response

### 2.1 Check visibility of required detection policies

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-6, SI-4 |

#### Description

Review Centrix policies and ensure required policies are enabled in the correct scope.

#### Rationale

**Why This Matters:**

- An enabled policy alone does not prove it detects the intended behavior or routes alerts to the correct owner.

#### Prerequisites

Policy inventory, SOC ownership, and a bearer token with PERMISSION.POLICY.READ for the optional sample.

#### ClickOps Implementation

1. Open the Centrix Policies workspace and identify the approved policy or appropriate Policies Library template.
2. Review enabled status, condition, sensor scope, schedule and alert severity against the approved baseline.
3. Use alert-only behavior for new pilot policies until evidence and operational ownership are confirmed.

#### Code Implementation

{% include pack-code.html vendor="armis-centrix" section="2.1" %}

#### Validation & Testing

Review policy evidence and a known historical benign or approved staging alert for the intended scope. The pack reports only the counts and cursor presence for the first page.

#### Monitoring & Maintenance

Reconcile policy changes and alerts with an assigned service owner, especially after a collector change.

#### Operational Impact & Rollback

Restore prior policy conditions or switch the affected pilot policy back to alert-only.

**Sources:** [Armis Policy Management](https://dev.armis.com/docs/policy-management). [Armis policy UI example](https://media.armis.com/wp-operationalizing_the-vulnerability-remediation-lifecycle-en.pdf).

### 2.2 Require review before disruptive policy actions

**Profile Level:** L2

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-5, CM-3 |

#### Description

Keep action mode and external enforcement changes behind documented operational approval.

#### Rationale

**Why This Matters:**

- Isolation and other actions can interrupt essential services; review conditions and downstream integrations before enabling them.

#### Prerequisites

Change approval process, asset owner, operational safety review, and a documented recovery owner.

#### ClickOps Implementation

1. Identify Centrix policy actions and any integration used for downstream enforcement.
2. Keep experimental actions alert-only and verify output with approved historical or synthetic events.
3. Require explicit per-scope approval before promoting an action that could affect live assets; verify alert targeting and rollback ownership first.

#### Validation & Testing

Review recorded approval, matched asset ownership and recovery readiness. Do not exercise isolation or other disruptive actions on production or safety-critical systems.

#### Monitoring & Maintenance

Track action ownership and approved exceptions, and reevaluate after scope or integration changes.

#### Operational Impact & Rollback

Disable only the affected disruptive action with the authorized owner and use the downstream product’s approved recovery runbook if needed.

**Sources:** [Armis Policy Management](https://dev.armis.com/docs/policy-management). [Armis Integration Management](https://dev.armis.com/docs/integration-management).

## 3. Compliance Quick Reference

These are thematic NIST mappings, not a benchmark, certification, or evidence of implementation.

| Control | NIST SP 800-53 Rev. 5 |
|---|---|
| 1.1 Constrain authentication and API scopes | AC-2, AC-6, IA-5 |
| 1.2 Review integration health and collection scope | CM-8, SI-4 |
| 2.1 Check visibility of required detection policies | AU-6, SI-4 |
| 2.2 Require review before disruptive policy actions | AC-5, CM-3 |

## Appendix A: Automation and applicability

Scope is standalone Centrix after the ServiceNow acquisition. [ServiceNow completion announcement](https://newsroom.servicenow.com/press-releases/details/2026/ServiceNow-completes-Armis-acquisition-closing-the-gap-between-asset-visibility-and-cyber-risk/default.aspx). The v3 Policy API uses OAuth and does not have full v1/v2 parity. This pack does not invoke v1/v2, modify policy actions, query assets or call integrations.

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial tenant hardening controls and read-only verification | How to Harden Community |

## Contributing

Submit corrections and sanitized verification evidence through [GitHub](https://github.com/grcengineering/how-to-harden). Never attach tenant exports or secrets.
