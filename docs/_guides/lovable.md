---
layout: guide
title: "Lovable Hardening Guide"
vendor: "Lovable"
slug: "lovable"
tier: "3"
category: "AI/ML Platform"
description: "Security and privacy hardening for Lovable workspaces and the apps they publish — SSO/SCIM, workspace access governance, AI-agent and MCP surface controls, Lovable Cloud data protection (RLS, secrets, storage), security scanning gates, AI training opt-out, and audit logging."
version: "0.1.0"
maturity: "draft"
last_updated: "2026-08-15"
---

**Plans Covered:** Free, Pro, Business, Enterprise (settings are heavily plan-gated; each control notes its gate)

---

## Overview

Lovable is an AI app builder: prompts in, published full-stack applications out, with a managed backend (Lovable Cloud, built on Supabase's open-source foundation) or a connected Supabase project behind them. That makes its security surface unusual in two ways.

First, **the workspace is an AI-agent governance problem**. Prompts, uploaded files, and generated code flow through Lovable's AI gateway to third-party model providers; MCP clients and connectors can reach into the workspace; and on Free/Pro plans, **customer content is used for AI model training by default starting September 9, 2026** — with only a per-member opt-out. Second, **the published apps are a data-exposure problem the platform formally leaves to you**: CVE-2025-48757 (CVSS 9.3) documented Lovable-generated apps whose missing Row-Level Security let unauthenticated attackers read *and write* arbitrary tables, and Lovable's response placed responsibility for data protection on each customer. The controls exist — RLS review, security scans, a publish-blocking gate — but most ship disabled.

There is **no admin API and no CLI**: apart from SCIM provisioning (Enterprise), every control in this guide is console-only, and that honest constraint shapes the automation story throughout.

### Intended Audience

- Security engineers governing Lovable adoption in an organization
- Workspace owners/admins on any plan
- GRC teams assessing AI app-builder ("vibe coding") platforms
- Builders publishing apps that hold real user data

### How to Use This Guide

- **L1 (Crawl):** Essential controls for every workspace
- **L2 (Walk):** Enhanced controls for security-sensitive teams
- **L3 (Run):** Strictest controls for regulated environments
- **L4 (Fly):** Maximum-assurance controls (rare)

### Scope

Covers the Lovable workspace (identity, membership, project access, publishing, integrations, AI/MCP surfaces, privacy, audit) and the security configuration of apps built on Lovable Cloud. For projects connected to your own Supabase project, authentication settings live in the Supabase dashboard — this guide covers the Lovable side and hands off explicitly. Does not cover general Supabase hardening, prompt-engineering technique, or Lovable's internal infrastructure.

---

## Table of Contents

1. [Identity & Authentication](#1-identity--authentication)
2. [Workspace Access Governance](#2-workspace-access-governance)
3. [AI Agent & Integration Surfaces](#3-ai-agent--integration-surfaces)
4. [Data Protection](#4-data-protection)
5. [Published App Security](#5-published-app-security)
6. [Privacy & AI Training](#6-privacy--ai-training)
7. [Monitoring & Audit](#7-monitoring--audit)
8. [Compliance Quick Reference](#8-compliance-quick-reference)

---

## 1. Identity & Authentication

### 1.1 Verify Your Domain (Foundation for SSO, SCIM, and Provisioning)

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 5.6, 6.7 |
| NIST 800-53 | IA-2, AC-2 |

#### Description
Domain verification (DNS TXT record) is the prerequisite for every serious identity control in Lovable: SSO configuration, Enforce SSO, SCIM (Enterprise), verified-email auto-provisioning, and branded app URLs. Verify your domain deliberately — and understand its two sharp edges: verification is a **one-time check** that is never re-validated, and **another workspace can verify the same domain**.

#### Rationale
**Why This Matters:**

- Without a verified domain, the workspace cannot enforce SSO — leaving membership on invite links and per-account passwords
- First verification **auto-activates "Verified email sign-up" with editor-level default access** — anyone with an email on your domain can join as an editor unless you review and downgrade that default
- Because the same domain can be verified by multiple workspaces, domain verification alone is not proof of organizational control — govern which workspace is canonical

**Attack Prevented:** Unauthorized workspace joins via unmanaged sign-up paths; shadow workspaces claiming your domain

#### Prerequisites
- Business or Enterprise plan; workspace admin/owner; access to your DNS zone

#### ClickOps Implementation
1. **Settings → Access → Identity → Verified domains** → add your domain
2. Create the DNS TXT record: Host `@`, value = the full `lovable_verification=` token shown; wait for propagation (up to 72h), then click **Verify domain**
3. Immediately review the auto-activated **Verified email sign-up** setting and downgrade its default role (or disable it) to match your joiner policy

**Time to Complete:** ~30 minutes plus DNS propagation

#### Validation & Testing
1. The domain shows **Verified** under Settings → Access → Identity
2. Test that a new same-domain sign-up receives the role you intended (not an unreviewed editor default)

**Expected result:** Domain verified, sign-up defaults deliberate, SSO/SCIM unlocked.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | IA-2, AC-2 | Identification; account management |
| **ISO 27001:2022** | 5.16 | Identity management |

---

### 1.2 Enforce SSO with Short Sessions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.7, 12.5 |
| NIST 800-53 | IA-2, IA-8, AC-12 |

#### Description
Configure OIDC (Lovable's recommended protocol) or SAML 2.0 against Okta, Auth0, Microsoft Entra ID, or any compliant IdP, then enable **Enforce SSO** so every workspace member must authenticate through your IdP. Set the session duration to the shortest workable window (options: 8h, 24h, 48h, 7 days).

#### Rationale
**Why This Matters:**

- Lovable has **no workspace-wide 2FA enforcement** (2FA is per-account, see 1.4) — Enforce SSO with IdP-side MFA is the *only* way to guarantee MFA for all members
- When SSO is enforced, external collaborators and invite links become unavailable — collapsing the unmanaged-access surface in one move
- JIT provisioning with IdP group→role mappings (plus optional Group restriction) keeps role assignment in your directory, not in ad-hoc invites

**Attack Prevented:** Credential-stuffing and phished-password account takeover; membership sprawl outside the IdP

#### Prerequisites
- Business or Enterprise plan; verified domain (1.1); workspace owner/admin

#### ClickOps Implementation
1. **Settings → Access → Identity** (lovable.dev/settings/identity) → configure **OIDC** (recommended) or **SAML 2.0** with your IdP
2. Map IdP groups to workspace roles; set the JIT default role to the least privilege that works (viewer)
3. Enable **Enforce SSO**; set **Session duration** to 8h (L2+) or 24h (L1)

**Time to Complete:** ~1–2 hours

#### Validation & Testing
1. A member signing in with email/password is redirected to the IdP
2. Confirm invite links and external collaborators are unavailable while enforcement is on

**Expected result:** All members authenticate via the IdP (with its MFA), sessions expire on your schedule.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | IA-2(1), IA-8, AC-12 | MFA via federation; session termination |
| **ISO 27001:2022** | 5.17, 8.5 | Authentication; secure log-on |

---

### 1.3 Automate Joiner/Leaver Flow with SCIM

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 5.1, 5.3, 6.1, 6.2 |
| NIST 800-53 | AC-2, AC-2(3) |

#### Description
SCIM provisioning (Enterprise) syncs users and groups from Okta, Microsoft Entra ID, or any SCIM 2.0 IdP to Lovable, and — critically — **deprovisions on IdP deactivation**: the user is removed from the workspace and blocked from logging in. The SCIM API at `https://api.lovable.dev/scim/v2` is Lovable's only documented programmatic admin surface.

#### Rationale
**Why This Matters:**

- IdP-driven deprovisioning is the tested leaver kill-switch — no manual removal race when someone departs
- Group mappings (viewer/editor/admin) keep roles synchronized with your directory; the default role catches unmapped users — set it to viewer
- The SCIM API token is **shown only once** and is rotatable — treat it as a privileged credential (audit-log events carry API-key attribution)

**Attack Prevented:** Orphaned access after offboarding; role drift between directory and workspace

#### Prerequisites
- Enterprise plan; active SSO (1.2); verified domain (1.1); workspace owner/admin

#### ClickOps Implementation
1. **Settings → Access → Identity → SCIM provisioning** → enable; record the generated API key (shown once; **Rotate** here if ever exposed)
2. Configure your IdP with base URL `https://api.lovable.dev/scim/v2` and the token; map IdP groups to Lovable roles; set the default role to viewer
3. Note: disabling SCIM stops provisioning but **does not remove existing members** — removals still need review

#### Code Implementation

{% include pack-code.html vendor="lovable" section="1.3" %}

#### Validation & Testing
1. Deactivate a test user in the IdP → confirm they are removed from the workspace and blocked from login
2. Run the SCIM access-review pack to list provisioned users/groups and reconcile against the directory

**Expected result:** Workspace membership mirrors the IdP; leavers lose access automatically.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-2(3) | Disable accounts (automated) |
| **ISO 27001:2022** | 5.18 | Access rights |

---

### 1.4 Require 2FA on Every Account (Especially Below Business)

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.3, 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Lovable 2FA is **per-account, not per-workspace** — there is no admin toggle to require it. Every member (all plans) should enable it themselves, preferring the authenticator app (TOTP) over SMS. On Free/Pro workspaces, where Enforce SSO is unavailable, this is the only MFA you can get.

#### Rationale
**Why This Matters:**

- Workspaces below Business have no SSO — a phished password on an admin account is otherwise game over
- **Lovable provides no backup/recovery codes**; losing all enrolled methods means proving account ownership to Lovable Support — so the doc's own advice stands: keep **at least two active methods** enrolled
- Owner/admin accounts can delete the workspace and every project in it — MFA on those accounts is non-negotiable

**Attack Prevented:** Account takeover via credential phishing or password reuse

#### ClickOps Implementation
1. Each member: **Settings → Your account → Two-factor authentication** → enable **Authenticator app (recommended)**; optionally add **Phone (SMS)** as the second method
2. Admins: track enrollment manually (there is no enforcement dashboard) — make it a joiner-checklist item; on Business/Enterprise prefer Enforce SSO (1.2) with IdP MFA instead

#### Validation & Testing
1. Sign-in on a fresh session prompts for the TOTP code
2. Confirm two methods are enrolled per the lockout guidance

**Expected result:** All accounts (at minimum all owners/admins) carry MFA.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | IA-2(1) | Multi-factor authentication |
| **ISO 27001:2022** | 5.17 | Authentication information |

---

## 2. Workspace Access Governance

### 2.1 Right-size Roles and Member Lifecycle

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 5.4, 6.1 |
| NIST 800-53 | AC-6, AC-2 |

#### Description
Lovable has five workspace roles — Owner, Admin, Editor, Viewer, and (external, project-scoped) Collaborator. Keep owners to a governed minimum (inviting additional owners requires Business/Enterprise), default new members to viewer, and use the documented lifecycle semantics: email invites expire after 30 days, invite links after 5 days, and removal revokes access immediately with owned projects auto-transferring to the most senior remaining member.

#### Rationale
**Why This Matters:**

- Owners hold full control including owner management and workspace deletion; admins manage everything except owners — both are takeover-grade accounts to minimize
- Editors can invite viewers and external collaborators — meaning **editor count is also your invitation surface** unless restricted (2.2)
- Auto-transfer on removal means projects never orphan, but also that seniority silently inherits data access — review transfers after offboarding

**Attack Prevented:** Privilege sprawl; lingering access through stale invites

#### ClickOps Implementation
1. **Settings → Access → People** → audit each member's role; demote to the least role that works (viewer for read-only stakeholders)
2. Cancel stale pending invites; on paid plans use viewer/admin tiers deliberately
3. On Business/Enterprise, use **Settings → Access → Groups** to grant project/folder access by group (SCIM-syncable), and set **Default monthly member credit limit** (Settings → General) as a resource-abuse cap

#### Validation & Testing
1. The People list shows no unexplained admins/owners and no expired-but-pending invites
2. A removed test member loses access immediately; their projects transfer as documented

**Expected result:** Least-privilege membership with governed lifecycle.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-6, AC-2 | Least privilege; account management |
| **ISO 27001:2022** | 5.18, 8.2 | Access rights; privileged access |

---

### 2.2 Lock Down Invitations, Invite Links, and Workspace Discovery

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 5.4, 6.1 |
| NIST 800-53 | AC-2, AC-6 |

#### Description
Three settings govern how people get in: **Restrict workspace invitations** (Enterprise; only admins/owners may invite by email), the **Invite links** toggle (Free/Pro/Business; shareable join links, 5-day expiry, one active per role), and **Workspace discovery** (Business/Enterprise, default **enabled**; verified-domain users can discover and request access). Harden all three.

#### Rationale
**Why This Matters:**

- Invite links are bearer credentials — anyone holding the URL joins at the link's role; disable them where SSO/SCIM handles joining
- Workspace discovery is enumeration surface: it advertises the workspace to everyone on the domain — turn it off unless you rely on request-to-join flows
- With invitations restricted, membership converges on the governed paths (SSO JIT, SCIM, admin invites) — the auditable ones

**Attack Prevented:** Uncontrolled joins via leaked invite links; social-engineering via discovery/request-access flows

#### ClickOps Implementation
1. **Settings → Security → Privacy & security → Restrict workspace invitations** → enable (Enterprise)
2. Same page → **Invite links** → disable (or accept the 5-day/one-per-role limits knowingly)
3. Same page → **Workspace discovery** → disable; also review **Public member profiles** (Enterprise, default disabled — keep it off)

#### Validation & Testing
1. A non-admin editor cannot generate an email invite or an invite link
2. A same-domain outsider can no longer discover the workspace

**Expected result:** Every join flows through an admin- or IdP-governed path.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-2, AC-6 | Account management; least privilege |
| **ISO 27001:2022** | 5.18 | Access rights |

---

### 2.3 Default Projects to Restricted; Govern External Collaborators

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.3, 6.8 |
| NIST 800-53 | AC-3, AC-6 |

#### Description
Set **Default project access** from Workspace (every member can view/remix/edit per role — the default) to **Restricted** (owner + invited collaborators only; Business/Enterprise), and constrain **External project collaborators** (default "Allow all") to the narrowest workable option. Workspace owners retain full access regardless — that residual is by design.

#### Rationale
**Why This Matters:**

- Workspace-wide default access means any member — and anything acting as a member — can open any project, including ones holding production schemas and chat history
- External collaborators are project-scoped but outside your identity governance; "Allow all" lets any editor pull outsiders into any project
- Restricted-by-default converts data access from ambient to deliberate, which is also what your auditors will ask for

**Attack Prevented:** Intra-workspace data exposure; unsanctioned external access to source and data

#### Prerequisites
- Business or Enterprise for Restricted default and the external-collaborators setting

#### ClickOps Implementation
1. **Settings → Security → Privacy & security → Default project access** → **Restricted**
2. Same page → **External project collaborators** → **Allow viewers** or **None allowed** (L3: None)
3. Per-project overrides stay available via the project **Share** dialog — audit them, including project-level Admin grants (paid plans)

#### Validation & Testing
1. A new project is visible only to its owner and explicit invitees
2. An editor attempting to add an external collaborator hits the policy

**Expected result:** Project access is explicit, external access is bounded.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-3, AC-6 | Access enforcement; least privilege |
| **ISO 27001:2022** | 5.15, 8.3 | Access control; information access restriction |

---

### 2.4 Control Who Can Publish and Who Can View Published Apps

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.3, 4.2 |
| NIST 800-53 | AC-3, CM-5 |

#### Description
Publishing is the moment a project becomes an internet-facing app. Constrain **Who can publish externally** (Enterprise; default "Editors and above" → tighten to "Admins and owners" or "Owners only"), set **Default website access** (Business/Enterprise; default "Anyone" → "Workspace"), and use the per-project **Who can view your site?** picker (Public | Workspace | Custom with invited people/groups/external emails). On Free/Pro, published apps are **always public** — plan accordingly.

#### Rationale
**Why This Matters:**

- The default lets every editor put an app on the public internet under your brand — a change-control gap in regulated teams
- Workspace-visibility publishing turns Lovable into a viable internal-tools platform: viewers must authenticate as members
- "External invites" (default enabled) lets members email outside viewers into internally published apps — govern it with the same care as external collaborators

**Attack Prevented:** Unreviewed public exposure of internal apps and their data

#### Prerequisites
- Business/Enterprise for non-public website access; Enterprise for the publish-permission setting

#### ClickOps Implementation
1. **Workspace settings → Privacy & security → Who can publish externally** → **Admins and owners** (L2) or **Owners only** (L3)
2. Same page → **Default website access** → **Workspace**; review **External invites** (disable at L3)
3. Per project: Publish dialog → visibility row → **Who can view your site?** → the narrowest audience; unpublish stale apps (**Project settings → Unpublish project**)

#### Validation & Testing
1. An editor's Publish attempt on an external target is blocked by policy
2. A published internal app demands workspace sign-in from an incognito session

**Expected result:** Publishing is a governed act; internal apps are actually internal.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | CM-5, AC-3 | Access restrictions for change; access enforcement |
| **ISO 27001:2022** | 8.32 | Change management |

---

### 2.5 Harden the GitHub Integration

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.3, 4.6 |
| NIST 800-53 | AC-6, CM-5 |

#### Description
The Lovable GitHub App requests **Contents (write), Metadata (read), Pull requests (write), Workflows (write), and Administration (write — to create repositories)**. Install it with **"Only select repositories"**, never "All repositories", and use the documented role gating (workspace owners/admins install and manage connections). Repositories created by Lovable are private by default on every plan.

#### Rationale
**Why This Matters:**

- Workflows-write plus Contents-write on all repositories would make the Lovable app a supply-chain pivot into your CI — scope the install to the repos it syncs
- Administration-write exists so Lovable can create repos; on an org-wide install that is repo-creation authority for a third-party app
- For GitHub Enterprise Server/data-residency (Enterprise plan), Lovable publishes its egress IP ranges in the setup wizard — add them to the GitHub org **IP allow list** rather than opening the org

**Attack Prevented:** Third-party-app blast radius across your GitHub org; unreviewed workflow modification

#### ClickOps Implementation
1. **Workspace settings → Git → GitHub → Add connection** (owners/admins) → during the GitHub install choose **Only select repositories**
2. Review the granted permissions against the documented list; re-scope any legacy all-repositories install
3. GHES/GHEC-DR (Enterprise): add Lovable's setup-wizard IP ranges to **GitHub organization → Settings → Security → IP allow list**

#### Validation & Testing
1. The GitHub App's installation page lists only the intended repositories
2. Two-way sync works on the connected repo's single active branch

**Expected result:** Lovable's GitHub reach is scoped to exactly the repos it needs.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-6, CM-5 | Least privilege; change restrictions |
| **ISO 27001:2022** | 5.19, 8.30 | Supplier relationships; outsourced development |

---

## 3. AI Agent & Integration Surfaces

### 3.1 Govern Connectors (and Know Their Enforcement Boundary)

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.8, 15.2 |
| NIST 800-53 | AC-20, SA-9 |

#### Description
Connectors wire projects (and the AI agent) to external services. On Business/Enterprise, **Connectors → Admin settings** exposes per-connector **"Who can create connections and clients"** (No one | Admins | Editors & admins) across two tabs (App + chat connectors; App user connectors). Enterprise defaults to **No one** — keep it that way and enable per-connector on demand. **Critical boundary:** connector access controls are **not enforced after publishing** — a published app keeps using its connections regardless of later admin-setting changes.

#### Rationale
**Why This Matters:**

- Every connector is a credential-bearing egress path; token storage is encrypted and unreadable (even to admins and the agent), but *creation* rights determine who can open new paths
- Because governance applies at build time only, the admin setting is a gate, not a runtime revocation — to actually cut a published app off, **delete the connection** (which removes its secrets and stops dependent apps)
- Rate limiting (1,000 req/min per connector per project) bounds runaway agent loops but not data sensitivity — the creation policy is your real control

**Attack Prevented:** Unsanctioned third-party data flows opened by any editor; token sprawl

#### Prerequisites
- Business or Enterprise for admin settings (Free/Pro: any editor+ can create connections)

#### ClickOps Implementation
1. **Connectors → Admin settings** → for each connector on both tabs, set **Who can create connections and clients** to **No one** (enable per-request) or **Admins**
2. Review existing connections' usage scope (Only you | Invite specific people | Invite entire workspace) — narrow the workspace-wide ones
3. To revoke a published app's external access: delete the connection itself, not just the admin setting

#### Validation & Testing
1. An editor's attempt to create a new connection is blocked by the policy
2. Deleting a test connection stops the dependent app's integration immediately

**Expected result:** New external data flows require admin action; revocation semantics are understood.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-20, SA-9 | Use of external systems; external services |
| **ISO 27001:2022** | 5.19, 5.23 | Supplier relationships; cloud services security |

---

### 3.2 Restrict MCP Surfaces (Third-Party Clients, Remote Connectors, Local Servers)

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.8, 15.2 |
| NIST 800-53 | AC-20, CM-7 |

#### Description
Three Privacy & security toggles govern Model Context Protocol reach into the workspace: **Third-party MCP clients** (Claude Desktop, Cursor, etc. connecting via Lovable's MCP server at `mcp.lovable.dev`; default enabled on Business, disabled on Enterprise), **Remote MCP connectors** (members connecting external MCP servers; default enabled), and **Local desktop MCP servers** (desktop-app users attaching local servers; default enabled, disabled on Enterprise). Disable all three unless a governed use case exists.

#### Rationale
**Why This Matters:**

- The Lovable MCP server exposes real capability — project creation/deployment, visibility changes, file reads, `query_database`, analytics — to any OAuth-authorized external AI client; on Free/Pro it is always available, so Business/Enterprise gating is your only off-switch
- Remote and local MCP servers are member-attached code with access to project context — an unvetted-tool supply-chain surface
- Enterprise defaults (disabled) reflect the vendor's own risk read — mirror them on Business

**Attack Prevented:** Workspace data egress and project manipulation through external AI clients and unvetted MCP servers

#### Prerequisites
- Business or Enterprise (toggles are not configurable below that)

#### ClickOps Implementation
1. **Settings → Security → Privacy & security → Third-party MCP clients** → disable (enable narrowly if a sanctioned client workflow exists)
2. Same page → **Remote MCP connectors** → disable
3. Same page → **Local desktop MCP servers** → disable

#### Validation & Testing
1. An external MCP client's OAuth connection attempt fails while the toggle is off
2. Members cannot attach new remote/local MCP servers to projects

**Expected result:** MCP reach into the workspace is deliberate, not default.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-20, CM-7 | External systems; least functionality |
| **ISO 27001:2022** | 5.23, 8.19 | Cloud services; software installation |

---

### 3.3 Treat Workspace Knowledge and Cross-Project Sharing as Privileged Configuration

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.3, 4.1 |
| NIST 800-53 | CM-5, AC-3 |

#### Description
Workspace Knowledge/Skills (Settings → Customization, owner/admin-managed) inject instructions into **every project's** AI context — they steer the agent workspace-wide. **Cross-project sharing** (all plans, default enabled) lets members reference and reuse implementations from other projects. For segregated teams or regulated work, disable cross-project sharing and change-control the knowledge base.

#### Rationale
**Why This Matters:**

- Workspace knowledge is prompt-injection-shaped by design: whoever edits it programs the agent for everyone — treat edits like CI-config changes
- Cross-project sharing moves code (and the context embedded in it) across project boundaries you may have deliberately drawn in 2.3
- Both surfaces are invisible in day-to-day use — they belong in your periodic access review

**Attack Prevented:** Workspace-wide agent manipulation via knowledge edits; cross-boundary code/context leakage

#### ClickOps Implementation
1. **Settings → Security → Privacy & security → Cross-project sharing** → disable for segregated environments
2. **Settings → Customization** → review Workspace Knowledge/Skills; restrict editing to owners/admins and log changes through your change process (audit-log Projects/workspace-management events cover this on Enterprise)

#### Validation & Testing
1. A member cannot pull implementation context from a sibling project while sharing is off
2. Knowledge edits appear in the audit log and match approved changes

**Expected result:** The agent's standing instructions and cross-project flows are governed.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | CM-5, AC-3 | Change restrictions; access enforcement |
| **ISO 27001:2022** | 8.32 | Change management |

---

## 4. Data Protection

### 4.1 Manage Secrets the Platform's Way (and Rotate on Exposure)

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.11, 16.9 |
| NIST 800-53 | SC-12, SC-28, IA-5 |

#### Description
Project secrets live at **Cloud tab → Secrets**: encrypted, injected into Edge Functions automatically, never reaching the browser, and **write-only after save** (view shows name + creation date only). The reserved `SUPABASE_`/`LOVABLE_` prefixes are platform-managed; the project's `LOVABLE_API_KEY` is rotatable in place. The sharp edge: **`VITE_`-prefixed variables are build-time and browser-exposed — never put secrets there.** Enterprise adds workspace-level **Build secrets** (Settings → Build & deploy) for private-registry/CI-type credentials.

#### Rationale
**Why This Matters:**

- The most common AI-generated-app leak is a secret pasted into frontend code; Lovable auto-detects API keys pasted into chat and routes them to Secrets + Edge Functions — but the `VITE_` path remains a self-inflicted bypass
- Write-only semantics mean an exposed value can't be re-read from the console — rotation (not inspection) is the response: **Rotate** on `LOVABLE_API_KEY` re-issues and updates the Edge Function environment automatically
- Build secrets separate registry/CI credentials from runtime app secrets, with role-scoped visibility (editors see names read-only)

**Attack Prevented:** Secret exposure via client bundles; stale compromised credentials

#### ClickOps Implementation
1. **Cloud tab → Secrets** → keep every credential here; audit for anything mirrored into `VITE_` variables or source
2. On suspected exposure: **Rotate** (`LOVABLE_API_KEY`) or replace the secret value (replace-only by design)
3. Enterprise: **Settings → Build & deploy → Build secrets** for `.npmrc`-style `${SECRET_NAME}` injection during builds

#### Validation & Testing
1. The published app's browser bundle contains no secret values (search the served JS)
2. Deep scan (5.3) reports no exposed-secret findings

**Expected result:** Secrets are server-side, write-only, and rotated on exposure.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | IA-5, SC-28 | Authenticator management; protection at rest |
| **ISO 27001:2022** | 8.24 | Use of cryptography |

---

### 4.2 Keep Storage Buckets Private (Verify the Default)

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.3 |
| NIST 800-53 | AC-3, SC-28 |

#### Description
**Block public storage buckets** (all plans) is **default enabled** — new Lovable Cloud buckets are private, governed by database-layer RLS, and file links are one-hour signed URLs. Public buckets serve permanent public URLs and can only be unblocked by workspace owners/admins. Verify the block is still on, and treat any unblocking as an exception with an owner.

#### Rationale
**Why This Matters:**

- Public buckets are the classic accidental-exposure primitive; the platform default is right — your job is to keep it and catch exceptions
- Private-bucket access rides the same RLS layer as the database (5.1) — storage exposure and table exposure are the same failure class
- Signed-URL expiry (1 hour) limits link-forwarding leakage from private buckets

**Attack Prevented:** Unauthenticated harvesting of uploaded files (documents, images, exports)

#### ClickOps Implementation
1. **Settings → Security → Privacy & security → Block public storage buckets** → confirm **enabled**
2. **Cloud tab → Storage** → inventory buckets; any public bucket needs a documented owner and reason (bucket names are immutable; deletion requires an empty bucket and is irreversible)

#### Validation & Testing
1. Creating a public bucket as a non-admin fails while the block is on
2. A private bucket's copied file URL stops working after one hour

**Expected result:** All buckets private unless deliberately excepted.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-3, SC-28 | Access enforcement; protection at rest |
| **ISO 27001:2022** | 8.3, 8.12 | Information access restriction; data leakage prevention |

---

### 4.3 Turn On Sensitive-Data Scanning and Chat Send Protection

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.1, 3.13 |
| NIST 800-53 | SI-4, SC-7(10) |

#### Description
Enterprise workspaces get a DLP layer, **disabled by default**: **Sensitive data scanning** (identity, financial, government-ID, medical, and security data — passwords, API keys, auth secrets — across chat, file uploads, chat history, sampled Cloud database rows, and storage buckets), **Chat send protection** (Off | Log only — the default | Ask before sending | Block original), and **Block publishing with PII** (unresolved findings stop publish/update).

#### Rationale
**Why This Matters:**

- Builders paste production data into AI chat — that is the workflow, not an anomaly; "Log only" records it, **"Ask before sending"/"Block original"** actually intervenes
- Database-row and bucket sampling catches PII that arrived through the app, not just through chat — the scan follows the data, not the door
- The publish gate turns findings into a hard control instead of a report

**Attack Prevented (privacy):** PII/credential leakage into prompts, model providers, and published apps

#### Prerequisites
- Enterprise plan; workspace owner/admin

#### ClickOps Implementation
1. **Settings → Privacy & security → Sensitive data scanning** → enable
2. Same page → **Chat send protection** → **Ask before sending** (L3) or **Block original** (L4)
3. Same page → **Block publishing with PII** → enable; editors triage findings (false-positive, redact, delete) per project

#### Validation & Testing
1. Sending a test credit-card-formatted string in chat triggers the configured mode
2. A project with an unresolved finding cannot publish while the gate is on

**Expected result:** Sensitive data is detected — and blocked — before it leaves.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SI-4, SC-7(10) | Monitoring; prevent exfiltration |
| **ISO 27001:2022** | 8.12 | Data leakage prevention |

---

### 4.4 Set Data-Boundary Controls: Code Downloads, Transfers, Region, Abandoned Projects

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.4, 3.1 |
| NIST 800-53 | AC-4, SI-12 |

#### Description
Four Enterprise/Business boundary settings finish the data story: **Code downloads** (Enterprise, default enabled — disable so only admins/owners can export source zips), **Editor project transfers** (default disabled — keep it off so editors cannot move/remix projects into other workspaces), **Default hosting region** (Business/Enterprise — Americas | Europe | Asia Pacific, new projects only), and the **Abandoned projects** lifecycle (Enterprise — mark after 60 idle days; optional auto-delete with 7/14/30-day grace).

#### Rationale
**Why This Matters:**

- Source export and cross-workspace transfer are the two doors data walks out of when someone leaves — closing both makes offboarding (1.3) complete
- Hosting region is a compliance commitment; it must be set **before** projects are created (it never applies retroactively)
- Idle projects hold real data behind forgotten access lists — the abandoned-project sweep is attack-surface reduction, with export-first discipline (database export caps: 5 GB, one per 24h; backups: daily, ~14-day retention; restores are permanent)

**Attack Prevented:** Data exfiltration via export/transfer; stale-project exposure; residency violations

#### ClickOps Implementation
1. **Settings → Security → Privacy & security** → **Code downloads** → disable; **Editor project transfers** → keep disabled; consider **Require workspace editor role** for modify rights
2. Same page → **Default hosting region** → set to your jurisdiction before onboarding builders
3. Same page → **Abandoned projects** → enable marking; enable auto-delete with a grace period only after your export runbook exists (**Cloud tab → Advanced settings → Export project data**)

#### Validation & Testing
1. An editor cannot download a source zip or transfer a project out
2. New projects land in the configured region (project settings confirm)

**Expected result:** Data leaves the workspace only through governed, admin-visible paths.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-4, SI-12 | Information flow; information handling |
| **ISO 27001:2022** | 5.14, 8.10 | Information transfer; information deletion |

---

## 5. Published App Security

### 5.1 Enforce Row-Level Security on Every Table Before Go-Live

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.3, 16.1 |
| NIST 800-53 | AC-3, AC-6 |

#### Description
Lovable-built apps call the database from the client, so **RLS policies are the authorization layer** — the vendor's own doc is blunt: "Before going live, make sure every table has Row Level Security policies that restrict who can read and write each row… Missing RLS policies are the most common way app data gets exposed." Review policies at **Cloud tab → Database → RLS policies** (read-only viewer: policy name, command, applies-to, rule expression; changes go through chat requests). For connected-Supabase projects, verify in the Supabase dashboard — auth settings live there, not in Lovable.

#### Rationale
**Why This Matters:**

- **CVE-2025-48757** (CVSS 9.3, researcher Matt Palmer): Lovable-generated apps with missing/weak RLS were readable **and writable** by unauthenticated attackers — reported scope ~10% of scanned projects. Lovable disputed the CVE, stating each customer "accepts a responsibility over protecting the data of their application" — which makes RLS review *your* control, formally
- The Basic scan lints RLS ("overly permissive rules or missing access checks"); the Deep scan additionally detects **database functions that bypass RLS** — run both before any launch (5.3)
- Client-side auth state is UI, not enforcement: "All authentication decisions must happen server-side" — RLS plus Edge-Function checks are that server side

**Real-World Incidents:**

- **CVE-2025-48757 (2025):** unauthenticated read/write to arbitrary tables of generated sites via insufficient RLS — the defining incident class for this platform

**Attack Prevented:** Unauthenticated database read/write on published apps

#### ClickOps Implementation
1. **Cloud tab → Database → RLS policies** → verify every table (filter by Tables/Storage/Realtime) has policies restricting each command to the right principals
2. Ask the agent to review ("Make sure users can only see and edit their own data") — then **verify yourself**; for connected Supabase, confirm in the Supabase dashboard
3. Follow Lovable's pre-launch checklist: no secrets in frontend, validation and critical logic in Edge Functions, auth enforced server-side, external API calls server-side

#### Validation & Testing
1. As an unauthenticated client, table reads/writes fail; as user A, user B's rows are invisible
2. Basic + Deep scans report no RLS/access-control errors

**Expected result:** Every table's access is policy-enforced; scans agree.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-3, AC-6 | Access enforcement; least privilege |
| **ISO 27001:2022** | 8.3, 8.26 | Access restriction; application security requirements |

---

### 5.2 Harden App Authentication (Lovable Cloud)

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.2, 16.2 |
| NIST 800-53 | IA-2, IA-5, SC-23 |

#### Description
For apps on Lovable Cloud, end-user authentication is configured at **Cloud tab → Users → Auth settings**. Harden email auth (disable auto-confirm, secure email change, minimum password length ≥8 with required character classes, **Password HIBP check** against breached passwords, re-authentication before password change, tight OTP expiry/length), restrict enabled providers, lock down **Redirect URLs** (up to 50), and use **Disable sign-up** for closed apps. Workspace policy can restrict **App login methods** across all workspace apps (Business/Enterprise — e.g., SAML SSO only for internal tools).

#### Rationale
**Why This Matters:**

- Auto-confirmed emails and 6-character passwords are the shipped defaults of least resistance — each toggle here removes a standard account-takeover path; HIBP checking alone kills the reused-breached-password class
- Open redirect-URL lists are OAuth-token-leak surface; the allowlist (plus Site URL) is the fix — and the documented cause when "sign-in works in preview but breaks on the published domain"
- Workspace-level login-method restriction turns per-project auth choices into policy (SAML-only internal apps)

**Attack Prevented:** End-user account takeover; OAuth redirect abuse; unwanted self-registration

#### ClickOps Implementation
1. **Cloud tab → Users → Auth settings → Email** → disable auto-confirm; enable secure email change, HIBP check, re-auth for password change; set min length ≥8 + character classes; tighten OTP expiry
2. **Auth settings** → disable unused providers; **Advanced** → set Site URL + explicit Redirect URLs; **Disable sign-up** for closed apps; review email sending limits
3. Workspace: **Settings → Security → Privacy & security → App login methods** → restrict to approved methods

#### Validation & Testing
1. A breached-list password is rejected at sign-up; unverified emails cannot sign in
2. An unlisted redirect URL is refused during OAuth

**Expected result:** App auth resists takeover by default across every workspace app.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | IA-5(1), SC-23 | Password-based authentication; session authenticity |
| **ISO 27001:2022** | 5.17, 8.26 | Authentication; application security |

---

### 5.3 Make Security Scans a Publish Gate

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 16.12, 7.5 |
| NIST 800-53 | RA-5, SA-11 |

#### Description
Lovable ships two free scanners: **Basic scan** (10–15s; RLS policy linting, schema/access review, npm dependency audit — runs automatically in the publish dialog) and **Deep scan** (~4 min; agentic review adding access-control analysis, unauthenticated-endpoint detection, exposed secrets, unsafe input handling). Two workspace settings convert them from advice into control: **Block publishing with critical findings** (all plans, default **disabled**) and **Auto-fix security issues** (scope up to All projects; auto-remediates error-level Basic findings). Wiz (SCA/SAST) and Aikido (DAST) integrations can feed the same findings view.

#### Rationale
**Why This Matters:**

- The publish-time Basic scan is the platform's answer to CVE-2025-48757-class exposure — but without the blocking toggle, a builder can ship past red findings
- Deep scan catches what config linting can't: edge functions lacking auth, RLS-bypassing database functions, injected secrets
- "Try to fix all" and auto-fix lower the cost of remediation to near zero (shared pool of 10 free fixes, then credits) — there is no economic excuse for shipping criticals

**Attack Prevented:** Publishing apps with known-critical exposure (missing RLS, open endpoints, leaked secrets)

#### ClickOps Implementation
1. **Settings → Security → Privacy & security → Block publishing with critical findings** → **enable** (all plans — do this on day one)
2. Same page → **Auto-fix security issues** → scope to **All published projects** (L2) after piloting
3. Per project: **More → Security** → run Deep scan before launch; resolve Errors; use **Edit security memory** to document accepted risks

#### Validation & Testing
1. A project with an error-level finding is refused publication
2. Deep scan completes clean (or with documented, accepted non-critical findings) before go-live

**Expected result:** Nothing ships with known-critical findings.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | RA-5, SA-11 | Vulnerability scanning; developer testing |
| **ISO 27001:2022** | 8.29, 8.8 | Security testing; technical vulnerability management |

---

### 5.4 Publish on a Custom Domain (and Know the Shared-Suffix Risk)

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 9.2 |
| NIST 800-53 | SC-8, SC-20 |

#### Description
Production apps should serve from a custom domain (**Project → Settings → Domains** or the Publish dialog; paid plans) — A record to `185.158.133.1` plus a `_lovable` TXT verification record, auto-provisioned certificates, **TLS 1.2+ enforced**. Beyond branding, this moves your app off the shared `*.lovable.app` suffix — where phishing kits demonstrably also live.

#### Rationale
**Why This Matters:**

- Guardio Labs' **VibeScamming** benchmark (2025) scored Lovable weakest of the tested platforms (≈1.8/10) at resisting phishing-kit generation — it produced and *hosted* a Microsoft-lookalike credential harvester on a `login-microsft-com.lovable.app` subdomain, complete with a captured-credentials dashboard and Telegram exfiltration
- Your legitimate app sharing a suffix with such kits inherits reputational and filtering risk; a custom domain separates your trust surface
- Defensively: your security team should monitor for brand-lookalike `*.lovable.app` subdomains as a phishing vector against your users

**Attack Prevented:** Brand impersonation blending with your production URLs; shared-suffix reputation damage

#### ClickOps Implementation
1. **Project → Settings → Domains** → add your domain; create the A record (`185.158.133.1`) and `_lovable` TXT record (`lovable_verify=…`); remove AAAA records
2. Confirm certificate issuance and that TLS 1.0/1.1 clients are rejected (platform-enforced)
3. Add `*.lovable.app` lookalike patterns to your brand-monitoring/anti-phishing watchlist

#### Validation & Testing
1. The app serves on the custom domain with a valid certificate; TLS 1.1 handshakes fail
2. Brand-monitoring alerts cover lovable.app lookalikes

**Expected result:** Production traffic on your domain, with the shared-suffix risk consciously managed.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SC-8, SC-20 | Transmission protection; secure name resolution |
| **ISO 27001:2022** | 8.20 | Network security |

---

## 6. Privacy & AI Training

### 6.1 Opt Out of AI Model Training (Before September 9, 2026 on Free/Pro)

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.1 |
| NIST 800-53 | SI-12, PL-4 |

#### Description
From **September 9, 2026**, Free and Pro customer content — "prompts (including images and files you attach), code, project files, generated outputs, and usage data" — may be used to train Lovable's models, **opted in by default**. The opt-out is **per-member only** (Account settings → AI model training → disable "Use my Lovable content for model training"); an admin cannot opt a Free/Pro workspace out — every member must flip their own toggle, and opting out is **forward-only** (it does not retract prior training data). Business/Enterprise workspace data is excluded by default under DPA; verify the workspace toggle regardless.

#### Rationale
**Why This Matters:**

- Opting out **before** September 9, 2026 prevents any training use; after that date, whatever was collected stays in assembled datasets/models — the deadline is the control
- Because the toggle is per-member on Free/Pro, one un-flipped account leaks the whole team's shared-project content — verify every member or upgrade to a plan with the workspace-level guarantee
- End-user data inside your apps is excluded from training scope — the exposure is your *build* content: prompts, code, uploads

**Attack Prevented (privacy):** Proprietary prompts, code, and files entering third-party model training

#### ClickOps Implementation
1. Every member (Free/Pro): **Account settings → AI model training** → disable **Use my Lovable content for model training** — before 2026-09-09
2. Business/Enterprise admins: **Settings → Security → Privacy & security → Use workspace content for model training** → confirm **disabled** (docs state Business defaults have been inconsistent — verify the toggle, don't trust the default)
3. Make the opt-out a joiner-checklist item on Free/Pro teams

#### Validation & Testing
1. Each member's account toggle reads disabled; the workspace toggle (Business/Enterprise) reads disabled
2. New-member onboarding includes the check

**Expected result:** No workspace content flows into model training.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SI-12, PL-4 | Information handling; rules of behavior |
| **ISO 27001:2022** | 5.34 | Privacy and PII protection |

---

### 6.2 Close the Passive Exposure Channels: Previews, Remixing, Analytics

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.3 |
| NIST 800-53 | AC-3, SI-12 |

#### Description
Three low-visibility channels expose project content or user data: **public preview links** (view-only URLs valid 7 days, guest comments on by default; Enterprise can disable workspace-wide via "Allow public preview links sharing"), **Public remixing** (project-level; when on, anyone with the link copies the latest version *including source code* — off by default, unavailable on Enterprise), and **Visitor analytics** on published apps (auto-collected; disable per project under Project settings → General → Publishing if your privacy posture requires).

#### Rationale
**Why This Matters:**

- Preview links are unauthenticated bearer URLs to your work-in-progress — 7-day validity limits but does not remove the leak window
- A remix copies code and database **schema** (not records) plus optionally chat history — enabling it on a proprietary project is a source-code disclosure decision
- Analytics is privacy-positive as shipped (aggregate, no visitor profiles per the docs) but is still a data-collection surface to declare in your app's privacy notice — or switch off

**Attack Prevented (privacy):** Unintended source/context disclosure via shareable artifacts

#### ClickOps Implementation
1. Enterprise: **Settings → Privacy & security → Allow public preview links sharing** → disable; otherwise train builders to treat preview links as ephemeral secrets
2. Per project: **Project settings → Sharing → Public remixing** → confirm **off** for anything proprietary
3. Per published app: **Project settings → General → Publishing → Visitor analytics** → align with your privacy notice

#### Validation & Testing
1. Preview-link creation fails (Enterprise, disabled) or links expire at 7 days
2. A non-collaborator cannot remix a proprietary project

**Expected result:** No passive disclosure channel is open unknowingly.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-3, SI-12 | Access enforcement; information handling |
| **ISO 27001:2022** | 5.34, 8.12 | Privacy; data leakage prevention |

---

### 6.3 Know the Privacy Floor: Providers, Telemetry, Retention

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.1, 15.1 |
| NIST 800-53 | SI-12, SA-9 |

#### Description
Some privacy realities have **no console toggle** and belong in your risk register instead: prompts and related content transit Lovable's AI Gateway to third-party providers (the privacy policy names OpenAI, Google Gemini, and models via OpenRouter — pass-through, "we do not store the raw prompts… unless you explicitly save them"); there is **no admin control over which LLM subprocessor processes prompts and no zero-data-retention option** documented; Lovable's own product telemetry (PostHog; prompts-submitted/build/deploy events) has **no in-app off-switch** — only cookie consent, browser controls, and Global Privacy Control. Retention commitments: log data ≤90 days, customer data ≤90 days post-deletion, account deletion within 30 days of request (30-day grace), workspace deletion 60-day grace then permanent removal including integration keys/tokens.

#### Rationale
**Why This Matters:**

- What you cannot configure you must contract: Enterprise buyers should route model-provider constraints and ZDR requirements through the DPA — the console will not do it
- The pass-through claim is a policy commitment, not a setting — treat prompts as data shared with the named providers and govern *what goes into them* (4.3 is your enforcement layer)
- Deletion timelines (30/60/90-day) belong in your records-retention and offboarding docs verbatim

**Attack Prevented (privacy):** Compliance surprises — undisclosed processor flows and retention mismatches

#### ClickOps Implementation
1. Record the AI Gateway provider list and retention terms in your vendor-risk file; for Enterprise, negotiate provider/ZDR terms in the DPA
2. Enable Global Privacy Control in managed browsers if honoring CPRA opt-outs matters to your users
3. Pair with 4.3 (DLP) and 6.1 (training opt-out) — the configurable layers over this floor

#### Validation & Testing
1. Vendor-risk documentation reflects the current privacy policy (re-verify on policy updates)
2. DPA terms cover model subprocessors for Enterprise deployments

**Expected result:** The non-configurable privacy surface is documented, contracted, and compensated for.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SA-9, SI-12 | External services; information handling |
| **ISO 27001:2022** | 5.19, 5.34 | Supplier relationships; privacy |

---

## 7. Monitoring & Audit

### 7.1 Operate the Audit Log (13-Week Retention Forces an Export Cadence)

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 8.2, 8.9 |
| NIST 800-53 | AU-2, AU-6, AU-11 |

#### Description
Enterprise audit logs (**Settings → Security → Audit logs**) capture membership, workspace management, groups, identity/access (domain verification, SSO, SCIM), secrets and integrations, project events (including database queries and prompt sending), Lovable Cloud changes, and authentication — with **13-week (~90-day) retention** and **manual JSONL export only** (no API; SIEM integration is an account-team conversation). That retention floor mandates a scheduled export.

#### Rationale
**Why This Matters:**

- 90 days is shorter than most incident-response lookback and many compliance retention requirements — export monthly (minimum) to your own storage or lose the history
- There is no log API: a poller cannot exist; the export button (JSONL, filters respected, links live 7 days) is the mechanism — put it on the calendar
- Expandable event rows carry structured JSON with API-key attribution — enough to reconstruct SCIM-driven changes and secret/integration touches

**Attack Prevented:** Un-investigable incidents; compliance gaps from silent log expiry

#### Prerequisites
- Enterprise plan; owner/admin

#### ClickOps Implementation
1. **Settings → Security → Audit logs** → establish a monthly (L2) or weekly (L3) **Export** → JSONL routine into your evidence store (clear resource filters first — export is unavailable while one is active)
2. Review high-signal categories on a cadence: identity/access changes, secrets and integrations, Cloud storage/auth changes
3. If you need streaming, raise SIEM integration with your account team — do not build against undocumented endpoints

#### Validation & Testing
1. Exported JSONL files land in your store on schedule and parse cleanly
2. A test setting change appears in the log with correct actor attribution

**Expected result:** Continuous, exportable audit coverage beyond the platform's 13-week window.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AU-2, AU-11 | Event logging; retention |
| **ISO 27001:2022** | 8.15 | Logging |

---

### 7.2 Run the Security Center as Your Posture Dashboard

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 7.5, 16.13 |
| NIST 800-53 | RA-5, CA-7 |

#### Description
The workspace **Security center** (Settings → Security → Security center; Business/Enterprise, admins/owners) aggregates Code analysis (Basic/Deep findings across all projects, central Deep-scan triggering), Supply chain security (dependency vulnerabilities by severity), Secrets overview (secret **names** by project — never values), and Workspace insights (Enterprise; risk portfolio including PII detection). Enterprise adds **scheduled scans** (weekly Monday or monthly 1st, 08:00 workspace time; 1 credit per project per run). Only the latest results are retained — export CSV if you need history.

#### Rationale
**Why This Matters:**

- Central Deep-scan triggering plus scheduling turns per-project diligence (5.3) into a fleet control — no reliance on each builder remembering
- The secrets overview is your credential-inventory answer on a platform with write-only secrets: names, locations, publish status
- No-history retention means trend evidence only exists if you export it — same cadence discipline as 7.1

**Attack Prevented:** Fleet-wide drift — unscanned projects, aging dependency vulns, orphaned secrets

#### Prerequisites
- Business or Enterprise; scheduled scans Enterprise-only

#### ClickOps Implementation
1. **Settings → Security → Security center** → review all four tabs; clear error-level findings fleet-wide
2. Enterprise: configure the recurring scan (scope: all projects or published-only; weekly at L3)
3. Export CSV per review cycle into your evidence store

#### Validation & Testing
1. Scheduled scans run on cadence and consume expected credits
2. CSV exports accumulate as posture history

**Expected result:** One dashboard, on a schedule, with exported evidence.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | RA-5, CA-7 | Vulnerability scanning; continuous monitoring |
| **ISO 27001:2022** | 8.8 | Technical vulnerability management |

---

## 8. Compliance Quick Reference

### Tier 2 baseline coverage (verified 2026-08-15)

| Body | Coverage of Lovable |
|------|---------------------|
| CIS Benchmarks | **None** — no benchmark exists for Lovable or any AI app-builder category |
| DISA STIG | **None** found (best-effort; official library renders as a JS shell to automated checks) |
| CISA SCuBA | **Not applicable** — SCuBA covers Microsoft 365 services only |

Mappings in this guide therefore reference CIS Controls v8 (the general framework), NIST 800-53 Rev 5, and ISO 27001:2022 — not product benchmarks.

### Control-to-framework summary

| Area | Controls | NIST 800-53 anchors |
|------|----------|---------------------|
| Identity | [1.1](#11-verify-your-domain-foundation-for-sso-scim-and-provisioning)–[1.4](#14-require-2fa-on-every-account-especially-below-business) | IA-2, IA-8, AC-2, AC-12 |
| Access governance | [2.1](#21-right-size-roles-and-member-lifecycle)–[2.5](#25-harden-the-github-integration) | AC-3, AC-6, CM-5 |
| AI/integration surfaces | [3.1](#31-govern-connectors-and-know-their-enforcement-boundary)–[3.3](#33-treat-workspace-knowledge-and-cross-project-sharing-as-privileged-configuration) | AC-20, SA-9, CM-7 |
| Data protection | [4.1](#41-manage-secrets-the-platforms-way-and-rotate-on-exposure)–[4.4](#44-set-data-boundary-controls-code-downloads-transfers-region-abandoned-projects) | SC-12, SC-28, SI-4, AC-4 |
| Published apps | [5.1](#51-enforce-row-level-security-on-every-table-before-go-live)–[5.4](#54-publish-on-a-custom-domain-and-know-the-shared-suffix-risk) | AC-3, IA-5, RA-5, SC-8 |
| Privacy | [6.1](#61-opt-out-of-ai-model-training-before-september-9-2026-on-freepro)–[6.3](#63-know-the-privacy-floor-providers-telemetry-retention) | SI-12, PL-4, SA-9 |
| Monitoring | [7.1](#71-operate-the-audit-log-13-week-retention-forces-an-export-cadence)–[7.2](#72-run-the-security-center-as-your-posture-dashboard) | AU-2, AU-11, RA-5, CA-7 |

---

## Appendix A: Plan Gating Summary

| Control surface | Free | Pro | Business | Enterprise |
|-----------------|------|-----|----------|------------|
| 2FA (per-account) | ✅ | ✅ | ✅ | ✅ |
| SSO + Enforce SSO | ❌ | ❌ | ✅ | ✅ |
| SCIM provisioning | ❌ | ❌ | ❌ | ✅ |
| Restricted default project access | ❌ | ❌ | ✅ | ✅ |
| Non-public published apps | ❌ | ❌ | ✅ | ✅ |
| Publish-permission restriction | ❌ | ❌ | ❌ | ✅ |
| Block publishing w/ critical findings | ✅ | ✅ | ✅ | ✅ |
| Sensitive data scanning / DLP | ❌ | ❌ | ❌ | ✅ |
| Security center | ❌ | ❌ | ✅ | ✅ (＋scheduled scans) |
| Audit logs | ❌ | ❌ | ❌ | ✅ |
| Workspace training-data toggle | ❌ (per-member) | ❌ (per-member) | ✅ | ✅ |
| MCP surface toggles | ❌ (always on) | ❌ (always on) | ✅ | ✅ |

---

## Appendix B: References

**Tier 1 — Lovable documentation (all fetch-verified 2026-08-15):**

- [Privacy & security settings](https://docs.lovable.dev/features/privacy-and-security-settings) · [SSO](https://docs.lovable.dev/features/business/sso) · [SCIM](https://docs.lovable.dev/features/business/scim) · [Verified domains](https://docs.lovable.dev/features/verified-domains) · [2FA](https://docs.lovable.dev/introduction/two-factor-authentication-2-fa) · [People & roles](https://docs.lovable.dev/features/people)
- [Security features & scans](https://docs.lovable.dev/features/security) · [Security view](https://docs.lovable.dev/features/security-view) · [Security center](https://docs.lovable.dev/features/security-center) · [Security best practices](https://docs.lovable.dev/tips-tricks/security-best-practices) · [Sensitive data scanning](https://docs.lovable.dev/features/sensitive-data-scanning) · [Audit logs](https://docs.lovable.dev/features/audit-logs)
- [Secrets](https://docs.lovable.dev/features/secrets) · [Build secrets](https://docs.lovable.dev/features/build-secrets) · [Storage](https://docs.lovable.dev/features/storage) · [Database & RLS](https://docs.lovable.dev/features/database) · [Authentication](https://docs.lovable.dev/features/authentication) · [Email auth](https://docs.lovable.dev/features/email-auth) · [Advanced settings](https://docs.lovable.dev/features/advanced-settings)
- [Publish & visibility](https://docs.lovable.dev/features/publish) · [Project visibility](https://docs.lovable.dev/features/project-visibility) · [Share & preview links](https://docs.lovable.dev/features/share-project) · [Remix](https://docs.lovable.dev/features/projects/remix) · [Custom domains](https://docs.lovable.dev/features/custom-domain) · [Analytics](https://docs.lovable.dev/features/analytics)
- [Connector admin controls](https://docs.lovable.dev/integrations/admin-controls) · [Integration security](https://docs.lovable.dev/integrations/security) · [GitHub integration](https://docs.lovable.dev/integrations/github) · [Supabase integration](https://docs.lovable.dev/integrations/supabase) · [MCP server](https://docs.lovable.dev/integrations/lovable-mcp-server) · [Lovable API (scope)](https://docs.lovable.dev/integrations/lovable-api)
- [AI training opt-out](https://docs.lovable.dev/features/business/data-opt-out) · [Account settings](https://docs.lovable.dev/introduction/lovable-account-settings) · [Delete account](https://docs.lovable.dev/introduction/delete-account) · [Delete workspace](https://docs.lovable.dev/introduction/delete-workspace) · [Privacy policy](https://lovable.dev/privacy)

**Tier 3/4 — research and incidents:**

- [CVE-2025-48757 — Lovable RLS bypass, CVSS 9.3 (researcher: Matt Palmer)](https://cvefeed.io/vuln/detail/CVE-2025-48757)
- [Guardio Labs — VibeScamming benchmark](https://guard.io/labs/vibescamming-from-prompt-to-phish-benchmarking-popular-ai-agents-resistance-to-the-dark-side)

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-08-15 | Initial guide: 25 controls across identity (SSO/SCIM/2FA/verified domains), workspace access governance (roles, invitations, project access, publishing, GitHub), AI-agent surfaces (connectors with the not-enforced-after-publishing boundary, MCP toggles, workspace knowledge), data protection (secrets, storage, DLP, data boundaries), published-app security (RLS/CVE-2025-48757, app auth, scan gates, custom domains/VibeScamming), privacy (training opt-out deadline 2026-09-09, passive channels, non-configurable floor), and monitoring (audit-log export cadence, Security Center). Honest automation story: no admin API/CLI exists; SCIM is the sole programmatic surface (one pack). Tier 2 negatives (no CIS/STIG/SCuBA) cited. Authored by Claude Code (Opus 5). |

---

## Contributing

Found an issue or improvement? Open an issue or PR on [GitHub](https://github.com/grcengineering/how-to-harden). Lovable ships settings rapidly — plan-gating and defaults drift; currency PRs welcome.
