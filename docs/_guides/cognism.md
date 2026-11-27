---
layout: guide
title: "Cognism Hardening Guide"
vendor: "Cognism"
slug: "cognism"
tier: "2"
category: "Marketing"
description: "Harden Cognism administrative access and verify scoped control evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Cognism’s workforce console and current M2M Connect API. Do not apply OAuth assumptions to the separately documented older API-key interface.

### Intended Audience

- Tenant and identity administrators responsible for access and configuration
- Security or assurance reviewers responsible for control evidence

### How to Use This Guide

L1 (Crawl) is the supported baseline here. Confirm the exact tenant, plan, and responsible administrator before testing with synthetic evidence or an approved nonproduction account.

### Scope

No account setting writes or CRM/people data reads are packaged. For compliance configuration changes, use the supported vendor process rather than assuming a writable endpoint. The pack performs a narrow read-only or local evidence check; no live tenant validation or configuration writes were performed.

## Table of Contents

1. [Security Configuration](#1-security-configuration)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Security Configuration

### 1.1 Require managed workforce authentication

**Profile Level:** L1 (Crawl)

**NIST 800-53:** IA-2

#### Description

Use a centrally managed IdP for employee sign-in.

#### Rationale

- Managed authentication reduces exposure when local credentials or identity assignments survive ordinary personnel changes.

#### ClickOps Implementation

Open Settings → Authentication as a Cognism Admin and configure the supported IdP. Confirm the use of scoped workforce assignments and IdP MFA; keep a documented recovery procedure until managed sign-in works.

Source: [Cognism documentation](https://help.cognism.com/hc/en-gb/articles/40038595894034-Setting-up-Single-Sign-On-guide) (checked 2026-11-27).

**Automation:** Review and change this control in the documented admin interface; no policy mutation is packaged.

#### Validation & Testing

Test sign-in and denied access with approved users, and separately verify local fallback, if any. Do not treat an IdP assignment alone as evidence a seat exists.

---

### 1.2 Separate workspace delegation from security administration

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-6

#### Description

Give workspace managers only routine workspace access and protect integration credentials.

#### Rationale

- Constrain effective entitlement to the minimum needed and review privileged claims rather than assuming UI and API access are identical.

#### ClickOps Implementation

Delegate routine workspace access to Workspace Managers rather than Admins. Reserve SSO/SCIM, M2M Connect credential creation and external integration setup for approved admins. Review integration owners and exclude M2M secrets from clients and repositories.

Source: [Cognism documentation](https://help.cognism.com/hc/en-gb/articles/38961280654738-Using-the-Workspace-Manager-role) (checked 2026-11-27).

**Automation:** Review and change this control in the documented admin interface; no policy mutation is packaged.

#### Validation & Testing

Check that a test Workspace Manager can perform the intended work but cannot change Authentication or issue credentials. Inventory and rotate service credentials separately.

---

### 1.3 Detect drift in account contact restrictions

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AU-6

#### Description

Compare a bounded read of account privacy settings against the reviewed baseline.

#### Rationale

- Review source records and minimize the confidential information written into evidence systems.

#### ClickOps Implementation

Compare the approved DNC-masking and geographic restrictions with the actual configuration using the authorized account API. Record the restricted geography approval and save the approved settings JSON in a protected location; only the digest, not contact data, is needed for routine comparison.

Source: [Cognism documentation](https://docs.cognism.com/reference/getcompliancesettings) (checked 2026-11-27).

**Automation:** One read-only GET to current Cognism M2M API. Supply the SHA-256 computed from the approved, independently reviewed compliance JSON by serializing one object with jq -cS and retaining its terminating newline. The output only reports whether it matches, not the underlying rules. Match does not prove regulatory compliance or token tenant identity.

#### Code Implementation

{% include pack-code.html vendor="cognism" section="1.3" %}

#### Validation & Testing

Use an independently approved baseline digest and verified account token. A changed digest requires manual review, and equality does not verify contacts already exported or the account identity.

## 2. Compliance Quick Reference

These mappings describe control objectives, not certification.

| HTH control | Objective | NIST SP 800-53 Rev. 5 |
|-------------|-----------|-----------------------|
| 1.1 | Require managed workforce authentication | IA-2 |
| 1.2 | Separate workspace delegation from security administration | AC-6 |
| 1.3 | Detect drift in account contact restrictions | AU-6 |

### References

- [Pack source and coverage boundaries](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-enterprise-data-source-coverage.md)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Changelog

| Version | Date | Maturity | Changes |
|---------|------|----------|---------|
| 0.1.0 | 2026-11-27 | ai-drafted | Initial control guide and offline-tested evidence pack. |
