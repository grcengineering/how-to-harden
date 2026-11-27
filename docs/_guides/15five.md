---
layout: guide
title: "15Five Hardening Guide"
vendor: "15Five"
slug: "15five"
tier: "2"
category: "HR/Finance"
description: "Harden 15Five administrative access and verify scoped control evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Scope the 15Five workforce platform and its company-wide API. Some SSO entitlements vary by plan.

### Intended Audience

- Tenant and identity administrators responsible for access and configuration
- Security or assurance reviewers responsible for control evidence

### How to Use This Guide

L1 (Crawl) is the supported baseline here. Confirm the exact tenant, plan, and responsible administrator before testing with synthetic evidence or an approved nonproduction account.

### Scope

Public API credentials do not prove SAML policy or SCIM assignment. Use a dedicated approved test identity. The pack performs a narrow read-only or local evidence check; no live tenant validation or configuration writes were performed.

## Table of Contents

1. [Security Configuration](#1-security-configuration)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Security Configuration

### 1.1 Enforce a tested SAML sign-in path

**Profile Level:** L1 (Crawl)

**NIST 800-53:** IA-2

#### Description

Move workforce authentication to the managed IdP without locking out administrators.

#### Rationale

- Managed authentication reduces exposure when local credentials or identity assignments survive ordinary personnel changes.

#### ClickOps Implementation

Open Company Settings → SAML Single Sign-On as an administrator. Configure the company subdomain and IdP metadata. Leave Allow Password Sign In enabled while you test; turn it off only after validating your recovery procedure. Do not enable JIT provisioning if SCIM or an HRIS integration is already authoritative.

Source: [15Five documentation](https://success.15five.com/hc/en-us/articles/50988921314331-Set-up-SAML-Single-Sign-On-SSO-in-15Five) (checked 2026-11-27).

**Automation:** Review and change this control in the documented admin interface; no policy mutation is packaged.

#### Validation & Testing

Confirm workforce login with IdP MFA in a fresh browser and test the expected behavior for a removed test user. Track the certificate rollover date.

---

### 1.2 Limit and rotate Public API tokens

**Profile Level:** L1 (Crawl)

**NIST 800-53:** IA-5

#### Description

Keep company API keys scoped to the consumer and rotate them before they expire.

#### Rationale

- Credential separation and overlapping rotation prevent hidden integrations from retaining unrestricted or expired access.

#### ClickOps Implementation

Under Settings → Integrations → Public API, review Company API keys. Choose High Fives-only scope when adequate, otherwise approve the broader scope explicitly. Public keys expire after one year; rotate before expiry and do not mix up Public API and SCIM credentials.

Source: [15Five documentation](https://success.15five.com/hc/en-us/articles/50988716008347-Manage-API-Keys-Expiration-Rotation-and-Security) (checked 2026-11-27).

**Automation:** Review and change this control in the documented admin interface; no policy mutation is packaged.

#### Validation & Testing

Check purpose, owner, rotation date and actual consumers of each key. Confirm a newly rotated key preserves an approved workflow before revoking the old one.

---

### 1.3 Confirm one user account state and admin flag

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-2

#### Description

Determine whether a known user can still access the company account or administer its settings.

#### Rationale

- Identity lifecycle checks prevent access from outlasting approved assignments.

#### ClickOps Implementation

Use your approved 15Five user roster to identify a test record. In Company Settings, review the matching person and their administrative access. Compare the vendor API flag with effective permissions in the UI; a company admin flag does not enumerate product-specific privileges.

Source: [15Five documentation](https://my.15five.com/api/public/coreapi/) (checked 2026-11-27).

**Automation:** An API GET returns one selected person’s active and company admin flags and omits personal profile fields. This endpoint requires a company-wide Public API key. Do not create a broad production token solely to run this sample; use manual review or authorized test credentials when appropriate.

#### Code Implementation

{% include pack-code.html vendor="15five" section="1.3" %}

#### Validation & Testing

Run against an active and then a deactivated synthetic employee as part of an authorized lifecycle exercise; compare the observed flags with the independently expected state.

## 2. Compliance Quick Reference

These mappings describe control objectives, not certification.

| HTH control | Objective | NIST SP 800-53 Rev. 5 |
|-------------|-----------|-----------------------|
| 1.1 | Enforce a tested SAML sign-in path | IA-2 |
| 1.2 | Limit and rotate Public API tokens | IA-5 |
| 1.3 | Confirm one user account state and admin flag | AC-2 |

### References

- [Pack source and coverage boundaries](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-people-infrastructure-source-coverage.md)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Changelog

| Version | Date | Maturity | Changes |
|---------|------|----------|---------|
| 0.1.0 | 2026-11-27 | ai-drafted | Initial control guide and offline-tested evidence pack. |
