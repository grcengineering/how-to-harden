---
layout: guide
title: "HumanLayer Hardening Guide"
vendor: "HumanLayer"
slug: "humanlayer"
platform: "Factory"
platform_slug: "factory"
product: "HumanLayer"
tier: "2"
category: "AI/ML Platform"
description: "Harden HumanLayer daemon credentials, host access, workspace setup, unattended sessions, model routing, integration grants and cloud task sharing."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-05"
---

## Overview

HumanLayer is a **product within the [Factory platform](/guides/factory/)** with its own hosted service, desktop app, CLI, daemon, task storage and integrations. Factory’s [November 4 announcement](https://factory.com/news/humanlayer) uses completed-acquisition language and says the hosted service will remain available during a transition supporting export, migration to Factory and self-hosting. It gives no universal shutdown date. HumanLayer’s [November 2 release](https://docs.humanlayer.com/release-notes) says its core desktop, daemon, CLI, web UI, API and plugins are open source and that hosted HumanLayer stays the same. Neither statement proves an organization has migrated. **Factory’s Droid organization policy, SSO and API keys do not configure this control plane.**

**Validation status:** no tenants declared — Tier 0+1 only. Public configuration sources were checked on 2026-11-05. Offline fixtures validate the supplied pack guards and generated fields; no daemon, provider login, integration, API tenant, automation session or self-hosted deployment was exercised. Maturity remains [ai-drafted](https://github.com/grcengineering/how-to-harden/blob/main/VERSIONS.md#maturity-statuses--the-matrix).

### Intended Audience

- Administrators approving local and remote coding-agent hosts
- Security teams reviewing integration identities and synced task data
- Platform teams running unattended HumanLayer sessions

### How to Use This Guide

- **L1 (Crawl):** Scope host identities and integration access.
- **L2 (Walk):** Review workspace execution, unattended approvals, model destinations and cloud sharing.
- Apply the downstream coding agent’s own [Claude Code](/guides/claude-code/) or OpenAI controls too; HumanLayer does not proxy model calls.

### Scope

Eight controls cover the documented HumanLayer app/daemon, native configuration and integrations. General host hardening, arbitrary repository scripts and self-hosted database/orchestrator configuration are outside scope. Protecting HumanLayer’s own refresh tokens, host identity and copied agent settings is in scope. The [family source ledger](/research/factory-source-coverage/) retains unresolved hosted lifecycle/export procedures, admin SSO/RBAC/API contracts, native credential-at-rest enforcement and automation availability. These gaps do not justify guessed configuration or an inherited Factory policy claim.

## Table of Contents

1. [Identity and Host Access](#1-identity-and-host-access)
2. [Workspace and Unattended Execution](#2-workspace-and-unattended-execution)
3. [Destinations and Integrations](#3-destinations-and-integrations)
4. [Task Data and Sharing](#4-task-data-and-sharing)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

## 1. Identity and Host Access

### 1.1 Protect Daemon Credentials and Retire Stored Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | IA-5, AC-6 |

#### Description

Treat daemon authentication state as credentials for remote coding-agent access. Choose persistent login or short-lived launch authentication deliberately, preserve the required host identity for resume, and remove obsolete login state through the supported logout flow.

#### Rationale

**Why This Matters:**

- A remote daemon operates with the files and network access of its OS user.
- A persistent login includes a refresh token and survives daemon restarts; an ephemeral launch token has different persistence behavior.

**Attack Prevented:** Retained remote execution authority through copied authentication volumes, stale hosts or reused daemon identities.

#### Prerequisites

The daemon account owner, an already installed approved HumanLayer CLI and an authorized remote host. Do not generate a token or log in solely to run these packs.

#### ClickOps Implementation

1. Review the intended host in **Settings → Daemons/Hosts**; documentation uses Daemons for launch-token generation and Hosts for the current desktop host list. Choose a restricted OS account whose accessible files/network match the approved work.
2. For persistent production login, protect `~/.humanlayer/riptide/`, which holds the saved session including refresh token. Beta and production use separate state. `HUMANLAYER_RIPTIDE_HOME` relocates that credential home, but `host_id` remains under `$HOME/.humanlayer/riptide/host_id`; persist both when resumability is required.
3. For temporary launch-token use, review the UI-generated short-lived token and pass it only through the documented launch flow. Exchanged process credentials are not saved for the next launch. A supervised service restart needs persistent login or a fresh launch token. Treat mounted authentication volumes as credentials.
4. Use `humanlayer logout` to remove obsolete persistent login, and separately stop the daemon and reconcile supervisors. Logout/file removal is not documented as deleting historical task artifacts or revoking every independent provider credential.
5. Review Claude’s local resume history under `~/.claude` separately from HumanLayer’s Codex persistence. No enforceable OS-keystore-only or encryption-at-rest switch was verified; do not describe ordinary file persistence as hardware-backed protection.

Source: [Daemon authentication and persistence](https://docs.humanlayer.com/explanation/remote-daemons), checked 2026-11-05. Source: [Remote daemon setup](https://docs.humanlayer.com/guide/remote-daemons), checked 2026-11-05.

#### Code Implementation

The CLI pack defaults to a dry run and requires `HTH_APPLY=1` before invoking the documented production `humanlayer logout`. It creates no credential and does not delete guessed state files. Review beta sessions separately.

{% include pack-code.html vendor="humanlayer" section="1.1" %}

#### Validation & Testing

- In a disposable authorized host, verify which login/host identity survives restart, and that the chosen teardown removes the intended persistent login. Test only with non-production credentials.
- Confirm the daemon process and any supervisor have stopped; a UI preference or logout alone is not proof that every separately started daemon is offline.

#### Monitoring & Maintenance

Review after client, integration and role changes and at least quarterly. Keep private evidence of the identity, client version, effective scope and result; do not retain credential values in the report.

#### Operational Impact

Logging out can prevent supervised daemons from reconnecting. Loss of host identity can break resume. Keep an approved reauthentication/recovery process and never publish credential state.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | IA-5, AC-6 | Supports the access, configuration or information-flow objective described above; no certification claim. |

---

### 1.2 Restrict Local Daemon Use and Control Host Updates

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-6, CM-8, SI-2 |

#### Description

Where work belongs on approved remote hosts, turn off the desktop app’s local daemon and verify the actual process state. Pin updates only for managed images with an explicit security-update process, and distinguish desktop-managed daemons from separately launched CLI daemons.

#### Rationale

**Why This Matters:**

- The local daemon exposes the desktop user’s reachable files and network to agent sessions.
- An update or service supervisor can change or restart the executable independently of a desktop preference.

**Attack Prevented:** Unintended local execution and unreviewed daemon changes on credential-bearing hosts.

#### Prerequisites

The account or organization administrator, a reviewed workflow and a disposable pilot environment.

#### ClickOps Implementation

1. In desktop **Settings → Hosts → Advanced**, switch **Local daemon** off and confirm **Stop daemon**. This stops daemons started by that desktop app, including prior organizations; it does not stop separately launched CLI daemons or other apps.
2. Verify the stop completed. A failed stop can leave the switch off while a process remains running. Active local sessions are interrupted and are not migrated; task/history data remains.
3. Confirm an approved remote host is reachable before launch. Offline selected hosts can queue work. The local-daemon preference persists for that desktop, not every device on the account.
4. For a pinned remote image, use documented `--no-self-update` or `HUMANLAYER_DISABLE_SELF_UPDATE=1` in the daemon’s deployment environment. Match the app/CLI version and update deliberately; the UI Update action will no longer update a disabled host. Do not disable updates without an owner and cadence.

Source: [Use remote hosts only](https://docs.humanlayer.com/guide/local-daemon), checked 2026-11-05. Source: [Remote daemon setup](https://docs.humanlayer.com/guide/remote-daemons), checked 2026-11-05.

**Automation:** The local-daemon switch is a documented desktop preference; a public settings writer was not verified. Remote self-update flags are native CLI/environment settings, not an organization-wide remote-host allowlist. No pack launches a daemon as a verification step. ([Local daemon](https://docs.humanlayer.com/guide/local-daemon), [remote setup](https://docs.humanlayer.com/guide/remote-daemons), checked 2026-11-05.)

#### Validation & Testing

- Verify new sessions target the approved remote host and no desktop-started local daemon is still running. Inventory separate CLI/service launches independently.
- After an approved update, confirm host version and reconnect behavior. A successful UI toggle does not prove process termination.

#### Monitoring & Maintenance

Review after client, integration and role changes and at least quarterly. Keep private evidence of the identity, client version, effective scope and result; do not retain credential values in the report.

#### Operational Impact

Stopping interrupts active sessions and can queue work if no approved host is online. Re-enabling the local daemon restores local execution authority and requires another host-access review.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-6, CM-8, SI-2 | Supports the access, configuration or information-flow objective described above; no certification claim. |

---

## 2. Workspace and Unattended Execution

### 2.1 Review Workspace Setup and Default Secret Copies

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | CM-5, AC-6 |

#### Description

Review HumanLayer workspace configuration as executable code and credential-copy policy. Use a trusted source reference and block the first session until required setup completes. Keep the source checkout free of secrets that the product copies by default.

#### Rationale

**Why This Matters:**

- Workspace setup runs shell commands after copying local files into the new worktree.
- Default copy patterns include environment files and local agent settings, and user overrides can broaden the result.

**Attack Prevented:** Secret propagation and code execution through untrusted worktree setup or local configuration.

#### Prerequisites

The account or organization administrator, a reviewed workflow and a disposable pilot environment.

#### ClickOps Implementation

1. Review `.humanlayer/workspace.json` and uncommitted `.humanlayer/workspace.local.json` for every repository, including multi-repository `repos` paths. The reference uses strict JSON; local sparse overrides win and are not an organization policy boundary. No native admin-console enforcement path is documented.
2. Inspect every `setupCommand` and repository command: they run through `sh -c` after copying. Choose a reviewed `sourceRef` such as an approved upstream branch or exact commit and enable `setupBlocksFirstSession` where setup must finish before agent access. The default source reference is HEAD and setup blocking defaults false.
3. Account for the built-in copied patterns: `.env`, `.env.local`, `.env.development.local`, `.claude/settings.local.json`, `.humanlayer/workspace.json` and `.humanlayer/workspace.local.json`. Shared/local `copyGlobs` append and deduplicate with defaults; an empty array does not remove them. Use a clean source checkout without those secret-bearing files rather than claiming `copyGlobs: []` disables copying.
4. Review the resulting workspace before starting a session. A `disabled` flag or local override is a user preference, not an enforced allowlist. Protect shared configuration through repository review and scope the daemon’s accessible source directories.

Source: [Workspace configuration reference](https://docs.humanlayer.com/reference/workspace-config), checked 2026-11-05.

#### Code Implementation

The generator requires a reviewed source reference and emits strict JSON with `setupBlocksFirstSession: true`. It adds no setup shell, repositories or copy patterns. It does not remove the documented default credential copies, validate the repository’s trust, or install a policy.

{% include pack-code.html vendor="humanlayer" section="2.1" %}

#### Validation & Testing

- Generate into a review buffer and verify the effective merged JSON, local overrides, setup outcome and copied files using synthetic non-secret fixtures.
- Confirm setup failure blocks the first session when configured; inspect all default copied files and multi-repository paths.

#### Monitoring & Maintenance

Review after client, integration and role changes and at least quarterly. Keep private evidence of the identity, client version, effective scope and result; do not retain credential values in the report.

#### Operational Impact

Blocking setup can delay or prevent sessions. Changing source reference changes the worktree base. Keep the prior reviewed configuration and avoid real secrets in fixture checkouts.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | CM-5, AC-6 | Supports the access, configuration or information-flow objective described above; no certification claim. |

---

### 2.2 Bound Approval-Free Automation Sessions

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-6, IA-5, SI-10 |

#### Description

Run HumanLayer automation sessions only in isolated, narrowly credentialed jobs with reviewed input and a bounded follow-up lifetime. The documented automation daemon bypasses coding-agent approval prompts; interactive workflow review does not restore them.

#### Rationale

**Why This Matters:**

- A personal access token authorizes Cloud-visible automated work and must not be exposed to untrusted code.
- The default inactivity shutdown window is extended by subsequent Cloud interaction.

**Attack Prevented:** Unattended credential abuse, prompt-driven writes and prolonged agent authority after a job’s initial result.

#### Prerequisites

Confirmed feature entitlement, an existing reviewed PAT with expiry, an isolated job and the actual provider’s least-privileged credentials. Release history labels the initial GitHub Actions feature experimental; the current guide gives no universal GA/plan contract.

#### ClickOps Implementation

1. Review the documented **Account → Personal access tokens** expiry and owner for the job’s existing PAT. Store it in the CI secret manager; the documented `--pat` argument can be visible to the process environment/tooling, so protect job/process/log access and never echo it. Do not assume an undocumented environment authentication flag exists.
2. Inspect the job’s checkout and full privileges before `humanlayer automation run`. It does not clone a repository or apply the desktop workspace setup. Treat incoming issue/PR/prompt text as untrusted and keep credential-bearing follow-up separate from untrusted build steps.
3. Review the Cloud task/session audience and follow-up authority. The default inactivity timeout is two minutes and resets on each interaction; use documented `--shutdown-on stop` when no follow-up window is required. This is an automation shutdown condition, not a guarantee that prior artifacts or provider credentials are removed.
4. Review `--ensure-task` versus `--use-task`, the prompt file and metadata output. Keep task/session identifiers and logs private and require independent review before downstream publication. Stop the job and revoke the PAT through its supported account workflow during containment.

Source: [Run sessions in automations](https://docs.humanlayer.com/guide/automation-sessions), checked 2026-11-05. Source: [Release history](https://docs.humanlayer.com/release-notes), checked 2026-11-05.

**Automation:** The official CLI is the execution surface, but no pack starts an approval-free session or creates a PAT as a safety check. The source documents execution flags, not a no-execution permission validator; automatic policy proof remains unverified. ([Automation sessions](https://docs.humanlayer.com/guide/automation-sessions), checked 2026-11-05.)

#### Validation & Testing

- In an authorized isolated test job, use harmless input and short-lived test credentials to verify shutdown, Cloud follow-up audience and effective repository permissions.
- Record whether approval prompts are bypassed and whether a follow-up resets inactivity. Do not label a timeout as credential revocation.

#### Monitoring & Maintenance

Review after client, integration and role changes and at least quarterly. Keep private evidence of the identity, client version, effective scope and result; do not retain credential values in the report.

#### Operational Impact

Immediate shutdown removes interactive follow-up capability. Jobs must persist only reviewed results, clean their own isolated runtime and separately handle Cloud history and token lifecycle.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-6, IA-5, SI-10 | Supports the access, configuration or information-flow objective described above; no certification claim. |

---

## 3. Destinations and Integrations

### 3.1 Approve Model Routing on Every Daemon Host

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-4, IA-5 |

#### Description

Configure the approved model gateway on the daemon host that runs the coding agent, then verify actual egress. HumanLayer does not proxy model calls, so a hosted-service setting or Factory model policy does not prove the destination of Claude Code or Codex traffic.

#### Rationale

**Why This Matters:**

- The coding agent inherits the daemon’s environment and can call its endpoint directly.
- Changing the desktop machine’s environment does not configure a different remote daemon host.

**Attack Prevented:** Repository context transfer to an unapproved model endpoint and provider-key exposure on execution hosts.

#### Prerequisites

The account or organization administrator, a reviewed workflow and a disposable pilot environment.

#### ClickOps Implementation

1. Review routing on the actual local/remote host. Claude Code uses its documented `ANTHROPIC_BASE_URL` and authentication settings, including `~/.claude/settings.json`; daemon environment values take precedence over HumanLayer defaults. Apply the upstream agent’s own policy too.
2. For Codex’s HumanLayer integration, use the documented `CODELAYER_CODEX_BASE_URL` and `CODELAYER_CODEX_API_KEY` gateway configuration. HTTPS is required except for loopback; a private-network HTTP address is not automatically exempt. Custom endpoint setup skips `humanlayer agents auth codex login`.
3. Review HTTP(S)_PROXY and NO_PROXY routing, separately approving exclusions. The source says the daemon and Claude Code do not support SOCKS proxies. Restart the daemon after changes; fully quit/reopen desktop when changing its inherited environment.
4. Run a harmless new session for every enabled provider and verify the gateway’s requests. Provider credentials, model choices, telemetry and session storage remain separate boundaries; the generator below configures only the documented Codex endpoint variables.

Source: [LLM gateway setup](https://docs.humanlayer.com/guide/llm-gateways), checked 2026-11-05.

#### Code Implementation

The config generator requires a reviewed HTTPS gateway and emits a shell environment fragment with an unresolved secret-manager variable. It does not read a token, authenticate Codex, launch the daemon or claim an endpoint allowlist.

{% include pack-code.html vendor="humanlayer" section="3.1" %}

#### Validation & Testing

- Verify the generated fragment contains no credential value and accepts only the reviewed HTTPS URL.
- After an authorized deployment/restart, confirm each enabled provider reaches the expected gateway and investigate any direct-provider egress. Offline URL validation alone proves no routing behavior.

#### Monitoring & Maintenance

Review after client, integration and role changes and at least quarterly. Keep private evidence of the identity, client version, effective scope and result; do not retain credential values in the report.

#### Operational Impact

A wrong endpoint or inherited credential breaks sessions. Retain a tested approved route; reverting to direct provider access requires the data owner’s approval.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-4, IA-5 | Supports the access, configuration or information-flow objective described above; no certification claim. |

---

### 3.2 Scope GitHub Linear and Jira Integration Grants

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-3, AC-6, AC-21 |

#### Description

Approve each integration’s source scope, write actions and artifact destinations. HumanLayer can import issue contents into tasks, update source systems and link Cloud artifacts back to issues. Disconnecting and disabling task creation have different effects.

#### Rationale

**Why This Matters:**

- Read/write repository and issue access can expose private content and modify downstream state.
- Workflow automation and artifact links can change external systems after the initial task import.

**Attack Prevented:** Unreviewed repository access, issue-data disclosure and unauthorized workflow or artifact updates.

#### Prerequisites

A HumanLayer organization admin and downstream installation/OAuth authority for the intended GitHub account, Linear workspace or Jira Cloud site.

#### ClickOps Implementation

1. Open browser **Settings → Integrations → GitHub** and review every installation. Prefer **Only select repositories**. The documented app permissions are Contents read/write, Issues read/write, Pull requests read/write and Metadata read. Use **Manage** in GitHub and **Refresh** in HumanLayer to reconcile scope; suspensions must be restored in GitHub.
2. Review source-issue content, comments and images imported into `ticket.md` and task artifacts. GitHub artifact links require Issues write; a failed source comment does not block saving the Cloud artifact. Review task access as well as repository selection.
3. In **Settings → Integrations**, inspect the authorized Linear workspace and Jira Cloud site. The **Enable Linear Integration** / **Enable Jira Integration** switches can stop task creation while retaining OAuth. For revocation use the documented Connected-badge **Disconnect?** action and verify the downstream grant too. Exact OAuth scopes/revocation latency are not established by these setup pages.
4. For Linear RPI auto-advance, inspect each team’s workflow states and which actions move an issue into progress/review. The HumanLayer companion `linear` CLI can inspect and mutate states. Always preview writes; `--remove-other-columns` archives other started states and `--destroy` archives the built-in RPI set. Do not use those flags during inventory.
5. During offboarding, disconnect each installation and remove downstream authorization. A failed GitHub disconnect keeps the local connection for retry; verify success rather than treating the click as completion. Retained tasks/artifacts require a separate review.

Source: [GitHub setup](https://docs.humanlayer.com/guide/github-integration), checked 2026-11-05. Source: [Linear setup and companion CLI](https://docs.humanlayer.com/guide/linear-integration), checked 2026-11-05. Source: [Jira setup](https://docs.humanlayer.com/guide/jira-integration), checked 2026-11-05.

#### Code Implementation

The first-party HumanLayer Linear companion pack collects one explicitly named team’s workflow states as JSON. It does not create/archive columns, change issue status or prove the integration’s OAuth scope. GitHub/Jira connection configuration remains in their documented consent flows.

{% include pack-code.html vendor="humanlayer" section="3.2" %}

#### Validation & Testing

- Compare selected GitHub repositories, downstream consent grants and Linear team states with the approved inventory. Test one harmless permitted/denied source in a disposable tenant.
- Confirm disabling task creation differs from disconnecting OAuth, and that a failed disconnect is retried and verified. Inspect retained artifact links separately.

#### Monitoring & Maintenance

Review after client, integration and role changes and at least quarterly. Keep private evidence of the identity, client version, effective scope and result; do not retain credential values in the report.

#### Operational Impact

Revocation or state changes can stop task imports and workflow status updates. Preserve the approved workflow mapping and avoid destructive companion CLI flags.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-3, AC-6, AC-21 | Supports the access, configuration or information-flow objective described above; no certification claim. |

---

### 3.3 Restrict Slack Notification Destinations and Events

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-4, AC-6 |

#### Description

Limit HumanLayer’s Slack destinations to approved channels, events and task owners. This integration delivers task updates; do not treat it as Factory’s inbound Slack delegation app or assume the same scopes and execution identity.

#### Rationale

**Why This Matters:**

- Task updates and artifact links can disclose work to a broader Slack audience.
- Private-channel membership and destination filters are separate from task access inside HumanLayer.

**Attack Prevented:** Sensitive task metadata or artifact disclosure through an overbroad notification destination.

#### Prerequisites

The account or organization administrator, a reviewed workflow and a disposable pilot environment.

#### ClickOps Implementation

1. As a HumanLayer organization admin, open **Settings → Integrations → Slack** and review the connected workspace before consent. The setup page does not enumerate exact OAuth scopes; inspect current consent rather than copying Factory app scopes.
2. Choose only approved notification channels and event/owner filters for each destination. Invite the app to a private channel where required; review its membership and recipient audience when a channel becomes public or changes membership.
3. Use a harmless event to inspect the actual notification and artifact-link audience. A message link does not itself prove that task content is private or public.
4. Disable/remove unneeded destinations and use **Disconnect** when the workspace is retired. Reconcile the downstream app grant and messages already posted; connection removal is not a deletion guarantee.

Source: [Slack integration](https://docs.humanlayer.com/guide/slack-integration), checked 2026-11-05.

**Automation:** Configuration uses the documented admin UI. A supported destination-management API/CLI, exact OAuth scope list, event-signature/replay contract or stable audit schema was not verified. No inbound-execution or HMAC setting is invented. ([Slack setup](https://docs.humanlayer.com/guide/slack-integration), checked 2026-11-05.)

#### Validation & Testing

- Verify one approved owner/event reaches only the selected test destination and an excluded event does not. Inspect the task/artifact link as an authorized and unauthorized viewer.
- Verify disconnection prevents new notifications and review retained Slack messages separately.

#### Monitoring & Maintenance

Review after client, integration and role changes and at least quarterly. Keep private evidence of the identity, client version, effective scope and result; do not retain credential values in the report.

#### Operational Impact

Narrow filters can suppress operational updates. Keep the approved destination list and a documented incident notification path.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-4, AC-6 | Supports the access, configuration or information-flow objective described above; no certification claim. |

---

## 4. Task Data and Sharing

### 4.1 Review Cloud Task Sharing and Synced Artifacts

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-3, AC-4, SI-12 |

#### Description

Approve task access and files placed in the task directory before agents read or update them. HumanLayer shares related sessions and artifacts at the task level and syncs supported agent file operations to Cloud; local execution is not a local-only data guarantee.

#### Rationale

**Why This Matters:**

- People with task edit access can add sessions and change files consumed by later agents.
- Text and binary artifacts can persist remotely and move to another connected workstation.

**Attack Prevented:** Unauthorized task disclosure, unreviewed synced instructions and cross-host propagation of sensitive files.

#### Prerequisites

The account or organization administrator, a reviewed workflow and a disposable pilot environment.

#### ClickOps Implementation

1. Review the task’s sharing/access in HumanLayer before adding teammates. The conceptual guide documents task-level view/edit behavior, but this run did not verify an exact universal permission-picker path, default audience or admin-enforced sharing policy. Resolve those in the deployed edition before admitting sensitive work.
2. Inspect `.humanlayer/tasks/<task-slug>/` and its linked workstation storage. Supported agent Read/Write/Edit/MultiEdit/apply_patch operations trigger sync; another program merely placing a file there is not a dependable upload or exclusion mechanism.
3. Treat Markdown, text, JSON/JSONL and uploaded binary artifacts as Cloud data. The text API’s 10 MB per-file limit is not a DLP boundary. A connected host downloads the task’s Cloud files and receives changes while sync is active.
4. Review comments, shared links and outbound source-issue/Slack links as additional audiences. Obtain the actual export/deletion/retention and migration procedure from the hosted-service owner before decommissioning; the acquisition announcement gives a transition commitment, not a verified retention or shutdown contract.

Source: [Task sharing and sync model](https://docs.humanlayer.com/explanation/tasks), checked 2026-11-05. [Factory transition announcement](https://factory.com/news/humanlayer), checked 2026-11-05.

**Automation:** Task sync is documented, but a complete hosted task-sharing/retention administration API or enforced local-only switch was not verified. No fabricated ACL/retention configuration is supplied. ([Task model](https://docs.humanlayer.com/explanation/tasks), checked 2026-11-05.)

#### Validation & Testing

- With harmless synthetic text and binary artifacts, verify intended sync, recipient access and a second host’s behavior in an authorized test.
- Record the actual default audience, supported revocation/deletion outcome and exported copies separately. Unknown retention or export behavior remains a gap.

#### Monitoring & Maintenance

Review after client, integration and role changes and at least quarterly. Keep private evidence of the identity, client version, effective scope and result; do not retain credential values in the report.

#### Operational Impact

Restricting task access can interrupt collaborative follow-up. Removing a connection or daemon does not prove Cloud artifacts or downloaded copies were deleted.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-3, AC-4, SI-12 | Supports the access, configuration or information-flow objective described above; no certification claim. |

---

## 5. Compliance Quick Reference

These mappings support an organization’s assessment; they are not a HumanLayer benchmark or certification. This refresh did not verify product-specific CIS, DISA, CISA SCuBA, NSA or ACSC baseline coverage for HumanLayer; each remains a source gap rather than an asserted absence. No third-party incident claim originates a control.

| Objective | Controls | NIST SP 800-53 Rev. 5 families |
|-----------|----------|-----------------------------|
| Host and credential access | 1.1–1.2 | AC, IA, CM, SI |
| Trusted workspace and unattended execution | 2.1–2.2 | AC, CM, IA, SI |
| Routing and integration scope | 3.1–3.3 | AC, IA |
| Task sharing and retention | 4.1 | AC, SI |

## Appendix A: Availability and Automation

Eight authored controls; four have packs across CLI and native configuration. This measures pack coverage, not discovery completeness. CLI1.1 is a guarded logout writer; CLI3.2 is a Linear workflow-state read; config2.1 and3.1 emit candidates without deployment. HumanLayer’s main CLI and its Linear companion have separate contracts and inventory rows.

| Surface | Evidence and read/write decision |
|---------|----------------------------------|
| Terraform resources/data sources | Unverified. No provider catalog was established by the current official docs index; registry verification remains missing. No infrastructure-provider substitute. |
| REST/GraphQL | The core API is now open source per release notes, but a supported hosted administration endpoint/schema was not established by the fetched docs. No guessed hosted ACL or retention writer/read. |
| First-party CLI/daemon | Available documented `humanlayer` login/logout/daemon/automation commands and `@humanlayer/linear-cli` workflow-state commands. Automation feature entitlement/GA remains unverified; it is not executed here. |
| Official SDK | A current hosted administration SDK contract was not verified. Historical approval-SDK branding is not evidence for this daemon/task product’s controls. |
| Native config/system policy | Available strict workspace JSON, sparse local overrides and daemon/provider environment settings. No org-enforced MDM policy or keystore-only switch verified. Generators are candidates, not enforcement. |
| SIEM | Hosted task activity and source-system updates are documented, but no stable general audit export/schema was verified. No SIEM table or detection is invented. |

See the [HumanLayer pack README](https://github.com/grcengineering/how-to-harden/blob/main/packs/humanlayer/README.md) and [source coverage ledger](/research/factory-source-coverage/) for source status, implementation limits and offline validation. Hosted continuity and open-source availability do not establish a tested migration or supported self-host configuration.

## Appendix B: References

- [Remote daemon model](https://docs.humanlayer.com/explanation/remote-daemons) and [setup](https://docs.humanlayer.com/guide/remote-daemons)
- [Local daemon](https://docs.humanlayer.com/guide/local-daemon) and [automation sessions](https://docs.humanlayer.com/guide/automation-sessions)
- [Workspace reference](https://docs.humanlayer.com/reference/workspace-config) and [model gateways](https://docs.humanlayer.com/guide/llm-gateways)
- [GitHub](https://docs.humanlayer.com/guide/github-integration), [Linear](https://docs.humanlayer.com/guide/linear-integration), [Jira](https://docs.humanlayer.com/guide/jira-integration) and [Slack](https://docs.humanlayer.com/guide/slack-integration)
- [Task sharing/sync](https://docs.humanlayer.com/explanation/tasks), [release history](https://docs.humanlayer.com/release-notes) and [Factory announcement](https://factory.com/news/humanlayer)

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-05 | 0.1.0 | ai-drafted | Initial eight-control source-backed guide for the separate HumanLayer plane; guarded CLI and configuration packs; offline validation only. | Codex (GPT-6) |

## Contributing

Report corrections through [GitHub issues](https://github.com/grcengineering/how-to-harden/issues), including product edition, client version, primary source and validation scope. Follow the [contribution guidelines](/contributing/).
