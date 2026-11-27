---
layout: guide
title: "Grafana Cloud Hardening Guide"
vendor: "Grafana Cloud"
slug: "grafana-cloud"
tier: "2"
category: "DevOps"
description: "Harden portal authentication, scoped Cloud Access Policies and workload service accounts in Grafana Cloud."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

This guide covers managed Grafana Cloud: the Grafana.com organization portal, regional Cloud Access Policies, and service accounts inside a Grafana stack. Valence lists Grafana without specifying an edition; this guide does not assert which deployment the connector supports. Self-managed Grafana, data-plane log retention and deployment hardening are separate scopes.

### Intended Audience

- SaaS administrators and security engineers
- GRC practitioners collecting configuration and access evidence

### How to Use This Guide

- **L1 (Crawl):** Establish identity, least privilege and review basics.
- **L2 (Walk):** Add controls that require staged deployment or split administration.

### Scope

ClickOps and code are documentation-derived; no tenant was accessed. Run inventories only on authorized accounts. They attest the visible configuration, not overall compliance.

## Table of Contents

1. [Control Checklist](#1-control-checklist)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Control Checklist

### 1.1 Require MFA for Portal Sign-In

**Profile Level:** L1 (Crawl)

#### Description

Enforce native MFA for the cloud organization and address the documented exception for social-only sign-in accounts.

#### Rationale

**Why This Matters:**

- Cloud Portal administrators can affect stacks, roles and API credentials across the organization.

#### Prerequisites

Cloud organization admin, enrolled pilot accounts and protected recovery codes. API writes require authorization and a separately approved change.

#### ClickOps Implementation

In **Cloud Portal → Org Settings**, turn on **Enforce MFA** and select **Update**. Review social-only accounts separately: Grafana documents that accounts without a password are exempt. Enforce an equivalent verified upstream MFA policy or migrate those accounts to supported enrollment.

**Source:** [Vendor administration documentation](https://grafana.com/docs/grafana-cloud/platform/security-and-account-management/security-and-access/authentication-and-permissions/mfa/).

#### Code Implementation

{% include pack-code.html vendor="grafana-cloud" section="1.1" %}

#### Validation & Testing

Read back the MFA setting, then sign in with a test account to verify enrollment and confirm which paths are exempt. A true flag alone does not attest every identity.

#### Operational Impact

A user without MFA may be sent to enrollment on the next sign-in. Keep a tested administrator and recovery codes available before rollout.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | IA-2 | Supports this objective; configuration alone does not establish compliance. |

### 1.2 Scope Cloud Access Policies by Stack and Task

**Profile Level:** L1 (Crawl)

#### Description

Grant telemetry integration tokens only the necessary scopes and stack realms. Consider approved source subnets where supported and stable.

#### Rationale

**Why This Matters:**

- One multi-stack policy with broad data access increases the scope of a compromised credential.

#### Prerequisites

Cloud Portal admin for organization policies or appropriate stack permission for stack policies. Gather intended scopes, stack and stable egress.

#### ClickOps Implementation

Open **Access Policies** in the Cloud Portal, or **Administration → Users and access → Cloud access policies** in the stack. Create a policy scoped to the required stack and data operations, then issue a dedicated token and store it directly in the secret manager. Review old policies and allowlists before any removal.

**Source:** [Vendor administration documentation](https://grafana.com/docs/grafana-cloud/platform/security-and-account-management/security-and-access/authentication-and-permissions/access-policies/create-access-policies/).

#### Code Implementation

{% include pack-code.html vendor="grafana-cloud" section="1.2" %}

#### Validation & Testing

The Terraform example creates a single-stack metrics-read policy, not a token; review the provider pin and generated plan against your approved release before apply. Query the exact policy and region using the Cloud API; compare scopes, realms and allowed subnets to the approved baseline. Verify a legitimate client still works before retiring an old token.

#### Operational Impact

Wrong scope or egress ranges can stop telemetry. Keep the prior approved policy during migration and remove unused credentials after dependent producers are verified.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | AC-6 | Supports this objective; configuration alone does not establish compliance. |

### 1.3 Use Separate Stack Service Accounts

**Profile Level:** L1 (Crawl)

#### Description

Assign one stack service account per automation purpose with minimum basic role and RBAC grants. Do not use a Cloud Access Policy token for stack HTTP API calls.

#### Rationale

**Why This Matters:**

- Shared administrator tokens hide ownership and can modify unrelated dashboards or alerting.

#### Prerequisites

Grafana stack administrator or role with service-account permissions; approved team and role assignments.

#### ClickOps Implementation

Within the stack, open **Administration → Users and access → Service accounts**. Select **Add service account**, use a descriptive owner-linked name, choose a minimum role, then create a token with an appropriate expiry and retain it in an approved secret store.

**Source:** [Vendor administration documentation](https://grafana.com/docs/grafana/latest/administration/service-accounts/).

**Automation:** No verified pack is supplied for this control. This is not a claim that no automated interface exists.

#### Validation & Testing

Confirm the token can perform the intended stack actions and cannot access unrelated resources. Verify both basic role and additional RBAC grants; a basic Viewer role need not describe all permissions.

#### Operational Impact

Test all alerting and dashboard workloads with the replacement before revoking any existing credential.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | AC-6 | Supports this objective; configuration alone does not establish compliance. |

### 1.4 Separate Portal and Stack Administrator Roles

**Profile Level:** L2 (Walk)

#### Description

Maintain a small Cloud Portal admin group and grant stack-local admin roles to operators only where required.

#### Rationale

**Why This Matters:**

- An operator who only manages a dashboard need not be able to create Cloud API policies or alter billing.

#### Prerequisites

Working recovery administrators in both planes; approved ownership and role map.

#### ClickOps Implementation

Review organization membership and roles within **Cloud Portal → Org Settings**. In each Grafana stack, review **Administration → Users and access** and compare roles to the approved map. Pilot a downgrade on an intended non-admin and note any propagated role access.

**Source:** [Vendor administration documentation](https://grafana.com/docs/grafana-cloud/platform/security-and-account-management/security-and-access/authentication-and-permissions/plan-access-management/).

#### Code Implementation

{% include pack-code.html vendor="grafana-cloud" section="1.4" %}

#### Validation & Testing

Use the CLI pack only to corroborate the authenticated caller’s organization roles; it is not a roster. Exercise each retained administration path separately and verify operators cannot use privilege reserved for the other plane.

#### Operational Impact

Role propagation can affect stack access. Export the current role assignments first and restore only the required role if coverage becomes insufficient.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | AC-6 | Supports this objective; configuration alone does not establish compliance. |

## 2. Compliance Quick Reference

| Control | Profile | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 Require MFA for Portal Sign-In | L1 | IA-2 |
| 1.2 Scope Cloud Access Policies by Stack and Task | L1 | AC-6 |
| 1.3 Use Separate Stack Service Accounts | L1 | AC-6 |
| 1.4 Separate Portal and Stack Administrator Roles | L2 | AC-6 |

## References

- [Source and validation notes](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-dev-source-coverage.md)

## Contributing

Use the repository contribution guide. Include the tested edition, source and validation results with corrections.

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-11-27 | Initial documentation-derived guide and verification packs |
