---
layout: guide
title: "Cursor Hardening Guide"
vendor: "Anysphere"
slug: "cursor"
tier: "1"
category: "DevOps"
description: "AI code editor security hardening for code privacy, API key management, and workspace trust"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-02-19"
---


**Product Editions Covered:** Cursor Free, Cursor Pro, Cursor Business

---

## Overview

Cursor is an AI-powered code editor built on VSCode that integrates large language models (LLMs) directly into the development workflow. As organizations adopt AI coding assistants, securing these tools becomes critical—they process proprietary source code, handle API credentials, and connect to multiple AI providers. Compromised AI code editors can expose intellectual property, leak secrets to third-party AI services, or introduce vulnerable code into production systems.

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
This guide covers Cursor-specific security configurations including AI privacy settings, API key management, code privacy controls, workspace trust, and organizational policies. General VSCode security and operating system hardening are out of scope.

### Why This Guide Exists

**No comprehensive security hardening guide currently exists for AI code editors.** As AI coding assistants become mission-critical development tools, securing them is essential to:
- Prevent proprietary code leakage to third-party AI providers
- Protect API keys and credentials from exposure via AI context
- Control what code gets sent to cloud AI services vs. local models
- Audit AI usage and code generation for compliance
- Manage third-party extension risks in AI-augmented workflows

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [AI Privacy & Data Controls](#2-ai-privacy--data-controls)
3. [API Key & Credential Management](#3-api-key--credential-management)
4. [Workspace Trust & Code Security](#4-workspace-trust--code-security)
5. [Extension & Integration Security](#5-extension--integration-security)
6. [Network & Telemetry Controls](#6-network--telemetry-controls)
7. [Monitoring & Audit Logging](#7-monitoring--audit-logging)
8. [Organization & Team Controls](#8-organization--team-controls)

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
4. For team deployments: Use Cursor Business to enforce authentication

**Step 2: Configure Authentication Method**
1. Go to: https://cursor.sh/settings
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
1. [ ] Attempt to use Cursor features without authentication
2. [ ] Verify AI features require authenticated account
3. [ ] Confirm account shows in Cursor status bar

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

**Attack Prevented:** Credential stuffing, password reuse attacks, phishing

#### ClickOps Implementation

**Step 1: Enable MFA on Cursor Account**
1. Visit: https://cursor.sh/settings/security
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
1. [ ] Attempt login with only password - should prompt for MFA
2. [ ] Test authenticator app generates valid codes
3. [ ] Verify recovery codes work for MFA bypass

**Expected result:** All logins require MFA verification

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Multi-factor authentication |
| **NIST 800-53** | IA-2(1) | Multi-factor authentication |
| **PCI DSS** | 8.3 | MFA for all access |

---

## 2. AI Privacy & Data Controls

### 2.1 Disable Privacy Mode for Sensitive Codebases

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-4

#### Description
Configure Cursor's Privacy Mode to prevent code from being sent to third-party AI providers (OpenAI, Anthropic, etc.). Enable Privacy Mode for repositories containing proprietary code, secrets, or regulated data.

#### Rationale
**Why This Matters:**
- By default, Cursor sends code snippets to cloud AI services for completions and chat
- Cloud AI providers may use your code for model training (depending on agreements)
- Proprietary algorithms, trade secrets, and customer data may be exposed
- Compliance regulations (GDPR, HIPAA, SOC 2) may prohibit cloud AI processing

**Attack Prevented:** Data leakage to third-party AI providers, unauthorized code exposure

**Real-World Context:**
- Samsung banned ChatGPT after engineers leaked sensitive code (April 2023)
- Multiple organizations restrict AI coding assistants due to IP concerns

#### Prerequisites
- Classification of codebases (public, internal, confidential)
- Decision on which repos require Privacy Mode
- Communication to developers about Privacy Mode policies

#### ClickOps Implementation

**Step 1: Enable Privacy Mode Globally**
1. Open Cursor → **Settings** (Cmd/Ctrl + ,)
2. Navigate to: **Cursor Settings** → **Privacy**
3. Enable: **Privacy Mode**
   - When enabled, code is NOT sent to cloud AI services
   - Only local indexing and caching occur
   - AI features requiring cloud models will be disabled

**Step 2: Configure Per-Workspace Privacy**

For more granular control:
1. Open a specific workspace/folder
2. Go to: **Workspace Settings** (.vscode/settings.json)
3. Add `"cursor.privacyMode": true` to the workspace settings (see Code Pack below for full configuration)
4. Commit `.vscode/settings.json` to repository

**Step 3: Verify Privacy Mode Active**
1. Check Cursor status bar for **Privacy Mode: ON** indicator
2. Attempt to use AI chat - should show "Privacy Mode enabled, cloud AI unavailable"

**Time to Complete:** ~5 minutes per workspace

#### Validation & Testing
1. [ ] With Privacy Mode ON, attempt AI autocomplete - should not trigger
2. [ ] Check network traffic - no requests to OpenAI/Anthropic APIs
3. [ ] Verify privacy indicator in Cursor status bar
4. [ ] Test that local features (syntax highlighting, search) still work

**Expected result:** No code sent to external AI services

#### Monitoring & Maintenance

**Alert on Privacy Mode Bypass:**
- Monitor for network connections to `api.openai.com`, `api.anthropic.com`
- Use endpoint security tools to detect unauthorized AI API calls

**Maintenance schedule:**
- **Weekly:** Verify Privacy Mode still enabled in settings
- **Monthly:** Audit developer workspaces for privacy settings compliance
- **Quarterly:** Review Privacy Mode policy effectiveness

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **Developer Productivity** | High | Cloud AI features (autocomplete, chat) disabled |
| **Code Quality** | Medium | Developers lose AI assistance for code generation |
| **Maintenance Burden** | Low | Once configured, no ongoing maintenance |
| **Rollback Difficulty** | Easy | Disable Privacy Mode in settings |

**Potential Issues:**
- Developers may disable Privacy Mode locally if not enforced
- Reduced productivity for developers relying on AI completions
- May need to provide alternative AI tools (local models, approved cloud services)

**Rollback Procedure:**
1. Open Cursor Settings
2. Navigate to Privacy
3. Disable Privacy Mode
4. Restart Cursor

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.7 | Data transmission controls |
| **NIST 800-53** | SC-4 | Information in shared system resources |
| **GDPR** | Article 28 | Processor obligations (AI providers as processors) |
| **ISO 27001** | A.13.2.1 | Information transfer policies |

---

### 2.2 Configure AI Provider Restrictions

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-7

#### Description
Restrict which AI providers Cursor can use. Allow only approved providers with acceptable data processing agreements.

#### Rationale
**Why This Matters:**
- Different AI providers have different data retention and training policies
- OpenAI, Anthropic, and others have varying compliance certifications
- Organizations may have specific vendor approval processes

#### ClickOps Implementation

**Step 1: Review AI Provider Settings**
1. Open Cursor → **Settings** → **Cursor Settings**
2. Navigate to: **AI Providers**
3. Review enabled providers:
   - OpenAI (GPT-4, GPT-3.5)
   - Anthropic (Claude)
   - Local Models (if configured)

**Step 2: Restrict to Approved Providers**
1. In Cursor Settings, configure allowed AI providers
2. Disable any providers not approved by your organization

**Step 3: Verify Provider Restrictions**
1. Attempt to use disabled provider in chat
2. Should show error: "Provider not available"

#### Recommended Provider Security Posture

| Provider | Data Retention | Training on Data | SOC 2 | GDPR DPA | Recommendation |
|----------|---------------|------------------|-------|----------|----------------|
| **OpenAI API** | 30 days | No (by default, with opt-out) | Yes | Yes | Approved with API Business tier |
| **Anthropic** | Not used for training | No | Yes | Yes | Approved |
| **Local Models** | Local only | No | N/A | N/A | Highest security (L3) |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC9.2 | Third-party vendor management |
| **NIST 800-53** | SA-9 | External system services |

---

### 2.3 Enable Local AI Models (L3 Maximum Security)

**Profile Level:** L3 (Maximum Security)
**NIST 800-53:** SC-4, SC-7

#### Description
Configure Cursor to use only local AI models (running on-premises or on developer machines) instead of cloud-based AI services. This provides maximum code privacy.

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
- **Ollama:** Local LLM runtime (supports CodeLlama, Mistral, etc.)
- **LM Studio:** Local model management
- **Custom OpenAI-compatible API:** Self-hosted models

**Step 2: Configure Cursor to Use Local Model**
1. Open Cursor → **Settings**
2. Navigate to: **AI Providers**
3. Add custom provider pointing to local endpoint (e.g., `http://localhost:11434`)

**Step 3: Verify Local Model Usage**
1. Use Cursor AI chat
2. Check network traffic - should only connect to localhost
3. Verify no external API calls

**Time to Complete:** ~1 hour (model download + configuration)

#### Performance Considerations

| Model Size | RAM Required | Performance | Use Case |
|------------|-------------|-------------|----------|
| **7B params** | 8 GB | Fast, lower quality | Quick completions |
| **13B params** | 16 GB | Balanced | General development |
| **34B params** | 32 GB+ | Slow, high quality | Complex code generation |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SC-4 | Information remnants |
| **ITAR** | Data Sovereignty | Code never leaves jurisdiction |
| **FedRAMP** | SC-7 | Boundary protection |

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
- Hardcoded keys difficult to rotate

**Attack Prevented:** API key exposure via Git history, backup theft

#### ClickOps Implementation

**Step 1: Remove Hardcoded API Keys from Settings**
1. Check Cursor settings for hardcoded keys (e.g., `"cursor.openai.apiKey": "sk-proj-..."` -- see Code Pack below for the anti-pattern)
2. Remove any hardcoded API keys

**Step 2: Use Environment Variables**
1. Add API keys to shell profile (`~/.zshrc` or `~/.bashrc`) as environment variables (see Code Pack below for examples)
2. Reload shell with `source ~/.zshrc`
3. Cursor will automatically use environment variables

**Step 3: Verify API Keys Not in Settings**
1. Search settings files for hardcoded keys (see Code Pack below for verification command)
2. Should return no hardcoded keys

**Time to Complete:** ~10 minutes

#### Validation & Testing
1. [ ] Search settings files for hardcoded keys - should find none
2. [ ] Verify Cursor can access API keys from environment
3. [ ] Check Git history for accidentally committed keys

**Expected result:** API keys only in environment variables or secure stores

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
1. Document all API keys in use:
   - OpenAI API keys
   - Anthropic API keys
   - Custom provider keys

2. Set rotation reminders (quarterly)

**Step 2: Rotate Keys**

For OpenAI:
1. Visit: https://platform.openai.com/api-keys
2. Click **Create new secret key**
3. Copy new key
4. Update environment variable with new key (see Code Pack below)
5. Restart Cursor
6. Verify new key works
7. **Revoke old key** on OpenAI platform

For Anthropic:
1. Visit: https://console.anthropic.com/settings/keys
2. Generate new key
3. Update environment
4. Revoke old key

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

## 4. Workspace Trust & Code Security

### 4.1 Enable Workspace Trust for All Repositories

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### Description
Use VSCode/Cursor Workspace Trust to prevent automatic execution of untrusted code when opening new repositories. This prevents malicious code in cloned repos from running automatically.

#### Rationale
**Why This Matters:**
- Cloning untrusted repos can execute malicious code via tasks, extensions, or scripts
- Workspace Trust restricts code execution until user explicitly trusts workspace
- Attackers can inject malicious `.vscode/tasks.json` or extension configs

**Attack Prevented:** Arbitrary code execution from malicious repositories

**Real-World Context:**
- VSCode introduced Workspace Trust after security research showed attack vectors

#### Prerequisites
- Understanding of which repositories are trusted (internal, verified sources)
- Communication to developers about trust prompts

#### ClickOps Implementation

**Step 1: Enable Workspace Trust**
1. Open Cursor → **Settings**
2. Search for: `security.workspace.trust`
3. Configure (see Code Pack below for full settings)

**Step 2: Configure Trusted Folders**
1. Add trusted parent directories:
   - Company code: `~/work/company-name/`
   - Personal projects: `~/projects/personal/`

**Step 3: Verify Trust Prompts**
1. Clone a new repository outside trusted folders
2. Open in Cursor
3. Should see: **"Do you trust the authors of the files in this folder?"**
4. Select **"No, I don't trust the authors"** for untrusted repos

**Time to Complete:** ~5 minutes

#### Validation & Testing
1. [ ] Clone untrusted repo - should trigger trust prompt
2. [ ] Verify restricted mode prevents task execution
3. [ ] Trust workspace and verify features enabled

**Expected result:** All untrusted workspaces open in restricted mode

#### What Gets Restricted in Untrusted Workspaces

| Feature | Trusted | Untrusted |
|---------|---------|-----------|
| **Tasks** | Run automatically | Blocked |
| **Debugging** | Enabled | Disabled |
| **Extensions** | Full functionality | Limited/disabled |
| **Settings (workspace)** | Applied | Ignored |

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **Developer Workflow** | Medium | Must trust repos to use full features |
| **Security Posture** | High Improvement | Prevents malicious code execution |
| **Maintenance Burden** | Low | One-time trust decision per workspace |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | CM-7 | Least functionality |
| **SOC 2** | CC6.6 | Logical access - malware protection |

---

### 4.2 Scan for Secrets in Code Before AI Processing

**Profile Level:** L2 (Hardened)
**NIST 800-53:** IA-5

#### Description
Use secret scanning tools to detect and remove secrets from code before allowing AI processing. Prevents accidental credential leakage to AI providers.

#### Rationale
**Why This Matters:**
- Cursor sends code snippets to AI providers (unless Privacy Mode enabled)
- Secrets in code sent to AI may be logged or retained by provider
- AI chat history may contain secrets if discussing code with credentials

**Attack Prevented:** Credential leakage via AI context

#### ClickOps Implementation

**Step 1: Install Secret Scanning Extension**
1. In Cursor, open Extensions (Cmd/Ctrl + Shift + X)
2. Install: **GitGuardian** or **TruffleHog** extension
3. Configure to scan on save

**Step 2: Enable Pre-Commit Hooks**
1. Install `pre-commit` framework
2. Add secret scanning hooks (e.g., `detect-secrets`, `trufflehog`)
3. Run `pre-commit install` in repository

**Step 3: Verify Secret Scanning**
1. Create test file with fake secret
2. Attempt commit - should be blocked
3. Remove secret and retry

---

## 5. Extension & Integration Security

### 5.1 Audit and Restrict VSCode Extensions

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### Description
Review all installed VSCode extensions and remove unnecessary or untrusted ones. Extensions have broad permissions and can access code, secrets, and network.

#### Rationale
**Why This Matters:**
- VSCode extensions can read all workspace files
- Malicious extensions can exfiltrate code or secrets
- Extensions may have vulnerabilities

**Attack Prevented:** Malicious extension data exfiltration

#### ClickOps Implementation

**Step 1: Audit Installed Extensions**
1. Open Cursor → **Extensions** (Cmd/Ctrl + Shift + X)
2. Review each installed extension:
   - When was it last updated?
   - How many installs/ratings?
   - What permissions does it request?
   - Is it still needed?

**Step 2: Remove Unnecessary Extensions**
1. Click extension → **Uninstall**
2. Focus on:
   - Extensions with <10K installs (less vetted)
   - Extensions not updated in >1 year
   - Extensions requesting network/filesystem permissions unnecessarily

**Step 3: Use Extension Allowlist (Cursor Business)**
1. In Cursor Business dashboard, configure extension allowlist
2. Only permit approved extensions for your organization

#### Recommended Extensions Security Posture

| Extension Category | Risk Level | Recommendation |
|-------------------|-----------|----------------|
| **Official Microsoft** | Low | Generally safe |
| **GitHub Official** | Low | Safe |
| **Popular (>1M installs)** | Low-Medium | Review permissions |
| **Niche (<10K installs)** | Medium-High | Audit code before use |
| **Deprecated/Unmaintained** | High | Remove immediately |

---

## 6. Network & Telemetry Controls

### 6.1 Disable Telemetry and Crash Reporting

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
3. Set `telemetry.telemetryLevel` to `off`
4. Disable `telemetry.enableCrashReporter`
5. Disable `telemetry.enableTelemetry`

**Step 2: Verify Telemetry Disabled**
1. Check network traffic - should not see telemetry endpoints
2. Use tools like Little Snitch (macOS) or Wireshark to monitor

---

### 6.2 Configure Network Allowlisting

**Profile Level:** L3 (Maximum Security)
**NIST 800-53:** SC-7

#### Description
Use enterprise firewall or endpoint security to allowlist only required Cursor network endpoints, blocking all other traffic.

#### Required Endpoints

| Endpoint | Purpose | Required For |
|----------|---------|-------------|
| `cursor.sh` | Authentication, licensing | All users |
| `api.openai.com` | OpenAI API (if used) | AI features |
| `api.anthropic.com` | Anthropic API (if used) | AI features |
| `marketplace.visualstudio.com` | Extension downloads | Extension management |

**Block all other network traffic from Cursor.**

---

## 7. Monitoring & Audit Logging

### 7.1 Enable Cursor Usage Logging

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AU-2

#### Description
Configure logging of Cursor AI usage for audit and compliance purposes.

#### Rationale
**Why This Matters:**
- Compliance frameworks require logging of AI usage
- Detect anomalous usage patterns (insider threats)
- Attribution of AI-generated code

#### ClickOps Implementation

**Step 1: Enable Built-in Logging**
1. Configure Cursor to log AI interactions in settings

**Step 2: Export Logs to SIEM**
1. Configure log forwarding to your SIEM platform
2. Set up alerts for anomalous AI usage patterns

---

## 8. Organization & Team Controls

### 8.1 Deploy Cursor Business for Centralized Management

**Profile Level:** L2 (Hardened)

#### Description
Use Cursor Business edition to enforce organizational policies, manage licenses, and control AI provider access centrally.

#### Rationale
**Why This Matters:**
- Centralized policy enforcement (Privacy Mode, allowed providers)
- License management and usage tracking
- Audit logging at organization level

#### ClickOps Implementation

**Step 1: Sign Up for Cursor Business**
1. Visit: https://cursor.sh/business
2. Create organization account
3. Invite team members

**Step 2: Configure Organization Policies**
1. In Cursor Business dashboard:
   - **Privacy Mode:** Enforce for all users
   - **Allowed AI Providers:** Restrict to approved vendors
   - **Extension Allowlist:** Limit to approved extensions
   - **Telemetry:** Disable for all users

**Step 3: Deploy Managed Settings**
1. Create organization-wide settings configuration
2. Deploy via MDM (Jamf, Intune, etc.) to all developer machines

---

## Appendix A: Edition Compatibility

| Control | Cursor Free | Cursor Pro | Cursor Business |
|---------|------------|-----------|-----------------|
| Account Authentication | ✅ | ✅ | ✅ |
| MFA | ✅ | ✅ | ✅ |
| Privacy Mode | ✅ | ✅ | ✅ (Enforced) |
| API Provider Restrictions | Manual | Manual | ✅ Centralized |
| Workspace Trust | ✅ | ✅ | ✅ |
| Telemetry Control | ✅ | ✅ | ✅ |
| Organization Policies | ❌ | ❌ | ✅ |
| Usage Audit Logs | ❌ | ❌ | ✅ |
| Centralized License Mgmt | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Cursor Documentation:**
- [Cursor Trust Center](https://trust.cursor.com/)
- [Cursor Security](https://cursor.com/security)
- [Cursor Documentation](https://cursor.com/docs)
- [Cursor Enterprise](https://cursor.com/enterprise)

**VSCode Security (Cursor inherits):**
- [Workspace Trust](https://code.visualstudio.com/docs/editor/workspace-trust)
- [Extension Security](https://code.visualstudio.com/api/references/extension-manifest)

**Compliance Frameworks:**
- SOC 2 Type II, GDPR, CCPA — via [Cursor Trust Center](https://trust.cursor.com/)
- Annual third-party penetration testing

**AI Code Security Research:**
- [OWASP LLM Top 10](https://owasp.org/www-project-top-10-for-large-language-model-applications/)
- [OWASP AI Security and Privacy Guide](https://github.com/OWASP/www-project-ai-security-and-privacy-guide)
- [NIST AI Risk Management Framework](https://www.nist.gov/itl/ai-risk-management-framework)

**Security Incidents:**
- **August 2025 — CurXecute (CVE-2025-54135) and MCPoison (CVE-2025-54136) vulnerabilities disclosed.** CurXecute allowed prompt injection via MCP-connected Slack to modify global MCP configuration and execute arbitrary commands. MCPoison enabled persistent code execution by silently swapping trusted MCP configuration files in shared GitHub repositories. Both vulnerabilities were patched. ([The Hacker News](https://thehackernews.com/2025/08/cursor-ai-code-editor-vulnerability.html))
- **September 2025 — Workspace Trust bypass via autorun.** Cursor shipped with Workspace Trust disabled by default, allowing hidden autorun instructions in projects to execute tasks without user consent when opening a folder. ([Help Net Security](https://www.helpnetsecurity.com/2025/09/11/cursor-ai-editor-vulnerability/))
- No confirmed data breaches affecting user data have been disclosed.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
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
