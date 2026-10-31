---
layout: guide
title: "Factory Hardening Guide"
vendor: "Factory"
slug: "factory"
tier: "2"
category: "AI/ML Platform"
description: "Harden Factory and Droid with enterprise identity, managed execution policy, sandboxing, MCP and plugin controls, model governance, data minimization, and audit evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-10-31"
---

## Overview

Factory's Droid can read code, invoke tools, execute commands and connect to other services across the Factory App, CLI, SDK and automated workflows. This guide limits the access and data flows available to that agent and its integrations. Factory is provided by The San Francisco AI Factory, Inc., as identified in its [terms](https://factory.com/legal/terms-individual). This is a standalone Factory guide; marketplace distribution through another vendor does not imply that vendor owns or administers Factory.

**Validation status:** no tenants declared — Tier 0+1 only. The guide was researched against current public documentation; no Factory tenant, credentialed API, live CLI policy, sandbox or IdP was exercised. Maturity remains `ai-drafted` as defined in the [version registry](https://github.com/grcengineering/how-to-harden/blob/main/VERSIONS.md#maturity-statuses--the-matrix).

### Intended Audience

- Enterprise identity and endpoint administrators
- Security engineers governing coding agents and integrations
- Platform teams running Droid in development and CI
- GRC teams collecting configuration and audit evidence

### How to Use This Guide

- **L1 (Crawl):** Govern identity, workload credentials and basic agent safety.
- **L2 (Walk):** Enforce execution and integration boundaries, minimize data exports and collect evidence.
- **L3 (Run):** Add reviewed network-origin restrictions after proving recovery access.

### Scope

Nineteen controls cover the Factory organization and managed Droid runtime. Generic infrastructure hardening, model quality, vulnerability remediation and secret rotation procedures are outside scope. Protect source-control platforms using their own [GitHub](/guides/github/) or [GitLab](/guides/gitlab/) controls as well.

**Policy deployment matters.** Factory distinguishes hard controls from locally overridable session defaults. Apply enforcement fields at organization level through [Enterprise Controls](https://docs.factory.com/enterprise/hierarchical-settings-and-org-control), or through a protected system-managed settings file distributed by endpoint administrators. Its documented locations are `/Library/Application Support/Factory/settings.json` on macOS, `/etc/factory/settings.json` on Linux/WSL, and `C:\\Program Files\\Factory\\settings.json` on Windows. A present valid file takes precedence over remote org settings; an absent or unreadable file falls back to remote settings. A present malformed or schema-invalid file resolves to **empty org policy**, not a deny-all policy. Validate the complete merged file before deployment and confirm effective behavior on every supported client release.

Code Pack configuration files are **fragments**, not complete replacement policies. Merge reviewed fragments into the existing policy, preserve unrelated controls and retain a known-good rollback. Generators print candidate JSON; they do not deploy it. Private inventory files contain identity or policy metadata and belong outside source control.

---

## Table of Contents

1. [Identity & Access Controls](#1-identity--access-controls)
2. [Agent Execution Controls](#2-agent-execution-controls)
3. [Integration & Extension Security](#3-integration--extension-security)
4. [Network & Data Boundaries](#4-network--data-boundaries)
5. [Monitoring & Change Detection](#5-monitoring--change-detection)
6. [Integration Risk Reference](#6-integration-risk-reference)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Identity & Access Controls

### 1.1 Federate Identity through Verified Domains

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Access Control Management (control-family mapping) |
| NIST 800-53 Rev. 5 | IA-2, IA-8 |
| SOC 2 | CC6.1 |

#### Description

Verify corporate email domains and require SAML or OIDC sign-in for covered users through the enterprise identity portal. Apply phishing-resistant MFA and conditional access in the identity provider. Domain claiming, authentication, and provisioning are distinct decisions; external collaborators may use a separate sign-in path.

#### Rationale

**Why This Matters:**

- Central sign-in brings developer access under the corporate authentication policy.
- Verifying subsidiary and alias domains reduces unmanaged accounts outside that policy.

**Attack Prevented:** Account takeover through weaker authentication and unmanaged corporate accounts.

#### Prerequisites

Enterprise identity entitlement, an enterprise root Owner, DNS administration, an IdP administrator, and a tested recovery sign-in path.

#### ClickOps Implementation

1. Open **Admin Console → Security & Identity** and launch the identity portal. Contact Factory for the secure WorkOS setup link if setup has not been enabled.
2. Add each approved domain and publish the exact TXT record supplied by the wizard. Confirm verification before configuring SSO.
3. Complete the provider-specific SAML/OIDC wizard, then require SSO for the intended verified-domain population. Apply MFA and access policy in the IdP; do not assume Factory has a separate MFA switch.
4. Pilot normal and recovery sign-in before expanding enforcement. Review automatic claiming and external-collaborator access.

Source: [Factory configuration documentation](https://docs.factory.com/enterprise/identity-and-access), verified 2026-10-30.

**Automation:** ClickOps only for domain verification and SSO enforcement — the current public Factory administration reference documents no identity-configuration write operation. Use the generated WorkOS setup flow, rather than guessed SAML URLs or SCIM endpoints. ([Public API reference](https://docs.factory.com/api-reference), verified 2026-10-30.)

#### Validation & Testing

1. Confirm a pilot user on each verified domain follows the required IdP flow and receives the intended MFA challenge.
2. Verify the intended policy for non-SSO attempts and external users, and test the independent recovery account.

**Expected result:** The scoped corporate population authenticates under the reviewed IdP policy.

#### Monitoring & Maintenance

Review this control after client upgrades, policy changes and integration changes; include it in the quarterly access/configuration review. Record the tested client version and effective organization/device scope.

#### Operational Impact

Incorrect domain or IdP configuration can prevent sign-in. Keep a working recovery path and restore the previous IdP configuration if the pilot fails.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By control family | Access Control Management; no product-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | IA-2, IA-8 | Supports the access, configuration, information-flow or evidence objective described above. |
| SOC 2 | CC6.1 | Supporting evidence for the relevant logical-access or monitoring criterion; not a certification claim. |

---

### 1.2 Govern Directory Sync Membership and Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Account Management (control-family mapping) |
| NIST 800-53 Rev. 5 | AC-2, AC-6 |
| SOC 2 | CC6.2 |

#### Description

Use SCIM Directory Sync for approved groups and assign the least privileged Factory role in each organization. Reserve enterprise root ownership for administrators who need enterprise-wide control. Choose a primary provisioning model when SSO JIT and Directory Sync coexist.

#### Rationale

**Why This Matters:**

- A removed directory user should not retain coding-agent or repository access.
- A Factory Manager can change security settings and API keys; it is an administrative role.

**Attack Prevented:** Orphaned memberships, excessive administrative access, and unintended access through provisioning conflicts.

#### Prerequisites

Directory Sync setup through the identity portal, an IdP administrator, and an approved role and organization assignment list.

#### ClickOps Implementation

1. Open **Admin Console → Security & Identity → identity portal** and configure Directory Sync using the tenant-specific wizard.
2. Sync only approved groups. Map `owner` to Owner and `admin` or `manager` to Manager; other role slugs resolve to User.
3. Review cross-organization access in **Admin Console → Directory**. Change Directory Sync-managed memberships in the IdP, rather than relying on UI edits.
4. Review each organization's owners and managers. If JIT and SCIM coexist, choose directory-first or SSO-first provisioning as documented and test the join path.

Source: [Factory configuration documentation](https://docs.factory.com/enterprise/identity-and-access), verified 2026-10-30.

#### Code Implementation

The API pack collects paginated organization users. Its documented response does not prove role assignments or SCIM ownership; reconcile the private inventory with Directory and the IdP. Provisioning changes remain in the configured IdP workflow.

{% include pack-code.html vendor="factory" section="1.2" %}

#### Validation & Testing

1. Provision a pilot user, change an approved group, and remove the user in the IdP. Confirm access is deactivated and history is retained.
2. Compare the full membership inventory with approved assignments. Inspect root Owners and local Managers separately in the console.

**Expected result:** Membership tracks the directory and administrative roles match the approved list.

#### Monitoring & Maintenance

Review this control after client upgrades, policy changes and integration changes; include it in the quarterly access/configuration review. Record the tested client version and effective organization/device scope.

#### Operational Impact

SCIM removals soft-deactivate access. Correct the directory assignment to restore legitimate access; do not broaden roles to solve a sync problem.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By control family | Account Management; no product-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AC-2, AC-6 | Supports the access, configuration, information-flow or evidence objective described above. |
| SOC 2 | CC6.2 | Supporting evidence for the relevant logical-access or monitoring criterion; not a certification claim. |

---

### 1.3 Restrict API Key Administration and Use Workload Identities

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Account Management (control-family mapping) |
| NIST 800-53 Rev. 5 | AC-6, IA-5 |
| SOC 2 | CC6.1 |

#### Description

Restrict API key creation to Owners and Managers and use a dedicated service account for each automated workflow. Give temporary workload keys an expiry, store them in a secret manager, and review inactive identities and unbounded credentials. Human administration and workload execution use different credentials.

#### Rationale

**Why This Matters:**

- Personal tokens create unnecessary dependency on a teammate's account.
- Separate workload identities make activity attributable and reduce shared credential exposure.

**Attack Prevented:** Uncontrolled credential creation, long-lived automation access, and shared human credentials in CI.

#### Prerequisites

An Owner or Manager; Business or Enterprise entitlement for general-purpose service accounts. Other plans have a limited Delegations-specific service account.

#### ClickOps Implementation

1. Open organization **Settings → API Keys**. Create a service account with a clear workload name and description, and generate only the keys the workload requires.
2. Set an expiry for temporary work and store the one-time key value directly in the workload's secret manager.
3. Open the organization's **Enterprise Controls** and enable `restrictApiKeyCreationToManagers`. Review the pending changes and save.
4. Review service-account activity and ownership before disabling an identity or revoking a key. Deletion can remove owned computers and stored Git credentials.

Source: [Factory configuration documentation](https://docs.factory.com/enterprise/identity-and-access), verified 2026-10-30.

#### Code Implementation

The config fragment restricts key creation. The API pack reads service-account and key metadata using a human Manager-or-Owner credential: service-account credentials cannot administer this API. It does not create or rotate secrets. Creation and expiry are performed in the approved setup workflow; destructive rotation is outside this pack.

{% include pack-code.html vendor="factory" section="1.3" %}

#### Validation & Testing

1. Confirm a User cannot create a new API key while an authorized Manager can.
2. Review the private inventory for workload ownership, inactive accounts, revoked keys and missing expirations. Inventory collection alone is not a compliance verdict.

**Expected result:** Credential administration is restricted and every active automation identity has an accountable owner.

#### Monitoring & Maintenance

Review this control after client upgrades, policy changes and integration changes; include it in the quarterly access/configuration review. Record the tested client version and effective organization/device scope.

#### Operational Impact

Existing keys are not revoked by the settings fragment. Disabling an account can interrupt workloads; move consumers before an approved revocation.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By control family | Account Management; no product-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AC-6, IA-5 | Supports the access, configuration, information-flow or evidence objective described above. |
| SOC 2 | CC6.1 | Supporting evidence for the relevant logical-access or monitoring criterion; not a certification claim. |

---

## 2. Agent Execution Controls

### 2.1 Cap Agent and Subagent Autonomy

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Access Control Management (control-family mapping) |
| NIST 800-53 Rev. 5 | AC-6 |
| SOC 2 | CC6.1 |

#### Description

Set an organization `maxAutonomyLevel` appropriate to the environment and explicitly cap subagents. The sample uses a Low ceiling and Off subagent autonomy. `sessionDefaultSettings` supplies convenient starting values, while the ceiling provides the policy boundary.

#### Rationale

**Why This Matters:**

- An easily overridden default cannot enforce an organization-wide execution limit.
- Delegated work should not gain greater autonomy than the approved parent workflow.

**Attack Prevented:** Unattended high-impact operations and escalation of agent autonomy through local preferences.

#### Prerequisites

Organization administration and a supported managed Droid deployment.

#### ClickOps Implementation

1. Open **Settings → Enterprise Controls** in the Factory App for the active organization. Enterprise root Owners can also open the organization controls from **Admin Console → Organizations**.
2. Set `maxAutonomyLevel` to `low` and `subagentAutonomyLevel` to `off` for the baseline policy. Choose stricter or separately scoped policy where the workflow requires it.
3. Optionally set Off autonomy and Spec interaction as session defaults. Review Changes and save; do not treat these defaults as locked controls.
4. Keep command blocks, sandboxing and scoped credentials enabled. A permission-bypass launch is not made safe by a session default.

Source: [Factory Enterprise Controls](https://docs.factory.com/enterprise/hierarchical-settings-and-org-control), verified 2026-10-30.

#### Code Implementation

{% include pack-code.html vendor="factory" section="2.1" %}

#### Validation & Testing

1. Attempt to choose an autonomy level above the ceiling as a normal member and inspect the resolved result.
2. Check subagent behavior in a controlled task and verify the explicit cap is applied.

**Expected result:** Normal member and project preferences cannot raise autonomy above the managed ceiling.

#### Monitoring & Maintenance

Review this control after client upgrades, policy changes and integration changes; include it in the quarterly access/configuration review. Record the tested client version and effective organization/device scope.

#### Operational Impact

Lower ceilings add approvals and may prevent Missions that require High autonomy. Use a separately governed environment for those workloads instead of raising the general ceiling.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By control family | Access Control Management; no product-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AC-6 | Supports the access, configuration, information-flow or evidence objective described above. |
| SOC 2 | CC6.1 | Supporting evidence for the relevant logical-access or monitoring criterion; not a certification claim. |

---

### 2.2 Enforce Tested Command Permission Rules

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Secure Configuration (control-family mapping) |
| NIST 800-53 Rev. 5 | AC-6, CM-7 |
| SOC 2 | CC6.1 |

#### Description

Use native `permissionRules` to block specific publishing operations and require approval where that is sufficient. The sample blocks the exact `git push` and `npm publish` prefixes. Command rules match ordered tokens and cannot cover every equivalent executable, wrapper or script.

#### Rationale

**Why This Matters:**

- Prompt instructions do not enforce a prohibition on remote writes.
- An explicit block remains effective when permission prompts are skipped; an Ask decision does not.

**Attack Prevented:** Unreviewed publishing or remote writes using the command forms covered by policy.

#### Prerequisites

Confirm permission rules are activated for the organization and supported by deployed clients. A successful checker run does not activate enforcement.

#### ClickOps Implementation

1. Open **Enterprise Controls → Permission Rules → Manage rules** and add a rule with a stable organization ID.
2. Choose **Block** for forbidden operations, enter the ordered tokens under **Command starts with**, and provide **Should match** and **Should not match** examples.
3. Select **Done**, then **Review Changes** and save. Closing the editor alone does not publish the policy.
4. Test argument-order and executable-path variants. Retain existing legacy restrictions until coexistence and migration have been reviewed; native rules can replace restrictions from the same source.

Source: [Factory configuration documentation](https://docs.factory.com/autonomy-and-safety/permission-rules), verified 2026-10-30.

#### Code Implementation

The CLI pack extracts a standalone rules container from reviewed strict JSON, validates it, and collects candidate and resolved previews without executing the command. Checker exit 0 does not mean the command was allowed or blocked: inspect the reported decision and diagnostics. Invalid local rules may be skipped.

{% include pack-code.html vendor="factory" section="2.2" %}

#### Validation & Testing

1. Preview `git push origin main` with candidate and resolved policy and confirm a Block decision after rollout.
2. Confirm `git -C /repo push` is outside this sample prefix. Assess that gap with sandboxing, credential scoping and additional tested rules.

**Expected result:** The tested command forms are blocked; diagnostics and uncovered equivalents are understood.

#### Monitoring & Maintenance

Review this control after client upgrades, policy changes and integration changes; include it in the quarterly access/configuration review. Record the tested client version and effective organization/device scope.

#### Operational Impact

The sample prevents direct publishing through those prefixes. Restore a previously tested policy if an approved workflow breaks; never replace a hard block with Ask while assuming equivalent protection.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By control family | Secure Configuration; no product-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AC-6, CM-7 | Supports the access, configuration, information-flow or evidence objective described above. |
| SOC 2 | CC6.1 | Supporting evidence for the relevant logical-access or monitoring criterion; not a certification claim. |

---

### 2.3 Isolate the Runtime and Protect Host Secrets

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Network Infrastructure Management (control-family mapping) |
| NIST 800-53 Rev. 5 | SC-7, AC-6 |
| SOC 2 | CC6.6 |

#### Description

Enable the built-in sandbox, explicitly deny credential directories, and limit command egress to reviewed domains. Prefer `whole-process` where the host supports it and the workflow has been tested. Merely enabling the sandbox leaves reads allowed unless explicit deny rules apply.

#### Rationale

**Why This Matters:**

- A coding agent otherwise inherits much of the user's filesystem and network access.
- Whole-process isolation also contains the main Droid process; per-command mode leaves that process outside the OS sandbox.

**Attack Prevented:** Credential harvesting from host files and command-driven data exfiltration.

#### Prerequisites

Supported macOS or Linux/WSL2 isolation primitives, an approved domain list, and a pilot host. Confirm native-platform support before deployment.

#### ClickOps Implementation

1. Open the organization's **Enterprise Controls** and enable `sandbox.enabled`; select `sandbox.mode` as `whole-process` for this profile.
2. Add credential locations to `sandbox.filesystem.denyRead` and protected write locations to `denyWrite`. Add project-specific secrets explicitly.
3. Review `sandbox.network.allowedDomains`. The sample permits only GitHub hosts in addition to Factory and WorkOS domains that are always permitted.
4. Review socket, local-binding and proxy requirements. Do not add broad writable credential locations or wildcard domains merely to make a failed workflow pass.

Source: [Factory configuration documentation](https://docs.factory.com/autonomy-and-safety/sandbox), verified 2026-10-30.

#### Code Implementation

{% include pack-code.html vendor="factory" section="2.3" %}

#### Validation & Testing

1. On a disposable pilot host, verify denied file reads and writes fail and an unapproved network destination is blocked.
2. Confirm missing isolation primitives prevent startup in whole-process mode. Test ordinary development tasks before expanding rollout.

**Expected result:** Explicitly denied files and unapproved command destinations remain inaccessible under the tested sandbox.

#### Monitoring & Maintenance

Review this control after client upgrades, policy changes and integration changes; include it in the quarterly access/configuration review. Record the tested client version and effective organization/device scope.

#### Operational Impact

Dependencies, custom model gateways and local services may need narrowly scoped exceptions. Factory/WorkOS traffic remains permitted. Restore the last approved sandbox policy if rollout breaks required tasks.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By control family | Network Infrastructure Management; no product-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | SC-7, AC-6 | Supports the access, configuration, information-flow or evidence objective described above. |
| SOC 2 | CC6.6 | Supporting evidence for the relevant logical-access or monitoring criterion; not a certification claim. |

---

### 2.4 Keep Droid Shield Secret Scanning Enabled

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Data Protection (control-family mapping) |
| NIST 800-53 Rev. 5 | SI-4 |
| SOC 2 | CC6.7 |

#### Description

Keep `enableDroidShield` enabled in organization policy so Droid scans changes for likely secrets before Droid-mediated Git commits and pushes. Do not represent this protection as general DLP or as coverage for Git operations performed outside Droid.

#### Rationale

**Why This Matters:**

- Generated changes can accidentally contain credentials or sensitive configuration.
- A scan that cannot safely process a large diff should not silently permit publication.

**Attack Prevented:** Accidental secret publication through the Droid-mediated Git operations covered by Shield.

#### ClickOps Implementation

1. Open the organization's **Enterprise Controls** and enable Droid Shield through `enableDroidShield`. Review Changes and save.
2. Confirm users cannot disable the managed value through personal settings.
3. Keep repository secret scanning and publishing controls in place for external Git clients and other upload paths. Evaluate any private-preview Shield features separately.

Source: [Factory configuration documentation](https://docs.factory.com/autonomy-and-safety/droid-shield), verified 2026-10-30.

#### Code Implementation

{% include pack-code.html vendor="factory" section="2.4" %}

#### Validation & Testing

1. Verify the effective setting on a pilot client and review how the current version reports a blocked scan or oversized diff.
2. Use the vendor's documented testing workflow in a disposable repository if exercising detection; do not introduce real secrets.

**Expected result:** Droid-mediated commit and push checks remain enabled and their coverage limits are recorded.

#### Monitoring & Maintenance

Review this control after client upgrades, policy changes and integration changes; include it in the quarterly access/configuration review. Record the tested client version and effective organization/device scope.

#### Operational Impact

False positives or oversized diffs may block a change. Follow the documented review/recovery procedure instead of disabling the organization setting.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By control family | Data Protection; no product-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | SI-4 | Supports the access, configuration, information-flow or evidence objective described above. |
| SOC 2 | CC6.7 | Supporting evidence for the relevant logical-access or monitoring criterion; not a certification claim. |

---

### 2.5 Govern Built-in Network Tools

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Data Protection (control-family mapping) |
| NIST 800-53 Rev. 5 | AC-4, CM-7 |
| SOC 2 | CC6.7 |

#### Description

Remove built-in Web Search when external searching is not approved, and require a higher approval threshold for remaining built-in network tools. Web Search and Web Fetch are distinct tools; disabling one does not disable the other. These settings are honored only at organization scope.

#### Rationale

**Why This Matters:**

- Search queries and fetched pages create data and untrusted-content paths outside a repository.
- An MCP allowlist does not govern the availability of built-in network tools.

**Attack Prevented:** Unapproved automatic web queries and fetching under the tool-approval scope configured here.

#### ClickOps Implementation

1. Open the organization's **Enterprise Controls → Built-in Network Tools**.
2. Turn on **Disable Web Search**, which sets `webSearchDisabled: true` and removes `WebSearch` from tool discovery and Script access.
3. Review `builtInToolAutonomyOverrides` and set `FetchUrl` to `high` for this profile. With the Low ceiling from control 2.1, normal permission-checked use requires approval.
4. Review Changes and save. Retain sandbox/network controls: an approval threshold is not a hard prohibition, and permission-bypass execution can skip prompts.

Source: [Factory Enterprise Controls](https://docs.factory.com/enterprise/hierarchical-settings-and-org-control), verified 2026-10-31.

#### Code Implementation

The organization fragment removes Search and sets high thresholds for both built-in network tools. The CLI pack collects the available tool catalog without starting a model task; inspect Search availability and test Fetch approval independently. The Search threshold becomes relevant only if Search is later made available. Project, folder, user and runtime preferences do not establish these org-only controls.

{% include pack-code.html vendor="factory" section="2.5" %}

#### Validation & Testing

1. Confirm built-in `WebSearch` is absent from the client tool catalog and cannot be re-enabled through lower-level settings.
2. In a pilot session below High autonomy, verify `FetchUrl` requires approval. Test its network destination against the sandbox policy separately.

**Expected result:** Search is unavailable and Fetch approval follows the organization threshold; no claim of a universal network block is made.

#### Monitoring & Maintenance

Review tool availability and approval behavior after client upgrades. Check both org-only settings and actual tool discovery rather than relying on a user preference.

#### Operational Impact

Research workflows may need an approved alternative. Restore Search only after approving its data flow; lowering a threshold broadens automatic access and does not change the sandbox.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By control family | Data Protection; no product benchmark recommendation asserted. |
| NIST 800-53 Rev. 5 | AC-4, CM-7 | Restrict information flows and unnecessary tool availability. |
| SOC 2 | CC6.7 | Supports restrictions on data transmission paths. |

---

## 3. Integration & Extension Security

### 3.1 Allow Only Reviewed MCP Servers and Tools

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Access Control Management (control-family mapping) |
| NIST 800-53 Rev. 5 | AC-6, CM-7 |
| SOC 2 | CC6.1 |

#### Description

Enable the organization MCP policy and populate it only with reviewed server matchers. The starter policy uses an empty allowlist to deny all servers. Review per-server tool exposure and persistent approvals before admitting an integration.

#### Rationale

**Why This Matters:**

- MCP adds executable tools and access to other services under the agent's authority.
- A broad hostname or launcher matcher can authorize substantially more than one reviewed tool.

**Attack Prevented:** Unreviewed tool execution and data access through malicious or overprivileged MCP servers.

#### ClickOps Implementation

1. Open the organization's **Enterprise Controls** and set `mcpPolicy.enabled` to `true`. Start with an empty `allowlist` during assessment.
2. Review proposed remote hostnames or exact stdio commands and arguments before adding entries. A remote matcher is hostname-based: scheme, path and port do not constrain it, and a parent hostname also permits subdomains.
3. In Droid, open **/mcp** to inspect each server's origin, enabled tools and authentication. Prefer explicit `enabledTools` where an integration needs only a subset.
4. Review persistent tool permissions. Store credentials outside project `mcp.json`; use supported environment references or the keyring.

Source: [Factory configuration documentation](https://docs.factory.com/harness/mcp), verified 2026-10-30.

#### Code Implementation

The CLI pack collects server and persistent-approval inventories. It does not revoke approvals. An enabled empty allowlist blocks every server; omitting `enabled` does not enforce the allowlist. Avoid broad `npx`, hostname and normalized argument matchers.

{% include pack-code.html vendor="factory" section="3.1" %}

#### Validation & Testing

1. Attempt a connection to an unapproved server in a pilot project and verify policy denial.
2. Review approved-server tools and persistent grants. Changing a server's transport configuration should require new approval.

**Expected result:** Only vetted matches are available and tool approvals align with the integration's intended access.

#### Monitoring & Maintenance

Review this control after client upgrades, policy changes and integration changes; include it in the quarterly access/configuration review. Record the tested client version and effective organization/device scope.

#### Operational Impact

Deny-all disables existing MCP workflows. Add reviewed matchers deliberately; a URL path cannot provide isolation between production and staging on the same hostname.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By control family | Access Control Management; no product-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AC-6, CM-7 | Supports the access, configuration, information-flow or evidence objective described above. |
| SOC 2 | CC6.1 | Supporting evidence for the relevant logical-access or monitoring criterion; not a certification claim. |

---

### 3.2 Restrict Plugins and Marketplace Sources

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Inventory and Control of Software Assets (control-family mapping) |
| NIST 800-53 Rev. 5 | CM-7, CM-10 |
| SOC 2 | CC6.8 |

#### Description

Enforce an exhaustive plugin allowlist and restrict marketplace sources at organization level. The starter fragment allows no plugins or additional marketplaces. Add approved plugins and pinned marketplace commits only after reviewing their commands, MCP servers and hooks.

#### Rationale

**Why This Matters:**

- A plugin is a software supply-chain input with executable capabilities.
- Additive enablement preferences do not prevent a member or repository from enabling another plugin.

**Attack Prevented:** Unreviewed extension execution and malicious marketplace updates.

#### Prerequisites

A client release that recognizes `strictEnabledPlugins` and the marketplace policy. Older clients may ignore new fields.

#### ClickOps Implementation

1. Open the organization's **Enterprise Controls** and set `strictEnabledPlugins` to `true`. Review `enabledPlugins` as the exhaustive approved map.
2. Review `strictKnownMarketplaces` and all organization `extraKnownMarketplaces`. Organization-added sources are automatically included even when the strict list is empty.
3. For an approved remote marketplace, prefer its supported full commit `sha` pin and review the pinned source. Inspect each plugin's own dependencies as well.
4. Save and test a normal member's attempt to enable an unlisted plugin. Check default plugins as well; strict mode disables defaults unless explicitly listed.

Source: [Factory configuration documentation](https://docs.factory.com/enterprise/internal-plugin-marketplaces), verified 2026-10-30.

#### Code Implementation

{% include pack-code.html vendor="factory" section="3.2" %}

#### Validation & Testing

1. Verify an unapproved manual install or local enablement is rejected on each deployed client version.
2. Compare the private installed-plugin inventory with effective enablement. Previously installed plugins may remain on disk and reactivate if the policy is removed.

**Expected result:** Lower-level settings cannot enable plugins outside the organization allowlist.

#### Monitoring & Maintenance

Review this control after client upgrades, policy changes and integration changes; include it in the quarterly access/configuration review. Record the tested client version and effective organization/device scope.

#### Operational Impact

The starter policy disables default plugins and can interrupt workflows. Restore only approved entries; removing strict mode can reactivate previously installed extensions.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By control family | Inventory and Control of Software Assets; no product-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | CM-7, CM-10 | Supports the access, configuration, information-flow or evidence objective described above. |
| SOC 2 | CC6.8 | Supporting evidence for the relevant logical-access or monitoring criterion; not a certification claim. |

---

### 3.3 Govern Hooks as Executable Policy

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Secure Configuration (control-family mapping) |
| NIST 800-53 Rev. 5 | CM-5, CM-7 |
| SOC 2 | CC6.8 |

#### Description

Allow only organization-managed hooks and hooks from organization-enabled plugins, keep hooks enabled, and protect the executable scripts they reference. Use PreToolUse hooks for pre-execution checks. Hooks execute code and are part of the trusted computing base.

#### Rationale

**Why This Matters:**

- A repository-supplied hook can introduce unreviewed execution into otherwise governed sessions.
- A hook pointing at a user-writable script can be altered without changing the managed hook definition.

**Attack Prevented:** Untrusted hook execution and bypass of custom pre-execution checks.

#### ClickOps Implementation

1. Open the organization's **Enterprise Controls** and set `allowManagedHooksOnly` to `true` and `hooksDisabled` to `false`. Review the permitted plugins from control 3.2.
2. Distribute approved hook scripts through protected endpoint management locations and reference those paths in organization hooks.
3. For a blocking PreToolUse check, implement the documented denial contract and test failures. Exit 2 is blocking; ordinary other nonzero errors are nonblocking.
4. Do not use PostToolUse as a preventive boundary: it runs after the action. Review Changes and save the managed hook policy.

Source: [Factory configuration documentation](https://docs.factory.com/harness/hooks), verified 2026-10-30.

#### Code Implementation

The fragment pins loading policy and leaves hook definitions to the organization. It does not install a DLP script or claim a fail-closed hook implementation. Organization-enabled plugin hooks remain in scope.

{% include pack-code.html vendor="factory" section="3.3" %}

#### Validation & Testing

1. Verify user and project hooks are ignored while an approved managed hook runs.
2. Test an explicit denial, an ordinary error and a timeout using harmless actions; confirm the actual behavior and protect the referenced script from member edits.

**Expected result:** Only reviewed managed hook sources load, with observed failure behavior for the deployed scripts.

#### Monitoring & Maintenance

Review this control after client upgrades, policy changes and integration changes; include it in the quarterly access/configuration review. Record the tested client version and effective organization/device scope.

#### Operational Impact

Local workflow hooks stop loading. Restore approved functionality as protected managed hooks rather than re-enabling every repository's hooks.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By control family | Secure Configuration; no product-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | CM-5, CM-7 | Supports the access, configuration, information-flow or evidence objective described above. |
| SOC 2 | CC6.8 | Supporting evidence for the relevant logical-access or monitoring criterion; not a certification claim. |

---

### 3.4 Scope Source Control Access to Approved Repositories

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Access Control Management (control-family mapping) |
| NIST 800-53 Rev. 5 | AC-6, AC-3 |
| SOC 2 | CC6.3 |

#### Description

Limit Factory's source-control integration and each service account to the repositories required by its workload. Prefer the documented GitHub App installation model for GitHub/GHES, and a dedicated service-account token for GitLab. Factory service accounts do not inherit a human user's SCM OAuth credentials.

#### Rationale

**Why This Matters:**

- An agent or integration compromise is limited by the repositories its credentials can reach.
- Separate organization and workload credentials reduce cross-team and cross-client exposure.

**Attack Prevented:** Lateral access across repositories through an overprivileged integration or shared human SCM token.

#### ClickOps Implementation

1. Open organization **Settings → API Keys** and select the service account that owns the workflow.
2. For GitHub or GHES, review the organization's GitHub App installation and grant only the repositories the service account requires.
3. For GitLab or self-hosted GitLab, configure the account's own token under its **Git Credentials** and scope repository access in the source-control platform.
4. Test both an approved repository and a repository outside the assignment. Preserve branch protection and PR review requirements in the SCM platform.

Source: [Factory configuration documentation](https://docs.factory.com/enterprise/identity-and-access), verified 2026-10-30.

**Automation:** ClickOps only for Factory's SCM credential and installation association — the current public administration reference documents no supported write operation for those associations. Repository installation scope is managed in the SCM platform; do not invent a Factory repository-allowlist endpoint. ([Public API reference](https://docs.factory.com/api-reference), verified 2026-10-30.)

#### Validation & Testing

1. Confirm the workload can access its assigned repository and cannot use a human fallback for an unassigned repository.
2. Review organization integrations and the SCM installation or token grants after repository ownership changes.

**Expected result:** The workflow can reach only its explicitly authorized source-control repositories.

#### Monitoring & Maintenance

Review this control after client upgrades, policy changes and integration changes; include it in the quarterly access/configuration review. Record the tested client version and effective organization/device scope.

#### Operational Impact

Narrower grants can prevent cloning or PR creation. Restore the specific approved repository grant; do not substitute a teammate's broad OAuth token.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By control family | Access Control Management; no product-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AC-6, AC-3 | Supports the access, configuration, information-flow or evidence objective described above. |
| SOC 2 | CC6.3 | Supporting evidence for the relevant logical-access or monitoring criterion; not a certification claim. |

---

### 3.5 Approve Factory-Managed App Connectors

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Access Control Management (control-family mapping) |
| NIST 800-53 Rev. 5 | AC-3, AC-6 |
| SOC 2 | CC6.3 |

#### Description

Limit Factory-managed app connectors to approved catalog entries and separately restrict each connected account's permissions in the downstream service. Connectors run through Factory's managed remote service and have their own organization availability controls; an MCP server policy does not replace them.

#### Rationale

**Why This Matters:**

- A managed connector can read or change data in services such as Slack, Google Workspace and issue trackers.
- Enabling an app permits members to connect their own account in that organization; it does not create a shared organization credential.

**Attack Prevented:** Access to unapproved SaaS integrations and excessive downstream access through connected user accounts.

#### Prerequisites

Enterprise connector controls and an organization Owner or Manager. Organizations without these controls use Factory's curated catalog without organization availability switches.

#### ClickOps Implementation

1. In the Factory App, open **Settings → Enterprise Controls → Connectors**.
2. Review every catalog entry. Enable only approved apps and turn off unapproved apps; initial enterprise configuration starts connectors disabled.
3. Have each member review **Settings → Connectors** for the active organization and authorize only an approved account/workspace with appropriate downstream permissions.
4. When retiring an integration, disable organization availability and have members **Disconnect** saved connections as required. Disabling availability does not delete those saved credentials.

Source: [Factory Connectors](https://docs.factory.com/harness/connectors), verified 2026-10-31.

**Automation:** ClickOps only for organization connector availability — the connector guide documents the console switches, while the current public administration reference supplies no verified write operation or native settings schema for them. Persona connector recommendations are not availability enforcement. ([Connector controls](https://docs.factory.com/harness/connectors), [public API](https://docs.factory.com/api-reference), verified 2026-10-31.)

#### Validation & Testing

1. Confirm a disabled app is absent from member settings and tool discovery and cannot start a new authorization flow or execute a tool call.
2. Verify an approved connector is scoped to the correct Factory user and organization, then test a harmless read and the intended write approval behavior.
3. Review saved connections separately: re-enabling an app can reactivate an existing member connection. Connector approvals are per action, not persistent MCP approvals.

**Expected result:** Only approved connector apps are available, and each downstream account grants no more access than its workflow requires.

#### Monitoring & Maintenance

Review availability changes, connected accounts and downstream grants quarterly and during offboarding. Connector invocation audit events identify tool names without arguments/results; use the downstream service's audit trail where more detail is required.

#### Operational Impact

Disabling an app blocks its managed tools for the organization, but does not revoke the external provider's grant or erase member connections. Coordinate retirement and credential removal in both services before re-enabling access.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By control family | Access Control Management; no product benchmark recommendation asserted. |
| NIST 800-53 Rev. 5 | AC-3, AC-6 | Enforce approved integration availability and downstream least privilege. |
| SOC 2 | CC6.3 | Supports authorization and removal of external access. |

---

## 4. Network & Data Boundaries

### 4.1 Restrict the Source IPs of Authenticated Factory Access

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Network Infrastructure Management (control-family mapping) |
| NIST 800-53 Rev. 5 | AC-17, SC-7 |
| SOC 2 | CC6.6 |

#### Description

Configure `networkPolicy.allowedIps` with reviewed corporate IPv4 addresses or CIDRs to restrict where authenticated Factory web, CLI and API access originates. This is a source-access policy. Agent command egress belongs to the sandbox policy in control 2.3.

#### Rationale

**Why This Matters:**

- A stolen token is less useful when requests must originate from approved network locations.
- Keeping ingress and egress policies distinct prevents a false assumption that source-IP restrictions stop agent exfiltration.

**Attack Prevented:** Use of stolen Factory credentials from an unapproved source network.

#### Prerequisites

Verified corporate egress addresses, all CI/proxy/remote-work paths, a separate proven recovery path, and an authorized rollout window.

#### ClickOps Implementation

1. Inventory the IPv4 source addresses used by administrators, developer clients, CI and any approved proxy. Do not use documentation/example IPs.
2. Open the organization's **Enterprise Controls** and review `networkPolicy.allowedIps`; a configured list must contain at least one entry.
3. Include the verified administrator and recovery paths before saving. Pilot the policy and confirm access from approved locations.
4. Use the dedicated managed-settings and safety references for this field's scope. The CLI Settings page also describes it as outbound restriction; that conflicts with the dedicated administration reference.

Source: [Factory configuration documentation](https://docs.factory.com/enterprise/llm-safety-and-agent-controls), verified 2026-10-30.

#### Code Implementation

The generator requires a reviewed JSON input file, rejects IPv6 and unrestricted /0, and prints a fragment without applying it. It cannot prove that the operator's current egress or recovery path is included.

{% include pack-code.html vendor="factory" section="4.1" %}

#### Validation & Testing

1. From independently controlled approved and unapproved networks, test web, CLI and API access without exposing tokens.
2. Confirm legitimate CI and remote-work requests still succeed and that the recovery path works.

**Expected result:** Authenticated access succeeds only from the reviewed source networks on the tested surfaces.

#### Monitoring & Maintenance

Review this control after client upgrades, policy changes and integration changes; include it in the quarterly access/configuration review. Record the tested client version and effective organization/device scope.

#### Operational Impact

An incomplete list can lock out administrators and CI. Do not apply until recovery access is proven. Restore the prior policy through that path if needed.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By control family | Network Infrastructure Management; no product-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AC-17, SC-7 | Supports the access, configuration, information-flow or evidence objective described above. |
| SOC 2 | CC6.6 | Supporting evidence for the relevant logical-access or monitoring criterion; not a certification claim. |

---

### 4.2 Approve Model Destinations and Disable Unapproved Image Models

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Data Protection (control-family mapping) |
| NIST 800-53 Rev. 5 | AC-4, CM-7 |
| SOC 2 | CC6.7 |

#### Description

Allow only reviewed model IDs, disable automatic admission of future Factory models, and restrict user-supplied custom models. Govern image generation separately because image models are outside the ordinary `modelPolicy` lists. The starter policy disables user BYOK and image generation.

#### Rationale

**Why This Matters:**

- Inference destinations determine where repository context and prompts are processed.
- A default model selection does not prevent other models or future catalog additions from becoming available.

**Attack Prevented:** Context transfer to unapproved model providers, custom endpoints or image-generation models.

#### ClickOps Implementation

1. Open the organization's **Enterprise Controls** and review the allowed model catalog with the data owner.
2. Set `modelPolicy.allowedModelIds`, `allowAllFactoryModels: false` and `allowCustomModels: false` for a hosted-model allowlist. Review all existing custom definitions.
3. Disable **Session Features → Image Generation**, or separately configure **Allowed image models** after approving those models.
4. For a gateway/BYOK deployment, design a separate tested policy using documented `allowedBaseUrls` and approved custom models. Do not combine this no-user-BYOK starter with a claim that custom model traffic is enabled.

Source: [Factory Enterprise Controls](https://docs.factory.com/enterprise/hierarchical-settings-and-org-control), verified 2026-10-30.

#### Code Implementation

The generator requires current approved IDs. The official Python SDK pack discovers enabled and disabled models without opening a session or making a model call, then compares selectable IDs with the reviewed list. Unknown IDs can be silently dropped by Factory; verify the effective catalog.

{% include pack-code.html vendor="factory" section="4.2" %}

#### Validation & Testing

1. Run catalog verification in a trusted project under a normal member's identity and investigate unexpected or missing models.
2. Confirm a disallowed custom endpoint and image generation cannot be selected. Check model routing and inference data flows separately.

**Expected result:** Selectable models match the reviewed list for the tested account/project, with independent image-model governance.

#### Monitoring & Maintenance

Review this control after client upgrades, policy changes and integration changes; include it in the quarterly access/configuration review. Record the tested client version and effective organization/device scope.

#### Operational Impact

Models can disappear as region or entitlement changes. Update approvals deliberately. Factory Private normally retains a hosted control plane; VPC execution alone does not establish private inference or storage.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By control family | Data Protection; no product-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AC-4, CM-7 | Supports the access, configuration, information-flow or evidence objective described above. |
| SOC 2 | CC6.7 | Supporting evidence for the relevant logical-access or monitoring criterion; not a certification claim. |

---

### 4.3 Minimize Session and AutoWiki Cloud Persistence

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Data Protection (control-family mapping) |
| NIST 800-53 Rev. 5 | AC-4, SI-12 |
| SOC 2 | CC6.7 |

#### Description

Disable cloud session synchronization and AutoWiki cloud synchronization where cloud persistence is not approved. Set cloud session retention to the organization's documented requirement; the sample uses 30 days within Factory's supported 14–365-day range.

#### Rationale

**Why This Matters:**

- Agent transcripts and generated wiki content can contain sensitive repository context.
- Session sync and AutoWiki sync are separate data paths and need separate decisions.

**Attack Prevented:** Unapproved persistence or sharing of repository and session content through hosted features.

#### ClickOps Implementation

1. Open the organization's **Enterprise Controls** and set `cloudSessionSync` and `wikiCloudSync` to `false` when hosted content is not approved.
2. Set `sessionRetentionDays` to the reviewed requirement. Do not assume the cloud retention field deletes local transcripts, GitHub wikis, exports or existing independent copies.
3. Review the operational impact: disabling wiki sync blocks AutoWiki API endpoints and skips Factory cloud and GitHub wiki sync.
4. For Enterprise compliance restrictions across managed inference, managed compute or cloud sync, use Factory's written-request process; those restrictions cannot be changed through Enterprise Controls.

Source: [Factory Enterprise Controls](https://docs.factory.com/enterprise/hierarchical-settings-and-org-control), verified 2026-10-30.

#### Code Implementation

{% include pack-code.html vendor="factory" section="4.3" %}

#### Validation & Testing

1. Verify a member cannot re-enable managed sync settings through local preferences.
2. Confirm new sessions and AutoWiki operations follow the intended policy and obtain separate evidence for historical data removal if required.

**Expected result:** The specified hosted sync paths are disabled and retention matches the approved requirement.

#### Monitoring & Maintenance

Review this control after client upgrades, policy changes and integration changes; include it in the quarterly access/configuration review. Record the tested client version and effective organization/device scope.

#### Operational Impact

Cross-device history and hosted AutoWiki workflows stop working. Restore individual features only after data handling is approved; legal holds and deletion requests need separate handling.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By control family | Data Protection; no product-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AC-4, SI-12 | Supports the access, configuration, information-flow or evidence objective described above. |
| SOC 2 | CC6.7 | Supporting evidence for the relevant logical-access or monitoring criterion; not a certification claim. |

---

### 4.4 Restrict Managed Compute and Remote Control

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Access Control Management (control-family mapping) |
| NIST 800-53 Rev. 5 | AC-17, AC-6 |
| SOC 2 | CC6.1 |

#### Description

Disable Factory-managed computers and Remote Control until their data, credential and access boundaries are approved. Where those features are required, scope the documented allowed-email lists to authorized operators rather than admitting every member.

#### Rationale

**Why This Matters:**

- Remote control adds another route into a persistent development environment.
- Persistent computers can retain credentials and services beyond a single coding task.

**Attack Prevented:** Unapproved remote execution and access to development environments through remote-control features.

#### ClickOps Implementation

1. Open the organization's **Enterprise Controls** and review `managedComputersEnabled` and `byomComputersEnabled`. The starter fragment sets both to `false`.
2. If approved, enable the required feature and review `managedComputersAllowedEmails` or `byomComputersAllowedEmails` for the permitted operators.
3. Inventory existing computers, registrations, workloads and stored credentials separately. Do not assume a feature toggle deletes or cleans up existing resources.
4. Document whether execution, inference, orchestration and session storage are local, customer-hosted or Factory-hosted.

Source: [Factory Enterprise Controls](https://docs.factory.com/enterprise/hierarchical-settings-and-org-control), verified 2026-10-30.

#### Code Implementation

The CLI pack collects computers visible to the authenticated identity. Review other operators and persistent resources separately; it does not provision or remove computers.

{% include pack-code.html vendor="factory" section="4.4" %}

#### Validation & Testing

1. Verify an unapproved member cannot register a Remote Control computer or provision managed compute.
2. Check existing resources and access paths after the policy change; perform any decommissioning through the authorized operational workflow.

**Expected result:** Only explicitly approved computer and remote-access workflows remain available.

#### Monitoring & Maintenance

Review this control after client upgrades, policy changes and integration changes; include it in the quarterly access/configuration review. Record the tested client version and effective organization/device scope.

#### Operational Impact

Disabling a feature may interrupt remote work. Re-enable only the approved scoped path and review existing persistent state independently.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By control family | Access Control Management; no product-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AC-17, AC-6 | Supports the access, configuration, information-flow or evidence objective described above. |
| SOC 2 | CC6.1 | Supporting evidence for the relevant logical-access or monitoring criterion; not a certification claim. |

---

## 5. Monitoring & Change Detection

### 5.1 Export Telemetry without Raw Message Content

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Audit Log Management (control-family mapping) |
| NIST 800-53 Rev. 5 | AU-2, AU-9, AC-4 |
| SOC 2 | CC7.2 |

#### Description

Pin a customer-owned HTTPS OTLP collector through organization `telemetry` settings and set `logMessageContent` to `false`. Use aggregate granularity when per-user identity is not needed. The sample keeps GenAI trace structure while excluding message content and direct user identifiers.

#### Rationale

**Why This Matters:**

- Opting into content exports sends raw prompts, tool inputs and results without secret or PII redaction.
- An organization-pinned collector prevents local telemetry variables from redirecting the customer stream.

**Attack Prevented:** Sensitive content disclosure through telemetry configuration and unauthorized redirection of the customer sink.

#### Prerequisites

An approved collector, controlled retention and access, and a separately provisioned machine-local collector credential.

#### ClickOps Implementation

1. Open the organization's **Enterprise Controls** and configure the organization-only `telemetry` block with `enabled: true` and the reviewed collector endpoint.
2. Set `logMessageContent: false` and choose `granularity: aggregate` where identity minimization is appropriate. Keep the selected export convention consistent with the collector.
3. Reference `${FACTORY_OTLP_TOKEN}` in the header and distribute that variable out of band. Managed telemetry settings are readable by every member; never embed a resolved secret.
4. Restart pilot sessions and verify delivery. A missing referenced variable disables the customer sink for that session; it does not disable Factory's separate collector.

Source: [Factory configuration documentation](https://docs.factory.com/enterprise/telemetry), verified 2026-10-30.

#### Code Implementation

The generator emits a literal credential reference and requires an HTTPS endpoint without embedded credentials, query or fragment. Aggregate telemetry still carries organization/session/repository/tool metadata and is not anonymous. Customer sink settings do not configure Factory's own collector.

{% include pack-code.html vendor="factory" section="5.1" %}

#### Validation & Testing

1. Confirm a fresh session reaches the customer collector and raw content attributes are absent.
2. Check direct user identifiers are removed in aggregate mode and review remaining metadata. Test missing-credential handling and monitor delivery failures.

**Expected result:** The customer collector receives the approved telemetry shape with content export disabled.

#### Monitoring & Maintenance

Review this control after client upgrades, policy changes and integration changes; include it in the quarterly access/configuration review. Record the tested client version and effective organization/device scope.

#### Operational Impact

Aggregate mode reduces per-person attribution. The GenAI format retains trace structure; legacy aggregate mode emits no spans. Review this tradeoff with the audit and privacy owners.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By control family | Audit Log Management; no product-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AU-2, AU-9, AC-4 | Supports the access, configuration, information-flow or evidence objective described above. |
| SOC 2 | CC7.2 | Supporting evidence for the relevant logical-access or monitoring criterion; not a certification claim. |

---

### 5.2 Review Audit Events and Managed Policy History

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Audit Log Management (control-family mapping) |
| NIST 800-53 Rev. 5 | AU-6, CM-3 |
| SOC 2 | CC7.2 |

#### Description

Review Factory's organization audit log for changes to identities, keys, integrations and settings, and retain managed-settings revision history for change review. Use telemetry for runtime activity; organization audit events do not describe every agent action.

#### Rationale

**Why This Matters:**

- Policy and integration changes can weaken otherwise correct controls.
- Historical settings snapshots make unexpected changes reviewable but do not prove the policy currently effective on a managed device.

**Attack Prevented:** Undetected weakening of governance, rogue key creation and unauthorized integration changes.

#### Prerequisites

Enterprise organization Owner access for the audit log; a human administrator credential authorized to read enterprise-control history for the API pack.

#### ClickOps Implementation

1. Open **Team Settings** in the Factory web app and open the **Audit Log** as an Enterprise organization Owner.
2. Review membership, API-key, service-account, integration and managed-settings events against approved changes.
3. Collect documented enterprise-control history using the read-only API and compare revisions with change records. Treat settings snapshots as sensitive evidence.
4. Compare remote history with endpoint-management policy too: a system-managed settings file can short-circuit remote org settings. Correlate runtime activity with telemetry rather than treating the audit log as a complete command transcript.

Source: [Factory configuration documentation](https://docs.factory.com/enterprise/audit-log), verified 2026-10-30.

#### Code Implementation

The pack implements the documented paginated settings-history endpoint only. Factory documents public-API audit access, but this run did not verify an exact general audit-log export route or machine event schema; no such endpoint or SIEM table is invented.

{% include pack-code.html vendor="factory" section="5.2" %}

#### Validation & Testing

1. Make an authorized harmless change in a test organization and confirm the expected audit event and settings revision appear.
2. Confirm the history pack collects all pages, protects the evidence file and rejects incomplete results. Review the evidence manually.

**Expected result:** Organization changes are attributable and approved settings changes can be traced through revisions.

#### Monitoring & Maintenance

Review this control after client upgrades, policy changes and integration changes; include it in the quarterly access/configuration review. Record the tested client version and effective organization/device scope.

#### Operational Impact

Audit viewing is Enterprise Owner-gated. Preserve exports under the organization's retention and privacy rules; collecting evidence does not change the tenant.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By control family | Audit Log Management; no product-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AU-6, CM-3 | Supports the access, configuration, information-flow or evidence objective described above. |
| SOC 2 | CC7.2 | Supporting evidence for the relevant logical-access or monitoring criterion; not a certification claim. |

---

## 6. Integration Risk Reference

This is a reference table, not additional leveled controls.

| Integration or surface | Access at risk | Apply |
|------------------------|----------------|-------|
| Source-control application or workload token | Repository content, branches and PR operations | 1.3, 2.2, 3.4; SCM branch and application controls |
| MCP server | External data and tools; local process execution for stdio | 2.3, 3.1; downstream service permissions |
| Plugin or hook | Executable code, tools and lifecycle events | 3.2, 3.3; protected script distribution |
| Factory-managed app connector | Downstream account data and tools | 3.5; downstream service grants and audit |
| Built-in Search or Fetch | Search queries, fetched content and external destinations | 2.3, 2.5; data-flow review |
| Model provider or custom gateway | Prompts and selected repository context | 4.2; approved contracts and inference destinations |
| Remote or managed computer | Persistent files, local services and credentials | 2.3, 4.4; separate resource lifecycle review |
| Customer OTLP collector | Runtime metadata and optionally raw content | 5.1; collector access and retention controls |
| Cloud session sync or AutoWiki | Session and generated documentation content | 4.3; review other copies and destinations separately |

Factory Private normally uses Factory's hosted control plane with execution in the customer's VPC; inference and session storage follow separate settings. See [Data Flows & Privacy](https://docs.factory.com/enterprise/privacy-and-data-flows). Customer-wide compliance restrictions require a [written request to Factory](https://docs.factory.com/enterprise/compliance-audit-and-monitoring). Neither a VPC deployment nor a local CLI setting by itself proves that all data stays inside a private network.

## 7. Compliance Quick Reference

Mappings identify supporting objectives and require an organization-specific assessment. They do not establish compliance or replace a product benchmark. The source sweep did not identify a Factory-specific CIS, CISA SCuBA, NSA or ACSC configuration baseline; DISA coverage was not verifiable from its public index. The [source ledger](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/factory-source-evidence.md) records the search and automation limits.

| Objective | Guide controls | Example NIST SP 800-53 Rev. 5 families |
|-----------|----------------|----------------------------------------|
| Workforce and workload identity | 1.1–1.3, 3.4–3.5 | AC-2, AC-3, AC-6, IA-2, IA-5 |
| Execution and extension boundaries | 2.1–2.5, 3.1–3.3 | AC-6, CM-5, CM-7, SC-7 |
| Data destinations and persistence | 4.1–4.4, 5.1 | AC-4, AC-17, SC-7, SI-12 |
| Evidence and change review | 5.1–5.2 | AU-2, AU-6, AU-9, CM-3 |

NIST's [Rev. 5 publication and current release notes](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) provide the control catalog; [CIS Controls](https://www.cisecurity.org/controls/v8) provide broader control-family context. CIS mappings here are by family name, not unverified safeguard numbers. ISO, PCI DSS and DISA recommendation numbers are not asserted without a verified applicable source.

## Appendix A: Availability and Automation

| Capability | Availability and limitation |
|------------|-----------------------------|
| Enterprise identity and Admin Console | Enterprise root Owner administration; setup may require a Factory-provided WorkOS link. Confirm the contract and pilot the IdP flow. |
| Service accounts | Business/Enterprise support general-purpose accounts. Other plans have a limited Delegations-specific account. Service-account management APIs require human Manager+ credentials. |
| Organization audit log | Enterprise organization Owners only. Runtime telemetry and managed-settings revision history are separate evidence sources. |
| Permission rules and strict plugin policy | Require supported deployed clients and, for native rules, organization rollout activation. Unknown/new fields on older clients do not prove enforcement. |
| Sandboxing | Depends on supported OS primitives. Test the chosen mode and each required tool before rollout. |
| Shield | The guide uses documented secret scanning. It makes no claim that private-preview learned protections are generally available. |

**Automation census (2026-10-31):** sixteen of nineteen controls have a pack, across four implemented surfaces: REST, first-party CLI, official Python SDK and native configuration. Domain/SSO setup, SCM credential/installation association and managed connector availability use documented console and external identity/SCM workflows.

| Surface | Verdict |
|---------|---------|
| Terraform resources and data sources | No official Factory/Droid provider or resource/data-source catalog identified in the official docs and registry search; no Terraform pack fabricated. |
| REST / GraphQL | REST member, service-account/key metadata and paginated control-history reads implemented. Public write operations exist for users, limits and service accounts, but do not configure the managed-policy fields in this guide. No public GraphQL contract identified. |
| First-party CLI | `droid rules check`, MCP inventory/permissions and plugin inventory implemented as read-only collection. |
| Official SDK | Python `droid_sdk.list_models` verifies selectable model IDs without opening a session or making a model call. No organization-policy administration SDK method was identified. |
| Native config | Reviewed organization-policy fragments and input-validated generators. An administrator must merge, validate and deploy the complete policy. |
| SIEM | OTLP export is documented. No assumed SIEM index/table or general audit-event schema is supplied; map the actual ingested schema before writing detections. |

See the [Factory Code Pack README](https://github.com/grcengineering/how-to-harden/blob/main/packs/factory/README.md) for inputs, return codes, safe operation and offline tests. No scanner definitions in the deprecated HTH control-YAML format are added.

## Appendix B: References

- [Enterprise Controls & Managed Settings](https://docs.factory.com/enterprise/hierarchical-settings-and-org-control)
- [Identity & Access](https://docs.factory.com/enterprise/identity-and-access) and [Admin Console](https://docs.factory.com/enterprise/enterprise-admin-console)
- [Permission Rules](https://docs.factory.com/autonomy-and-safety/permission-rules) and [Sandbox](https://docs.factory.com/autonomy-and-safety/sandbox)
- [Droid Shield](https://docs.factory.com/autonomy-and-safety/droid-shield) and [Agent Safety & Controls](https://docs.factory.com/enterprise/llm-safety-and-agent-controls)
- [Connectors](https://docs.factory.com/harness/connectors), [MCP](https://docs.factory.com/harness/mcp), [Internal Plugin Marketplaces](https://docs.factory.com/enterprise/internal-plugin-marketplaces) and [Hooks](https://docs.factory.com/harness/hooks)
- [Factory Public API](https://docs.factory.com/api-reference), [Organization API](https://docs.factory.com/api-reference/organization) and [Service Accounts API](https://docs.factory.com/api-reference/service-accounts)
- [Droid CLI Reference](https://docs.factory.com/droid-cli/cli-reference) and [Python SDK](https://docs.factory.com/sdk/python)
- [Telemetry](https://docs.factory.com/enterprise/telemetry), [Telemetry Privacy](https://docs.factory.com/enterprise/telemetry/privacy) and [Audit Log](https://docs.factory.com/enterprise/audit-log)
- [Data Flows & Privacy](https://docs.factory.com/enterprise/privacy-and-data-flows) and [Compliance Restrictions](https://docs.factory.com/enterprise/compliance-audit-and-monitoring)

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-10-31 | 0.1.0 | ai-drafted | Initial 19-control guide with source evidence, native policy fragments, REST/CLI inventories and SDK model verification; offline validation only. | Codex (GPT-6) |

## Contributing

Report outdated settings or propose improvements through [GitHub issues](https://github.com/grcengineering/how-to-harden/issues). Follow the [contribution guidelines](/contributing/) and include the product edition, client version, source and validation scope with corrections.
