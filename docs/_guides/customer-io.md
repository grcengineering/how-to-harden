---
layout: guide
title: "Customer.io Hardening Guide"
vendor: "Customer.io"
slug: "customer-io"
tier: "2"
category: "Marketing"
description: "Harden Customer.io administrative access and verify scoped control evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Customer.io account and workspace administration, not the consumer identity systems that feed Journey events.

### Intended Audience

- Tenant and identity administrators responsible for access and configuration
- Security or assurance reviewers responsible for control evidence

### How to Use This Guide

L1 (Crawl) is the supported baseline here. Confirm the exact tenant, plan, and responsible administrator before testing with synthetic evidence or an approved nonproduction account.

### Scope

App API IP allowlisting is separate from sign-in protection. A broader private key cannot substitute for the account audit-only key and can expose unrelated customer data. The pack performs a narrow read-only or local evidence check; no live tenant validation or configuration writes were performed.

## Table of Contents

1. [Security Configuration](#1-security-configuration)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Security Configuration

### 1.1 Require managed workforce sign-in

**Profile Level:** L1 (Crawl)

**NIST 800-53:** IA-2

#### Description

Put managed teammates behind your identity provider and track guests separately.

#### Rationale

- Managed authentication reduces exposure when local credentials or identity assignments survive ordinary personnel changes.

#### ClickOps Implementation

Use Account settings → Security → Single sign-on with approved IdP and MFA. Consider SCIM where supported and review guest access separately: guests follow their home account login requirements.

Source: [Customer.io documentation](https://docs.customer.io/accounts/settings/login-with-sso/) (checked 2026-11-27).

**Automation:** Review and change this control in the documented admin interface; no policy mutation is packaged.

#### Validation & Testing

Use sanctioned test identities to verify workforce MFA, removal and a guest exception check. Account Admins automatically receive all-workspace access; review grants separately.

---

### 1.2 Constrain App API use by workspace and source IP

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-17

#### Description

Make a valid App credential insufficient when a request originates outside approved egress.

#### Rationale

- Restrict the path from which integration credentials can be used; valid credentials by themselves should not authorize requests from arbitrary networks.

#### ClickOps Implementation

Under Account Settings → API Credentials, inventory workspace-specific keys and restrict accepted App API source IPs for the workspace. Use only approved stable egress IPs and confirm which integrations this policy covers before enforcing.

Source: [Customer.io documentation](https://docs.customer.io/accounts/settings/managing-credentials/) (checked 2026-11-27).

**Automation:** Review and change this control in the documented admin interface; no policy mutation is packaged.

#### Validation & Testing

Validate authorized and non-allowlisted source behavior with test traffic and confirm legitimate integrations and credential rotation continue to work. This is not a universal Pipelines or Track API restriction.

---

### 1.3 Use an audit-only key for account evidence

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AU-6

#### Description

Collect limited security activity evidence without granting access to customer profiles or sending capability.

#### Rationale

- Review source records and minimize the confidential information written into evidence systems.

#### ClickOps Implementation

Under Account Settings → API Credentials, a continuing Account Admin creates a private key limited to audit logs. Review Account settings → Audit logs, and explicitly select account scope instead of assuming one workspace log covers all activity.

Source: [Customer.io documentation](https://docs.customer.io/accounts/audit-logs/) (checked 2026-11-27).

**Automation:** The App API request fetches one latest page of up to 20 account events. Use an audit-only key in the correctly selected region, and treat an empty page as insufficient evidence to identify the account. No user email, IP address, event ID or detailed data is printed.

#### Code Implementation

{% include pack-code.html vendor="customer-io" section="1.3" %}

#### Validation & Testing

Confirm the expected account and region; compare summary counts with the same query scope. One bounded page cannot verify audit completeness or the presence or absence of a control.

## 2. Compliance Quick Reference

These mappings describe control objectives, not certification.

| HTH control | Objective | NIST SP 800-53 Rev. 5 |
|-------------|-----------|-----------------------|
| 1.1 | Require managed workforce sign-in | IA-2 |
| 1.2 | Constrain App API use by workspace and source IP | AC-17 |
| 1.3 | Use an audit-only key for account evidence | AU-6 |

### References

- [Pack source and coverage boundaries](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-business-source-coverage.md)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Changelog

| Version | Date | Maturity | Changes |
|---------|------|----------|---------|
| 0.1.0 | 2026-11-27 | ai-drafted | Initial control guide and offline-tested evidence pack. |
