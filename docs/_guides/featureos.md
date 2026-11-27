---
layout: guide
title: "FeatureOS Hardening Guide"
vendor: "FeatureOS"
slug: "featureos"
tier: "2"
category: "Productivity"
description: "Harden FeatureOS authentication, access boundaries, and security evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

This guide covers FeatureOS, formerly Hellonext. The vendor documents the rebrand and maintains customer and API documentation under FeatureOS; legacy Hellonext sign-in return URLs redirect to the new app.

### Intended Audience

Tenant administrators, identity engineers, and reviewers who need defensible evidence of configuration.

### How to Use This Guide

- **L1 (Crawl):** Close basic access and disclosure gaps.
- **L2 (Walk):** Add targeted reviews and scoped evidence.
- Treat documented but untested settings as guidance, not a statement about your tenant.

### Scope

These controls cover only the stated product plane. No procedure was exercised in a live tenant.

## Table of Contents

1. [Portal privacy and authentication](#1-portal-privacy-and-authentication)
2. [OAuth evidence](#2-oauth-evidence)
3. [Compliance Quick Reference](#compliance-quick-reference)

## 1. Portal privacy and authentication

### 1.1 Restrict access to non-public feedback portals and boards

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Use Organization Privacy for internal-only or invite-only portals, and review authorization for each private board separately.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow public disclosure of internal feedback.
- Test separately for unreviewed board membership; do not assume related controls inherit the same policy.

**Attack Prevented:** Public disclosure of internal feedback; Unreviewed board membership.

#### Prerequisites

FeatureOS admin with an approved customer and board-member list.

#### ClickOps Implementation

1. Open **Dashboard → Organization Settings → Basic → Privacy** and enable **Organization Privacy** where the portal must be private.
2. Review approved customers and use **Boards → Private Boards → Members** to review access to each restricted board.
3. Avoid reusable invitation links for sensitive boards where direct member enrollment suffices.

[Vendor instructions](https://help.featureos.app/en/articles/public-vs-private-organizations)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Test a clean signed-out browser, a permitted customer and a signed-in customer without a private board grant. Check any embedded surfaces independently.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Use the last reviewed member list to restore legitimate access; do not switch the entire portal to public to fix one entitlement.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

### 1.2 Limit feedback portal authentication to approved routes

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | IA-2 |

#### Description

Disable unapproved customer sign-in methods and test the chosen SSO route. Enabling SSO can disable other methods initially, but administrators can turn them back on.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow identity policy bypass through alternate sign-in.
- Test separately for loss of customer access during rollout; do not assume related controls inherit the same policy.

**Attack Prevented:** Identity policy bypass through alternate sign-in; Loss of customer access during rollout.

#### Prerequisites

Business plan or legacy Fly High for authentication-method controls; verify the selected SSO entitlement and recovery route.

#### ClickOps Implementation

1. Open **Dashboard → Organization Settings → Advanced → Authentication Methods**.
2. Establish the approved SSO method, then confirm remaining toggles match policy. Keep at least one method enabled.
3. Verify both customer and staff roles with approved pilot identities.

[Vendor instructions](https://help.featureos.app/en/articles/configuring-authentication-methods)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

From a fresh browser confirm an authorized user can sign in and alternate routes are not offered. Confirm the portal still denies unapproved users independently of role configuration.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Restore only an approved login route with a documented expiration, and retest guest and staff access.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | IA-2 | Contributes to the named control; does not assert compliance. |

## 2. OAuth evidence

### 2.1 Verify scoped OAuth actor and organization binding

**Profile Level:** L2 (Walk)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Use the documented session-info read to bind an integration credential to its organization and either the app bot or authorized user. Do not substitute a broad organization API key.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow cross-tenant credential mistakes.
- Test separately for wrong acting identity; do not assume related controls inherit the same policy.

**Attack Prevented:** Cross-tenant credential mistakes; Wrong acting identity.

#### Prerequisites

Approved bearer credential granting posts:read, expected numeric organization and actor IDs, and expected actor mode.

#### ClickOps Implementation

1. Review the integration in the target organization and note the expected actor mode and IDs from a trusted inventory.
2. Grant only the documented read scope needed for this check; follow the OAuth app policy before authorizing a credential.
3. Run the check before scheduling assessment jobs.

[Vendor instructions](https://developers.featureos.app/docs/oauth-apps/access-tokens)

#### Code Implementation

The pack is read-only and limited to the documented evidence scope, not enforcement. See the [vendor implementation reference](https://developers.featureos.app/docs/oauth-apps/access-tokens).

{% include pack-code.html vendor="featureos" section="2.1" %}

#### Validation & Testing

Match organization, user and actor mode. This does not enumerate effective OAuth scopes, prove privacy settings, or authorize writes.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

No remote mutation. Revoke or reauthorize any mismatched token through the organization’s integration settings.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## Compliance Quick Reference

Use the NIST IDs in each control to trace evidence to the applicable policy. These mappings are recommendations, not certification.

## Appendix A: Edition and Tier Compatibility

The prerequisites in each control identify the validated documentation scope. Confirm entitlement in the tenant before scheduling an enforcement action; unsupported or untested editions are not asserted here.

## Appendix B: References

- [Product documentation](https://featureos.com/blog/hellonext-is-now-featureos)
- [Technical documentation](https://developers.featureos.app/docs)
- [Restrict access to non-public feedback portals and boards](https://help.featureos.app/en/articles/public-vs-private-organizations)
- [Limit feedback portal authentication to approved routes](https://help.featureos.app/en/articles/configuring-authentication-methods)
- [Verify scoped OAuth actor and organization binding](https://developers.featureos.app/docs/oauth-apps/access-tokens)


## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial guide and evidence packs | Codex |

## Contributing

Report corrections or propose a control in the [project issue tracker](https://github.com/grcengineering/how-to-harden/issues).
