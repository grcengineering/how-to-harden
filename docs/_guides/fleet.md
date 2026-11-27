---
layout: guide
title: "Fleet Cloud Hardening Guide"
vendor: "Fleet"
slug: "fleet"
tier: "2"
category: "IT Operations"
description: "Harden the Fleet Cloud management plane with SSO, delegated roles, endpoint-restricted API identities and audit evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

[Fleet](https://fleetdm.com/) is an endpoint management platform. The ability to control enrolled devices makes the administrative boundary more consequential than an ordinary SaaS user directory.

**Validation status:** Source-backed administrative steps. The verification packs were not run against a live Fleet deployment.

### Intended Audience

Fleet administrators, endpoint engineering, identity administrators, and security monitoring owners.

### How to Use This Guide

Start with administrator sign-in and roles. Then separate workload identities and verify activity collection. Roll out to a dedicated pilot fleet before changing enterprise-wide settings.

### Scope

Fleet Cloud organization plane and customer-controlled settings. Check your plan and Fleet server version. The scope does not include self-managed database, TLS termination, or Fleet server internals; the vendor says those server options are customer configurable only on self-managed deployments.

## Table of Contents

1. [Administration](#1-administration)
2. [Integration and Audit](#2-integration-and-audit)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Administration

### 1.1 Require SSO for Fleet Administrators

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2 |

#### Description

Enable organization-managed SAML for human administrators and require MFA at the identity provider. Fleet end-user device authentication and Fleet admin login are distinct configuration targets.

#### Rationale

**Why This Matters:**

- Fleet admins can change enrollment and endpoint management policy. Enabling the organization SAML endpoint alone does not establish that every human administrator uses it.

#### ClickOps Implementation

1. Open **Settings → Integrations → Authentication (SSO) → Fleet users**. Configure matching IdP metadata and Fleet entity ID using the [Fleet SSO instructions](https://fleetdm.com/docs/deploy/single-sign-on-sso).
2. Require MFA at the IdP and pilot with one non-emergency account. Document any separately protected break-glass user; Fleet documents email two-factor authentication for that exception.
3. Leave JIT provisioning disabled until role mapping and IdP app assignments have been reviewed. Validate the effects of unassignment separately for SSO and non-SSO accounts.

**Automation:** The [Fleet REST API](https://fleetdm.com/docs/api/rest-api#sso-config) can assess whether Fleet SSO is enabled. The [GitOps settings reference](https://fleetdm.com/docs/configuration/yaml-files) documents a separate declarative change path under `org_settings.sso_settings`; do not replace an organization config from a partial example.

#### Code Implementation

{% include pack-code.html vendor="fleet" section="1.1" %}

#### Validation & Testing

Validate a known user with a new browser session, MFA, a rejected unassigned user, and emergency access. The code result is a configuration indicator, not a substitute for these tests.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2 |

### 1.2 Limit Global Roles and Delegate per Fleet

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Reserve global administrator access for approved operators and use fleet-scoped roles for endpoint administration where the subscription supports them.

#### Rationale

**Why This Matters:**

- The global and fleet-level roles have different reach; a global role can bypass restrictions intended to isolate fleets.

#### ClickOps Implementation

1. Open **Settings → Users**. Review which users have a global role and assign fleet-level roles to delegated operators where appropriate.
2. Compare the role with the vendor’s [role-based access matrix](https://fleetdm.com/guides/role-based-access); distinguish observers, maintainers and admins, and separate API-only identities from humans. Document why each global admin or write-capable GitOps identity is necessary.

**Automation:** The [first-party fleetctl export workflow](https://fleetdm.com/guides/downgrade-fleet) documents `fleetctl get user_roles` for reviewing role assignments. The pack writes those records to a newly created private local file; it does not change roles.

#### Code Implementation

{% include pack-code.html vendor="fleet" section="1.2" %}

#### Validation & Testing

With an approved pilot identity, confirm its expected fleet is visible and an unrelated fleet is not. Reconcile the exported assignments with the approved roster.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

## 2. Integration and Audit

### 2.1 Restrict API-Only Identities to Required Operations

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Give each workload a dedicated API-only identity with the minimum role and access to the exact API endpoints it needs.

#### Rationale

**Why This Matters:**

- Fleet documents that an API-only identity can be restricted to an endpoint list without expanding its role. Its key does not expire automatically, so ownership and revocation matter.

#### ClickOps Implementation

1. Open **Settings → Users → Create user** and enable the API-only option. Assign the minimum role and restrict the endpoint list as documented in [Fleetctl’s API-only user guidance](https://fleetdm.com/guides/fleetctl#using-fleetctl-with-an-api-only-user).
2. Put the token into your approved secret store, document the owner and replace credentials using a planned access review. Set a retirement date for unused identities.

**Automation:** Fleetctl documents API-only user creation, but the reviewed CLI example does not apply endpoint restrictions. Do not treat the example as complete least privilege; no write pack is provided for endpoint policy.

#### Validation & Testing

Under an authorized test identity, verify a benign permitted read and a benign disallowed read. Remove a pilot identity at completion and confirm access is withdrawn without retaining its token in logs.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

### 2.2 Verify Fleet Global Activity Collection

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6 |

#### Description

Review authentication and global management events and forward the required event classes to your organization’s approved log destination where supported.

#### Rationale

**Why This Matters:**

- Global and per-host streams are not equivalent. An authenticated query that returns no events is not proof that evidence is being captured.

#### ClickOps Implementation

1. In Fleet, open its **Activity** feed and review the authentication, user and configuration event classes in the [global audit log schema](https://fleetdm.com/docs/api/global-audit-logs).
2. Coordinate an export with your Fleet Cloud deployment owner if external retention is required. Do not apply `activity.enable_audit_log` to Fleet Cloud as if it were a tenant setting: it is documented as a [self-managed server option](https://fleetdm.com/docs/configuration/fleet-server-configuration), with external activity output gated by Fleet Premium.

**Automation:** Use `GET /api/v1/fleet/activities` with a credential allowed to read those events. This pack reports a bounded newest-first sample of types, not raw details or heartbeat health.

#### Code Implementation

{% include pack-code.html vendor="fleet" section="2.2" %}

#### Validation & Testing

Generate a benign permitted pilot sign-in. Verify its event arrives in both required locations with a sane timestamp, allowing for asynchronous delivery. Record any gaps; an empty sample is inconclusive.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6 |

## 3. Compliance Quick Reference

| Control area | NIST SP 800-53 Rev. 5 | Evidence |
|--------------|----------------------|----------|
| Fleet administrator SSO | IA-2 | Pilot authentication results and IdP enforcement |
| Scoped fleet and API roles | AC-6 | Reviewed roster and permitted/rejected read records |
| Global activity collection | AU-6 | Known events correlated to approved pilot actions |

These are implementation mappings, not a certification claim.

## Changelog

| Date | Version | Maturity | Change |
|------|---------|----------|--------|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial cloud management-plane controls and verification packs |
