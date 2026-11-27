---
layout: guide
title: "Articulate 360 Hardening Guide"
vendor: "Articulate 360"
slug: "articulate-360"
tier: "2"
category: "Productivity"
description: "Harden Articulate 360 authentication, access boundaries, and security evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

This guide covers Articulate 360 AI Teams administration and a separately labeled Reach 360 training-delivery control. Reach 360 API evidence does not cover Articulate 360 Teams creator/admin policy.

### Intended Audience

Tenant administrators, identity engineers, and reviewers who need defensible evidence of configuration.

### How to Use This Guide

- **L1 (Crawl):** Close basic access and disclosure gaps.
- **L2 (Walk):** Add targeted reviews and scoped evidence.
- Treat documented but untested settings as guidance, not a statement about your tenant.

### Scope

These controls cover only the stated product plane. No procedure was exercised in a live tenant.

## Table of Contents

1. [Authoring team access](#1-authoring-team-access)
2. [Reach training access](#2-reach-training-access)
3. [Compliance Quick Reference](#compliance-quick-reference)

## 1. Authoring team access

### 1.1 Enroll creators and admins in managed single sign-on

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Use vendor-assisted SSO enrollment for the creator and administrator plane. Reach 360 learner SSO is a separate setup, not evidence for this policy.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow unmanaged creator sign-in.
- Test separately for wrong-plane enforcement; do not assume related controls inherit the same policy.

**Attack Prevented:** Unmanaged creator sign-in; Wrong-plane enforcement.

#### Prerequisites

Articulate 360 AI Teams account owner or administrator, supported SAML identity provider, and organizational identities.

#### ClickOps Implementation

1. Have the accountable administrator request enrollment via the documented Articulate support route and prepare the public SAML metadata for the intended organization.
2. Work with the vendor and IdP administrator to configure and pilot the connection; no self-serve policy write is established here.
3. Review assigned creator and administrator identities before any broad rollout.

[Vendor instructions](https://www.articulatesupport.com/article/Articulate-360-Teams-Single-Sign-On)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Test creator and administrator flows via the intended IdP. If Reach 360 is deployed, separately validate its learner SSO configuration.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Coordinate recovery of the Teams configuration with the vendor and your IdP administrator rather than relaxing account access ad hoc.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

### 1.2 Review creators and team managers

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Separate product seats from elevated administrative rights and review access by role. Account and group admin rights do not necessarily imply a creator seat.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow excessive team management rights.
- Test separately for stale content-creation access; do not assume related controls inherit the same policy.

**Attack Prevented:** Excessive team management rights; Stale content-creation access.

#### Prerequisites

Articulate 360 AI Teams account owner or designated admin, with an approved role roster and training-content continuity plan.

#### ClickOps Implementation

1. Open the account’s **Manage Team → People** view.
2. Compare the displayed role and group assignment with the authorized roster; use the documented role management action only for approved changes.
3. Resolve ownership or content continuity before removing an existing creator.

[Vendor instructions](https://www.articulatesupport.com/article/Articulate-360-Teams-Managing-People-Groups-and-Invites)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Confirm the new role on the target identity and verify normal creators do not gain broader team administration rights.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Restore a prior assignment only under an approved access exception, and verify content ownership and effective permissions.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## 2. Reach training access

### 2.1 Verify a named Reach 360 training account role

**Profile Level:** L2 (Walk)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Read back the role of one named user in the separately managed Reach 360 tenant. Never interpret a Reach response as proof of authoring-account privileges.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow unreviewed training administration rights.
- Test separately for cross-plane evidence confusion; do not assume related controls inherit the same policy.

**Attack Prevented:** Unreviewed training administration rights; Cross-plane evidence confusion.

#### Prerequisites

Reach 360 enabled; approved Reach API key, expected user ID, approved role, and the correct data region.

#### ClickOps Implementation

1. In Reach 360, use **Manage → Settings → Manage API Keys** to arrange a dedicated credential if justified. Use the documented Reach console permissions as the separate role system.
2. Record the Reach user ID and authorized role independently before running the audit.

[Vendor instructions](https://www.articulatesupport.com/article/Reach-360-Manage-API-Keys)

#### Code Implementation

The pack is read-only and limited to the documented evidence scope, not enforcement. See the [API reference](https://www.articulatesupport.com/article/Reach-360-Users-API).

{% include pack-code.html vendor="articulate-360" section="2.1" %}

#### Validation & Testing

Check that the exact identifier and role match. The pack exits nonzero on drift and emits only role evidence; separately inspect group management permissions.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

This pack does not mutate roles. Revoke the dedicated collection key after use if it was issued temporarily.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## Compliance Quick Reference

Use the NIST IDs in each control to trace evidence to the applicable policy. These mappings are recommendations, not certification.

## Appendix A: Edition and Tier Compatibility

The prerequisites in each control identify the validated documentation scope. Confirm entitlement in the tenant before scheduling an enforcement action; unsupported or untested editions are not asserted here.

## Appendix B: References

- [Product documentation](https://www.articulatesupport.com/article/Articulate-360-Teams-Managing-People-Groups-and-Invites)
- [API documentation](https://www.articulatesupport.com/article/Reach-360-Introduction-to-Reach-360-API)
- [Enroll creators and admins in managed single sign-on](https://www.articulatesupport.com/article/Articulate-360-Teams-Single-Sign-On)
- [Review creators and team managers](https://www.articulatesupport.com/article/Articulate-360-Teams-Managing-People-Groups-and-Invites)
- [Verify a named Reach 360 training account role](https://www.articulatesupport.com/article/Reach-360-Manage-API-Keys)


## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial guide and evidence packs | Codex |

## Contributing

Report corrections or propose a control in the [project issue tracker](https://github.com/grcengineering/how-to-harden/issues).
