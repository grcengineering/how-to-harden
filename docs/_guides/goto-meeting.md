---
layout: guide
title: "GoTo Meeting Hardening Guide"
vendor: "GoTo Meeting"
slug: "goto-meeting"
tier: "3"
category: "Productivity"
description: "Harden GoTo Meeting organizer access and private meeting workflows."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden GoTo Meeting organizer access and private meeting workflows.

**Validation status:** Documented control paths and offline Code Pack behavior; no live tenant, credentials, or production changes. License and effective permissions may limit visibility.

### Intended Audience

Platform owners, identity administrators, and security reviewers.

### How to Use This Guide

- **L1 (Crawl):** Establish accountable identities and least privilege.
- **L2 (Walk):** Add narrower access boundaries and independent monitoring.

### Scope

GoTo Meeting only; identity and account inventory may be shared across GoTo products. GoTo Connect voice, Webinar and Training settings are not assessed.

## Table of Contents

1. [Access and Administration](#1-access-and-administration)
2. [Sharing, Integrations and Audit](#2-sharing-integrations-and-audit)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Access and Administration

### 1.1 Constrain organizer and administrator access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6, IA-2(1) |

#### Description

Federate managed organizers, require IdP MFA, and restrict GoTo admin roles.

#### Rationale

**Why This Matters:**

- GoTo account visibility is distinct from each product license and effective sign-in enforcement.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://learn.microsoft.com/en-us/entra/identity/saas-apps/citrix-gotomeeting-tutorial).
2. Configure enterprise sign-in for the verified domain and pilot the organization policy before enforcement. In the GoTo Admin Center reconcile administrators and Meeting organizers to the currently approved roster.

**Automation:** The account evidence pack checks the exact account is visible to an approved GoTo Admin token; it does not prove product licensing or SSO enforcement.

#### Code Implementation

{% include pack-code.html vendor="goto-meeting" section="1.1" %}

#### Validation & Testing

Confirm expected managed and recovery login behavior. Verify independently whether legacy direct logins remain available.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6, IA-2(1) |

### 1.2 Restrict entry to confidential meetings

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3 |

#### Description

Use a meeting passcode and lock the meeting when the attendee list is established.

#### Rationale

**Why This Matters:**

- Possession of a meeting link or ID is not an identity assertion. Meeting lock and passcode are independent controls.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://www.goto.com/meeting/features).
2. Enable passcode protection before sending the invitation. Share the secret through an approved channel, use unique meeting credentials, lock the session and admit only expected guests.

**Automation:** No account-wide enforcement via Meeting API is asserted.

#### Validation & Testing

Verify a host and authorized guest can join, and test an unauthorized attendee against the lock using a benign session.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3 |

## 2. Sharing, Integrations and Audit

### 2.1 Restrict recording and transcript distribution

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AU-11 |

#### Description

Record and transcribe only approved meeting types and control access to produced artifacts.

#### Rationale

**Why This Matters:**

- Removing a participant or ending a session does not revoke a link that was already distributed or an exported copy.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://www.goto.com/meeting/features).
2. Review organizer recording and transcription choices. Confirm approved retention and sharing practice before producing artifacts; review active shares independently.

**Automation:** The guide does not download recordings or transcripts.

#### Validation & Testing

In a non-sensitive test meeting, verify effective recording and transcript access for an approved viewer and anonymous browser, and document deletion behavior.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AU-11 |

## 3. Compliance Quick Reference

These mappings support control design; they are not evidence of certification or operating effectiveness.

| Section | Control | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 | Constrain organizer and administrator access | AC-2, AC-6, IA-2(1) |
| 1.2 | Restrict entry to confidential meetings | AC-3 |
| 2.1 | Restrict recording and transcript distribution | AC-3, AU-11 |

## Changelog

- **0.1.0 (2026-11-27):** Initial guide and documented automation examples.
