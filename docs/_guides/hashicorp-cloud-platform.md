---
layout: guide
title: "HashiCorp Cloud Platform Hardening Guide"
vendor: "HashiCorp Cloud Platform"
slug: "hashicorp-cloud-platform"
tier: "2"
category: "IaC"
description: "Harden HCP organization sign-in, scoped project authorization and audit delivery."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

This guide covers the shared HashiCorp Cloud Platform (HCP) Portal organization and project IAM plane. The [AppOmni directory](https://appomni.com/common-apps/) says “HashiCorp” without identifying the exact integration; this guide does not assert which HCP service AppOmni monitors.

**Validation status:** Documentation and local fixture verification, not a live HCP organization.

### Intended Audience

Organization owners, project administrators and assurance engineers who operate shared HCP services.

### How to Use This Guide

Pilot sign-in and project role restrictions first, then ensure evidence reaches its independent destination. Audit the underlying products with their own controls.

### Scope

HCP Portal identity, organization and project roles, and HCP-managed audit streaming. [HCP Terraform](/guides/terraform-cloud/) and [Vault](/guides/hashicorp-vault/) product settings remain distinct, even where the tenant uses the same provider or credentials.

## Table of Contents

1. [Control Plane Hardening](#1-control-plane-hardening)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Control Plane Hardening

### 1.1 Configure Organization Federation with Scoped Recovery

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2 |

#### Description

Configure SAML or OIDC with the approved central IdP and use its supported MFA policy. Do not claim federation alone disables existing email or GitHub authentication.

#### Rationale

**Why This Matters:**

- Shared cross-product administration makes incorrect metadata, audience or broad default membership consequential.

#### ClickOps Implementation

1. Follow [HCP’s organization SSO setup](https://developer.hashicorp.com/hcp/docs/hcp/iam/sso) for your IdP and test metadata and identity mapping on a small group.
2. Use SCIM where approved after confirming group mapping. Verify any federation default role is no broader than required. Keep a protected organization-owner recovery path until all sign-in conditions are verified.

**Automation:** The reviewed CLI policy operations do not set SSO. Use the documented Portal workflow.

#### Validation & Testing

Test an assigned user, unassigned user and approved recovery account separately.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2 |

### 1.2 Review Project IAM with the Organization Policy

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Reduce broad organization-level roles and delegate service-specific roles on projects and resources. Review users, groups and service principals independently.

#### Rationale

**Why This Matters:**

- A correctly scoped project policy is not sufficient if the same identity has privilege inherited from the organization.

#### ClickOps Implementation

1. In HCP Portal, review organization **Access Control (IAM)** role assignments and project access. Reserve Owner and Admin for approved control-plane operators; prefer scoped service roles over basic roles for production.
2. Reconcile the [role matrix](https://developer.hashicorp.com/hcp/docs/hcp/iam/access-management) at organization, project and resource levels. Use a clearly identified project for comparison.

**Automation:** The first-party [project IAM CLI](https://developer.hashicorp.com/hcp/docs/cli/commands/projects/iam/read-policy) reads the binding policy for one explicitly named project. The pack stores the provider output in a local private file without mutating roles. No decision about effective access is implied.

#### Code Implementation

{% include pack-code.html vendor="hashicorp-cloud-platform" section="1.2" %}

#### Validation & Testing

Compare project output against approved identities and independently check inherited organization and resource-level grants. Verify a scoped workload cannot read an unrelated project.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

### 1.3 Verify Audit Streaming at Both Ends

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6 |

#### Description

Stream the documented HCP platform and relevant product events to an approved destination. Track reception, not just connection settings.

#### Rationale

**Why This Matters:**

- A misconfigured or unauthorized sink can lose events. Product logs and platform events have distinct coverage.

#### ClickOps Implementation

1. Open the organization’s **Audit log streaming** page in the Portal and select an approved destination. Follow the vendor-documented least-privilege credential prerequisites.
2. Generate a benign connection test using the Portal and verify the event appears in the destination. [HCP audit streaming](https://developer.hashicorp.com/hcp/docs/hcp/audit-log).

**Automation:** HCP documents the `hcp_log_streaming_destination` Terraform resource. Destination credential and tenant requirements differ; use the approved provider workflow and do not apply a generic example across organizations.

#### Validation & Testing

Verify documented platform and relevant product events with expected timestamp, actor and tenant. If credentials fail, inspect sink health and event gaps before declaring coverage.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6 |

## 2. Compliance Quick Reference

| Control | NIST SP 800-53 Rev. 5 |
|---------|----------------------|
| Central identity | IA-2 |
| Narrow role assignment | AC-6 |
| Audit verification | AU-6 |

These mappings describe control intent, not certification.

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial HCP organization and project baseline | Jai |
