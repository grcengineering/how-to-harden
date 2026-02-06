---
layout: guide
title: "GitHub Enterprise Hardening Guide"
vendor: "GitHub"
slug: "github-enterprise"
tier: "1"
category: "DevOps & Engineering"
description: "Enterprise hardening for GitHub Enterprise Cloud and Server including organization security, Actions security, and GHAS configuration"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

GitHub Enterprise powers software development for **over 100 million developers** worldwide, with Enterprise deployments managing critical source code, CI/CD pipelines, and secrets for Fortune 500 companies. As the central hub for code and deployments, GitHub Enterprise security directly impacts supply chain integrity. Compromised repositories or pipelines can lead to widespread software supply chain attacks affecting downstream users.

### Intended Audience
- Security engineers managing development platforms
- DevOps administrators configuring GitHub Enterprise
- GRC professionals assessing code repository security
- Platform engineers implementing secure SDLC

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers GitHub Enterprise Cloud and GitHub Enterprise Server security configurations including organization settings, repository security, Actions hardening, and GitHub Advanced Security (GHAS) implementation.

---

## Table of Contents

1. [Enterprise & Organization Security](#1-enterprise--organization-security)
2. [Repository Security](#2-repository-security)
3. [GitHub Actions Security](#3-github-actions-security)
4. [GitHub Advanced Security (GHAS)](#4-github-advanced-security-ghas)
5. [Monitoring & Compliance](#5-monitoring--compliance)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Enterprise & Organization Security

### 1.1 Configure Enterprise SSO and SCIM

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO and SCIM provisioning to centralize identity management for GitHub Enterprise.

#### Rationale
**Why This Matters:**
- Centralized identity management ensures consistent access control
- SCIM enables automatic deprovisioning when employees leave
- SSO enables enforcement of corporate MFA policies

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Enterprise Settings** → **Authentication security**
2. Click **Enable SAML authentication**
3. Configure SAML settings:
   - Sign on URL
   - Issuer
   - Public certificate
4. Configure attribute mappings
5. Test authentication before requiring

**Step 2: Require SAML SSO**
1. After testing, select **Require SAML authentication**
2. Configure recovery codes for break-glass access
3. Document emergency access procedures

**Step 3: Configure SCIM**
1. Navigate to: **Enterprise Settings** → **Authentication security** → **SCIM configuration**
2. Generate SCIM token
3. Configure IdP SCIM provisioning:
   - User provisioning
   - Group synchronization
   - Deprovisioning
4. Test user lifecycle

**Time to Complete:** ~1 hour

---

### 1.2 Configure Enterprise IP Allow List

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17, SC-7 |

#### Description
Restrict enterprise access to approved IP addresses using IP allow lists.

#### ClickOps Implementation

**Step 1: Enable IP Allow List**
1. Navigate to: **Enterprise Settings** → **Authentication security** → **IP allow list**
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

---

### 1.3 Configure Organization Security Policies

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure organization-level security policies for consistent security across all repositories.

#### ClickOps Implementation

**Step 1: Configure Member Privileges**
1. Navigate to: **Organization Settings** → **Member privileges**
2. Configure:
   - **Base permissions:** Set to **No permission** or **Read** (never Admin)
   - **Repository creation:** Restrict to specific roles
   - **Repository forking:** Disable for private repos
   - **Pages creation:** Restrict as needed

**Step 2: Configure Security Policies**
1. Navigate to: **Organization Settings** → **Code security and analysis**
2. Enable **Automatically enable for new repositories**:
   - Dependency graph
   - Dependabot alerts
   - Dependabot security updates
   - Secret scanning
   - Push protection

**Step 3: Require Two-Factor Authentication**
1. Navigate to: **Organization Settings** → **Authentication security**
2. Enable **Require two-factor authentication**
3. Grace period: Allow reasonable time for compliance
4. Monitor compliance status

---

### 1.4 Configure Admin Access Controls

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Implement least privilege for organization and enterprise administrators.

#### Rationale
**Why This Matters:**
- Site admins can promote themselves, create powerful tokens
- Each admin should use passphrase-protected SSH keys
- Limit admin scope to reduce blast radius

#### ClickOps Implementation

**Step 1: Review Enterprise Owners**
1. Navigate to: **Enterprise Settings** → **People** → **Enterprise owners**
2. Limit to 2-3 essential personnel
3. Ensure each owner has MFA enabled
4. Document owner responsibilities

**Step 2: Configure Organization Owner Policies**
1. Review organization owners across all orgs
2. Limit to essential personnel per org
3. Create separate admin accounts for privileged operations

**Step 3: Audit Admin Activity**
1. Regular review of admin audit logs
2. Alert on privilege escalation
3. Document admin changes

**For GitHub Enterprise Server:**
- Management Console admins have shell access
- Use passphrase-protected SSH keys per admin
- Restrict Management Console to bastion host access

---

## 2. Repository Security

### 2.1 Configure Branch Protection Rules

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.9 |
| NIST 800-53 | CM-3, SI-7 |

#### Description
Configure branch protection rules to enforce code review and prevent unauthorized changes.

#### Rationale
**Why This Matters:**
- Prevents direct pushes to production branches
- Enforces peer review before merge
- Protects against compromised developer accounts

#### ClickOps Implementation

**Step 1: Create Branch Protection Rule**
1. Navigate to: **Repository Settings** → **Branches**
2. Click **Add branch protection rule**
3. Branch name pattern: `main` (or default branch)

**Step 2: Configure Protection Settings**
1. Enable **Require a pull request before merging**:
   - Required approving reviews: 2+ for L2
   - Dismiss stale reviews
   - Require review from code owners
   - Require approval of most recent push
2. Enable **Require status checks to pass**:
   - Require branches to be up to date
   - Add required status checks (tests, linting, security scans)
3. Enable **Require conversation resolution**
4. Enable **Require signed commits** (L2)
5. Enable **Require linear history** (optional)
6. Enable **Do not allow bypassing the above settings** (L3)

**Step 3: Configure for Release Branches**
1. Create rules for release branches: `release/*`
2. Apply similar or stricter protections

---

### 2.2 Configure Repository Rulesets (Enterprise)

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.9 |
| NIST 800-53 | CM-3 |

#### Description
Configure organization-wide repository rulesets to enforce consistent branch protection across all repositories.

#### ClickOps Implementation

**Step 1: Create Organization Ruleset**
1. Navigate to: **Organization Settings** → **Repository** → **Rulesets**
2. Click **New ruleset** → **New branch ruleset**

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
2. Configure bypass list (limit to emergency access)

---

### 2.3 Enforce Commit Signing

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.9 |
| NIST 800-53 | SI-7 |

#### Description
Require cryptographically signed commits to verify commit authenticity and prevent tampering.

#### ClickOps Implementation

**Step 1: Configure Vigilant Mode**
1. Navigate to: **User Settings** → **SSH and GPG keys**
2. Enable **Flag unsigned commits as unverified**

**Step 2: Require Signed Commits in Branch Protection**
1. Navigate to: **Repository Settings** → **Branches** → Edit rule
2. Enable **Require signed commits**

**Supported Signing Methods:**
- GPG keys
- SSH keys (recommended for ease of use)
- S/MIME certificates

---

## 3. GitHub Actions Security

### 3.1 Restrict Actions Permissions

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.1 |
| NIST 800-53 | CM-7 |

#### Description
Configure GitHub Actions policies to restrict which actions can run and with what permissions.

#### Rationale
**Why This Matters:**
- Actions have access to source code, secrets, and production systems
- Untrusted actions can exfiltrate secrets or inject malicious code
- Misconfigured workflows can compromise entire build environment

#### ClickOps Implementation

**Step 1: Configure Enterprise Actions Policies**
1. Navigate to: **Enterprise Settings** → **Policies** → **Actions**
2. Configure allowed actions:
   - **Allow enterprise and select non-enterprise actions** (recommended)
   - Specify allowed patterns: `github/*`, `actions/*`
3. Restrict to verified creators if possible

**Step 2: Configure Organization Actions Policies**
1. Navigate to: **Organization Settings** → **Actions** → **General**
2. Configure:
   - **Actions permissions:** Allow select actions
   - **Fork pull request workflows:** Require approval
   - **Workflow permissions:** Read repository contents (not write)

**Step 3: Configure GITHUB_TOKEN Permissions**
1. Navigate to: **Repository Settings** → **Actions** → **General**
2. Set **Workflow permissions** to **Read repository contents**
3. Disable **Allow GitHub Actions to create and approve pull requests**

---

### 3.2 Secure Actions Secrets

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Securely manage secrets used in GitHub Actions workflows.

#### ClickOps Implementation

**Step 1: Configure Organization Secrets**
1. Navigate to: **Organization Settings** → **Secrets and variables** → **Actions**
2. Create secrets at organization level for shared credentials
3. Restrict repository access to minimum necessary

**Step 2: Configure Environment Secrets**
1. Navigate to: **Repository Settings** → **Environments**
2. Create environments: `staging`, `production`
3. Configure environment protection rules:
   - Required reviewers for production
   - Wait timer
   - Deployment branches: protected branches only
4. Add secrets at environment level (most secure)

**Step 3: Audit Secret Usage**
1. Review workflows accessing secrets
2. Remove unused secrets
3. Rotate secrets regularly

---

### 3.3 Pin Actions to Commit SHAs

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.1 |
| NIST 800-53 | SI-7 |

#### Description
Pin third-party actions to full commit SHAs instead of tags to prevent supply chain attacks.

#### Rationale
**Why This Matters:**
- Tags can be moved to point to different commits
- A bad actor can add a backdoor and move a tag
- SHA pinning creates an immutable reference

#### Code Implementation

```yaml
# RECOMMENDED: Pin to full commit SHA
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1

# NOT RECOMMENDED: Using tags (mutable)
- uses: actions/checkout@v4
```

**Step 1: Identify Current Actions**
1. Search repository for workflow files
2. List all action references
3. Identify those using tags

**Step 2: Convert to SHA Pinning**
1. Find current SHA for each action version
2. Replace tag with full SHA
3. Add comment with version for reference

**Step 3: Automate SHA Updates**
1. Use Dependabot for automated updates:
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

---

### 3.4 Configure Self-Hosted Runner Security

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Secure self-hosted runners to prevent compromise of build environment.

#### ClickOps Implementation

**Step 1: Isolate Runners**
1. Use ephemeral runners (new VM per job)
2. Never run on controller/sensitive systems
3. Use dedicated runner network segment

**Step 2: Restrict Repository Access**
1. Navigate to: **Organization Settings** → **Actions** → **Runner groups**
2. Create runner groups for different trust levels
3. Restrict which repositories can use each group

**Step 3: Configure Runner Labels**
1. Use labels to route jobs to appropriate runners
2. Production deployments: dedicated secure runners
3. Public fork builds: isolated runners with no secrets

---

## 4. GitHub Advanced Security (GHAS)

### 4.1 Enable Secret Scanning with Push Protection

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.4 |
| NIST 800-53 | IA-5 |

#### Description
Enable secret scanning to detect and prevent committed secrets.

#### ClickOps Implementation

**Step 1: Enable at Organization Level**
1. Navigate to: **Organization Settings** → **Code security and analysis**
2. Enable **Secret scanning**
3. Enable **Push protection**
4. Configure for all repositories

**Step 2: Configure Custom Patterns (Enterprise)**
1. Navigate to: **Organization Settings** → **Code security** → **Secret scanning**
2. Add custom patterns for:
   - Internal API keys
   - Database connection strings
   - Custom tokens

**Step 3: Configure Alerts**
1. Configure alert notifications
2. Define escalation procedures
3. Set SLA for secret rotation

---

### 4.2 Enable Dependabot Security Updates

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 7.4 |
| NIST 800-53 | SI-2 |

#### Description
Enable Dependabot for automated vulnerability detection and patching.

#### ClickOps Implementation

**Step 1: Enable Dependabot**
1. Navigate to: **Organization Settings** → **Code security and analysis**
2. Enable:
   - **Dependency graph**
   - **Dependabot alerts**
   - **Dependabot security updates**
   - **Grouped security updates** (recommended)

**Step 2: Configure Dependabot**
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "daily"
    open-pull-requests-limit: 10
    groups:
      development-dependencies:
        dependency-type: "development"
      production-dependencies:
        dependency-type: "production"
```

---

### 4.3 Enable Code Scanning (CodeQL)

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.12 |
| NIST 800-53 | SA-11 |

#### Description
Enable CodeQL code scanning to identify security vulnerabilities in source code.

#### ClickOps Implementation

**Step 1: Enable Default Setup**
1. Navigate to: **Repository Settings** → **Code security and analysis**
2. Click **Set up** next to Code scanning
3. Select **Default** for automatic configuration

**Step 2: Configure Custom Setup (Advanced)**
```yaml
# .github/workflows/codeql-analysis.yml
name: "CodeQL"
on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]
  schedule:
    - cron: '0 0 * * 1'

jobs:
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      security-events: write

    strategy:
      fail-fast: false
      matrix:
        language: [ 'javascript', 'python' ]

    steps:
    - name: Checkout repository
      uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11

    - name: Initialize CodeQL
      uses: github/codeql-action/init@v3
      with:
        languages: ${{ matrix.language }}
        queries: security-extended

    - name: Autobuild
      uses: github/codeql-action/autobuild@v3

    - name: Perform CodeQL Analysis
      uses: github/codeql-action/analyze@v3
```

---

## 5. Monitoring & Compliance

### 5.1 Configure Audit Log Streaming

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-6 |

#### Description
Configure audit log streaming to SIEM for security monitoring and compliance.

#### ClickOps Implementation

**Step 1: Enable Audit Log Streaming**
1. Navigate to: **Enterprise Settings** → **Audit log** → **Log streaming**
2. Configure stream destination:
   - Amazon S3
   - Azure Blob Storage
   - Azure Event Hubs
   - Datadog
   - Google Cloud Storage
   - Splunk

**Step 2: Configure Stream Settings**
1. Enable **Git events** for repository activity
2. Select event categories to stream
3. Verify connection

**Key Events to Monitor:**
- `org.add_member`, `org.remove_member`
- `repo.create`, `repo.destroy`
- `protected_branch.create`, `protected_branch.destroy`
- `oauth_authorization.create`
- `personal_access_token.create`

---

### 5.2 Apply GitHub-Recommended Security Configuration

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Apply GitHub's recommended security configuration to all repositories in the enterprise.

#### ClickOps Implementation

**Step 1: Access Security Configurations**
1. Navigate to: **Enterprise Settings** → **Code security** → **Configurations**

**Step 2: Apply GitHub Recommended**
1. Select **GitHub recommended** configuration
2. Review included settings:
   - Dependency graph
   - Dependabot alerts and security updates
   - Secret scanning and push protection
   - Code scanning (default setup)
3. Apply to all repositories

**Step 3: Create Custom Configuration**
1. For stricter requirements, create custom configuration
2. Enable additional settings as needed
3. Apply to specific repository sets

---

## 6. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | GitHub Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-enterprise-sso-and-scim) |
| CC6.2 | Admin access control | [1.4](#14-configure-admin-access-controls) |
| CC6.6 | IP allow list | [1.2](#12-configure-enterprise-ip-allow-list) |
| CC7.1 | Branch protection | [2.1](#21-configure-branch-protection-rules) |
| CC7.2 | Audit logging | [5.1](#51-configure-audit-log-streaming) |
| CC8.1 | Signed commits | [2.3](#23-enforce-commit-signing) |

### NIST 800-53 Rev 5 Mapping

| Control | GitHub Control | Guide Section |
|---------|----------------|---------------|
| IA-2 | SSO/MFA | [1.1](#11-configure-enterprise-sso-and-scim) |
| AC-6(1) | Least privilege | [1.4](#14-configure-admin-access-controls) |
| CM-3 | Branch protection | [2.1](#21-configure-branch-protection-rules) |
| SI-7 | Code integrity | [2.3](#23-enforce-commit-signing) |
| SA-11 | Security testing | [4.3](#43-enable-code-scanning-codeql) |
| AU-2 | Audit logging | [5.1](#51-configure-audit-log-streaming) |

---

## Appendix A: Edition Compatibility

| Feature | GitHub Free | GitHub Team | GitHub Enterprise Cloud | GitHub Enterprise Server |
|---------|-------------|-------------|------------------------|-------------------------|
| Branch protection | Basic | ✅ | ✅ | ✅ |
| Repository rulesets | ❌ | ❌ | ✅ | ✅ |
| SAML SSO | ❌ | ❌ | ✅ | ✅ |
| IP allow list | ❌ | ❌ | ✅ | ✅ |
| Audit log streaming | ❌ | ❌ | ✅ | ✅ |
| GHAS (CodeQL, Secret scanning) | Public repos | Public repos | ✅ | ✅ (add-on) |
| SCIM provisioning | ❌ | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official GitHub Documentation:**
- [Hardening Security for Your Enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/configuring-settings/hardening-security-for-your-enterprise)
- [Configuring SAML SSO for Enterprise Managed Users](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/configuring-authentication-for-enterprise-managed-users/configuring-saml-single-sign-on-for-enterprise-managed-users)
- [Configuring SAML SSO for Your Enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/using-saml-for-enterprise-iam/configuring-saml-single-sign-on-for-your-enterprise)
- [SAML Configuration Reference](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/iam-configuration-reference/saml-configuration-reference)
- [Security Hardening for GitHub Actions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions)
- [GitHub Advanced Security](https://docs.github.com/en/get-started/learning-about-github/about-github-advanced-security)

**Community Resources:**
- [GitHub Hardening Guide](https://github.com/iAnonymous3000/GitHub-Hardening-Guide)
- [CIS GitHub Benchmark](https://www.cisecurity.org/benchmark/software_supply_chain_security)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with enterprise security, Actions hardening, and GHAS | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
