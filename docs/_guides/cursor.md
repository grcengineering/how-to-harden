---
layout: guide
title: "Cursor Hardening Guide"
vendor: "Anysphere"
slug: "cursor"
tier: "1"
category: "DevOps"
description: "AI code editor security hardening for code privacy, MCP security, agent sandboxing, API key management, and workspace trust"
version: "0.3.0"
maturity: "draft"
last_updated: "2026-04-15"
---


**Product Editions Covered:** Cursor Free, Cursor Pro, Cursor Teams, Cursor Enterprise

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
- **L1 (Baseline):** Essential controls for all organizations using Cursor
- **L2 (Hardened):** Enhanced controls for organizations with sensitive codebases
- **L3 (Maximum Security):** Strictest controls for regulated industries or high-security environments

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

**Profile Level:** L1 (Baseline)
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
- Decision on authentication method (email/password, GitHub OAuth, Google OAuth)
- Communication plan for mandatory account creation

#### ClickOps Implementation

**Step 1: Require Login**
1. Open Cursor → **Settings** (Cmd/Ctrl + ,)
2. Navigate to: **Cursor Settings**
3. Ensure **Sign in to Cursor** is completed
4. For team deployments: Use Cursor Teams or Enterprise to enforce authentication

**Step 2: Configure Authentication Method**
1. Go to: https://cursor.com/settings
2. Choose authentication provider:
   - **Email/Password:** Basic authentication
   - **GitHub OAuth:** Recommended for developer workflows
   - **Google Workspace:** Recommended for G Suite organizations
3. Complete authentication flow

**Step 3: Verify Authentication Status**
1. In Cursor, check bottom-right status bar for account email
2. Verify account is active and authenticated

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

**Profile Level:** L2 (Hardened)
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

### 1.3 Configure SSO with SAML/OIDC (Enterprise)

**Profile Level:** L2 (Hardened)
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
- Cursor Enterprise plan
- IdP with SAML 2.0 support (Okta, Microsoft Entra ID, Google Workspace, OneLogin)

#### ClickOps Implementation

**Step 1: Configure SSO in Cursor Admin Dashboard**
1. Navigate to: https://cursor.com/dashboard → **Settings** → **Single Sign-On (SSO)**
2. Select your IdP type (SAML 2.0 or OIDC)
3. Enter IdP metadata URL or upload metadata XML
4. Configure attribute mapping:
   - `email` → user email
   - `name` → display name
5. Save configuration

**Step 2: Configure IdP Side**
1. In your IdP, create a new SAML/OIDC application for Cursor
2. Set ACS URL and Entity ID provided by Cursor dashboard
3. Assign users/groups to the Cursor application

**Step 3: Enforce SSO-Only Authentication**
1. In Cursor dashboard: Enable **Require SSO for all team members**
2. This disables local login for all team members

**Step 4: Verify SSO Flow**
1. Sign out of Cursor
2. Attempt sign in — should redirect to IdP login
3. Complete IdP authentication
4. Verify automatic redirect back to Cursor with active session

**Time to Complete:** ~30 minutes

#### Validation & Testing
1. Verify SSO login flow completes without errors
2. Test that local login is blocked when SSO is enforced
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

**Profile Level:** L2 (Hardened)
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
- Cursor Enterprise plan
- SSO configured (Control 1.3)
- IdP with SCIM 2.0 support

#### ClickOps Implementation

**Step 1: Generate SCIM Token**
1. In Cursor dashboard → **Settings** → **SCIM Provisioning**
2. Generate a SCIM bearer token
3. Copy the SCIM endpoint URL and token

**Step 2: Configure IdP SCIM Client**
1. In your IdP, open the Cursor SAML application settings
2. Enable SCIM provisioning
3. Enter the SCIM endpoint URL and bearer token from Step 1
4. Configure provisioning actions:
   - **Create Users:** Enabled
   - **Update User Attributes:** Enabled
   - **Deactivate Users:** Enabled
5. Map IdP groups to Cursor roles (Member, Admin)

**Step 3: Test Provisioning**
1. Assign a test user to the Cursor application in IdP
2. Verify user appears in Cursor dashboard within minutes
3. Remove the test user from IdP
4. Verify user is deactivated in Cursor

**Time to Complete:** ~30 minutes

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.2 | Prior to issuing access, authorization is verified |
| **NIST 800-53** | AC-2 | Account management |
| **ISO 27001** | A.9.2.6 | Removal or adjustment of access rights |

---

## 2. AI Privacy & Data Controls

### 2.1 Enable Privacy Mode for Sensitive Codebases

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-4

#### Description
Configure Cursor's Privacy Mode to prevent code from being stored or used for training by third-party AI providers. When enabled, Cursor has zero data retention agreements with OpenAI, Anthropic, Google, xAI, and Fireworks. Code enters volatile memory for processing and is discarded.

#### Rationale
**Why This Matters:**
- Without Privacy Mode, Cursor may store codebase data, prompts, and code snippets to improve AI features and train models
- For accounts created after October 15, 2025, prompts may be shared with OpenAI when using their models
- Fireworks (Cursor's inference provider) may collect prompts to improve inference speed
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
4. For Teams/Enterprise: Enable org-wide enforcement in admin dashboard to prevent individual override

**Step 2: Configure Per-Workspace Privacy**

For granular control, add privacy settings to workspace configuration:

{% include pack-code.html vendor="cursor" section="2.1" %}

**Step 3: Verify Privacy Mode Active**
1. Check Cursor status bar for Privacy Mode indicator
2. Run the verification commands from the Code Pack

**Time to Complete:** ~5 minutes per workspace

#### Validation & Testing

{% include pack-code.html vendor="cursor" section="2.1" %}

**Expected result:** No code sent to external AI services for retention or training

#### Monitoring & Maintenance

**Alert on Privacy Mode Bypass:**
- Monitor for network connections to `api.openai.com`, `api.anthropic.com` that bypass Cursor's proxy
- Use endpoint security tools to detect unauthorized AI API calls

**Important caveat:** Regardless of model selection, some requests may route through OpenAI or Anthropic for background summarization tasks. In Privacy Mode, these still have zero data retention, but the routing itself is worth noting for strict data flow requirements.

**Maintenance schedule:**
- **Weekly:** Verify Privacy Mode still enabled in settings
- **Monthly:** Audit developer workspaces for privacy settings compliance
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

### 2.2 Configure AI Provider Restrictions

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-7

#### Description
Restrict which AI providers Cursor can use. Allow only approved providers with acceptable data processing agreements.

#### Rationale
**Why This Matters:**
- Cursor routes requests to multiple providers: OpenAI, Anthropic, Google (Gemini), xAI, and Fireworks
- Different providers have varying data retention, training, and compliance policies
- Organizations may have specific vendor approval processes

#### ClickOps Implementation

**Step 1: Review AI Provider Settings**
1. Open Cursor → **Settings** → **Cursor Settings**
2. Navigate to: **Models**
3. Review enabled providers and models

**Step 2: Restrict to Approved Providers**
1. For Enterprise: Use admin dashboard to configure allowed models at the organization level
2. For individual users: Disable BYOK (Bring Your Own Key) for unapproved providers

**Step 3: Verify Provider Restrictions**
1. Attempt to use disabled provider in chat
2. Should show error: "Model not available"

#### Recommended Provider Security Posture

| Provider | Data Retention | Training on Data | SOC 2 | Zero Retention Agreement | Recommendation |
|----------|---------------|------------------|-------|--------------------------|----------------|
| **OpenAI API** | 30 days (default) | No (API) | Yes | Yes (via Cursor Privacy Mode) | Approved with Privacy Mode |
| **Anthropic** | Not used for training | No | Yes | Yes (via Cursor Privacy Mode) | Approved |
| **Google Gemini** | Varies by tier | Enterprise: No | Yes | Via Vertex AI | Review DPA |
| **Fireworks** | Temporary (inference) | No | Yes | Yes (via Cursor) | Approved with Privacy Mode |
| **Local Models** | Local only | No | N/A | N/A | Highest security (L3) |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC9.2 | Third-party vendor management |
| **NIST 800-53** | SA-9 | External system services |
| **OWASP LLM** | LLM03 | Supply chain vulnerabilities |

---

### 2.3 Configure .cursorignore for Sensitive Files

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, SC-4

#### Description
Create a `.cursorignore` file to exclude sensitive files and directories from being sent to Cursor's servers for AI processing, indexing, or embedding. This is a critical data boundary control.

#### Rationale
**Why This Matters:**
- Cursor sends code context (recently viewed files, surrounding code) to AI providers on every keystroke for Tab completions
- Codebase indexing uploads code chunks for embedding computation
- Without `.cursorignore`, secrets, credentials, and proprietary configuration may be included in AI context
- `.cursorignore` provides a hard block — AI cannot see excluded files even if explicitly referenced

**Known Limitation:** `.cursorignore` is described as "best-effort" by Cursor. Bugs may allow ignored files through in certain cases (see GHSA-vhc2-fjv4-wqch). Use `.cursorignore` as defense-in-depth alongside secret scanning and Privacy Mode, not as a sole control.

**Attack Prevented:** Credential leakage via AI context, sensitive data exposure to AI providers

#### ClickOps Implementation

**Step 1: Create .cursorignore File**

Add a `.cursorignore` file to your project root:

{% include pack-code.html vendor="cursor" section="2.3" %}

**Step 2: Also Create .cursorindexingignore (Optional)**
- `.cursorignore` — hard block from both AI access and indexing
- `.cursorindexingignore` — excludes from indexing only; files remain accessible to AI features if explicitly referenced

Use `.cursorignore` for secrets and credentials. Use `.cursorindexingignore` for large non-sensitive files (vendor directories, build artifacts).

**Step 3: Commit to Repository**
1. Add `.cursorignore` to version control
2. Standardize across all organizational repositories

**Time to Complete:** ~10 minutes

#### Validation & Testing

{% include pack-code.html vendor="cursor" section="2.3" %}

**Expected result:** All critical patterns present and sensitive files excluded from AI context

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | AC-3 | Access enforcement |
| **NIST 800-53** | SC-4 | Information in shared resources |
| **OWASP LLM** | LLM02 | Sensitive information disclosure |

---

### 2.4 Enable Local AI Models (L3 Maximum Security)

**Profile Level:** L3 (Maximum Security)
**NIST 800-53:** SC-4, SC-7

#### Description
Configure Cursor to use only local AI models (running on-premises or on developer machines) instead of cloud-based AI services. This provides maximum code privacy — zero code leaves the organization's network.

#### Rationale
**Why This Matters:**
- Zero code leaves the organization's network
- Complete control over model and data processing
- Meets strictest compliance requirements (defense, healthcare, financial)

**Use Cases:**
- Government contractors with classified code
- Healthcare orgs processing PHI/ePHI
- Financial institutions with proprietary trading algorithms

#### ClickOps Implementation

**Step 1: Install Local Model Backend**

Options:
- **Ollama:** Local LLM runtime (supports CodeLlama, Qwen2.5-Coder, DeepSeek-Coder, etc.)
- **LM Studio:** Local model management with OpenAI-compatible API
- **Custom OpenAI-compatible API:** Self-hosted models (vLLM, TGI)

**Step 2: Configure Cursor to Use Local Model**
1. Open Cursor → **Settings**
2. Navigate to: **Models** → **OpenAI API Key**
3. Set custom base URL pointing to local endpoint (e.g., `http://localhost:11434/v1`)
4. Disable all cloud AI providers

**Step 3: Verify Local Model Usage**
1. Use Cursor AI chat
2. Check network traffic — should only connect to localhost
3. Verify no external API calls

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
| **ITAR** | Data Sovereignty | Code never leaves jurisdiction |
| **FedRAMP** | SC-7 | Boundary protection |
| **NIST AI RMF** | GOVERN 1.4 | AI deployment controls |

---

## 3. API Key & Credential Management

### 3.1 Use Environment Variables for API Keys (Never Hardcode)

**Profile Level:** L1 (Baseline)
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
1. Check Cursor settings for hardcoded keys:

{% include pack-code.html vendor="cursor" section="3.1" %}

2. Remove any hardcoded API keys

**Step 2: Use Environment Variables**

{% include pack-code.html vendor="cursor" section="3.1" %}

**Step 3: Verify API Keys Not in Settings**

{% include pack-code.html vendor="cursor" section="3.1" %}

**Time to Complete:** ~10 minutes

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

**Profile Level:** L2 (Hardened)
**NIST 800-53:** IA-5(1)

#### Description
Establish a quarterly rotation schedule for all AI provider API keys used with Cursor.

#### Rationale
**Why This Matters:**
- Limits exposure window if keys compromised
- Follows secret management best practices
- Required by many compliance frameworks

#### ClickOps Implementation

**Step 1: Create API Key Rotation Schedule**
1. Document all API keys in use (OpenAI, Anthropic, Google, custom providers)
2. Set quarterly rotation reminders

**Step 2: Rotate Keys**

For OpenAI:
1. Visit: https://platform.openai.com/api-keys
2. Click **Create new secret key**
3. Update environment variable:

{% include pack-code.html vendor="cursor" section="3.2" %}

4. Restart Cursor
5. Verify new key works
6. **Revoke old key** on OpenAI platform

For Anthropic:
1. Visit: https://console.anthropic.com/settings/keys
2. Generate new key → Update environment → Revoke old key

**Time to Complete:** ~15 minutes per provider

---

### 3.3 Monitor API Key Usage and Costs

**Profile Level:** L2 (Hardened)

#### Description
Monitor AI provider API usage to detect anomalies (unusual spikes, unauthorized usage, cost overruns).

#### ClickOps Implementation

**Step 1: Enable Usage Tracking**

For OpenAI:
1. Visit: https://platform.openai.com/usage
2. Set up billing alerts:
   - **Soft limit:** Warning at $X per month
   - **Hard limit:** Block at $Y per month

For Anthropic:
1. Visit: https://console.anthropic.com/settings/billing
2. Configure usage alerts

**Step 2: Review Usage Regularly**
- **Daily:** Check for cost spikes
- **Weekly:** Review usage patterns
- **Monthly:** Analyze per-user usage (if using organization accounts)

---

## 4. MCP Server Security

### 4.1 Audit and Allowlist MCP Servers

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7, SA-9

#### Description
Audit all configured MCP (Model Context Protocol) servers and restrict usage to an approved allowlist. MCP servers extend Cursor's capabilities by connecting to external tools and services, but represent one of the most significant attack surfaces — three CVEs in 2025 directly exploited MCP configuration.

#### Rationale
**Why This Matters:**
- MCP server installation (via `pip install` or `npx`) executes arbitrary code with full user permissions — no sandboxing by default
- CVE-2025-54135 (CurXecute): Prompt injection via MCP-connected services (e.g., Slack) rewrote `mcp.json` and executed arbitrary commands
- CVE-2025-54136 (MCPoison): After initial approval, attackers silently swapped benign MCP configs with malicious payloads for persistent RCE
- CVE-2025-64106: Insufficient validation in MCP deep-link handling enabled malicious server impersonation
- 53% of MCP servers rely on static API keys or PATs that are rarely rotated
- 43% of tested MCP implementations had unsafe shell calls exposing them to command injection

**Attack Prevented:** Remote code execution via MCP prompt injection, persistent team-wide compromise, supply chain poisoning

**Real-World Context:**
- Between January-February 2026, over 30 CVEs were filed targeting MCP servers, clients, and infrastructure
- Among 2,614 MCP implementations surveyed, 82% use file operations vulnerable to path traversal

#### Prerequisites
- Inventory of all MCP servers in use across the organization
- Enterprise plan for centralized MCP allowlisting

#### ClickOps Implementation

**Step 1: Audit Existing MCP Configurations**

{% include pack-code.html vendor="cursor" section="4.1" %}

**Step 2: Establish MCP Allowlist**
1. For Enterprise: Navigate to admin dashboard → **MCP Servers** → Configure allowlist
2. Add only vetted, organizationally-approved MCP servers
3. Block all other MCP server installations

**Step 3: Secure MCP Config File Permissions**

{% include pack-code.html vendor="cursor" section="4.1" %}

**Step 4: Monitor MCP Configuration Changes**
1. Set up file integrity monitoring on `.cursor/mcp.json` (project and global)
2. Alert on any modification to MCP configuration files
3. Require re-approval for any MCP configuration change (enforced in Cursor 1.3+)

**Time to Complete:** ~30 minutes

#### Validation & Testing
1. Verify only approved MCP servers are configured
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

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-6

#### Description
Enable MCP Tool Protection to require explicit user approval before any MCP tool executes. This prevents prompt injection from triggering MCP tool calls without user consent.

#### Rationale
**Why This Matters:**
- Without tool protection, a prompt injection payload in a repository file or chat message can trigger MCP tools automatically
- MCP tools can read files, execute commands, and make network requests with the developer's full privileges
- Tool Protection ensures human-in-the-loop for all MCP operations

#### ClickOps Implementation

**Step 1: Enable MCP Tool Protection**
1. Open Cursor → **Settings**
2. Navigate to: **Features** → **MCP**
3. Ensure **Require approval for tool calls** is enabled (this is now the default in Cursor 1.3+)

**Step 2: Also Enable Dotfile Protection**
1. In same settings area, enable **Dotfile Protection**
2. This prevents AI from modifying sensitive files: `.env`, `.ssh/config`, `.aws/credentials`, etc.

**Time to Complete:** ~5 minutes

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-6 | Least privilege |
| **OWASP Agentic** | ASI02 | Tool misuse |
| **OWASP Agentic** | ASI03 | Identity and privilege abuse |

---

## 5. Agent & Sandbox Security

### 5.1 Disable Auto-Run Mode

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7, AC-6

#### Description
Disable Cursor's auto-run mode (sometimes called "YOLO mode") to require explicit human approval before the AI agent executes any terminal command. This is the single most impactful security control for Cursor.

#### Rationale
**Why This Matters:**
- In auto-run mode, Cursor's agent executes terminal commands without any user approval
- The command denylist uses a blocklist approach that has been repeatedly bypassed by researchers
- CVE-2026-22708 (NomShub): Shell builtins (`export`, `cd`, `eval`) bypass the command allowlist entirely because the parser only tracks external executables — enabling "deterministic, 100% reliable sandbox escape"
- GHSA-82wg-qcm4-fp2w: Environment variable manipulation bypassed the terminal allowlist
- Disabling auto-run prevents the majority of documented attack scenarios

**Attack Prevented:** Autonomous code execution, sandbox escape via shell builtins, privilege escalation, data exfiltration

**Real-World Context:**
- CyberScoop reported a one-line prompt attack that morphed Cursor's agent into a local shell with full developer privileges
- The NomShub attack chain achieved persistent remote access by chaining prompt injection → sandbox escape → `~/.zshenv` overwrite → GitHub OAuth device code hijack

#### ClickOps Implementation

**Step 1: Disable Auto-Run**
1. Open Cursor → **Settings**
2. Search for: `auto-run` or `autoRun`
3. Disable: **Agent Auto-Run**

{% include pack-code.html vendor="cursor" section="5.1" %}

**Step 2: Verify Auto-Run is Disabled**

{% include pack-code.html vendor="cursor" section="5.1" %}

**Time to Complete:** ~2 minutes

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

### 5.2 Configure Agent Sandbox

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-39, CM-7

#### Description
Enable and configure Cursor's agent sandbox to restrict file system access, network connectivity, and process execution for AI agent sessions.

#### Rationale
**Why This Matters:**
- The sandbox (GA on macOS since Cursor 2.0, all platforms since early 2026) provides filesystem isolation — writes are scoped to workspace only
- However, local agents have full filesystem read access by default, including `~/.ssh/`, `~/.aws/`, `.env` files
- macOS sandbox (Apple Seatbelt) permits writes anywhere in `~/` rather than restricting to workspace only
- Linux uses Landlock (filesystem) + seccomp (syscall blocking)
- Windows runs the Linux sandbox inside WSL2

**Known Limitation:** The sandbox is necessary but not sufficient. Researchers have demonstrated bypasses via shell builtins (NomShub) and the macOS Seatbelt scope. Use sandbox alongside disabled auto-run and network controls.

#### ClickOps Implementation

**Step 1: Enable Sandbox**
1. Open Cursor → **Settings**
2. Navigate to: **Agent** → **Security**
3. Enable: **Sandbox Mode**

**Step 2: Configure Network Access (Cursor 2.5+)**
1. In settings, navigate to: **Agent** → **Network Access**
2. Choose restriction level:
   - **Restrict to sandbox.json domains:** Most restrictive — only domains listed in project's `sandbox.json`
   - **Restrict to allowlist + Cursor defaults:** Moderate — approved domains plus Cursor's required endpoints
   - **Allow all:** Least restrictive (not recommended)
3. For Enterprise: Enforce network allowlists/denylists from admin dashboard

**Step 3: For Enterprise — Enforce Sandbox Org-Wide**
1. In admin dashboard, enable **Require Sandbox for all agent sessions**
2. Configure organization-level network allowlists

**Time to Complete:** ~10 minutes

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SC-39 | Process isolation |
| **NIST 800-53** | CM-7 | Least functionality |
| **OWASP Agentic** | ASI06 | Code execution controls |

---

### 5.3 Secure Background/Cloud Agents

**Profile Level:** L3 (Maximum Security)
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
1. For Enterprise: In admin dashboard, disable **Cloud Agents** entirely
2. Or configure agent run settings to require approval for all cloud agent operations

**Option B: Deploy Self-Hosted Cloud Agents (Enterprise)**
1. Self-hosted agents run entirely within your infrastructure using outbound-only HTTPS connections
2. Deploy via Helm chart or Kubernetes operator
3. Code, tool execution, and build artifacts never leave your environment
4. No inbound ports, firewall changes, or VPNs needed

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

**Profile Level:** L1 (Baseline)
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

{% include pack-code.html vendor="cursor" section="6.1" %}

**Step 2: Review Rules File Content for Suspicious Patterns**

{% include pack-code.html vendor="cursor" section="6.1" %}

**Step 3: Establish Rules File Governance**
1. Treat `.cursor/` directory and `.cursorrules` files as security-critical in code review — equivalent to CI/CD pipeline configurations
2. Require explicit review of all changes to rules files in pull requests
3. Maintain an approved rules file template for your organization (see CSA R.A.I.L.G.U.A.R.D. framework)

**Time to Complete:** ~15 minutes per repository

#### Validation & Testing
1. Create a test rules file with a hidden Unicode character
2. Run the scanning script — should detect and flag it
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

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CM-3

#### Description
Require mandatory code review for any changes to AI rules files (`.cursorrules`, `.cursor/rules/*.mdc`) before they are merged. Implement CODEOWNERS rules to enforce security team review.

#### Rationale
**Why This Matters:**
- Rules file changes affect all future AI interactions for the entire team
- Malicious changes can be subtle (single-line instruction additions, Unicode injection)
- Without mandatory review, a compromised contributor can silently weaponize AI output

#### ClickOps Implementation

**Step 1: Add Rules Files to CODEOWNERS**
1. In your repository, add to `.github/CODEOWNERS`:
   - `.cursorrules @security-team`
   - `.cursor/rules/ @security-team`
   - `.cursor/mcp.json @security-team`
   - `.vscode/tasks.json @security-team`
2. Enable branch protection requiring CODEOWNERS approval

**Step 2: Configure Pre-Commit Hook (Optional)**
1. Add a pre-commit hook that runs the Unicode scanning script from Control 6.1
2. Block commits containing hidden Unicode in rules files

**Time to Complete:** ~15 minutes

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | CM-3 | Configuration change control |
| **SOC 2** | CC8.1 | Changes are authorized |
| **NIST SP 800-218A** | PW.7.1 | Review code changes |

---

## 7. Workspace Trust & Code Security

### 7.1 Enable Workspace Trust for All Repositories

**Profile Level:** L1 (Baseline)
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
2. Search for: `security.workspace.trust`
3. Apply the following settings:

{% include pack-code.html vendor="cursor" section="7.1" %}

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

{% include pack-code.html vendor="cursor" section="7.1" %}

**Time to Complete:** ~5 minutes

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

**Profile Level:** L2 (Hardened)
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

---

## 8. Extension & Integration Security

### 8.1 Audit and Restrict VSCode Extensions

**Profile Level:** L1 (Baseline)
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

{% include pack-code.html vendor="cursor" section="8.1" %}

**Step 2: Remove Unnecessary Extensions**
1. Click extension → **Uninstall**
2. Focus on:
   - Extensions with <10K installs (less vetted)
   - Extensions not updated in >1 year
   - Extensions requesting network/filesystem permissions unnecessarily
   - Extensions side-loaded from `.vsix` files

**Step 3: Use Extension Allowlist (Enterprise)**
1. Configure `AllowedExtensions` MDM policy (JSON configuration specifying permitted publishers)
2. Deploy via MDM (macOS) or Group Policy/Intune (Windows)
3. Third-party plugin imports default to OFF on Enterprise (require explicit admin override)

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

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-4

#### Description
Disable telemetry data collection and crash reporting to prevent code snippets or metadata from being sent to Cursor/Microsoft.

#### Rationale
**Why This Matters:**
- Telemetry may include code snippets, file paths, or project metadata
- Crash reports can contain sensitive information
- Reduces data exposure to third parties

#### ClickOps Implementation

**Step 1: Disable All Telemetry**
1. Open Cursor → **Settings**
2. Search for `telemetry`
3. Apply the telemetry-disabling settings:

{% include pack-code.html vendor="cursor" section="9.1" %}

**Step 2: Verify Telemetry Disabled**
1. Check network traffic — should not see telemetry endpoints
2. Use tools like Little Snitch (macOS) or Wireshark to monitor

---

### 9.2 Configure Network Allowlisting

**Profile Level:** L3 (Maximum Security)
**NIST 800-53:** SC-7

#### Description
Use enterprise firewall or endpoint security to allowlist only required Cursor network endpoints, blocking all other traffic.

#### Required Endpoints

| Endpoint | Purpose | Required For |
|----------|---------|-------------|
| `*.cursor.com` | Core application services | All users |
| `*.cursor.sh` | Authentication and SSO | All users |
| `*.cursorapi.com` | API services and marketplace | All users |
| `cursor-cdn.com` | CDN for static assets | All users |
| `downloads.cursor.com` | Client downloads and updates | All users |
| `anysphere-binaries.s3.us-east-1.amazonaws.com` | Binary updates | All users |
| `marketplace.visualstudio.com` | Extension downloads (fallback) | Extension management |

**Block all other network traffic from Cursor.**

#### Network Verification

{% include pack-code.html vendor="cursor" section="9.2" %}

**Important:** All AI model requests route through Cursor's infrastructure (the domains above), not directly to `api.openai.com` or `api.anthropic.com`. Blocking direct access to AI provider APIs forces traffic through Cursor's Privacy Mode proxy.

---

## 10. Monitoring & Audit Logging

### 10.1 Enable Cursor Usage Logging

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AU-2

#### Description
Configure logging of Cursor AI usage for audit and compliance purposes. Ensure Cursor is running a patched version to benefit from all security fixes.

#### Rationale
**Why This Matters:**
- Compliance frameworks require logging of AI usage
- Detect anomalous usage patterns (insider threats)
- Attribution of AI-generated code
- Version tracking prevents use of vulnerable Cursor releases

#### ClickOps Implementation

**Step 1: Verify Cursor Version**

{% include pack-code.html vendor="cursor" section="10.1" %}

**Step 2: Enable Built-in Logging (Enterprise)**
1. In admin dashboard, navigate to **Compliance and Monitoring**
2. Enable audit logging — tracks:
   - Authentication events (logins, logouts)
   - User management (additions, removals, role changes)
   - API key management (creation, revocation)
   - Team settings changes
   - Privacy Mode changes
   - MCP server configuration changes
3. Note: Agent responses and generated code content are NOT captured in audit logs

**Step 3: Configure Log Streaming (Enterprise)**
1. Configure log forwarding to your SIEM platform
2. Supported destinations: Splunk, Datadog, Sumo Logic, webhook endpoints, S3 buckets, Elasticsearch, CloudWatch
3. Logs are JSON format with timestamps, event IDs, user details, IP addresses

### 10.2 Monitor for Suspicious Agent Activity

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AU-6, SI-4

#### Description
Monitor developer workstations for indicators of Cursor-based attacks including unexpected process spawning, shell startup file modifications, and suspicious network connections.

#### Rationale
**Why This Matters:**
- The NomShub attack chain persisted via `~/.zshenv` overwrite
- Prompt injection can spawn `curl` to exfiltrate data via agent terminal access
- Unexpected `cursor-tunnel` processes may indicate remote access exploitation

#### ClickOps Implementation

**Key Indicators to Monitor:**
1. **Shell startup file modifications:** Watch `~/.zshenv`, `~/.bashrc`, `~/.zprofile` for unexpected changes
2. **Process tree anomalies:** AI agents spawn child processes — EDR should monitor the full process tree from Cursor
3. **Unexpected network connections:** Flag outbound connections from Cursor subprocesses to non-allowlisted endpoints
4. **MCP config changes:** File integrity monitoring on `.cursor/mcp.json` (project and global)
5. **Cursor application file tampering:** Monitor for modifications to Cursor's `main.js` (malicious npm packages have overwritten this)
6. **`cursor-tunnel` processes:** Monitor for unexpected remote tunnel activity

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AU-6 | Audit record review |
| **NIST 800-53** | SI-4 | System monitoring |
| **OWASP Agentic** | ASI10 | Rogue agents |

---

## 11. Organization & Team Controls

### 11.1 Deploy Cursor Teams or Enterprise for Centralized Management

**Profile Level:** L2 (Hardened)

#### Description
Use Cursor Teams or Enterprise edition to enforce organizational policies, manage licenses, and control AI provider access centrally.

#### Rationale
**Why This Matters:**
- Centralized policy enforcement (Privacy Mode, allowed providers, MCP servers)
- License management and usage tracking
- Audit logging at organization level
- Over half of Fortune 500 now use Cursor — enterprise governance is critical

#### ClickOps Implementation

**Step 1: Set Up Cursor Teams or Enterprise**
1. Visit: https://cursor.com/pricing
2. Choose plan:
   - **Teams ($40/user/month):** SSO, org-wide Privacy Mode, usage analytics, shared rules
   - **Enterprise (custom pricing):** All Teams features plus SCIM, MDM policies, audit logs, CMEK, self-hosted agents, AI Code Tracking API
3. Create organization and invite team members

**Step 2: Configure Organization Policies**
1. In admin dashboard:
   - **Privacy Mode:** Enforce for all users (cannot be overridden)
   - **Allowed AI Models:** Restrict to approved models
   - **MCP Servers:** Configure allowlist
   - **Agent Settings:** Disable auto-run, require sandbox
   - **Extensions:** Configure allowlist
   - **Telemetry:** Disable for all users
   - **Cloud Agents:** Enable or disable per policy
   - **BYOK:** Disable if using only org-managed keys

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

---

### 11.2 Enforce Organizational Policies via MDM

**Profile Level:** L3 (Maximum Security)

#### Description
Use MDM (Mobile Device Management) to deploy and enforce Cursor security settings across all developer machines. MDM-deployed policies cannot be overridden locally.

#### Rationale
**Why This Matters:**
- Without MDM enforcement, developers can disable Privacy Mode, enable auto-run, or install unapproved MCP servers locally
- 78% of AI coding tool usage is shadow IT — MDM ensures governance even for unmanaged adoption
- MDM-deployed settings survive Cursor updates and reinstalls

#### ClickOps Implementation

**Step 1: Create MDM Configuration Profile**
1. Create a configuration profile with these key policies:
   - **Allowed Team IDs:** Comma-separated list restricting which team IDs can authenticate (prevents personal account usage on corporate devices)
   - **Allowed Extensions:** JSON configuration controlling permitted extension publishers
   - **Privacy Mode:** Force-enabled
   - **Workspace Trust:** Force-enabled

**Step 2: Deploy via MDM**
- **macOS (Jamf/Kandji):** Deploy as `.mobileconfig` XML profile
- **Windows (Intune/SCCM):** Deploy equivalent Group Policy Objects
- **Linux:** Deploy via configuration management (Ansible, Puppet, Chef)

**Step 3: Distribute Compliance Hooks**
1. Use Cursor Hooks to enforce compliance policies at runtime
2. Hooks can intercept agent actions, block unapproved commands, and scrub secrets
3. Deploy hook configurations through MDM alongside editor settings

**Time to Complete:** ~2 hours (initial setup), ongoing maintenance for policy updates

---

## Appendix A: Edition Compatibility

| Control | Cursor Free | Cursor Pro | Cursor Teams | Cursor Enterprise |
|---------|------------|-----------|-------------|-------------------|
| Account Authentication (1.1) | ✅ | ✅ | ✅ | ✅ |
| MFA (1.2) | ✅ | ✅ | ✅ | ✅ |
| SSO/SAML (1.3) | ❌ | ❌ | ✅ | ✅ |
| SCIM Provisioning (1.4) | ❌ | ❌ | ❌ | ✅ |
| Privacy Mode (2.1) | ✅ (opt-in) | ✅ (opt-in) | ✅ (enforceable) | ✅ (enforceable) |
| .cursorignore (2.3) | ✅ | ✅ | ✅ | ✅ |
| Local Models (2.4) | ✅ | ✅ | ✅ | ✅ |
| MCP Allowlisting (4.1) | Manual | Manual | Manual | ✅ Centralized |
| MCP Tool Protection (4.2) | ✅ | ✅ | ✅ | ✅ |
| Disable Auto-Run (5.1) | ✅ | ✅ | ✅ | ✅ (enforceable) |
| Agent Sandbox (5.2) | ✅ | ✅ | ✅ | ✅ (enforceable) |
| Self-Hosted Agents (5.3) | ❌ | ❌ | ❌ | ✅ |
| Rules File Audit (6.1) | ✅ | ✅ | ✅ | ✅ |
| Workspace Trust (7.1) | ✅ | ✅ | ✅ | ✅ (enforceable) |
| Extension Allowlist (8.1) | ❌ | ❌ | ❌ | ✅ |
| Telemetry Control (9.1) | ✅ | ✅ | ✅ | ✅ |
| Audit Logs (10.1) | ❌ | ❌ | Basic | ✅ Full |
| Log Streaming (10.1) | ❌ | ❌ | ❌ | ✅ |
| Organization Policies (11.1) | ❌ | ❌ | Partial | ✅ |
| MDM Enforcement (11.2) | ❌ | ❌ | ❌ | ✅ |
| CMEK (11.1) | ❌ | ❌ | ❌ | ✅ |
| AI Code Tracking API (11.1) | ❌ | ❌ | ❌ | ✅ (alpha) |

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
| Nov 2025 | CVE-2025-64106 | MCP Install Trust | 8.8 | MCP deep-link handling trust bypass (Cyata) | Patched |
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
- [Cursor Trust Center](https://trust.cursor.com/)
- [Cursor Security](https://cursor.com/security)
- [Cursor Data Use & Privacy](https://cursor.com/data-use)
- [Cursor Enterprise](https://cursor.com/enterprise)
- [Cursor Privacy and Data Governance Docs](https://cursor.com/docs/enterprise/privacy-and-data-governance)
- [Cursor Identity and Access Management](https://cursor.com/docs/enterprise/identity-and-access-management)
- [Cursor Network Configuration](https://cursor.com/docs/enterprise/network-configuration)
- [Cursor Deployment Patterns](https://cursor.com/docs/enterprise/deployment-patterns)
- [Cursor Ignore Files](https://cursor.com/docs/reference/ignore-file)
- [Cursor Agent Sandboxing Blog](https://cursor.com/blog/agent-sandboxing)
- [Cursor Self-Hosted Cloud Agents](https://cursor.com/blog/self-hosted-cloud-agents)
- [Cursor DPA](https://cursor.com/terms/dpa)

**VSCode Security (Cursor inherits):**
- [Workspace Trust](https://code.visualstudio.com/docs/editor/workspace-trust)
- [Extension Security](https://code.visualstudio.com/api/references/extension-manifest)

**CVE and Vulnerability Research:**
- [Tenable: CurXecute and MCPoison FAQ](https://www.tenable.com/blog/faq-cve-2025-54135-cve-2025-54136-vulnerabilities-in-cursor-curxecute-mcpoison)
- [Check Point Research: MCPoison](https://research.checkpoint.com/2025/cursor-vulnerability-mcpoison/)
- [Lakera: CVE-2025-59944](https://www.lakera.ai/blog/cursor-vulnerability-cve-2025-59944)
- [Cyata: CVE-2025-64106](https://cyata.ai/blog/cyata-research-critical-flaw-in-cursor-mcp-installation/)
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
| 2026-04-15 | 0.3.0 | draft | [SECURITY] Major update: add MCP Server Security (sec 4), Agent & Sandbox Security (sec 5), Rules File Security (sec 6), SSO/SCIM (1.3-1.4), .cursorignore (2.3), extension supply chain (8.1), agent monitoring (10.2), MDM enforcement (11.2). Update Security Incidents appendix with 12+ new CVEs/vulns. Add OWASP Agentic/LLM, NIST AI RMF, MITRE ATLAS compliance mappings. Update edition compatibility for Teams/Enterprise tiers. Create 12 code pack files. | Claude Code (Opus 4.6) |
| 2026-02-19 | 0.2.0 | draft | Migrate all inline code blocks to Code Packs (sections 2.1, 3.1, 3.2, 3.3, 4.2, 7.1) | Claude Code (Opus 4.6) |
| 2025-12-15 | 0.1.0 | draft | Initial Cursor hardening guide | Claude Code (Opus 4.5) |

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
