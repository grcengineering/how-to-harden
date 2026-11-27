---
layout: guide
title: "Tabnine Hardening Guide"
vendor: "Tabnine"
slug: "tabnine"
tier: "3"
category: "AI/ML Platform"
description: "Tabnine can expose source code context, third-party model endpoints and developer-approved tools to coding workflows"
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

**Product Editions Covered:** Tabnine Enterprise SaaS; private deployment and version gates are marked

## Overview

Tabnine can expose source code context, third-party model endpoints and developer-approved tools to coding workflows. Separate console configuration from individual IDE/CLI configuration, and verify only documented Enterprise APIs with scoped credentials.

### Intended Audience

Platform administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Baseline controls for the documented deployment.
- **L2 (Walk):** Add verified controls where the workload needs stronger isolation.
- **L3 (Run):** Add controls warranted by higher-risk workflows and contractual requirements.

### Scope

Covers centrally managed onboarding, repository connections, MCP governance and audit evidence. Private instance configuration varies by version. This guide does not attest to IDE-local permissioning, Kubernetes security or model behavior.

---

## Table of Contents

1. [Organization Access](#1-organization-access)
2. [Coding Agent Boundaries](#2-coding-agent-boundaries)
3. [Operational Evidence](#3-operational-evidence)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

---

## 1. Organization Access

### 1.1 Require explicit assignment to an approved team

**Profile Level:** L1 (Crawl)

#### Description

On private installations, disable self-registration into the default team unless explicitly approved. Use the approved identity-provider or invitation workflow and review active unassigned accounts as exceptions.

#### Rationale

- Users with network access to a private installation can otherwise enroll into its default team, granting access that may not have been approved. An active, unassigned account is an investigation lead, not proof of usable IDE access.

#### Prerequisites

Tabnine administrator, private installation with Self-Registration control, documented onboarding workflow, and recovery account. Read-back requires a PAT with Organization Read plus access to the tenant.

#### ClickOps Implementation

1. Open **Tabnine Admin Console → Settings → General**. Turn off self-registration to the default team.
2. Verify invitations/identity-provider assignments place users in the intended team. Review active unassigned identities separately rather than automatically removing them.

Source: [Vendor configuration reference](https://docs.tabnine.com/main/administering-tabnine/managing-your-team/settings/general-settings).

#### Code Implementation

The read-only API pack counts a bounded page of active users who have no team assignment, not the total when pagination applies.

{% include pack-code.html vendor="tabnine" section="1.1" %}

#### Validation & Testing

Use a synthetic authorized pilot identity without team assignment and verify it cannot obtain plugin access. Use the pack to inspect one page of active unassigned users without disclosing user records. It does not prove the Self-Registration switch itself is off.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Existing onboarding may rely on default assignment. Identify approved users before changing the setting.

#### Rollback Procedure

Reinstate intended explicit team assignments. Restore self-registration only under a time-limited approved exception.

---

## 2. Coding Agent Boundaries

### 2.1 Use an explicit allowlist for MCP servers

**Profile Level:** L1 (Crawl)

#### Description

Prefer Block all where MCP is not needed; otherwise restrict it to the admitted server list and review remote URL scope and local executable/argument matching against the approved deployment.

#### Rationale

- Transport restrictions alone still permit unapproved remote servers. A permissive wildcard can admit more services than the team validated, and a local server may inherit sensitive access from its process.

#### Prerequisites

An admin and a reviewed inventory of expected servers and credentials. Run first in a pilot group using synthetic services and no production secrets.

#### ClickOps Implementation

1. Open **MCP Governance** in the Admin Console and choose **Block all**, or **Allow-list only** if there is a documented requirement.
2. Add only explicitly approved service URLs. For approved local servers, bind the reviewed executable and arguments and use exact matches where supported.
3. Restrict CLI automatic approval at the organization and PAT layers rather than relying on personal preference alone.

Source: [Vendor configuration reference](https://docs.tabnine.com/main/administering-tabnine/managing-your-team/settings/mcp-governance.md).

#### Code Implementation

Console only for organization MCP governance in the reviewed API contract. The first-party developer CLI is not a central-policy writer. The separate PAT CLI/Agent scope is described in the API reference.

#### Validation & Testing

Test recognition of an approved synthetic server and rejection of a nonlisted synthetic server in the expected client versions. Verify a newly created PAT cannot enable automation modes forbidden at the organization layer.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Existing integrations can stop working if the allowlist is incomplete. Keep a reviewed rollback list and do not add broad wildcards to fix syntax.

#### Rollback Procedure

Restore the last reviewed policy or one necessary service entry. Avoid fallbacks to unrestricted mode.

---
### 2.2 Limit indexed repository connections

**Profile Level:** L2 (Walk)

#### Description

Allow only the code repositories needed by each team and avoid reusing privileged source control credentials across teams. Inventory a team’s configured repositories separately from what the model can actually retrieve.

#### Rationale

- Repository connections widen the source code available to indexing. A successful code-search result does not prove intended team boundaries or correct source permissions.

#### Prerequisites

Approved repositories and team IDs, Tabnine Admin with Team repositories Read and source repository ownership review.

#### ClickOps Implementation

1. Open the team’s repository connections and reconcile with the approved list. Examine **Context Engine → Data Sources** for organization-wide context separately.
2. Remove unused connections after checking user impact. Rotate dedicated source credentials and verify their permissions in the source system.

Source: [Vendor configuration reference](https://docs.tabnine.com/main/administering-tabnine/managing-your-team/tabnine-apis#team-repositories).

#### Code Implementation

The API reads the exact team’s connections. Output intentionally excludes URLs and credential names.

{% include pack-code.html vendor="tabnine" section="2.2" %}

#### Validation & Testing

Compare the returned connection count, types and status categories with the approved target. A count can catch drift but cannot independently establish that the correct repository identities are linked; verify names in the console.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Changes can affect indexed search and autocomplete context. Sourcing alternative credentials can trigger reindexing.

#### Rollback Procedure

Restore the last approved single connection with a narrowly scoped source credential. Verify access before reopening use.

---

## 3. Operational Evidence

### 3.1 Read and protect Tabnine organization audit records

**Profile Level:** L2 (Walk)

#### Description

Review identity, team and authentication events through the version-supported audit API using the Audit logs Read PAT area and no CLI/Agent privileges.

#### Rationale

- Audit records can contain personal details, request context and changed values. Raw output should not be reused as a general-purpose usage report.

#### Prerequisites

Approved tenant HTTPS origin (the SaaS console or operator-verified private origin), release with the Audit Logs API, authorized identity and short-lived audit read PAT.

#### ClickOps Implementation

1. Open **Settings → Access Tokens → Generate Token**. Grant only **Audit logs → Read**, name it for the collector, choose the shortest feasible expiry and store it in the approved secret manager.
2. Sample organization events using the pack. Use the supported period/offset inputs in an independently reviewed full collector.

Source: [Vendor configuration reference](https://docs.tabnine.com/main/administering-tabnine/managing-your-team/tabnine-apis#audit-logs).

#### Code Implementation

Read-only API; one JSON page with personal data omitted from stdout.

{% include pack-code.html vendor="tabnine" section="3.1" %}

#### Validation & Testing

Use a previously approved synthetic administrative event and verify its ID, type and timestamp in a bounded sample. API success proves the call only; it does not prove all relevant events are collected.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Avoid multiple overlapping collectors with broad token permissions. File copies may have distinct retention requirements.

#### Rollback Procedure

Revoke the test PAT when done and rotate collector credentials without broadening scope. Apply approved retention to historical evidence.

---

## 4. Compliance Quick Reference

These mappings indicate how settings can contribute to a control objective; they do not establish conformity or operation over a period.

| HTH control | NIST SP 800-53 Rev. 5 | Evidence to retain |
| --- | --- | --- |
| 1.1 | AC-2, AC-6 | Onboarding restriction and activity inventory |
| 2.1 | AC-6, CM-7 | Approved MCP allowlist and synthetic allow/deny result |
| 2.2 | AC-3, AC-6 | Scoped repository connection review |
| 3.1 | AU-2, AU-6, AU-9 | Scoped credential and known event identifiers |

## Appendix A: Automation and Evidence

Tabnine’s official developer CLI can act as an agent but no tenant-policy administration command was verified. The REST schema describes both read and write for several team-management objects; these packs are checks only and do not set centrally enforced role, model or MCP policies. No vendor-maintained Terraform provider or organization-policy config file for the documented tenant controls was verified. No Tabnine-specific CIS, DISA STIG or SCuBA benchmark equivalence claimed; no live tenant verification.

## Appendix B: References

- [Unified Tabnine Enterprise API](https://docs.tabnine.com/main/administering-tabnine/managing-your-team/tabnine-apis)
- [Tabnine OpenAPI schema](https://raw.githubusercontent.com/codota/t9-api-yamls/refs/heads/main/docs/unified-tabnine-api.yaml)
- [PAT management](https://docs.tabnine.com/main/administering-tabnine/managing-your-team/settings/access-tokens)
- [Context Engine data sources](https://docs.tabnine.com/main/administering-tabnine/managing-your-team/context-engine/data-sources.md)
- [Models settings](https://docs.tabnine.com/main/administering-tabnine/managing-your-team/settings/models-settings.md)

## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial platform controls and documented verification packs | How to Harden Community |

## Contributing

Report inaccurate or outdated guidance through the [issue tracker](https://github.com/grcengineering/how-to-harden/issues).
