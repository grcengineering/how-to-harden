---
layout: guide
title: "Google Vertex AI Hardening Guide"
vendor: "Google Vertex AI"
slug: "google-vertex-ai"
tier: "3"
category: "AI/ML Platform"
description: "Google Vertex AI provides managed model inference and deployment on Google Cloud"
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

**Product Editions Covered:** Vertex AI API (aiplatform.googleapis.com) and the corresponding Gemini Enterprise Agent Platform administration surfaces

## Overview

Google Vertex AI provides managed model inference and deployment on Google Cloud. Current Google documentation places these capabilities under Gemini Enterprise Agent Platform; the Vertex AI API service and model policy identifiers still apply to the controls cited here.

### Intended Audience

Platform administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Baseline controls for the documented deployment.
- **L2 (Walk):** Add verified controls where the workload needs stronger isolation.
- **L3 (Run):** Add controls warranted by higher-risk workflows and contractual requirements.

### Scope

Covers Model Garden permissions by model/action, VPC Service Controls and audit logging for the Vertex AI API. Does not cover Vertex AI Vision, Gemini for Workspace, unrestricted custom workloads or Google Cloud project baselines generally.

---

## Table of Contents

1. [Model Access](#1-model-access)
2. [Network Isolation](#2-network-isolation)
3. [Audit Logging](#3-audit-logging)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

---

## 1. Model Access

### 1.1 Allow only approved Model Garden model actions

**Profile Level:** L1 (Crawl)

#### Description

Set an effective organization policy for `vertexai.allowedModels` to approved publisher, model and action combinations in each production project.

#### Rationale

- IAM answers which principal can act, but this constraint limits the Model Garden model actions available to principals in a scope. It does not restrict models in the Model Registry.

#### Prerequisites

Approved model/action inventory and Organization Policy Administrator at the intended scope. Identify inherited rules and existing overrides before editing.

#### ClickOps Implementation

1. Open **IAM & Admin → Organization Policies** and select the organization, folder, or project.
2. Search for `vertexai.allowedModels`, inspect inheritance, and manage the policy with an explicit approved allowlist. Use the publisher model identifier and action format listed in the vendor reference.
3. Review overrides in production projects.

Source: [Vendor configuration reference](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/control-model-access).

#### Code Implementation

The first-party CLI reads effective policy, not the live success of a model action. The Terraform example adds a **dry-run-only** candidate in a dedicated test project; it preserves inherited rules and does not enforce the local allowlist. Reconcile existing policy ownership and state before adapting it.

{% include pack-code.html vendor="google-vertex-ai" section="1.1" %}

#### Validation & Testing

Compare the **effective** policy in every production project with the approved list, not merely with an organization resource. In a test project, verify expected approved actions continue to work and a harmless unapproved test action is denied.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

A changed allowlist may block legitimate inference, tuning or deployment. Stage changes in a project first.

#### Rollback Procedure

Restore the previous approved rule/inheritance configuration and verify affected workload paths before closing the change.

---

## 2. Network Isolation

### 2.1 Stage a service perimeter for supported Vertex AI workloads

**Profile Level:** L2 (Walk)

#### Description

Place supported AI projects and their necessary Google services inside a regular VPC Service Controls perimeter; stage dry-run restrictions before enforcement.

#### Rationale

- IAM alone cannot express all contextual data movement restrictions. A service perimeter adds controls but is not a generic web firewall or a replacement for IAM.

#### Prerequisites

Access Context Manager policy permissions, numeric project identifiers, dependency inventory and planned ingress/egress for supported methods.

#### ClickOps Implementation

1. In **Security → VPC Service Controls**, choose the access policy and create or edit a dedicated perimeter.
2. Include the approved projects and `aiplatform.googleapis.com` as a restricted service where supported. Stage in dry-run mode.
3. Assess dependency flows and unsupported endpoints; promote only after approved calls succeed and expected violations are understood.

Source: [Vendor configuration reference](https://docs.cloud.google.com/gemini-enterprise-agent-platform/machine-learning/general/vpc-service-controls).

#### Code Implementation

The first-party CLI inventories service perimeters; it does not authorize calls or prove network behavior.

{% include pack-code.html vendor="google-vertex-ai" section="2.1" %}

#### Validation & Testing

Review project numbers, restricted services, ingress/egress and dry-run versus enforced configuration. A candidate present only in dry-run is not enforced. Google documents that certain inference endpoints must be created after the project enters the perimeter.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Can block build, deployment, data access and public-dedicated Model Garden endpoint scenarios. Plan dependency and endpoint migration before enforcement.

#### Rollback Procedure

Restore the prior approved effective perimeter rules if needed. Use narrow, reviewed exceptions instead of removing the entire perimeter.

---

## 3. Audit Logging

### 3.1 Verify security audit coverage for Vertex AI

**Profile Level:** L2 (Walk)

#### Description

Keep Admin Activity audit trails and explicitly configure necessary Data Access log classes for `aiplatform.googleapis.com`. Read from a restricted audit destination.

#### Rationale

- Admin Activity cannot substitute for Data Access evidence. Data Access audit logs can incur costs and contain sensitive metadata; auditing should follow a defined collection and retention policy.

#### Prerequisites

Authorized IAM audit-config editor and least-privilege log viewer with access to private logs where needed.

#### ClickOps Implementation

1. Open **IAM & Admin → Audit Logs** and select the relevant project.
2. Select the service that corresponds to `aiplatform.googleapis.com`. Enable the approved Data Access classes and review exemptions.
3. Configure a restricted sink and retention as required by policy.

Source: [Vendor configuration reference](https://docs.cloud.google.com/gemini-enterprise-agent-platform/machine-learning/general/audit-logging).

#### Code Implementation

This query outputs only identifiers and method metadata, never full records. It is capped to a recent sample, not an audit completeness check.

{% include pack-code.html vendor="google-vertex-ai" section="3.1" %}

#### Validation & Testing

Generate an authorized benign sample event and confirm the expected log category, method and principal in the protected destination. Empty query output is not evidence of compliant configuration; check service coverage, filters and visibility.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Additional audit logs can create costs and metadata exposure. Scope viewers and retention.

#### Rollback Procedure

Revert only the approved Data Access configuration change if needed while preserving mandatory Admin Activity records.

---

## 4. Compliance Quick Reference

These mappings indicate how settings can contribute to a control objective; they do not establish conformity or operation over a period.

| HTH control | NIST SP 800-53 Rev. 5 | Evidence to retain |
| --- | --- | --- |
| 1.1 | AC-3, CM-6 | Effective policy plus time-scoped synthetic check |
| 2.1 | SC-7 | Enforced perimeter and documented test flows |
| 3.1 | AU-2, AU-6, AU-9 | Audit classes, restricted destination and observed sample |

## Appendix A: Automation and Evidence

The organization policy and perimeter have REST surfaces as well as gcloud; they require OAuth and the relevant Cloud IAM roles. A documented Terraform resource can stage a dry-run candidate; actual enforcement remains an explicitly reviewed console or policy change. REST and SDK integrations are not verified here. No Vertex AI-specific CIS, STIG or SCuBA equivalent is claimed; Google Cloud-wide guidance does not prove these settings. Samples are read-only; none were run against a tenant.

## Appendix B: References

- [Google Cloud organization constraints](https://docs.cloud.google.com/organization-policy/reference/org-policy-constraints?hl=en)
- [Cloud audit service catalog](https://docs.cloud.google.com/logging/docs/audit/services)
- [Terraform organization policy resource](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/org_policy_policy)
- [Service perimeter operations](https://docs.cloud.google.com/vpc-service-controls/docs/manage-service-perimeters)

## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial platform controls and documented verification packs | How to Harden Community |

## Contributing

Report inaccurate or outdated guidance through the [issue tracker](https://github.com/grcengineering/how-to-harden/issues).
