---
layout: guide
title: "YouTrack Cloud Hardening Guide"
vendor: "YouTrack Cloud"
slug: "youtrack-cloud"
tier: "2"
category: "Productivity"
description: "Harden YouTrack Cloud authentication, access boundaries, and security evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

This guide covers JetBrains YouTrack Cloud account authentication, access and offboarding verification. Server installations and other JetBrains products are separately managed.

### Intended Audience

Tenant administrators, identity engineers, and reviewers who need defensible evidence of configuration.

### How to Use This Guide

- **L1 (Crawl):** Close basic access and disclosure gaps.
- **L2 (Walk):** Add targeted reviews and scoped evidence.
- Treat documented but untested settings as guidance, not a statement about your tenant.

### Scope

These controls cover only the stated product plane. No procedure was exercised in a live tenant.

## Table of Contents

1. [Authentication](#1-authentication)
2. [Identity lifecycle](#2-identity-lifecycle)
3. [Compliance Quick Reference](#compliance-quick-reference)

## 1. Authentication

### 1.1 Require two-factor authentication for approved groups

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | IA-2 |

#### Description

Enable the group policy for Hub accounts. Groups can cover a pilot population or All Users after a broad review, and configured noncompliant users may lose functional access until they enroll.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow password-only access.
- Test separately for unplanned hub credential lockout; do not assume related controls inherit the same policy.

**Attack Prevented:** Password-only access; Unplanned Hub credential lockout.

#### Prerequisites

Cloud administrator authorized to update the group. Verify Hub credential and third-party-only sign-in limitations before enforcement.

#### ClickOps Implementation

1. From **Administration → Access Management → Groups**, open the intended group’s **Settings** tab.
2. Use the documented Users filters to identify unprepared members and those whose accounts do not support 2FA.
3. Enable the group’s **Two-factor authentication** requirement only after the pilot and recovery work succeed.

[Vendor instructions](https://www.jetbrains.com/help/youtrack/cloud/require-two-factor-authentication.html)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Verify a user without a factor is restricted and a correctly enrolled user retains expected access. Confirm external IdP policies independently.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

If an approved exception is required, scope it to the affected group and verify the precise restored access.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | IA-2 | Contributes to the named control; does not assert compliance. |

## 2. Identity lifecycle

### 2.1 Disable unused sign-in modules

**Profile Level:** L2 (Walk)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Remove unnecessary login routes after transitioning users. Disablement can break service integrations and accounts whose primary identity is linked to that provider.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow unmanaged authentication routes.
- Test separately for disruption of linked identities; do not assume related controls inherit the same policy.

**Attack Prevented:** Unmanaged authentication routes; Disruption of linked identities.

#### Prerequisites

Cloud administrator with a working recovery sign-in route and an inventory of user identities dependent on each module.

#### ClickOps Implementation

1. Open **Administration → Access Management → Auth Modules**.
2. Review an unused module’s dependency population and disable it by using the documented controls.
3. Keep the recovery provider available until all tested user and automation paths are confirmed.

[Vendor instructions](https://www.jetbrains.com/help/youtrack/cloud/managing-auth-modules.html)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Inspect the available login options with a fresh session and verify the primary route works. Record any supported exceptions.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Re-enable only the affected provider as approved, verify its scope and set a removal date when dependency migration is complete.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

### 2.2 Verify a specific account is banned after offboarding

**Profile Level:** L2 (Walk)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Read back the specific account’s documented banned flag. Banning does not by itself prove independent IdP sessions, tokens and partner-system access were also revoked.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow former user sign-in.
- Test separately for wrong-account offboarding; do not assume related controls inherit the same policy.

**Attack Prevented:** Former user sign-in; Wrong-account offboarding.

#### Prerequisites

Authorized operator with Update User for the console action; separate minimal reader capable of retrieving the selected banned flag.

#### ClickOps Implementation

1. Open **Administration → Access Management → Users**, choose the exact approved account, and use the **Ban** action when authorized.
2. Handle project ownership and separate federation or token revocation according to the offboarding procedure.
3. Capture the stable database ID and use the read-only Code Pack on the intended tenant.

[Vendor instructions](https://www.jetbrains.com/help/youtrack/cloud/ban-user-accounts.html)

#### Code Implementation

The pack is read-only and limited to the documented evidence scope, not enforcement. See the [API reference](https://www.jetbrains.com/help/youtrack/devportal/operations-api-users.html).

{% include pack-code.html vendor="youtrack-cloud" section="2.2" %}

#### Validation & Testing

Verify the selected ID is returned with banned set to true and check available separate IdP and integration evidence.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Unban only after a fresh access authorization. Reconcile restored project grants immediately.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## Compliance Quick Reference

Use the NIST IDs in each control to trace evidence to the applicable policy. These mappings are recommendations, not certification.

## Appendix A: Edition and Tier Compatibility

The prerequisites in each control identify the validated documentation scope. Confirm entitlement in the tenant before scheduling an enforcement action; unsupported or untested editions are not asserted here.

## Appendix B: References

- [Product documentation](https://www.jetbrains.com/help/youtrack/cloud/secure-your-installation.html)
- [API documentation](https://www.jetbrains.com/help/youtrack/devportal/youtrack-rest-api.html)
- [Require two-factor authentication for approved groups](https://www.jetbrains.com/help/youtrack/cloud/require-two-factor-authentication.html)
- [Disable unused sign-in modules](https://www.jetbrains.com/help/youtrack/cloud/managing-auth-modules.html)
- [Verify a specific account is banned after offboarding](https://www.jetbrains.com/help/youtrack/cloud/ban-user-accounts.html)


## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial guide and evidence packs | Codex |

## Contributing

Report corrections or propose a control in the [project issue tracker](https://github.com/grcengineering/how-to-harden/issues).
