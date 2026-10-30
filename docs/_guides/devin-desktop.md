---
layout: guide
title: "Devin Desktop Hardening Guide"
vendor: "Devin Desktop"
slug: "devin-desktop"
platform: "Cognition"
platform_slug: "cognition"
product: "Devin Desktop"
tier: "2"
category: "AI/ML Platform"
description: "Harden Devin Desktop (formerly Windsurf): distinguish Cascade and Devin Local, enforce editor policies, restrict extensions and integrations, protect source context, and verify managed-device settings."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-10-30"
---

## Overview

This is a **product guide within the [Cognition platform](/guides/devin/)**. Cognition introduced Devin Desktop on June 2, 2026 as the successor to Windsurf; this is the Windsurf product lineage, not a separate product originally created by Cognition ([Desktop announcement](https://cognition.com/blog/introducing-devin-desktop)). Cognition announced a signed agreement to acquire Windsurf on July 14, 2025 ([acquisition announcement](https://cognition.com/blog/windsurf)); that date is not asserted here as a closing date. Current Desktop installations retain some Windsurf-named configuration paths. Do not rename those paths speculatively.

An editor with local agents can reach source code, developer credentials, extensions, terminals, and connected services. Harden the workstation and each agent, not merely its cloud account. Organization identity and repository access are covered in the [Devin common-controls guide](/guides/devin/). Legacy Windsurf identity administration must also be checked against the [Desktop administrator guide](https://docs.devin.ai/desktop/guide-for-admins); cloud-account controls do not automatically prove legacy-account enforcement.

> **Two agents, different controls.** New tabs use Devin Local where enabled; Enterprise can disable this agent, and Cascade remains a legacy agent. Cascade autonomy levels, command lists, and hooks do **not** configure Devin Local. Apply the [Devin CLI guide](/guides/devin-cli/) to Local permissions, sandboxing, MCP, and lifecycle hooks. Third-party ACP agents require their own security review. ([Devin Local](https://docs.devin.ai/desktop/devin-local))

### Intended Audience

- Endpoint and developer-platform administrators
- Security engineers approving local coding agents
- Repository owners protecting source code and credentials

### How to Use This Guide

- **L1 (Crawl):** Start with approvals, updates, and source exclusions.
- **L2 (Walk):** Add managed extension, integration, telemetry, and sharing restrictions.
- **L3 (Run):** Disable Cascade shell tools when the workflow does not require them.
- Pilot changes on an enrolled test device; preserve the prior managed baseline and an administrator recovery path.

### Scope

Current Devin Desktop on Windows, macOS, and Linux; Teams/Enterprise features are labeled individually. This guide does not cover air-gapped/FedRAMP deployments, third-party agents, or assert that editor ignore rules stop shell or MCP access. No live tenant or client was available: configuration examples and offline tests are not live-product validation.

**Admin entry point:** **Settings → Enterprise → Devin Desktop** in the Devin app, or **Team Settings** at the legacy Windsurf dashboard. The same team configuration is exposed through both. Team changes require the Desktop-admin permission; enterprise settings can have child-organization overrides. Inspect both levels before declaring enforcement. ([Admin controls](https://docs.devin.ai/desktop/controls))

---

## Table of Contents

1. [Agent Execution Boundaries](#1-agent-execution-boundaries)
2. [Editor and Extension Supply Chain](#2-editor-and-extension-supply-chain)
3. [External Integrations](#3-external-integrations)
4. [Data Handling](#4-data-handling)
5. [Verification and Maintenance](#5-verification-and-maintenance)
6. [Integration Risk Reference](#6-integration-risk-reference)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Agent Execution Boundaries

### 1.1 Require Approval for Cascade Commands

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Cap Cascade at the non-autonomous execution level. This preserves a human checkpoint before shell commands rather than asking the model to decide which commands are safe.

#### Rationale

**Why This Matters:**
- A shell command can act with the developer’s account privileges.
- Broad prefix allowlists authorize more than the single command an administrator intended.

**Attack Prevented:** Unattended command execution induced by untrusted repository content.

#### Prerequisites

Teams or Enterprise administrator; a test member using Cascade.

#### ClickOps Implementation

1. Open the Desktop admin entry point and set **Maximum autonomy level** to **No auto-approvals**. The terminal documentation calls the corresponding level **Disabled**; verify the labels in your deployed release.
2. In the editor’s bottom-right **Devin Settings**, select **Disabled** for Cascade.
3. Review **Team Settings → Terminal Commands → Manage Lists**. Remove broad allowlist entries; a denylist requires approval, it does not prohibit execution.

**Source:** [Official configuration documentation](https://docs.devin.ai/desktop/terminal) (checked 2026-10-29).

**Automation:** ClickOps only for this team setting — no documented write interface was identified in the [complete Desktop admin controls reference](https://docs.devin.ai/desktop/controls) and [admin API inventory](https://docs.devin.ai/desktop/guide-for-admins) (2026-10-29). Do not substitute an internal dashboard endpoint.

#### Validation & Testing

1. Ask Cascade to run a harmless command in a test workspace; it must wait for approval. Cancel it.
2. Confirm the member cannot select a more autonomous level; repeat separately for every permitted agent.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-3 | Supporting implementation, not proof of compliance |

---

### 1.2 Restrict Cascade to the Workspace

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-6 |

#### Description

Enable the workspace restriction for the legacy Cascade agent. Keep unrelated repositories, production credentials, and personal files outside the open workspace.

#### Rationale

**Why This Matters:**
- Opening a home directory gives an agent a much larger starting scope than opening one repository.
- A workspace limit narrows accidental cross-project access but is not proof that every subprocess is isolated.

**Attack Prevented:** Unintended agent reads or edits outside the approved project.

#### Prerequisites

Teams or Enterprise; inspect the actual workspace roots, including multi-root workspaces.

#### ClickOps Implementation

1. At the Desktop admin entry point, enable **Restrict Cascade to workspace** under legacy Cascade controls.
2. Open only the approved repository, not the user’s home directory.
3. Apply Devin Local filesystem restrictions and OS sandboxing separately using the [Devin CLI guide](/guides/devin-cli/).

**Source:** [Official configuration documentation](https://docs.devin.ai/desktop/controls) (checked 2026-10-29).

**Automation:** ClickOps only for this team setting — no documented write interface was identified in the [complete Desktop admin controls reference](https://docs.devin.ai/desktop/controls) and [admin API inventory](https://docs.devin.ai/desktop/guide-for-admins) (2026-10-29). Do not substitute an internal dashboard endpoint.

#### Validation & Testing

1. Create a harmless canary outside the workspace and request a direct Cascade file read/edit. Confirm denial without using real secrets.
2. Do not extend this observation to shell, MCP, symlinks, or another agent without a separate test.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-6 | Supporting implementation, not proof of compliance |

---

### 1.3 Block Cascade Shell Execution

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

For a review-only workflow, install a managed Cascade pre-command hook that always returns the documented blocking exit code. Unlike a command denylist, this control rejects the shell action rather than merely requesting approval.

#### Rationale

**Why This Matters:**
- A review workflow may need code navigation but no shell execution.
- A constant denial avoids brittle command-string blacklists and their quoting or interpreter bypasses.

**Attack Prevented:** Cascade shell execution where no shell tool is authorized.

#### Prerequisites

A managed hooks deployment; test device; workflows that can operate without Cascade commands.

#### ClickOps Implementation

1. Review the pack’s **hooks.json** object in an editor. Merge its **pre_run_command** entry with existing hooks; do not replace unrelated hook arrays.
2. Deploy through the Enterprise **Agent hooks** setting, or a protected system hooks file: macOS **/Library/Application Support/Devin/hooks.json**, Linux **/etc/devin/hooks.json**, Windows **C:\ProgramData\Devin\hooks.json**.
3. Keep the system file administrator-owned. Do not trust a repository-writable hook as organizational enforcement.

**Source:** [Official configuration documentation](https://docs.devin.ai/desktop/cascade/hooks) (checked 2026-10-29).

#### Code Implementation

{% include pack-code.html vendor="devin-desktop" section="1.3" %}

#### Validation & Testing

1. In a trusted test workspace, request a harmless Cascade shell command and verify that the hook blocks it.
2. Confirm both OS-specific command fields are present in a mixed fleet. Hooks do not run in Restricted Mode; this is not an OS sandbox and does not govern humans, MCP, Local, or third-party agents.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-3 | Supporting implementation, not proof of compliance |

---

## 2. Editor and Extension Supply Chain

### 2.1 Allow Only Approved Extensions

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | CM-7 |

#### Description

Allow reviewed extension IDs rather than accepting every extension from a publisher. Treat an extension as executable code with developer-level access, not as a cosmetic editor preference.

#### Rationale

**Why This Matters:**
- A compromised extension can access valuable local development data.
- A specific extension-ID inventory makes approval and removal auditable.

**Attack Prevented:** Unreviewed or look-alike extension installation.

#### Prerequisites

Managed device policy support; Enterprise is required for the server-side Extension policy setting.

#### ClickOps Implementation

1. Inventory the extensions genuinely required for the team and record their approved IDs and owners.
2. Generate the pack’s **AllowedExtensions** value, then merge it into the managed policy. It is a JSON-encoded string, not a nested JSON object.
3. On Windows use **Computer Configuration → Administrative Templates → Devin → AllowedExtensions** with the release’s **Devin.admx/Devin.adml**. On macOS edit the release-shipped configuration profile. On Linux use **/etc/vscode/policy.json**.
4. If the Enterprise **Extension policy** team setting is configured, align it with the device baseline: that setting replaces the MDM allowlist for signed-in members.

**Source:** [Official configuration documentation](https://docs.devin.ai/desktop/enterprise-policies) (checked 2026-10-29).

**Important:** Linux uses the same policy path as VS Code. Coordinate with its administrator and merge the shared file; do not overwrite another product’s policy.

#### Code Implementation

{% include pack-code.html vendor="devin-desktop" section="2.1" %}

#### Validation & Testing

1. After restarting the client, verify that an approved extension is available and an unapproved extension cannot be installed.
2. Check the Extensions view for managed-policy indication. Test both signed-in and signed-out device-policy behavior.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | CM-7 | Supporting implementation, not proof of compliance |

---

### 2.2 Pin the Extension Marketplace

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | CM-6 |

#### Description

Point the editor at an organization-approved extension gallery. A controlled gallery complements an allowlist by governing the distribution source and update pipeline.

#### Rationale

**Why This Matters:**
- A permitted extension name is not a complete distribution policy.
- A curated gallery can implement the organization’s release review and retention process.

**Attack Prevented:** Extension retrieval from an unapproved marketplace.

#### Prerequisites

A functioning approved HTTPS gallery service; deployment access to managed device policy.

#### ClickOps Implementation

1. Obtain the actual gallery service endpoint from its administrator; a website homepage is not sufficient.
2. Use the pack to emit **ExtensionGalleryServiceUrl**, then merge it into the existing device policy using the platform mechanism in control 2.1.
3. Restart Devin Desktop and inspect **Extensions**. Device policy takes precedence over the team **Extension marketplace URL** and the member’s own marketplace setting.

**Sources:** [Extension marketplace](https://docs.devin.ai/desktop/advanced) and [managed-policy precedence](https://docs.devin.ai/desktop/controls) (checked 2026-10-29).

#### Code Implementation

{% include pack-code.html vendor="devin-desktop" section="2.2" %}

#### Validation & Testing

1. Confirm the Extensions view names the approved marketplace and shows that it is organizationally managed.
2. Search/install an approved test extension and confirm it comes from the intended gallery; verify a member cannot switch to another source.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | CM-6 | Supporting implementation, not proof of compliance |

---

### 2.3 Keep Client Updates Enabled

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | SI-2 |

#### Description

Keep Devin Desktop on a maintained release through an approved automatic update channel or an explicitly owned managed rollout. Do not turn updates off without a replacement patching process.

#### Rationale

**Why This Matters:**
- Agent and editor behavior changes across releases, including policy enforcement fixes.
- A stale client can retain known defects even when the server policy is correct.

**Attack Prevented:** Exposure to vulnerabilities already fixed in supported releases.

#### Prerequisites

An approved update and rollback process; a pilot group for compatibility testing.

#### ClickOps Implementation

1. Inspect the **UpdateMode** policy shipped with the installed release. For an approved automatic update channel, use **default** via the managed policy in control 2.1.
2. If your organization requires **manual** updates, assign a rollout owner and a time-bounded patch SLA. Do not present manual mode by itself as hardening.
3. Retest the execution, extension, and data controls after upgrades.

**Source:** [Official configuration documentation](https://docs.devin.ai/desktop/controls) (checked 2026-10-29).

#### Code Implementation

{% include pack-code.html vendor="devin-desktop" section="2.3" %}

#### Validation & Testing

1. Confirm the managed setting and installed client version on a pilot device.
2. Demonstrate the chosen update mechanism delivers an approved newer release; a policy-file check alone does not prove patching.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | SI-2 | Supporting implementation, not proof of compliance |

---

## 3. External Integrations

### 3.1 Restrict MCP Servers and Their Configuration

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-6 |

#### Description

Disable MCP when it is unnecessary. Where it is needed, approve the server implementation, launch configuration, credential scope, and tools—not merely a friendly server name.

#### Rationale

**Why This Matters:**
- An MCP server can execute code or access an external system independently of shell approval.
- A name-only allowlist does not bind that name to a trusted executable.

**Attack Prevented:** Unapproved tool servers and over-privileged connected-service access.

#### Prerequisites

Teams/Enterprise administrator; approved server inventory and least-privilege credentials.

#### ClickOps Implementation

1. At the Desktop admin entry point, disable **Allow MCP** unless the team needs it.
2. If enabled, add the approved server to **MCP allowlist** with an exact configuration template. Server IDs are case-sensitive; an empty template accepts any configuration using that ID.
3. Use narrow command/argument patterns and test changes. For Local, also configure registry enforcement rather than assuming that listing registry URLs alone blocks other servers.
4. Review credential permissions at the server. Cascade allowlist matching does not constrain **env** values or **disabledTools**.

**Source:** [Official configuration documentation](https://docs.devin.ai/desktop/cascade/mcp) (checked 2026-10-29).

**Automation:** ClickOps only for this team setting — no documented write interface was identified in the [complete Desktop admin controls reference](https://docs.devin.ai/desktop/controls) and [admin API inventory](https://docs.devin.ai/desktop/guide-for-admins) (2026-10-29). Do not substitute an internal dashboard endpoint.

#### Validation & Testing

1. On a test account, verify a non-allowlisted server and a changed command/argument configuration are blocked.
2. Exercise approved read-only tools with test data, then test denied actions at the backing service. Do not infer tool-level authorization from a server allowlist.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-6 | Supporting implementation, not proof of compliance |

---

### 3.2 Disable Unapproved App Deploys

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Disable Cascade App Deploys unless the team has an approved public-preview workflow. Keep production deployment behind the repository’s established review and CI/CD controls.

#### Rationale

**Why This Matters:**
- A preview can publish application code and data outside the development environment.
- A public URL is a disclosure boundary, even if the application is temporary.

**Attack Prevented:** Accidental publication of private applications or data.

#### Prerequisites

Teams/Enterprise administrator; review any existing preview deployments separately.

#### ClickOps Implementation

1. Open the legacy Windsurf dashboard **Team Settings** and disable **App Deploys** for teams that do not need it. This toggle is documented there, not in every Devin settings surface.
2. For approved use, restrict previews to sanitized projects and require a named owner for each public deployment.
3. Inspect and retire existing previews through their provider; disabling future deployment is not evidence that existing URLs were removed.

**Source:** [Official configuration documentation](https://docs.devin.ai/desktop/cascade/app-deploys) (checked 2026-10-29).

**Automation:** ClickOps only for this team setting — no documented write interface was identified in the [complete Desktop admin controls reference](https://docs.devin.ai/desktop/controls) and [admin API inventory](https://docs.devin.ai/desktop/guide-for-admins) (2026-10-29). Do not substitute an internal dashboard endpoint.

#### Validation & Testing

1. Confirm the App Deploys tool is unavailable to an ordinary Cascade member.
2. Check an existing test preview separately: revocation/deletion must be verified at its provider. Devin Local does not implement this Cascade tool.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-3 | Supporting implementation, not proof of compliance |

---

## 4. Data Handling

### 4.1 Exclude Sensitive Files from Agent Context

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-6 |

#### Description

Add repository-specific exclusions for credentials and private data before opening the project to an agent. Prefer the current .devinignore filename while preserving valid legacy exclusions.

#### Rationale

**Why This Matters:**
- Developer worktrees often contain test credentials and local exports not intended as model input.
- Exclusions reduce incidental exposure but cannot replace secret storage and OS access controls.

**Attack Prevented:** Accidental indexing or direct agent-file access to sensitive repository content.

#### Prerequisites

Repository ownership; a reviewed list of sensitive path classes.

#### ClickOps Implementation

1. Create or edit **.devinignore** at the repository root. Review and merge the pack output rather than replacing an existing file.
2. For an enterprise-wide baseline, the documented global file remains **~/.codeium/.codeiumignore**. Legacy **.windsurfignore** and **.codeiumignore** files are still read.
3. Review exception/negation patterns and keep actual credentials out of the worktree. Apply separate sandbox and MCP permissions for non-file-tool access.

**Source:** [Official configuration documentation](https://docs.devin.ai/desktop/context-awareness/devin-ignore) (checked 2026-10-29).

#### Code Implementation

{% include pack-code.html vendor="devin-desktop" section="4.1" %}

#### Validation & Testing

1. Use harmless canary files matching each required exclusion; confirm they are not indexed and direct agent file access is denied.
2. Test a normal source file remains usable. Do not test with production secrets or interpret the result as a shell/network security boundary.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-6 | Supporting implementation, not proof of compliance |

---

### 4.2 Minimize Editor Telemetry and Feedback

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | CM-6 |

#### Description

Use managed editor settings to disable optional telemetry and feedback entry points where organizational policy requires data minimization. Distinguish editor telemetry from the data required to run an agent.

#### Rationale

**Why This Matters:**
- Optional diagnostic and feedback paths can create additional data flows.
- Clear scope prevents a telemetry switch from being misrepresented as zero retention or offline inference.

**Attack Prevented:** Unnecessary optional telemetry or feedback submissions.

#### Prerequisites

Managed device policy deployment; agreement with support owners on reduced diagnostics.

#### ClickOps Implementation

1. Set **TelemetryLevel** to **off** and **EnableFeedback** to **false** using the installed release’s policy templates.
2. Merge the pack into the existing Linux policy, or transpose the same typed keys into the release-shipped Windows/macOS template.
3. Restart the client and review any troubleshooting impact with the support team.

**Source:** [Official configuration documentation](https://docs.devin.ai/desktop/enterprise-policies) (checked 2026-10-29).

#### Code Implementation

{% include pack-code.html vendor="devin-desktop" section="4.2" %}

#### Validation & Testing

1. Confirm both settings are locked in the client and use control 5.1 to compare the disk baseline.
2. Validate model-provider retention and agent request handling independently; this control makes no claim about those flows.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | CM-6 | Supporting implementation, not proof of compliance |

---

### 4.3 Restrict Conversation and Codemap Sharing

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Disable sharing where no collaboration use case has been approved; otherwise limit it to the team. Review already-shared artifacts as a separate task.

#### Rationale

**Why This Matters:**
- Generated explanations and conversations can reproduce private source details.
- Existing shared artifacts may need explicit cleanup rather than a change to future defaults.

**Attack Prevented:** Unapproved disclosure of code context through shared links.

#### Prerequisites

Teams/Enterprise administrator; an approved internal-sharing policy.

#### ClickOps Implementation

1. At the Desktop admin entry point, open **Sharing**. Turn off **Share conversations** when unnecessary.
2. Set **Share codemaps** to **no sharing**, or **team only** for an approved collaboration need; do not permit public sharing of private-repository context.
3. Review the conversations and Codemaps listed on the Sharing tab and follow up on previously shared content.

**Sources:** [Codemaps](https://docs.devin.ai/desktop/codemaps) and [Sharing admin controls](https://docs.devin.ai/desktop/controls) (checked 2026-10-29).

**Automation:** ClickOps only for this team setting — no documented write interface was identified in the [complete Desktop admin controls reference](https://docs.devin.ai/desktop/controls) and [admin API inventory](https://docs.devin.ai/desktop/guide-for-admins) (2026-10-29). Do not substitute an internal dashboard endpoint.

#### Validation & Testing

1. Verify a normal team member cannot create a prohibited link.
2. If team sharing is allowed, verify an external/nonmember account cannot open a test artifact. Check existing links separately.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-3 | Supporting implementation, not proof of compliance |

---

### 4.4 Allow Only Approved Models

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Constrain model selection to models or providers approved for the repository’s data classification. Reassess retention exceptions and new models before expanding the allowlist.

#### Rationale

**Why This Matters:**
- Model selection can change the external processing path for source context.
- Provider-wide tags can authorize future models without individual approval.

**Attack Prevented:** Unapproved processing of confidential development data.

#### Prerequisites

Teams/Enterprise for model controls. The alpha API requires a Devin service user with **Use Devin Desktop**; replacement also requires **account.windsurf.admin**. Legacy Windsurf service keys are not accepted.

#### ClickOps Implementation

1. Open **Models** in Desktop administration and configure **Allowlisted models**. Prefer reviewed specific models over a broad provider filter.
2. Leave provider data-retention exception toggles disabled unless approved; these are separate from editor telemetry.
3. Test with a normal member and inspect organization/group restrictions.

**Sources:** [Admin controls](https://docs.devin.ai/desktop/controls) and [update API](https://docs.devin.ai/desktop/accounts/api-reference/update-models) (2026-10-29).

#### Code Implementation

The default is an offline plan. A reviewed control-5.2 snapshot, a nonempty desired selection, and explicit **--apply** are required for replacement. **If-Match** rejects stale state without retrying; a credential fingerprint prevents accidentally applying another key’s snapshot. Do not guess model UIDs.

{% include pack-code.html vendor="devin-desktop" section="4.4" %}

#### Validation & Testing

1. Preserve the prior lists before an authorized change; rollback also requires a fresh ETag.
2. Re-read the policy and verify a normal member cannot select a prohibited model. An unexpected **v2alpha** schema or authorization failure is unknown, not secure.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-3 | Supporting access enforcement, not proof of compliance |

---

## 5. Verification and Maintenance

### 5.1 Verify Managed Device Policy

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | CA-7 |

#### Description

Compare the deployed Linux policy against an approved baseline, then verify the effective client settings and account-level overrides. A file that exists is not evidence that the product accepted it.

#### Rationale

**Why This Matters:**
- Malformed policy can leave an intended restriction unapplied.
- A writable policy or a conflicting server override can invalidate a correct-looking local baseline.

**Attack Prevented:** Undetected policy drift or silently ineffective management.

#### Prerequisites

Python 3 for the read-only pack; approved merged JSON baseline; Linux device access. Other platforms require their native MDM/GPO evidence.

#### ClickOps Implementation

1. Restart Devin Desktop and open **File → Preferences → Settings**. Inspect locked/managed indicators for the intended settings.
2. Open the Command Palette and select **Show Window Log**; investigate policy parsing errors.
3. Compare enterprise and child-organization overrides, especially extension allowlists. Record client version, policy revision, scope, and test result without collecting source code or credentials.

**Source:** [Official configuration documentation](https://docs.devin.ai/desktop/enterprise-policies) (checked 2026-10-29).

#### Code Implementation

{% include pack-code.html vendor="devin-desktop" section="5.1" %}

#### Validation & Testing

1. Run the read-only pack with the approved baseline. Exit 0 means the selected disk keys and ownership checks matched; 1 is drift, 2 is unknown/invalid input.
2. A fixture path is only a fixture result. Repeat against the real managed file and combine with runtime tests from controls 2.1–4.2 before claiming enforcement.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | CA-7 | Supporting implementation, not proof of compliance |

---

### 5.2 Audit the Effective Model Allowlist

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | CA-7 |

#### Description

Read the stored model selection and the caller’s effective allowed models before and after changes. An ETag guards concurrency; it is not proof of universal member access.

#### Rationale

**Why This Matters:**
- Stored UID/tag lists and effective availability answer different questions.
- Group restrictions can make the caller’s view differ from another member’s.

**Attack Prevented:** Undetected expansion of model access or stale administrative updates.

#### Prerequisites

Desktop access enabled; a **cog_** service user with **Use Devin Desktop**; curl and Python 3. Listing does not require administrator write permission.

#### ClickOps Implementation

1. Inspect **Models** in Desktop administration.
2. Compare the approved selection with a normal member’s model picker.
3. Investigate differences before changing the policy.

**Source:** [List Models API](https://docs.devin.ai/desktop/accounts/api-reference/list-models) (2026-10-29).

#### Code Implementation

The GET-only report includes stored UIDs/tags, effectively allowed UIDs, ETag, and a one-way credential fingerprint. It omits prices and raw response bodies. Protect snapshots; the key is never printed or placed in curl’s argument list.

{% include pack-code.html vendor="devin-desktop" section="5.2" %}

#### Validation & Testing

1. Compare the report with approved selection. A successful GET alone is not a security pass.
2. Treat authorization failure, redirects, rate limits, missing ETags, or schema drift as unknown. The pack does not expand access to make a check succeed.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | CA-7 | Supporting monitoring, not proof of compliance |

---

## 6. Integration Risk Reference

| Surface | Main boundary | Required companion control |
|---------|---------------|----------------------------|
| Cascade shell | Developer workstation privileges | Approval cap, optional hard-deny hook; do not call denylist a block |
| Devin Local / CLI | Separate permissions and sandbox | [Devin CLI guide](/guides/devin-cli/) |
| MCP | Server code, credentials, and external tools | Approved implementation plus backing-service least privilege |
| Extensions | Local executable code and supply chain | Exact-ID allowlist plus approved gallery |
| ACP agents | Separate vendor/runtime | Review each agent; Desktop policy is not automatically inherited |
| App Deploys / sharing | Public or team-visible artifacts | Disable unused features; separately remove prior artifacts |

### Automation Surface Census

Checked 2026-10-29. Nine of fourteen controls have packs across **config** and **API** surfaces. Device policy and model access are different administrative planes; a check of one does not prove the other.

| Surface | Write/read assessment for this guide |
|---------|-------------------------------------|
| Terraform | Cognition’s provider covers cloud resources, not the Desktop policy keys used here; see the [common-controls guide](/guides/devin/) for that separate plane. |
| REST / GraphQL | [GET/PUT models](https://docs.devin.ai/desktop/accounts/api-reference/api-introduction) provide an alpha read/write surface for model allowlisting; both have packs. No documented REST writes for the other team toggles or GraphQL policy interface were identified. Analytics, usage, and SCIM are separate APIs. |
| First-party CLI | Devin CLI is a coding agent, not a Desktop team-settings administration CLI; its controls live in the [CLI guide](/guides/devin-cli/). |
| SDK | No Desktop security-policy SDK is listed in the [docs index](https://docs.devin.ai/llms.txt); do not invent one. |
| Config | Native device policy, .devinignore, and hooks.json: templates/emitters for enforcement; a separate disk-baseline verification pack. |
| SIEM | Cascade hooks can produce local audit events, but this guide does not invent a standard vendor SIEM table, event schema, or collector. Cloud audit export is separate. |

### Operating and Reversing Changes

- **Before deployment:** preserve and diff the prior managed configuration. Merge fragments; never replace a multi-purpose policy file with one control’s example.
- **Monthly and after upgrades:** test ordinary-user restrictions, compare policy revisions, inspect overrides, and refresh the extension/MCP inventory.
- **Rollback:** revert only the affected keys or hook entry through the same management channel, restart the client, and retest. Do not remove all organization policy to undo one change.
- Disabling autonomy, tools, or extensions can break builds and integrations. Pilot with a representative project. Lower telemetry reduces diagnostic detail; preserve an approved troubleshooting process.

## 7. Compliance Quick Reference

These are implementation relationships to the [NIST SP 800-53 Rev. 5 catalog](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final), not a certification or a substitute for organization-specific assessment. No Devin Desktop-specific benchmark was identified in accessible sources; the DISA index could not be fully inspected. Do not invent product benchmark IDs or claim exhaustive absence.

| NIST control | Supporting controls |
|--------------|---------------------|
| AC-3 — Access Enforcement | 1.1, 1.3, 3.2, 4.3, 4.4 |
| AC-6 — Least Privilege | 1.2, 3.1, 4.1 |
| CM-6 — Configuration Settings | 2.2, 4.2 |
| CM-7 — Least Functionality | 2.1 |
| SI-2 — Flaw Remediation | 2.3 |
| CA-7 — Continuous Monitoring | 5.1, 5.2 |

## Appendix A: Edition and Platform Compatibility

| Control group | Availability / limitation |
|---------------|---------------------------|
| Cascade autonomy, workspace restriction, MCP, App Deploys, sharing | Teams / Enterprise settings; individual controls differ by agent |
| Server-side Extension policy and marketplace | Enterprise |
| Models API | Alpha; Devin service user with Use Devin Desktop; writes also require account.windsurf.admin; general Desktop API inventory is Enterprise |
| Managed device policy | Windows GPO, macOS configuration profile, Linux /etc/vscode/policy.json; use templates shipped with the installed release |
| Cascade hooks | Native hooks configuration; cloud-managed Agent hooks is Enterprise; no execution in Restricted Mode |
| .devinignore | Repository file; global ~/.codeium/.codeiumignore documented for enterprise management |
| Local/CLI sandbox and permissions | Separate agent plane; see the CLI guide for OS and plan limitations |

The pack emitters do not install policy. JSONC examples are reviewed templates: remove comment lines before using them as strict JSON. The Linux verifier does not inspect Windows registry or macOS managed preferences and does not assert effective server policy.

## Appendix B: References

- [Cognition: Introducing Devin Desktop](https://cognition.com/blog/introducing-devin-desktop)
- [Desktop admin controls reference](https://docs.devin.ai/desktop/controls)
- [Enterprise policy deployment](https://docs.devin.ai/desktop/enterprise-policies)
- [Desktop administrator guide](https://docs.devin.ai/desktop/guide-for-admins)
- [Terminal controls](https://docs.devin.ai/desktop/terminal)
- [Devin Local](https://docs.devin.ai/desktop/devin-local)
- [Cascade hooks](https://docs.devin.ai/desktop/cascade/hooks)
- [Cascade MCP configuration](https://docs.devin.ai/desktop/cascade/mcp)
- [App Deploys](https://docs.devin.ai/desktop/cascade/app-deploys)
- [Ignore files](https://docs.devin.ai/desktop/context-awareness/devin-ignore)
- [Extension marketplace](https://docs.devin.ai/desktop/advanced)
- [Codemaps](https://docs.devin.ai/desktop/codemaps)
- [Models API read](https://docs.devin.ai/desktop/accounts/api-reference/list-models) and [write](https://docs.devin.ai/desktop/accounts/api-reference/update-models)

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-10-30 | 0.1.0 | ai-drafted | Initial Desktop guide; agent-specific boundaries, managed policy packs, offline verification, and explicit plan/validation limits | Codex |

## Contributing

Report outdated behavior or propose improvements through [GitHub issues](https://github.com/grcengineering/how-to-harden/issues) and the [contribution guide](/contributing/). Include the client version and affected agent; do not attach credentials or private source code.
