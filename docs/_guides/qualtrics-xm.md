---
layout: guide
title: "Qualtrics XM Hardening Guide"
vendor: "Qualtrics XM"
slug: "qualtrics-xm"
tier: "2"
category: "Data"
description: "Limit Qualtrics sign-in and proxy access, minimize brand administration and inspect user evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

This guide covers Qualtrics XM brand settings and organization users. It does not cover respondent identity, survey authentication, product-specific licensing or policy inherited from an enterprise identity provider.

### Intended Audience

- Tenant administrators, business system owners and integration operators
- Security engineers and reviewers who need traceable configuration evidence

### How to Use This Guide

L1 (Crawl) is the initial baseline. Inventory the current behavior, confirm plan requirements, and pilot changes with approved nonproduction identities and synthetic data before changing production settings.

### Scope

This guide covers the controls below, with offline-tested evidence only. No live tenant or credentials were used. Code Packs do not perform remediation, assert complete audit coverage, or inspect tenant configuration beyond their named read.

## Table of Contents

1. [Security Configuration](#1-security-configuration)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Security Configuration

### 1.1 Separate native and federated sign-in controls

**Profile Level:** L1 (Crawl)

**NIST 800-53:** IA-2

#### Description

Require the appropriate second factor on both applicable login paths.

#### Rationale

- Native 2FA does not apply to SSO users; leaving both paths open without separate tests can give a user a weaker alternative.

#### ClickOps Implementation

In **Admin → Organization Settings → Authentication**, review the available login types. Enable native **Two-factor Authentication** for non-SSO users where required. Set phishing-resistant MFA for federated users at the IdP and review the branded URL's alternate-login options. Test a recovery path and coordinate disabling any unused option with the organization owner.

Source: [Qualtrics XM documentation](https://www.qualtrics.com/support/survey-platform/sp-administration/organization-settings/) (checked 2026-11-27).

**Automation:** No public write operation for this exact brand login policy was verified.

#### Validation & Testing

Use fresh sessions for native and federated users. Verify the expected factor and recovery path separately. Qualtrics says participant user types are not covered by the native 2FA rule.

---

### 1.2 Disable routine proxy logins

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-6

#### Description

Allow direct sign-in to another user's account only under a reviewed, documented exception.

#### Rationale

- Proxy login gives an administrator direct access as another user and can expand the exposure of surveys, dashboards and respondent data.

#### ClickOps Implementation

In **Admin → Security**, inspect **Allow Proxy Logins** and deselect it where there is no approved requirement. Confirm separate Employee Experience behavior and choose an approved support workflow for troubleshooting issues without impersonation.

Source: [Qualtrics XM documentation](https://www.qualtrics.com/support/survey-platform/sp-administration/security-tab/) (checked 2026-11-27).

**Automation:** No supported API setter for this proxy policy was verified.

#### Validation & Testing

Verify a selected administrator no longer has the expected proxy option for a test user while authorized normal admin work remains possible. Review the Security audit event catalog for the types your organization is entitled to see.

---

### 1.3 Review one account's division and expiry

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-6

#### Description

Reconcile the known organization's user type in the UI and corroborate tenant, division and expiration through the bounded API read.

#### Rationale

- Administrative user types and division assignment impact which project and brand data are visible. An API token inherits capability from its owning identity; fetching someone else's record requires Brand Administrator access.

#### ClickOps Implementation

In **Admin → Users**, inspect the exact account, entitlement and user type. Retain the approved user ID, minimally privileged credential and expected assignment in the access review. Do not create a privileged account simply to run a pack when direct review is enough.

Source: [Qualtrics XM documentation](https://developer-docs.qualtrics.com/docs/public-api/guides/common-tasks/managing-users/) (checked 2026-11-27).

**Automation:** The Users API supports reads and writes. This pack only reads metadata for one user and never retrieves that user's API token.

#### Code Implementation

{% include pack-code.html vendor="qualtrics-xm" section="1.3" %}

#### Validation & Testing

Compare the returned organization, division and expiry to the approved record, then verify the account's assigned user type in the UI. Use a harmless test project to verify actual capabilities separately.

## 2. Compliance Quick Reference

These relationships support the named control objectives. They are not certification or compliance claims.

| HTH control | Objective | NIST SP 800-53 Rev. 5 |
|-------------|-----------|-----------------------|
| 1.1 | Separate native and federated sign-in controls | IA-2 |
| 1.2 | Disable routine proxy logins | AC-6 |
| 1.3 | Review one account's division and expiry | AC-6 |

### References

- [Users API authentication scope](https://developer-docs.qualtrics.com/docs/public-api/users/users/)
- [Qualtrics identifiers](https://www.qualtrics.com/support/integrations/api-integration/finding-qualtrics-ids/)
- [Coverage and validation boundaries](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-data-platform-next-source-coverage.md)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Changelog

| Version | Date | Maturity | Changes |
|---------|------|----------|---------|
| 0.1.0 | 2026-11-27 | ai-drafted | Initial customer controls and a read-only evidence pack; no live tenant validation. |
