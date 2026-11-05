---
layout: guide
title: "Mentlio Hardening Guide"
vendor: "Mentlio"
slug: "mentlio"
platform: "Factory"
platform_slug: "factory"
product: "Mentlio"
tier: "2"
category: "AI/ML Platform"
description: "Review Mentlio team access, local agent identities, derived telemetry, model routing, integration grants and the limits of proxy-enforced spend controls."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-05"
---

## Overview

Mentlio is a **product within the [Factory platform](/guides/factory/)** with its own desktop agent, organization dashboard and integrations. Factory’s [October 9 announcement](https://factory.com/news/mentlio) is titled as an acquisition and says the team is joining Factory. The surviving [Mentlio product documentation](https://www.mentlio.com/docs), updated September 3 and read in a real browser on 2026-11-05, describes an operating product with its own account, agent and integration administration. The announcement does not establish a hosted shutdown date or migration contract. **Factory’s Droid organization policy, SSO and API keys do not configure Mentlio.**

**Validation status:** no tenants declared — Tier 0+1 only. These five controls are documentation-backed and remain [ai-drafted](https://github.com/grcengineering/how-to-harden/blob/main/VERSIONS.md#maturity-statuses--the-matrix). No desktop agent, organization, integration consent or enforcement path was exercised. Mentlio’s local-processing and telemetry statements are company-stated behavior, not independently observed guarantees.

### Intended Audience

- Administrators approving desktop AI-usage measurement and routing
- Identity owners reviewing employee, team and manager access
- Security teams approving engineering-system and notification integrations

### How to Use This Guide

- **L1 (Crawl):** Review organization access and downstream grants.
- **L2 (Walk):** Review local credential reuse, data destinations and bypassable client routing.
- Keep the underlying AI clients’ own access and model policy in place.

### Scope

This guide uses the actual public configuration guidance rather than acquisition marketing. The docs give some exact UI surfaces (Integrations, desktop connection/activation, savings/routing settings), but no complete role-permission matrix, OAuth scopes, native policy schema, hosted API/SDK, managed installer/MDM contract or credential-store paths. Those are explicit research gaps in the [family ledger](/research/factory-source-coverage/). No unsupported interface, pack or detailed consent path is invented. Generic disk/host hardening and cost optimization alone are outside scope.

## Table of Contents

1. [Organization Access](#1-organization-access)
2. [Local Agent and Routing](#2-local-agent-and-routing)
3. [Integration Access](#3-integration-access)
4. [Enforcement Boundaries](#4-enforcement-boundaries)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

## 1. Organization Access

### 1.1 Review Employee Team and Manager Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-2, AC-6 |

#### Description

Maintain an approved Mentlio organization roster and review employee team/manager assignments when responsibilities change. Remove accounts that no longer need access and verify the actual role boundary before exposing employee-level telemetry.

#### Rationale

**Why This Matters:**

- Team and employee views can reveal individual AI usage, quality and delivery information.
- Stale manager assignments can expose employee reporting outside its intended audience.

**Attack Prevented:** Orphaned organization access and excessive visibility into employee-derived activity.

#### Prerequisites

The account or organization administrator, a reviewed workflow and a disposable pilot environment.

#### ClickOps Implementation

1. Use the organization’s employee/team administration workflow to compare work-email invitations, current membership and team/manager assignments with the approved roster. The docs describe these operations without publishing an exact universal menu or role-permission matrix; confirm the deployed UI before changing access.
2. Review **Teams** and employee profiles under the intended management scope and test an ordinary employee’s visibility. Do not assert that a manager can see only their team until the actual product boundary is verified.
3. Remove accounts no longer required and review configured Microsoft Entra ID or other supported sign-in-provider grants where present. The documentation does not establish SSO enforcement, SCIM or MFA configuration steps; record those as gaps rather than importing Factory’s WorkOS paths.

Source: [Mentlio product documentation](https://www.mentlio.com/docs), “Getting started,” “Dashboard” and “Data and security,” read in a real browser 2026-11-05.

**Automation:** Manual review through the documented product surfaces. A public administration API, CLI, SDK, Terraform resource/data source or native enforceable configuration contract was not verified; this is an unverified automation gap, not a claim that none exists. ([Product docs](https://www.mentlio.com/docs), checked 2026-11-05.)

#### Validation & Testing

- In an authorized test organization, compare administrator, manager and employee access using harmless fixture telemetry. Record the actual permission matrix.
- Verify removal and reassignment outcomes and any retained reporting data separately; invitation removal is not a deletion guarantee.

#### Monitoring & Maintenance

Review after client, integration and role changes and at least quarterly. Keep private evidence of the identity, client version, effective scope and result; do not retain credential values in the report.

#### Operational Impact

Membership and team changes can interrupt dashboards and change reporting scope. Preserve an approved roster and a separate recovery administrator.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-2, AC-6 | Supports the access, configuration or information-flow objective described above; no certification claim. |

---

## 2. Local Agent and Routing

### 2.1 Review Local Credential Reuse and Uploaded Telemetry

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | IA-5, AC-4 |

#### Description

Approve the Mentlio desktop agent’s use of existing AI-client identities and the derived information uploaded to the organization dashboard. Distinguish the company’s local-processing claim from an observed endpoint or storage guarantee.

#### Rationale

**Why This Matters:**

- The agent uses the existing local Cursor sign-in to collect exact model, token, cache and charged-cost records.
- Derived classifications, scores and model metadata can still be sensitive employee and engineering information.

**Attack Prevented:** Unexpected identity reuse and disclosure of sensitive derived activity through an unreviewed endpoint agent.

#### Prerequisites

The account or organization administrator, a reviewed workflow and a disposable pilot environment.

#### ClickOps Implementation

1. Use the menu-bar/system-tray app to inspect **connection and activation status**. Confirm the employee and organization receiving that device’s telemetry before activating a transferred or shared device.
2. Review supported clients on that host: Claude Code, Codex, Cursor, GitHub Copilot CLI/macOS, and supported VS Code extensions. The docs state Cursor credentials and raw account identifiers stay on-device and require no Cursor API key; no precise credential-store path, at-rest mechanism or native lock policy is published. Obtain that contract before claiming stronger protection.
3. Review the documented upload boundary: prompts, raw outputs, source code, private files and full paths are said to remain local; classifications, scores, token counts, model metadata and aggregate savings are sent to the dashboard. Approve retention and recipients for that derived telemetry; the docs do not give an enforced upload-disable or retention setting.
4. During offboarding, reconcile the employee account, active desktop activation and the underlying clients’ local credentials separately. Do not treat a dashboard account change as proof that every client credential or local cache was removed.

Source: [Mentlio documentation](https://www.mentlio.com/docs), “Desktop agent” and “Data and security,” read in a real browser 2026-11-05.

**Automation:** Manual review through the documented product surfaces. A public administration API, CLI, SDK, Terraform resource/data source or native enforceable configuration contract was not verified; this is an unverified automation gap, not a claim that none exists. ([Product docs](https://www.mentlio.com/docs), checked 2026-11-05.)

#### Validation & Testing

- In an authorized isolated device test, verify the connected organization and examine approved telemetry evidence using synthetic prompts. Do not submit real source or secrets to test a privacy claim.
- Record missing credential-store, telemetry-retention and deactivation contracts as unresolved; connection status alone is not proof of the data-flow assertions.

#### Monitoring & Maintenance

Review after client, integration and role changes and at least quarterly. Keep private evidence of the identity, client version, effective scope and result; do not retain credential values in the report.

#### Operational Impact

Deactivation or account changes may stop measurement and routing. Keep product-specific cleanup evidence separate from underlying AI-client offboarding.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | IA-5, AC-4 | Supports the access, configuration or information-flow objective described above; no certification claim. |

---

### 2.2 Approve Routing and Local Context Transformations

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-4, CM-6 |

#### Description

Review Mentlio’s organization-managed savings/routing controls against the approved model destinations and data-handling policy before rollout. A cheaper model or transformed tool output can change where context is processed and what later agent steps consume.

#### Rationale

**Why This Matters:**

- Route can choose another model, while Lens, Logs and Recall change context or locally retained output.
- Underlying AI clients retain their own model and credential policies.

**Attack Prevented:** Context transfer to an unapproved model and unreviewed transformation or retention of agent tool data.

#### Prerequisites

The account or organization administrator, a reviewed workflow and a disposable pilot environment.

#### ClickOps Implementation

1. As an organization manager, review the available controls in Mentlio’s **savings and routing settings**. Approve model destinations and account identities before enabling Route broadly; the docs provide no endpoint/model allowlist schema or hard enforcement contract.
2. Review Lens semantic code search, Quiet response shaping, Logs compression and Recall’s local reversible output markers. Confirm which information is retained locally or supplied back to the agent; do not describe them as DLP or immutable redaction controls.
3. Pilot each change on synthetic repositories under the underlying clients’ own model policy. The docs say Copilot model selection is intercepted locally so Auto does not reach GitHub’s server-side router; verify effective routing rather than treating a UI selection as proof.

Source: [Mentlio documentation](https://www.mentlio.com/docs), “Token Savers” and “Desktop agent,” read in a real browser 2026-11-05.

**Automation:** Manual review through the documented product surfaces. A public administration API, CLI, SDK, Terraform resource/data source or native enforceable configuration contract was not verified; this is an unverified automation gap, not a claim that none exists. ([Product docs](https://www.mentlio.com/docs), checked 2026-11-05.)

#### Validation & Testing

- Compare actual provider/model evidence before and after an authorized pilot and confirm approved destinations. Investigate any mismatch with the underlying client’s policy.
- Verify compressed/Recall output can be retrieved as intended without exposing prohibited data. No offline generated policy proves this runtime behavior.

#### Monitoring & Maintenance

Review after client, integration and role changes and at least quarterly. Keep private evidence of the identity, client version, effective scope and result; do not retain credential values in the report.

#### Operational Impact

Routing and context changes can affect behavior and quality. Restore the prior reviewed configuration if the pilot violates destination or data-handling requirements.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-4, CM-6 | Supports the access, configuration or information-flow objective described above; no certification claim. |

---

## 3. Integration Access

### 3.1 Limit Engineering and Notification Integration Grants

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-6, AC-21 |

#### Description

Connect only the engineering systems and notification destinations needed for approved reporting. Review the actual provider organization, repository, project and workspace grants during setup and reconnection, and remove integrations that are no longer required.

#### Rationale

**Why This Matters:**

- GitHub, Jira and Linear contribute engineering context beyond local agent measurements.
- Slack and Teams digests or coaching alerts can expose derived employee and delivery information to another audience.

**Attack Prevented:** Overbroad source-system access and telemetry disclosure through notification integrations.

#### Prerequisites

A Mentlio administrator, downstream app-consent authority and an approved source/destination inventory.

#### ClickOps Implementation

1. Open the dashboard **Integrations** page. Review GitHub repository/PR delivery access and Jira/Linear project/issue access against the approved inventory. Exact OAuth scopes and app permission manifests were not published by the fetched page; inspect actual consent and provider grants before approval.
2. For Slack and Microsoft Teams, review the configured digest, coaching and threshold-alert audiences before enabling delivery. The docs do not specify channel-specific setup steps, scope names, signing/replay checks or the complete payload; do not substitute Factory or HumanLayer integration contracts.
3. When reconnecting a stale integration, verify the provider account still grants only the intended organization, repositories, project or workspace. Reauthorization can expand access and requires a fresh review.
4. Remove integrations that are no longer needed and verify downstream grant revocation. Review retained notifications/reporting data separately; the public docs do not establish a complete disconnection/purge contract.

Source: [Mentlio documentation](https://www.mentlio.com/docs), “Integrations,” “Data and security” and “Troubleshooting,” read in a real browser 2026-11-05.

**Automation:** Manual review through the documented product surfaces. A public administration API, CLI, SDK, Terraform resource/data source or native enforceable configuration contract was not verified; this is an unverified automation gap, not a claim that none exists. ([Product docs](https://www.mentlio.com/docs), checked 2026-11-05.)

#### Validation & Testing

- Test one harmless approved source and notification destination in an authorized tenant; verify actual payload recipients and denied out-of-scope access.
- Record consent scopes, update latency, revocation outcome and retention limits from the deployed integration. Missing evidence is unknown, not a clean audit.

#### Monitoring & Maintenance

Review after client, integration and role changes and at least quarterly. Keep private evidence of the identity, client version, effective scope and result; do not retain credential values in the report.

#### Operational Impact

Removing grants can stop delivery reporting and alerts. Preserve a minimal approved destination inventory and verify reconnection does not restore broad defaults.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-6, AC-21 | Supports the access, configuration or information-flow objective described above; no certification claim. |

---

## 4. Enforcement Boundaries

### 4.1 Verify Managed-Hook Coverage Before Relying on Usage Limits

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-6, CM-8 |

#### Description

If a manager enables monthly AI-usage limits, inventory which clients actually pass through Mentlio’s managed hooks and proxies. The documented cap blocks new prompts only on those paths and cannot enforce direct connections that bypass the daemon.

#### Rationale

**Why This Matters:**

- An abuse-prevention limit is ineffective for traffic that never reaches the enforcing hook or proxy.
- An inactive desktop agent or changed client integration can silently change coverage.

**Attack Prevented:** Unbounded agent resource use through unmanaged client connections or stale interception paths.

#### Prerequisites

The account or organization administrator, a reviewed workflow and a disposable pilot environment.

#### ClickOps Implementation

1. Review the manager-configured monthly usage limit and its intended users. The docs establish manager control but give no exact universal limit-menu path or configuration schema; confirm the deployed setting with the administrator.
2. Inventory each supported client and extension on the device, then confirm the desktop agent’s **activation/connection** and actual managed-hook/proxy path. Distinguish observed spend from every provider account’s full usage.
3. Test a harmless synthetic prompt through the managed path in an approved pilot. Treat direct client traffic as outside the documented enforcement boundary; underlying provider/client access and limits still need their own controls.
4. Recheck after client, extension, OS and agent updates. A reporting dashboard or configured threshold is not proof of prompt blocking.

Source: [Mentlio documentation](https://www.mentlio.com/docs), “Desktop agent” monthly-limit paragraph and troubleshooting, read in a real browser 2026-11-05.

**Automation:** Manual review through the documented product surfaces. A public administration API, CLI, SDK, Terraform resource/data source or native enforceable configuration contract was not verified; this is an unverified automation gap, not a claim that none exists. ([Product docs](https://www.mentlio.com/docs), checked 2026-11-05.)

#### Validation & Testing

- Record which exact client/version paths are managed and which are direct. Validate blocking only with harmless authorized fixtures and a controlled limit.
- Confirm inactive/lost activation is detected and record unknown or bypassed paths explicitly; no code pack fabricates a universal network enforcement rule.

#### Monitoring & Maintenance

Review after client, integration and role changes and at least quarterly. Keep private evidence of the identity, client version, effective scope and result; do not retain credential values in the report.

#### Operational Impact

A cap can interrupt developer prompts, while bypass paths remain usable. Resolve coverage gaps through the actual provider/client policy rather than overstating Mentlio’s limit.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-6, CM-8 | Supports the access, configuration or information-flow objective described above; no certification claim. |

---

## 5. Compliance Quick Reference

Mappings are supporting objectives, not a product benchmark. Product-specific CIS, DISA, CISA SCuBA, NSA and ACSC coverage was not verified in this refresh; no claim of verified absence is made. No third-party incident or certification claim originates a control.

| Objective | Controls | NIST SP 800-53 Rev. 5 families |
|-----------|----------|-----------------------------|
| Organization and downstream access | 1.1, 3.1 | AC |
| Local identity, destinations and data | 2.1–2.2 | AC, IA, CM |
| Actual enforcement coverage | 4.1 | AC, CM |

## Appendix A: Automation and Evidence Limits

Five authored controls; zero packs. The [public documentation](https://www.mentlio.com/docs) provides implementable UI/agent review guidance but does not establish an executable public administration contract. Shipping an invented policy file or unofficial CLI would conceal this limit.

| Surface | Evidence status and read/write decision |
|---------|-----------------------------------------|
| Terraform resources/data sources | Unverified; no vendor-native resource/data-source catalog established. No infrastructure substitute. |
| REST/GraphQL | Unverified; no current supported admin endpoint categories or schema established. No guessed inventory or writer. |
| First-party CLI/daemon | Desktop local agent documented. No public supported CLI/daemon command reference verified; no `cli/` pack. |
| Official SDK | Unverified; no admin/security SDK contract established. |
| Native config/system policy | Manager controls and desktop activation documented, but no native config/MDM keys, credential-store path or enforceable endpoint allowlist verified. UI review only. |
| SIEM | Derived telemetry/dashboard and notification delivery documented; no stable audit export/event schema or SIEM table verified. |

These are research gaps, not assertions that interfaces do not exist. Obtain supported configuration and lifecycle contracts from Mentlio before relying on automated evidence, enterprise sign-in enforcement, retention or migration guarantees.

## Appendix B: References

- [Mentlio product documentation](https://www.mentlio.com/docs) — actual agent, dashboard, routing and integration instructions
- [Factory acquisition announcement](https://factory.com/news/mentlio) — corporate boundary only
- [Family source coverage ledger](/research/factory-source-coverage/) — retrieval limits, candidate dispositions and surface census

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-05 | 0.1.0 | ai-drafted | Initial five-control guide from surviving product documentation; separate control-plane and explicit automation/source limitations; no live validation. | Codex (GPT-6) |

## Contributing

Report corrections through [GitHub issues](https://github.com/grcengineering/how-to-harden/issues), including product edition, client version, primary source and validation scope. Follow the [contribution guidelines](/contributing/).
