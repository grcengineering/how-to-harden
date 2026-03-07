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
7. [Monitoring & Governance](#7-monitoring--governance)
8. [Third-Party Integration Security](#8-third-party-integration-security)

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

### 1.6 Enforce Fine-Grained Personal Access Token Policies

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-6 (Least Privilege), IA-4 (Identifier Management), IA-5 (Authenticator Management)
**CIS Controls:** 6.2

#### Description
Configure organization-level policies for personal access tokens (PATs) to require approval for fine-grained tokens and restrict or disable classic PATs. Fine-grained PATs offer scoped repository access, mandatory expiration, and organization policy enforcement. Classic PATs grant broad, long-lived access that cannot be scoped to specific repositories.

#### Rationale
**Attack Prevented:** Overprivileged token theft, lateral movement via stolen credentials

**Real-World Incidents:**
- **GitHub Code Signing Certificate Theft (January 2023):** Attacker used a compromised classic PAT to access repositories and steal encrypted code-signing certificates for GitHub Desktop and Atom.
- **Fake Dependabot Commits (July 2023):** Stolen classic PATs used to inject malicious commits disguised as Dependabot contributions across hundreds of repositories.
- **SpotBugs PAT Theft (2025):** Attacker exploited a `pull_request_target` workflow to steal a maintainer's classic PAT, then pivoted to compromise the tj-actions/changed-files Action affecting 23,000+ repositories.

**Why This Matters:** Classic PATs have no repository scoping, no expiration requirement, and no approval workflow -- a single stolen classic PAT can grant access to every repository in an organization.

#### ClickOps Implementation

**Step 1: Configure PAT Policies**
1. Navigate to: **Organization Settings** -> **Personal access tokens** -> **Settings**
2. Under "Fine-grained personal access tokens":
   - Select **"Require administrator approval"** for fine-grained tokens
3. Under "Personal access tokens (classic)":
   - Select **"Restrict access via personal access tokens (classic)"** to block classic PATs from accessing the organization

**Step 2: Review Existing Tokens**
1. Navigate to: **Organization Settings** -> **Personal access tokens** -> **Active tokens**
2. Review all active fine-grained tokens for:
   - Appropriate repository scope
   - Reasonable expiration dates
   - Minimal permissions
3. Revoke any overprivileged or unused tokens

**Step 3: Approve Token Requests**
1. Navigate to: **Organization Settings** -> **Personal access tokens** -> **Pending requests**
2. Review each request for appropriate scope and permissions
3. Approve or deny based on least-privilege requirements

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="github" section="1.12" %}

#### Validation & Testing
1. [ ] Verify classic PATs are restricted from accessing the organization
2. [ ] Create a fine-grained PAT and verify it requires approval
3. [ ] Verify fine-grained PATs can only access specified repositories
4. [ ] Confirm existing classic PATs are blocked (or plan migration timeline)

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC6.3 | Logical access security, token management |
| **NIST 800-53** | AC-6, IA-4, IA-5 | Least privilege, identifier and authenticator management |
| **ISO 27001** | A.9.2.3, A.9.4.1 | Management of privileged access rights |
| **PCI DSS** | 7.1, 8.6 | Restrict access, application and system account management |

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

### 2.5 Enable Private Vulnerability Reporting

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SI-2 (Flaw Remediation), SI-5 (Security Alerts), IR-6 (Incident Reporting)

#### Description
Enable private vulnerability reporting on all repositories to allow security researchers to confidentially report vulnerabilities. Without this feature, researchers may publicly disclose vulnerabilities or not report them at all, leaving your organization exposed.

#### Rationale
**Attack Prevented:** Uncoordinated public disclosure, zero-day exploitation

**Why This Matters:**
- Security researchers discovering vulnerabilities in your code need a private channel to report them
- Without private reporting, researchers may open public issues (exposing the vulnerability) or simply not report
- Private vulnerability reporting creates GitHub Security Advisories that can be triaged and patched before disclosure
- Demonstrates organizational commitment to responsible disclosure practices

#### ClickOps Implementation

**Step 1: Enable for a Single Repository**
1. Navigate to: **Repository Settings** -> **Code security and analysis**
2. Under "Private vulnerability reporting":
   - Click **Enable**

**Step 2: Enable Organization-Wide**
1. Navigate to: **Organization Settings** -> **Code security and analysis**
2. Under "Private vulnerability reporting":
   - Click **Enable all** to enable for all existing repositories
   - Check **"Automatically enable for new repositories"**

**Time to Complete:** ~5 minutes

#### Code Implementation

{% include pack-code.html vendor="github" section="2.9" %}

#### Validation & Testing
1. [ ] Navigate to a repository's Security tab and verify "Report a vulnerability" button appears
2. [ ] Submit a test vulnerability report to verify the workflow
3. [ ] Verify organization admins receive notification of the report
4. [ ] Confirm new repositories automatically have the feature enabled

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.1, CC7.4 | Security event identification and response |
| **NIST 800-53** | SI-2, SI-5, IR-6 | Flaw remediation, security alerts, incident reporting |
| **ISO 27001** | A.16.1.2, A.16.1.3 | Reporting information security events |

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

#### Description
Review all OAuth apps with access to your organization. Revoke unnecessary apps, restrict scopes for remaining apps.

#### Rationale
**Attack Vector:** When CircleCI was breached, attackers exfiltrated GitHub OAuth tokens. These tokens had broad permissions, allowing attackers to access private repositories and secrets.

**Real-World Incident:**
- **CircleCI Breach (January 2023):** Tokens for GitHub, AWS, and other services stolen. GitHub OAuth tokens allowed repository access.
- **Heroku/Travis CI (April 2022):** GitHub OAuth tokens leaked, used for unauthorized repository access.

#### ClickOps Implementation

**Step 1: Audit Installed Apps**
1. **Organization Settings** -> **OAuth Apps** (or **GitHub Apps**)
2. Review each app:
   - When was it last used?
   - What permissions does it have?
   - Is it still needed?
3. Click app -> "Review" -> Check granted permissions

**Step 2: Revoke Unnecessary Apps**
- Click "Revoke" for unused apps
- For remaining apps, click "Restrict access" to limit to specific repositories

**Step 3: Restrict New App Installation**
1. **Organization Settings** -> **OAuth application policy**
2. Select **"Restrict installation of OAuth Apps"**
3. Require admin approval for new app installations

**Time to Complete:** ~30 minutes for initial audit

#### Code Implementation

{% include pack-code.html vendor="github" section="4.4" %}

**Automation script:**

{% include pack-code.html vendor="github" section="4.6" %}

{% include pack-code.html vendor="github" section="4.3" %}
{% include pack-code.html vendor="github" section="5.4" %}

#### Recommended Scope Restrictions

| App Type | Recommended Scopes | Avoid |
|----------|-------------------|-------|
| **CI/CD (CircleCI, Travis)** | `repo` (read), `status` (write), `write:packages` (if needed) | `admin:org`, `delete_repo` |
| **Code Analysis (SonarQube)** | `repo:read`, `statuses:write` | `repo:write` |
| **Project Management (Jira)** | `repo:status`, `read:org` | `repo` (full) |
| **Dependency Tools (Snyk, Dependabot)** | `repo:read`, `security_events:write` | `repo:write` |

#### Monitoring

**Monthly Review:**
- Export list of OAuth apps
- Check for apps not used in >90 days
- Verify scope grants haven't increased

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **Developer Workflow** | Low | Apps still work with scoped access |
| **Integration Functionality** | Low | May need to re-authorize apps after scope changes |
| **Security Incidents** | High Reduction | Limits blast radius of token theft |

#### Compliance Mappings
- **SOC 2:** CC6.2 (Least privilege), CC9.2 (Third-party access)
- **NIST 800-53:** AC-6
- **ISO 27001:** A.9.2.1

---

## 5. Secret Management

### 5.1 Use GitHub Actions Secrets with Environment Protection

**Profile Level:** L1 (Baseline)

#### Description
Store sensitive credentials in GitHub Actions secrets (not hardcoded in code). Use environment protection rules to require approval for production secret access. Structure secrets at organization, repository, and environment levels for proper access control.

#### Rationale
**Attack Prevention:**
- Secrets in code -> exposed in Git history forever
- Secrets in logs -> leaked via CI/CD output
- Secrets in unprotected workflows -> stolen via malicious PR

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

**Step 5: Reference Secrets in Workflow**

See the deployment workflow template in the Code Pack below.

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
- Use short-lived credentials where possible (OIDC tokens)
- Track secret age using the Code Pack below

**Secret Sprawl Prevention:**
- Use organization secrets for widely-used credentials
- Limit repository-specific secrets
- Document what each secret is for

**Audit Secret Usage:**
1. Review workflows accessing secrets regularly
2. Remove unused secrets
3. Rotate secrets on a documented schedule

**Never Do:**
- Echo secrets in workflow logs: `echo {% raw %}${{ secrets.API_KEY }}{% endraw %}`
- Write secrets to files that get uploaded as artifacts
- Pass secrets in URLs: `curl https://api.example.com?key={% raw %}${{ secrets.API_KEY }}{% endraw %}`

#### Monitoring

**Alert on secret access:**

{% include pack-code.html vendor="github" section="5.9" %}

#### Compliance Mappings
- **SOC 2:** CC6.1 (Secret management)
- **NIST 800-53:** SC-12 (Cryptographic key management)
- **PCI DSS:** 8.2.1 (Strong cryptography for secrets)

---

### 5.2 Use OpenID Connect (OIDC) Instead of Long-Lived Credentials

**Profile Level:** L2 (Hardened)

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

#### Benefits

**Security:**
- No secrets in GitHub
- Credentials expire in 15 minutes
- Per-repository/branch access control
- Full AWS CloudTrail audit log

**Operations:**
- No credential rotation needed
- No secret management overhead

#### Compliance Mappings
- **SLSA:** Build L3 (Short-lived credentials)
- **NIST 800-53:** IA-5(1) (Authenticator management)
- **SOC 2:** CC6.1

---

### 5.3 Configure Secret Scanning Delegated Bypass

**Profile Level:** L2 (Hardened)
**Requires:** GitHub Enterprise Cloud with GHAS
**NIST 800-53:** AC-3 (Access Enforcement), AC-6 (Least Privilege), IA-5(7) (No Embedded Authenticators)

#### Description
Configure delegated bypass for secret scanning push protection to control who can bypass push protection when a secret is detected. By default, any developer can bypass push protection by providing a reason. Delegated bypass requires a designated reviewer (typically the security team) to approve bypass requests before a detected secret can be committed.

#### Rationale
**Attack Prevented:** Unauthorized secret commits, accidental credential exposure

**Why This Matters:**
- Default push protection allows any developer to bypass with a reason, providing no real enforcement
- Delegated bypass ensures the security team is aware of and approves every secret that enters the codebase
- Creates an audit trail of bypass requests and approvals
- Prevents developers from routinely bypassing push protection without review

#### ClickOps Implementation

**Step 1: Access Code Security Configuration**
1. Navigate to: **Organization Settings** -> **Code security** -> **Configurations**
2. Select your active security configuration (or create one)

**Step 2: Enable Delegated Bypass**
1. Under "Push protection":
   - Set bypass to **"Delegated bypass"**
2. Under "Bypass reviewers":
   - Add your security team as designated reviewers
   - Optionally add specific roles (e.g., Security Managers)

**Step 3: Configure Bypass Request Settings**
1. Set bypass request timeout (recommended: 7 days)
2. Configure notification preferences for reviewers
3. Apply the configuration to target repositories

**Time to Complete:** ~10 minutes

#### Code Implementation

{% include pack-code.html vendor="github" section="2.10" %}

#### Validation & Testing
1. [ ] Attempt to push a test secret (use a revoked key) to a protected repository
2. [ ] Verify push is blocked and bypass request is created
3. [ ] Verify designated reviewers receive the bypass request notification
4. [ ] Approve the request and verify the push succeeds
5. [ ] Deny a request and verify the push remains blocked

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC7.1 | Logical access security, monitoring |
| **NIST 800-53** | AC-3, AC-6, IA-5(7) | Access enforcement, least privilege |
| **ISO 27001** | A.10.1.2, A.9.2.3 | Key management, privileged access |

---

## 6. Dependency & Supply Chain Security

### 6.1 Enable Dependency Review for Pull Requests

**Profile Level:** L1 (Baseline)
**SLSA:** Build L2

#### Description
Automatically block pull requests that introduce vulnerable or malicious dependencies.

#### Rationale
**Attack Vector:** Typosquatting, dependency confusion, compromised packages

**Real-World Incidents:**
- **event-stream (2018):** Popular npm package hijacked, malicious code added to steal Bitcoin wallet credentials
- **ua-parser-js (2021):** Maintainer account compromised, cryptominer injected
- **codecov (2021):** Bash uploader modified to exfiltrate environment variables

**Dependency Review:** Catches these attacks before they merge.

#### ClickOps Implementation

**Step 1: Enable Dependency Graph**
1. **Repository Settings** -> **Code security and analysis**
2. Enable **Dependency graph** (should already be enabled from Section 2.2)

**Step 2: Add Dependency Review Action**

{% include pack-code.html vendor="github" section="4.5" %}

**Time to Complete:** ~10 minutes

#### Code Implementation

Automated via workflow (see above). Can also use CLI:

{% include pack-code.html vendor="github" section="6.1" %}

{% include pack-code.html vendor="github" section="4.1" %}
{% include pack-code.html vendor="github" section="4.2" %}

#### Monitoring

**Track introduced vulnerabilities:** See dependency review and PR vulnerability check commands in the Code Pack above.

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

### 6.3 Enable Artifact Attestations for Supply Chain Provenance

**Profile Level:** L2 (Hardened)
**SLSA:** Build L2-L3
**NIST 800-53:** SA-12 (Supply Chain Protection), SI-7 (Software Integrity)

#### Description
Enable GitHub artifact attestations to generate signed SLSA provenance for build artifacts. Artifact attestations create a cryptographically verifiable link between a build artifact and the source code, workflow, and environment that produced it. Consumers can verify that an artifact was built from a specific commit in a trusted workflow.

#### Rationale
**Attack Prevented:** Artifact substitution, build system compromise, supply chain tampering

**Real-World Incidents:**
- **tj-actions/changed-files (March 2025):** Attacker repointed mutable version tags to malicious commits, exfiltrating CI/CD secrets from 23,000+ repositories. Artifact attestations would have allowed consumers to verify build provenance.
- **SolarWinds (2020):** Build system compromise injected malicious code into signed artifacts. SLSA provenance with attestations would have detected the discrepancy between source and build output.

**Why This Matters:**
- Attestations are signed by Sigstore using the OIDC identity of the GitHub Actions workflow
- Consumers can verify the exact source commit, repository, and workflow that produced an artifact
- Supports SLSA Build L2 (provenance) and L3 (build platform hardening) requirements
- GitHub CLI provides built-in verification via `gh attestation verify`

#### ClickOps Implementation

**Step 1: Enable Artifact Attestations in Organization**
1. Navigate to: **Organization Settings** -> **Actions** -> **General**
2. Ensure GitHub Actions is enabled for the organization

**Step 2: Add Attestation Step to Workflows**
1. Open your release workflow file (e.g., `.github/workflows/release.yml`)
2. Add the `actions/attest-build-provenance` action after build steps
3. Ensure the workflow has `id-token: write` and `attestations: write` permissions

**Time to Complete:** ~20 minutes

#### Code Implementation

{% include pack-code.html vendor="github" section="4.7" %}

#### Validation & Testing
1. [ ] Trigger a build that generates an attestation
2. [ ] Verify attestation appears in the Actions workflow run summary
3. [ ] Run `gh attestation verify` against the produced artifact
4. [ ] Verify the attestation includes correct source commit and workflow information

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SLSA** | Build L2, L3 | Provenance and build platform integrity |
| **SOC 2** | CC7.1, CC8.1 | Security monitoring and change management |
| **NIST 800-53** | SA-12, SI-7 | Supply chain protection, software integrity |
| **ISO 27001** | A.14.2.7, A.14.2.9 | Outsourced development, system acceptance testing |

---

### 6.4 Configure Dependabot Grouped Security Updates

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SI-2 (Flaw Remediation), SA-12 (Supply Chain Protection), RA-5 (Vulnerability Scanning)

#### Description
Configure Dependabot grouped security updates to combine related dependency updates into a single pull request. Without grouping, Dependabot creates individual PRs for each vulnerability, leading to PR fatigue and delayed remediation.

#### Rationale
**Why This Matters:**
- Organizations with many repositories can receive hundreds of individual Dependabot PRs per week
- PR fatigue leads to developers ignoring or delaying security updates
- Grouped updates reduce noise by combining related updates (e.g., all patch-level npm updates)
- Accelerates mean time to remediation by making review more efficient
- Can be configured per ecosystem, dependency type, and severity

#### ClickOps Implementation

**Step 1: Create Dependabot Configuration**
1. In your repository, create `.github/dependabot.yml`
2. Define package ecosystems to monitor
3. Add `groups` configuration to combine related updates

**Step 2: Configure Grouping Strategy**
1. Group by dependency type (production vs. development)
2. Group by update type (patch, minor)
3. Optionally group by pattern (e.g., all `@aws-sdk/*` packages together)

**Time to Complete:** ~10 minutes per repository

#### Code Implementation

{% include pack-code.html vendor="github" section="4.8" %}

#### Validation & Testing
1. [ ] Verify `dependabot.yml` is present and valid
2. [ ] Trigger a Dependabot run and verify grouped PRs are created
3. [ ] Verify grouped PRs include all expected dependency updates
4. [ ] Confirm individual PRs are no longer created for grouped dependencies

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.1, CC7.2 | Security monitoring and response |
| **NIST 800-53** | SI-2, SA-12, RA-5 | Flaw remediation, supply chain, vulnerability scanning |
| **ISO 27001** | A.12.6.1, A.14.2.2 | Technical vulnerability management |

---

## 7. Monitoring & Governance

### 7.1 Enable Audit Log Streaming to SIEM

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

#### Key Events to Monitor

These events should be prioritized in your SIEM alert rules:

| Event | Description | Alert Priority |
|-------|-------------|----------------|
| `org.add_member` | New member added to org | Medium |
| `org.remove_member` | Member removed from org | Low |
| `repo.create` | New repository created | Low |
| `repo.destroy` | Repository deleted | High |
| `protected_branch.create` | Branch protection added | Low |
| `protected_branch.destroy` | Branch protection removed | Critical |
| `oauth_authorization.create` | New OAuth app authorized | Medium |
| `personal_access_token.create` | New PAT created | Medium |
| `protected_branch.policy_override` | Admin bypassed branch protection | High |

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

### 7.2 Apply GitHub-Recommended Security Configuration

**Profile Level:** L1 (Baseline)
**Requires:** GitHub Enterprise Cloud

#### Description
Apply GitHub's recommended security configuration to all repositories in the enterprise. This provides a baseline security posture that can be customized for stricter requirements.

#### Rationale
**Why This Matters:**
- GitHub maintains a curated set of security defaults based on best practices
- Applying this configuration ensures no repository is left without basic security features
- Custom configurations can layer additional requirements on top of the baseline

#### ClickOps Implementation

**Step 1: Access Security Configurations**
1. Navigate to: **Enterprise Settings** -> **Code security** -> **Configurations**

**Step 2: Apply GitHub Recommended**
1. Select **GitHub recommended** configuration
2. Review included settings:
   - Dependency graph
   - Dependabot alerts and security updates
   - Secret scanning and push protection
   - Code scanning (default setup)
3. Apply to all repositories

**Step 3: Create Custom Configuration (Optional)**
1. For stricter requirements, create custom configuration
2. Enable additional settings:
   - Grouped security updates
   - Custom secret scanning patterns
   - Security-extended CodeQL queries
3. Apply to specific repository sets based on sensitivity

#### Code Implementation

{% include pack-code.html vendor="github" section="5.8" %}

#### Validation & Testing
1. [ ] Verify configuration is applied to all repositories
2. [ ] Spot-check individual repositories for expected security features
3. [ ] Verify new repositories automatically receive the configuration

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.1 | Configuration management |
| **NIST 800-53** | CM-6 | Configuration settings |
| **ISO 27001** | A.12.1.1 | Documented operating procedures |
| **CIS Controls** | 4.1 | Secure configuration of enterprise assets |

---

### 7.3 Enable Organization-Level Code Security Configurations

**Profile Level:** L1 (Baseline)
**Requires:** GitHub Enterprise Cloud
**NIST 800-53:** CM-2 (Baseline Configuration), CM-6 (Configuration Settings), SA-11 (Developer Security Testing)

#### Description
Use GitHub code security configurations to define and enforce security feature settings at the organization level. Security configurations allow you to create named policies that enable Dependabot, secret scanning, code scanning, and other security features, then apply them uniformly across repositories. This eliminates configuration drift and ensures new repositories automatically receive the organization's security baseline.

#### Rationale
**Why This Matters:**
- Without centralized configurations, each repository must be individually configured
- Repository admins may disable security features, creating gaps
- New repositories may not receive security features until manually configured
- Code security configurations provide a single pane of glass for security posture management
- Configurations can be enforced so repository admins cannot disable them

#### ClickOps Implementation

**Step 1: Access Security Configurations**
1. Navigate to: **Organization Settings** -> **Code security** -> **Configurations**

**Step 2: Create Custom Configuration**
1. Click **New configuration**
2. Name: `hth-hardened` (or your preferred name)
3. Enable the following features:
   - Dependency graph: Enabled
   - Dependabot alerts: Enabled
   - Dependabot security updates: Enabled
   - Secret scanning: Enabled
   - Push protection: Enabled
   - Code scanning default setup: Enabled
   - Private vulnerability reporting: Enabled
4. Set enforcement level to **Enforced** for critical features

**Step 3: Apply Configuration**
1. Select target repositories (all or specific sets)
2. Apply the configuration
3. Verify all repositories show the correct security posture

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="github" section="3.19" %}

#### Validation & Testing
1. [ ] Verify configuration is applied to all target repositories
2. [ ] Spot-check individual repositories for expected security features
3. [ ] Create a new repository and verify it automatically receives the configuration
4. [ ] Attempt to disable an enforced feature at the repository level (should be blocked)

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.1, CC8.1 | Security monitoring and change management |
| **NIST 800-53** | CM-2, CM-6, SA-11 | Baseline configuration, configuration settings |
| **ISO 27001** | A.12.1.1, A.14.2.1 | Documented procedures, development policy |

---

### 7.4 Configure Repository Custom Properties for Security Classification

**Profile Level:** L2 (Hardened)
**NIST 800-53:** RA-2 (Security Categorization), SC-16 (Transmission of Security Attributes), CM-8 (Information System Component Inventory)

#### Description
Use GitHub repository custom properties to classify repositories by security sensitivity, data classification, compliance requirements, and ownership. Custom properties enable organization-wide tagging of repositories with structured metadata that can drive ruleset targeting, security configuration assignment, and compliance reporting.

#### Rationale
**Why This Matters:**
- Without classification, organizations cannot systematically apply different security policies to repositories of different risk levels
- Custom properties can be used as conditions in repository rulesets (e.g., stricter rules for "critical" repositories)
- Enables automated compliance reporting by querying repositories by classification
- Supports data governance requirements for knowing where sensitive data resides
- Properties are required and can have default values, ensuring no repository is unclassified

#### ClickOps Implementation

**Step 1: Define Custom Properties**
1. Navigate to: **Organization Settings** -> **Custom properties**
2. Click **New property**
3. Create classification properties:
   - `security-tier`: single_select (critical, high, standard, low)
   - `data-classification`: single_select (public, internal, confidential, restricted)
   - `compliance-scope`: multi_select (soc2, pci-dss, hipaa, fedramp, none)
4. Set `security-tier` and `data-classification` as required with defaults

**Step 2: Classify Repositories**
1. Navigate to: **Organization Settings** -> **Repositories**
2. Select repositories to classify
3. Set property values based on repository sensitivity
4. Prioritize classifying repositories with production code and customer data

**Step 3: Use Properties in Rulesets**
1. Navigate to: **Organization Settings** -> **Repository** -> **Rulesets**
2. Create rulesets that target repositories by custom property values
3. Example: Require additional reviewers for `security-tier: critical` repositories

**Time to Complete:** ~30 minutes for setup, ongoing for classification

#### Code Implementation

{% include pack-code.html vendor="github" section="5.10" %}

#### Validation & Testing
1. [ ] Verify custom properties are defined in the organization
2. [ ] Verify critical repositories have correct property values assigned
3. [ ] Verify rulesets correctly target repositories by property values
4. [ ] Confirm new repositories receive default property values

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC3.1, CC6.1 | Risk assessment, logical access |
| **NIST 800-53** | RA-2, SC-16, CM-8 | Security categorization, asset inventory |
| **ISO 27001** | A.8.1.1, A.8.2.1 | Inventory of assets, classification of information |

---

## 8. Third-Party Integration Security

### 8.1 Integration Risk Assessment Matrix

Before allowing any third-party integration access to GitHub, assess risk:

| Risk Factor | Low | Medium | High |
|-------------|-----|--------|------|
| **Repository Access** | Public repos only | Read private repos | Write access to repos |
| **OAuth Scopes** | `read:user`, `public_repo` | `repo:status`, `read:org` | `repo`, `admin:org` |
| **Token Lifetime** | Session-based (hours) | Days | Persistent/no expiration |
| **Vendor Security** | SOC 2 Type II, penetration tested | SOC 2 Type I | No certifications |
| **Data Sensitivity** | Non-production data | Some prod access | Full prod/secrets access |

**Decision Matrix:**
- **0-5 points:** Approve with standard OAuth scope restrictions
- **6-10 points:** Approve with enhanced monitoring + restricted repos
- **11-15 points:** Require security review, minimize scope, or reject

---

### 8.2 Common Integrations and Recommended Controls

#### CircleCI (CI/CD Platform)

**Data Access:** High (needs read/write to repos, access to secrets)

**Recommended Controls:**
- OAuth scope: `repo`, `user:email`, `write:repo_hook` ONLY (not `admin:org`)
- Restrict to specific repositories (not all org repos)
- Use CircleCI OIDC for cloud credentials (not long-lived secrets)
- Enable IP allowlisting if CircleCI provides static IPs
- **Note:** CircleCI was breached in January 2023 - high-risk integration
- Rotate GitHub OAuth tokens quarterly
- Monitor audit logs for bulk repository access

**CircleCI IP Addresses (if available):**
Check CircleCI documentation for current static IPs for webhook allowlisting.

---

#### Snyk (Dependency Scanning)

**Data Access:** Medium (read repos, write security alerts)

**Recommended Controls:**
- OAuth scope: `repo:read`, `security_events:write`
- Use Snyk's GitHub App (scoped permissions) instead of OAuth app
- Enable only for repos with dependencies (not docs/config repos)
- Review Snyk alerts weekly, don't let them accumulate

---

#### Dependabot / Renovate (Dependency Updates)

**Data Access:** Medium-High (read repos, create PRs, update dependencies)

**Recommended Controls:**
- Use GitHub-native Dependabot (preferred, built-in)
- If using Renovate: Scope to `repo` only
- Require PR reviews for Dependabot/Renovate PRs (don't auto-merge)
- Enable branch protection to require status checks before merge
- Review dependency update PRs for unusual changes

---

#### Slack/Microsoft Teams (Notifications)

**Data Access:** Low-Medium (read repos, post notifications)

**Recommended Controls:**
- OAuth scope: `repo:read`, `notifications` (minimal)
- Use GitHub App with narrow repository selection
- Avoid granting write permissions
- Filter notifications to avoid leaking sensitive data in public Slack channels

---

#### SonarQube / SonarCloud (Code Quality)

**Data Access:** Medium (read repos, write code analysis results)

**Recommended Controls:**
- OAuth scope: `repo:read`, `statuses:write`, `checks:write`
- Use SonarCloud GitHub App for scoped permissions
- Review code analysis results before merging
- Ensure SonarQube doesn't store secrets from scanned code

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
| Secret Scanning (public repos) | Yes | Yes | Yes | Yes |
| Secret Scanning (private repos) | No | No | Yes | Yes |
| Code Scanning (public repos) | Yes | Yes | Yes | Yes |
| Code Scanning (private repos) | No | No | Yes | Yes (add-on) |
| GHAS (CodeQL + Secret Scanning) | Public repos | Public repos | Yes | Yes (add-on) |
| Audit Log Streaming | No | No | Yes | Yes |
| Required Workflows | No | No | Yes | Yes |
| Self-Hosted Runner Groups | No | No | Yes | Yes |
| Fine-Grained PAT Policies | Yes | Yes | Yes | Yes |
| Private Vulnerability Reporting | Yes | Yes | Yes | Yes |
| Delegated Bypass (Push Protection) | No | No | Yes | No |
| Artifact Attestations | Yes | Yes | Yes | Yes |
| Code Security Configurations | No | No | Yes | No |
| Custom Properties | No | No | Yes | Yes |

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

**Supply Chain Security Frameworks:**
- [SLSA Framework](https://slsa.dev/)
- [SLSA GitHub Generator](https://github.com/slsa-framework/slsa-github-generator)
- [OpenSSF Supply Chain Integrity WG](https://github.com/ossf/wg-supply-chain-integrity)
- [Achieving SLSA 3 with GitHub Actions](https://github.blog/security/supply-chain-security/slsa-3-compliance-with-github-actions/)

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
| 2026-03-07 | 0.3.0 | draft | Added 7 new controls: fine-grained PAT policies, private vulnerability reporting, secret scanning delegated bypass, artifact attestations, Dependabot grouped updates, code security configurations, repository custom properties | Claude Code (Opus 4.6) |
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
