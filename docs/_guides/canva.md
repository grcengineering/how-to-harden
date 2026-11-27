---
layout: guide
title: "Canva Hardening Guide"
vendor: "Canva"
slug: "canva"
tier: "2"
category: "Productivity"
description: "Harden Canva authentication, access boundaries, and security evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

This guide covers Canva Enterprise organization and team settings; not Canva Connect app development or vendor-hosted infrastructure.

### Intended Audience

Tenant administrators, identity engineers, and reviewers who need defensible evidence of configuration.

### How to Use This Guide

- **L1 (Crawl):** Close basic access and disclosure gaps.
- **L2 (Walk):** Add targeted reviews and scoped evidence.
- Treat documented but untested settings as guidance, not a statement about your tenant.

### Scope

Organization-controlled controls and narrowly scoped evidence only. IdP, client, and connected application risks require separate review. No procedure was exercised in a live tenant.

## Table of Contents

1. [Authentication](#1-authentication)
2. [Sharing](#2-sharing)
3. [Identity inventory](#3-identity-inventory)
4. [Compliance Quick Reference](#compliance-quick-reference)

## 1. Authentication

### 1.1 Enforce SAML sign-in for managed team members

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | IA-2 |

#### Description

Centralize managed member sign-in at your IdP. Prefer the team-only setting unless the organization deliberately wants to govern every account using its domain.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow local sign-in bypass.
- Test separately for domain-wide lockout; do not assume related controls inherit the same policy.

**Attack Prevented:** Local sign-in bypass; Domain-wide lockout.

#### Prerequisites

Team owner or administrator; Canva Enterprise; verified domain, SAML IdP, and a tested recovery plan.

#### ClickOps Implementation

1. Review the configured IdP and an existing managed member in **Settings → SSO and provisioning**.
2. Under the SSO signup and login control, choose **SSO required for everyone on your team** and save.
3. Leave just-in-time provisioning enabled unless a tested SCIM workflow already provisions members.

[Vendor instructions](https://www.canva.com/help/sso-login-controls/)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Use a fresh session for a test member to confirm the IdP is mandatory; separately check an approved recovery path. Test an account outside the team to verify the intended boundary.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Restoring the previous login policy may reopen non-SSO access. Use it only for authorized, time-limited recovery.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | IA-2 | Contributes to the named control; does not assert compliance. |

## 2. Sharing

### 2.1 Restrict external design sharing

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Set who may share outside the brand. This setting applies to new designs, not previously shared objects; treat existing links as a separate exposure backlog.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow unintended disclosure.
- Test separately for uncontrolled public links; do not assume related controls inherit the same policy.

**Attack Prevented:** Unintended disclosure; Uncontrolled public links.

#### Prerequisites

Canva Enterprise team owner; inventory publication workflows and approved external collaborators first.

#### ClickOps Implementation

1. Select the intended team in **Settings → Permissions**.
2. In **Share and publish**, set both external-link sharing and sharing to external email addresses to **Team admins only** or **No one**, depending on approved work.
3. For legacy designs, inspect actual link and collaborator grants individually and record the approved disposition.

[Vendor instructions](https://www.canva.com/help/restrict-design-sharing/)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Use a non-sensitive new design to verify that normal members cannot create an external share. Separately check known old links and verify explicitly approved collaborations.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

An authorized team administrator may restore the prior role setting; old links changed individually are not restored by changing the policy.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## 3. Identity inventory

### 3.1 Reconcile organization user inventory

**Profile Level:** L2 (Walk)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Inventory organization user IDs for reconciliation with the approved workforce inventory and provisioning records. Team membership is not the same as organization membership.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow orphaned accounts.
- Test separately for unreviewed provisioning; do not assume related controls inherit the same policy.

**Attack Prevented:** Orphaned accounts; Unreviewed provisioning.

#### Prerequisites

Canva Enterprise organization administrator; obtain a short-lived, client-credentials Admin API access token with only admin:user:read.

#### ClickOps Implementation

1. In Canva **Settings → Admin API**, have an authorized organization admin create a named client scoped to user reads and exchange credentials using Canva’s documented flow.
2. If the IdP is already used for lifecycle management, review the SCIM assignment population before comparing it with the organization list.

[Vendor instructions](https://www.canva.com/help/set-up-admin-api/)

#### Code Implementation

The pack is read-only and limited to the documented evidence scope, not enforcement. See the [API reference](https://www.canva.dev/docs/admin/api-reference/users/list-users/).

{% include pack-code.html vendor="canva" section="3.1" %}

#### Validation & Testing

Reconcile the full returned ID set with approved users; investigate unexpected IDs rather than deleting them automatically. The inventory does not prove SAML enforcement, deprovisioning, or team membership.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

The pack does not modify users. Revoke a temporary client when the assessment is complete.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## Compliance Quick Reference

Use the NIST IDs in each control to trace evidence to the applicable policy. These mappings are recommendations, not certification.

## Appendix A: Edition and Tier Compatibility

The prerequisites in each control identify the validated documentation scope. Confirm entitlement in the tenant before scheduling an enforcement action; unsupported or untested editions are not asserted here.

## Appendix B: References

- [Product documentation](https://www.canva.com/help/about-canva-enterprise/)
- [API documentation](https://www.canva.dev/docs/admin/)
- [Enforce SAML sign-in for managed team members](https://www.canva.com/help/sso-login-controls/)
- [Restrict external design sharing](https://www.canva.com/help/restrict-design-sharing/)
- [Reconcile organization user inventory](https://www.canva.com/help/set-up-admin-api/)


## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial guide and evidence packs | Codex |

## Contributing

Report corrections or propose a control in the [project issue tracker](https://github.com/grcengineering/how-to-harden/issues).
