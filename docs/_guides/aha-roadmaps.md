---
layout: guide
title: "Aha! Roadmaps Hardening Guide"
vendor: "Aha! Roadmaps"
slug: "aha-roadmaps"
tier: "2"
category: "Productivity"
description: "Harden Aha! Roadmaps authentication, access boundaries, and security evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

This guide covers Aha! Roadmaps account security and user evidence; no assumptions about Ideas portals, Aha! Builder, or other distinct Aha! control planes.

### Intended Audience

Tenant administrators, identity engineers, and reviewers who need defensible evidence of configuration.

### How to Use This Guide

- **L1 (Crawl):** Close basic access and disclosure gaps.
- **L2 (Walk):** Add targeted reviews and scoped evidence.
- Treat documented but untested settings as guidance, not a statement about your tenant.

### Scope

These controls cover only the stated product plane. No procedure was exercised in a live tenant.

## Table of Contents

1. [Account authentication](#1-account-authentication)
2. [Developer access](#2-developer-access)
3. [Account evidence](#3-account-evidence)
4. [Compliance Quick Reference](#compliance-quick-reference)

## 1. Account authentication

### 1.1 Require managed SAML sign-in

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | IA-2 |

#### Description

Centralize account member sign-in while preserving a separately governed recovery route. IdP enforcement is not a substitute for reviewing user permissions.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow password-only access.
- Test separately for sso rollout lockout; do not assume related controls inherit the same policy.

**Attack Prevented:** Password-only access; SSO rollout lockout.

#### Prerequisites

Aha! Roadmaps account administrator with a working SAML IdP, pilot cohort, and independently tested admin recovery.

#### ClickOps Implementation

1. In **User menu → Settings → Account → Security and single sign-on**, configure the SAML provider as documented.
2. Exchange the exact IdP metadata and pilot an assigned member before broader enforcement.
3. Review any non-SSO access and protect that population separately.

[Vendor instructions](https://support.aha.io/aha-roadmaps/account/account-single-sign-on/configure-sso-saml-2-point-0~7444657704368362659)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Verify a permitted test account can sign in and a non-assigned test identity is denied. Verify the intended admin recovery path before rollout.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Restore only a confirmed previous configuration under an approved recovery plan and reassess affected sessions.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | IA-2 | Contributes to the named control; does not assert compliance. |

## 2. Developer access

### 2.1 Restrict new developer credentials and OAuth approvals

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Limit new personal API keys, external app authorizations, and OAuth registrations independently. Disabling new access does not revoke existing tokens or apps.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow unapproved saas integration access.
- Test separately for standing credentials after policy change; do not assume related controls inherit the same policy.

**Attack Prevented:** Unapproved SaaS integration access; Standing credentials after policy change.

#### Prerequisites

Account administrator; Enterprise+ only if using capability-specific exceptions.

#### ClickOps Implementation

1. Go to **User menu → Settings → Account → Security and single sign-on → Developer governance**.
2. In the **API keys**, **Authorized applications**, and **OAuth applications** panels, disable access according to your policy and save each supported control.
3. Set narrow Enterprise+ exceptions per capability if required. Separately audit existing API keys, app grants, and OAuth clients for authorized revocation.

[Vendor instructions](https://support.aha.io/aha-roadmaps/support-articles/settings/account-settings~7444670273994478592)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

From an allowed test identity and an ordinary test identity, verify the expected ability to start a new authorization without actually approving an untrusted app. Reconcile existing credentials separately.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Re-enable only the affected capability after approval or add a time-bound exception where supported; revoke old granted access separately.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## 3. Account evidence

### 3.1 Reconcile the account user inventory

**Profile Level:** L2 (Walk)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Collect minimized account user identifiers and compare with an approved workforce inventory. Do not mistake the list for verified SSO, MFA, API-token restrictions, or individual workspace permissions.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow untracked account population.
- Test separately for orphaned accounts; do not assume related controls inherit the same policy.

**Attack Prevented:** Untracked account population; Orphaned accounts.

#### Prerequisites

Account-approved Aha! credential with access to user records, tenant subdomain, and an operations contact for the API User-Agent.

#### ClickOps Implementation

1. Use **Settings → Account → Users** to review account members and approved workspace permissions.
2. Reconcile with a dedicated assessor’s credential using the API pack. The credential inherits its user’s product permissions.

[Vendor instructions](https://support.aha.io/aha-roadmaps/account/billing-and-users/user-permissions~7444657360296913475)

#### Code Implementation

The pack is read-only and limited to the documented evidence scope, not enforcement. See the [API reference](https://www.aha.io/api/resources/users/list_users).

{% include pack-code.html vendor="aha-roadmaps" section="3.1" %}

#### Validation & Testing

Confirm the expected account subdomain and compare returned IDs to the roster. Investigate missing or unexpected records rather than automatically removing them.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

No state changes. Revoke a temporary collector credential after collecting evidence.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## Compliance Quick Reference

Use the NIST IDs in each control to trace evidence to the applicable policy. These mappings are recommendations, not certification.

## Appendix A: Edition and Tier Compatibility

The prerequisites in each control identify the validated documentation scope. Confirm entitlement in the tenant before scheduling an enforcement action; unsupported or untested editions are not asserted here.

## Appendix B: References

- [Product documentation](https://support.aha.io/aha-roadmaps/support-articles/settings/account-settings~7444670273994478592)
- [API documentation](https://www.aha.io/api)
- [Require managed SAML sign-in](https://support.aha.io/aha-roadmaps/account/account-single-sign-on/configure-sso-saml-2-point-0~7444657704368362659)
- [Restrict new developer credentials and OAuth approvals](https://support.aha.io/aha-roadmaps/support-articles/settings/account-settings~7444670273994478592)
- [Reconcile the account user inventory](https://support.aha.io/aha-roadmaps/account/billing-and-users/user-permissions~7444657360296913475)


## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial guide and evidence packs | Codex |

## Contributing

Report corrections or propose a control in the [project issue tracker](https://github.com/grcengineering/how-to-harden/issues).
