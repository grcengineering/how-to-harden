---
layout: guide
title: "Superhuman Docs (Coda) Hardening Guide"
vendor: "Superhuman Docs (Coda)"
slug: "coda"
tier: "2"
category: "Productivity"
description: "Harden Superhuman Docs (Coda) authentication, access boundaries, and security evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

This guide covers Enterprise organization settings for Superhuman Docs, formerly Coda; not other Superhuman products or independent Pack developers.

### Intended Audience

Tenant administrators, identity engineers, and reviewers who need defensible evidence of configuration.

### How to Use This Guide

- **L1 (Crawl):** Close basic access and disclosure gaps.
- **L2 (Walk):** Add targeted reviews and scoped evidence.
- Treat documented but untested settings as guidance, not a statement about your tenant.

### Scope

These controls cover only the stated management plane. No procedure was exercised in a live tenant.

## Table of Contents

1. [Authentication](#1-authentication)
2. [External sharing](#2-external-sharing)
3. [Workspace inventory](#3-workspace-inventory)
4. [Compliance Quick Reference](#compliance-quick-reference)

## 1. Authentication

### 1.1 Centralize managed-domain sign-in with SAML

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | IA-2 |

#### Description

Enable SAML on managed domains, with a narrowly scoped test before production enforcement. Organization identity policy is distinct from assignment into a specific workspace.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow local credential bypass.
- Test separately for overbroad workspace enrollment; do not assume related controls inherit the same policy.

**Attack Prevented:** Local credential bypass; Overbroad workspace enrollment.

#### Prerequisites

Enterprise organization admin, correctly verified domains and tested IdP metadata and assignments.

#### ClickOps Implementation

1. Open **Admin settings → Security → Authentication methods** and configure **Authenticate with SSO (SAML)**.
2. Exchange and validate the IdP and application metadata using the vendor setup procedure.
3. Review assertion mappings for each workspace, and test documentation-backed recovery before larger rollout.

[Vendor instructions](https://help.coda.io/hc/en-us/articles/39629608416013-Set-up-SSO-for-your-org)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Test with a member in a managed domain; sample a guest outside it and a second workspace. Confirm IdP MFA and tenant membership separately.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Retain the previous metadata to recover the intended configuration. Do not relax authentication across unrelated domains during recovery.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | IA-2 | Contributes to the named control; does not assert compliance. |

## 2. External sharing

### 2.1 Restrict external sharing of docs and Packs

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Use No external sharing for internal material, or use custom rules restricted to approved partner domains. Forms can have a separate policy; case-by-case administrator overrides need review.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow anonymous external document links.
- Test separately for third-party access drift; do not assume related controls inherit the same policy.

**Attack Prevented:** Anonymous external document links; Third-party access drift.

#### Prerequisites

Enterprise org admin with an approved trusted-domain list and recorded exceptions for external collaboration.

#### ClickOps Implementation

1. In **Admin settings → Security → Sharing controls**, review **Content sharing policies** for docs, folders, Packs and forms.
2. Choose **No external sharing** or **Use custom sharing rules → Share only with trusted domains**, and maintain the domains list.
3. Use **Doc management** to review legacy public sharing and authorized policy exceptions.

[Vendor instructions](https://help.coda.io/hc/en-us/articles/39555789441805-Control-sharing-of-docs-and-Packs)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Try a new share to an unapproved test partner using synthetic content. Separately verify existing external links, the forms policy, and approved overrides.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Restoring public or broad external sharing is a new disclosure decision. Roll back only the affected settings on approval.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## 3. Workspace inventory

### 3.1 Reconcile workspaces covered by the organization

**Profile Level:** L2 (Walk)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Inventory workspace IDs within the named organization to identify unsupported or unexpected workspaces in the scope of a security review. The list is not a readback of any individual policy.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow untracked workspace scope.
- Test separately for unreviewed organization expansion; do not assume related controls inherit the same policy.

**Attack Prevented:** Untracked workspace scope; Unreviewed organization expansion.

#### Prerequisites

Enterprise org administrator and a dedicated authorized Admin API token. Admin API privileges must be reviewed separately from workspace member roles.

#### ClickOps Implementation

1. Open **Admin settings** in the intended organization, verify its workspace and document ownership context, and record the approved workspace roster.
2. Use the documented Admin API token setup for repeatable inventory. Store its secret outside scripts and restrict the collector.

[Vendor instructions](https://help.coda.io/hc/en-us/articles/39555856878477-Intro-to-the-Admin-API)

#### Code Implementation

The pack is read-only and limited to the documented evidence scope, not enforcement. See the [API reference](https://docs.superhuman.com/developers/apis/admin/v1).

{% include pack-code.html vendor="coda" section="3.1" %}

#### Validation & Testing

Compare the complete inventory to the approved roster; investigate extra workspaces and separately check their membership and sharing configuration.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

The pack does not modify any resources. Retire the temporary Admin API credential when collection is no longer needed.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## Compliance Quick Reference

Use the NIST IDs in each control to trace evidence to the applicable policy. These mappings are recommendations, not certification.

## Appendix A: Edition and Tier Compatibility

The prerequisites in each control identify the validated documentation scope. Confirm entitlement in the tenant before scheduling an enforcement action; unsupported or untested editions are not asserted here.

## Appendix B: References

- [Product documentation](https://help.coda.io/hc/en-us/articles/39555715801741-Overview-Enterprise-security-features)
- [API documentation](https://docs.superhuman.com/developers/apis/admin/v1)
- [Centralize managed-domain sign-in with SAML](https://help.coda.io/hc/en-us/articles/39629608416013-Set-up-SSO-for-your-org)
- [Restrict external sharing of docs and Packs](https://help.coda.io/hc/en-us/articles/39555789441805-Control-sharing-of-docs-and-Packs)
- [Reconcile workspaces covered by the organization](https://help.coda.io/hc/en-us/articles/39555856878477-Intro-to-the-Admin-API)


## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial guide and evidence packs | Codex |

## Contributing

Report corrections or propose a control in the [project issue tracker](https://github.com/grcengineering/how-to-harden/issues).
