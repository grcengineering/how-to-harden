---
layout: guide
title: "Claude Tag Hardening Guide"
vendor: "Claude Tag"
slug: "claude-tag"
platform: "Anthropic"
platform_slug: "anthropic"
product: "Claude Tag"
tier: "1"
category: "AI/ML Platform"
description: "Harden Claude Tag’s Slack audiences, agent identity, connectors, federation, egress, runtime, retention and audit boundaries."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-11"
---

## Overview

Claude Tag is Anthropic’s Slack-native team agent, currently in public beta, not a synonym for Claude Code or an API resource tag. This product guide extends the [Anthropic Common Controls](/guides/anthropic-claude/) and [Claude Enterprise guide](/guides/claude-enterprise/). Apply those identity, organization and integration controls alongside this guide.

Channel work normally uses the agent’s service identity. Member-linked one-to-one DMs, personal connectors in channels, group DMs and unlinked-user DMs have different identity, audience and billing boundaries. An employee’s ability to invoke Tag is not proof that Tag acts with that employee’s upstream permissions. Nor does an Enterprise IP allowlist or tenant restriction cover messages sent through Slack.

### Scope and validation boundary

This guide covers the documented commercial Team/Enterprise Tag surfaces as checked **2026-11-11**, including current federated agent access. Recommendations are HTH’s risk-based baseline, not a claim to reproduce Anthropic Security Center’s exact checklist. See the [source-coverage ledger](/research/claude-tag-source-coverage-2026-11). The **Scheduled tasks** capability under **Remote sessions** is a documented prerequisite; disabling it prevents Tag work rather than making Tag local-only. No live tenant was configured or validated; public documentation and offline pack tests retain **ai-drafted** maturity. Version, plan and staged-UI differences require verification in your tenant. Government/FedRAMP guidance does not make commercial Tag authorized for government workloads.

### Intended Audience

Enterprise security administrators, Slack administrators, platform engineers and owners of services delegated to agents.

### How to Use This Guide

- **L1 (Crawl):** establish the minimum identity, audience, data and response boundaries.
- **L2 (Walk):** constrain sensitive workloads and test every independent authorization layer.
- The Tag Admin API (and these API/CLI/SDK packs) requires an Enterprise organization; Team deployments use the documented console controls. Use synthetic data in pilots and negative tests. Apply mode changes organizational configuration only when an operator explicitly approves its exact plan; no pack provisions credentials or performs underlying business tasks.

## Table of Contents

1. [Governance and Containment](#1-governance-and-containment)
2. [Credentials, Egress and Federation](#2-credentials-egress-and-federation)
3. [Slack Audience and Disclosure](#3-slack-audience-and-disclosure)
4. [Runtime and Persistent Work](#4-runtime-and-persistent-work)
5. [Data Lifecycle and Operations](#5-data-lifecycle-and-operations)

## 1. Governance and Containment

### 1.1 Inventory Effective Access Before Enabling Tools

**Profile Level:** L1 (Crawl)

#### Description

Inventory paired workspaces, channels, scope settings, bundles and delegated administration before connecting privileged systems. Treat the API inventory as partial, not a full effective-permission calculation.

#### Rationale

**Why This Matters:**
- Channel service identities can exceed the requesting employee’s own access.
- API-visible scope records do not establish the contents or effective inheritance of every bundle.

**Attack Prevented:** Unnoticed broad grants and false compliance conclusions.

#### Prerequisites

An authorized Owner or appropriately delegated administrator; approved test channels and non-sensitive fixtures. Plan-specific capabilities are called out below.

#### ClickOps Implementation

Open **Organization settings → Claude Tag → Claude’s access**. Review **Channels**, **Connectors**, bundles and the inheritance shown for each pilot channel. Include Enterprise Grid workspace IDs, channel-name rules, repository grants and each credential’s upstream permissions. Assign a named owner to every access grant. Compare the read-only pack output with this console evidence; resolve unknowns before approval.

#### Code Implementation

{% include pack-code.html vendor="claude-tag" section="1.1" %}

#### Validation & Testing

Run the inventory with a read-only key where supported. Verify that a known broad grant and a Grid workspace are represented. Missing resources, pagination failures and opaque bundle contents must remain UNKNOWN, never PASS.

**Expected result:** Approved operations succeed, disallowed operations fail, and untested or inaccessible surfaces remain explicitly unknown.

#### References

- [Anthropic: attach to scope](https://claude.com/docs/claude-tag/admins/attach-to-scope)

### 1.2 Constrain Invocation and Provide a Tested Stop Control

**Profile Level:** L1 (Crawl)

#### Description

Limit who can invoke Tag and where it runs. Disable an unapproved channel explicitly rather than assuming a parent toggle is an unconditional deny.

#### Rationale

**Why This Matters:**
- An installed Slack app can expose agent authority to users without a Claude seat.
- Scoped overrides and inherited settings differ from a global kill switch.

**Attack Prevented:** Unauthorized invocation and ineffective incident containment.

#### Prerequisites

An authorized Owner or appropriately delegated administrator; approved test channels and non-sensitive fixtures. Plan-specific capabilities are called out below.

#### ClickOps Implementation

On **Claude’s access → Channels → Slack → Advanced → Access**, enable the Enterprise role restriction (or Team organization restriction). On Enterprise, assign custom roles deliberately: built-in roles grant Tag and any granting role wins. On **General**, disable broad channel response and enable only approved channels where per-scope switches exist. Reset pre-existing workspace/channel enable overrides before relying on a default-off rollout. Review DMs separately. Enterprise Grid channels shared across workspaces paired to the same Claude organization use only the Slack-root settings/access, not channel/workspace bundles; they cannot be individually enabled as exceptions to root default-off. Shared channels spanning different Claude organizations do not respond. Test these Grid cases separately. Disable DMs when unapproved; group DMs lack individual channel-style scoping and can inherit root/workspace access. Review verified-domain account linking when your Enterprise organization exposes that control. Use blocked name patterns to exclude sensitive channels and audit auto-join rules; never assume an auto-join rule alone enables a disabled channel. Use the pack only for an existing exact channel you intend to disable; it also restricts guests. Review the before/after plan before explicit apply.

#### Code Implementation

{% include pack-code.html vendor="claude-tag" section="1.2" %}

#### Validation & Testing

Test an authorized and unauthorized member and an explicitly disabled channel. Confirm no new task starts there, while approved channels remain unchanged. Emergency response also revokes upstream credentials; disabling responses does not erase stored data.

**Expected result:** Approved operations succeed, disallowed operations fail, and untested or inaccessible surfaces remain explicitly unknown.

#### References

- [Anthropic: restrict access](https://claude.com/docs/claude-tag/admins/restrict-access)

### 1.3 Cross-check Explicit Bundle Targets with the SDK

**Profile Level:** L1 (Crawl)

#### Description

Use the official SDK’s paginated target inventory as a second evidence route. A target list is not the contents of a bundle or a complete effective policy.

#### Rationale

**Why This Matters:**
- Explicit workspace targets can grant far more than a single channel.
- Default and rule-derived access is not represented by explicit target rows.

**Attack Prevented:** Undetected broad bundle assignment and misleading “no targets means no access” findings.

#### ClickOps Implementation

Open each bundle in **Claude’s access** and compare **Where it applies** with the inventory. Reconcile channel-name rules, defaults and contents separately; do not delete or detach anything based on an incomplete list.

#### Code Implementation

{% include pack-code.html vendor="claude-tag" section="1.3" %}

#### Validation & Testing

Use an organization-scoped `read:claude_tag` key and a current SDK exposing the documented namespace. Confirm all pages are traversed. A failed page or unsupported SDK is an error, not an empty inventory. Review the private report against the console.

#### References

- [Claude Tag Admin API and SDK](https://platform.claude.com/docs/en/manage-claude/claude-tag-api)

## 2. Credentials, Egress and Federation

### 2.1 Keep Service Credentials Narrowly Scoped from Creation

**Profile Level:** L1 (Crawl)

#### Description

Use dedicated service identities and introduce sensitive credentials at the channel or an initially unassigned bundle, not through an organization-wide default.

#### Rationale

**Why This Matters:**
- Every member in an authorized channel can benefit from the service identity’s permissions.
- The first credential created for a service on the Connectors tab applies across Slack immediately.

**Attack Prevented:** Privilege amplification and transient organization-wide credential exposure.

#### Prerequisites

An authorized Owner or appropriately delegated administrator; approved test channels and non-sensitive fixtures. Plan-specific capabilities are called out below.

#### ClickOps Implementation

Create a dedicated upstream identity with only necessary projects, folders and operations. In **Claude’s access → Channels**, open the intended private channel and add a **Connector** there, or use a new bundle and assign only approved channels. Inspect **Where it applies** and inherited access at root, workspace, channel and name-rule scopes. Remove broad grants at their source: a narrow bundle does not subtract inherited privileges. Recheck when channels are renamed or shared.

**Automation:** The inventory pack in [1.1](#11-inventory-effective-access-before-enabling-tools) supplies partial evidence only. The current Tag API covers only five scope settings plus explicit bundle attachments, not these connector, identity, retention or other console/upstream-service controls. Use their documented console/service configuration and verify effective inheritance separately. See the automation-surface census in the research ledger; this is a pack coverage boundary, not a claim that vendor APIs do not exist.

#### Validation & Testing

Use harmless fixtures to prove access in the approved channel and denial in an unrelated channel. Test the union of overlapping bundles and rules, not only the newly added grant.

**Expected result:** Approved operations succeed, disallowed operations fail, and untested or inaccessible surfaces remain explicitly unknown.

#### References

- [Anthropic: add connections](https://claude.com/docs/claude-tag/admins/add-connections)

### 2.2 Constrain Credential Injection and All Egress Layers

**Profile Level:** L2 (Walk)

#### Description

Restrict credential destinations, paths and methods, and audit every independent outbound allowance. Secret isolation alone does not prevent misuse of the authenticated API.

#### Rationale

**Why This Matters:**
- Proxy-injected secrets are outside the sandbox, but the agent can still exercise their granted authority.
- Domain entries and environment network policy can allow uncredentialed exfiltration independently.

**Attack Prevented:** Credential forwarding, excessive API operations and outbound data exfiltration.

#### Prerequisites

An authorized Owner or appropriately delegated administrator; approved test channels and non-sensitive fixtures. Plan-specific capabilities are called out below.

#### ClickOps Implementation

In each connector’s advanced settings, replace broad or incorrect regional **Allowed websites** with approved hosts; use documented path-prefix and HTTP-method restrictions where supported. Review domain entries at every scope and avoid the allow-all `*` entry. Review the selected cloud environment’s network policy: **Limited access** already permits developer/package hosts. Prefer the smallest required network set. Review GitHub separately because its proxy is not governed by these ordinary egress layers. Server-side web search is another distinct path: sandbox domain/network rules do not govern it and no Tag channel web-search-off switch is documented. Shared egress IPs identify vendor infrastructure, not your tenant; authenticate every exposed service. Do not put secrets in instructions, setup scripts, repository files or environment variables merely to bypass connector constraints.

**Automation:** The inventory pack in [1.1](#11-inventory-effective-access-before-enabling-tools) supplies partial evidence only. The current Tag API covers only five scope settings plus explicit bundle attachments, not these connector, identity, retention or other console/upstream-service controls. Use their documented console/service configuration and verify effective inheritance separately. See the automation-surface census in the research ledger; this is a pack coverage boundary, not a claim that vendor APIs do not exist.

#### Validation & Testing

Test approved and rejected hosts, methods and paths with non-sensitive requests; also test uncredentialed egress and GitHub. Inspect upstream audit records to confirm the dedicated identity. Revalidate redirects and subdomain matching before allowing a new endpoint.

**Expected result:** Approved operations succeed, disallowed operations fail, and untested or inaccessible surfaces remain explicitly unknown.

#### References

- [Anthropic: security and data](https://claude.com/docs/claude-tag/concepts/security-and-data)

### 2.3 Prefer Federated Agent Identity with Exact Subject Authorization

**Profile Level:** L2 (Walk)

#### Description

Where supported, replace stored keys with Tag’s documented gateway, AWS role, Google Cloud workload identity or OAuth authorization-server federation. This authenticates the channel agent, not the employee.

#### Rationale

**Why This Matters:**
- The token issuer and some audiences are shared across customers.
- A valid signature alone does not authorize this organization’s agent.

**Attack Prevented:** Cross-tenant confused-deputy access and stolen long-lived credentials.

#### Prerequisites

An authorized Owner or appropriately delegated administrator; approved test channels and non-sensitive fixtures. Plan-specific capabilities are called out below.

#### ClickOps Implementation

Open the documented **Federated agent access** setup and create the least-privileged connection in an unassigned bundle before selecting channels. At your gateway or authorization server validate ES256 signature using rotating JWKS, issuer, exact audience, expiry and your exact agent subject; if deliberately using an organization prefix, include its complete agent boundary. Do not infer human roles or group membership from reserved/absent claims. Keep upstream resource authorization independent. A gateway’s control/test subject must receive only readiness responses, never backend-service rights; never forward the identity token to downstream services. These connections require Anthropic-hosted channel sessions, not self-hosted environments or personal one-to-one DMs.

**Automation:** The inventory pack in [1.1](#11-inventory-effective-access-before-enabling-tools) supplies partial evidence only. The current Tag API covers only five scope settings plus explicit bundle attachments, not these connector, identity, retention or other console/upstream-service controls. Use their documented console/service configuration and verify effective inheritance separately. See the automation-surface census in the research ledger; this is a pack coverage boundary, not a claim that vendor APIs do not exist.

#### Validation & Testing

Accept the intended agent and reject another tenant, wrong audience, expired token and tampered signature. Exercise key rotation without pinning one signing key. A repeated token identifier is not automatically an attack: gateway tokens may be reused across requests. Test your own revocation response and upstream token expiry.

**Expected result:** Approved operations succeed, disallowed operations fail, and untested or inaccessible surfaces remain explicitly unknown.

#### References

- [Anthropic: token reference](https://claude.com/docs/claude-tag/admins/federated-access/token-reference)

### 2.4 Prevent Federated Cloud Credentials from Expanding Authority

**Profile Level:** L2 (Walk)

#### Description

Apply least-privilege cloud IAM and token-exchange restrictions as well as federation trust. Removing a connection does not instantly invalidate all previously issued credentials.

#### Rationale

**Why This Matters:**
- A short-lived credential can still mint another credential or authorize a destructive action.
- AWS sessions and downstream access tokens can outlast the Tag identity token.

**Attack Prevented:** Credential laundering, persistence and cloud privilege escalation.

#### Prerequisites

An authorized Owner or appropriately delegated administrator; approved test channels and non-sensitive fixtures. Plan-specific capabilities are called out below.

#### ClickOps Implementation

For AWS, condition role trust on both the intended subject and audience and restrict role resources/actions; the documented connection supports commercial-partition roles, not GovCloud/China. For Google Cloud, restrict provider attributes and IAM grants and retain **Block requests that mint new credentials** unless a reviewed exception requires otherwise. That block is best-effort, not a substitute for IAM; the OAuth scope is broad cloud-platform. For OAuth servers, authorize the subject, issue narrowly scoped short-lived tokens and constrain allowed API hosts/paths away from the token endpoint. Include upstream revocation in containment runbooks: Tag identity tokens last ten minutes and cannot be revoked; AWS sessions last one hour, and other issued tokens follow their issuer’s expiry.

**Automation:** The inventory pack in [1.1](#11-inventory-effective-access-before-enabling-tools) supplies partial evidence only. The current Tag API covers only five scope settings plus explicit bundle attachments, not these connector, identity, retention or other console/upstream-service controls. Use their documented console/service configuration and verify effective inheritance separately. See the automation-surface census in the research ledger; this is a pack coverage boundary, not a claim that vendor APIs do not exist.

#### Validation & Testing

Exercise negative IAM tests, denied credential/signature creation and denied unauthorized resources. Record maximum residual access after removal. Verify actual cloud audit events; a successful console connection check alone does not validate every downstream authorization rule.

**Expected result:** Approved operations succeed, disallowed operations fail, and untested or inaccessible surfaces remain explicitly unknown.

#### References

- [Anthropic: limits](https://claude.com/docs/claude-tag/admins/federated-access/limits)

## 3. Slack Audience and Disclosure

### 3.1 Default External Audiences to Restricted Access

**Profile Level:** L1 (Crawl)

#### Description

Keep guest and Slack Connect channels restricted unless their explicit channel grants are approved for the external audience.

#### Rationale

**Why This Matters:**
- Guests can read posted results even when they cannot approve tools.
- Channel-only mode preserves directly attached channel access and is not an empty-permission sandbox.

**Attack Prevented:** Disclosure to guests and cross-company Slack participants.

#### Prerequisites

An authorized Owner or appropriately delegated administrator; approved test channels and non-sensitive fixtures. Plan-specific capabilities are called out below.

#### ClickOps Implementation

On the relevant scope’s **Advanced → Access**, keep **How should Claude work in channels with guests** at **Restrict**. For an approved exception, use **Channel only**, review direct bundles/connectors and channel instructions, and test the actual Slack Connect audience. In channel-only guest mode the selected custom environment does not apply; do not rely on its setup or network policy. Re-review existing channels before sharing them externally and after a guest joins. In Slack Connect, even **Full access** is capped at channel-only access; directly attached eligible bundles can still serve external participants. Guest channels cannot search the workspace even under Full access. Use the organization/role invocation restriction as well, but remember that blocking invocation does not prevent an external participant from reading posted results.

**Automation:** The inventory pack in [1.1](#11-inventory-effective-access-before-enabling-tools) supplies partial evidence only. The current Tag API covers only five scope settings plus explicit bundle attachments, not these connector, identity, retention or other console/upstream-service controls. Use their documented console/service configuration and verify effective inheritance separately. See the automation-surface census in the research ledger; this is a pack coverage boundary, not a claim that vendor APIs do not exist.

#### Validation & Testing

Test a guest join and an external-company member with harmless data. Confirm inherited private grants are unavailable and directly attached grants expose only approved material. Test a fresh thread and the documented transition of an existing conversation.

**Expected result:** Approved operations succeed, disallowed operations fail, and untested or inaccessible surfaces remain explicitly unknown.

#### References

- [Anthropic: restrict access](https://claude.com/docs/claude-tag/admins/restrict-access)

### 3.2 Limit Search and Personal-Connector Disclosure

**Profile Level:** L2 (Walk)

#### Description

Constrain workspace search and require review before personal-connector results reach shared channels. Treat result screening as advisory detection, not recipient authorization.

#### Rationale

**Why This Matters:**
- Default public-channel search includes channels the app has not joined.
- The requester’s personal access does not prove that every recipient may see the result.

**Attack Prevented:** Cross-channel disclosure and private-to-shared data leakage.

#### Prerequisites

An authorized Owner or appropriately delegated administrator; approved test channels and non-sensitive fixtures. Plan-specific capabilities are called out below.

#### ClickOps Implementation

For sensitive deployments set **Channels Claude can search** to **Only channels Claude is in** and inspect more-specific overrides. In **Claude Tag → Personal connectors → Edit**, Enterprise admins should enable **Require human review of every message**. Keep **Claude Opus 5**, required by the current sensitive-content checks, available and review underlying connector enablement. Team has no equivalent mandatory-review switch; document the gap or avoid sensitive personal connectors. Do not describe disabling a dedicated Tag personal-connector toggle as available when it is not.

**Automation:** The inventory pack in [1.1](#11-inventory-effective-access-before-enabling-tools) supplies partial evidence only. The current Tag API covers only five scope settings plus explicit bundle attachments, not these connector, identity, retention or other console/upstream-service controls. Use their documented console/service configuration and verify effective inheritance separately. See the automation-surface census in the research ledger; this is a pack coverage boundary, not a claim that vendor APIs do not exist.

#### Validation & Testing

From a pilot channel, verify excluded public-channel content is not returned. With synthetic private data, verify the requester reviews every personal-connector result before posting. Review final recipients manually; screening does not check their source-system ACLs.

**Expected result:** Approved operations succeed, disallowed operations fail, and untested or inaccessible surfaces remain explicitly unknown.

#### References

- [Anthropic: personal connectors](https://claude.com/docs/claude-tag/concepts/personal-connectors)

## 4. Runtime and Persistent Work

### 4.1 Select the Runtime and Repository Boundary Deliberately

**Profile Level:** L2 (Walk)

#### Description

Distinguish Anthropic-hosted sandboxes from self-hosted runners and restrict repositories independently of ordinary network policy.

#### Rationale

**Why This Matters:**
- Changing runtime changes connector availability and the trust boundary.
- The GitHub proxy is a distinct authorization plane.

**Attack Prevented:** Unexpected code access and credential leakage through repository workflows.

#### Prerequisites

An authorized Owner or appropriately delegated administrator; approved test channels and non-sensitive fixtures. Plan-specific capabilities are called out below.

#### ClickOps Implementation

Review the environment selected on each scope and apply the appropriate [Claude Code hardening guide](/guides/claude-code/) to its runtime. In Tag’s GitHub configuration grant only required repositories and keep human review and protected branches at GitHub. Tag-managed connectors are unavailable in self-hosted sessions; do not work around this by copying personal PATs into runners. Review the GitHub App’s access separately from domain allowlists; public unauthenticated clones may still be possible. Its fixed Actions authority includes re-running/cancelling/dispatching workflows, deleting runs/logs/artifacts, enabling/disabling workflows and proposing workflow-file changes. It cannot approve held runs/deployments or send `repository_dispatch`; a custom GitHub token does not replace this App identity. Require two approving reviews when a person other than the requester must review bot-authored PRs, and dismiss stale approvals after new pushes. One required review alone lets the requester approve and merge the agent’s PR.

**Automation:** The inventory pack in [1.1](#11-inventory-effective-access-before-enabling-tools) supplies partial evidence only. The current Tag API covers only five scope settings plus explicit bundle attachments, not these connector, identity, retention or other console/upstream-service controls. Use their documented console/service configuration and verify effective inheritance separately. See the automation-surface census in the research ledger; this is a pack coverage boundary, not a claim that vendor APIs do not exist.

#### Validation & Testing

Attempt authorized and unauthorized private-repository operations and confirm branch protections remain effective. Validate the selected runtime in a fresh thread and ensure no workflow depends on an unavailable hosted connector.

**Expected result:** Approved operations succeed, disallowed operations fail, and untested or inaccessible surfaces remain explicitly unknown.

#### References

- [Anthropic: configure github](https://claude.com/docs/claude-tag/admins/configure-github)

### 4.2 Protect Skills, Instructions and Scheduled Work

**Profile Level:** L2 (Walk)

#### Description

Treat skills repositories, plugins, setup scripts and channel memory as executable or persistent inputs. Restrict their writers and review standing work.

#### Rationale

**Why This Matters:**
- A channel task can persist through a schedule or stored instruction after its original request.
- Prompt instructions do not enforce backend permissions.

**Attack Prevented:** Persistent prompt injection and unauthorized recurring actions.

#### Prerequisites

An authorized Owner or appropriately delegated administrator; approved test channels and non-sensitive fixtures. Plan-specific capabilities are called out below.

#### ClickOps Implementation

Review **Claude’s access** scope customization and delegated channel managers. Under **Advanced → Sessions → Auto mode allow rules**, remove broad pre-approvals and limit any exception to the exact tool, action and environment in the narrowest scope. These additive rules bypass the permission checker for named actions; retain service-side authorization. Govern permitted models with Enterprise **Models → Model access**, not merely Claude Code’s server-managed model allowlist: channel sessions do not receive those managed settings, and their conversational allowlist check is not consistently enforced. Verify the actual model in a new reply’s footer and inspect fallback behavior. Keep Claude Sonnet 5 available for the documented channel-session permission checker rather than bypassing it to repair model restrictions. Protect a skills repository with pull-request review and branch protection; do not let the agent approve its own changes. Review **Activity → Scheduled work** and **Memory**, pause unapproved routines, and keep high-impact actions behind service-side approval. Disable automatic responses for sensitive pilot channels when unprompted activity is not wanted. Rebuild test threads after changing startup-loaded skills/instructions; access/connection checks have different refresh semantics.

**Automation:** The inventory pack in [1.1](#11-inventory-effective-access-before-enabling-tools) supplies partial evidence only. The current Tag API covers only five scope settings plus explicit bundle attachments, not these connector, identity, retention or other console/upstream-service controls. Use their documented console/service configuration and verify effective inheritance separately. See the automation-surface census in the research ledger; this is a pack coverage boundary, not a claim that vendor APIs do not exist.

#### Validation & Testing

Seed a harmless instruction-like document and confirm it cannot expand service permissions. Verify only approved skills revisions load in new sessions. Test routine pause and confirm the next scheduled run does not execute.

**Expected result:** Approved operations succeed, disallowed operations fail, and untested or inaccessible surfaces remain explicitly unknown.

#### References

- [Anthropic: skills repo](https://claude.com/docs/claude-tag/admins/skills-repo)

## 5. Data Lifecycle and Operations

### 5.1 Approve the Actual Retention and Regulated-Data Boundary

**Profile Level:** L1 (Crawl)

#### Description

Approve Tag’s own data lifecycle before admitting regulated or retention-limited material. Do not infer retention from ordinary Claude chat policies or Slack deletion.

#### Rationale

**Why This Matters:**
- During beta, session transcripts and memory have no automatic retention cutoff and do not inherit custom chat retention.
- Removing Slack content does not necessarily remove its transcript copies.

**Attack Prevented:** Unapproved long-term retention and mistaken deletion/compliance assurances.

#### Prerequisites

An authorized Owner or appropriately delegated administrator; approved test channels and non-sensitive fixtures. Plan-specific capabilities are called out below.

#### ClickOps Implementation

Read the current **Data lifecycle** and healthcare documentation with the data owner. Keep PHI out: Tag is not covered by Anthropic’s BAA. Tag is unavailable with ZDR, CMEK or the specified local Code/Cowork HIPAA configuration. Document separate lifecycles for transcripts, memory, artifacts, published code and downstream records. Treat public-channel workspace memory as shared context: credential isolation is not knowledge isolation. Artifacts follow their source Slack channel audience, not an independent private share boundary. Define authorized scope/workspace deletion procedures and preserve required evidence first; turning Tag off is not deletion, and exports/Compliance API are not complete deletion tools.

**Automation:** The inventory pack in [1.1](#11-inventory-effective-access-before-enabling-tools) supplies partial evidence only. The current Tag API covers only five scope settings plus explicit bundle attachments, not these connector, identity, retention or other console/upstream-service controls. Use their documented console/service configuration and verify effective inheritance separately. See the automation-surface census in the research ledger; this is a pack coverage boundary, not a claim that vendor APIs do not exist.

#### Validation & Testing

Use synthetic data to verify the planned deletion workflow and its scope. Confirm downstream copies separately. If required retention/deletion cannot be enforced, do not admit that data class or enable Tag for that workflow.

**Expected result:** Approved operations succeed, disallowed operations fail, and untested or inaccessible surfaces remain explicitly unknown.

#### References

- [Anthropic: data lifecycle](https://claude.com/docs/claude-tag/concepts/data-lifecycle)

### 5.2 Collect Independent Audit Trails and Cap Autonomous Spend

**Profile Level:** L1 (Crawl)

#### Description

Correlate Tag’s activity with upstream service logs and Enterprise transcripts, and bound the financial impact of autonomous work.

#### Rationale

**Why This Matters:**
- Network events are best-effort and omit git/MCP traffic; absent records do not prove no activity.
- Invoiced Enterprise usage has no upper bound until a spend limit is set.

**Attack Prevented:** Undetected service-account abuse and runaway autonomous consumption.

#### Prerequisites

An authorized Owner or appropriately delegated administrator; approved test channels and non-sensitive fixtures. Plan-specific capabilities are called out below.

#### ClickOps Implementation

Review **Claude Tag → Activity** for scheduled work, memory and hourly network events; centralize dedicated service-account audit logs. On Enterprise with Compliance API enabled, collect authorized session transcripts under restricted access. Configure **Usage → Claude Tag** monthly and per-channel limits appropriate to the pilot; include group DMs and unlinked-user DMs in the billing assessment. Separate personal-seat DM limits from channel limits. Alert on new scopes, grants, channel managers and unusual service activity.

**Automation:** The inventory pack in [1.1](#11-inventory-effective-access-before-enabling-tools) supplies partial evidence only. The current Tag API covers only five scope settings plus explicit bundle attachments, not these connector, identity, retention or other console/upstream-service controls. Use their documented console/service configuration and verify effective inheritance separately. See the automation-surface census in the research ledger; this is a pack coverage boundary, not a claim that vendor APIs do not exist.

#### Validation & Testing

Trace a harmless action from Slack thread to upstream service log and, where available, transcript. Record logging gaps rather than treating the network export as exhaustive. Verify configured limits and alert ownership without deliberately generating billable runaway work.

**Expected result:** Approved operations succeed, disallowed operations fail, and untested or inaccessible surfaces remain explicitly unknown.

#### References

- [Anthropic: audit](https://claude.com/docs/claude-tag/admins/audit)

## Compliance Mappings

These are thematic mappings, not certification evidence.

| Framework | Controls | Application |
|-----------|----------|-------------|
| NIST SP 800-53 | AC-3, AC-6, IA-5, SC-7 | Authorization, least privilege, credentials and egress |
| NIST SP 800-53 | AU-6, SI-4, CM-6 | Audit correlation, monitoring and configuration |
| CIS Controls | 3, 5, 6, 8 | Data protection, identities, access and audit logs |
| SOC 2 | CC6.1, CC6.3, CC7.2 | Logical access and operational monitoring |

## Operational Impact

Strict channel scopes, mandatory review and restricted network access reduce convenience and may break unapproved workflows. Federation reduces stored secrets but does not supply employee device trust or user-delegated authorization. A separate policy enforcement point is needed when upstream authorization must depend on a specific employee or device. Validate beta behavior before broad deployment; API inventory and fixture tests do not establish effective tenant security.

## References

- [Claude Tag documentation index](https://claude.com/docs/claude-tag/overview)
- [Claude Tag Admin API](https://platform.claude.com/docs/en/manage-claude/claude-tag-api)
- [Trust Center resource catalog](https://trust.anthropic.com/resources)
- [Claude Tag source-coverage ledger](/research/claude-tag-source-coverage-2026-11)

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-11 | 0.1.0 | ai-drafted | [SECURITY] Initial Tag-specific boundary controls, current federation guidance and guarded API/SDK inventory/containment packs. No live validation. | OpenAI Codex |
