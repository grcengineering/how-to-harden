---
layout: guide
title: "Cursor Hardening Guide"
vendor: "Anysphere"
slug: "cursor"
tier: "1"
category: "DevOps"
description: "AI code editor security hardening for code privacy, MCP security, agent sandboxing, API key management, and workspace trust"
version: "0.5.0"
maturity: ["ai-drafted"]
last_updated: "2026-09-25"
---


**Product Editions Covered:** Cursor Hobby (free), Cursor Individual (Pro, Pro+, Ultra), Cursor Teams, Cursor Enterprise

---

## Overview

Cursor is an AI-powered code editor built on VSCode that integrates large language models (LLMs) directly into the development workflow. As organizations adopt AI coding assistants, securing these tools becomes critical—they process proprietary source code, handle API credentials, connect to multiple AI providers, and increasingly operate as autonomous agents capable of executing terminal commands, modifying files, and interacting with external services via MCP servers.

The threat landscape for AI code editors evolved rapidly in 2025-2026. Seven CVEs were assigned to Cursor in 2025 alone—including remote code execution via MCP prompt injection (CurXecute), persistent team-wide compromise through poisoned MCP configurations (MCPoison), sandbox escapes via shell builtins (NomShub), and case-sensitivity bypasses enabling sensitive file overwrites. A malicious extension on the Open VSX registry led to a confirmed $500,000 cryptocurrency theft. Security researchers demonstrated that invisible Unicode characters in `.cursorrules` files can weaponize AI code generation across entire teams.

This guide provides comprehensive hardening controls informed by vendor documentation, CVE analysis, security researcher disclosures, and industry frameworks including the OWASP Top 10 for LLM Applications (2025), the OWASP Top 10 for Agentic Applications (2026), NIST AI RMF, NIST SP 800-218A, and MITRE ATLAS v5.

### Intended Audience
- Security engineers evaluating AI coding tools
- DevOps/Platform engineers managing developer environments
- Engineering managers responsible for tooling security
- Compliance teams assessing data privacy for AI tools

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations using Cursor
- **L2 (Walk):** Enhanced controls for organizations with sensitive codebases
- **L3 (Run):** Strictest controls for regulated industries or high-security environments

### Scope
This guide covers Cursor-specific security configurations including AI privacy settings, MCP server security, agent sandbox controls, API key management, rules file integrity, code privacy controls, workspace trust, extension supply chain security, and organizational policies. General VSCode security and operating system hardening are out of scope.

### Why This Guide Exists

**No CIS Benchmark or equivalent standard exists for AI code editors.** As AI coding assistants become mission-critical development tools with autonomous agent capabilities, securing them is essential to:
- Prevent proprietary code leakage to third-party AI providers
- Protect API keys and credentials from exposure via AI context
- Defend against prompt injection attacks through MCP servers, rules files, and repository content
- Control autonomous agent actions (file writes, terminal execution, network access)
- Audit AI usage and code generation for compliance
- Manage extension supply chain risks in AI-augmented workflows
- Meet emerging regulatory requirements (EU AI Act, NIST AI RMF)

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [AI Privacy & Data Controls](#2-ai-privacy--data-controls)
3. [API Key & Credential Management](#3-api-key--credential-management)
4. [MCP Server Security](#4-mcp-server-security)
5. [Agent & Sandbox Security](#5-agent--sandbox-security)
6. [Rules File & Project Security](#6-rules-file--project-security)
7. [Workspace Trust & Code Security](#7-workspace-trust--code-security)
8. [Extension & Integration Security](#8-extension--integration-security)
9. [Network & Telemetry Controls](#9-network--telemetry-controls)
10. [Monitoring & Audit Logging](#10-monitoring--audit-logging)
11. [Organization & Team Controls](#11-organization--team-controls)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Account Authentication for All Users

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2

#### Description
Require all developers to authenticate with a Cursor account instead of using the editor anonymously. This enables audit logging, usage tracking, and centralized policy enforcement.

#### Rationale
**Why This Matters:**
- Anonymous usage prevents attribution of AI-generated code
- Account-based access enables usage monitoring and anomaly detection
- Required for enforcing organizational policies and compliance

**Attack Prevented:** Unauthorized tool usage, lack of accountability

#### Prerequisites
- Cursor account for each developer
- Decision on sign-in method: Cursor accounts log in with an email magic link, Google, or GitHub, and team members can be required to use SSO (1.3) ([Cursor Help](https://cursor.com/help/security-and-privacy/account-compromised)). With a magic link or Google/GitHub login, the account is only as strong as that mailbox or provider account, so require MFA there
- Communication plan for mandatory account creation

#### ClickOps Implementation

**Step 1: Require Login**
1. Open Cursor → **Settings** (Cmd/Ctrl + ,)
2. Navigate to: **Cursor Settings**
3. Ensure **Sign in to Cursor** is completed
4. For team deployments: Use Cursor Teams or Enterprise to enforce authentication

**Step 2: Configure Authentication Method**
1. Go to: https://cursor.com/settings — signed out, this redirects to the sign-in page at `authenticator.cursor.sh`, which opens with an email field
2. Complete sign-in with the method your account uses
3. For organizational accounts, prefer SSO (1.3) so authentication is governed by your identity provider rather than by a Cursor credential

**Step 3: Verify Authentication Status**
1. In Cursor, check bottom-right status bar for account email
2. Verify account is active and authenticated

**Automation:** ClickOps only — Cursor exposes no write interface for requiring sign-in on an individual install ([Deployment Patterns](https://cursor.com/docs/enterprise/deployment-patterns), 2026-09-24). On managed devices the enforceable form is the `AllowedTeamId` MDM policy, which forcefully logs out any account outside your team; the 11.2 Code Pack emits and verifies it.

**Time to Complete:** ~5 minutes per user

#### Validation & Testing
1. Attempt to use Cursor features without authentication
2. Verify AI features require authenticated account
3. Confirm account shows in Cursor status bar

**Expected result:** All Cursor features require authenticated account

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|--------------|---------|
| **User Experience** | Low | One-time authentication flow |
| **Development Workflow** | None | No workflow changes after authentication |
| **Maintenance Burden** | Low | Occasional re-authentication required |
| **Rollback Difficulty** | Easy | Sign out from account |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | User identification and authentication |
| **NIST 800-53** | IA-2 | Identification and authentication |
| **ISO 27001** | A.9.2.1 | User registration and de-registration |

---

### 1.2 Enable Multi-Factor Authentication (MFA)

**Profile Level:** L2 (Walk)
**NIST 800-53:** IA-2(1)

#### Description
Require MFA for Cursor account authentication to prevent account takeover via compromised credentials.

#### Rationale
**Why This Matters:**
- Developer accounts access proprietary source code
- Cursor accounts may have API keys for OpenAI, Anthropic, and other providers
- Account compromise could leak code via AI chat history
- StackAware researchers demonstrated an account takeover chain via login link interception

**Attack Prevented:** Credential stuffing, password reuse attacks, phishing, login link interception

#### ClickOps Implementation

> **Source note (2026-09-24).** Cursor's current documentation index has no page on account-level MFA, and the path below sits behind sign-in, so it was not re-verified in this pass. Confirm the options your account actually shows. For team accounts, the stronger design is to enforce MFA in your identity provider and require SSO (1.3), so Cursor never holds a password at all.

**Step 1: Enable MFA on Cursor Account**
1. Visit: https://cursor.com/settings/security
2. Navigate to **Multi-Factor Authentication**
3. Click **Enable MFA**
4. Choose method:
   - **Authenticator App (TOTP):** Recommended (Authy, 1Password, Google Authenticator)
   - **SMS:** Available but less secure
5. Scan QR code with authenticator app
6. Enter verification code
7. Save recovery codes in secure location (password manager)

**Step 2: Verify MFA Enforcement**
1. Sign out of Cursor
2. Sign back in
3. Verify MFA prompt appears after password

**Automation:** ClickOps only — Cursor exposes no write interface for account MFA; the Admin API documents no MFA route ([Admin API](https://cursor.com/docs/account/teams/admin-api), 2026-09-24).

**Time to Complete:** ~10 minutes

#### Validation & Testing
1. Attempt login with only password - should prompt for MFA
2. Test authenticator app generates valid codes
3. Verify recovery codes work for MFA bypass

**Expected result:** All logins require MFA verification

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Multi-factor authentication |
| **NIST 800-53** | IA-2(1) | Multi-factor authentication |
| **PCI DSS** | 8.3 | MFA for all access |

---

### 1.3 Configure SSO with SAML/OIDC (Teams and Enterprise)

**Profile Level:** L2 (Walk)
**NIST 800-53:** IA-2, IA-8

#### Description
Integrate Cursor with your identity provider (IdP) via SAML 2.0 or OIDC for centralized authentication. Enforce SSO-only login to prevent local credential usage.

#### Rationale
**Why This Matters:**
- Centralizes authentication lifecycle — offboarding in the IdP immediately revokes Cursor access
- Enables conditional access policies (device compliance, location-based restrictions)
- Eliminates password reuse risk for Cursor accounts
- Required for SCIM provisioning (Control 1.4)

**Attack Prevented:** Orphaned accounts, credential reuse, unauthorized access after offboarding

#### Prerequisites
- Cursor Teams or Enterprise plan — Cursor documents that "SAML 2.0 SSO is available at no additional cost on Teams and Enterprise plans"
- IdP with SAML 2.0 support (Okta, Microsoft Entra ID, Google Workspace, OneLogin)

#### ClickOps Implementation

**Step 1: Configure SSO in the Cursor dashboard**
1. Sign in with a team admin account and open https://cursor.com/dashboard/team-settings#single-sign-on-sso
2. Expand **Single Sign-On (SSO)** and click **Configure** next to **SSO-Provider Connection Settings**, then follow the wizard — it supplies the values your IdP needs
3. Enterprise organizations configure SSO in the Organization's settings rather than per team

**Step 2: Configure IdP Side**
1. In your IdP, create a new SAML application for Cursor and configure it with the values from the Cursor wizard
2. Set up Just-in-Time (JIT) provisioning
3. Assign users/groups to the Cursor application — assign users directly or as direct members of an assigned group; Cursor notes that nested groups often fail

**Step 3: Verify the domain — this is what enforces SSO**
1. Click **Configure** next to **Domain Verification Settings** and verify each email domain your users sign in with; each domain is verified separately
2. There is no separate "require SSO" switch. Cursor documents that once domain verification and the SSO provider connection are active, "users on that domain are required to sign in with SSO. There is no separate enforcement toggle."

**Step 4: Verify SSO Flow**
1. Sign out of Cursor
2. Attempt sign in — should redirect to IdP login
3. Complete IdP authentication
4. Verify automatic redirect back to Cursor with active session

**Automation:** ClickOps only — SSO is configured through the dashboard wizard and the Admin API documents no SSO route ([SSO](https://cursor.com/docs/account/teams/sso), [Admin API](https://cursor.com/docs/account/teams/admin-api), 2026-09-24).

**Time to Complete:** ~30 minutes

#### Validation & Testing
1. Verify SSO login flow completes without errors
2. Test that a user on a verified domain can no longer sign in without SSO
3. Offboard a test user in IdP — verify Cursor access is revoked
4. Verify JIT (Just-in-Time) provisioning creates new user accounts on first SSO login

**Expected result:** All team members authenticate exclusively through SSO

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Centralized identity management |
| **NIST 800-53** | IA-2 | Identification and authentication |
| **NIST 800-53** | IA-8 | Identification and authentication (non-org users) |
| **ISO 27001** | A.9.2.1 | User registration and de-registration |

---

### 1.4 Enable SCIM Provisioning (Enterprise)

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-2

#### Description
Enable SCIM 2.0 to automate user lifecycle management (provisioning, deprovisioning, group sync) between your IdP and Cursor.

#### Rationale
**Why This Matters:**
- Automating deprovisioning ensures no orphaned accounts retain access to AI chat history or cached code context
- Group-based role assignment enforces RBAC consistently
- Reduces manual administration burden for large teams

**Attack Prevented:** Orphaned accounts, excessive access, manual provisioning errors

#### Prerequisites
- **Cursor Enterprise plan with SSO enabled** — Cursor documents SCIM 2.0 provisioning as "available on Enterprise plans with SSO enabled." SSO (Control 1.3) is a hard dependency, not a recommendation
- IdP with SCIM 2.0 support

#### ClickOps Implementation

**Step 1: Start the SCIM wizard**
1. With an admin account, open https://cursor.com/dashboard/members?subtab=active-directory — the **Members & Groups** tab, **Directory Groups** subtab
2. Once SSO is verified, a link for step-by-step SCIM setup appears; click it to start the configuration wizard
3. Copy the SCIM endpoint URL and token the wizard provides

**Step 2: Configure IdP SCIM Client**
1. In your IdP, create or configure the SCIM application for Cursor
2. Enter the SCIM endpoint URL and token from Step 1
3. Enable user provisioning **and** push group provisioning — Cursor notes that group sync "must be configured separately from user sync"
4. Configure provisioning actions:
   - **Create Users:** Enabled
   - **Update User Attributes:** Enabled
   - **Deactivate Users:** Enabled
5. Set roles in Cursor, not through SCIM. Roles are configured in Cursor; to drive them from your directory, sync the directory group into an Organization Group and map that group to a team with a role. Cursor teams have **three** roles: **Members**, **Admins**, and **Unpaid Admins** — the last exists so an administrator can manage the team without consuming a paid seat, which is the correct assignment for IT or security staff who administer Cursor but do not write code in it

**Step 3: Test Provisioning**
1. Assign a test user to the Cursor application in IdP
2. Verify user appears in Cursor dashboard within minutes
3. Remove the test user from IdP
4. Verify user is deactivated in Cursor — or prove it with the Code Pack below by setting `HTH_EXPECT_REMOVED` to the test user's email

**Time to Complete:** ~30 minutes

#### Code Implementation

SCIM itself is configured in the dashboard and the IdP; the Admin API has no SCIM-configuration route. What the API can do is prove the outcome — member roles and `isRemoved` from `GET /teams/members`, and the synced groups from `GET /teams/directory-groups`.

{% include pack-code.html vendor="cursor" section="1.4" %}

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.2 | Prior to issuing access, authorization is verified |
| **NIST 800-53** | AC-2 | Account management |
| **ISO 27001** | A.9.2.6 | Removal or adjustment of access rights |

---

## 2. AI Privacy & Data Controls

### 2.1 Enable Privacy Mode for Sensitive Codebases

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-4

#### Description
Configure Cursor's Privacy Mode to prevent code from being stored or used for training by Cursor and its AI model providers. When enabled, Cursor maintains zero data retention (ZDR) agreements with all of its model providers, so providers do not store or train on your code — Cursor's data-use page names SpaceXAI, OpenAI, Anthropic, and Meta. Providers may still run risk classifiers and retain prompts that trip abuse detection, and non-ZDR models are flagged or require admin opt-in. Privacy Mode is on by default for Enterprise teams.

#### Rationale
**Why This Matters:**
- Without Privacy Mode, Cursor may store codebase data, prompts, and code snippets to improve AI features and train models
- With Privacy Mode off, Cursor states that "some of our inference providers may temporarily access and store model inputs and outputs to improve our inference performance; this data is deleted after use"
- Privacy Mode routes requests through separate server replicas where all logging functions are no-ops
- Compliance regulations (GDPR, HIPAA, SOC 2) may prohibit cloud AI processing of sensitive code

**Attack Prevented:** Data leakage to third-party AI providers, unauthorized code retention, training data contamination

**Real-World Context:**
- Samsung banned ChatGPT after engineers leaked sensitive code (April 2023)
- Over 50% of Cursor users already enable Privacy Mode, indicating widespread concern
- Internal repositories are 6x more likely to contain hardcoded secrets than public ones

#### Prerequisites
- Classification of codebases (public, internal, confidential)
- Decision on which repos require Privacy Mode
- Communication to developers about Privacy Mode policies

#### ClickOps Implementation

**Step 1: Enable Privacy Mode Globally**
1. Open Cursor → **Settings** (Cmd/Ctrl + ,)
2. Navigate to: **Cursor Settings** → **General** → **Privacy Mode**
3. Enable: **Privacy Mode**
   - When enabled, zero data retention agreements apply with all AI providers
   - Code enters volatile memory only for processing, then is discarded
   - Cursor's servers run separate replicas where logging is disabled
4. For Teams/Enterprise: open the [team dashboard](https://cursor.com/dashboard) → **Settings** → **Privacy Settings**, enable Privacy Mode for the team, and enforce it so members cannot disable it. Privacy Mode is on by default for Enterprise teams — confirm it is still on and enforced

**Step 2: Request US-only data residency (Enterprise, L2/L3)**

Privacy Mode governs *retention*; data residency governs *location*. Where your obligations are jurisdictional rather than retention-based, Privacy Mode alone does not satisfy them.

1. Cursor documents US-only data residency as "available to Enterprise customers and is enabled per team" — request it **through your account team**, not from the dashboard
2. Plan the lead time: Cursor says to "plan for up to two weeks from the time the request comes in"
3. Budget for the cost: it carries a **"10% uplift on Model pricing for eligible Models"**
4. Understand the coverage before relying on it. Residency applies to inference, data processing, and storage across supported features including Cloud Agents, autocomplete, and semantic search — but **only a specific set of model families run in-region**. Cursor lists these as GPT (`gpt-*`), Claude 4.6 and above, Gemini 2.5 Flash, Composer, and Grok 4.5. A model outside that list will not run in-region, so pair residency with model restrictions (2.2) or developers can silently select their way out of it
5. Expect added latency for users travelling outside the US, since requests still route to US-only infrastructure

**Step 3: Gate restricted models that carry retention obligations**

Some models are withheld from Privacy Mode and Enterprise users until an admin explicitly approves them, because the provider retains inputs and outputs. Cursor documents Claude Fable 5 and Claude Fable 5.1 as requiring such approval: Anthropic "stores their inputs and outputs to run automatic and human harm-prevention reviews," and "this data is not used for training or product improvement." Opting in applies to the whole team.

1. Treat any such approval as a data-flow decision, not a model-availability decision — approving it changes what leaves your organization under Privacy Mode
2. If you approve it, narrow the exposure: Cursor notes that "Enterprise admins can still limit which user groups can select the model," so scope it to the teams that need it rather than the whole organization
3. Record the approval and its scope in your AI vendor register, since it is an exception to the zero-retention posture the rest of this control establishes

**Step 4: Pin managed devices to the enforcing team**

Privacy Mode has no settings-file key and no MDM policy. The device-side control Cursor documents is the `AllowedTeamId` policy (11.2): it stops users from signing in to personal accounts — which might not have Privacy Mode enabled — on corporate devices.

**Step 5: Verify Privacy Mode Active**
1. Confirm Privacy Mode is on in Cursor Settings, and for teams that it is enabled and enforced in the dashboard
2. Run the Code Pack below to confirm nobody changed Privacy Mode during the review period

**Time to Complete:** ~5 minutes

#### Code Implementation

Cursor documents Privacy Mode as a dashboard (team) or in-app (individual) setting — there is no settings.json key and no MDM policy for it, so the enforcing write is ClickOps only ([Privacy and Data Governance](https://cursor.com/docs/enterprise/privacy-and-data-governance), [Deployment Patterns](https://cursor.com/docs/enterprise/deployment-patterns), 2026-09-24). Privacy Mode changes at user or team level are audit-logged as `privacy_mode` events, which the Admin API returns; this pack turns that into evidence.

{% include pack-code.html vendor="cursor" section="2.1" %}

#### Validation & Testing
1. As a team member, confirm Privacy Mode cannot be switched off when the team enforces it
2. Run the Code Pack above for the review period — it exits `0` only when no Privacy Mode change was logged

**Expected result:** Privacy Mode on and enforced, with no unreviewed `privacy_mode` events

#### Monitoring & Maintenance

**Alert on Privacy Mode Bypass:**
- Monitor for network connections to `api.openai.com`, `api.anthropic.com` that bypass Cursor's proxy
- Use endpoint security tools to detect unauthorized AI API calls

**Important caveat:** Regardless of model selection, some requests may route through OpenAI or Anthropic for background summarization tasks. In Privacy Mode, these still have zero data retention, but the routing itself is worth noting for strict data flow requirements.

**Maintenance schedule:**
- **Weekly:** Verify Privacy Mode still enabled in settings, and run the 2.1 Code Pack
- **Monthly:** Confirm managed devices carry the `AllowedTeamId` policy (11.2)
- **Quarterly:** Review Privacy Mode policy effectiveness

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **Developer Productivity** | Low | AI features remain functional; only data retention changes |
| **Code Quality** | None | AI assistance quality is identical |
| **Maintenance Burden** | Low | Once configured, no ongoing maintenance |
| **Rollback Difficulty** | Easy | Disable Privacy Mode in settings |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.7 | Data transmission controls |
| **NIST 800-53** | SC-4 | Information in shared system resources |
| **GDPR** | Article 28 | Processor obligations (AI providers as processors) |
| **ISO 27001** | A.13.2.1 | Information transfer policies |
| **NIST AI RMF** | GOVERN 1.7 | AI data governance policies |
| **OWASP LLM** | LLM02 | Sensitive information disclosure |

---

### 2.2 Govern Model Selection with Cursor Router

**Profile Level:** L2 (Walk)
**NIST 800-53:** SC-7, SA-9

#### Description
Cursor Router (shipped 2026-07-22) is the model routing system behind **Auto**: it selects an underlying model for each request. It is available on Teams and Enterprise plans only. Admins configure it from the team dashboard — enable it, choose which optimization modes members can select, show or hide the routed model, and **Impose Auto** with soft or hard enforcement. Which models it may route to is governed separately, by the team's **Model Access Control** (Enterprise), which the router respects. The three optimization modes are **Cost**, **Balance**, and **Intelligence**.

#### Rationale
**Why This Matters:**
- **Know whether routing is on before you assume either way.** Cursor Router is available on Teams and Enterprise; Cursor documents that "Enterprise teams must enable the router manually as it's off by default." Confirm the state for every team rather than inheriting an assumption
- The routed model is **hidden from the user by default** — Cursor calls hidden "the default and recommended" setting — so a developer cannot tell you which provider processed a given request unless an admin turns the display on. That is a material gap for anyone who has to evidence data flows to an auditor
- Different underlying models carry different retention, residency, and training postures — some are restricted models requiring explicit admin approval (see 2.1). Model Access Control, which the router respects, is where those decisions become enforceable rather than advisory
- Model choice is also a residency decision: US-only data residency covers only a documented subset of model families (2.1), so unrestricted model selection can route a request out of the region you paid to stay in
- Impose Auto's soft enforcement standardises behaviour while leaving an escape hatch; hard enforcement removes it. Both are off by default — choose deliberately

**Attack Prevented:** Silent routing of proprietary code to an unvetted or non-approved model provider, circumvention of data-residency and zero-retention commitments through developer model selection, and loss of auditable data-flow evidence when the processing model is hidden by default

#### Prerequisites
- Cursor Teams or Enterprise — Cursor Router "is currently only available on Teams and Enterprise plans," and Enterprise teams must enable it manually
- Enterprise for Model Access Control (allowing or blocking specific models)

#### ClickOps Implementation

**Step 1: Establish the current state**
1. Open the team dashboard's **Cursor Router** settings and check whether the router is enabled for each team (on Enterprise, also per organization group)
2. Do not assume a default: Enterprise teams have it off until an admin enables it
3. Record which optimization modes members can select, whether the routed model is displayed, and whether Impose Auto is set

**Step 2: Make the routed model visible**
1. Turn on display of the routed model so developers and auditors can see which model served a request
2. Leaving this hidden is defensible for a consumer product and indefensible for a regulated one — if you must evidence where code was processed, you need the model surfaced

**Step 3: Allow or block underlying models with Model Access Control (Enterprise)**
1. Model allow/block is **Model Access Control** in **Team Settings → Models**, a separate setting the router respects — the router routes around a blocked model
2. Block models your vendor-review process has not approved
3. Where US-only data residency is in force (2.1), block model families that Cursor does not run in-region, or residency is bypassable by model choice
4. Keep restricted models that require explicit retention approval blocked until that approval is recorded
5. Do not over-block: Cursor warns that "blocking too many models reduces routing quality and can disable the router," and documents Grok 4.6 as required for the router to work. Organization Groups can also widen model access for their members (team and group access combine, most permissive wins), so review group settings too

**Step 4: Constrain modes and set enforcement**
1. Under **Routing preferences**, restrict which optimization modes members may select — **Cost**, **Balance**, or **Intelligence**; Cursor allows disabling up to two
2. Use **Impose Auto** to standardise on Auto: **Soft** defaults each new chat to Auto while members can still switch; **Hard** locks the model picker to Auto. Both are off by default. Document which you chose and why

**Step 5: Scope per team or group**
1. Apply stricter model and mode restrictions to teams working on regulated or highest-sensitivity code
2. Re-review after each Cursor changelog entry that touches routing — this is a fast-moving surface

#### Code Implementation

The router's own toggles have no API. The model access policy it respects is readable through the Admin API (`GET /teams/model-access/configuration` and `/providers`, marked preview); this pack fails when no custom policy exists or when new providers are enabled by default.

{% include pack-code.html vendor="cursor" section="2.2" %}

**Automation:** The router settings themselves — enable, routing preferences, underlying-model display, Impose Auto — are ClickOps only; Cursor exposes no write interface for them ([Cursor Router](https://cursor.com/docs/cursor-router), [Admin API](https://cursor.com/docs/account/teams/admin-api), 2026-09-24).

#### Validation & Testing
1. As a non-admin member, confirm blocked models are unavailable
2. Confirm the routed model is displayed in the UI after enabling display
3. Where hard enforcement is set, confirm a member cannot switch away from the standardised mode
4. Confirm restrictions apply to the correct teams or groups, not just at the organization root

> **BYOK note:** Personal API key (BYOK) controls stay in the dashboard — the model-access API does not cover them — and Cursor documents that its Zero Data Retention policy "does not apply when using your own API keys." Treat BYOK as a separate decision and disable it for teams under model governance.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC9.2 | Third-party vendor management |
| **NIST 800-53** | SA-9 | External system services |
| **NIST 800-53** | SC-7 | Boundary protection |
| **OWASP LLM** | LLM03 | Supply chain vulnerabilities |
| **NIST AI RMF** | GOVERN 1.7 | AI data governance policies |

---

### 2.3 Configure .cursorignore for Sensitive Files

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, SC-4

#### Description
Create a `.cursorignore` file to exclude sensitive files and directories from being sent to Cursor's servers for AI processing, indexing, or embedding. This is a critical data boundary control.

#### Rationale
**Why This Matters:**
- Cursor sends code context (recently viewed files, surrounding code) to AI providers on every keystroke for Tab completions
- Codebase indexing uploads code chunks for embedding computation
- Without `.cursorignore`, secrets, credentials, and proprietary configuration may be included in AI context
- `.cursorignore` blocks ignored files from Agent, Tab, Inline Edit and @-references — but Cursor documents that "the terminal and MCP server tools used by Agent cannot block access to code governed by `.cursorignore`." Pair it with Run Modes (5.1), sandboxing (5.2) and a secret-read hook (7.2)

**Known Limitation:** Cursor states that while it blocks ignored files, "complete protection isn't guaranteed due to LLM unpredictability." Bugs have also let ignored files through (see GHSA-vhc2-fjv4-wqch). Use `.cursorignore` as defense-in-depth alongside secret scanning and Privacy Mode, not as a sole control.

**Attack Prevented:** Credential leakage via AI context, sensitive data exposure to AI providers

#### ClickOps Implementation

**Step 1: Create .cursorignore File**

Add a `.cursorignore` file to your project root using `.gitignore` syntax — the Code Pack below writes a template without overwriting an existing file. Cursor also ignores everything in `.gitignore` plus a built-in default list (lockfiles, `.env*`, binaries, media).

**Step 2: Cover what a single project file cannot**
1. **Global ignore list:** add patterns such as `**/.env`, `**/*.pem`, `**/*.key` and `**/credentials.json` to the global ignore setting in Cursor user settings, so every project is covered without its own file. The global list is empty by default
2. **Hierarchical ignore:** enable **Cursor Settings → Indexing → Ignore Files → Hierarchical Cursor Ignore** so `.cursorignore` files in parent directories apply to monorepos and nested checkouts
3. **Enterprise:** set organization-wide patterns in the team dashboard's **Cursor Ignore Configuration**

**Step 3: Commit to Repository**
1. Add `.cursorignore` to version control
2. Standardize across all organizational repositories

**Time to Complete:** ~10 minutes

#### Code Implementation

{% include pack-code.html vendor="cursor" section="2.3" %}

#### Validation & Testing
1. Run the verification excerpt of the Code Pack — it exits `1` if `.cursorignore` is missing or lacks a critical pattern
2. Test a pattern with `git check-ignore -v <file>`, which Cursor recommends because `.cursorignore` uses `.gitignore` semantics
3. `@`-reference an ignored file in chat and confirm the agent cannot read it

**Expected result:** All critical patterns present and sensitive files excluded from AI context

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | AC-3 | Access enforcement |
| **NIST 800-53** | SC-4 | Information in shared resources |
| **OWASP LLM** | LLM02 | Sensitive information disclosure |

---

### 2.4 Enable Local AI Models (L3 Run)

**Profile Level:** L3 (Run)
**NIST 800-53:** SC-4, SC-7

#### Description
Configure Cursor to use a model endpoint your organization operates (self-hosted or on-premises inference) instead of a third-party AI provider. This removes the third-party model provider from the data flow — but not Cursor's own backend: Cursor documents that even with your own API key, "your requests will still go through our backend! That's where we do our final prompt building." Prompts and code context therefore still transit Cursor's infrastructure, and the endpoint is called from there.

#### Rationale
**Why This Matters:**
- Inference runs on infrastructure you control, so no third-party model provider receives or retains your code
- Complete control over the model itself — version, weights, logging, and retention
- Cursor states that its Zero Data Retention policy "does not apply when using your own API keys," so the endpoint's own retention and logging become your responsibility — which is the point when you operate it
- Narrows dependence on upstream commitments — per-provider retention agreements and per-model approvals stop mattering once no third-party provider is in the path. Cursor's backend still is, so Privacy Mode (2.1) and data residency still apply to it

**Attack Prevented:** Exfiltration of source code, prompts, or embeddings to a third-party inference provider — including routes that bypass Privacy Mode or model restrictions, such as developer-supplied provider keys or a model family outside the data-residency scope

**Use Cases** (subject to the caveat above — requests still transit Cursor's backend, so this is not an air gap):
- Government contractors with classified code
- Healthcare orgs processing PHI/ePHI
- Financial institutions with proprietary trading algorithms

#### ClickOps Implementation

**Step 1: Install Local Model Backend**

Options:
- **Ollama:** Local LLM runtime (supports CodeLlama, Qwen2.5-Coder, DeepSeek-Coder, etc.)
- **LM Studio:** Local model management with OpenAI-compatible API
- **Custom OpenAI-compatible API:** Self-hosted models (vLLM, TGI)

**Step 2: Configure Cursor to Use Your Endpoint**
1. Open Cursor → **Settings**
2. Navigate to: **Models** → **OpenAI API Key**
3. Set the custom base URL to the OpenAI-compatible endpoint you operate. Because requests are built on Cursor's backend, plan the endpoint's exposure and authentication accordingly, and verify that your endpoint is reachable in your environment before relying on it
4. Disable all cloud AI providers

**Step 3: Verify Your Endpoint Is Used**
1. Use Cursor AI chat
2. Confirm your endpoint's access log records the requests
3. Confirm no third-party provider API (`api.openai.com`, `api.anthropic.com`) is contacted — the 9.2 egress allowlist blocks them

**Automation:** ClickOps only — Cursor documents the model base-URL override only as an in-app setting; there is no settings-file key or MDM policy for it ([Deployment Patterns](https://cursor.com/docs/enterprise/deployment-patterns), 2026-09-24).

**Time to Complete:** ~1 hour (model download + configuration)

#### Performance Considerations

| Model | Parameters | RAM Required | Performance | Use Case |
|-------|-----------|-------------|-------------|----------|
| **Qwen2.5-Coder** | 7B | 8 GB | Fast, good quality | Quick completions |
| **DeepSeek-Coder-V2** | 16B | 16 GB | Balanced | General development |
| **Qwen2.5-Coder** | 32B | 32 GB+ | Slower, high quality | Complex code generation |
| **CodeLlama** | 70B | 64 GB+ | Slow, highest quality | Critical code review |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SC-4 | Information remnants |
| **ITAR** | Data Sovereignty | Inference stays on infrastructure you control; pair with data residency for Cursor's backend |
| **FedRAMP** | SC-7 | Boundary protection |
| **NIST AI RMF** | GOVERN 1.4 | AI deployment controls |

---

## 3. API Key & Credential Management

### 3.1 Use Environment Variables for API Keys (Never Hardcode)

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5(1)

#### Description
Store Cursor AI provider API keys in environment variables or secure credential stores, never hardcoded in settings files committed to version control.

#### Rationale
**Why This Matters:**
- API keys in committed files leak to version control history
- Cursor settings files may sync to cloud or backups
- Hardcoded keys are difficult to rotate
- Developers using AI tools leak secrets at 2x the baseline rate

**Attack Prevented:** API key exposure via Git history, backup theft

#### ClickOps Implementation

**Step 1: Remove Hardcoded API Keys from Settings**
1. Check Cursor settings for hardcoded keys — the antipattern excerpt in the Code Pack below shows what to search for
2. Remove any hardcoded API keys

**Step 2: Use Environment Variables**
1. Add each provider key to your shell profile once, with the setup excerpt below — it prompts with hidden input, never writes placeholders, and skips variables that are already defined
2. Open a new terminal and restart Cursor to load them

**Step 3: Verify API Keys Not in Settings**
1. Run the verification excerpt — it exits `1` if a key is found in a settings file or in the repository's git history

**Time to Complete:** ~10 minutes

#### Code Implementation

{% include pack-code.html vendor="cursor" section="3.1" %}

#### Monitoring & Maintenance
- **Monthly:** Rotate API keys
- **Quarterly:** Audit environment variable security

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Secret management |
| **NIST 800-53** | IA-5(1) | Password-based authentication |
| **PCI DSS** | 8.2.1 | Render credentials unreadable |

---

### 3.2 Rotate AI Provider API Keys Quarterly

**Profile Level:** L2 (Walk)
**NIST 800-53:** IA-5(1)

#### Description
Establish a quarterly rotation schedule for all AI provider API keys used with Cursor.

#### Rationale
**Why This Matters:**
- Limits exposure window if keys compromised
- Follows secret management best practices
- Required by many compliance frameworks
- A leaked provider key is billable as well as confidential — an unrotated key funds an attacker's inference until someone notices the invoice (see 3.3)

**Attack Prevented:** Indefinite reuse of a leaked or exfiltrated provider API key, and persistent unauthorized inference access after a developer offboards or a workstation is compromised

#### ClickOps Implementation

**Step 1: Create API Key Rotation Schedule**
1. Document all API keys in use (OpenAI, Anthropic, Google, custom providers)
2. Set quarterly rotation reminders

**Step 2: Rotate Keys**

For OpenAI:
1. Visit: https://platform.openai.com/api-keys
2. Click **Create new secret key**
3. Update the environment variable with the Code Pack below (it reads the new key with hidden input and replaces the old value in place)
4. Restart Cursor
5. Verify new key works
6. **Revoke old key** on OpenAI platform

For Anthropic:
1. Visit: https://platform.claude.com/settings/keys
2. Generate new key → update the environment with the Code Pack (`ANTHROPIC_API_KEY`) → revoke old key

**Time to Complete:** ~15 minutes per provider

#### Code Implementation

{% include pack-code.html vendor="cursor" section="3.2" %}

---

### 3.3 Monitor API Key Usage and Costs

**Profile Level:** L2 (Walk)

#### Description
Monitor AI provider API usage to detect anomalies (unusual spikes, unauthorized usage, cost overruns).

#### Rationale
**Why This Matters:**
- A leaked or stolen AI provider key usually surfaces first as an abnormal spike in token usage or spend, well before any other indicator appears
- Hard billing limits cap the financial blast radius of a compromised key, a runaway agent loop, or an abusive integration
- Per-user usage review exposes shadow usage and insider misuse that account-level controls alone would miss
- Cursor connects to multiple providers (OpenAI, Anthropic, Google, custom keys), so usage anomalies are the most practical signal of credential abuse across all of them

**Attack Prevented:** API key abuse, undetected credential theft, denial-of-wallet via cost exhaustion, runaway agent token consumption

#### ClickOps Implementation

**Step 1: Enable Usage Tracking**

For OpenAI:
1. Visit: https://platform.openai.com/usage
2. Set up billing alerts:
   - **Soft limit:** Warning at $X per month
   - **Hard limit:** Block at $Y per month

For Anthropic:
1. Visit: https://platform.claude.com/settings/billing
2. Configure usage alerts

For usage billed by Cursor (Teams and Enterprise):
1. In the team dashboard, set monthly team spending limits under **Usage-Based Pricing Settings**; Enterprise adds individual, per-member and per-group limits under **Enhanced Spend Limits**
2. Run the Code Pack below on a schedule — it reads current-cycle spend per member and fails on members above your alert threshold or with no per-user limit

**Step 2: Review Usage Regularly**
- **Daily:** Check for cost spikes
- **Weekly:** Review usage patterns
- **Monthly:** Analyze per-user usage (if using organization accounts)

#### Code Implementation

{% include pack-code.html vendor="cursor" section="3.3" %}

**Automation:** Provider-side usage and billing alerts for keys you bring yourself are ClickOps only in those providers' consoles; the Code Pack covers usage billed by Cursor, through the Admin API's spending data ([Admin API](https://cursor.com/docs/account/teams/admin-api), 2026-09-24).

---

## 4. MCP Server Security

### 4.1 Audit and Allowlist MCP Servers

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7, SA-9

#### Description
Audit all configured MCP (Model Context Protocol) servers and restrict usage to an approved allowlist. MCP servers extend Cursor's capabilities by connecting to external tools and services, but represent one of the most significant attack surfaces — three CVEs in 2025 directly exploited MCP configuration.

#### Rationale
**Why This Matters:**
- MCP server installation (via `pip install` or `npx`) executes arbitrary code with full user permissions — no sandboxing by default
- CVE-2025-54135 (CurXecute): Prompt injection via MCP-connected services (e.g., Slack) rewrote `mcp.json` and executed arbitrary commands
- CVE-2025-54136 (MCPoison): After initial approval, attackers silently swapped benign MCP configs with malicious payloads for persistent RCE
- CVE-2025-64106: An input-validation flaw in MCP server installation let a crafted deep-link bypass the security warning and conceal the commands that would run (fixed after Cursor 1.7.28)
- 53% of MCP servers rely on static API keys or PATs that are rarely rotated
- 43% of tested MCP implementations had unsafe shell calls exposing them to command injection

**Attack Prevented:** Remote code execution via MCP prompt injection, persistent team-wide compromise, supply chain poisoning

**Real-World Context:**
- Between January-February 2026, over 30 CVEs were filed targeting MCP servers, clients, and infrastructure
- Among 2,614 MCP implementations surveyed, 82% use file operations vulnerable to path traversal

#### Prerequisites
- Inventory of all MCP servers in use across the organization
- A paid plan — Cursor's pricing lists MCP as an addition above Hobby
- Enterprise plan for centralized MCP allowlisting

#### ClickOps Implementation

**Step 1: Audit Existing MCP Configurations**
1. Run the audit excerpt of the Code Pack below against each project and developer home directory. It lists every server's command, URL and argument list, and only the *names* of env variables and headers, so the audit never copies a token into a terminal or CI log

**Step 2: Establish MCP Allowlist (Enterprise)**
1. Open **Team Settings → MCP Configuration** (https://cursor.com/dashboard/team-settings?view=mcp-configuration)
2. Add **command entries** (local `stdio` servers, matched by command pattern) and **URL entries** (remote HTTP/SSE servers, matched by URL pattern) for vetted servers only
3. For each approved server, set a **tool allowlist** — an empty tool allowlist allows every tool from that server
4. For local command-based servers, set the per-server network mode to **Allowlist** or **Deny all** rather than **Allow all** or **No sandbox**
5. Decide whether users may add their own MCP servers outside your patterns; if you allow it, use the **User MCP Network Denylist**
6. Allowlisting approves a configuration; it does not distribute or install a server. Tool-level pre-approval on developer machines lives in `permissions.json` (`mcpAllowlist`) — audit it with the 4.2 Code Pack

**Step 3: Secure MCP Config File Permissions**
1. Run the Code Pack with `--fix` to set both `mcp.json` files to owner read/write only (`600`)

**Step 4: Monitor MCP Configuration Changes**
1. Set up file integrity monitoring on `.cursor/mcp.json` (project and global)
2. Alert on any modification to MCP configuration files
3. Require re-approval for any MCP configuration change (enforced in Cursor 1.3+)

**Time to Complete:** ~30 minutes

#### Code Implementation

{% include pack-code.html vendor="cursor" section="4.1" %}

#### Validation & Testing
1. Verify only approved MCP servers are configured — the Code Pack exits `1` on a server that launches through a download or shell pipe, a cleartext `http://` URL, or a config file writable by others
2. Attempt to add an unapproved MCP server — should be blocked (Enterprise)
3. Modify an approved MCP config — should trigger re-approval prompt

**Expected result:** Only vetted MCP servers active, all changes require explicit approval

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **Developer Workflow** | Medium | Must request approval for new MCP servers |
| **Security Posture** | Critical Improvement | Prevents the most exploited attack vector in 2025 |
| **Maintenance Burden** | Medium | Ongoing review of MCP server requests |
| **Rollback Difficulty** | Easy | Re-enable MCP servers as needed |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | CM-7 | Least functionality |
| **NIST 800-53** | SA-9 | External system services |
| **OWASP LLM** | LLM03 | Supply chain vulnerabilities |
| **OWASP Agentic** | ASI05 | Supply chain risks |
| **MITRE ATLAS** | AML.T0063 | Publish poisoned AI agent tool |

---

### 4.2 Enable MCP Tool Protection

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-6

#### Description
Enable MCP Tool Protection to require explicit user approval before any MCP tool executes. This prevents prompt injection from triggering MCP tool calls without user consent.

#### Rationale
**Why This Matters:**
- Without tool protection, a prompt injection payload in a repository file or chat message can trigger MCP tools automatically
- MCP tools can read files, execute commands, and make network requests with the developer's full privileges
- Tool Protection ensures human-in-the-loop for all MCP operations
- Cursor's documented model has **two** approval points, not one: the MCP connection itself requires approval, and thereafter "each tool call still needs individual approval before running" — an approved server is not an approved set of tools
- The MCP allowlist exists to pre-approve specific tools. Every entry on it is a permanent removal of the second approval point for that tool, so the allowlist is the thing to audit, not the connection list

**Attack Prevented:** Prompt-injection-triggered MCP tool execution, silent invocation of file-read, shell, or network tools with developer privileges, and over-broad trust granted to a server on the basis of one connection approval

#### ClickOps Implementation

**Step 1: Keep per-tool approval in force**
1. MCP tool calls follow the same Run Modes as terminal commands. Open **Settings → Agents → Approvals & Execution**
2. For per-call approval on every MCP tool, choose **Allowlist** and keep the MCP allowlist empty. In **Auto-review** — the default since Cursor 3.6 — allowlisted MCP tools run immediately and everything else goes to a classifier (Cursor: "Auto-review is not a security boundary"); in **Run Everything** nothing is reviewed
3. Do not treat connection approval as sufficient — the per-call prompt is the control

**Step 2: Audit the MCP allowlist**
1. Review every tool pre-approved in the editor and in `mcpAllowlist` in `~/.cursor/permissions.json` and `<project>/.cursor/permissions.json` — both files are concatenated, and a team-dashboard allowlist overrides them
2. Remove wildcard entries: `*:*` (every tool on every server), `server:*` (every tool on a server, including ones it adds later) and `*:tool` (that tool name on any server)
3. Remove entries for tools that write files, execute commands, or make network requests — these are precisely the tools whose approval prompt matters
4. Keep the allowlist to genuinely read-only, low-consequence tools, and re-review it on a schedule

**Step 3: Also enable the file protections**
1. In the same settings area, enable **External-File Protection** (blocks automatic creation, modification or deletion of files outside the workspace) and **File-Deletion Protection** (blocks automatic deletes, including `rm`)
2. On Enterprise, enable **.cursor Directory Protection** in the team dashboard so agents cannot modify the project's `.cursor` directory

**Time to Complete:** ~5 minutes

#### Code Implementation

{% include pack-code.html vendor="cursor" section="4.2" %}

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-6 | Least privilege |
| **OWASP Agentic** | ASI02 | Tool misuse |
| **OWASP Agentic** | ASI03 | Identity and privilege abuse |

---

## 5. Agent & Sandbox Security

### 5.1 Disable Auto-Run Mode

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7, AC-6

#### Description
Keep terminal commands behind explicit human approval — do not widen Cursor's Run Modes to auto-run trusted commands (sometimes called "YOLO mode"). This is the single most impactful security control for Cursor.

Cursor's current documented model is a set of approval tiers. Reading files and code search need no approval, and the agent may modify workspace files **except configuration files**. Approval is required for terminal commands, configuration-file changes, actions that expose sensitive data, and MCP connections and tool calls — unless a **Run Mode** relaxes it. The three modes, chosen in **Settings → Agents → Approvals & Execution**, are **Auto-review** (allowlisted calls run, other shell commands run in the sandbox when possible, everything else goes to a classifier), **Allowlist** (only allowlisted actions run without approval), and **Run Everything** (every tool call runs automatically). Since Cursor 3.6 (May 29, 2026) Auto-review is the default; **Ask Every Time** was deprecated in 3.5, and Cursor's replacement for it is Allowlist with an empty allowlist.

> **The vendor does not claim Run Modes are a security boundary.** Cursor describes them as **"best-effort guardrails rather than a hard security boundary."** Treat any relaxation of the terminal approval tier as a productivity trade you are making knowingly, not as a control you can attest to.

#### Rationale
**Why This Matters:**
- In auto-run mode, Cursor's agent executes terminal commands without any user approval
- The command denylist uses a blocklist approach that has been repeatedly bypassed by researchers
- The vendor's own framing of Run Modes as best-effort means an auditor cannot be told that an allowlisted-command configuration prevents arbitrary execution — only that it discourages it
- The default is no longer approve-everything: since Cursor 3.6 the default mode is Auto-review, which runs allowlisted and sandboxed commands without prompting and sends the rest to a classifier Cursor says is not a security boundary. Getting to per-command approval is an explicit choice, not the default
- CVE-2026-22708 (NomShub): Shell builtins (`export`, `cd`, `eval`) bypass the command allowlist entirely because the parser only tracks external executables — enabling "deterministic, 100% reliable sandbox escape"
- GHSA-82wg-qcm4-fp2w: Environment variable manipulation bypassed the terminal allowlist
- Disabling auto-run prevents the majority of documented attack scenarios

**Attack Prevented:** Autonomous code execution, sandbox escape via shell builtins, privilege escalation, data exfiltration

**Real-World Context:**
- CyberScoop reported a one-line prompt attack that morphed Cursor's agent into a local shell with full developer privileges
- The NomShub attack chain achieved persistent remote access by chaining prompt injection → sandbox escape → `~/.zshenv` overwrite → GitHub OAuth device code hijack

#### ClickOps Implementation

**Step 1: Require approval for agent commands**
1. Open Cursor → **Settings → Agents → Approvals & Execution**
2. Select **Allowlist** and leave the allowlist empty, so every terminal, MCP, and Fetch call needs approval. Never select **Run Everything**
3. If you accept Auto-review for productivity, keep its allowlist narrow and add `block_instructions` in `permissions.json` for actions that must always be reviewed — as a trade you are making knowingly
4. **Enterprise:** restrict which modes users may pick with the team dashboard's **Auto Run Configuration**; team settings take precedence over individual and project configuration

**Step 2: Verify the terminal allowlist**
1. Run the Code Pack below. It audits `terminalAllowlist` and `autoRun` in both `permissions.json` files and exits `1` on an entry that is empty, `*`, or starts with a shell, interpreter, or network tool. The Run Mode itself is not stored in a documented file — confirm it in the app or the dashboard

**Time to Complete:** ~2 minutes

#### Code Implementation

{% include pack-code.html vendor="cursor" section="5.1" %}

#### Validation & Testing
1. Start an agent session
2. Agent proposes a terminal command
3. Verify the command requires explicit "Run" approval
4. Verify destructive commands (rm, git push) show warning

**Expected result:** Every terminal command requires explicit user approval

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **Developer Productivity** | Low-Medium | Must click "Run" for each agent command |
| **Security Posture** | Critical Improvement | Prevents autonomous code execution attacks |
| **Maintenance Burden** | None | One-time setting |
| **Rollback Difficulty** | Easy | Re-enable auto-run in settings |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | CM-7 | Least functionality |
| **NIST 800-53** | AC-6 | Least privilege |
| **OWASP Agentic** | ASI06 | Code execution |
| **OWASP Agentic** | ASI03 | Identity and privilege abuse |
| **MITRE ATLAS** | AML.T0061 | AI agent tools abuse |

---

### 5.2 Constrain the Agent's Approval and Network Posture

**Profile Level:** L2 (Walk)
**NIST 800-53:** SC-39, CM-7, SC-7

#### Description
Keep the agent inside the approval tiers, sandbox, and default network posture Cursor documents, and resist the pressure to widen them. Cursor layers two mechanisms: approval tiers with Run Modes (5.1), and an OS-level sandbox for terminal commands — Seatbelt through `sandbox-exec` on macOS (Cursor 2.0+), Landlock plus seccomp on Linux (kernel 6.2+; older kernels fall back to asking for approval). The sandbox's reach is set by `sandbox.json` and by a network mode chosen in the app.

> **Sources restored under this control (2026-09).** The 2026-08 revision recorded the sandbox documentation as 404 and withheld these specifics. Cursor now documents them again in [Run Modes](https://cursor.com/docs/agent/security/run-modes) and the [`sandbox.json` reference](https://cursor.com/docs/reference/sandbox), and this control is written against those pages.

#### Rationale
**Why This Matters:**
- The agent's *default* posture is the hardened one: Cursor documents that "agents cannot make arbitrary network requests with default settings," with access limited to GitHub, direct link retrieval, and web search providers. Most real-world weakening comes from someone relaxing this, not from the default
- Approval tiers are asymmetric by design — reading and searching are free, but terminal commands, configuration-file changes, and actions exposing sensitive data are gated. Configuration files are specifically excluded from free-edit, which is what stops an agent quietly rewriting the settings that constrain it
- Run Modes are the release valve on the terminal tier, and Cursor calls them "best-effort guardrails rather than a hard security boundary" — so the isolation story cannot rest on them
- Local agents retain broad filesystem read access, including paths such as `~/.ssh/`, `~/.aws/`, and `.env` files, so read-side exposure is governed by `.cursorignore` (2.3) and secret hygiene (7.2), not by the agent's approval tiers
- Researchers have demonstrated escapes via shell builtins (NomShub) and via macOS sandbox scope, so defence has to be layered across approval (5.1), hooks (11.3), and network allowlisting (9.2)

**Attack Prevented:** Agent-initiated network egress to attacker-controlled endpoints, agent modification of the configuration files that define its own constraints, and privilege expansion through progressively widened Run Modes

#### ClickOps Implementation

**Step 1: Confirm the default network posture is intact**
1. Verify agents are not permitted arbitrary outbound network access — Cursor's documented default limits its own tools' requests to GitHub, direct link retrieval, and web search providers
2. For sandboxed terminal commands, open **Settings → Agents → Approvals & Execution** and confirm the network mode is **sandbox.json Only** or **sandbox.json + Defaults** (the default, which adds roughly a hundred package-registry and tooling domains) — never **Allow All**, which ignores `sandbox.json` entirely
3. Review `~/.cursor/sandbox.json` and `<project>/.cursor/sandbox.json` (per-repo wins when they merge): `type` must not be `insecure_none`, `networkPolicy.default` should stay `deny`, and `additionalReadwritePaths` must not include your home directory. The Code Pack below checks all three
4. If someone has widened any of this for a workflow, record who, why, and for which teams. Undocumented widening is the finding
5. Layer the endpoint allowlist from 9.2 underneath, so network policy holds even if the in-product setting changes. On Enterprise, the team dashboard can set sandbox networking rules that local files cannot weaken

**Step 2: Preserve the configuration-file approval tier**
1. Confirm the agent still requires approval to modify configuration files — this is the tier that protects `.cursor/` rules (6.1), hooks configuration (11.3), and `.cursorignore` (2.3) from agent self-modification
2. The sandbox also write-protects certain paths regardless of `sandbox.json`: `.cursor/*.json`, `.vscode/**`, `.git/hooks/**`, `.git/config` and `.cursorignore`, among others. Note that `.cursor/rules/` is writable by design, which is why 6.1 and 6.2 exist
3. Treat any change that lets the agent edit configuration files without approval as a critical regression

**Step 3: Keep Run Modes narrow**
1. Prefer the strictest available mode; a broad allowlist and the Auto-review classifier both sit on the vendor's "best-effort" caveat
2. Where a team needs a wider mode, scope it to that team rather than the organization, and pair it with blocking hooks (11.3), which are the enforceable layer

**Step 4: Verify against your installed version**
1. Confirm the platform requirements hold: Cursor 2.0+ on macOS; on Linux, kernel 6.2+ with Landlock and unprivileged user namespaces, otherwise commands fall back to approval prompts
2. Where a setting this guide describes is absent in your build, do not assume it is applied silently — capture the gap and compensate with 9.2 and 11.3

**Time to Complete:** ~10 minutes

#### Code Implementation

{% include pack-code.html vendor="cursor" section="5.2" %}

#### Validation & Testing
1. Ask an agent to fetch a URL outside the permitted set and confirm it cannot
2. Ask an agent to modify a configuration file and confirm an approval prompt appears
3. Confirm the Run Mode in effect for each team matches what you documented
4. Confirm blocking hooks (11.3) deny a representative dangerous command, since that is the layer that does not carry a best-effort caveat

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SC-39 | Process isolation |
| **NIST 800-53** | CM-7 | Least functionality |
| **NIST 800-53** | SC-7 | Boundary protection |
| **OWASP Agentic** | ASI06 | Code execution controls |

---

### 5.3 Secure Background/Cloud Agents

**Profile Level:** L3 (Run)
**NIST 800-53:** SC-7, AC-6

#### Description
Configure security controls for Cursor's Background Agents (remote cloud agents that run in isolated Ubuntu VMs on Cursor's AWS infrastructure) or deploy self-hosted cloud agents for maximum control.

#### Rationale
**Why This Matters:**
- Background agents clone repositories, work on branches, and submit PRs autonomously
- Cursor acknowledges background agents have "a much bigger surface area of attacks compared to existing Cursor features"
- Cloud agents with Computer Use (Feb 2026) gave each agent its own VM with browser access and video recording — creating lateral movement risk if compromised
- Self-hosted cloud agents (March 2026) keep code and execution entirely within your infrastructure

**Attack Prevented:** Code exfiltration via cloud agents, lateral movement from compromised agent VMs

#### ClickOps Implementation

**Option A: Restrict Cloud Agent Usage**
1. Cloud Agents are optional. Cursor's own guidance is that "if your security policy prohibits code storage, don't enable Cloud Agents" — they are the only feature that requires Cursor to store code
2. Cloud Agents do not use Run Modes and never prompt for approval — "the agent never asks you to approve an action" — so approval-based controls (5.1) do not apply. The controls that do, in the [Cloud Agents dashboard](https://cursor.com/dashboard/cloud-agents):
   - **Network access:** set **Allowlist only** rather than **Allow all network access**
   - **Team follow-ups:** set **Disabled** or **Service accounts only** — Cursor warns that follow-ups let a member steer an agent running with another user's secrets
   - **Computer use** (Enterprise) and **Long running agents:** disable unless needed
   - **Display agent summary:** disable where file paths and code should not appear in the sidebar or external channels
3. Use **Protected Git Scopes** so repositories in your Git organization can only be used with Cloud Agents by your Cursor teams

**Option B: Deploy Self-Hosted Cloud Agents (Enterprise)**
1. Self-hosted agents run entirely within your infrastructure using outbound-only HTTPS connections
2. Deploy via Helm chart or Kubernetes operator
3. Code, tool execution, and build artifacts never leave your environment
4. No inbound ports, firewall changes, or VPNs needed

**Automation:** ClickOps only — Cursor documents Cloud Agent network, follow-up and security settings only in the Cloud Agents dashboard, and the Admin API has no route for them ([Cloud Agents settings](https://cursor.com/docs/cloud-agent/settings), [Admin API](https://cursor.com/docs/account/teams/admin-api), 2026-09-24).

**Time to Complete:** ~2 hours (self-hosted) or ~5 minutes (restrict)

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SC-7 | Boundary protection |
| **NIST 800-53** | AC-6 | Least privilege |
| **NIST AI RMF** | MANAGE 1.3 | AI deployment risk management |

---

## 6. Rules File & Project Security

### 6.1 Audit .cursorrules for Hidden Payloads

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SI-3, CM-7

#### Description
Scan `.cursorrules` and `.cursor/rules/*.mdc` files for hidden Unicode characters and suspicious instructions that could carry prompt injection payloads. Rules files define project-level AI instructions that automatically apply to all AI interactions — making them a potent supply chain attack vector.

#### Rationale
**Why This Matters:**
- Pillar Security demonstrated that invisible Unicode characters (zero-width joiners, bidirectional text markers) embedded in `.cursorrules` files silently instruct the AI to inject backdoors into all generated code
- Instructions are invisible in code editors and GitHub diffs
- Compromised rules files affect all team members who clone the repository
- Attack survives project forking — creating downstream supply chain contamination
- No trace in chat history or coding logs; security teams have zero visibility
- Cursor disputed this as "not a vulnerability on their side"

**Attack Prevented:** Supply chain poisoning via rules file prompt injection, invisible backdoor insertion, team-wide code compromise

**Real-World Context:**
- GitHub added hidden Unicode warnings to diffs by May 2025, implicitly validating the risk
- HiddenLayer researchers demonstrated control token abuse (`<user_query>`, `<user_info>`) to escalate malicious instructions to user-instruction privilege level

#### ClickOps Implementation

**Step 1: Scan Rules Files for Hidden Unicode**
1. Run the Unicode-scan excerpt of the Code Pack below from each repository root. It matches the UTF-8 bytes of zero-width, bidirectional, word-joiner, byte-order-mark and Unicode tag characters, works with macOS's BSD `grep`, and stops with exit `2` if the scan cannot run rather than reporting a clean result

**Step 2: Review Rules File Content for Suspicious Patterns**
1. The content-review excerpt flags instructions such as `curl`, `base64`, `/dev/tcp`, control tokens (`<user_query>`) and "ignore previous instructions". Matches are warnings for a human to read, not failures

**Step 3: Establish Rules File Governance**
1. Treat `.cursor/` directory and `.cursorrules` files as security-critical in code review — equivalent to CI/CD pipeline configurations
2. Require explicit review of all changes to rules files in pull requests
3. Maintain an approved rules file template for your organization (see CSA R.A.I.L.G.U.A.R.D. framework)

**Time to Complete:** ~15 minutes per repository

#### Code Implementation

{% include pack-code.html vendor="cursor" section="6.1" %}

#### Validation & Testing
1. Create a test rules file with a hidden Unicode character
2. Run the scanning script — it should flag the file and exit `1`
3. Review flagged file with hex editor to confirm

**Expected result:** All rules files are free of hidden Unicode and suspicious patterns

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SI-3 | Malicious code protection |
| **NIST 800-53** | CM-7 | Least functionality |
| **OWASP LLM** | LLM01 | Prompt injection |
| **OWASP Agentic** | ASI01 | Agent goal hijacking |
| **OWASP Agentic** | ASI04 | Memory poisoning |
| **MITRE ATLAS** | AML.T0051 | LLM prompt injection |

---

### 6.2 Enforce Rules File Review in PRs

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-3

#### Description
Require mandatory code review for any changes to AI rules files (`.cursorrules`, `.cursor/rules/*.mdc`) before they are merged. Implement CODEOWNERS rules to enforce security team review.

#### Rationale
**Why This Matters:**
- Rules file changes affect all future AI interactions for the entire team
- Malicious changes can be subtle (single-line instruction additions, Unicode injection)
- Without mandatory review, a compromised contributor can silently weaponize AI output
- Project-scoped hooks (`.cursor/hooks.json`, see 11.3) live in the same directory and carry more authority than rules — a hook can block, allow, or rewrite tool inputs — so the same review gate must cover them

**Attack Prevented:** Silent weaponization of team-wide AI behaviour through an unreviewed rules or hooks change, and prompt-injection payloads reaching main without a human ever reading the diff

#### ClickOps Implementation

**Step 1: Add Rules Files to CODEOWNERS**
1. In your repository, add to `.github/CODEOWNERS`:
   - `.cursorrules @security-team`
   - `.cursor/rules/ @security-team`
   - `.cursor/mcp.json @security-team`
   - `.cursor/hooks.json @security-team`
   - `.cursor/hooks/ @security-team`
   - `.cursor/permissions.json @security-team` (terminal and MCP allowlists, 5.1 and 4.2)
   - `.cursor/sandbox.json @security-team` (sandbox and network policy, 5.2)
   - `.cursorignore @security-team` (2.3)
   - `.vscode/tasks.json @security-team`
2. Enable branch protection requiring CODEOWNERS approval

**Step 2: Configure Pre-Commit Hook (Optional)**
1. Add a pre-commit hook that runs the Unicode scanning script from Control 6.1
2. Block commits containing hidden Unicode in rules files — the 6.1 script exits `1` when it finds any

**Time to Complete:** ~15 minutes

#### Code Implementation

The enforcement for this control lives on the Git host, not in Cursor. For GitHub, the GitHub guide's CODEOWNERS pack enforces code-owner review with the `github_branch_protection` Terraform resource and audits that a CODEOWNERS file exists (see [GitHub 3.11](/guides/github/#311-require-codeowners-approval-for-workflow-changes)); it is reused here, not re-validated by this guide:

{% include pack-code.html vendor="github" section="3.6" %}

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | CM-3 | Configuration change control |
| **SOC 2** | CC8.1 | Changes are authorized |
| **NIST SP 800-218A** | PW.7.1 | Review code changes |

---

## 7. Workspace Trust & Code Security

### 7.1 Enable Workspace Trust for All Repositories

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Enable VSCode/Cursor Workspace Trust to prevent automatic execution of untrusted code when opening new repositories. **Cursor ships with Workspace Trust disabled by default** — a deliberate design choice that creates a critical attack vector.

#### Rationale
**Why This Matters:**
- With Workspace Trust disabled (Cursor's default), a malicious `.vscode/tasks.json` with `runOptions.runOn: "folderOpen"` auto-executes arbitrary code the moment a developer opens a folder — no prompt, no consent, no AI involvement needed
- Developer laptops typically hold cloud keys, PATs, API tokens, and SaaS sessions — a booby-trapped repo pivots immediately to CI/CD and cloud infrastructure
- Cursor stated they "intended to keep the autorun behavior" because "Workspace Trust disables AI and other features our users want to use"
- This vulnerability has no CVE assigned (it's a design choice) but was disclosed by Oasis Security in September 2025

**Attack Prevented:** Arbitrary code execution from malicious repositories on folder open

**Real-World Context:**
- Oasis Security demonstrated complete exploitation: clone repo → open in Cursor → immediate code execution with developer privileges

#### Prerequisites
- Understanding of which repositories are trusted (internal, verified sources)
- Communication to developers about trust prompts (they will see new prompts after enabling)

#### ClickOps Implementation

**Step 1: Enable Workspace Trust**
1. Open Cursor → **Settings**
2. Search for: `security.workspace.trust.enabled` — this is the exact setting identifier
3. Apply the settings in the first excerpt of the Code Pack below (Workspace Trust on, startup prompt always, automatic tasks off)

**Step 1a: Enforce it centrally rather than per developer (Enterprise)**

A per-machine setting a developer can turn off is a recommendation, not a control. Cursor exposes workspace trust as an MDM policy key — **`WorkspaceTrustEnabled`**, corresponding to the client setting `security.workspace.trust.enabled`. Push it through MDM (see 11.2) so the setting cannot be reverted locally. Advanced identity controls including SCIM and MDM policies are documented as available on Enterprise.

**Step 2: Configure Trusted Folders**
1. Add trusted parent directories:
   - Company code: `~/work/company-name/`
   - Personal projects: `~/projects/personal/`

**Step 3: Verify Trust Prompts**
1. Clone a new repository outside trusted folders
2. Open in Cursor
3. Should see: **"Do you trust the authors of the files in this folder?"**
4. Select **"No, I don't trust the authors"** for untrusted repos

**Step 4: Verify Workspace Trust is Active**
1. Run the verification excerpt of the Code Pack below — it exits `1` when Workspace Trust is off or unset in a Cursor user settings file (on MDM-managed machines the `WorkspaceTrustEnabled` policy overrides the file; verify it with the 11.2 pack)

**Time to Complete:** ~5 minutes

#### Code Implementation

{% include pack-code.html vendor="cursor" section="7.1" %}

#### What Gets Restricted in Untrusted Workspaces

| Feature | Trusted | Untrusted |
|---------|---------|-----------|
| **Tasks** | Run automatically | Blocked |
| **Debugging** | Enabled | Disabled |
| **Extensions** | Full functionality | Limited/disabled |
| **Settings (workspace)** | Applied | Ignored |
| **AI Features** | Full | May be limited |

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **Developer Workflow** | Medium | Must trust repos to use full features; prompts on first open |
| **Security Posture** | Critical Improvement | Prevents auto-execution from malicious repos |
| **Maintenance Burden** | Low | One-time trust decision per workspace |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | CM-7 | Least functionality |
| **SOC 2** | CC6.6 | Logical access — malware protection |
| **OWASP Agentic** | ASI01 | Agent goal hijacking |

---

### 7.2 Scan for Secrets in Code Before AI Processing

**Profile Level:** L2 (Walk)
**NIST 800-53:** IA-5

#### Description
Use secret scanning tools to detect and remove secrets from code before allowing AI processing. Prevents accidental credential leakage to AI providers.

#### Rationale
**Why This Matters:**
- Cursor sends code snippets to AI providers (unless Privacy Mode enabled)
- Secrets in code sent to AI may be logged or retained by provider
- AI chat history may contain secrets if discussing code with credentials
- Researchers demonstrated that prompt injection can instruct Cursor to use `grep` to find API keys and exfiltrate them via `curl`

**Attack Prevented:** Credential leakage via AI context, secret exfiltration via prompt injection

#### ClickOps Implementation

**Step 1: Install Secret Scanning Extension**
1. In Cursor, open Extensions (Cmd/Ctrl + Shift + X)
2. Install: **GitGuardian** or **TruffleHog** extension
3. Configure to scan on save

**Step 2: Enable Pre-Commit Hooks**
1. Install `pre-commit` framework
2. Add secret scanning hooks (e.g., `detect-secrets`, `gitleaks`, `trufflehog`)
3. Run `pre-commit install` in repository

**Step 3: Verify Secret Scanning**
1. Create test file with fake secret
2. Attempt commit — should be blocked
3. Remove secret and retry

**Step 4: Block credential-bearing files at the agent boundary**
1. Scanners catch secrets at commit time; Cursor hooks catch them at read time. A `beforeReadFile` hook (Agent) and a `beforeTabFileRead` hook (Tab) receive the file's content before it is sent to a model and can deny the read — Cursor documents `beforeReadFile` for exactly this: "block sensitive files from being sent to the model"
2. Install the hook from the Code Pack below as a project hook, registered with `failClosed: true` so a crash or timeout blocks instead of allowing the read. Project hooks run only in trusted workspaces (7.1)

#### Code Implementation

{% include pack-code.html vendor="cursor" section="7.2" %}

---

## 8. Extension & Integration Security

### 8.1 Audit and Restrict VSCode Extensions

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Review all installed VSCode extensions and remove unnecessary or untrusted ones. Extensions have broad permissions and can access code, secrets, and network. Cursor uses the Open VSX registry instead of Microsoft's official Marketplace — introducing unique supply chain risks.

#### Rationale
**Why This Matters:**
- VSCode extensions can read all workspace files and make network requests
- Cursor uses Open VSX, which has weaker verification than Microsoft's Marketplace
- In June 2025, a fake "Solidity Language" extension on Open VSX led to a confirmed $500,000 cryptocurrency theft — the extension was a dropper that installed remote access tools and credential stealers
- In December 2025, researchers found Cursor was recommending extensions that didn't exist in Open VSX, enabling attackers to register those names and publish malware that the IDE actively recommended

**Attack Prevented:** Malicious extension data exfiltration, cryptomining, credential theft, supply chain compromise

**Real-World Context:**
- $500K crypto theft via malicious Open VSX extension (Kaspersky, July 2025)
- Extension name squatting across Cursor, Windsurf, and Google Antigravity (December 2025)

#### ClickOps Implementation

**Step 1: Audit Installed Extensions**
1. Run the Code Pack below. It lists every extension with its version from the `cursor` shell command, or from the extension manifest on disk if that command is missing or fails, and exits `2` rather than reporting an empty audit when it has no working inventory source

**Step 2: Remove Unnecessary Extensions**
1. Click extension → **Uninstall**
2. Focus on:
   - Extensions with <10K installs (less vetted)
   - Extensions not updated in >1 year
   - Extensions requesting network/filesystem permissions unnecessarily
   - Extensions side-loaded from `.vsix` files

**Step 3: Use Extension Allowlist (Enterprise)**

Cursor exposes extension allowlisting two ways, and the interaction matters:

1. **Dashboard:** configure the allowlist under **Security & Identity** in the admin dashboard. This corresponds to the client setting **`extensions.allowed`**
2. **MDM:** the policy key is **`AllowedExtensions`**, and it **overrides** the dashboard configuration. If you deploy both, MDM wins — do not assume the dashboard list is in force on MDM-managed machines
3. **Version floor:** dashboard-configured extension restrictions require **Cursor client version 2.1 or later**. Cursor states that "users on older versions will not have extension restrictions applied," so pair the allowlist with a minimum-version requirement (10.1) or the control simply does not apply to part of your fleet
4. Deploy via MDM (macOS) or Group Policy/Intune (Windows)
5. Third-party plugin imports default to OFF on Enterprise (require explicit admin override)

#### Code Implementation

{% include pack-code.html vendor="cursor" section="8.1" %}

#### Recommended Extensions Security Posture

| Extension Category | Risk Level | Recommendation |
|-------------------|-----------|----------------|
| **Official Microsoft** | Low | Generally safe |
| **GitHub Official** | Low | Safe |
| **Popular (>1M installs, verified publisher)** | Low-Medium | Review permissions |
| **Niche (<10K installs)** | Medium-High | Audit code before use |
| **Side-loaded .vsix** | High | Avoid; verify publisher and integrity |
| **Deprecated/Unmaintained** | High | Remove immediately |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | CM-7 | Least functionality |
| **OWASP LLM** | LLM03 | Supply chain vulnerabilities |

---

## 9. Network & Telemetry Controls

### 9.1 Disable Telemetry and Crash Reporting

**Profile Level:** L2 (Walk)
**NIST 800-53:** SC-4

#### Description
Disable telemetry data collection and crash reporting to prevent code snippets or metadata from being sent to Cursor/Microsoft.

#### Rationale
**Why This Matters:**
- Telemetry may include code snippets, file paths, or project metadata
- Crash reports can contain sensitive information
- Reduces data exposure to third parties
- Telemetry is a data flow that sits outside Privacy Mode's retention guarantees and outside your data-residency scope (2.1), so it has to be disabled explicitly rather than assumed covered

**Attack Prevented:** Inadvertent disclosure of proprietary file paths, project structure, and code fragments through diagnostic channels that bypass the retention and residency controls applied to model traffic

#### ClickOps Implementation

**Step 1: Disable All Telemetry**
1. Open Cursor → **Settings**
2. Search for `telemetry`
3. Set **Telemetry Level** (`telemetry.telemetryLevel`) to `off` — the documented VS Code setting that stops crash reports, error telemetry and usage data together. The older `telemetry.enableTelemetry` / `telemetry.enableCrashReporter` booleans are not on the current VS Code telemetry page, and Cursor documents no `cursor.general.*` telemetry key

**Step 2: Verify Telemetry Disabled**
1. Run the verification excerpt of the Code Pack below — it exits `1` unless `telemetry.telemetryLevel` is `off` in every Cursor user settings file
2. Check network traffic with tools like Little Snitch (macOS) or Wireshark

#### Code Implementation

{% include pack-code.html vendor="cursor" section="9.1" %}

---

### 9.2 Configure Network Allowlisting

**Profile Level:** L3 (Run)
**NIST 800-53:** SC-7

#### Description
Use enterprise firewall or endpoint security to allowlist only required Cursor network endpoints, blocking all other traffic.

#### Rationale
**Why This Matters:**
- Restricting Cursor to a known set of endpoints forces all AI model traffic through Cursor's Privacy Mode proxy instead of direct provider APIs that bypass data-retention guarantees
- An egress allowlist removes the exfiltration channels that prompt injection, a malicious extension, or a poisoned MCP server would use to reach attacker-controlled servers
- Outbound filtering contains compromised agents and subprocesses that attempt to call out to unapproved hosts for command-and-control or data theft
- Codebase context, embeddings, and credentials only leave the machine through network connections, so the network boundary is the last enforceable control when in-editor protections fail

**Attack Prevented:** Data exfiltration to unauthorized endpoints, Privacy Mode proxy bypass, command-and-control callbacks from compromised agents or extensions

#### Required Endpoints

The following are the hosts Cursor documents for enterprise network configuration. A previous revision of this guide listed `*.cursor.com` and `marketplace.visualstudio.com`; neither appears in Cursor's documented endpoint list and both have been removed. `*.cursorvm.com` — the cloud-agent VM domain — was absent from the previous list and is required if Cloud Agents are in use.

| Endpoint | Purpose | Required For |
|----------|---------|-------------|
| `api2.cursor.sh`, `api3.cursor.sh`, `api4.cursor.sh`, `api5.cursor.sh` | Core API requests | All users |
| `us-asia.gcpp.cursor.sh`, `us-eu.gcpp.cursor.sh`, `us-only.gcpp.cursor.sh` | Region-specific request routing | All users (varies by region/residency) |
| `agent.api5.cursor.sh`, `agentn.api5.cursor.sh`, `agent.us.api5.cursor.sh`, `agentn.us.api5.cursor.sh`, `agent.global.api5.cursor.sh`, `agentn.global.api5.cursor.sh` | Agent network access layer | Agent features |
| `repo42.cursor.sh` | Repository indexing / embeddings | Codebase indexing |
| `authenticate.cursor.sh`, `authenticator.cursor.sh`, `authentication.cursor.sh`, `prod.authentication.cursor.sh` | Authentication and SSO | All users |
| `adminportal42.cursor.sh` | Admin portal | Admins |
| `marketplace.cursorapi.com` | Extension marketplace | Extension management |
| `cursor-cdn.com` | CDN for static assets | All users |
| `downloads.cursor.com` | Client downloads and updates | All users |
| `anysphere-binaries.s3.us-east-1.amazonaws.com` | Binary updates | All users |
| `*.cursorvm.com`, `*.*.cursorvm.com` | Cloud Agent VMs and Grok Bot hosted computers (nested hostnames need the two-level wildcard) | Cloud Agents (5.3), Grok Bot |

**Recommended wildcards.** Where per-host allowlisting is impractical, Cursor documents these wildcards: `*.cursor.sh`, `*.cursor-cdn.com`, `*.cursorapi.com`, `*.cursorvm.com`, and `*.*.cursorvm.com`. Prefer the explicit host list at L3 — the wildcards trade precision for maintainability, and `*.cursor.sh` in particular admits every future subdomain without review.

**Block all other network traffic from Cursor.** If Cloud Agents are disabled per 5.3, omit the `*.cursorvm.com` entries rather than allowing them "just in case" — an unused allowlist entry is an available egress path.

#### Code Implementation

The Code Pack prints Cursor's documented allowlist — no `*.cursor.com` — with direct provider APIs listed under **BLOCK**, and snapshots Cursor's established connections for comparison with your firewall log.

{% include pack-code.html vendor="cursor" section="9.2" %}

**Important:** All AI model requests route through Cursor's infrastructure (the domains above), not directly to `api.openai.com` or `api.anthropic.com` — Cursor documents that even requests made with your own API key "still go through our backend." Blocking direct access to AI provider APIs forces traffic through Cursor's Privacy Mode proxy.

---

## 10. Monitoring & Audit Logging

### 10.1 Enable Cursor Usage Logging

**Profile Level:** L2 (Walk)
**NIST 800-53:** AU-2

#### Description
Configure logging of Cursor AI usage for audit and compliance purposes. Ensure Cursor is running a patched version to benefit from all security fixes.

#### Rationale
**Why This Matters:**
- Compliance frameworks require logging of AI usage
- Detect anomalous usage patterns (insider threats)
- Attribution of AI-generated code
- Version tracking prevents use of vulnerable Cursor releases — and several controls in this guide have hard version floors (extension allowlisting requires client 2.1+, see 8.1), so an unpatched fleet is also an unprotected one

**Attack Prevented:** Undetected insider misuse or account compromise, unattributable AI-generated code entering the codebase, and silent non-application of version-gated controls across an unpatched fleet

> **Source restored (2026-09).** The 2026-08 revision could not re-verify the audit-log claims because the documentation URL returned 404. Cursor now documents them in [Compliance and Monitoring](https://cursor.com/docs/enterprise/compliance-and-monitoring), including the negative claim that matters most for attestation: "We do not log agent responses or generated code content." This control is written against that page.

#### ClickOps Implementation

**Step 1: Verify Cursor Version**
1. Run the version-floor excerpt of the Code Pack below on each endpoint. It exits `1` below the floor (default 2.1, the version extension restrictions in 8.1 require) and `2` when the version cannot be determined — an unreadable endpoint is not a passing one

**Step 2: Review the Audit Log (Enterprise)**
1. Open https://cursor.com/dashboard/audit-log with an admin account. The audit log is available exclusively on Enterprise plans and is always on — there is no "enable" step
2. It records authentication events, user management (additions, removals, role changes, spend limits), team and user API key creation and revocation, team settings, repository management, Cloud Agent environments, directory groups, Privacy Mode changes at user or team level, team rules and commands, Grok Bot administration, and MCP server configuration and authentication
3. Agent responses and generated code content are **not** logged. Cursor recommends hooks for that; see 10.2

**Step 3: Get the log into your SIEM (Enterprise)**
1. **Streaming** to SIEM systems (Splunk, Sumo Logic, Datadog), webhooks, S3, Elasticsearch or CloudWatch is arranged on request through hi@cursor.com — it is not a self-serve setting
2. **Pull** collection works today: the Admin API's `GET /teams/audit-logs` returns the same events (rate limited to 20 requests per minute, at most 30 days per request). The Code Pack below exports them as JSONL for your SIEM
3. Events are JSON with timestamp, event ID, user email, IP address, event type and `application_type`

#### Code Implementation

{% include pack-code.html vendor="cursor" section="10.1" %}

### 10.2 Monitor for Suspicious Agent Activity

**Profile Level:** L2 (Walk)
**NIST 800-53:** AU-6, SI-4

#### Description
Monitor developer workstations for indicators of Cursor-based attacks including unexpected process spawning, shell startup file modifications, and suspicious network connections.

#### Rationale
**Why This Matters:**
- The NomShub attack chain persisted via `~/.zshenv` overwrite
- Prompt injection can spawn `curl` to exfiltrate data via agent terminal access
- Unexpected `cursor-tunnel` processes may indicate remote access exploitation
- Cursor's own audit logs do not capture agent execution on the endpoint, so workstation telemetry is the only place these indicators appear at all

**Attack Prevented:** Persistence via shell startup file modification, data exfiltration through agent-spawned subprocesses, silent MCP configuration tampering, and remote access established through unexpected tunnel processes

#### ClickOps Implementation

**Key Indicators to Monitor:**
1. **Shell startup file modifications:** Watch `~/.zshenv`, `~/.bashrc`, `~/.zprofile` for unexpected changes
2. **Process tree anomalies:** AI agents spawn child processes — EDR should monitor the full process tree from Cursor
3. **Unexpected network connections:** Flag outbound connections from Cursor subprocesses to non-allowlisted endpoints
4. **MCP config changes:** File integrity monitoring on `.cursor/mcp.json` (project and global)
5. **Cursor application file tampering:** Monitor for modifications to Cursor's `main.js` (malicious npm packages have overwritten this)
6. **`cursor-tunnel` processes:** Monitor for unexpected remote tunnel activity

**Agent-side telemetry with hooks:** Cursor does not record agent actions in its audit log and recommends hooks for this instead. The Code Pack below installs a user-scope audit hook on `afterShellExecution`, `afterMCPExecution` and `afterFileEdit` that appends one JSON line per agent action to `~/.cursor/hth-agent-audit.jsonl` — command, MCP server and tool, or edited path — with `suspicious: true` on indicators 1, 4 and 6 above and on download-and-execute and reverse-shell commands. It records no command output, tool results or edit contents. Ship the file to your SIEM with your endpoint agent and alert on `suspicious`. Deploy it at the Enterprise hooks path through MDM (11.2, 11.3) so developers cannot remove it.

#### Code Implementation

{% include pack-code.html vendor="cursor" section="10.2" %}

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AU-6 | Audit record review |
| **NIST 800-53** | SI-4 | System monitoring |
| **OWASP Agentic** | ASI10 | Rogue agents |

---

## 11. Organization & Team Controls

### 11.1 Deploy Cursor Teams or Enterprise for Centralized Management

**Profile Level:** L2 (Walk)

#### Description
Use Cursor Teams or Enterprise edition to enforce organizational policies, manage licenses, and control AI provider access centrally.

#### Rationale
**Why This Matters:**
- Centralized policy enforcement (Privacy Mode, allowed providers, MCP servers)
- License management and usage tracking
- Audit logging at organization level
- Over half of Fortune 500 now use Cursor — enterprise governance is critical
- Several controls in this guide have no self-serve equivalent: model governance via Cursor Router (2.2), extension allowlisting (8.1), Team and Enterprise hooks distribution (11.3), and SCIM (1.4) all require a team plan and, in most cases, Enterprise

**Attack Prevented:** Policy divergence across individually-configured installations, and the shadow-IT case where developers adopt Cursor on personal accounts entirely outside organizational visibility and control

#### ClickOps Implementation

**Step 1: Set Up Cursor Teams or Enterprise**
1. Visit: https://cursor.com/pricing
2. Choose plan:
   - **Teams ($40/user/month standard seat):** SAML/OIDC SSO, team-wide Privacy Mode enforcement, usage analytics (also through the Admin API), team marketplace, Cursor Router
   - **Enterprise (custom pricing):** All Teams features plus SCIM, MDM policies, audit logs, model/MCP/auto-run access controls, CMEK, self-hosted agents, AI Code Tracking API
3. Create organization and invite team members

**Step 2: Configure Organization Policies**
1. In the team dashboard:
   - **Privacy Mode:** Enable and enforce for all users (2.1)
   - **Cursor Router:** Configure routing, display and Impose Auto (2.2)
   - **Allowed AI Models:** Restrict to approved models with Model Access Control — *Enterprise* (2.2)
   - **MCP Servers:** Configure the MCP allowlist in MCP Configuration — *Enterprise* (4.1)
   - **Agent Settings:** Restrict available Run Modes in Auto Run Configuration and set sandbox networking rules — *Enterprise* (5.1, 5.2)
   - **Extensions:** Configure allowlist — *Enterprise* (8.1)
   - **Cloud Agents:** Set network access, team follow-ups and security settings per policy (5.3)
   - **BYOK:** Disable if using only org-managed keys
2. Telemetry has no documented team-level switch; set it per device (9.1)

#### Code Implementation

{% include pack-code.html vendor="cursor" section="11.1" %}

#### Enterprise-Only Features

| Feature | Description |
|---------|-------------|
| **SCIM 2.0** | Automated user provisioning/deprovisioning |
| **MDM Policies** | Deploy settings via Jamf, Intune, Kandji |
| **Audit Logs** | Authentication, settings changes, API key management |
| **Log Streaming** | Export to SIEM (Splunk, Datadog, etc.) |
| **CMEK** | Customer-managed encryption keys for embeddings |
| **Self-Hosted Agents** | Cloud agents running in your infrastructure |
| **AI Code Tracking API** | Per-commit AI attribution (alpha) |
| **Cursor Blame** | AI vs. human code attribution in git blame |
| **Billing Groups** | Cross-team spend allocation |
| **Service Accounts** | Automated workflow authentication |
| **Model Access Control** | Allow or block specific models (2.2) |
| **Auto Run Configuration** | Restrict which Run Modes members can use (5.1) |
| **MCP Configuration** | MCP server and tool allowlist (4.1) |
| **Cursor Ignore Configuration** | Organization-wide ignore patterns (2.3) |
| **.cursor Directory Protection** | Stop agents modifying a project's `.cursor` directory (4.2) |

---

### 11.2 Enforce Organizational Policies via MDM

**Profile Level:** L3 (Run)

#### Description
Use MDM (Mobile Device Management) to deploy and enforce Cursor security settings across all developer machines. MDM-deployed policies cannot be overridden locally.

#### Rationale
**Why This Matters:**
- Without MDM enforcement, developers can disable Privacy Mode, enable auto-run, or install unapproved MCP servers locally
- 78% of AI coding tool usage is shadow IT — MDM ensures governance even for unmanaged adoption
- MDM-deployed settings survive Cursor updates and reinstalls
- MDM is the layer that wins conflicts: the `AllowedExtensions` MDM key **overrides** the dashboard-configured extension allowlist, so where both exist the MDM value is what is actually enforced

**Attack Prevented:** Local reversal of organizational security settings by a developer or by malware acting with the developer's privileges, and authentication with personal Cursor accounts on corporate devices to escape organizational policy entirely

#### Prerequisites
- Cursor documents advanced identity controls — "SCIM, MDM policies, and more" — as available on Enterprise. Confirm MDM policy entitlement for your specific plan with Cursor before designing around it.

#### ClickOps Implementation

**Step 1: Create MDM Configuration Profile**

Use the exact policy keys Cursor documents. The client setting and the MDM key are different identifiers for the same control — searching Cursor settings for the client setting is how you verify the MDM key landed:

| Control | Client setting | MDM policy key |
|---------|---------------|----------------|
| Restrict login to your team | `cursorAuth.allowedTeamId` | `AllowedTeamId` |
| Extension allowlist | `extensions.allowed` | `AllowedExtensions` |
| Workspace trust | `security.workspace.trust.enabled` | `WorkspaceTrustEnabled` |

1. **`AllowedTeamId`** takes a comma-separated list of permitted team IDs. Cursor documents the enforcement behaviour explicitly: a user authenticating with a team ID outside the list is **forcefully logged out immediately**, an error is displayed, and further authentication attempts are prevented until a valid team ID is used. This is what stops a personal account being used on a corporate device
2. **`AllowedExtensions`** controls permitted extensions and overrides the dashboard allowlist (8.1)
3. **`WorkspaceTrustEnabled`** force-enables workspace trust (7.1), which Cursor ships disabled by default — this is the highest-value single key in the profile
4. Privacy Mode (2.1) has no MDM key: enforce it in the team dashboard and use `AllowedTeamId` so devices can only sign in to that team. The remaining documented policies are `ExtensionGalleryServiceUrl`, `NetworkDisableHttp2` and `UpdateMode`; MDM can also distribute `~/.cursor/permissions.json` (terminal and MCP allowlists, 4.2 and 5.1) and the Enterprise-scope `hooks.json` (11.3)
5. Delete every policy you do not intend to enforce from Cursor's sample profile — Cursor warns that a policy left in the sample "will be enforced with its default value"

**Step 2: Deploy via MDM**
- **macOS (Jamf/Kandji/Intune):** Deploy as a `.mobileconfig` configuration profile; Cursor ships a sample at `/Applications/Cursor.app/Contents/Resources/app/policies/com.todesktop.230313mzl4w4u92.mobileconfig`
- **Windows (Intune/SCCM):** Deploy Group Policy from the ADMX/ADML files in `AppData\Local\Programs\cursor\policies`; computer-level values take precedence over user-level
- **Linux:** Deploy `~/.cursor/policy.json` (Cursor 2.0+) via configuration management (Ansible, Puppet, Chef). `AllowedExtensions` must be a JSON *string*, and invalid JSON makes Cursor run without policy restrictions — the Code Pack below emits a valid file and verifies the one in force

**Step 3: Distribute Compliance Hooks**
1. Use Cursor Hooks to enforce compliance policies at runtime — see 11.3 for the event model, precedence, and enterprise file paths
2. Hooks can block unapproved commands and modify tool inputs, which is enforcement rather than advice
3. Deploy the enterprise-scope `hooks.json` through MDM alongside editor settings, or distribute team hooks through the dashboard

**Time to Complete:** ~2 hours (initial setup), ongoing maintenance for policy updates

#### Code Implementation

{% include pack-code.html vendor="cursor" section="11.2" %}

#### Validation & Testing
1. On a managed machine, attempt to sign in with a personal Cursor account and confirm the forced logout and error
2. Search Cursor settings for `security.workspace.trust.enabled` and confirm it reads as enabled and is not locally editable
3. Attempt to install an extension outside the allowlist and confirm it is blocked
4. Confirm the client version meets the 2.1+ floor required for extension restrictions (8.1)

---

### 11.3 Deploy Cursor Hooks as an Enforcement Layer

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-3, AU-2, SI-4, CM-7

#### Description
Cursor Hooks are scripts that observe, control, and extend the agent loop. They are spawned processes that exchange JSON over stdio before and after defined agent stages, and — critically — they can **block** an action or **modify** its input. Where Run Modes are described by the vendor as best-effort guardrails (5.1), hooks are the layer where an organization can impose a deterministic decision on what the agent is allowed to do.

#### Rationale
**Why This Matters:**
- Hooks are the only Cursor-native mechanism that can deny a specific agent action programmatically: returning `"permission": "deny"` or exiting with code `2` blocks the action, while `"updated_input"` fields rewrite tool inputs before execution
- They cover the exact chokepoints that every attack in Appendix B passes through — shell execution, MCP calls, file reads, file edits, and prompt submission — so a single hook can neutralize a class of attack rather than a single CVE
- They are the enforceable answer to prompt injection: an injected instruction may convince the model, but it does not convince the hook process, which sees the concrete tool call rather than the persuasive text
- Precedence is explicit and top-down — **Enterprise → Team → Project → User** — so an organizational hook cannot be overridden by a project or a developer, which is what makes them a control rather than a convention
- **Fail-open is the default.** An exit code other than `0` or `2` allows the action. A hook that crashes therefore permits what it was written to block — hooks must be tested for their failure behaviour, not just their success path
- Untested hooks add latency to every agent interaction, so scoping them to the events that matter is a usability requirement as well as a performance one

**Attack Prevented:** Prompt-injection-driven shell execution and MCP tool invocation, exfiltration of secrets through agent-initiated commands, unreviewed edits to sensitive files, and per-developer divergence from organizational agent policy

#### Prerequisites
- A paid plan — Cursor's pricing lists hooks as an addition above Hobby
- Enterprise plan for dashboard-distributed team and enterprise-managed hooks
- Ability to deploy files to developer endpoints for the enterprise-scope path, or MDM (11.2)
- A tested hook script, including its behaviour when it errors

#### ClickOps Implementation

**Step 1: Choose the scope, and understand precedence**

Precedence runs **Enterprise → Team → Project → User** (highest to lowest). Place organizational policy at Enterprise or Team so it cannot be overridden locally.

| Scope | Location |
|-------|----------|
| Enterprise (macOS) | `/Library/Application Support/Cursor/hooks.json` |
| Enterprise (Linux/WSL) | `/etc/cursor/hooks.json` |
| Enterprise (Windows) | `C:\ProgramData\Cursor\hooks.json` |
| Team | Configured in the Cursor web dashboard and distributed automatically |
| Project | `<project-root>/.cursor/hooks.json` |
| User | `~/.cursor/hooks.json` |

**Step 2: Hook the events that carry risk**

Cursor documents these events. Start with the security-relevant subset rather than instrumenting everything:

| Class | Events | Security use |
|-------|--------|--------------|
| Shell | `beforeShellExecution`, `afterShellExecution` | Deny dangerous commands; this is the chokepoint Run Modes only guard on a best-effort basis |
| MCP | `beforeMCPExecution`, `afterMCPExecution` | Enforce a real MCP tool policy independent of the approval prompt (4.2) |
| Files | `beforeReadFile`, `afterFileEdit` | Block reads of credential paths; audit or reject edits to sensitive files |
| Prompt | `beforeSubmitPrompt` | Scrub secrets from outbound prompts before they leave the machine |
| Tools | `preToolUse`, `postToolUse`, `postToolUseFailure` | General-purpose policy and telemetry across all tool calls |
| Session | `sessionStart`, `sessionEnd`, `stop`, `preCompact` | Session-scoped audit records |
| Subagents | `subagentStart`, `subagentStop` | Apply the same policy to delegated agents, which otherwise inherit trust silently |
| Agent output | `afterAgentResponse`, `afterAgentThought` | Response-side monitoring |
| Tab | `beforeTabFileRead`, `afterTabFileEdit` | Extend file policy to inline completions, which are a separate data path from chat |
| Lifecycle | `workspaceOpen` | Workspace-entry checks, complementing workspace trust (7.1) |

**Step 3: Write hooks that fail closed**
1. Return `"permission": "deny"` or exit `2` to block; any other non-zero exit allows the action by default
2. Set `"failClosed": true` on every security-critical hook definition — Cursor documents that with it, "hook failures (crash, timeout, non-zero exit code, no output) block the action instead of allowing it through." Permission hooks also block on invalid JSON even without it
3. Also wrap hook logic so that an error it can detect produces an explicit deny, rather than relying on either default
4. Keep hooks fast — they run in the agent loop, on every matching event
5. Project hooks run only in trusted workspaces, so Workspace Trust (7.1) is a prerequisite for project-scope enforcement

The Code Pack below installs a project `beforeShellExecution` hook registered with `failClosed: true` and self-tests both its deny list and its fail-closed path.

**Step 4: Distribute and keep them in sync**
1. On Enterprise, configure team and enterprise-managed hooks through the web dashboard; Cursor documents automatic synchronization to all team members **every thirty minutes**
2. Budget for that sync interval in your incident response: a hook change pushed to block an active attack is not instantaneous across the fleet, so pair urgent changes with the MDM-deployed enterprise file
3. Put `.cursor/hooks.json` under CODEOWNERS review (6.2) — a project hook is executable policy and deserves the same review as a rules file

#### Code Implementation

{% include pack-code.html vendor="cursor" section="11.3" %}

#### Validation & Testing
1. Trigger a command your `beforeShellExecution` hook should block and confirm it is denied
2. Deliberately make the hook exit with a code other than `0` or `2`: without `failClosed` the action is allowed (fail-open); with `failClosed: true` it must be blocked. Every security-critical hook should pass the second test
3. Set a conflicting hook at Project scope and confirm the Enterprise or Team hook still wins
4. Confirm a dashboard-distributed hook reaches a test machine, and record the observed sync delay
5. Confirm hooks apply to subagent activity, not just the top-level agent

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-3 | Access enforcement |
| **NIST 800-53** | CM-7 | Least functionality |
| **NIST 800-53** | AU-2 | Event logging |
| **NIST 800-53** | SI-4 | System monitoring |
| **OWASP LLM** | LLM01 | Prompt injection |
| **OWASP Agentic** | ASI02 | Tool misuse |
| **OWASP Agentic** | ASI06 | Code execution controls |

---

## Appendix A: Edition Compatibility

Plan names and tiers follow [cursor.com/pricing](https://cursor.com/pricing) and Cursor's plan documentation, read 2026-09-24. The Individual tier (Pro, Pro+, Ultra) is where MCP, hooks and Cloud Agents begin — Hobby does not list them.

| Control | Hobby (free) | Individual (Pro, Pro+, Ultra) | Teams | Enterprise |
|---------|-------------|-------------------------------|-------|------------|
| Account Authentication (1.1) | ✅ | ✅ | ✅ | ✅ |
| MFA (1.2) | ✅ | ✅ | ✅ | ✅ |
| SSO/SAML (1.3) | ❌ | ❌ | ✅ | ✅ |
| SCIM Provisioning (1.4) | ❌ | ❌ | ❌ | ✅ |
| Privacy Mode (2.1) | ✅ (opt-in) | ✅ (opt-in) | ✅ (enforceable) | ✅ (on by default, enforceable) |
| US-only data residency (2.1) | ❌ | ❌ | ❌ | ✅ (per team, via account team, 10% model uplift) |
| Cursor Router (2.2) | ❌ | ❌ | ✅ | ✅ (off by default — enable manually) |
| Model Access Control (2.2) | ❌ | ❌ | ❌ | ✅ |
| .cursorignore (2.3) | ✅ | ✅ | ✅ | ✅ (plus org-wide Cursor Ignore Configuration) |
| Custom model endpoint (2.4) | ✅ | ✅ | ✅ | ✅ |
| MCP Allowlisting (4.1) | ❌ (no MCP) | Manual | Manual | ✅ Centralized |
| MCP Tool Protection (4.2) | ❌ (no MCP) | ✅ | ✅ | ✅ (plus .cursor Directory Protection) |
| Run Modes / Disable Auto-Run (5.1) | ✅ | ✅ | ✅ | ✅ (enforceable via Auto Run Configuration) |
| Agent Sandbox & Network Posture (5.2) | ✅ | ✅ | ✅ | ✅ (team sandbox networking rules) |
| Cloud Agents (5.3) | ❌ | ✅ | ✅ | ✅ |
| Self-Hosted Agents (5.3) | ❌ | ❌ | ❌ | ✅ |
| Rules File Audit (6.1) | ✅ | ✅ | ✅ | ✅ |
| Workspace Trust (7.1) | ✅ | ✅ | ✅ | ✅ (enforceable) |
| Extension Allowlist (8.1) | ❌ | ❌ | ❌ | ✅ |
| Telemetry Control (9.1) | ✅ | ✅ | ✅ | ✅ |
| Audit Logs (10.1) | ❌ | ❌ | ❌ | ✅ |
| Log Streaming (10.1) | ❌ | ❌ | ❌ | ✅ (on request) |
| Admin API (1.4, 2.1, 2.2, 3.3, 10.1, 11.1) | ❌ | ❌ | ✅ (members, usage, spend) | ✅ (adds audit logs, model access) |
| Organization Policies (11.1) | ❌ | ❌ | Partial | ✅ |
| MDM Enforcement (11.2) | ❌ | ❌ | ❌ | ✅ |
| Hooks — User/Project scope (11.3) | ❌ | ✅ | ✅ | ✅ |
| Hooks — Team/Enterprise distribution (11.3) | ❌ | ❌ | ❌ | ✅ (dashboard, ~30 min sync) |
| CMEK (11.1) | ❌ | ❌ | ❌ | ✅ |
| AI Code Tracking API (11.1) | ❌ | ❌ | ❌ | ✅ |

---

## Appendix B: Security Incidents and CVEs

| Date | CVE/ID | Name | Severity | Description | Fixed In |
|------|--------|------|----------|-------------|----------|
| Mar 2025 | None | Rules File Backdoor | High | Hidden Unicode in `.cursorrules` injects invisible backdoors (Pillar Security) | Attack class |
| Jun 2025 | None | Malicious Extension | High | Fake Solidity extension on Open VSX → $500K crypto theft (Kaspersky) | Removed |
| Aug 2025 | CVE-2025-54135 | CurXecute | 8.6 | RCE via MCP prompt injection (AIM Security) | v1.3 |
| Aug 2025 | CVE-2025-54136 | MCPoison | 7.2 | Persistent MCP trust bypass (Check Point) | v1.3 |
| Sep 2025 | None | Workspace Trust Bypass | High | Auto-exec via disabled Workspace Trust (Oasis Security) | Design choice |
| Sep 2025 | CVE-2025-59944 | Case-Sensitivity Bypass | 8.0 | File protection bypass on macOS/Windows (Lakera) | v1.7 |
| Sep 2025 | CVE-2025-61590 | Workspace RCE | High | RCE via .code-workspace files (Geordie AI) | v1.7 |
| Sep 2025 | CVE-2025-61591 | OAuth MCP Impersonation | High | MCP server impersonation via OAuth (Geordie AI) | v1.7 |
| Sep 2025 | CVE-2025-61592 | CLI Config Exploit | High | RCE via manipulated CLI config (Geordie AI) | v1.7 |
| Sep 2025 | CVE-2025-61593 | CLI Agent Overwrite | High | Sensitive file overwrite via CLI agent (Geordie AI) | v1.7 |
| Nov 2025 | GHSA-vhc2-fjv4-wqch | Cursorignore Bypass | Medium | AI agents read files protected by `.cursorignore` | Cursor 1.7.23 |
| Nov 2025 | CVE-2025-64106 | MCP Install Trust | 8.8 | MCP deep-link install bypasses the security warning and conceals executed commands (Cursor advisory GHSA-4575-fh42-7848) | After 1.7.28 |
| Dec 2025 | None | Extension Recommendation | Medium | IDE recommends non-existent extensions on Open VSX (Koi Security) | Dec 1, 2025 |
| Dec 2025 | GHSA-82wg-qcm4-fp2w | Terminal Allowlist Bypass | High | Environment variable manipulation bypasses command denylist | Patched |
| 2025 | None | NomShub | Critical | Persistent remote access via sandbox breakout (Straiker) | v3.0 |
| 2026 | CVE-2026-22708 | Shell Builtin Bypass | High | Shell builtins bypass command allowlist for sandbox escape (Straiker) | Patched |
| Ongoing | 94+ CVEs | Chromium N-Days | Various | Cursor runs Chromium 6 major versions behind; 94+ unpatched CVEs (OX Security) | Unresolved |

**Minimum safe version:** Cursor 1.7+ (patches all September 2025 CVEs). Recommended: latest stable release.

---

## Appendix C: Compliance Framework Mappings

### OWASP Top 10 for LLM Applications (2025)

| OWASP LLM ID | Risk | Guide Controls |
|---------------|------|----------------|
| LLM01 | Prompt Injection | 4.1, 4.2, 5.1, 6.1, 6.2, 7.1 |
| LLM02 | Sensitive Information Disclosure | 2.1, 2.3, 3.1, 7.2, 9.1 |
| LLM03 | Supply Chain | 4.1, 6.1, 8.1 |
| LLM05 | Improper Output Handling | 5.1, 7.2 |
| LLM06 | Excessive Agency | 4.2, 5.1, 5.2, 5.3 |

### OWASP Top 10 for Agentic Applications (2026)

| OWASP Agentic ID | Risk | Guide Controls |
|-------------------|------|----------------|
| ASI01 | Agent Goal Hijacking | 5.1, 6.1, 7.1 |
| ASI02 | Tool Misuse | 4.2, 5.1 |
| ASI03 | Identity and Privilege Abuse | 4.2, 5.1, 5.2 |
| ASI04 | Memory Poisoning | 6.1, 6.2 |
| ASI05 | Supply Chain Risks | 4.1, 8.1 |
| ASI06 | Code Execution | 5.1, 5.2 |
| ASI10 | Rogue Agents | 10.2 |

### NIST AI RMF and MITRE ATLAS

| Framework | Reference | Guide Controls |
|-----------|-----------|----------------|
| **NIST AI RMF** GOVERN 1.4 | AI deployment controls | 2.4, 5.3, 11.1 |
| **NIST AI RMF** GOVERN 1.7 | AI data governance | 2.1, 2.3 |
| **NIST AI RMF** MAP 1.5 | Risk characterization | 4.1 |
| **NIST AI RMF** MANAGE 1.3 | Deployment risk mgmt | 5.3, 11.1 |
| **NIST SP 800-218A** PW.5.1 | Injection prevention | 4.1, 6.1 |
| **NIST SP 800-218A** PW.7.1 | Code review | 6.2 |
| **MITRE ATLAS** AML.T0051 | LLM prompt injection | 6.1, 7.1 |
| **MITRE ATLAS** AML.T0061 | AI agent tools | 5.1, 5.2 |
| **MITRE ATLAS** AML.T0063 | Poisoned AI agent tool | 4.1 |

---

## Appendix D: References

**Official Cursor Documentation:**
- [Cursor Agent Security](https://cursor.com/docs/agent/security)
- [Cursor Hooks](https://cursor.com/docs/agent/hooks)
- [Cursor Privacy and Data Governance Docs](https://cursor.com/docs/enterprise/privacy-and-data-governance)
- [Cursor Identity and Access Management](https://cursor.com/docs/enterprise/identity-and-access-management)
- [Cursor Network Configuration](https://cursor.com/docs/enterprise/network-configuration)
- [Cursor Deployment Patterns](https://cursor.com/docs/enterprise/deployment-patterns)
- [Cursor Ignore Files](https://cursor.com/docs/reference/ignore-file)
- [Cursor Run Modes and Sandboxing](https://cursor.com/docs/agent/security/run-modes)
- [Cursor sandbox.json Reference](https://cursor.com/docs/reference/sandbox)
- [Cursor MCP](https://cursor.com/docs/mcp)
- [Cursor Router](https://cursor.com/docs/cursor-router)
- [Cursor Team SSO](https://cursor.com/docs/account/teams/sso)
- [Cursor SCIM](https://cursor.com/docs/account/teams/scim)
- [Cursor Team Dashboard](https://cursor.com/docs/account/teams/dashboard)
- [Cursor Admin API](https://cursor.com/docs/account/teams/admin-api)
- [Cursor Compliance and Monitoring](https://cursor.com/docs/enterprise/compliance-and-monitoring)
- [Cursor Cloud Agents Settings](https://cursor.com/docs/cloud-agent/settings)
- [Cursor Changelog](https://cursor.com/changelog)
- [Cursor Data Use & Privacy](https://cursor.com/data-use)
- [Cursor DPA](https://cursor.com/terms/dpa)

> **Currency note (2026-09).** Cursor ships faster than a guide revision cycle. The agent sandboxing and audit-log claims that the 2026-08 revision could not re-verify (both source URLs returned 404 then) are documented again — at [Run Modes](https://cursor.com/docs/agent/security/run-modes) and [Compliance and Monitoring](https://cursor.com/docs/enterprise/compliance-and-monitoring) — and 5.2 and 10.1 are now written against those pages. Cursor's Trust Center and `/security` marketing page have been removed from this list under the repository's source standard: they describe certifications, not configuration. Cursor also carries a known Tier 3 exposure gap in this repository's source coverage; independent research beyond the incidents in Appendix B was not re-surveyed in this pass and warrants a dedicated search budget.

**Third-Party Benchmarks:**
- No CIS Benchmark, DISA STIG, or CISA SCuBA baseline exists for Cursor as of 2026-08. Compliance mappings in this guide are to NIST 800-53, SOC 2, ISO 27001, OWASP LLM/Agentic, NIST AI RMF, and MITRE ATLAS by name.

**VSCode Security (Cursor inherits):**
- [Workspace Trust](https://code.visualstudio.com/docs/editor/workspace-trust)
- [Extension Security](https://code.visualstudio.com/api/references/extension-manifest)

**CVE and Vulnerability Research:**
- [Tenable: CurXecute and MCPoison FAQ](https://www.tenable.com/blog/faq-cve-2025-54135-cve-2025-54136-vulnerabilities-in-cursor-curxecute-mcpoison)
- [Check Point Research: MCPoison](https://research.checkpoint.com/2025/cursor-vulnerability-mcpoison/)
- [Lakera: CVE-2025-59944](https://www.lakera.ai/blog/cursor-vulnerability-cve-2025-59944)
- [Cursor Security Advisory GHSA-4575-fh42-7848: CVE-2025-64106](https://github.com/cursor/cursor/security/advisories/GHSA-4575-fh42-7848) — the original Cyata write-up now redirects to an unrelated page
- [Geordie AI: Multiple Cursor CVEs](https://www.geordie.ai/resources/technical-advisory-multiple-vulnerabilities-in-cursor-ai-code-editor)
- [Oasis Security: Workspace Trust Bypass](https://www.oasis.security/blog/cursor-security-flaw)
- [Straiker: NomShub Sandbox Breakout](https://www.straiker.ai/blog/nomshub-cursor-remote-tunneling-sandbox-breakout)
- [Pillar Security: Rules File Backdoor](https://www.pillar.security/blog/new-vulnerability-in-github-copilot-and-cursor-how-hackers-can-weaponize-code-agents)
- [HiddenLayer: Control Token Abuse](https://hiddenlayer.com/innovation-hub/how-hidden-prompt-injections-can-hijack-ai-code-assistants-like-cursor/)
- [Kaspersky: $500K Crypto Theft via Extension](https://www.kaspersky.com/about/press-releases/kaspersky-uncovers-500k-crypto-heist-through-malicious-packages-targeting-cursor-developers)
- [OX Security: 94 Chromium Vulnerabilities](https://www.ox.security/blog/94-vulnerabilities-in-cursor-and-windsurf-put-1-8m-developers-at-risk/)

**Industry Frameworks:**
- [OWASP Top 10 for LLM Applications (2025)](https://genai.owasp.org/resource/owasp-top-10-for-llm-applications-2025/)
- [OWASP Top 10 for Agentic Applications (2026)](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/)
- [NIST AI Risk Management Framework](https://www.nist.gov/itl/ai-risk-management-framework)
- [NIST SP 800-218A: Secure Software Development for GenAI](https://csrc.nist.gov/pubs/sp/800/218/a/final)
- [MITRE ATLAS](https://atlas.mitre.org/)
- [OpenSSF: Security-Focused Guide for AI Code Assistant Instructions](https://best.openssf.org/Security-Focused-Guide-for-AI-Code-Assistant-Instructions.html)
- [CSA R.A.I.L.G.U.A.R.D. Framework](https://cloudsecurityalliance.org/blog/2025/05/06/secure-vibe-coding-level-up-with-cursor-rules-and-the-r-a-i-l-g-u-a-r-d-framework)

**Government Guidance:**
- [NCSC: Guidelines for Secure AI System Development](https://www.ncsc.gov.uk/collection/guidelines-secure-ai-system-development)
- [NSA: Deploying AI Systems Securely](https://media.defense.gov/2024/Apr/15/2003439257/-1/-1/0/CSI-DEPLOYING-AI-SYSTEMS-SECURELY.PDF)
- [NSA: AI Data Security](https://media.defense.gov/2025/May/22/2003720601/-1/-1/0/CSI_AI_DATA_SECURITY.PDF)

**Community Resources:**
- [Endor Labs: Cursor Security 2026](https://www.endorlabs.com/learn/cursor-security)
- [MintMCP: Cursor Security Guide](https://www.mintmcp.com/blog/cursor-security)
- [matank001/cursor-security-rules (GitHub)](https://github.com/matank001/cursor-security-rules)
- [brighton-labs/railguard-cursor-coding (GitHub)](https://github.com/brighton-labs/railguard-cursor-coding)
- [slowmist/MCP-Security-Checklist (GitHub)](https://github.com/slowmist/MCP-Security-Checklist)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-09-25 | 0.5.0 | ai-drafted | validate-hth-guide Phase 5 fix pass plus its independent-audit response (no live surface verified — Hobby account behind a sign-in wall, Cursor app not installed — so maturity is unchanged). Corrected against current vendor docs: 1.1 sign-in methods are email magic link, Google, or GitHub (not email/password); 1.3 SSO is Teams and Enterprise, dashboard path, and domain verification is the enforcement (no toggle); 1.4 SCIM wizard path and roles; 2.1 provider list, Privacy Mode wording, Enterprise default, team path; 2.2 router availability and defaults, Model Access Control, Impose Auto; 2.3 `.cursorignore` does not cover terminal/MCP tools, hierarchical/global ignore, removed `.cursorindexingignore`; 2.4 requests still transit Cursor's backend; 3.2/3.3 Anthropic console moved to platform.claude.com; 4.1 MCP Configuration path; 4.2 MCP follows Run Modes, file protections; 5.1 Auto-review default since 3.6; 5.2 documented sandbox and `sandbox.json`; 5.3 Cloud Agents never prompt; 10.1 audit log always on (Enterprise), streaming on request, stale caveat replaced; 11.2 Linux `policy.json`, no Privacy Mode policy; 11.3 `failClosed`; Appendix A rebuilt on Hobby/Individual/Teams/Enterprise; CVE-2025-64106 citation replaced with the vendor advisory. Code: new api/ packs (1.4, 2.1, 2.2, 3.3, 10.1, 11.1) on the Cursor Admin API, new config/ packs (4.2, 5.2, 7.2, 10.2, 11.2, 11.3); fixed fail-open or destructive packs (2.3 overwrite, 3.1 placeholder append, 3.2 key clobber, 4.1 secret printing, 6.1 BSD-grep fail-open, 8.1/10.1 exit 0 on no data); every api/ pack now exits 2 on an HTTP 200 whose body lacks the documented response shape (and 1.4, 3.3, 11.1 on zero members) instead of passing on nothing, and 8.1 no longer trusts a `cursor` CLI that fails; removed undocumented settings keys (2.1, 5.1, 9.1, 9.2); every pack carries an HTH Pack Contract v1 header; `**Automation:**` verdicts added to 1.1, 1.2, 1.3, 2.4, 5.3 | Claude Code (Opus 5.5) |
| 2026-08-08 | 0.4.0 | ai-drafted | Add 11.3 Cursor Hooks as an enforcement layer (event classes, Enterprise→Team→Project→User precedence, per-platform config paths, fail-open default, ~30 min dashboard sync). Rewrite 2.2 around Cursor Router model governance (on by default for Teams; routed model hidden by default; mode restrictions; soft/hard enforcement). Add US-only data residency and restricted-model retention approvals to 2.1. Replace the 9.2 endpoint table with Cursor's documented hosts, add `*.cursorvm.com` cloud-agent VMs, and remove `*.cursor.com` and `marketplace.visualstudio.com` (not in the vendor list). Correct exact identifiers in 1.4, 7.1, 8.1, 11.2 (`cursorAuth.allowedTeamId`/`AllowedTeamId`, `extensions.allowed`/`AllowedExtensions` with MDM override and 2.1+ version floor, `security.workspace.trust.enabled`/`WorkspaceTrustEnabled`, three roles, SCIM requires Enterprise with SSO). Reframe 4.2, 5.1, and 5.2 around the current approval-tier model and quote the vendor's "best-effort guardrails rather than a hard security boundary" caveat. Soften 5.2 sandbox internals and 10.1 audit-log specifics — both source URLs now 404, annotated rather than asserted. Add missing **Attack Prevented** to 2.2, 2.4, 4.2, 5.2, 6.2, 9.1, 10.1, 10.2, 11.1, 11.2, 11.3. Remove Trust Center and `/security` marketing references | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.3.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2026-04-15 | 0.3.0 | ai-drafted | [SECURITY] Major update: add MCP Server Security (sec 4), Agent & Sandbox Security (sec 5), Rules File Security (sec 6), SSO/SCIM (1.3-1.4), .cursorignore (2.3), extension supply chain (8.1), agent monitoring (10.2), MDM enforcement (11.2). Update Security Incidents appendix with 12+ new CVEs/vulns. Add OWASP Agentic/LLM, NIST AI RMF, MITRE ATLAS compliance mappings. Update edition compatibility for Teams/Enterprise tiers. Create 12 code pack files. | Claude Code (Opus 4.6) |
| 2026-02-19 | 0.2.0 | ai-drafted | Migrate all inline code blocks to Code Packs (sections 2.1, 3.1, 3.2, 3.3, 4.2, 7.1) | Claude Code (Opus 4.6) |
| 2025-12-15 | 0.1.0 | ai-drafted | Initial Cursor hardening guide | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)

---

**Questions or feedback?**
- GitHub Discussions: [Link]
- GitHub Issues: [Link]

---

**Built with focus on securing AI-powered development tools while maintaining developer productivity.**
