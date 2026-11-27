---
layout: guide
title: "Google Cloud Hardening Guide"
vendor: "Google Cloud"
slug: "google-cloud"
tier: "3"
category: "IT Operations"
description: "Harden the Google Cloud organization hierarchy, workload credentials and central evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden the Google Cloud organization hierarchy, workload credentials and central evidence.

**Validation status:** Documented control paths and offline Code Pack behavior; no live tenant, credentials, or production changes. License and effective permissions may limit visibility.

### Intended Audience

Platform owners, identity administrators, and security reviewers.

### How to Use This Guide

- **L1 (Crawl):** Establish accountable identities and least privilege.
- **L2 (Walk):** Add narrower access boundaries and independent monitoring.

### Scope

Google Cloud resource-manager organization, folders and projects only. See the separate guides for [Google Workspace](/guides/google-workspace/), [Google Vertex AI](/guides/google-vertex-ai/), and [Google Gemini Enterprise](/guides/google-gemini-enterprise/).

## Table of Contents

1. [Access and Administration](#1-access-and-administration)
2. [Sharing, Integrations and Audit](#2-sharing-integrations-and-audit)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Access and Administration

### 1.1 Assess effective long-lived key guardrails

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-5, AC-6 |

#### Description

Prevent new persistent service account keys and uploads except through reviewed, time-bound exceptions.

#### Rationale

**Why This Matters:**

- Organization defaults, explicit policies, folder/project replacement and conditional rule cases can differ. Existing user-managed keys are not revoked by disabling future creation.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://docs.cloud.google.com/resource-manager/docs/manage-baseline-constraints).
2. In IAM & Admin → Organization Policies review managed and legacy key policies and any exception tags. Pilot an approved workload identity alternative before changing legacy dependencies. Inventory existing user-managed keys independently.

**Automation:** The read-only Cloud CLI example shows effective rules for the managed creation and upload constraints; it does not infer that conditional rules enforce every operation.

#### Code Implementation

{% include pack-code.html vendor="google-cloud" section="1.1" %}

#### Validation & Testing

Read the effective project policy using an approved credential and compare the requested key guardrail with expected inheritance and exceptions. Verify existing keys separately.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-5, AC-6 |

### 1.2 Constrain organization IAM and posture connectors

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6 |

#### Description

Review highly privileged and third-party IAM on every ancestor of the intended resource.

#### Rationale

**Why This Matters:**

- An inherited organization-level grant can affect all projects. A posture collector may require sensitive read visibility without management rights.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://docs.cloud.google.com/iam/docs/resource-hierarchy-access-control).
2. In IAM & Admin select the organization and reconcile inherited groups, workload identities and roles. Review the [Okta Google Cloud integration](https://help.okta.com/ispm/en-us/content/topics/ispm/google-cloud-platform.htm) as a separate scope: the documented connector reuses a Google Workspace integration service account and calls for organization viewer/reviewer roles. Review any key or network exception separately.

**Automation:** No IAM bindings, tenant exceptions or credentials are created.

#### Validation & Testing

Confirm the principal, role, resource level, business owner, scope and any conditions. Do not equate Cloud Asset inventory with complete effective IAM.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6 |

## 2. Sharing, Integrations and Audit

### 2.1 Protect organization audit and log routing

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-9, AU-12 |

#### Description

Route relevant evidence from covered projects to a destination managed by the logging team.

#### Rationale

**Why This Matters:**

- Admin Activity and Data Access differ; sink filters and excluded child resources can produce gaps.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://docs.cloud.google.com/logging/docs/export/aggregated_sinks).
2. Review organization or folder aggregated sink filters and inclusion settings. Validate destination permissions and retention, then review Data Access enablement for relevant services separately.

**Automation:** No sink or Data Access setting is modified.

#### Validation & Testing

Trace an approved child-project test operation to the destination, including source and caller, and verify a sample workload data access event when required.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-9, AU-12 |

## 3. Compliance Quick Reference

These mappings support control design; they are not evidence of certification or operating effectiveness.

| Section | Control | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 | Assess effective long-lived key guardrails | IA-5, AC-6 |
| 1.2 | Constrain organization IAM and posture connectors | AC-2, AC-6 |
| 2.1 | Protect organization audit and log routing | AU-9, AU-12 |

## Changelog

- **0.1.0 (2026-11-27):** Initial guide and documented automation examples.
