---
layout: guide
title: "Google Gemini Enterprise Hardening Guide"
vendor: "Google Gemini Enterprise"
slug: "google-gemini-enterprise"
tier: "3"
category: "AI/ML Platform"
description: "Google Cloud Gemini Enterprise combines enterprise search, data connectors and app or agent experiences"
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

**Product Editions Covered:** Google Cloud Gemini Enterprise apps and data stores in global, US and EU multi-regions

## Overview

Google Cloud Gemini Enterprise combines enterprise search, data connectors and app or agent experiences. Its Discovery Engine administration is separate from Google Workspace Gemini controls, the consumer Gemini application and Gemini Enterprise Agent Platform for building on Vertex AI.

### Intended Audience

Platform administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Baseline controls for the documented deployment.
- **L2 (Walk):** Add verified controls where the workload needs stronger isolation.
- **L3 (Run):** Add controls warranted by higher-risk workflows and contractual requirements.

### Scope

This guide covers Google Cloud projects that host Gemini Enterprise apps, their direct resource IAM policies, connected data access, and observability. Workload-specific actions, consumer accounts, Workspace administrator controls and model deployment policies are out of scope.

---

## Table of Contents

1. [Identity and App Access](#1-identity-and-app-access)
2. [Connected Data Boundaries](#2-connected-data-boundaries)
3. [Auditing and Observability](#3-auditing-and-observability)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

---

## 1. Identity and App Access

### 1.1 Remove unintended project-wide app access

**Profile Level:** L1 (Crawl)

#### Description

Review project and inherited roles before relying on app-specific grants. Use the project-level Gemini Enterprise Restricted User role for eligible users who should access only named apps.

#### Rationale

- A project-level Gemini Enterprise User grant permits access to all Gemini Enterprise apps in that project. App-specific role lists do not override that entitlement.

#### Prerequisites

Project IAM reviewer, licensed pilot users, app inventory, access matrix and a tested admin recovery path.

#### ClickOps Implementation

1. Open the target project’s **IAM & Admin → IAM**. Review direct and inherited permissions, broad Discovery Engine/basic roles, group membership and IAM conditions.
2. For eligible scope-restricted users, use the documented `roles/discoveryengine.agentspaceRestrictedUser` project role and the app-level user grant described in 1.2. Stage associated app grants before removing unintended broader access.

Source: [Vendor configuration reference](https://docs.cloud.google.com/gemini/enterprise/docs/iam-policy-for-apps).

#### Code Implementation

The CLI pack reads the direct project IAM policy and summarizes role names, principal counts, public-principal counts and presence of conditions, without printing individual member IDs. It neither resolves inherited permissions nor determines the effective role of an identity.

{% include pack-code.html vendor="google-gemini-enterprise" section="1.1" %}

#### Validation & Testing

Verify an approved pilot can open its specified app but cannot open a second app. Review organization and folder inheritance and group memberships separately.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Removing project-wide access can affect multiple apps, workloads and teams. Pilot identities first.

#### Rollback Procedure

Restore only the specifically required prior permission with time-bounded approval and recheck affected resources.

---
### 1.2 Restrict access at each Gemini Enterprise app

**Profile Level:** L1 (Crawl)

#### Description

Use app-specific Gemini Enterprise User grants for licensed, restricted personas and an app-specific approval list.

#### Rationale

- A missing app-level role can deny an intended user; a mistaken app grant can expose an app and data sources reachable by that user. Project-level permissions still take precedence.

#### Prerequisites

Gemini Enterprise admin, target app and location, approved role matrix and project IAM review. Enable granular resource controls if using the Console workflow.

#### ClickOps Implementation

1. For app and data-store granular mode, open **Gemini Enterprise → Settings → Resource access control**, review and enable the feature, then verify each deployed multi-region independently.
2. In the selected app’s **User permissions** tab, add each approved group with the minimum applicable resource role. For app-only mode, Google documents the app-level IAM API rather than a Console assigner.

Source: [Vendor configuration reference](https://docs.cloud.google.com/gemini/enterprise/docs/iam-policy-for-apps-and-data-stores).

#### Code Implementation

The GET pack summarizes a selected app’s direct IAM policy using the Discovery Engine v1 engine resource. It requests policy version 3 to preserve visibility of conditional bindings. A direct policy does not establish effective access.

{% include pack-code.html vendor="google-gemini-enterprise" section="1.2" %}

#### Validation & Testing

Reconcile each direct app grant with the approved roster; test granted and excluded pilot users. For a new multi-region, verify the feature has not remained off there.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Changes can remove access or affect users with a custom project role missing required Discovery Engine permissions.

#### Rollback Procedure

Reverse the specific reviewed binding change using the current policy and its concurrency token; do not overwrite unrelated bindings or restore broad project grants.

---

## 2. Connected Data Boundaries

### 2.1 Separate data-store access from source document access

**Profile Level:** L1 (Crawl)

#### Description

Limit data-store access to approved principals and validate document-level authorization using the supported connector identity provider and source ACL model.

#### Rationale

- An app grants access to a user experience, not blanket access to connected data. Third-party connectors that enforce end-user document permissions still rely on source identity and synced ACLs.

#### Prerequisites

Documented connector support, authorized data owner and pilot app, representative authorized/denied users and synthetic documents.

#### ClickOps Implementation

1. In **Gemini Enterprise → Data Stores**, select the target store and review **User permissions** if granular resource access is enabled. Map connector collections and entity-specific child data stores when a connector has multiple entities.
2. Choose the supported connector identity provider and identity mappings. For third-party ingestion, verify the connector’s actual per-document support and sync behavior; do not infer ACL protection from having a data-store role.

Source: [Vendor configuration reference](https://docs.cloud.google.com/gemini/enterprise/docs/iam-policy-for-apps-and-data-stores).

#### Code Implementation

This v1 GET pack reads direct IAM on an individual data store under default_collection, not parent connector collection grants, document ACLs, membership, inheritance or effective access.

{% include pack-code.html vendor="google-gemini-enterprise" section="2.1" %}

#### Validation & Testing

Using synthetic documents, confirm one allowed and one denied identity at the source and in Gemini Enterprise after sync. Re-test revocation after the appropriate sync; incremental sync does not update identities or deletions. Compare collection and child-store grants independently.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Some sources require correctly scoped service identities and planned full/identity syncs; incorrect mappings can temporarily hide approved content or expose it.

#### Rollback Procedure

Disable or detach the affected connector while validating mapping and source ACL corrections. Restore only a known approved access profile.

---
### 2.2 Review federation and ingestion data paths

**Profile Level:** L2 (Walk)

#### Description

Approve the connection mode and every enabled destination before attaching a connector. Prefer an approved narrowly scoped source over broad ingest credentials or unrelated federated search backends.

#### Rationale

- Ingestion copies content into the Gemini Enterprise index. Federation avoids that index copy but can send query text and conversation context to enabled third-party search backends.

#### Prerequisites

Data owner and privacy approval; connector-specific permissions, authorized regions and retention requirements.

#### ClickOps Implementation

1. Review the target app’s attached data stores in Gemini Enterprise. For each connector, record authorized source and tenant, selected mode, API access scope, identity provider and relevant regions.
2. Remove or detach connections that are not approved. Reassess whether sensitive workloads should use a separate app with a narrower connector list.

Source: [Vendor configuration reference](https://docs.cloud.google.com/gemini/enterprise/docs/connectors/introduction-to-connectors-and-data-stores).

#### Code Implementation

Connector guide and Console evidence are required. No generic verification of upstream or downstream ACLs is implied.

#### Validation & Testing

Confirm the intended app’s active data stores and approved downstream destinations. In a pilot, verify synthetic permitted searches and assess source permissions without using real sensitive content.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Changing connector mode can change coverage, ranking, data residency and copies. Detaching is not evidence that indexed copies or upstream activity are deleted.

#### Rollback Procedure

Restore only the approved configuration after validating identity, ACL and privacy boundaries.

---

## 3. Auditing and Observability

### 3.1 Collect usage metadata without prompt payloads by default

**Profile Level:** L2 (Walk)

#### Description

Enable approved observability for the Core Assistant and relevant agent types. Leave sensitive prompt and response logging off unless separately required, approved and access-controlled.

#### Rationale

- Usage events can help oversight. Logging inputs and outputs creates an additional sensitive content store with its own access and lifecycle. Discovery Engine Cloud Audit Logs normally cover different service operations and are not the same as app usage logs.

#### Prerequisites

Gemini Enterprise admin, verified logging project and view access, retention approval, and synthetic pilot prompts.

#### ClickOps Implementation

1. Open the app’s **Configurations → Observability** for the Core Assistant. For other agents, open the specific agent’s **Configuration** tab. Enable approved instrumentation and leave **Enable logging of prompt inputs and response outputs** off.
2. Scope Cloud Logging access and retention; verify exclusions/sinks and review Discovery Engine Cloud Audit Logs and Data Access settings separately.

Source: [Vendor configuration reference](https://docs.cloud.google.com/gemini/enterprise/docs/manage-observability-settings).

#### Code Implementation

The read-only v1alpha pack checks only Core Assistant engine fields and returns null for absent flags, which must be verified in the Console. The CLI pack counts up to 20 project usage log records over 24 hours, prints no payload or actor details, and cannot establish a particular app’s or agent’s configuration.

{% include pack-code.html vendor="google-gemini-enterprise" section="3.1" %}

#### Validation & Testing

Check settings and approved recent synthetic usage in Cloud Logging. Verify payload fields are elided or omitted and access is limited to authorized viewers. An empty sample alone cannot prove instrumentation is off.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Enabling instrumentation can have logging costs. Turning off sensitive logging does not remove existing entries. Each configured agent must be reviewed independently.

#### Rollback Procedure

Restore only the approved observability state and handle older stored payloads through the organization’s approved data-handling process.

---

## 4. Compliance Quick Reference

These mappings indicate how settings can contribute to a control objective; they do not establish conformity or operation over a period.

| HTH control | NIST SP 800-53 Rev. 5 | Evidence to retain |
| --- | --- | --- |
| 1.1 | AC-2, AC-6 | Reviewed inherited and direct grants, scoped pilot access |
| 1.2 | AC-3, AC-6 | Direct app IAM and approved app matrix |
| 2.1 | AC-3, AC-6 | Collection/store scope and denied synthetic source document |
| 2.2 | AC-4, SC-7 | Approved destinations and connector mode |
| 3.1 | AU-2, AU-9, SI-12 | Effective settings, minimized logs and synthetic evidence |

## Appendix A: Automation and Evidence

Run these packs only with approved read access, the actual target project and resource IDs, and, for REST, a short-lived OAuth token. No write, prompt submission, connector credential retrieval or live tenant traffic was exercised. Admin access settings, source ACLs and project inheritance each require separate evidence. No Gemini Enterprise-specific CIS Benchmark, STIG or SCuBA coverage is claimed.

## Appendix B: References

- [Gemini Enterprise editions](https://docs.cloud.google.com/gemini/enterprise/docs/editions)
- [App-only IAM workflow](https://docs.cloud.google.com/gemini/enterprise/docs/iam-policy-for-apps)
- [Gemini Enterprise IAM roles](https://docs.cloud.google.com/gemini/enterprise/docs/access-control)
- [Identity provider and source permissions](https://docs.cloud.google.com/gemini/enterprise/docs/configure-identity-provider)
- [Usage audit logs](https://docs.cloud.google.com/gemini/enterprise/docs/set-up-usage-audit-logs)
- [Discovery Engine Cloud Audit Logs](https://docs.cloud.google.com/gemini/enterprise/docs/audit-logging)
- [Cloud Logging IAM](https://docs.cloud.google.com/logging/docs/access-control)

## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial platform controls and documented verification packs | How to Harden Community |

## Contributing

Report inaccurate or outdated guidance through the [issue tracker](https://github.com/grcengineering/how-to-harden/issues).
