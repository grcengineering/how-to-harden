---
layout: guide
title: "Expiration Reminder Hardening Guide"
vendor: "Expiration Reminder"
slug: "expiration-reminder"
tier: "1"
category: "IT Operations"
description: "Harden the Expiration Reminder customer account."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden the Expiration Reminder customer account. The guide covers access, authentication, API credentials and audit logs without reading document contents or changing reminders.

### Intended Audience

Tenant administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Establish the essential controls before production rollout.
- **L2 (Walk):** Stage the additional restrictions with a representative pilot and a recovery path.
- **L3 (Run):** Validate applicability, evidence retention, and approval requirements for regulated use.

### Scope

This guide addresses customer-controlled settings, not the vendor's internal service security. Feature availability depends on the contract and tenant. Settings were checked against documentation; no live tenant was tested or modified.

## Table of Contents

1. [Account and records](#1-account-and-records)
2. [Integration and evidence](#2-integration-and-evidence)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Account and records

### 1.1 Restrict users to approved roles and owned records

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6 |

#### Description

Minimize Admin, Manager and broad read roles, and use owner-scoped roles where the task only covers assigned expiration items or contacts.

#### Rationale

**Why This Matters:**

- A read-only Viewer can still read all expirations and contacts; a contact notification record is not equivalent to a user login.

#### Prerequisites

Approved role matrix, authorized account administrator and a test record.

#### ClickOps Implementation

1. Open account settings and review enabled user roles separately from contacts that only receive notices.
2. Compare broad access to business need. Use Owner on approved expiration items or contacts for roles whose scope depends on ownership.
3. Review existing User, contact and record ownership when staff leave or change duties.

#### Validation & Testing

Verify a pilot cannot see an unrelated synthetic record and retains appropriate access to an approved owned record.

#### Monitoring & Maintenance

Recertify roles and ownership after staff changes and periodically.

#### Operational Impact & Rollback

Restore only the previously approved role or record ownership for the affected user and verify the scope again.

**Sources:** [Expiration Reminder User Roles](https://help.expirationreminder.com/user-roles-access-privileges). [Expiration Reminder owner-based access](https://help.expirationreminder.com/managing-permissions).

### 1.2 Protect sign-in and provisioning

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | IA-2, AC-2 |

#### Description

Prefer SSO with IdP-enforced MFA where entitled. If not using SSO, consider the platform’s available 2FA as a fallback; the vendor says the two modes cannot be combined.

#### Rationale

**Why This Matters:**

- Stale local or provisioned accounts may retain access to personnel and compliance records.

#### Prerequisites

Tenant administrator, IdP administrator and trusted recovery access.

#### ClickOps Implementation

1. Review SSO and SCIM eligibility. For a non-SSO account, review Settings > Customize > Features > Two-Factor Authentication; codes are sent by email or mobile message.
2. Validate IdP MFA and assigned pilot users before expanding; review account removal separately from contact notification records.
3. Confirm the recovery administrator can sign in through the approved route and test the offboarding procedure in a pilot.

#### Validation & Testing

Verify intended pilot sign-in and offboarding without exposing user contact or document data.

#### Monitoring & Maintenance

Review authentication options and mappings after IdP and subscription changes.

#### Operational Impact & Rollback

Restore the prior verified pilot configuration through a tested recovery route.

**Sources:** [Expiration Reminder authentication controls](https://help.expirationreminder.com/users-security-account-settings). [Expiration Reminder 2FA and its incompatibility with SSO](https://help.expirationreminder.com/two-factor-authentication).

## 2. Integration and evidence

### 2.1 Review and rotate API credentials

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | IA-5, AC-6 |

#### Description

Inventory named API keys for entitled accounts and restrict use to approved users and integrations.

#### Rationale

**Why This Matters:**

- The documentation does not establish a separate narrow event-read scope for API keys; a read-only script does not make the underlying key read-only.

#### Prerequisites

Business or Enterprise plan with authorized credential creation and secure storage.

#### ClickOps Implementation

1. Go to Account Settings > Personal > Manage API Keys and reconcile keys to named owners and approved purposes.
2. Use a dedicated approved integration identity if your account allows it and keep credentials in the approved secret manager.
3. Rotate by creating and verifying a replacement before revoking the old key; revoked keys cannot be reactivated.

#### Validation & Testing

Verify the intended integration with an approved read and inspect actual role restrictions separately. Do not widen token permissions on failure.

#### Monitoring & Maintenance

Review key owners, plan entitlement and integration use after staff changes and periodically.

#### Operational Impact & Rollback

Issue a new authorized credential for the same intended access if a revoked key is needed; the previous key is not recoverable.

**Sources:** [Expiration Reminder API key setup](https://help.expirationreminder.com/api-and-expiration-reminder).

### 2.2 Review account audit events without exporting personal details

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-2, AU-6, AU-9 |

#### Description

Monitor sign-ins, material record changes and notification delivery events in the authorized account.

#### Rationale

**Why This Matters:**

- An account-wide audit response may contain names, emails and other details; summary output should not disclose them.

#### Prerequisites

Account administrator or authorized event reviewer; optional approved API key for the evidence read.

#### ClickOps Implementation

1. Open Settings > Security > Audit Log and filter the appropriate action, user or time range.
2. Correlate known authorized changes and failed notifications with operational owners and preserve only necessary evidence.
3. Where appropriate, use the approved native event log API to check event availability. Review scope and secure execution before using an API key.

#### Code Implementation

{% include pack-code.html vendor="expiration-reminder" section="2.2" %}

#### Validation & Testing

Confirm a known authorized event in the UI. The pack reports page and type counts, not event details or delivery success.

#### Monitoring & Maintenance

Review audit coverage and delivery failures regularly; verify Advanced Reporting entitlement separately.

#### Operational Impact & Rollback

Correct only affected evidence access and preserve required history.

**Sources:** [Expiration Reminder UI Audit Log](https://help.expirationreminder.com/audit-log). [Expiration Reminder REST event logs](https://developers.expirationreminder.com/api-reference/event-log-get-all-event-logs).

## 3. Compliance Quick Reference

These are thematic NIST mappings, not a benchmark, certification, or evidence of implementation.

| Control | NIST SP 800-53 Rev. 5 |
|---|---|
| 1.1 Restrict users to approved roles and owned records | AC-2, AC-6 |
| 1.2 Protect sign-in and provisioning | IA-2, AC-2 |
| 2.1 Review and rotate API credentials | IA-5, AC-6 |
| 2.2 Review account audit events without exporting personal details | AU-2, AU-6, AU-9 |

## Appendix A: Automation and applicability

The read-only pack uses the current per-endpoint reference host api.expirationreminder.com; an older Key Concepts page mentions a .net host. Verify any tenant-specific hostname with the provider, and do not send tokens to redirects or alternative hosts. The pack does not read documents or change notification settings.

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial tenant hardening controls and read-only verification | How to Harden Community |

## Contributing

Submit corrections and sanitized verification evidence through [GitHub](https://github.com/grcengineering/how-to-harden). Never attach tenant exports or secrets.
