---
layout: guide
title: "Document360 Hardening Guide"
vendor: "Document360"
slug: "document360"
tier: "3"
category: "Productivity"
description: "Harden Document360 project roles, API keys, reader boundaries and audit review."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden Document360 project roles, API keys, reader boundaries and audit review.

**Validation status:** Documented control paths and offline Code Pack behavior; no live tenant, credentials, or production changes. License and effective permissions may limit visibility.

### Intended Audience

Platform owners, identity administrators, and security reviewers.

### How to Use This Guide

- **L1 (Crawl):** Establish accountable identities and least privilege.
- **L2 (Walk):** Add narrower access boundaries and independent monitoring.

### Scope

Document360 SaaS projects and reader sites. The [privacy notice](https://document360.com/privacy/) describes the Kovai group relationship. Plans differ; distinguish the editor portal, public or private reader site, and API v2/v3.

## Table of Contents

1. [Access and Administration](#1-access-and-administration)
2. [Sharing, Integrations and Audit](#2-sharing-integrations-and-audit)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Access and Administration

### 1.1 Separate editorial administration from reader access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6, IA-2(1) |

#### Description

Minimize project and content roles and enforce IdP MFA for supported managed editor identities.

#### Rationale

**Why This Matters:**

- Reader permission is not equivalent to editor authorization; portal and content permissions can both affect access.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://docs.document360.com/docs/user-overview).
2. Review Team Accounts and the role assignments for project, workspace and content scope. Assign only required rights and maintain named, monitored recovery accounts.

**Automation:** Policy is verified in the portal and IdP, not inferred from project API response.

#### Validation & Testing

Test a reader and a narrowly scoped editor independently; confirm the editor cannot manage roles or publish beyond their approval.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6, IA-2(1) |

### 1.2 Verify v3 API key project scope

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 |

#### Description

Create separate v3 keys for specific projects and required permissions, and retain explicit owners and rotation plans.

#### Rationale

**Why This Matters:**

- An account-wide key can reach multiple projects; a successful call alone does not prove least privilege.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://docs.document360.com/docs/api-keys).
2. In Settings → Knowledge base portal → API keys, inspect scopes and operations. Rotate key material in the consuming system before revoking the replaced key. Review legacy v2 separately.

**Automation:** The read-only pack checks visible projects; it does not validate allowed actions or configured grants.

#### Code Implementation

{% include pack-code.html vendor="document360" section="1.2" %}

#### Validation & Testing

Check that the v3 inventory returns exactly the expected project with no more pages, then independently verify action permissions and actual configured scope in the portal.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 |

## 2. Sharing, Integrations and Audit

### 2.1 Test private and mixed knowledge bases

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3 |

#### Description

Make restricted documentation visible only to approved reader groups.

#### Rationale

**Why This Matters:**

- A mixed site can have both public and private areas; testing only the home page does not establish article access.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://docs.document360.com/docs/reader-management).
2. Review site visibility and reader group memberships. Evaluate representative restricted content, attachments and workspace access under approved test identities.

**Automation:** The guide does not expose or retrieve private articles.

#### Validation & Testing

Check representative private content with a named reader, a reader outside the intended group and an anonymous browser session.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3 |

### 2.2 Validate team auditing coverage

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6, AU-12 |

#### Description

Select relevant project audit categories and retain approved filtered evidence.

#### Rationale

**Why This Matters:**

- A filtered export can omit events; MCP events are not separately visible in this view.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://docs.document360.com/docs/team-auditing).
2. Open Settings → Knowledge base portal → Team auditing and review Audit configuration. Establish explicit windows, categories and secure storage for exports.

**Automation:** Use the portal; no streaming API or completeness claim is made.

#### Validation & Testing

Generate and verify a benign approved test event with actor and time, and note exclusions and retention.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6, AU-12 |

## 3. Compliance Quick Reference

These mappings support control design; they are not evidence of certification or operating effectiveness.

| Section | Control | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 | Separate editorial administration from reader access | AC-6, IA-2(1) |
| 1.2 | Verify v3 API key project scope | AC-6, IA-5 |
| 2.1 | Test private and mixed knowledge bases | AC-3 |
| 2.2 | Validate team auditing coverage | AU-6, AU-12 |

## Changelog

- **0.1.0 (2026-11-27):** Initial guide and documented automation examples.
