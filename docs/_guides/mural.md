---
layout: guide
title: "Mural Hardening Guide"
vendor: "Mural"
slug: "mural"
tier: "2"
category: "Productivity"
description: "Harden Mural authentication, access boundaries, and security evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

This guide covers Mural content sharing and user-scoped workspace visibility; Enterprise organization policy is not interchangeable with the Public API.

### Intended Audience

Tenant administrators, identity engineers, and reviewers who need defensible evidence of configuration.

### How to Use This Guide

- **L1 (Crawl):** Close basic access and disclosure gaps.
- **L2 (Walk):** Add targeted reviews and scoped evidence.
- Treat documented but untested settings as guidance, not a statement about your tenant.

### Scope

These controls cover only the stated management plane. No procedure was exercised in a live tenant.

## Table of Contents

1. [Collaboration and identity](#1-collaboration-and-identity)
2. [Workspace reach](#2-workspace-reach)
3. [Compliance Quick Reference](#compliance-quick-reference)

## 1. Collaboration and identity

### 1.1 Prefer named guest access over visitor links

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Use named, revocable access for ongoing external work. Mural visitors enter via a visitor link, while guests use named accounts. If links are necessary, use documented time and password controls where available.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow forwarded visitor links.
- Test separately for loss of attribution for external collaborators; do not assume related controls inherit the same policy.

**Attack Prevented:** Forwarded visitor links; Loss of attribution for external collaborators.

#### Prerequisites

Mural workspace admin or authorized owner; review the workspace plan and collaboration settings.

#### ClickOps Implementation

1. On a non-sensitive mural, open **Share** and inspect access for named collaborators versus visitors.
2. Use a named guest for continuing access rather than distributing an anonymous visitor link.
3. If a visitor link is necessary, open **Share → Advanced settings → Visitor link settings → Add password**, save a unique password, and set the shortest appropriate [visitor-link expiration](https://support.mural.co/s/article/visitor-link-expiration) your plan supports. Existing named members and guests are not prompted for the visitor password.

[Vendor visitor-link instructions](https://support.mural.co/s/article/password-protect-visitor-links) · [Collaborator roles](https://developers.mural.co/public/docs/mural-basics)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Try revoking a synthetic guest, then verify that named access ends. Test expiration separately with an approved visitor link and confirm the allowed collaborator retains access.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Issue a replacement visitor link only with approval. Do not restore anonymous links by default when troubleshooting an external collaborator.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

### 1.2 Review identity provisioning on supported orgs

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Use SAML and SCIM where available to centralize identity enforcement and deprovisioning. Distinguish authentication of managed members from visitor links and unmanaged external identities.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow unmanaged logins.
- Test separately for residual access after offboarding; do not assume related controls inherit the same policy.

**Attack Prevented:** Unmanaged logins; Residual access after offboarding.

#### Prerequisites

Company administrator and one test identity with access to a non-production workspace; exact feature entitlements vary.

#### ClickOps Implementation

1. Use the Mural company administrator identity and access guidance to configure your supported SAML IdP and provisioning integration.
2. Test a single assigned member before broader rollout; review active guest access outside the managed population.
3. If the company settings or provisioning runbook is not visible, obtain the current plan-specific procedure instead of guessing an admin control path.

[Vendor instructions](https://www.mural.co/trust-and-security)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Verify the pilot member signs in through the IdP, is correctly assigned to the intended workspace, and loses named access after the approved pilot deprovisioning. Test visitor access independently.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Reverse only the pilot assignment while preserving intentional policy; broad IdP disablement or bypass requires separate recovery approval.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## 2. Workspace reach

### 2.1 Reconcile visible workspaces for a scoped credential

**Profile Level:** L2 (Walk)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Inventory workspace IDs reachable by the specific user, including results that may represent inactive objects. A Public API token is not an enterprise administrator inventory.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow unexpected workspace reach through an integration.
- Test separately for scope overstatement; do not assume related controls inherit the same policy.

**Attack Prevented:** Unexpected workspace reach through an integration; Scope overstatement.

#### Prerequisites

Approved Mural Public API OAuth token with workspaces:read. The token acts as the user who consented.

#### ClickOps Implementation

1. Review the approved app’s OAuth grants and the workspaces assigned to the integration user.
2. Use the Public API data below only for this scoped user. For company-wide scope, use the company dashboard or separately documented Enterprise API.

[Vendor instructions](https://developers.mural.co/public/docs/oauth)

#### Code Implementation

The pack is read-only and limited to the documented evidence scope, not enforcement. See the [API reference](https://developers.mural.co/public/reference/getworkspaces).

{% include pack-code.html vendor="mural" section="2.1" %}

#### Validation & Testing

Compare the returned IDs with the intended workspace roster and separately investigate inactive or unexpected results. HTTP errors and unexpected response shapes are not evidence of zero workspaces.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

No state changes. Revoke or narrow a temporary OAuth grant only by your normal approved access process.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## Compliance Quick Reference

Use the NIST IDs in each control to trace evidence to the applicable policy. These mappings are recommendations, not certification.

## Appendix A: Edition and Tier Compatibility

The prerequisites in each control identify the validated documentation scope. Confirm entitlement in the tenant before scheduling an enforcement action; unsupported or untested editions are not asserted here.

## Appendix B: References

- [Product documentation](https://www.mural.co/trust-and-security)
- [API documentation](https://developers.mural.co/public/docs/public-vs-enterprise)
- [Prefer named guest access over visitor links](https://developers.mural.co/public/docs/mural-basics)
- [Review identity provisioning on supported orgs](https://www.mural.co/trust-and-security)
- [Reconcile visible workspaces for a scoped credential](https://developers.mural.co/public/docs/oauth)


## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial guide and evidence packs | Codex |

## Contributing

Report corrections or propose a control in the [project issue tracker](https://github.com/grcengineering/how-to-harden/issues).
