---
layout: guide
title: "AWS Hardening Guide"
vendor: "AWS"
slug: "aws"
tier: "3"
category: "IT Operations"
description: "Harden the AWS Organizations control plane, trusted integrations and organization audit trail."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden the AWS Organizations control plane, trusted integrations and organization audit trail.

**Validation status:** Documented control paths and offline Code Pack behavior; no live tenant, credentials, or production changes. License and effective permissions may limit visibility.

### Intended Audience

Platform owners, identity administrators, and security reviewers.

### How to Use This Guide

- **L1 (Crawl):** Establish accountable identities and least privilege.
- **L2 (Walk):** Add narrower access boundaries and independent monitoring.

### Scope

This is a bounded AWS Organizations and CloudTrail baseline for the commercial partition, not workload, service, identity-provider or network hardening. See [AWS IAM Identity Center](/guides/aws-iam-identity-center/) for the distinct workforce identity plane.

## Table of Contents

1. [Access and Administration](#1-access-and-administration)
2. [Sharing, Integrations and Audit](#2-sharing-integrations-and-audit)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Access and Administration

### 1.1 Verify organization scope and SCP guardrails

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-6 |

#### Description

Keep management-account access exceptional; use reviewed service control policies (SCPs) at named organizational units.

#### Rationale

**Why This Matters:**

- An SCP sets a maximum permissions boundary, not a grant; it does not restrict principals in the management account or service-linked roles.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html).
2. Confirm all-features mode and the expected organization ID. Inventory root, OU and member-account attachments. Test any proposed deny with sandbox accounts and preserve management-account recovery before rollout.

**Automation:** The CLI pack reports identity/mode and a bounded SCP catalog of visible definitions; it is not proof of attachment coverage or effective permissions.

#### Code Implementation

{% include pack-code.html vendor="aws" section="1.1" %}

#### Validation & Testing

Confirm expected organization ID and mode, then review a test account’s complete ancestry and applicable policies. Verify representative approved tasks and an intended denied operation without modifying production.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-6 |

### 1.2 Review trusted access and delegated administration

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6, AC-2 |

#### Description

Record each trusted service, delegated administrator, external principal and integration owner.

#### Rationale

**Why This Matters:**

- Third-party roles and StackSets can create access across multiple member accounts, including newly created accounts when automatic deployment is enabled.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html).
2. In AWS Organizations reconcile trusted services and delegated administrators; in IAM and CloudFormation review cross-account trust, external IDs, permission policies and rollout scope. The [Okta ISPM setup](https://help.okta.com/ispm/en-us/content/topics/ispm/aws.htm) illustrates why the management account and StackSet member-account grants need distinct review. Do not deploy a third-party template merely to assess current state.

**Automation:** No integration installation, template execution or trust changes are included.

#### Validation & Testing

Compare configured trust and account rollout to the approval record; verify the approved identity cannot perform unrelated actions. Account for dependencies before removing access.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6, AC-2 |

## 2. Sharing, Integrations and Audit

### 2.1 Verify organization-wide audit delivery

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-9, AU-12 |

#### Description

Maintain a multi-Region organization trail with reviewed event selectors and protected delivery.

#### Rationale

**Why This Matters:**

- Trail presence does not prove delivery; event history alone is not a substitute for protected, centralized evidence.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/creating-trail-organization.html).
2. In the trail home Region confirm organization and multi-Region settings, event selectors and log-file validation as applicable. Protect the designated logs bucket and retention policy with a separate logging authority.

**Automation:** No trail configuration changes are deployed by the pack.

#### Validation & Testing

Check trail status, delivery health and an approved sample management event from a member account. Validate required data events independently.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-9, AU-12 |

## 3. Compliance Quick Reference

These mappings support control design; they are not evidence of certification or operating effectiveness.

| Section | Control | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 | Verify organization scope and SCP guardrails | AC-3, AC-6 |
| 1.2 | Review trusted access and delegated administration | AC-6, AC-2 |
| 2.1 | Verify organization-wide audit delivery | AU-9, AU-12 |

## Changelog

- **0.1.0 (2026-11-27):** Initial guide and documented automation examples.
