---
layout: guide
title: "ClickUp Hardening Guide"
vendor: "ClickUp"
slug: "clickup"
tier: "2"
category: "Productivity"
description: "Harden ClickUp authentication, access boundaries, and security evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

This guide covers ClickUp Workspace security settings and enterprise audit evidence; not every connected app or personal account.

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
3. [API access and evidence](#3-api-access-and-evidence)
4. [Compliance Quick Reference](#compliance-quick-reference)

## 1. Authentication

### 1.1 Require additional authentication for local logins

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | IA-2 |

#### Description

Apply the appropriate two-factor policy to Workspace users who do not authenticate through the enterprise IdP. Keep IdP MFA enforcement distinct from native 2FA.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow password-only access.
- Test separately for guest exception creep; do not assume related controls inherit the same policy.

**Attack Prevented:** Password-only access; Guest exception creep.

#### Prerequisites

Workspace owner or authorized admin; verify Workspace tier and guest exceptions.

#### ClickOps Implementation

1. Select **Workspace avatar → Settings → Security & Permissions**.
2. Choose **Immediately require 2FA for non-SSO logins only** where SSO is used; otherwise choose the appropriate requirement for all applicable users.
3. Review the guest exemption, where shown, before enabling it.

[Vendor instructions](https://help.clickup.com/hc/en-us/articles/6327741965591-Activate-and-manage-two-factor-authentication)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Check a representative non-SSO user through a fresh session and sample the security column under Manage users → People. Verify IdP users separately.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Use the same security panel to restore the recorded prior requirement only after an authorized recovery decision.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | IA-2 | Contributes to the named control; does not assert compliance. |

## 2. Sharing

### 2.1 Block new public links and protect attachments

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Limit public-sharing options and configure private attachment links separately. Public-link restrictions are not an attachment authorization control.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow unapproved external access.
- Test separately for anonymous attachment disclosure; do not assume related controls inherit the same policy.

**Attack Prevented:** Unapproved external access; Anonymous attachment disclosure.

#### Prerequisites

Workspace owner or authorized admin; review public link and attachment-dependent workflows before broad changes.

#### ClickOps Implementation

1. In Workspace settings, open **Security & Permissions** and activate **Block public sharing** after evaluating the documented effects on links and templates.
2. Enable **Private attachment links** separately to require the applicable signed-in access.
3. Review previously issued links and approved public links by category; do not infer that all old links are invalidated.

[Vendor instructions](https://help.clickup.com/hc/en-us/articles/6309213140375-Configure-advanced-Workspace-security-permissions)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Use a synthetic item to test a new public link and an attachment from an unauthenticated browser, then verify authorized collaborators can still open expected files.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Restore only the necessary setting with approval; record affected existing links and retest each allowed audience.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## 3. API access and evidence

### 3.1 Confirm API workspace authorization boundaries

**Profile Level:** L2 (Walk)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Diff the Workspace IDs returned to the token against a separately approved allowlist. This tests Workspace boundaries, not downstream resource permissions.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow overbroad app installation.
- Test separately for untracked token access; do not assume related controls inherit the same policy.

**Attack Prevented:** Overbroad app installation; Untracked token access.

#### Prerequisites

Use the integration’s OAuth access token, or for individual testing a personal token; supply the exact approved Workspace IDs.

#### ClickOps Implementation

1. Use ClickUp’s OAuth authorization flow and select only approved Workspaces.
2. For a personal API token, review the underlying account’s memberships and rotate the token if it was overexposed.

[Vendor instructions](https://developer.clickup.com/docs/authentication)

#### Code Implementation

The pack is read-only and limited to the documented evidence scope, not enforcement. See the [API reference](https://developer.clickup.com/reference/getauthorizedteams).

{% include pack-code.html vendor="clickup" section="3.1" %}

#### Validation & Testing

Check that exactly the approved Workspace IDs are returned; a nonzero comparison is a review item, not authority to revoke another integration.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

This pack performs no mutation. To unwind an authorization change, reconnect only the intended Workspaces and confirm the resulting list.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

### 3.2 Review Workspace security audit events

**Profile Level:** L2 (Walk)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AU-6 |

#### Description

Review successful and failed identity, configuration, and integration events before the documented retention window expires.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow undetected authentication drift.
- Test separately for missing investigation evidence; do not assume related controls inherit the same policy.

**Attack Prevented:** Undetected authentication drift; Missing investigation evidence.

#### Prerequisites

Workspace owner by default on eligible Enterprise or Max plans; authorized admins can be granted the documented viewing permission.

#### ClickOps Implementation

1. Open **Workspace avatar → Settings → Audit Logs → User**.
2. Filter a known time range and review security-related events; retain the evidence under your approved handling plan.
3. Keep access limited to the incident, compliance, and operations roles that need it.

[Vendor instructions](https://help.clickup.com/hc/en-us/articles/21929900448535-Workspace-audit-logs)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Find a known benign policy event and verify actor, date, and status. Confirm your monitoring process handles the 60-day Workspace retention limit, where documented for your plan.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Reviewing logs is non-mutating. Revoking an elevated audit-review role is separate from retention obligations.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AU-6 | Contributes to the named control; does not assert compliance. |

## Compliance Quick Reference

Use the NIST IDs in each control to trace evidence to the applicable policy. These mappings are recommendations, not certification.

## Appendix A: Edition and Tier Compatibility

The prerequisites in each control identify the validated documentation scope. Confirm entitlement in the tenant before scheduling an enforcement action; unsupported or untested editions are not asserted here.

## Appendix B: References

- [Product documentation](https://help.clickup.com/hc/en-us/articles/10853931837335-Workspace-and-account-settings)
- [API documentation](https://developer.clickup.com/docs/authentication)
- [Require additional authentication for local logins](https://help.clickup.com/hc/en-us/articles/6327741965591-Activate-and-manage-two-factor-authentication)
- [Block new public links and protect attachments](https://help.clickup.com/hc/en-us/articles/6309213140375-Configure-advanced-Workspace-security-permissions)
- [Confirm API workspace authorization boundaries](https://developer.clickup.com/docs/authentication)
- [Review Workspace security audit events](https://help.clickup.com/hc/en-us/articles/21929900448535-Workspace-audit-logs)


## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial guide and evidence packs | Codex |

## Contributing

Report corrections or propose a control in the [project issue tracker](https://github.com/grcengineering/how-to-harden/issues).
