---
layout: guide
title: "Pipedrive Hardening Guide"
vendor: "Pipedrive"
slug: "pipedrive"
tier: "2"
category: "Marketing"
description: "Harden Pipedrive administrative access and verify scoped control evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Pipedrive CRM company account, user permissions and scoped integration identity. Browser Security Center controls are not assumed to protect API traffic.

### Intended Audience

- Tenant and identity administrators responsible for access and configuration
- Security or assurance reviewers responsible for control evidence

### How to Use This Guide

L1 (Crawl) is the supported baseline here. Confirm the exact tenant, plan, and responsible administrator before testing with synthetic evidence or an approved nonproduction account.

### Scope

Advanced security rules can be plan-gated and do not necessarily apply to mobile; the provider describes browser access IP rules separately from API credential controls. Review the security dashboard and alert delivery for your plan. The pack performs a narrow read-only or local evidence check; no live tenant validation or configuration writes were performed.

## Table of Contents

1. [Security Configuration](#1-security-configuration)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Security Configuration

### 1.1 Enforce SSO with tested recovery

**Profile Level:** L1 (Crawl)

**NIST 800-53:** IA-2

#### Description

Require a managed identity provider and preserve a documented emergency recovery route.

#### Rationale

- Managed authentication reduces exposure when local credentials or identity assignments survive ordinary personnel changes.

#### ClickOps Implementation

Under Settings → Security Center → Single sign-on, configure and test the identity provider, then enforce SSO after validating administrator recovery. Require MFA in the identity provider where Pipedrive local password and 2FA settings are hidden by enforcement.

Source: [Pipedrive documentation](https://support.pipedrive.com/en/article/troubleshoot-single-sign-on-issues) (checked 2026-11-27).

**Automation:** Review and change this control in the documented admin interface; no policy mutation is packaged.

#### Validation & Testing

Check sign-in in a fresh browser and confirm alternate login methods are blocked for a managed test user. Review mobile and API access separately.

---

### 1.2 Remove unnecessary personal token access

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-6

#### Description

Limit access to user-scoped personal tokens and separately approve app connections.

#### Rationale

- Constrain effective entitlement to the minimum needed and review privileged claims rather than assuming UI and API access are identical.

#### ClickOps Implementation

Under Settings → Manage Users → Permission sets, review Global regular user → Tools and setup → Access their own API token. Disable unneeded access and inventory integrations first. Review OAuth scopes, permission sets and visibility groups separately.

Source: [Pipedrive documentation](https://support.pipedrive.com/en/article/can-all-users-access-the-pipedrive-api?category=account-settings) (checked 2026-11-27).

**Automation:** Review and change this control in the documented admin interface; no policy mutation is packaged.

#### Validation & Testing

Confirm an ordinary test user cannot use the restricted token path; independently confirm separately approved OAuth integrations still work.

---

### 1.3 Bind OAuth evidence to the expected company and user

**Profile Level:** L1 (Crawl)

**NIST 800-53:** IA-4

#### Description

Identify which company and identity an existing integration token actually represents.

#### Rationale

- An integration can appear healthy while bound to the wrong account or user.

#### ClickOps Implementation

Confirm the intended company identifier and integration identity using an approved tenant record. Compare against the authorized user profile returned by the documented Users endpoint. Review Security dashboard → Audit log separately on eligible plans.

Source: [Pipedrive documentation](https://developers.pipedrive.com/docs/api/v1/Users) (checked 2026-11-27).

**Automation:** The Users API authenticates the calling OAuth identity. No customer CRM records, user email address, or administrator-scoped permission endpoint is collected.

#### Code Implementation

{% include pack-code.html vendor="pipedrive" section="1.3" %}

#### Validation & Testing

Confirm the pack only succeeds for the expected company ID and expected user ID. It does not certify OAuth scopes, visibility, login rules, reporting plan or security policy.

## 2. Compliance Quick Reference

These mappings describe control objectives, not certification.

| HTH control | Objective | NIST SP 800-53 Rev. 5 |
|-------------|-----------|-----------------------|
| 1.1 | Enforce SSO with tested recovery | IA-2 |
| 1.2 | Remove unnecessary personal token access | AC-6 |
| 1.3 | Bind OAuth evidence to the expected company and user | IA-4 |

### References

- [Pack source and coverage boundaries](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-business-source-coverage.md)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Changelog

| Version | Date | Maturity | Changes |
|---------|------|----------|---------|
| 0.1.0 | 2026-11-27 | ai-drafted | Initial control guide and offline-tested evidence pack. |
