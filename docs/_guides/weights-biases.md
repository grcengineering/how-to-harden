---
layout: guide
title: "Weights & Biases Hardening Guide"
vendor: "Weights & Biases"
slug: "weights-biases"
tier: "3"
category: "AI/ML Platform"
description: "Weights & Biases, acquired by CoreWeave on May 5, 2025, is now part of CoreWeave Forge"
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

**Product Editions Covered:** Enterprise Multi-tenant Cloud; Dedicated Cloud and Self-Managed where stated

## Overview

Weights & Biases, acquired by CoreWeave on May 5, 2025, is now part of CoreWeave Forge. This guide hardens the continuing W&B organization and project controls, not the separate CoreWeave cloud infrastructure account, networking or cluster controls.

### Intended Audience

Platform administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Baseline controls for the documented deployment.
- **L2 (Walk):** Add verified controls where the workload needs stronger isolation.
- **L3 (Run):** Add controls warranted by higher-risk workflows and contractual requirements.

### Scope

Covers W&B organization privacy, sensitive project visibility, service credential scope, SCIM verification and the Multi-tenant Cloud audit API. W&B-specific settings are not evidence of a Forge infrastructure control. Dedicated/Self-Managed audit use different endpoints and are not automated by these packs.

---

## Table of Contents

1. [Project and Content Boundaries](#1-project-and-content-boundaries)
2. [Workload Identity](#2-workload-identity)
3. [Audit Evidence](#3-audit-evidence)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

---

## 1. Project and Content Boundaries

### 1.1 Enforce private projects and disable public report sharing

**Profile Level:** L1 (Crawl)

#### Description

Enforce private projects at the organization level, turn off public sharing for reports from private projects, and review existing project visibility independently. Use Restricted for sensitive projects when broad team membership is unnecessary.

#### Rationale

- New-project defaults do not fix existing visibility. Turning off public report sharing deactivates prior public report links, but cannot recall content previously copied elsewhere. Team-level access is broader than explicitly invited access.

#### Prerequisites

Organization and team admins, approved external sharing exceptions, and classification inventory. Restricted projects still have administrative access paths.

#### ClickOps Implementation

1. Open the organization’s settings and select **Privacy**. Enable **Enforce private projects** and **Disable public report sharing**, where approved.
2. Review currently open/public projects individually. For sensitive projects set **Project Visibility → Restricted** and invite only approved collaborators.
3. Review active report links and permitted project membership independently.

Source: [Vendor configuration reference](https://github.com/wandb/docs/blob/main/platform/hosting/privacy-settings.mdx).

#### Code Implementation

ClickOps. No stable API for the documented organization visibility toggles was verified; do not synthesize undocumented GraphQL mutations.

#### Validation & Testing

Verify a new synthetic project cannot be made public. Check an existing restricted project using both an approved collaborator and a synthetic non-member. Check prior public report links where deactivation was required.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

User-facing reports can stop loading for external recipients. Coordinate before applying organization toggles; the vendor saves changes immediately.

#### Rollback Procedure

Restore a specific approved recipient or classified sharing scope rather than weakening the entire organization. Assess prior exposure separately.

---
### 1.2 Disable automatic source code saving by default

**Profile Level:** L2 (Walk)

#### Description

Disable default code saving for teams and review explicit SDK configuration on approved workloads. Treat explicit file uploads, source logging and artifacts as separate collection paths.

#### Rationale

- Experiments can send source-related artifacts beyond the intended data-sharing boundary. A default prevents accidental collection but is not a complete prevention policy.

#### Prerequisites

Organization admin and cooperation from workflow owners. Document which workloads are permitted to store code for reproducibility.

#### ClickOps Implementation

1. Under **Organization settings → Privacy**, enable **Disable default code saving**.
2. Confirm team privacy settings indicate the enforced default. Give exceptions a separate reviewed workflow rather than enabling code capture globally.

Source: [Vendor configuration reference](https://github.com/wandb/docs/blob/main/platform/hosting/privacy-settings.mdx).

#### Code Implementation

ClickOps for the organization-wide setting. No public control-plane setter was verified. The local SDK environment pack reduces notebook/diff and repository metadata collection for a new workload process, not explicit artifact uploads or existing run records. Source it in the workload shell before starting the SDK.

{% include pack-code.html vendor="weights-biases" section="1.2" %}

#### Validation & Testing

Start a harmless authorized sample run with synthetic source and inspect what was captured. Verify explicit file, artifact and trace uploads independently. Do not inspect live notebooks or runs without authorization.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Some historical workflows expect captured source for provenance. Review retention for existing copies; the toggle does not delete them.

#### Rollback Procedure

Reinstate code collection only for approved workloads and document the reason and lifecycle. Do not use global rollback for one workload.

---

## 2. Workload Identity

### 2.1 Scope service accounts to individual teams

**Profile Level:** L1 (Crawl)

#### Description

Use team-scoped non-human identities for workload logging that does not require organization-wide access. Review restricted-project grants separately.

#### Rationale

- Organization-scoped accounts can reach nonrestricted projects across teams even when their default team appears narrow. Team-scoped keys can still interact with open-visibility projects under documented conditions.

#### Prerequisites

Team or organization admin; Enterprise feature availability; secure secret storage, a documented workload owner, and a verified W&B host.

#### ClickOps Implementation

1. Open the intended team’s **Team settings** and create a service account for each approved workload. For organization-level automation, separately document any requirement for organization scope.
2. Issue a credential into the secret manager, migrate the workload and revoke old credentials. For restricted projects, add only the explicitly required service account.
3. Have an admin review service account inventory and target mappings; verify Default API organization on Multi-tenant Cloud when the admin has multiple orgs.

Source: [Vendor configuration reference](https://github.com/wandb/docs/blob/main/platform/hosting/iam/service-accounts.mdx).

#### Code Implementation

SCIM read-only inventory, not a policy setter. The credential itself must be an authorized organization- or instance-level principal; do not reuse a team workload token. Requires v0.79.0+ for Bearer on Dedicated/Self-Managed.

{% include pack-code.html vendor="weights-biases" section="2.1" %}

#### Validation & Testing

Inspect which identity class is represented in the organization. The read-only SCIM sample emits counts for returned resources only, not identities. Verify actual team/project scope and any restricted-project grant separately.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Rotating the wrong key can interrupt run or trace ingestion. Use in-place validation and dual-key software where approved.

#### Rollback Procedure

Re-establish the prior approved scoped account and key through the secret manager if necessary. Do not reactivate a compromised credential.

---

## 3. Audit Evidence

### 3.1 Sample Multi-tenant Cloud organization audit events

**Profile Level:** L2 (Walk)

#### Description

Collect W&B audit evidence in an access-controlled location using the deployment-specific logging interface. Where possible, collect only approved event fields.

#### Rationale

- Audit records can expose names, email, IP addresses and project metadata. Multi-tenant Cloud does not offer the Dedicated/Self-Managed anonymization filter, and its feed excludes some actions.

#### Prerequisites

Enterprise Multi-tenant Cloud, an authorized admin principal and confirmed Default API organization where applicable. A dedicated protected logging workflow is required before production collection.

#### ClickOps Implementation

1. As an approved admin, verify the intended organization and review **User Settings → Default API organization** when applicable.
2. Supply the authorized credential to the audit pack using the secret manager. Authenticate only to the documented Multi-tenant Cloud endpoint.
3. For Dedicated or Self-Managed, use the corresponding instance endpoint and consider the documented anonymization option; do not substitute this hostname or script.

Source: [Vendor configuration reference](https://github.com/wandb/docs/blob/main/platform/hosting/monitoring-usage/audit-logging.mdx).

#### Code Implementation

Read-only Multi-tenant Cloud Audit API. Collect a one-day bounded sample, not a complete paginated export.

{% include pack-code.html vendor="weights-biases" section="3.1" %}

#### Validation & Testing

Select an approved synthetic action and verify an event in the corresponding window where the feed supports it. Empty results or a read alone do not establish logging coverage. Preserve returned UTC range and note whether another page exists.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

The sample fetches sensitive data transiently and deliberately suppresses it from stdout. Do not capture raw response output or turn on shell debugging in the collector.

#### Rollback Procedure

Revoke access to the collector credential if discontinued. Keep previously exported records only as required by the approved retention policy.

---

## 4. Compliance Quick Reference

These mappings indicate how settings can contribute to a control objective; they do not establish conformity or operation over a period.

| HTH control | NIST SP 800-53 Rev. 5 | Evidence to retain |
| --- | --- | --- |
| 1.1 | AC-3, AC-6 | Enforced privacy, classified sharing inventory and authorized non-member test |
| 1.2 | CM-6, SI-12 | Organization default and synthetic output check |
| 2.1 | AC-2, AC-6, IA-5 | Account scope and credential lifecycle evidence |
| 3.1 | AU-2, AU-6, AU-9 | Observed event and protected collection scope |

## Appendix A: Automation and Evidence

The W&B CLI/SDK primarily administer individual workload/run operations; its documented commands are not an organization privacy policy setter or SCIM inventory substitute. The first-party cloud Terraform modules manage deployment infrastructure, not the W&B SaaS organization toggles here. Documented SCIM write operations are not used. No W&B-specific CIS, STIG or SCuBA benchmark equivalence claimed. No live tenant verification; references link to the vendor’s source repository where old docs redirects could not be fetched.

## Appendix B: References

- [CoreWeave ownership and Forge platform](https://www.coreweave.com/companies/weights-and-biases)
- [Organization settings](https://github.com/wandb/docs/blob/main/platform/hosting/iam/access-management/manage-organization.mdx)
- [Restricted projects](https://github.com/wandb/docs/blob/main/platform/hosting/iam/access-management/restricted-projects.mdx)
- [Organization privacy settings](https://github.com/wandb/docs/blob/main/platform/hosting/privacy-settings.mdx)
- [W&B SCIM API](https://github.com/wandb/docs/blob/main/platform/hosting/iam/scim.mdx)
- [Audit API](https://github.com/wandb/docs/blob/main/platform/hosting/monitoring-usage/audit-logging.mdx)
- [SDK environment variables](https://github.com/wandb/docs/blob/main/models/track/environment-variables.mdx)
- [Official W&B CLI implementation](https://github.com/wandb/wandb/blob/main/wandb/cli/cli.py)

## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial platform controls and documented verification packs | How to Harden Community |

## Contributing

Report inaccurate or outdated guidance through the [issue tracker](https://github.com/grcengineering/how-to-harden/issues).
