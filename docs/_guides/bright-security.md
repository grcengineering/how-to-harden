---
layout: guide
title: "Bright Security Hardening Guide"
vendor: "Bright Security"
slug: "bright-security"
tier: "1"
category: "Security"
description: "Harden the Bright cloud organization, roles, project inventory and audit access."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden the Bright cloud organization, roles, project inventory and audit access. No scan creation, target authorization automation, attack configuration, test traffic or findings extraction is included.

### Intended Audience

Tenant administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Establish the essential controls before production rollout.
- **L2 (Walk):** Stage the additional restrictions with a representative pilot and a recovery path.
- **L3 (Run):** Validate applicability, evidence retention, and approval requirements for regulated use.

### Scope

This guide addresses customer-controlled settings, not the vendor's internal service security. Feature availability depends on the contract and tenant. Settings were checked against documentation; no live tenant was tested or modified.

## Table of Contents

1. [Access and credentials](#1-access-and-credentials)
2. [Scope and audit](#2-scope-and-audit)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Access and credentials

### 1.1 Require strong authentication for the organization

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | IA-2, AC-2 |

#### Description

Stage federated sign-in where entitled and review organization-wide two-factor authentication requirements.

#### Rationale

**Why This Matters:**

- A separate Bright administrator credential may expose sensitive project or workflow controls if weakly authenticated.

#### Prerequisites

Organization administrator, enrolled admins and tested recovery. The vendor documents that all administrators must enroll before setting mandatory 2FA.

#### ClickOps Implementation

1. In Organization Settings review member 2FA status and notify affected users under your change procedure.
2. For SAML, configure the authorized IdP and verify a pilot login before requiring SSO.
3. When ready, apply the organization 2FA policy for the applicable users. Independently verify MFA in the IdP for federated access.

#### Validation & Testing

Verify authorized pilot logins and recovery. Do not assume SSO enablement alone enforces MFA.

#### Monitoring & Maintenance

Review role changes, user enrollment and identity-provider settings.

#### Operational Impact & Rollback

Restore the affected pilot setting through the known recovery route; avoid leaving alternative access enabled broadly.

**Sources:** [Bright Organization settings](https://docs.brightsec.com/docs/manage-your-organization). [Bright SAML SSO](https://docs.brightsec.com/docs/saml-sso).

### 1.2 Constrain custom roles and API keys

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 |

#### Description

Use minimum scopes, project-specific identities where suitable, and separate inventory access from write capabilities.

#### Rationale

**Why This Matters:**

- An overpowered key can administer unrelated projects or trigger actions it was never intended for.

#### Prerequisites

Approved role map and access to organization/project settings.

#### ClickOps Implementation

1. Review organization members, Groups and Roles and compare custom scopes against approved duties.
2. Reconcile personal, project and organization API keys and remove unnecessary write grants.
3. Provide a dedicated key with projects:read for the documented inventory workflow; avoid scan-related scopes for this collector.

#### Validation & Testing

Confirm the key sees only intended projects without attempting write/scan operations; verify scopes and review key owner.

#### Monitoring & Maintenance

Review access after automation changes and periodic recertification.

#### Operational Impact & Rollback

Replace the specific credential through a staged rotation if access needs correction.

**Sources:** [Bright Organization settings](https://docs.brightsec.com/docs/manage-your-organization). [Bright capability scopes](https://docs.brightsec.com/docs/manage-access-scopes).

## 2. Scope and audit

### 2.1 Reconcile authorized project visibility

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-8, AC-6 |

#### Description

Compare the projects visible to the audit key to the intended scope, with tenant administrators verifying actual group assignments.

#### Rationale

**Why This Matters:**

- An overbroad inventory key can see unrelated projects; an overly narrow key can hide expected coverage.

#### Prerequisites

Authorized Bright tenant, restricted inventory key and expected project inventory.

#### ClickOps Implementation

1. Open the Bright Projects view, confirm the correct organization and compare visible projects against the approved scope.
2. In organization settings verify relevant group assignments and the permissions given to the inventory key.
3. Record excessive or missing project visibility as a review item rather than widening access reflexively.

#### Code Implementation

{% include pack-code.html vendor="bright-security" section="2.1" %}

#### Validation & Testing

Compare the pack’s first-page count and the authorized UI inventory. A count cannot prove which projects are visible or what their security status is.

#### Monitoring & Maintenance

Repeat after project or integration access changes.

#### Operational Impact & Rollback

Restore the previous approved scoped key or group mapping if a legitimate workflow loses required access.

**Sources:** [Bright capability scopes](https://docs.brightsec.com/docs/manage-access-scopes). [Bright first-party project listing contract](https://docs.brightsec.com/docs/integrating-with-the-bright-api).

### 2.2 Monitor human and API-key audit activity

**Profile Level:** L2

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-2, AU-6 |

#### Description

Review organizational audit activity for critical changes and correlate the recorded user or API-key actor with approved actions.

#### Rationale

**Why This Matters:**

- A personal audit view is not an organization audit and may omit other actors.

#### Prerequisites

Authorized audit role and restricted evidence storage.

#### ClickOps Implementation

1. Open Audit log in the correct organization and verify the viewer can see the required organizational scope.
2. Filter on event timing, object, action, and human or API-key actor as appropriate.
3. Preserve event IDs and redacted evidence from a known authorized change.

#### Validation & Testing

Confirm a known configuration change is present and attributed correctly; investigate discrepancies without retrieving underlying findings.

#### Monitoring & Maintenance

Track event review, changed audit permissions and key ownership.

#### Operational Impact & Rollback

Correct only the affected access grant or evidence destination; preserve available records.

**Sources:** [Bright activity log](https://docs.brightsec.com/docs/managing-audit-log).

## 3. Compliance Quick Reference

These are thematic NIST mappings, not a benchmark, certification, or evidence of implementation.

| Control | NIST SP 800-53 Rev. 5 |
|---|---|
| 1.1 Require strong authentication for the organization | IA-2, AC-2 |
| 1.2 Constrain custom roles and API keys | AC-6, IA-5 |
| 2.1 Reconcile authorized project visibility | CM-8, AC-6 |
| 2.2 Monitor human and API-key audit activity | AU-2, AU-6 |

## Appendix A: Automation and applicability

The pack calls only the documented read-only project list on the default Bright SaaS host. Partner collectors must set the documented X-Bright-Integration identification value. No issue or scan endpoints are exercised. Tenant settings and event access are manually reviewed.

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial tenant hardening controls and read-only verification | How to Harden Community |

## Contributing

Submit corrections and sanitized verification evidence through [GitHub](https://github.com/grcengineering/how-to-harden). Never attach tenant exports or secrets.
