---
layout: guide
title: "GitHub Hardening Guide"
vendor: "GitHub"
slug: "github"
tier: "1"
category: "DevOps"
description: "Comprehensive source control and CI/CD security hardening for GitHub organizations, Actions, supply chain protection, and Enterprise Cloud/Server"
version: "0.3.0"
maturity: "draft"
last_updated: "2026-03-07"
---


**GitHub Editions Covered:** GitHub.com (Free, Team, Enterprise Cloud), GitHub Enterprise Server

---

## Overview

This guide provides comprehensive security hardening recommendations for GitHub, organized by control category. GitHub is a critical part of the software supply chain -- compromises can lead to malicious code injection, secret theft, and downstream customer breaches. GitHub Enterprise powers software development for **over 100 million developers** worldwide, with Enterprise deployments managing critical source code, CI/CD pipelines, and secrets for Fortune 500 companies.

### Intended Audience
- Security engineers managing GitHub organizations
- DevOps/Platform engineers configuring CI/CD pipelines
- Application security teams governing third-party Actions
- GRC professionals assessing code repository security
- Platform engineers implementing secure SDLC
- Open source maintainers protecting projects

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for organizations building customer-facing software or security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for highly regulated or high-risk targets

### Scope
This guide covers GitHub.com and GitHub Enterprise Cloud/Server security configurations including organization settings, repository security, Actions hardening, GitHub Advanced Security (GHAS), and supply chain protection. For self-hosted runner infrastructure hardening (Kubernetes, VMs), refer to CIS Benchmarks for those platforms.

### Why This Guide Exists

**No CIS Benchmark or DISA STIG currently exists for GitHub.** This guide fills that gap using:
- GitHub's official security hardening documentation
- SLSA (Supply-chain Levels for Software Artifacts) framework
- OpenSSF (Open Source Security Foundation) best practices
- Lessons from real-world supply chain attacks

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Repository Security](#2-repository-security)
3. [GitHub Actions & CI/CD Security](#3-github-actions--cicd-security)
4. [OAuth & Third-Party App Security](#4-oauth--third-party-app-security)
5. [Secret Management](#5-secret-management)
6. [Dependency & Supply Chain Security](#6-dependency--supply-chain-security)
7. [Modern Platform Features](#7-modern-platform-features)
8. [Monitoring & Audit Logging](#8-monitoring--audit-logging)
9. [Third-Party Integration Security](#9-third-party-integration-security)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Multi-Factor Authentication (MFA) for All Organization Members

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1), IA-2(2)
**CIS Controls:** 6.3, 6.5

#### Description
Require all organization members to enable MFA on their GitHub accounts. This prevents account takeover via password compromise.

#### Rationale
**Attack Prevented:** Credential stuffing, password spray, phished credentials

**Real-World Incidents:**
- **CircleCI Breach (January 2023):** Attackers compromised employee laptop, pivoted to GitHub, stole OAuth tokens from thousands of customers. MFA on GitHub would have limited lateral movement.
- **Heroku/Travis CI (April 2022):** GitHub OAuth tokens stolen, used to access customer repositories. MFA enforcement would have required additional authentication.

**Why This Matters:** GitHub accounts with write access can inject malicious code into your supply chain affecting all downstream users.

#### Prerequisites
- GitHub organization owner/admin access
- Member communication plan (give 30-day notice before enforcement)

#### ClickOps Implementation

**Step 1: Enable MFA Requirement**
1. Navigate to: **Organization Settings** -> **Authentication security**
2. Under "Two-factor authentication":
   - Select **"Require two-factor authentication for everyone in the [org-name] organization"**
3. Set grace period (recommended: 30 days)
4. Click **"Save"**

**Step 2: Monitor Compliance**
1. Go to: **Organization Settings** -> **People**
2. Filter by "2FA" status to see non-compliant members
3. Members without 2FA will be removed from org after grace period

**Time to Complete:** ~5 minutes + 30-day rollout

#### Code Implementation

{% include pack-code.html vendor="github" section="1.1" %}

#### Validation & Testing
1. [ ] Create test user account, add to organization
2. [ ] Verify test user is prompted to enable 2FA
3. [ ] Confirm user cannot access org resources without 2FA setup
4. [ ] After grace period, verify non-compliant users are removed

**Expected result:** All org members have 2FA enabled or are automatically removed.

#### Monitoring & Maintenance

**Alert Configuration:**

{% include pack-code.html vendor="github" section="1.9" %}

**Maintenance schedule:**
- **Weekly:** Review new member 2FA status
- **Monthly:** Audit removed users (were they removed due to 2FA non-compliance?)

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Medium | Users must set up 2FA app/hardware key |
| **Onboarding** | Low | New members guided through 2FA setup |
| **Maintenance** | Low | Automated enforcement, no ongoing admin work |
| **Rollback** | Easy | Disable requirement in org settings |

**Potential Issues:**
- **Issue 1: Users locked out if they lose 2FA device**
  - Mitigation: Provide recovery code guidance, admin can reset 2FA
  - Documentation: https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa/recovering-your-account-if-you-lose-your-2fa-credentials

**Rollback Procedure:**
1. Organization Settings -> Authentication security
2. Uncheck "Require two-factor authentication"
3. Save (not recommended - only for emergency access recovery)

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security - MFA |
| **NIST 800-53** | IA-2(1), IA-2(2) | Multi-factor authentication |
| **ISO 27001** | A.9.4.2 | Secure log-on procedures |
| **PCI DSS** | 8.3 | Multi-factor authentication for all access |

---

### 1.2 Restrict Base Permissions for Organization Members

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-6 (Least Privilege)

#### Description
Set default organization member permissions to minimal access. Members should only have write access to repositories they actively work on.

#### Rationale
**Attack Impact:** When CircleCI was breached, attackers gained access to GitHub OAuth tokens. If those tokens had overly broad permissions, attackers could modify any repository in affected organizations.

**Least Privilege Principle:** Default to no repository access; grant write access only as needed.

#### ClickOps Implementation

**Step 1: Set Base Permissions**
1. **Organization Settings** -> **Member privileges**
2. Under "Base permissions":
   - Set to **"No permission"** (recommended) or **"Read"**
   - NOT "Write" or "Admin"
3. Click **"Save"**

**Step 2: Use Teams for Access**
1. Create teams for projects/repos
2. Grant teams specific repository access
3. Add members to relevant teams only

**Step 3: Configure Additional Member Privileges**
1. Navigate to: **Organization Settings** -> **Member privileges**
2. Configure:
   - **Repository creation:** Restrict to specific roles
   - **Repository forking:** Disable for private repos
   - **Pages creation:** Restrict as needed

#### Code Implementation

{% include pack-code.html vendor="github" section="1.2" %}

#### Compliance Mappings
- **SOC 2:** CC6.2 (Least privilege)
- **NIST 800-53:** AC-6

---

### 1.3 Enable SAML Single Sign-On (SSO) and SCIM Provisioning

**Profile Level:** L2 (Hardened)
**Requires:** GitHub Enterprise Cloud
**NIST 800-53:** IA-2, IA-4, IA-8
**CIS Controls:** 6.3, 12.5

#### Description
Integrate GitHub with your corporate identity provider (Okta, Azure AD, Google Workspace) via SAML SSO and configure SCIM provisioning for automated user lifecycle management. This centralizes authentication and enables conditional access policies.

#### Rationale
**Centralized Control:** If employee leaves company, disable their IdP account and they immediately lose GitHub access. SCIM enables automatic deprovisioning when employees leave, closing the gap between termination and access revocation.

**Conditional Access:** Enforce device compliance, location-based access, session timeouts via IdP.

**SSO enables enforcement of corporate MFA policies** -- rather than relying on individual users to configure GitHub MFA, the organization's IdP enforces consistent authentication requirements.

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Enterprise Settings** -> **Authentication security**
2. Click **Enable SAML authentication**
3. Configure SAML settings:
   - Sign on URL
   - Issuer
   - Public certificate
4. Configure attribute mappings
5. Test authentication with pilot users before requiring

**Step 2: Require SAML SSO**
1. After testing, select **Require SAML authentication**
2. Configure recovery codes for break-glass access
3. Document emergency access procedures
4. Enable **"Require SAML SSO authentication for all members"**

**Step 3: Configure SCIM Provisioning**
1. Navigate to: **Enterprise Settings** -> **Authentication security** -> **SCIM configuration**
2. Generate SCIM token
3. Configure IdP SCIM provisioning:
   - User provisioning
   - Group synchronization
   - Deprovisioning
4. Test user lifecycle (create, update, deactivate)

**Time to Complete:** ~1 hour

#### Code Implementation

{% include pack-code.html vendor="github" section="1.10" %}

{% include pack-code.html vendor="github" section="1.3" %}

#### Additional Hardening

After SAML SSO is enabled:
- Configure **session timeout** in IdP (recommend: 8 hours max)
- Enable **device trust** if IdP supports (require managed devices)
- Verify SCIM deprovisioning works by testing with a non-production user

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Identity and access management |
| **NIST 800-53** | IA-2, IA-4, IA-8 | Identification and authentication |
| **ISO 27001** | A.9.2.1 | User registration and de-registration |
| **CIS Controls** | 6.3, 12.5 | Centralized authentication |

---

### 1.4 Configure Admin Access Controls

**Profile Level:** L1 (Baseline)
**Requires:** GitHub Enterprise Cloud/Server (for enterprise-level controls)
**NIST 800-53:** AC-6(1) (Least Privilege - Authorize Access to Security Functions)
**CIS Controls:** 5.4

#### Description
Implement least privilege for organization and enterprise administrators. Limit the number of enterprise owners, enforce MFA for all admins, and use separate admin accounts for privileged operations.

#### Rationale
**Why This Matters:**
- Site admins can promote themselves, create powerful tokens, and access any repository
- Each admin account represents a high-value target for attackers
- Limiting admin scope reduces blast radius of a compromised admin account
- Enterprise owners have unrestricted access to all organizations and settings

#### ClickOps Implementation

**Step 1: Review Enterprise Owners**
1. Navigate to: **Enterprise Settings** -> **People** -> **Enterprise owners**
2. Limit to 2-3 essential personnel
3. Ensure each owner has MFA enabled
4. Document owner responsibilities

**Step 2: Configure Organization Owner Policies**
1. Review organization owners across all orgs
2. Limit to essential personnel per org
3. Create separate admin accounts for privileged operations
4. Enforce MFA for all admin accounts

**Step 3: Audit Admin Activity**
1. Regular review of admin audit logs
2. Alert on privilege escalation events
3. Document admin changes and justifications

**For GitHub Enterprise Server:**
- Management Console admins have shell access
- Use passphrase-protected SSH keys per admin
- Restrict Management Console to bastion host access

#### Code Implementation

{% include pack-code.html vendor="github" section="1.8" %}
{% include pack-code.html vendor="github" section="1.4" %}
{% include pack-code.html vendor="github" section="1.5" %}
{% include pack-code.html vendor="github" section="1.6" %}

#### Validation & Testing
1. [ ] Verify enterprise owner count is 2-3 maximum
2. [ ] Confirm all admin accounts have MFA enabled
3. [ ] Test that non-admin members cannot access admin settings
4. [ ] Verify audit logging captures admin actions

#### Monitoring & Maintenance

**Alert Configuration:**

{% include pack-code.html vendor="github" section="1.11" %}

**Maintenance schedule:**
- **Monthly:** Review admin roster and remove unnecessary privileges
- **Quarterly:** Full admin access audit with documented justification

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.2 | Least privilege access controls |
| **NIST 800-53** | AC-6(1) | Authorize access to security functions |
| **ISO 27001** | A.9.2.3 | Management of privileged access rights |
| **CIS Controls** | 5.4 | Restrict administrator privileges |

---

### 1.5 Configure Enterprise IP Allow List

**Profile Level:** L2 (Hardened)
**Requires:** GitHub Enterprise Cloud
**NIST 800-53:** AC-17, SC-7
**CIS Controls:** 13.5

#### Description
Restrict enterprise access to approved IP addresses using IP allow lists. This limits the network locations from which users and services can access your GitHub Enterprise instance.

#### Rationale
**Attack Prevention:** Even with stolen credentials or tokens, attackers outside your corporate network cannot access GitHub resources. This is a defense-in-depth measure that complements MFA and SSO.

#### ClickOps Implementation

**Step 1: Enable IP Allow List**
1. Navigate to: **Enterprise Settings** -> **Authentication security** -> **IP allow list**
2. Click **Enable IP allow list**

**Step 2: Add Allowed IPs**
1. Click **Add IP address or range**
2. Add corporate network IPs/CIDR ranges
3. Add VPN egress IPs
4. Add CI/CD runner IPs (if applicable)
5. Enable for GitHub Apps: Optionally apply to installed GitHub Apps

**Step 3: Validate Access**
1. Test access from allowed IPs
2. Verify blocked access from other IPs
3. Document emergency procedures if blocked

#### Code Implementation

{% include pack-code.html vendor="github" section="1.7" %}

#### Validation & Testing
1. [ ] Access GitHub from an allowed IP (should succeed)
2. [ ] Access GitHub from a non-allowed IP (should fail)
3. [ ] Verify CI/CD pipelines still function with runner IPs allowed
4. [ ] Test emergency access procedures

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | Network access restrictions |
| **NIST 800-53** | AC-17, SC-7 | Remote access, boundary protection |
| **ISO 27001** | A.13.1.1 | Network controls |
| **CIS Controls** | 13.5 | Manage access control to remote assets |

---

## 2. Repository Security

### 2.1 Enable Branch Protection for All Critical Branches

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-3 (Configuration Change Control)

#### Description
Protect `main`, `master`, `production`, and release branches from direct pushes. Require pull requests, reviews, and status checks before merging.

#### Rationale
**Attack Prevented:** Direct malicious code injection into production

**Real-World Incident:**
- **CodeCov Bash Uploader Compromise (April 2021):** Attacker modified Codecov's bash uploader script to exfiltrate environment variables (secrets) from thousands of CI/CD pipelines. Branch protection requiring PR reviews would have caught this modification.

#### ClickOps Implementation

**Step 1: Enable Branch Protection**
1. Navigate to: **Repository** -> **Settings** -> **Branches**
2. Under "Branch protection rules", click **"Add rule"**
3. Branch name pattern: `main` (or `master`, `production`)
4. Enable these protections:
   - **Require a pull request before merging**
     - Require approvals (minimum: 1 for L1, 2 for L2)
     - Dismiss stale pull request approvals when new commits are pushed
   - **Require status checks to pass before merging**
     - Select required checks (tests, security scans)
     - Require branches to be up to date before merging
   - **Require conversation resolution before merging**
   - **Do not allow bypassing the above settings** (critical!)
   - **Restrict who can push to matching branches** (optional: restrict to CI bot only)
5. Click **"Create"**

**Repeat for all critical branches.**

**Time to Complete:** ~10 minutes per repository

#### Code Implementation

{% include pack-code.html vendor="github" section="3.10" %}
{% include pack-code.html vendor="github" section="3.1" %}
{% include pack-code.html vendor="github" section="3.6" %}
{% include pack-code.html vendor="github" section="3.7" %}

#### Validation & Testing
1. [ ] Attempt to push directly to protected branch (should fail)
2. [ ] Create PR without required status checks (should block merge)
3. [ ] Create PR without required approvals (should block merge)
4. [ ] Verify admin cannot bypass (if enforce_admins enabled)

#### Monitoring & Maintenance

**Alert on protection changes:**

{% include pack-code.html vendor="github" section="2.6" %}

**Maintenance:**
- **Monthly:** Audit repositories missing branch protection
- **Quarterly:** Review and update required status checks

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **Developer Workflow** | Medium | Must create PRs instead of direct push |
| **Merge Speed** | Low | Adds review time (offset by quality improvement) |
| **Emergency Hotfixes** | Medium | Still possible via PR with expedited review |
| **Rollback** | Easy | Delete branch protection rule |

#### Compliance Mappings
- **SOC 2:** CC8.1 (Change management)
- **NIST 800-53:** CM-3 (Configuration Change Control)
- **ISO 27001:** A.12.1.2 (Change management)

---

### 2.2 Enable Security Features: Dependabot, Code Scanning, Secret Scanning

**Profile Level:** L1 (Baseline)

#### Description
Enable GitHub's native security features to detect vulnerabilities, secrets, and code quality issues automatically.

#### Rationale
**Attack Prevention:**
- **Secret Scanning:** Detects accidentally committed API keys, passwords, tokens
- **Dependabot:** Automatically identifies vulnerable dependencies
- **Code Scanning (CodeQL):** Finds security vulnerabilities in code

**Real-World Incident:**
- **Travis CI Secret Exposure (September 2021):** Secrets in logs exposed for years. GitHub Secret Scanning would have detected these tokens.

#### ClickOps Implementation

**Step 1: Enable at Organization Level**
1. **Organization Settings** -> **Code security and analysis**
2. Enable for all repositories:
   - **Dependency graph** (free)
   - **Dependabot alerts** (free)
   - **Dependabot security updates** (free)
   - **Secret scanning** (free for public repos, requires Advanced Security for private)
   - **Code scanning** (requires Actions, free for public repos)
3. Enable **Automatically enable for new repositories** for each feature

**Step 2: Configure Per-Repository (if needed)**
1. Navigate to: **Repository** -> **Settings** -> **Code security and analysis**
2. Enable same features
3. For **Code scanning**, click "Set up" -> Choose "CodeQL Analysis" workflow

**Step 3: Configure Custom Secret Scanning Patterns (Enterprise)**
1. Navigate to: **Organization Settings** -> **Code security** -> **Secret scanning**
2. Add custom patterns for:
   - Internal API keys
   - Database connection strings
   - Custom tokens

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="github" section="2.1" %}
{% include pack-code.html vendor="github" section="2.2" %}
{% include pack-code.html vendor="github" section="2.3" %}
{% include pack-code.html vendor="github" section="2.4" %}
{% include pack-code.html vendor="github" section="3.5" %}

#### Secret Scanning Push Protection

**L2 Enhancement:** Enable push protection to **block commits** containing secrets. This prevents secrets from ever entering Git history (better than post-commit detection). See the Code Pack above for API implementation.

#### L2 Enhancement: CodeQL Advanced Configuration

For organizations requiring deeper code analysis, configure CodeQL with custom query suites and scheduled scanning. See the advanced CodeQL workflow in the Code Pack above.

**CodeQL Configuration Options:**
- `security-extended` -- Includes additional security queries beyond default
- `security-and-quality` -- Full security plus code quality queries
- Custom query packs for organization-specific patterns

#### Monitoring Alerts

{% include pack-code.html vendor="github" section="2.7" %}

#### Compliance Mappings
- **SOC 2:** CC7.2 (System monitoring)
- **NIST 800-53:** RA-5 (Vulnerability scanning), SA-11 (Security testing)
- **ISO 27001:** A.12.6.1 (Technical vulnerability management)

---

### 2.3 Configure Repository Rulesets

**Profile Level:** L2 (Hardened)
**Requires:** GitHub Enterprise Cloud/Server
**NIST 800-53:** CM-3 (Configuration Change Control)
**CIS Controls:** 16.9

#### Description
Configure organization-wide repository rulesets to enforce consistent branch protection across all repositories. Rulesets provide centralized governance that cannot be overridden at the repository level, unlike individual branch protection rules.

#### Rationale
**Why This Matters:**
- Branch protection rules are configured per-repository and can be modified by repository admins
- Rulesets are managed at the organization level and enforce consistent policies across all repositories
- Reduces configuration drift and ensures no repository is accidentally unprotected

#### ClickOps Implementation

**Step 1: Create Organization Ruleset**
1. Navigate to: **Organization Settings** -> **Repository** -> **Rulesets**
2. Click **New ruleset** -> **New branch ruleset**

**Step 2: Configure Ruleset**
1. Name: `Production Branch Protection`
2. Enforcement status: **Active**
3. Target repositories: All or selected repositories
4. Branch targeting: Include `main`, `master`, `release/*`

**Step 3: Configure Rules**
1. Enable:
   - Restrict deletions
   - Require pull request
   - Require signed commits
   - Require status checks
   - Block force pushes
2. Configure bypass list (limit to emergency access only)

#### Code Implementation

{% include pack-code.html vendor="github" section="2.5" %}

#### Validation & Testing
1. [ ] Verify ruleset is active and applies to target branches
2. [ ] Attempt direct push to protected branch (should fail)
3. [ ] Verify bypass list is limited to emergency accounts only
4. [ ] Test that new repositories automatically inherit rulesets

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC8.1 | Change management |
| **NIST 800-53** | CM-3 | Configuration change control |
| **ISO 27001** | A.12.1.2 | Change management |
| **CIS Controls** | 16.9 | Secure application development |

---

### 2.4 Enforce Commit Signing

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SI-7 (Software, Firmware, and Information Integrity)
**CIS Controls:** 16.9

#### Description
Require cryptographically signed commits to verify commit authenticity and prevent tampering. Commit signing provides non-repudiation and ensures commits are genuinely from the claimed author.

#### Rationale
**Attack Prevented:** Commit spoofing -- Git allows anyone to set any name/email in commit metadata. Without signing, an attacker with push access can create commits that appear to be from trusted developers.

**Real-World Risk:** The Fake Dependabot Commits attack (July 2023) used stolen PATs to inject malicious commits disguised as Dependabot contributions. Signed commit requirements would have flagged these as unverified.

#### ClickOps Implementation

**Step 1: Configure Vigilant Mode**
1. Navigate to: **User Settings** -> **SSH and GPG keys**
2. Enable **Flag unsigned commits as unverified**

**Step 2: Require Signed Commits in Branch Protection**
1. Navigate to: **Repository Settings** -> **Branches** -> Edit rule
2. Enable **Require signed commits**

**Step 3: Enforce via Organization Ruleset** (recommended)
1. Navigate to: **Organization Settings** -> **Repository** -> **Rulesets**
2. Edit production ruleset
3. Enable **Require signed commits** rule

**Supported Signing Methods:**
- GPG keys
- SSH keys (recommended for ease of use)
- S/MIME certificates

#### Code Implementation

**Developer Setup (local git config):**

{% include pack-code.html vendor="github" section="2.8" %}

{% include pack-code.html vendor="github" section="3.7" %}

#### Validation & Testing
1. [ ] Create an unsigned commit and attempt to push (should fail if required)
2. [ ] Create a signed commit and verify it shows as "Verified" in GitHub UI
3. [ ] Verify vigilant mode flags unsigned commits from other contributors

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **Developer Setup** | Medium | Developers must configure GPG or SSH signing |
| **CI/CD Commits** | Medium | Bot accounts need signing keys configured |
| **Onboarding** | Medium | New developers must set up commit signing |
| **Rollback** | Easy | Disable in branch protection or ruleset |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC8.1 | Change management - code integrity |
| **NIST 800-53** | SI-7 | Software and information integrity |
| **ISO 27001** | A.14.2.7 | Outsourced development integrity |
| **CIS Controls** | 16.9 | Secure application development |

---

## 3. GitHub Actions & CI/CD Security

### 3.1 Restrict Third-Party GitHub Actions to Verified Creators Only

**Profile Level:** L1 (Baseline)
**SLSA:** Build L2+ requirement

#### Description
Prevent use of arbitrary third-party Actions by restricting to GitHub-verified creators and specific allow-listed actions. This limits supply chain risk from compromised or malicious Actions.

#### Rationale
**Attack Vector:** Malicious GitHub Actions can:
- Exfiltrate secrets from workflow environment
- Modify build artifacts to inject backdoors
- Steal source code

**Real-World Risk:**
- **Dependency Confusion:** Attackers create Actions with similar names to popular ones
- **Typosquatting:** `actions/checkout` vs `actions/check-out` (malicious)
- **Compromised Maintainer:** Legitimate Action author's account taken over

#### ClickOps Implementation

**Step 1: Set Enterprise Actions Policy** (Enterprise Cloud/Server)
1. Navigate to: **Enterprise Settings** -> **Policies** -> **Actions**
2. Configure allowed actions:
   - **Allow enterprise and select non-enterprise actions** (recommended)
   - Specify allowed patterns: `github/*`, `actions/*`
3. Restrict to verified creators if possible

**Step 2: Set Organization Action Policy**
1. **Organization Settings** -> **Actions** -> **General**
2. Under "Actions permissions":
   - Select **"Allow [org-name], and select non-[org-name], actions and reusable workflows"**
3. Under "Allow specified actions and reusable workflows":
   - **Allow actions created by GitHub** (GitHub-verified)
   - **Allow actions by Marketplace verified creators**
   - Add specific allow-listed actions (see allowed list in Code Pack below)
4. Click **"Save"**

{% include pack-code.html vendor="github" section="3.12" %}

**Time to Complete:** ~5 minutes

#### Code Implementation

{% include pack-code.html vendor="github" section="3.2" %}
{% include pack-code.html vendor="github" section="3.3" %}

#### Best Practices for Action Selection

**Tier 1 - Safest (Always Allow):**
- `actions/*` - GitHub official actions
- `github/*` - GitHub-maintained

**Tier 2 - Verified Vendors:**
- `aws-actions/*` - AWS official
- `azure/*` - Microsoft Azure
- `google-github-actions/*` - Google Cloud
- `hashicorp/*` - HashiCorp (Terraform)
- `docker/*` - Docker official

**Tier 3 - Vet Before Allowing:**
- Popular community actions with >10K stars
- Actions you've reviewed source code for
- Pin to specific commit SHA (not tag/branch)

#### Pin Actions to Commit SHA (L2 Enhancement)

**Why:** Tags and branches can be moved to point to malicious code. Commit SHAs are immutable.

{% include pack-code.html vendor="github" section="3.13" %}

**Automation to pin SHAs:**

{% include pack-code.html vendor="github" section="3.18" %}

**Automated SHA updates with Dependabot:**

{% include pack-code.html vendor="github" section="3.11" %}

#### Monitoring & Maintenance

**Alert on unapproved Action usage:**

{% include pack-code.html vendor="github" section="3.8" %}

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **Developer Workflow** | Medium | Must request approval for new Actions |
| **Build Speed** | None | No performance impact |
| **Maintenance** | Medium | Must review/approve new Action requests |
| **Rollback** | Easy | Change policy to allow all actions |

#### Compliance Mappings
- **SLSA:** Build L2 (Build as Code)
- **NIST 800-53:** SA-12 (Supply Chain Protection)
- **SOC 2:** CC9.2 (Third-party management)

---

### 3.2 Use Least-Privilege Workflow Permissions

**Profile Level:** L1 (Baseline)
**SLSA:** Build L2 requirement

#### Description
Set GitHub Actions `GITHUB_TOKEN` permissions to read-only by default. Grant write permissions only when explicitly needed per workflow.

#### Rationale
**Default Risk:** By default, `GITHUB_TOKEN` has write access to repository contents, packages, pull requests, etc. Compromised workflow can modify code.

**Least Privilege:** Start with no permissions, add only what's needed.

#### ClickOps Implementation

**Step 1: Set Organization Default**
1. **Organization Settings** -> **Actions** -> **General**
2. Under "Workflow permissions":
   - Select **"Read repository contents and packages permissions"** (read-only)
   - Do NOT check "Allow GitHub Actions to create and approve pull requests"
3. Click **"Save"**

**Step 2: Configure at Repository Level**
1. Navigate to: **Repository Settings** -> **Actions** -> **General**
2. Set **Workflow permissions** to **Read repository contents**
3. Disable **Allow GitHub Actions to create and approve pull requests**

**Step 3: Per-Workflow Explicit Permissions**

In each workflow file, explicitly declare required permissions. See the workflow template in the Code Pack below.

**Time to Complete:** ~5 minutes org-wide + per-workflow updates

#### Code Implementation

{% include pack-code.html vendor="github" section="3.4" %}

#### Common Permission Combinations

{% include pack-code.html vendor="github" section="3.14" %}

#### Monitoring

**Audit workflows with excessive permissions:**

{% include pack-code.html vendor="github" section="3.15" %}

#### Compliance Mappings
- **SLSA:** Build L2 (Least privilege)
- **NIST 800-53:** AC-6 (Least Privilege)
- **SOC 2:** CC6.2

---

### 3.3 Require Workflow Approval for First-Time Contributors

**Profile Level:** L2 (Hardened)

#### Description
Require manual approval before running workflows triggered by first-time contributors. Prevents malicious PR attacks that exfiltrate secrets.

#### Rationale
**Attack:** Attacker forks your public repo, modifies workflow to exfiltrate secrets, opens PR. Workflow runs automatically and steals `{% raw %}${{ secrets }}{% endraw %}`.

**Prevention:** Require maintainer to review and approve workflow runs from new contributors.

#### ClickOps Implementation

1. **Repository Settings** -> **Actions** -> **General**
2. Under "Fork pull request workflows from outside collaborators":
   - Select **"Require approval for first-time contributors"** (L2)
   - Or **"Require approval for all outside collaborators"** (L3)
3. Save

#### Code Implementation

{% include pack-code.html vendor="github" section="3.16" %}

#### Compliance Mappings
- **SLSA:** Build L2 (Source code integrity)
- **SOC 2:** CC6.1 (Logical access)

---

### 3.4 Configure Self-Hosted Runner Security

**Profile Level:** L2 (Hardened)
**Requires:** GitHub Enterprise Cloud/Server (for runner groups)
**NIST 800-53:** CM-6 (Configuration Settings)
**CIS Controls:** 4.1

#### Description
Secure self-hosted runners to prevent compromise of build environment. Self-hosted runners execute untrusted workflow code and have access to secrets, network resources, and potentially other systems on the host.

#### Rationale
**Why This Matters:**
- Self-hosted runners persist between jobs (unlike GitHub-hosted runners)
- A compromised runner can steal secrets from subsequent jobs
- Runners on the corporate network can pivot to internal systems
- Public repositories should NEVER use self-hosted runners (anyone can trigger workflow runs)

#### ClickOps Implementation

**Step 1: Isolate Runners**
1. Use ephemeral runners (new VM per job) -- this is the single most impactful security measure
2. Never run on controller/sensitive systems
3. Use dedicated runner network segment with firewall rules

**Step 2: Configure Runner Groups**
1. Navigate to: **Organization Settings** -> **Actions** -> **Runner groups**
2. Create runner groups for different trust levels:
   - `production-runners` -- only for deployment workflows from trusted repos
   - `general-runners` -- for CI/CD from internal repositories
   - `public-runners` -- isolated runners with no secrets for public fork builds
3. Restrict which repositories can use each group

**Step 3: Configure Runner Labels**
1. Use labels to route jobs to appropriate runners
2. Production deployments: dedicated secure runners
3. Public fork builds: isolated runners with no secrets access

#### Code Implementation

{% include pack-code.html vendor="github" section="3.9" %}

**Example ephemeral runner configuration:**

{% include pack-code.html vendor="github" section="3.17" %}

#### Validation & Testing
1. [ ] Verify ephemeral runners are destroyed after each job
2. [ ] Test that public repos cannot access production runner groups
3. [ ] Verify network segmentation between runner groups
4. [ ] Confirm secrets are not accessible from public runner groups

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access to compute resources |
| **NIST 800-53** | CM-6 | Configuration settings |
| **ISO 27001** | A.12.1.4 | Separation of development, testing, and operational environments |
| **CIS Controls** | 4.1 | Secure configuration of enterprise assets |

---

## 4. OAuth & Third-Party App Security

### 4.1 Audit and Restrict OAuth App Access

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-6, AC-17
**CIS Controls:** 6.8

#### Description
Review all OAuth apps and GitHub Apps with access to your organization. Revoke unnecessary apps, restrict scopes for remaining apps, and enable OAuth app access restrictions to require admin approval for new installations.

#### Rationale
**Attack Vector:** OAuth tokens remain valid until manually revoked. Most organizations have no visibility into which apps retain access or what scopes they hold.

**Real-World Incidents:**
- **CircleCI Breach (January 2023):** Tokens for GitHub, AWS, and other services stolen. GitHub OAuth tokens allowed repository access across customer organizations.
- **Heroku/Travis CI (April 2022):** GitHub OAuth tokens leaked, used for unauthorized repository access affecting npm packages.
- **GitHub SSO Bypass (CVE-2024-6337, July 2024):** GitHub App installation tokens could read private repository contents even when SAML SSO hadn't authorized the app, allowing unauthorized data access.

#### ClickOps Implementation

**Step 1: Enable OAuth App Access Restrictions**
1. **Organization Settings** -> **Third-party access** -> **OAuth application policy**
2. Click **"Setup application access restrictions"**
3. Review pending requests and approve only necessary apps
4. This ensures unapproved OAuth apps cannot access organization data

**Step 2: Audit Installed Apps**
1. **Organization Settings** -> **GitHub Apps** (for GitHub Apps)
2. **Organization Settings** -> **OAuth Apps** (for OAuth apps)
3. For each app, review:
   - Last used date
   - Granted permissions and scopes
   - Repository access (all repos vs. selected)
4. Click app -> **"Configure"** -> Review repository access and permissions

**Step 3: Revoke Unnecessary Apps**
- Click **"Revoke"** for unused OAuth apps
- For GitHub Apps, click **"Suspend"** or **"Uninstall"**
- For remaining apps, restrict repository access to minimum necessary

**Step 4: Limit Access Requests**
1. **Organization Settings** -> **Third-party access** -> **Access requests**
2. Configure whether outside collaborators can request app access
3. Set notification preferences for pending requests

**Time to Complete:** ~30 minutes for initial audit

#### Code Implementation

{% include pack-code.html vendor="github" section="4.4" %}

{% include pack-code.html vendor="github" section="4.6" %}

{% include pack-code.html vendor="github" section="4.3" %}

#### Recommended Scope Restrictions

| App Type | Recommended Scopes | Avoid |
|----------|-------------------|-------|
| **CI/CD (CircleCI, Jenkins)** | `repo` (read), `status` (write), `write:packages` (if needed) | `admin:org`, `delete_repo` |
| **Code Analysis (SonarQube)** | `repo:read`, `statuses:write` | `repo:write` |
| **Project Management (Jira)** | `repo:status`, `read:org` | `repo` (full) |
| **Dependency Tools (Snyk)** | `repo:read`, `security_events:write` | `repo:write` |

#### Compliance Mappings
- **CIS Controls:** 6.8 (Define and maintain role-based access control)
- **NIST 800-53:** AC-6 (Least Privilege), AC-17 (Remote Access)
- **SOC 2:** CC6.2 (Least privilege), CC9.2 (Third-party access)
- **ISO 27001:** A.9.2.1

---

### 4.2 Audit GitHub App Installation Permissions

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-6, CM-8
**CIS Controls:** 2.1

#### Description
Audit all installed GitHub Apps in the organization, review their granted permissions, and flag apps with excessive access. GitHub Apps have replaced OAuth apps as the preferred integration method due to finer-grained permission controls.

#### Rationale
**Why GitHub Apps Over OAuth Apps:**
- GitHub Apps request only specific permissions (not broad scopes)
- Can be installed on specific repositories (not all-or-nothing)
- Use short-lived installation tokens (expire after 1 hour)
- Each permission can be set to read-only, read-write, or no access

**Risk:** Apps with `administration: write` or `organization_administration: write` permissions can modify org settings, manage teams, and change repository visibility.

#### ClickOps Implementation

**Step 1: Review Installed GitHub Apps**
1. Navigate to: **Organization Settings** -> **GitHub Apps**
2. For each installed app, click **"Configure"**
3. Review:
   - **Repository access:** All repositories vs. specific repositories
   - **Permissions:** Which permissions were granted at install time
   - **Events:** What webhook events the app receives

**Step 2: Restrict Repository Access**
1. For each app, change from "All repositories" to "Only select repositories"
2. Select only the repositories the app actually needs
3. Click **"Save"**

**Step 3: Flag Excessive Permissions**
- Apps should not have `administration: write` unless they manage repo settings
- Apps should not have `organization_administration: write` unless they manage org-level config
- Review `members: write` -- apps generally should not manage team membership

**Time to Complete:** ~20 minutes

#### Code Implementation

{% include pack-code.html vendor="github" section="4.7" %}

#### Compliance Mappings
- **CIS Controls:** 2.1 (Establish and maintain a software inventory)
- **NIST 800-53:** AC-6 (Least Privilege), CM-8 (Information system component inventory)
- **SOC 2:** CC6.2

---

### 4.3 Enforce Fine-Grained Personal Access Tokens

**Profile Level:** L2 (Hardened)
**Requires:** GitHub Enterprise Cloud
**NIST 800-53:** IA-4, IA-5
**CIS Controls:** 6.3

#### Description
Require fine-grained personal access tokens (PATs) instead of classic PATs. Fine-grained PATs have mandatory expiration dates, scoped repository access, and specific permissions -- eliminating the risks of overly permissive classic tokens.

#### Rationale
**Classic PAT Risks:**
- No mandatory expiration -- tokens can live forever
- Broad scope -- `repo` grants full access to ALL repositories
- No granular permissions -- cannot restrict to specific API operations
- No approval workflow -- any user can create tokens with any scope

**Fine-Grained PAT Benefits:**
- Mandatory expiration (max 1 year)
- Repository-specific access (select individual repos)
- Granular permissions per API category
- Organization can require admin approval before tokens take effect

**Real-World Incident:**
- **Code Signing Certificate Theft (January 2023):** Attacker used a compromised PAT to access GitHub repositories and steal encrypted code-signing certificates for GitHub Desktop and Atom.
- **Fake Dependabot Commits (July 2023):** Stolen GitHub PATs used to inject malicious commits disguised as Dependabot contributions across hundreds of repositories.

#### ClickOps Implementation

**Step 1: Set PAT Policy**
1. Navigate to: **Organization Settings** -> **Personal access tokens**
2. Under **"Fine-grained personal access tokens"**:
   - Set to **"Allow access via fine-grained personal access tokens"**
   - Enable **"Require approval of fine-grained personal access tokens"**
3. Under **"Personal access tokens (classic)"**:
   - Set to **"Restrict access via personal access tokens (classic)"**

**Step 2: Review Pending Requests**
1. **Organization Settings** -> **Personal access tokens** -> **Pending requests**
2. Review each request: owner, repositories, permissions, expiration
3. Approve or deny based on least-privilege principle

**Step 3: Audit Active Tokens**
1. **Organization Settings** -> **Personal access tokens** -> **Active tokens**
2. Review all active fine-grained PATs
3. Revoke tokens that are no longer needed or have excessive permissions

**Time to Complete:** ~10 minutes for policy, ongoing for reviews

#### Code Implementation

{% include pack-code.html vendor="github" section="4.8" %}

**Note:** No Terraform provider support exists for fine-grained PAT policies at this time.

#### Compliance Mappings
- **CIS Controls:** 6.3 (Require MFA for externally-exposed applications)
- **NIST 800-53:** IA-4 (Identifier management), IA-5 (Authenticator management)
- **SOC 2:** CC6.1 (Logical access security)
- **ISO 27001:** A.9.4.2

---

## 5. Secret Management

### 5.1 Use GitHub Actions Secrets with Environment Protection

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-12, SC-28
**CIS Controls:** 3.11

#### Description
Store sensitive credentials in GitHub Actions secrets (not hardcoded in code). Use environment protection rules to require approval for production secret access. Structure secrets at organization, repository, and environment levels for proper access control.

#### Rationale
**Attack Prevention:**
- Secrets in code -> exposed in Git history forever
- Secrets in logs -> leaked via CI/CD output
- Secrets in unprotected workflows -> stolen via malicious PR

**Real-World Incident:**
- **tj-actions/changed-files Compromise (March 2025):** Supply chain attack on popular GitHub Action (23,000+ repositories). The malicious Action extracted secrets from Runner Worker process memory and dumped them to workflow logs, which were then exfiltrated.

**Environment Protection:** Require manual approval before workflows can access production secrets.

#### ClickOps Implementation

**Step 1: Configure Organization Secrets**
1. Navigate to: **Organization Settings** -> **Secrets and variables** -> **Actions**
2. Create secrets at organization level for shared credentials
3. Restrict repository access to minimum necessary

**Step 2: Store Repository Secrets**
1. **Repository Settings** -> **Secrets and variables** -> **Actions**
2. Click "New repository secret"
3. Name: `PROD_API_KEY` (use descriptive names)
4. Value: [paste secret]
5. Click "Add secret"

**Step 3: Create Environment with Protection**
1. **Repository Settings** -> **Environments**
2. Click "New environment", name it `production`
3. Configure protection rules:
   - **Required reviewers** (add team/users who must approve)
   - **Wait timer** (optional: delay before deployment)
   - **Deployment branches** (only `main` can deploy to production)
4. Add environment-specific secrets to this environment (most secure)

**Step 4: Create Staging Environment**
1. Create `staging` environment with lighter restrictions
2. Add staging-specific secrets
3. Allow deployment from `main` and `develop` branches

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="github" section="5.5" %}

#### Best Practices

**Secret Hierarchy (most to least restrictive):**
1. **Environment secrets** -- Only accessible during deployment to that environment
2. **Repository secrets** -- Accessible to all workflows in the repository
3. **Organization secrets** -- Shared across selected repositories

**Secret Rotation:**
- Rotate secrets quarterly (minimum)
- Use short-lived credentials where possible (OIDC tokens -- see 5.2)
- Track secret age using the Code Pack below

**Never Do:**
- Echo secrets in workflow logs: `echo {% raw %}${{ secrets.API_KEY }}{% endraw %}`
- Write secrets to files that get uploaded as artifacts
- Pass secrets in URLs: `curl https://api.example.com?key={% raw %}${{ secrets.API_KEY }}{% endraw %}`

#### Monitoring

{% include pack-code.html vendor="github" section="5.9" %}

#### Compliance Mappings
- **CIS Controls:** 3.11 (Encrypt sensitive data at rest)
- **NIST 800-53:** SC-12 (Cryptographic key management), SC-28 (Protection of information at rest)
- **SOC 2:** CC6.1 (Secret management)
- **PCI DSS:** 8.2.1

---

### 5.2 Use OpenID Connect (OIDC) Instead of Long-Lived Credentials

**Profile Level:** L2 (Hardened)
**NIST 800-53:** IA-5(1)
**SLSA:** Build L3

#### Description
Use GitHub Actions OIDC provider to get short-lived cloud credentials instead of storing long-lived access keys as secrets.

#### Rationale
**Problem with Long-Lived Secrets:**
- Stored in GitHub, accessible to anyone with repo admin access
- If leaked, valid until manually rotated
- Difficult to audit usage

**OIDC Advantage:**
- No secrets stored in GitHub
- Credentials auto-expire (15 minutes)
- Cloud provider controls access via trust policy
- Can't be exfiltrated and used elsewhere

**Supported Providers:**
- AWS (AssumeRoleWithWebIdentity)
- Google Cloud (Workload Identity Federation)
- Azure (Federated Credentials)
- HashiCorp Vault

#### ClickOps Implementation (AWS Example)

**Step 1: Configure AWS IAM OIDC Provider**
1. In AWS IAM Console, create OIDC provider:
   - Provider URL: `https://token.actions.githubusercontent.com`
   - Audience: `sts.amazonaws.com`

**Step 2: Create IAM Role and Deploy Workflow**

{% include pack-code.html vendor="github" section="5.6" %}

**Time to Complete:** ~30 minutes

#### Compliance Mappings
- **SLSA:** Build L3 (Short-lived credentials)
- **NIST 800-53:** IA-5(1) (Authenticator management)
- **SOC 2:** CC6.1

---

### 5.3 Configure Push Protection with Delegated Bypass

**Profile Level:** L2 (Hardened)
**Requires:** GitHub Advanced Security (Secret Protection, $19/month per committer as of April 2025)
**NIST 800-53:** IA-5, CM-3

#### Description
Enable push protection to block commits containing secrets before they reach the repository. Configure delegated bypass so that only designated security reviewers can approve exceptions, rather than allowing any developer to bypass push protection.

#### Rationale
**Why Delegated Bypass:**
- Default push protection allows any developer to bypass the block with a reason
- Delegated bypass routes bypass requests to designated reviewers (security team)
- Creates an audit trail of all bypass decisions
- Prevents developers from routinely bypassing push protection without oversight

**GHAS Unbundling (April 2025):** Secret scanning and push protection are now available as "Secret Protection" ($19/month per committer) separately from Code Security ($30/month). This makes push protection accessible to GitHub Team plan organizations.

#### ClickOps Implementation

**Step 1: Enable Push Protection**
1. **Organization Settings** -> **Code security** -> **Configurations**
2. Edit your security configuration (or create a new one)
3. Under **Secret scanning**, enable **Push protection**
4. Apply to all repositories

**Step 2: Configure Delegated Bypass**
1. **Organization Settings** -> **Code security** -> **Configurations**
2. Under push protection settings, set bypass mode to **"Require bypass request"**
3. Designate bypass reviewers (security team or specific users)
4. Set notification preferences for bypass requests

**Step 3: Monitor Bypass Requests**
1. **Organization Settings** -> **Code security** -> **Secret scanning**
2. Review pending bypass requests
3. Approve or deny based on the secret type and context

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="github" section="5.10" %}

**Note:** No Terraform provider support exists for delegated bypass configuration at this time.

#### Compliance Mappings
- **CIS Controls:** 16.12 (Implement code-level security checks)
- **NIST 800-53:** IA-5 (Authenticator management), CM-3 (Configuration change control)
- **SOC 2:** CC6.1

---

### 5.4 Define Custom Secret Scanning Patterns

**Profile Level:** L2 (Hardened)
**Requires:** GitHub Advanced Security
**NIST 800-53:** IA-5, SI-4

#### Description
Define organization-level custom secret scanning patterns to detect internal API keys, proprietary tokens, and other secrets specific to your organization that GitHub's built-in patterns don't cover. Custom patterns can also be configured for push protection (GA August 2025).

#### Rationale
**Why Custom Patterns:**
- GitHub's built-in secret scanning covers 200+ provider patterns
- Internal API keys, service tokens, and custom credentials are not detected by default
- Custom patterns extend coverage to organization-specific secret formats
- Patterns can be enforced in push protection to block commits containing internal secrets

#### ClickOps Implementation

**Step 1: Create Custom Pattern**
1. **Organization Settings** -> **Code security** -> **Secret scanning**
2. Click **"New pattern"**
3. Configure:
   - **Pattern name:** e.g., "Internal API Key"
   - **Secret format:** Regex pattern (e.g., `internal_api_key_[a-zA-Z0-9]{32}`)
   - **Before secret:** Optional context regex
   - **After secret:** Optional context regex
   - **Test string:** Provide sample matches for validation
4. Click **"Save and dry run"** to test against existing repositories

**Step 2: Enable in Push Protection**
1. After validating the pattern, edit it
2. Enable **"Include in push protection"** (GA August 2025)
3. This blocks commits containing matches for the custom pattern

**Time to Complete:** ~15 minutes per pattern

#### Code Implementation

{% include pack-code.html vendor="github" section="5.11" %}

#### Compliance Mappings
- **CIS Controls:** 16.12 (Implement code-level security checks)
- **NIST 800-53:** IA-5 (Authenticator management), SI-4 (Information system monitoring)
- **SOC 2:** CC6.1

---

## 6. Dependency & Supply Chain Security

### 6.1 Enable Dependency Review for Pull Requests

**Profile Level:** L1 (Baseline)
**SLSA:** Build L2
**NIST 800-53:** SA-12

#### Description
Automatically block pull requests that introduce vulnerable or malicious dependencies using the dependency-review-action.

#### Rationale
**Attack Vector:** Typosquatting, dependency confusion, compromised packages

**Real-World Incidents:**
- **event-stream (2018):** Popular npm package hijacked, malicious code added to steal Bitcoin wallet credentials
- **ua-parser-js (2021):** Maintainer account compromised, cryptominer injected
- **codecov (2021):** Bash uploader modified to exfiltrate environment variables

#### ClickOps Implementation

**Step 1: Enable Dependency Graph**
1. **Repository Settings** -> **Code security and analysis**
2. Enable **Dependency graph** (should already be enabled from Section 2.2)

**Step 2: Add Dependency Review Action**

{% include pack-code.html vendor="github" section="4.5" %}

**Time to Complete:** ~10 minutes

#### Code Implementation

{% include pack-code.html vendor="github" section="6.1" %}

{% include pack-code.html vendor="github" section="4.1" %}
{% include pack-code.html vendor="github" section="4.2" %}

#### Compliance Mappings
- **SLSA:** Build L2 (Dependency pinning)
- **NIST 800-53:** SA-12 (Supply chain protection)
- **SOC 2:** CC7.2

---

### 6.2 Pin Dependencies to Specific Versions (Hash Verification)

**Profile Level:** L2 (Hardened)
**SLSA:** Build L3

#### Description
Pin all dependencies (npm, pip, go modules, etc.) to specific versions with hash verification. Prevents dependency confusion and version confusion attacks.

#### Rationale
**Attack Prevention:**
- Prevents automatic pulling of compromised new versions
- Hash verification ensures package hasn't been tampered with
- Reproducible builds

#### Implementation by Ecosystem

{% include pack-code.html vendor="github" section="6.2" %}

#### Automated Pinning

Use Dependabot or Renovate to keep pins up-to-date while maintaining hash verification.

{% include pack-code.html vendor="github" section="5.1" %}
{% include pack-code.html vendor="github" section="5.2" %}

#### Compliance Mappings
- **SLSA:** Build L3 (Hermetic builds)
- **NIST 800-53:** SA-12

---

### 6.3 Configure Dependabot Grouped Security Updates

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SA-12, SI-2

#### Description
Configure Dependabot with grouped updates to reduce PR noise while keeping dependencies current. Group minor and patch updates by dependency type (production vs. development) to create fewer, more manageable pull requests.

#### Rationale
**Why Grouped Updates:**
- Individual PRs per dependency overwhelm teams with hundreds of PRs
- Grouped updates combine related updates into a single PR for easier review
- Reduces CI/CD load by running fewer pipeline executions
- Teams are more likely to review and merge timely updates

#### ClickOps Implementation

**Step 1: Create Dependabot Configuration**
1. In your repository, create `.github/dependabot.yml`
2. Define package ecosystems to monitor (npm, pip, GitHub Actions, etc.)
3. Configure grouped updates with `groups:` section

**Step 2: Configure Groups**
- Group by dependency type (`production` vs `development`)
- Group by update type (`minor` and `patch` together, `major` separately)
- Use patterns to group related packages (e.g., all `@aws-sdk/*` packages)

**Step 3: Set Limits**
- Set `open-pull-requests-limit` to control PR volume (default: 5)
- Major version updates should remain individual PRs for careful review

**Time to Complete:** ~10 minutes

#### Code Implementation

{% include pack-code.html vendor="github" section="6.3" %}

#### Compliance Mappings
- **NIST 800-53:** SA-12 (Supply chain protection), SI-2 (Flaw remediation)
- **SOC 2:** CC7.1

---

### 6.4 Enable Build Provenance and npm Provenance

**Profile Level:** L2 (Hardened)
**SLSA:** Build L2+
**NIST 800-53:** SA-12, SA-15

#### Description
Generate SLSA build provenance attestations for artifacts and publish npm packages with provenance. Build provenance creates a verifiable link between an artifact and its source code, build instructions, and build environment using Sigstore signing.

#### Rationale
**Why Build Provenance:**
- Consumers can verify artifacts were built from the claimed source code
- Detects tampering between build and distribution
- npm provenance connects packages to their source repository and CI/CD workflow
- Required for SLSA Build Level 2+ compliance

**npm Trusted Publishing (2025+):** When using OIDC-based trusted publishing, provenance attestations are automatically generated without requiring the `--provenance` flag, and long-lived npm tokens are eliminated entirely.

#### ClickOps Implementation

**Step 1: Enable Artifact Attestations**
1. **Repository Settings** -> **Code security and analysis**
2. Enable **Artifact attestations** (if not already enabled)
3. For public repos, attestations use the public Sigstore instance
4. For private repos, attestations use GitHub's private Sigstore instance (requires Enterprise Cloud)

**Step 2: Add Provenance to CI/CD**
- Add `actions/attest-build-provenance` to your release workflow
- For npm packages, add `--provenance` flag to `npm publish`
- Ensure workflow has `id-token: write` and `attestations: write` permissions

**Time to Complete:** ~15 minutes

#### Code Implementation

**npm Provenance Publishing:**

{% include pack-code.html vendor="github" section="6.4" %}

**SLSA Build Provenance Attestation:**

{% include pack-code.html vendor="github" section="6.5" %}

#### Compliance Mappings
- **SLSA:** Build L2 (Provenance), Build L3 (Signed provenance)
- **NIST 800-53:** SA-12 (Supply chain protection), SA-15 (Development process, standards, and tools)
- **SOC 2:** CC7.2

---

### 6.5 Enforce Dependency Review Across the Organization

**Profile Level:** L2 (Hardened)
**Requires:** GitHub Enterprise Cloud
**NIST 800-53:** SA-12, SA-11

#### Description
Use organization rulesets to enforce the dependency-review-action as a required workflow across all repositories. This ensures no repository can merge PRs with vulnerable dependencies without review, regardless of individual repository settings.

#### Rationale
**Why Organization-Wide Enforcement:**
- Individual repository setup is inconsistent -- some repos may skip dependency review
- Organization rulesets enforce policies uniformly across all repos
- Prevents teams from disabling security checks on their own repositories
- Provides centralized visibility into dependency review compliance

#### ClickOps Implementation

**Step 1: Create Required Workflow**
1. Create a `.github/workflows/dependency-review.yml` in a central repository (e.g., `.github` repo)
2. Configure with your organization's severity threshold and license policy

**Step 2: Create Organization Ruleset**
1. **Organization Settings** -> **Rules** -> **Rulesets**
2. Click **"New ruleset"** -> **"New branch ruleset"**
3. Set target branches: `main`, `master`
4. Set target repositories: **All repositories** (or select specific ones)
5. Under **Rules**, add **"Require workflows to pass before merging"**
6. Select the dependency-review workflow from your central repository
7. Set enforcement to **Active**

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="github" section="6.6" %}

#### Compliance Mappings
- **NIST 800-53:** SA-12 (Supply chain protection), SA-11 (Developer testing and evaluation)
- **SOC 2:** CC7.2
- **SLSA:** Build L2

---

## 7. Modern Platform Features

### 7.1 Configure Copilot Governance

**Profile Level:** L1 (Baseline)
**Requires:** GitHub Copilot Business or Enterprise
**NIST 800-53:** AC-3, AU-2

#### Description
Configure Copilot governance policies including content exclusions to prevent Copilot from accessing sensitive files, enable audit logging for Copilot usage, and manage Copilot feature policies at the organization and enterprise level.

#### Rationale
**Why Copilot Governance Matters:**
- Copilot reads file context to generate suggestions -- sensitive files (secrets, credentials, PII) should be excluded
- Content exclusions prevent Copilot from processing files matching specified patterns
- Audit logging tracks Copilot usage for compliance and security monitoring
- Enterprise-level policies (GA February 2026) control which Copilot features are available

**Content Exclusion Scope:**
- IDE-level content exclusions are GA
- GitHub.com content exclusions are in preview (January 2025)
- Exclusions prevent Copilot from using file content for suggestions but do not prevent developers from opening the files

#### ClickOps Implementation

**Step 1: Configure Copilot Policies**
1. Navigate to: **Organization Settings** -> **Copilot** -> **Policies**
2. Configure feature access:
   - **Suggestions matching public code:** Block or allow
   - **Chat in IDE:** Enable or disable
   - **Chat in GitHub.com:** Enable or disable
   - **CLI:** Enable or disable

**Step 2: Set Content Exclusions**
1. **Organization Settings** -> **Copilot** -> **Content exclusion**
2. Add paths to exclude from Copilot context:
   - `**/.env*` -- Environment files
   - `**/secrets/**` -- Secret directories
   - `**/*.pem` -- Certificate files
   - `**/*.key` -- Private keys
   - `**/credentials/**` -- Credential files
3. Apply per-repository or organization-wide

**Step 3: Review Audit Logs**
1. **Organization Settings** -> **Audit log**
2. Filter by `action:copilot` to see Copilot-related events
3. Monitor for unusual Copilot usage patterns

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="github" section="7.2" %}

**Note:** No Terraform provider support exists for Copilot policies at this time.

#### Compliance Mappings
- **CIS Controls:** 3.3 (Configure data access control lists)
- **NIST 800-53:** AC-3 (Access enforcement), AU-2 (Audit events)
- **SOC 2:** CC6.1

---

### 7.2 Create Custom Repository Roles

**Profile Level:** L2 (Hardened)
**Requires:** GitHub Enterprise Cloud
**NIST 800-53:** AC-2, AC-3
**CIS Controls:** 6.8

#### Description
Create custom repository roles to define fine-grained permission sets beyond the built-in Read, Triage, Write, Maintain, and Admin roles. Custom roles allow precise access control -- for example, a "Security Reviewer" role that can view and dismiss security alerts without write access to code.

#### Rationale
**Why Custom Roles:**
- Built-in roles don't cover all access patterns (e.g., security-only access)
- Reduces over-permissioning by providing exact permissions needed
- Supports separation of duties between development and security teams
- Each custom role inherits from a base role (Read, Triage, Write, or Maintain) and adds specific permissions

#### ClickOps Implementation

**Step 1: Create Custom Role**
1. Navigate to: **Organization Settings** -> **Repository roles**
2. Click **"Create a role"**
3. Set role name and description (e.g., "Security Reviewer")
4. Select base role (e.g., Read)
5. Add additional permissions:
   - **Security events** -- View and manage security alerts
   - **View secret scanning alerts** -- See detected secrets
   - **Dismiss secret scanning alerts** -- Close false positives
   - **View Dependabot alerts** -- See vulnerable dependencies
   - **Dismiss Dependabot alerts** -- Close resolved alerts
6. Click **"Create role"**

**Step 2: Assign Custom Role**
1. **Repository Settings** -> **Collaborators and teams**
2. Add team or user
3. Select the custom role from the dropdown

**Time to Complete:** ~10 minutes per role

#### Code Implementation

{% include pack-code.html vendor="github" section="7.3" %}

#### Compliance Mappings
- **CIS Controls:** 6.8 (Define and maintain role-based access control)
- **NIST 800-53:** AC-2 (Account management), AC-3 (Access enforcement)
- **SOC 2:** CC6.1, CC6.2

---

### 7.3 Enforce Required Workflows via Organization Rulesets

**Profile Level:** L2 (Hardened)
**Requires:** GitHub Enterprise Cloud
**NIST 800-53:** SA-11, CM-3

#### Description
Use organization rulesets to enforce required workflows (security scans, code quality checks, dependency review) across all or selected repositories. This ensures security gates cannot be bypassed at the repository level.

#### Rationale
**Why Required Workflows:**
- Repository-level branch protection can be disabled by repo admins
- Organization rulesets are managed centrally and cannot be overridden by repo admins
- Ensures consistent security checks across the entire organization
- Supports compliance by guaranteeing that all code changes pass required checks

#### ClickOps Implementation

**Step 1: Prepare Central Workflows**
1. Create a `.github` repository in your organization (if it doesn't exist)
2. Add required workflow files (e.g., `security-scan.yml`, `dependency-review.yml`)
3. These workflows will be referenced by the organization ruleset

**Step 2: Create Organization Ruleset**
1. Navigate to: **Organization Settings** -> **Rules** -> **Rulesets**
2. Click **"New ruleset"** -> **"New branch ruleset"**
3. Set name: "Required Security Workflows"
4. Set enforcement: **Active**
5. Set target branches: `refs/heads/main`, `refs/heads/master`
6. Set target repositories: **All repositories** (exclude `.github` repo)
7. Under **Rules**, add **"Require workflows to pass before merging"**
8. Select each required workflow and its source repository
9. Click **"Create"**

**Step 3: Test Enforcement**
1. Create a test PR in a target repository
2. Verify the required workflow runs automatically
3. Confirm the PR cannot be merged until the workflow passes

**Time to Complete:** ~20 minutes

#### Code Implementation

{% include pack-code.html vendor="github" section="7.4" %}

**Note:** No Terraform provider support exists for required workflow rulesets at this time.

#### Compliance Mappings
- **CIS Controls:** 16.12 (Implement code-level security checks)
- **NIST 800-53:** SA-11 (Developer testing and evaluation), CM-3 (Configuration change control)
- **SOC 2:** CC7.1, CC8.1

---

## 8. Monitoring & Audit Logging

### 8.1 Enable Audit Log Streaming to SIEM

**Profile Level:** L2 (Hardened)
**Requires:** GitHub Enterprise Cloud

#### Description
Stream GitHub audit logs to your SIEM (Splunk, Datadog, AWS Security Lake) for centralized monitoring and alerting.

#### Rationale
**Detection Use Cases:**
- Unusual authentication patterns (brute force, credential stuffing)
- Privilege escalation (user added to admin team)
- Data exfiltration (bulk repository clones)
- Supply chain attacks (malicious workflow modifications)

#### ClickOps Implementation

1. **Enterprise Settings** -> **Audit log** -> **Log streaming**
2. Click "Configure stream"
3. Choose destination:
   - **Amazon S3**
   - **Azure Blob Storage**
   - **Azure Event Hubs**
   - **Datadog**
   - **Google Cloud Storage**
   - **Splunk** (HTTP Event Collector)
4. Configure endpoint details
5. Enable **Git events** for repository activity
6. Select event categories to stream
7. Test connection
8. Enable stream

**Time to Complete:** ~30 minutes

#### Code Implementation

{% include pack-code.html vendor="github" section="5.7" %}
{% include pack-code.html vendor="github" section="5.3" %}

**Note:** No Terraform provider support exists for audit log streaming configuration at this time.

#### Key Events to Monitor

These events should be prioritized in your SIEM alert rules:

| Event | Description | Alert Priority |
|-------|-------------|----------------|
| `org.add_member` | New member added to org | Medium |
| `repo.destroy` | Repository deleted | High |
| `protected_branch.destroy` | Branch protection removed | Critical |
| `protected_branch.policy_override` | Admin bypassed branch protection | High |
| `oauth_authorization.create` | New OAuth app authorized | Medium |
| `personal_access_token.create` | New PAT created | Medium |
| `copilot.content_exclusion_changed` | Copilot exclusion rules modified | Medium |
| `secret_scanning_push_protection.bypass` | Push protection bypassed | High |
| `org.update_member_repository_creation_permission` | Repo creation permissions changed | Medium |

#### Detection Queries

{% include pack-code.html vendor="github" section="7.1" %}

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2 | System monitoring |
| **NIST 800-53** | AU-2, AU-6 | Audit events, audit review and analysis |
| **ISO 27001** | A.12.4.1 | Event logging |
| **CIS Controls** | 8.2 | Collect audit logs |

---

### 8.2 Use Security Overview Dashboard

**Profile Level:** L1 (Baseline)
**Requires:** GitHub Enterprise Cloud with GHAS
**NIST 800-53:** RA-5, SI-4

#### Description
Use the Security Overview dashboard to get a consolidated view of security alert status across all repositories in the organization. Monitor Dependabot, secret scanning, and code scanning alerts from a single interface with filtering and trend analysis.

#### Rationale
**Why Security Overview:**
- Provides organization-wide visibility into security posture without checking each repo individually
- Tracks alert trends over time to measure security improvement
- Identifies repositories with the most critical vulnerabilities
- Enables security teams to prioritize remediation efforts

#### ClickOps Implementation

**Step 1: Access Security Overview**
1. Navigate to: **Organization page** -> **Security** tab
2. Review the overview dashboard showing:
   - Total open alerts by type (Dependabot, secret scanning, code scanning)
   - Alert trends over time
   - Repositories with most alerts

**Step 2: Filter and Prioritize**
1. Filter by severity: Focus on **Critical** and **High** alerts first
2. Filter by repository: Identify highest-risk repositories
3. Filter by alert type: Address secret scanning alerts immediately (active credentials)

**Step 3: Export and Report**
1. Use the Security Overview API to extract metrics for reporting
2. Track key metrics: mean time to remediation, open critical alerts, coverage percentage

**Time to Complete:** ~5 minutes for initial review, ongoing monitoring

#### Code Implementation

{% include pack-code.html vendor="github" section="8.1" %}

#### Compliance Mappings
- **CIS Controls:** 7.5 (Perform automated vulnerability scans)
- **NIST 800-53:** RA-5 (Vulnerability monitoring and scanning), SI-4 (Information system monitoring)
- **SOC 2:** CC7.1, CC7.2

---

### 8.3 Apply GitHub-Recommended Security Configuration

**Profile Level:** L1 (Baseline)
**Requires:** GitHub Enterprise Cloud

#### Description
Apply GitHub's code security configurations to all repositories in the organization. Security configurations (GA July 2024) are named profiles that bundle security feature settings and can be applied to repository groups for consistent coverage.

#### Rationale
**Why Security Configurations:**
- Ensures no repository is left without basic security features
- Named profiles allow different tiers (e.g., "Standard" and "High Security")
- New repositories automatically receive the assigned configuration
- Custom configurations can layer stricter requirements on top of GitHub's defaults

#### ClickOps Implementation

**Step 1: Access Security Configurations**
1. Navigate to: **Organization Settings** -> **Code security** -> **Configurations**

**Step 2: Apply GitHub Recommended**
1. Select **GitHub recommended** configuration
2. Review included settings:
   - Dependency graph
   - Dependabot alerts and security updates
   - Secret scanning and push protection
   - Code scanning (default setup)
3. Apply to all repositories

**Step 3: Create Custom Configuration (Optional)**
1. For stricter requirements, click **"New configuration"**
2. Name it (e.g., "High Security")
3. Enable additional settings:
   - Grouped security updates
   - Custom secret scanning patterns
   - Security-extended CodeQL queries
   - Non-provider pattern scanning
4. Apply to specific repository sets based on sensitivity

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="github" section="5.8" %}

**Note:** No Terraform provider support exists for code security configurations at this time.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.1 | Configuration management |
| **NIST 800-53** | CM-6 | Configuration settings |
| **ISO 27001** | A.12.1.1 | Documented operating procedures |
| **CIS Controls** | 4.1 | Secure configuration of enterprise assets |

---

## 9. Third-Party Integration Security

### 9.1 Integration Risk Assessment Matrix

Before allowing any third-party integration access to GitHub, assess risk:

| Risk Factor | Low (1 pt) | Medium (2 pts) | High (3 pts) |
|-------------|------------|----------------|--------------|
| **Repository Access** | Public repos only | Read private repos | Write access to repos |
| **OAuth Scopes** | `read:user`, `public_repo` | `repo:status`, `read:org` | `repo`, `admin:org` |
| **Token Lifetime** | Session-based (hours) | Days | Persistent/no expiration |
| **Vendor Security** | SOC 2 Type II, pen tested | SOC 2 Type I | No certifications |
| **Data Sensitivity** | Non-production data | Some prod access | Full prod/secrets access |
| **Runner Access** | None | GitHub-hosted only | Self-hosted runners |

**Decision Matrix:**
- **6-8 points:** Approve with standard OAuth scope restrictions
- **9-12 points:** Approve with enhanced monitoring + restricted repos
- **13-18 points:** Require security review, minimize scope, or reject

---

### 9.2 Common Integrations and Recommended Controls

#### CI/CD Platforms (CircleCI, Jenkins, Travis CI)

**Data Access:** High (read/write repos, access to secrets)

**Recommended Controls:**
- Use GitHub App integration (scoped permissions) instead of OAuth tokens
- Restrict to specific repositories (not all org repos)
- Use OIDC for cloud credentials (see Section 5.2) -- never store long-lived cloud keys
- **Note:** CircleCI was breached in January 2023 -- high-risk integration
- Rotate any remaining OAuth tokens quarterly
- Monitor audit logs for bulk repository access and unusual clone patterns

---

#### Dependency Scanning (Snyk, Mend, Socket)

**Data Access:** Medium (read repos, write security alerts)

**Recommended Controls:**
- Use vendor's GitHub App (scoped permissions) instead of OAuth app
- Scope to repos with actual dependencies (not docs/config repos)
- Review security alerts weekly -- don't let them accumulate
- For Snyk: OAuth scope `repo:read`, `security_events:write`

---

#### Dependabot / Renovate (Dependency Updates)

**Data Access:** Medium-High (read repos, create PRs, update dependencies)

**Recommended Controls:**
- Use GitHub-native Dependabot (preferred -- built-in, no external access)
- If using Renovate: Scope to `repo` only, self-host if possible
- Require PR reviews for dependency update PRs (don't auto-merge major versions)
- Enable branch protection to require status checks before merge

---

#### Communication (Slack, Microsoft Teams)

**Data Access:** Low-Medium (read repos, post notifications)

**Recommended Controls:**
- Use the vendor's GitHub App with narrow repository selection
- Avoid granting write permissions
- Filter notifications to avoid leaking sensitive data in public channels
- Review connected channels quarterly

---

#### Code Quality (SonarQube, SonarCloud, CodeClimate)

**Data Access:** Medium (read repos, write analysis results)

**Recommended Controls:**
- Use vendor's GitHub App for scoped permissions
- OAuth scope: `repo:read`, `statuses:write`, `checks:write`
- Ensure the tool doesn't store secrets from scanned code
- Review code analysis results before merging

---

#### Security Tooling (OpenSSF Scorecard, StepSecurity, Allstar)

**Data Access:** Low-Medium (read repos, write check results)

**Recommended Controls:**
- **OpenSSF Scorecard:** Use `ossf/scorecard-action` to assess repository security posture
- **StepSecurity Harden-Runner:** Use `step-security/harden-runner` to detect and block exfiltration from GitHub Actions workflows
- **Allstar:** Install the Allstar GitHub App to enforce security policies across repos
- These tools improve security posture -- prioritize adoption over risk mitigation

**Self-Hosted Runner Risk:** Research in 2024 found 43,803 public repositories with exposed self-hosted runners. If your integrations use self-hosted runners, ensure they are ephemeral (see Section 3.4) and restricted to private repository workflows only.

---

## Appendix A: Edition Compatibility

| Feature | GitHub Free | GitHub Team | Enterprise Cloud | Enterprise Server |
|---------|------------|-------------|-----------------|-------------------|
| 2FA Enforcement | Yes | Yes | Yes | Yes |
| Branch Protection | Basic | Yes | Yes (advanced) | Yes (advanced) |
| Repository Rulesets | No | No | Yes | Yes |
| SAML SSO | No | No | Yes | Yes |
| SCIM Provisioning | No | No | Yes | Yes |
| IP Allow List | No | No | Yes | Yes |
| Secret Protection ($19/committer/mo) | Public repos | Public repos | Yes | Yes (add-on) |
| Code Security ($30/committer/mo) | Public repos | Public repos | Yes | Yes (add-on) |
| Push Protection | Public repos | Public repos | Yes | Yes |
| Custom Secret Patterns | No | No | Yes | Yes |
| Delegated Bypass for Push Protection | No | No | Yes | Yes |
| Dependency Review Action | Yes | Yes | Yes | Yes |
| Copilot (Business/Enterprise) | No | No | Yes | Yes |
| Custom Repository Roles | No | No | Yes | No |
| Audit Log Streaming | No | No | Yes | Yes |
| Required Workflows (org rulesets) | No | No | Yes | Yes |
| Security Overview Dashboard | No | No | Yes | Yes |
| Self-Hosted Runner Groups | No | No | Yes | Yes |

---

## Appendix B: References

**Official GitHub Documentation:**
- [GitHub Enterprise Cloud Trust Center](https://ghec.github.trust.page/)
- [GitHub Copilot Trust Center](https://copilot.github.trust.page/)
- [GitHub Docs](https://docs.github.com/en)
- [Enterprise Cloud Documentation](https://docs.github.com/en/enterprise-cloud@latest)
- [Best Practices for Securing Accounts](https://docs.github.com/en/enterprise-cloud@latest/code-security/tutorials/implement-supply-chain-best-practices/securing-accounts)
- [Configuring SAML SSO for Your Enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/using-saml-for-enterprise-iam/configuring-saml-single-sign-on-for-your-enterprise)
- [SAML SSO for Enterprise Managed Users](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/configuring-authentication-for-enterprise-managed-users/configuring-saml-single-sign-on-for-enterprise-managed-users)
- [SAML Configuration Reference](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/iam-configuration-reference/saml-configuration-reference)
- [Hardening security for your enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/configuring-settings/hardening-security-for-your-enterprise)
- [Security hardening for GitHub Actions](https://docs.github.com/en/enterprise-cloud@latest/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions)
- [GitHub Advanced Security](https://docs.github.com/en/get-started/learning-about-github/about-github-advanced-security)
- [Accessing Compliance Reports](https://docs.github.com/en/enterprise-cloud@latest/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/accessing-compliance-reports-for-your-organization)

**API & Developer Documentation:**
- [REST API Reference](https://docs.github.com/en/rest)
- [Enterprise Cloud REST API](https://docs.github.com/en/enterprise-cloud@latest/rest)
- [GraphQL API](https://docs.github.com/en/graphql)
- [GitHub CLI (gh)](https://cli.github.com/)
- [Accessing Compliance Reports for Your Enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/overview/accessing-compliance-reports-for-your-enterprise)

**GHAS Product Changes (April 2025):**
- [Secret Protection](https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning) -- $19/committer/month (standalone)
- [Code Security](https://docs.github.com/en/code-security/code-scanning/introduction-to-code-scanning/about-code-scanning) -- $30/committer/month (standalone)
- [GHAS Unbundling Announcement](https://github.blog/news-insights/product-news/github-availability-report-march-2025/)

**Supply Chain Security Frameworks:**
- [SLSA Framework](https://slsa.dev/)
- [SLSA GitHub Generator](https://github.com/slsa-framework/slsa-github-generator)
- [OpenSSF Supply Chain Integrity WG](https://github.com/ossf/wg-supply-chain-integrity)
- [Achieving SLSA 3 with GitHub Actions](https://github.blog/security/supply-chain-security/slsa-3-compliance-with-github-actions/)
- [npm Provenance](https://docs.npmjs.com/generating-provenance-statements)
- [GitHub Attestations](https://docs.github.com/en/actions/security-for-github-actions/using-artifact-attestations/using-artifact-attestations-to-establish-provenance-for-builds)

**Copilot Governance:**
- [Managing Copilot Policies](https://docs.github.com/en/copilot/managing-copilot/managing-github-copilot-in-your-organization/managing-policies-for-copilot-in-your-organization)
- [Content Exclusions for Copilot](https://docs.github.com/en/copilot/managing-copilot/managing-github-copilot-in-your-organization/configuring-content-exclusions-for-github-copilot)

**Compliance Frameworks:**
- SOC 1 Type II, SOC 2 Type II, ISO/IEC 27001:2013, CSA CAIQ Level 1, CSA STAR Level 2 -- via [Trust Center](https://ghec.github.trust.page/)
- GitHub Copilot included in SOC 2 Type 1 and ISO 27001 certification scope (June 2024)

**Security Incidents:**
- **March 2025 tj-actions/changed-files Compromise:** Supply chain attack modified the popular GitHub Action (23,000+ repositories), retroactively repointing version tags to a malicious commit that exfiltrated CI/CD secrets from workflow logs.
- **March-June 2025 Salesloft/Drift Breach (UNC6395):** Threat actor accessed Salesloft GitHub account, downloaded repository content, and established workflows -- affecting 700+ organizations including Cloudflare, Zscaler, and Palo Alto Networks.
- **November 2025 Service Outage:** Expired internal TLS certificate caused failures on all Git operations.
- **Code Signing Certificate Theft (January 2023):** Attacker used a compromised PAT to access GitHub repositories and steal encrypted code-signing certificates for GitHub Desktop and Atom. Certificates were revoked February 2, 2023.
- **Fake Dependabot Commits (July 2023):** Stolen GitHub PATs used to inject malicious commits disguised as Dependabot contributions across hundreds of public and private repositories.
- [CircleCI Security Incident (January 2023)](https://circleci.com/blog/january-4-2023-security-alert/) -- OAuth tokens stolen, used to access customer GitHub repositories.
- [Codecov Bash Uploader Compromise (April 2021)](https://about.codecov.io/security-update/) -- Modified uploader exfiltrated environment variables from CI/CD pipelines.
- [Heroku/Travis CI GitHub OAuth Token Leak (April 2022)](https://github.blog/2022-04-15-security-alert-stolen-oauth-user-tokens/) -- Stolen OAuth tokens used for unauthorized repository access.

**Community Resources:**
- [GitHub Hardening Guide by iAnonymous3000](https://github.com/iAnonymous3000/GitHub-Hardening-Guide)
- [Step Security - Harden-Runner for GitHub Actions](https://github.com/step-security/harden-runner)
- [CIS GitHub Benchmark](https://www.cisecurity.org/benchmark/software_supply_chain_security)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-03-07 | 0.3.0 | draft | Revamp sections 4-9: OAuth app auditing, GHAS unbundling, push protection delegated bypass, custom secret patterns, OIDC, build provenance, Copilot governance, custom roles, required workflows, security overview dashboard | Claude Code (Opus 4.6) |
| 2026-02-12 | 0.2.0 | draft | Merged enterprise guide, added code pack integration, comprehensive controls | Claude Code (Opus 4.6) |
| 2025-12-13 | 0.1.0 | draft | Initial GitHub hardening guide with supply chain security focus | Claude Code (Opus 4.5) |

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

**Sources:**

This guide was compiled from the following authoritative sources:

- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks)
- [DISA STIGs](https://www.cyber.mil/stigs/)
- [GitHub Enterprise Security Hardening Documentation](https://docs.github.com/en/enterprise-cloud@latest/admin/configuring-settings/hardening-security-for-your-enterprise)
- [GitHub Actions Security Hardening Guide](https://docs.github.com/en/enterprise-cloud@latest/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions)
- [GitHub Advanced Security Documentation](https://docs.github.com/en/get-started/learning-about-github/about-github-advanced-security)
- [SLSA Framework](https://slsa.dev/)
- [OpenSSF Supply Chain Integrity Working Group](https://github.com/ossf/wg-supply-chain-integrity)
- [Achieving SLSA 3 Compliance with GitHub Actions](https://github.blog/security/supply-chain-security/slsa-3-compliance-with-github-actions/)
