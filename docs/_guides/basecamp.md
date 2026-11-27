---
layout: guide
title: "Basecamp Hardening Guide"
vendor: "Basecamp"
slug: "basecamp"
tier: "2"
category: "Productivity"
description: "Harden Basecamp authentication, access boundaries, and security evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

This guide covers Basecamp 5 account authentication, public publishing, and applicable identity inventory; older editions can differ.

### Intended Audience

Tenant administrators, identity engineers, and reviewers who need defensible evidence of configuration.

### How to Use This Guide

- **L1 (Crawl):** Close basic access and disclosure gaps.
- **L2 (Walk):** Add targeted reviews and scoped evidence.
- Treat documented but untested settings as guidance, not a statement about your tenant.

### Scope

These controls cover only the stated management plane. No procedure was exercised in a live tenant.

## Table of Contents

1. [Identity and access](#1-identity-and-access)
2. [Public sharing](#2-public-sharing)
3. [Compliance Quick Reference](#compliance-quick-reference)

## 1. Identity and access

### 1.1 Require two-factor authentication for the account

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | IA-2 |

#### Description

Require 2FA before account users can sign in without an additional factor. The owner setting applies to account members on their next login.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow password-only account takeover.
- Test separately for account-wide access loss; do not assume related controls inherit the same policy.

**Attack Prevented:** Password-only account takeover; Account-wide access loss.

#### Prerequisites

Basecamp account owner, with a tested second owner and a secure recovery path.

#### ClickOps Implementation

1. From **Home → Adminland**, open **Require two-factor authentication**.
2. Have affected users prepare their factors and recovery before enabling the requirement.
3. Schedule rollout with a second owner available and record the effective scope.

[Vendor instructions](https://5.basecamp-help.com/article/1136-owner-and-admin-actions)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Use an authorized synthetic member account to verify a new login prompts for setup or the configured factor. Separately confirm at least two owner accounts are recoverable.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

If recovery requires restoring the prior setting, use the same owner control under approval and schedule re-enforcement.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | IA-2 | Contributes to the named control; does not assert compliance. |

### 1.2 Review account administrators and outsiders

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Reconcile visible user IDs and available admin and client flags against a separately approved roster. Caller-visible results cannot establish the absence of hidden people or project grants.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow unreviewed administrator access.
- Test separately for orphaned outsider accounts; do not assume related controls inherit the same policy.

**Attack Prevented:** Unreviewed administrator access; Orphaned outsider accounts.

#### Prerequisites

Basecamp account owner or administrator; use a documented scoped account profile for CLI inventory.

#### ClickOps Implementation

1. In **Adminland → Manage people**, check individual account type and project access as appropriate.
2. Review **Add/remove administrators** and **Add/remove account owners** separately; these roles are not interchangeable.
3. Verify owner continuity before removing a departed administrator; do not reuse a former employee’s account.

[Vendor instructions](https://5.basecamp-help.com/article/1185-managing-people)

#### Code Implementation

The pack is read-only and limited to the documented evidence scope, not enforcement. See the [first-party CLI](https://github.com/basecamp/basecamp-cli) and the [People API reference](https://github.com/basecamp/bc-api/blob/master/sections/people.md). The CLI emits employee, admin, and client flags; owners must be reviewed separately. Do not substitute project GET requests: Basecamp documents that opening some projects via API can auto-enroll the caller.

{% include pack-code.html vendor="basecamp" section="1.2" %}

#### Validation & Testing

Compare the account-scoped evidence to the console and expected approvers. If a first-party CLI supplies a default project, clear that configuration before collecting account-wide access evidence.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Inventory commands do not revoke access. Reinstating a removed administrator requires a new authorization decision.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## 2. Public sharing

### 2.1 Review public items and remove unnecessary links

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Identify live public share links using the account-level publishing view. Remove only unsupported links; do not assume private projects guarantee every shared object remains private.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow unintended link disclosure.
- Test separately for stale public shares; do not assume related controls inherit the same policy.

**Attack Prevented:** Unintended link disclosure; Stale public shares.

#### Prerequisites

Basecamp account owner and an inventory of approved externally published items.

#### ClickOps Implementation

1. From **Home → Adminland**, choose **Manage public items**.
2. Review who owns each public artifact and remove individual unapproved links before any bulk action.
3. Use **People** in each sensitive project to verify Invite-only access and explicit members separately.

[Vendor instructions](https://5.basecamp-help.com/article/1136-owner-and-admin-actions)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Check a previously published test link from a signed-out browser; it should no longer display the content. Verify approved external links still work.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Restoring a public link can publish data again. Require explicit disclosure approval rather than using public restoration as routine rollback.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## Compliance Quick Reference

Use the NIST IDs in each control to trace evidence to the applicable policy. These mappings are recommendations, not certification.

## Appendix A: Edition and Tier Compatibility

The prerequisites in each control identify the validated documentation scope. Confirm entitlement in the tenant before scheduling an enforcement action; unsupported or untested editions are not asserted here.

## Appendix B: References

- [Product documentation](https://5.basecamp-help.com/article/1132-adminland)
- [API documentation](https://github.com/basecamp/bc-api)
- [Require two-factor authentication for the account](https://5.basecamp-help.com/article/1136-owner-and-admin-actions)
- [Review account administrators and outsiders](https://5.basecamp-help.com/article/1185-managing-people)
- [Review public items and remove unnecessary links](https://5.basecamp-help.com/article/1136-owner-and-admin-actions)


## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial guide and evidence packs | Codex |

## Contributing

Report corrections or propose a control in the [project issue tracker](https://github.com/grcengineering/how-to-harden/issues).
