---
layout: guide
title: "Wrike Hardening Guide"
vendor: "Wrike"
slug: "wrike"
tier: "2"
category: "Productivity"
description: "Harden Wrike authentication, access boundaries, and security evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

This guide covers Wrike account identity, invitations, and per-account contact inventory for eligible tenant plans.

### Intended Audience

Tenant administrators, identity engineers, and reviewers who need defensible evidence of configuration.

### How to Use This Guide

- **L1 (Crawl):** Close basic access and disclosure gaps.
- **L2 (Walk):** Add targeted reviews and scoped evidence.
- Treat documented but untested settings as guidance, not a statement about your tenant.

### Scope

These controls cover only the stated management plane. No procedure was exercised in a live tenant.

## Table of Contents

1. [Authentication and invitations](#1-authentication-and-invitations)
2. [Account evidence](#2-account-evidence)
3. [Compliance Quick Reference](#compliance-quick-reference)

## 1. Authentication and invitations

### 1.1 Enforce managed sign-in with Wrike SAML

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | IA-2 |

#### Description

Enforce SAML for the intended scope instead of leaving an optional login path. Domain-scoped enforcement leaves other domains on local sign-in, which needs a separate policy.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow optional sso bypass.
- Test separately for guest authentication gap; do not assume related controls inherit the same policy.

**Attack Prevented:** Optional SSO bypass; Guest authentication gap.

#### Prerequisites

Account owner/authorized administrator, eligible enterprise edition, tested identity provider and domain verification when enforcing by domain.

#### ClickOps Implementation

1. Open **Account Management → Security → SAML SSO → Setup SAML SSO**.
2. Configure the provider metadata, verify a test identity, and choose the documented scope for employees and outside users.
3. Configure IdP MFA for the managed population and the documented local 2-Step Verification policy for applicable non-SSO accounts.

[Vendor instructions](https://help.wrike.com/hc/en-us/articles/209605769-SAML-SSO-Implementation-Guide)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Test the enterprise pilot identity and an authorized account outside managed domains, including mobile or desktop sign-in if used.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Keep a documented provider recovery path. Do not switch the tenant to optional mode for troubleshooting without an explicit risk decision.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | IA-2 | Contributes to the named control; does not assert compliance. |

### 1.2 Limit invitations and license grants

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Choose who can invite users, which email domains are allowed, and what licenses inviters can grant. Treat license assignments as access decisions, not merely billing.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow unauthorized outside invitations.
- Test separately for excess privileges through license allocation; do not assume related controls inherit the same policy.

**Attack Prevented:** Unauthorized outside invitations; Excess privileges through license allocation.

#### Prerequisites

Wrike account owner with the approved contractor domains and user license types documented.

#### ClickOps Implementation

1. Use **Profile → Settings → Security → Invitation settings**.
2. Restrict inviters to the designated admin population and limit allowed domains and license types according to the access policy.
3. Review existing outside collaborators and required guest workflows separately.

[Vendor instructions](https://help.wrike.com/hc/en-us/articles/1500005127661-Invitation-Settings)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Use synthetic accounts to confirm a non-inviter cannot invite and that a disallowed domain or license is rejected; do not send an external test invite.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Reopen only the minimum invite path under approved exception and verify the resulting control again.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## 2. Account evidence

### 2.1 Verify the calling account and identity

**Profile Level:** L2 (Walk)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Check the API caller’s account and returned privilege flags before collecting further tenant data. This pack describes one caller profile, not the overall account roster.

#### Rationale

**Why This Matters:**
- Avoid misattributing one authenticated account’s evidence to another.
- A scoped API credential still might belong to an owner; check the returned privilege flags.

**Attack Prevented:** Wrong-tenant evidence; Overprivileged collection identity.

#### Prerequisites

Wrike OAuth access approved for contacts with the issue-time returned regional host and exact intended account identity.

#### ClickOps Implementation

1. Use **Account Management** user records and the account’s approved roster to set the expected scope.
2. For this pack, use a credential whose OAuth response gives the exact documented host www.wrike.com; use the vendor guide for other regions.

[Vendor instructions](https://help.wrike.com/hc/en-us/articles/1500005126521-Running-User-Access-Report)

#### Code Implementation

The pack is read-only and limited to the documented evidence scope, not enforcement. See the [API reference](https://developers.wrike.com/reference/getcontactsempty).

{% include pack-code.html vendor="wrike" section="2.1" %}

#### Validation & Testing

Match the caller and account IDs to approved records and inspect admin, owner, and external flags. The pack does not prove other users’ roles or invitation rules.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

The pack makes no writes. Do not delete identities through the inventory process; use reviewed offboarding procedures.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## Compliance Quick Reference

Use the NIST IDs in each control to trace evidence to the applicable policy. These mappings are recommendations, not certification.

## Appendix A: Edition and Tier Compatibility

The prerequisites in each control identify the validated documentation scope. Confirm entitlement in the tenant before scheduling an enforcement action; unsupported or untested editions are not asserted here.

## Appendix B: References

- [Product documentation](https://help.wrike.com/hc/en-us/articles/210324325-Enterprise-Account-Admin-Permissions)
- [API documentation](https://developers.wrike.com/docs/oauth-20-authorization)
- [Enforce managed sign-in with Wrike SAML](https://help.wrike.com/hc/en-us/articles/209605769-SAML-SSO-Implementation-Guide)
- [Limit invitations and license grants](https://help.wrike.com/hc/en-us/articles/1500005127661-Invitation-Settings)
- [Verify the calling account and identity](https://help.wrike.com/hc/en-us/articles/1500005126521-Running-User-Access-Report)


## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial guide and evidence packs | Codex |

## Contributing

Report corrections or propose a control in the [project issue tracker](https://github.com/grcengineering/how-to-harden/issues).
