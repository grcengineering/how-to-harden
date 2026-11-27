---
layout: guide
title: "Grammarly Hardening Guide"
vendor: "Grammarly"
slug: "grammarly"
tier: "2"
category: "Productivity"
description: "Harden Grammarly authentication, access boundaries, and security evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

This guide covers Grammarly Enterprise, the writing product in the Superhuman suite, not Superhuman Go, Mail, or Docs. The parent company rebranded as Superhuman; Grammarly remains a product.

### Intended Audience

Tenant administrators, identity engineers, and reviewers who need defensible evidence of configuration.

### How to Use This Guide

- **L1 (Crawl):** Close basic access and disclosure gaps.
- **L2 (Walk):** Add targeted reviews and scoped evidence.
- Treat documented but untested settings as guidance, not a statement about your tenant.

### Scope

These controls cover only the stated product plane. No procedure was exercised in a live tenant.

## Table of Contents

1. [Identity lifecycle](#1-identity-lifecycle)
2. [Endpoint controls](#2-endpoint-controls)
3. [Compliance Quick Reference](#compliance-quick-reference)

## 1. Identity lifecycle

### 1.1 Federate sign-in and reconcile provisioned users

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Pair SAML with SCIM rather than relying on just-in-time provisioning. An app assignment removal can trigger suspension and later permanent deletion.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow orphaned enterprise accounts.
- Test separately for unexpected content loss; do not assume related controls inherit the same policy.

**Attack Prevented:** Orphaned enterprise accounts; Unexpected content loss.

#### Prerequisites

Grammarly Enterprise admin with a supported IdP and a tested recovery path.

#### ClickOps Implementation

1. Follow the SCIM article’s linked SAML setup and pilot the assigned and unassigned populations.
2. In **Provisioning**, configure the supported IdP integration and reconcile existing users with the downloadable report.
3. Test with a synthetic member before enabling broader automatic offboarding.

[Vendor instructions](https://support.grammarly.com/hc/en-us/articles/4403054674829-Configure-SCIM-provisioning)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Verify a fresh assigned login works, then remove the synthetic user’s IdP assignment and confirm session and account suspension via separate checks.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Stop expansion if reconciliation fails; confirm retention and recovery with the vendor before performing any bulk removal.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## 2. Endpoint controls

### 2.1 Restrict Grammarly access to sensitive desktop applications

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Use vendor application controls to prevent Grammarly from running in specified desktop applications. Browser domains are a distinct control.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow sensitive text disclosure.
- Test separately for unintended loss of writing assistance; do not assume related controls inherit the same policy.

**Attack Prevented:** Sensitive text disclosure; Unintended loss of writing assistance.

#### Prerequisites

Grammarly Enterprise administrator; exact Mac or Windows executable name and an approved inventory of sensitive apps.

#### ClickOps Implementation

1. Open **Organization → Enterprise Security → Domains and apps** and choose **Add to block list → Application**.
2. Enter the exact application filename and choose the intended scope.
3. Pilot using synthetic text in a blocked app and an allowed one.

[Vendor instructions](https://support.grammarly.com/hc/en-us/articles/27454187430029-Manage-application-controls)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Verify the client is unavailable in the blocked app and still works in the approved app. Do not treat this as evidence of coverage for a browser or unmanaged clients.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Remove only a confirmed incorrect rule and retest. Do not disable the entire boundary to resolve a naming mismatch.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

### 2.2 Validate the macOS desktop Managed Mode preference

**Profile Level:** L2 (Walk)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Managed Mode limits client use to organization accounts. Validate the native plist before MDM deployment without displaying the token. This does not test tenant SSO or installed state.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow personal account use in the work client.
- Test separately for incorrect enrollment configuration; do not assume related controls inherit the same policy.

**Attack Prevented:** Personal account use in the work client; Incorrect enrollment configuration.

#### Prerequisites

SSO enabled, approved enrollment token, and a local profile input for the com.grammarly.ProjectLlama preference domain.

#### ClickOps Implementation

1. Open the vendor’s **Managed mode** page and retrieve the approved token securely.
2. Prepare the documented macOS preference-domain plist and check it with the Code Pack before deployment.
3. Deploy through a reviewed MDM pilot. Test using distinct approved organization and personal test accounts.

[Vendor instructions](https://support.grammarly.com/hc/en-us/articles/8341171286541-Configure-Managed-Mode)

#### Code Implementation

The pack is read-only and limited to the documented evidence scope, not enforcement. See the [vendor implementation reference](https://support.grammarly.com/hc/en-us/articles/8341171286541-Configure-Managed-Mode).

{% include pack-code.html vendor="grammarly" section="2.2" %}

#### Validation & Testing

Require both positive and negative client tests. The vendor notes that personal web sign-in can still succeed even when the managed client will not work.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Restore a prior approved profile or remove it from a pilot scope in MDM under change control; verify effective client behavior.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## Compliance Quick Reference

Use the NIST IDs in each control to trace evidence to the applicable policy. These mappings are recommendations, not certification.

## Appendix A: Edition and Tier Compatibility

The prerequisites in each control identify the validated documentation scope. Confirm entitlement in the tenant before scheduling an enforcement action; unsupported or untested editions are not asserted here.

## Appendix B: References

- [Product documentation](https://superhuman.com/company/about)
- [Technical documentation](https://support.grammarly.com/hc/en-us/articles/8341171286541-Configure-Managed-Mode)
- [Federate sign-in and reconcile provisioned users](https://support.grammarly.com/hc/en-us/articles/4403054674829-Configure-SCIM-provisioning)
- [Restrict Grammarly access to sensitive desktop applications](https://support.grammarly.com/hc/en-us/articles/27454187430029-Manage-application-controls)
- [Validate the macOS desktop Managed Mode preference](https://support.grammarly.com/hc/en-us/articles/8341171286541-Configure-Managed-Mode)


## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial guide and evidence packs | Codex |

## Contributing

Report corrections or propose a control in the [project issue tracker](https://github.com/grcengineering/how-to-harden/issues).
