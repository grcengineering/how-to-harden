---
layout: guide
title: "Calendly Hardening Guide"
vendor: "Calendly"
slug: "calendly"
tier: "2"
category: "Productivity"
description: "Harden Calendly authentication, access boundaries, and security evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

This guide covers Calendly organization access and audit controls; not connected calendar, conferencing, or IdP settings.

### Intended Audience

Tenant administrators, identity engineers, and reviewers who need defensible evidence of configuration.

### How to Use This Guide

- **L1 (Crawl):** Close basic access and disclosure gaps.
- **L2 (Walk):** Add targeted reviews and scoped evidence.
- Treat documented but untested settings as guidance, not a statement about your tenant.

### Scope

Organization-controlled controls and narrowly scoped evidence only. IdP, client, and connected application risks require separate review. No procedure was exercised in a live tenant.

## Table of Contents

1. [Identity and access](#1-identity-and-access)
2. [Audit evidence](#2-audit-evidence)
3. [Compliance Quick Reference](#compliance-quick-reference)

## 1. Identity and access

### 1.1 Pilot and enforce SAML single sign-on

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | IA-2 |

#### Description

Apply SAML to the organization after establishing a working pilot. Explicitly safeguard the organization owner’s documented fallback sign-in.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow local login bypass.
- Test separately for idp configuration lockout; do not assume related controls inherit the same policy.

**Attack Prevented:** Local login bypass; IdP configuration lockout.

#### Prerequisites

Calendly owner or admin; Enterprise or eligible Teams tier with SSO add-on; IdP and owner recovery ready.

#### ClickOps Implementation

1. Under **Settings → Access → Single sign-on**, configure the SAML metadata and identity mappings with your IdP.
2. Choose **Enable SSO for yourself**, then complete a test round trip in another session.
3. Assign all eligible users before choosing **Enforce SAML SSO for my organization → Apply**.

[Vendor instructions](https://calendly.com/help/how-to-set-up-saml-sso-with-your-identity-provider)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Verify IdP sign-in from a regular account, the owner recovery method, and a sample of account integrations after the sign-out event.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Temporarily disabling SSO also turns off SCIM. Coordinate both systems before making an authorized rollback.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | IA-2 | Contributes to the named control; does not assert compliance. |

### 1.2 Reconcile scoped organization membership roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Reconcile membership roles against the approved owner and administrator roster. This catches privileges that a user can still hold even after routine team changes.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow privilege creep.
- Test separately for orphaned organization membership; do not assume related controls inherit the same policy.

**Attack Prevented:** Privilege creep; Orphaned organization membership.

#### Prerequisites

Organization owner or administrator with an authorized organization-scoped API credential; use organizations:read for OAuth.

#### ClickOps Implementation

1. In **Settings → People**, review each assigned owner or administrator against the access register.
2. For an Enterprise organization, use the reviewed SCIM lifecycle path under **Access → User provisioning** where applicable, after enforcing SAML.

[Vendor instructions](https://calendly.com/help/admin-center)

#### Code Implementation

The pack is read-only and limited to the documented evidence scope, not enforcement. See the [API reference](https://developer.calendly.com/api-docs/calendly-api/organizations/list-organization-memberships).

{% include pack-code.html vendor="calendly" section="1.2" %}

#### Validation & Testing

Confirm an API inventory contains approved members and roles, then check approved exceptions in the console and IdP. An API list does not validate deprovisioning or session revocation.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

The pack does not change roles. In an approved lifecycle rollback, verify the correct license, role, and team after reprovisioning.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## 2. Audit evidence

### 2.1 Collect organization activity evidence

**Profile Level:** L2 (Walk)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AU-6 |

#### Description

Retrieve activity entries for a bounded time window; record the tenant and time interval so gaps are not confused with clean results.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow undetected admin policy changes.
- Test separately for incomplete audit trail; do not assume related controls inherit the same policy.

**Attack Prevented:** Undetected admin policy changes; Incomplete audit trail.

#### Prerequisites

Enterprise owner or administrator; short-lived token or dedicated credential with activity_log:read where supported.

#### ClickOps Implementation

1. Open **Settings → Access → Activity log** and filter to the applicable interval.
2. Run the inventory in a dedicated secure collector; retain only approved fields and limit access to event records.

[Vendor instructions](https://calendly.com/help/the-activity-log)

#### Code Implementation

The pack is read-only and limited to the documented evidence scope, not enforcement. See the [API reference](https://developer.calendly.com/api-docs/calendly-api/activity-log/list-activity-log-entries).

{% include pack-code.html vendor="calendly" section="2.1" %}

#### Validation & Testing

Compare a known benign administration event from the chosen period with the console output. A genuinely empty result does not validate delivery. Calendly retains this data for 90 days; design collection accordingly. Treat any output from a nonzero pack run as incomplete.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

No settings are changed. Stop collection and dispose of restricted data according to your retention obligations.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AU-6 | Contributes to the named control; does not assert compliance. |

## Compliance Quick Reference

Use the NIST IDs in each control to trace evidence to the applicable policy. These mappings are recommendations, not certification.

## Appendix A: Edition and Tier Compatibility

The prerequisites in each control identify the validated documentation scope. Confirm entitlement in the tenant before scheduling an enforcement action; unsupported or untested editions are not asserted here.

## Appendix B: References

- [Product documentation](https://calendly.com/help/admin-center)
- [API documentation](https://developer.calendly.com/docs/getting-started/introduction)
- [Pilot and enforce SAML single sign-on](https://calendly.com/help/how-to-set-up-saml-sso-with-your-identity-provider)
- [Reconcile scoped organization membership roles](https://calendly.com/help/admin-center)
- [Collect organization activity evidence](https://calendly.com/help/the-activity-log)


## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial guide and evidence packs | Codex |

## Contributing

Report corrections or propose a control in the [project issue tracker](https://github.com/grcengineering/how-to-harden/issues).
