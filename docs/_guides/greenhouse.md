---
layout: guide
title: "Greenhouse Recruiting Hardening Guide"
vendor: "Greenhouse Recruiting"
slug: "greenhouse"
tier: "2"
category: "HR/Finance"
description: "Harden Greenhouse Recruiting administrative access and verify scoped control evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Scope Recruiting workforce identities, job-based roles and Harvest v3 audit access. Greenhouse Onboarding has its own SAML, permissions and APIs.

### Intended Audience

- Tenant and identity administrators responsible for access and configuration
- Security or assurance reviewers responsible for control evidence

### How to Use This Guide

L1 (Crawl) is the supported baseline here. Confirm the exact tenant, plan, and responsible administrator before testing with synthetic evidence or an approved nonproduction account.

### Scope

No credential creation, access updates or changes to hiring workflows are automated. The pack performs a narrow read-only or local evidence check; no live tenant validation or configuration writes were performed.

## Table of Contents

1. [Security Configuration](#1-security-configuration)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Security Configuration

### 1.1 Stage then finalize workforce SAML

**Profile Level:** L1 (Crawl)

**NIST 800-53:** IA-2

#### Description

Pilot SAML with selected workforce users before committing to the finalized login policy.

#### Rationale

- Managed authentication reduces exposure when local credentials or identity assignments survive ordinary personnel changes.

#### ClickOps Implementation

A user with Can manage and configure SSO permission can open Configure → Dev Center → Single sign-on. Enter approved metadata, soft-enable, pilot IdP MFA, and only then finalize. Identify a recovery owner; vendor support is required to deactivate finalized SSO.

Source: [Greenhouse Recruiting documentation](https://support.greenhouse.io/hc/en-us/articles/360040753811-Configure-single-sign-on-SSO-for-Greenhouse-Recruiting) (checked 2026-11-27).

**Automation:** Review and change this control in the documented admin interface; no policy mutation is packaged.

#### Validation & Testing

Test both sign-in and denied access before finalizing. On offboarding, remove the IdP assignment and deactivate access in Recruiting as appropriate.

---

### 1.2 Constrain recruiting and developer permissions

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-6

#### Description

Delegate job-level access and limit credentials that can manage settings or reach recruiting data.

#### Rationale

- Constrain effective entitlement to the minimum needed and review privileged claims rather than assuming UI and API access are identical.

#### ClickOps Implementation

Use Configure → Users and Permission Policies to review Basic, Job Admin and Site Admin. Grant Job Admin only for assigned roles and minimize private data permissions and future job grants. In Dev Center, review scoped Harvest v3 integrations and their associated Integration System Users.

Source: [Greenhouse Recruiting documentation](https://support.greenhouse.io/hc/en-us/articles/210957383-User-permissions-grid) (checked 2026-11-27).

**Automation:** Review and change this control in the documented admin interface; no policy mutation is packaged.

#### Validation & Testing

Confirm a test Job Admin can view an assigned synthetic job but cannot view an unassigned one or manage global settings. Review separate user-specific permissions.

---

### 1.3 Sample Harvest v3 audit evidence without exporting personal data

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AU-6

#### Description

Confirm that approved Harvest access events are retrievable without storing raw personal information.

#### Rationale

- Review source records and minimize the confidential information written into evidence systems.

#### ClickOps Implementation

On an eligible company account, use Configure → Dev Center to create Harvest v3 OAuth credentials limited to reading audit data. Read the 30-day audit context and validate a recent expected event in the UI or approved evidence workflow. Do not use the deprecated Harvest v1/v2 token exchange.

Source: [Greenhouse Recruiting documentation](https://support.greenhouse.io/hc/en-us/articles/15114161286043-Use-audit-log-with-API) (checked 2026-11-27).

**Automation:** An existing audit-scoped Harvest v3 OAuth token is used for one documented US audit endpoint request; no legacy exchange, pagination loop or raw event export. If the v3 support article specifies a different endpoint for your environment, validate that separately rather than sending your token to an inferred host.

#### Code Implementation

{% include pack-code.html vendor="greenhouse" section="1.3" %}

#### Validation & Testing

The pack samples one 15-minute first page of Harvest access events and verifies returned organization IDs. Compare with audit evidence for the same window; an empty page does not verify organization identity or completeness.

## 2. Compliance Quick Reference

These mappings describe control objectives, not certification.

| HTH control | Objective | NIST SP 800-53 Rev. 5 |
|-------------|-----------|-----------------------|
| 1.1 | Stage then finalize workforce SAML | IA-2 |
| 1.2 | Constrain recruiting and developer permissions | AC-6 |
| 1.3 | Sample Harvest v3 audit evidence without exporting personal data | AU-6 |

### References

- [Pack source and coverage boundaries](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-people-infrastructure-source-coverage.md)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Changelog

| Version | Date | Maturity | Changes |
|---------|------|----------|---------|
| 0.1.0 | 2026-11-27 | ai-drafted | Initial control guide and offline-tested evidence pack. |
