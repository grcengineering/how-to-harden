---
layout: guide
title: "Freshdesk Hardening Guide"
vendor: "Freshdesk"
slug: "freshdesk"
tier: "3"
category: "IT Operations"
description: "Harden Freshdesk helpdesk authentication, agent privileges, network restrictions and audit review."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden Freshdesk helpdesk authentication, agent privileges, network restrictions and audit review.

[Freshworks operates this product](https://www.freshworks.com/freshdesk/helpdesk-features/). The [Freshservice guide](/guides/freshservice/) covers a separate product and does not configure a Freshdesk tenant.

**Validation status:** Documented control paths and offline Code Pack behavior; no live tenant, credentials, or production changes. License and effective permissions may limit visibility.

### Intended Audience

Platform owners, identity administrators, and security reviewers.

### How to Use This Guide

- **L1 (Crawl):** Establish accountable identities and least privilege.
- **L2 (Walk):** Add narrower access boundaries and independent monitoring.

### Scope

Freshdesk cloud tenant and Freshworks Neo Admin Center for Freshdesk identity. Freshservice and Freshdesk Omni menus and plan availability can differ.

## Table of Contents

1. [Access and Administration](#1-access-and-administration)
2. [Network, Integrations and Audit](#2-network-integrations-and-audit)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Access and Administration

### 1.1 Require controlled agent authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2(1) |

#### Description

Apply agent sign-in policy in Freshworks Neo Admin Center; enforce MFA at the appropriate identity plane.

#### Rationale

**Why This Matters:**

- Customer and agent authentication serve different users. Confusing their policies can weaken privileged sign-in or disrupt external support.

#### ClickOps Implementation

1. Confirm the available plan and effective administrative permissions in the [vendor documentation](https://support.freshdesk.com/support/solutions/articles/50000003133-what-is-freshworks-neo-admin-center-).
2. Open the organization’s Neo Admin Center and review Centralized Security. Confirm the Freshdesk account and intended agent policy before configuring your supported SSO method. Apply MFA at the IdP and review local-account password and two-factor policy for documented exceptions.

**Automation:** The Freshdesk product API references do not establish an organization authentication-policy write path; use the administration UI.

#### Validation & Testing

Verify successful IdP sign-in for a test agent and verify that disallowed local sign-in is rejected without impacting the public contact flow. Retain and document a tested recovery path.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2(1) |

### 1.2 Minimize agent roles and ticket scope

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Grant agents only the permissions and data scope their work requires.

#### Rationale

**Why This Matters:**

- Agent scope governs ticket visibility separately from a role; a service account with broad role and global scope exposes support records.

#### ClickOps Implementation

1. Confirm the available plan and effective administrative permissions in the [vendor documentation](https://support.freshdesk.com/support/solutions/articles/97077-creating-a-custom-role).
2. Open Admin → Team → Roles and review preset and custom permissions. When supported, create narrow roles and assign them to named agents, then review each agent’s ticket visibility scope and groups. Keep privileged agent credentials out of integrations that do not require them.

**Automation:** The API pack inventories one page of visible agents and minimizes output to assignment fields. An empty page alone is not a coverage attestation; review all pages and compare expected membership.

#### Code Implementation

{% include pack-code.html vendor="freshdesk" section="1.2" %}

#### Validation & Testing

Use an admin-approved inventory across all pages and compare agent IDs, scopes and role IDs to approved assignments. Verify a nonprivileged test agent cannot view an out-of-scope test ticket.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

## 2. Network, Integrations and Audit

### 2.1 Restrict agent ingress on eligible plans

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-17 |

#### Description

Restrict access to the agent portal from approved egress where plan and operating requirements allow.

#### Rationale

**Why This Matters:**

- Immediately effective restrictions can break legitimate agent access or public support if applied across all channels unintentionally.

#### ClickOps Implementation

1. Confirm the available plan and effective administrative permissions in the [vendor documentation](https://support.freshdesk.com/support/solutions/articles/195168-restrict-access-to-your-support-portal-using-ip-address).
2. In a sandbox first, open Admin → Security and review IP Allow/Block list settings. Choose Agent portal scope unless the policy explicitly applies to all channels. Record known operator VPN egress and recovery instructions before saving.

**Automation:** No tenant-wide IP allow-list write API was verified; this implementation uses documented UI settings.

#### Validation & Testing

Verify a permitted agent can sign in and an ordinary test sign-in outside allowed egress is blocked. Confirm externally facing support and approved integrations still work as designed.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-17 |

### 2.2 Review administrative audit events

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-12 |

#### Description

Review documented agent, authentication and automation audit events on eligible plans.

#### Rationale

**Why This Matters:**

- Administrative access drift can otherwise persist until an incident or periodic review.

#### ClickOps Implementation

1. Confirm the available plan and effective administrative permissions in the [vendor documentation](https://support.freshdesk.com/support/solutions/articles/235745-track-helpdesk-changes-using-audit-log).
2. Use Admin → Account → Audit Log in Freshdesk. Filter agent and authentication events by time and actor. Verify security review covers relevant automation rule changes too.

**Automation:** No supported Freshdesk audit export API was verified in the product API index.

#### Validation & Testing

Compare an approved sandbox role or automation change with the recorded actor, scope and timestamp. Record gaps in event coverage rather than assuming all edits are captured.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-12 |

## 3. Compliance Quick Reference

These mappings support control design; they are not evidence of certification or operating effectiveness.

| Section | Control | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 | Require controlled agent authentication | IA-2(1) |
| 1.2 | Minimize agent roles and ticket scope | AC-6 |
| 2.1 | Restrict agent ingress on eligible plans | AC-17 |
| 2.2 | Review administrative audit events | AU-12 |

## References

- [Freshdesk REST API](https://developers.freshdesk.com/api/)
- [Freshworks Neo Admin Center](https://support.freshdesk.com/support/solutions/articles/50000003133-what-is-freshworks-neo-admin-center-)

## Changelog

- **0.1.0 (2026-11-27):** Initial guide and documented automation examples.
