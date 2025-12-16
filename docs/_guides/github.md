---
layout: guide
title: "GitHub Hardening Guide"
vendor: "GitHub"
slug: "github"
tier: "1"
category: "Developer Tools"
description: "Source control and CI/CD security hardening for GitHub organizations, Actions, and supply chain protection"
last_updated: "2025-12-13"
---


**Version:** 1.0
**Last Updated:** 2025-12-13
**GitHub Editions Covered:** GitHub.com (Free, Team, Enterprise Cloud), GitHub Enterprise Server
**Authors:** How to Harden Community

---

## Overview

This guide provides comprehensive security hardening recommendations for GitHub, organized by control category. GitHub is a critical part of the software supply chain—compromises can lead to malicious code injection, secret theft, and downstream customer breaches.

### Intended Audience
- Security engineers managing GitHub organizations
- DevOps/Platform engineers configuring CI/CD pipelines
- Application security teams governing third-party Actions
- Open source maintainers protecting projects

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for organizations building customer-facing software
- **L3 (Maximum Security):** Strictest controls for highly regulated or high-risk targets

### Scope
This guide covers GitHub.com and GitHub Enterprise Cloud/Server security configurations. For self-hosted runner infrastructure hardening (Kubernetes, VMs), refer to CIS Benchmarks for those platforms.

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
7. [Monitoring & Audit Logging](#7-monitoring--audit-logging)
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
- [ ] GitHub organization owner/admin access
- [ ] Member communication plan (give 30-day notice before enforcement)

#### ClickOps Implementation

**Step 1: Enable MFA Requirement**
1. Navigate to: **Organization Settings** → **Authentication security**
2. Under "Two-factor authentication":
   - Select **"Require two-factor authentication for everyone in the [org-name] organization"**
3. Set grace period (recommended: 30 days)
4. Click **"Save"**

**Step 2: Monitor Compliance**
1. Go to: **Organization Settings** → **People**
2. Filter by "2FA" status to see non-compliant members
3. Members without 2FA will be removed from org after grace period

**Time to Complete:** ~5 minutes + 30-day rollout

#### Code Implementation

**Option 1: GitHub CLI**
```bash
# Check current 2FA enforcement status
gh api /orgs/{org}/settings --jq '.two_factor_requirement_enabled'

# Enable 2FA requirement (requires owner permissions)
gh api -X PATCH /orgs/{org} \
  -f two_factor_requirement_enabled=true

# List members without 2FA
gh api /orgs/{org}/members?filter=2fa_disabled --jq '.[].login'
```

**Option 2: GitHub API**
```bash
ORG="your-org-name"
TOKEN="your_github_token"

# Enable 2FA requirement
curl -X PATCH "https://api.github.com/orgs/${ORG}" \
  -H "Authorization: token ${TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  -d '{
    "two_factor_requirement_enabled": true
  }'

# Audit members without 2FA
curl -X GET "https://api.github.com/orgs/${ORG}/members?filter=2fa_disabled" \
  -H "Authorization: token ${TOKEN}" \
  -H "Accept: application/vnd.github+json"
```

**Option 3: Terraform**
```hcl
# terraform/github/org-settings.tf

resource "github_organization_settings" "main" {
  billing_email = "billing@example.com"

  # Require 2FA for all members
  two_factor_requirement = true

  # Additional hardening
  members_can_create_repositories = false
  members_can_create_public_repositories = false
}
```

#### Validation & Testing
1. [ ] Create test user account, add to organization
2. [ ] Verify test user is prompted to enable 2FA
3. [ ] Confirm user cannot access org resources without 2FA setup
4. [ ] After grace period, verify non-compliant users are removed

**Expected result:** All org members have 2FA enabled or are automatically removed.

#### Monitoring & Maintenance

**Alert Configuration:**
```bash
# Daily check for non-compliant members
gh api /orgs/{org}/members?filter=2fa_disabled --jq 'length'
# Expected: 0
# If > 0, alert security team
```

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
1. Organization Settings → Authentication security
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
1. **Organization Settings** → **Member privileges**
2. Under "Base permissions":
   - Set to **"No permission"** (recommended) or **"Read"**
   - NOT "Write" or "Admin"
3. Click **"Save"**

**Step 2: Use Teams for Access**
1. Create teams for projects/repos
2. Grant teams specific repository access
3. Add members to relevant teams only

#### Code Implementation

```bash
# Set base permissions to none
gh api -X PATCH /orgs/{org} \
  -f default_repository_permission=none

# Verify
gh api /orgs/{org} --jq '.default_repository_permission'
# Expected: "none"
```

#### Compliance Mappings
- **SOC 2:** CC6.2 (Least privilege)
- **NIST 800-53:** AC-6

---

### 1.3 Enable SAML Single Sign-On (SSO) for Centralized Identity

**Profile Level:** L2 (Hardened)
**Requires:** GitHub Enterprise Cloud
**NIST 800-53:** IA-2, IA-4

#### Description
Integrate GitHub with your corporate identity provider (Okta, Azure AD, Google Workspace) via SAML SSO. This centralizes authentication and enables conditional access policies.

#### Rationale
**Centralized Control:** If employee leaves company, disable their IdP account and they immediately lose GitHub access.

**Conditional Access:** Enforce device compliance, location-based access, session timeouts via IdP.

#### ClickOps Implementation

1. **Organization Settings** → **Authentication security** → **Enable SAML authentication**
2. Configure IdP connection (Okta/Azure AD/Google)
3. Test with pilot users
4. Enforce SAML SSO (blocks non-SSO logins)

**Time to Complete:** ~30 minutes

#### Code Implementation

```bash
# Enable SAML SSO (requires Enterprise Cloud)
# Configuration done via GitHub web UI + IdP
# API can verify status:

gh api /orgs/{org} --jq '.saml_identity_provider'
```

#### Additional Hardening

After SAML SSO is enabled:
- Enable **"Require SAML SSO authentication for all members"**
- Configure **session timeout** in IdP (recommend: 8 hours max)
- Enable **device trust** if IdP supports (require managed devices)

#### Compliance Mappings
- **SOC 2:** CC6.1 (Identity and access management)
- **NIST 800-53:** IA-2, IA-4
- **ISO 27001:** A.9.2.1

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
1. Navigate to: **Repository** → **Settings** → **Branches**
2. Under "Branch protection rules", click **"Add rule"**
3. Branch name pattern: `main` (or `master`, `production`)
4. Enable these protections:
   - ☑ **Require a pull request before merging**
     - ☑ Require approvals (minimum: 1 for L1, 2 for L2)
     - ☑ Dismiss stale pull request approvals when new commits are pushed
   - ☑ **Require status checks to pass before merging**
     - Select required checks (tests, security scans)
     - ☑ Require branches to be up to date before merging
   - ☑ **Require conversation resolution before merging**
   - ☑ **Do not allow bypassing the above settings** (critical!)
   - ☑ **Restrict who can push to matching branches** (optional: restrict to CI bot only)
5. Click **"Create"**

**Repeat for all critical branches.**

**Time to Complete:** ~10 minutes per repository

#### Code Implementation

**Option 1: GitHub CLI**
```bash
REPO="org/repo-name"
BRANCH="main"

# Create branch protection rule
gh api -X PUT "/repos/${REPO}/branches/${BRANCH}/protection" \
  -H "Accept: application/vnd.github+json" \
  -f required_status_checks='{"strict":true,"contexts":["ci/test","security/scan"]}' \
  -f enforce_admins=true \
  -f required_pull_request_reviews='{"dismissal_restrictions":{},"dismiss_stale_reviews":true,"require_code_owner_reviews":true,"required_approving_review_count":2}' \
  -f restrictions=null
```

**Option 2: Terraform**
```hcl
# terraform/github/branch-protection.tf

resource "github_branch_protection" "main" {
  repository_id = github_repository.repo.node_id
  pattern       = "main"

  required_status_checks {
    strict   = true  # Require branch to be up to date
    contexts = ["ci/test", "security/scan"]
  }

  required_pull_request_reviews {
    dismiss_stale_reviews      = true
    require_code_owner_reviews = true
    required_approving_review_count = 2
  }

  enforce_admins = true  # No admin bypass

  require_conversation_resolution = true
}
```

**Option 3: Bulk Protection Script**
```python
#!/usr/bin/env python3
# automation/scripts/github/protect-all-branches.py

from github import Github
import os

g = Github(os.environ['GITHUB_TOKEN'])
org = g.get_organization('your-org')

PROTECTED_BRANCHES = ['main', 'master', 'production', 'release']

for repo in org.get_repos():
    print(f"Processing: {repo.name}")

    for branch_name in PROTECTED_BRANCHES:
        try:
            branch = repo.get_branch(branch_name)

            # Apply protection
            branch.edit_protection(
                strict=True,
                contexts=["ci/test"],
                enforce_admins=True,
                dismiss_stale_reviews=True,
                require_code_owner_reviews=True,
                required_approving_review_count=1
            )

            print(f"  ✓ Protected: {branch_name}")
        except Exception as e:
            print(f"  ⊙ Skipped {branch_name}: {e}")
```

#### Validation & Testing
1. [ ] Attempt to push directly to protected branch (should fail)
2. [ ] Create PR without required status checks (should block merge)
3. [ ] Create PR without required approvals (should block merge)
4. [ ] Verify admin cannot bypass (if enforce_admins enabled)

#### Monitoring & Maintenance

**Alert on protection changes:**
```sql
-- If using audit log analysis
SELECT * FROM github_audit_log
WHERE action = 'protected_branch.policy_override'
   OR action = 'protected_branch.destroy'
```

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
1. **Organization Settings** → **Code security and analysis**
2. Enable for all repositories:
   - ☑ **Dependency graph** (free)
   - ☑ **Dependabot alerts** (free)
   - ☑ **Dependabot security updates** (free)
   - ☑ **Secret scanning** (free for public repos, requires Advanced Security for private)
   - ☑ **Code scanning** (requires Actions, free for public repos)

**Step 2: Configure Per-Repository (if needed)**
1. Navigate to: **Repository** → **Settings** → **Code security and analysis**
2. Enable same features
3. For **Code scanning**, click "Set up" → Choose "CodeQL Analysis" workflow

**Time to Complete:** ~15 minutes

#### Code Implementation

**Enable via API:**
```bash
ORG="your-org"
TOKEN="your_github_token"

# Enable Dependabot alerts for all repos
for repo in $(gh repo list $ORG --json name --jq '.[].name'); do
  gh api -X PUT "/repos/${ORG}/${repo}/vulnerability-alerts"
  echo "✓ Enabled Dependabot for ${repo}"
done

# Enable secret scanning (requires Advanced Security)
for repo in $(gh repo list $ORG --json name --jq '.[].name'); do
  gh api -X PUT "/repos/${ORG}/${repo}/secret-scanning/alerts"
  echo "✓ Enabled Secret Scanning for ${repo}"
done
```

**Terraform:**
```hcl
resource "github_repository" "repo" {
  name = "my-repo"

  # Security features
  vulnerability_alerts = true  # Dependabot

  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"  # Block pushes with secrets
    }
  }
}
```

#### Secret Scanning Push Protection

**L2 Enhancement:** Enable push protection to **block commits** containing secrets:

```bash
# Enable push protection
gh api -X PUT "/repos/${ORG}/${REPO}/secret-scanning/push-protection"
```

This prevents secrets from ever entering Git history (better than post-commit detection).

#### Monitoring Alerts

**Dependabot Alerts:**
```bash
# List critical/high severity alerts
gh api /orgs/{org}/dependabot/alerts --jq '.[] | select(.severity == "critical" or .severity == "high") | {repo: .repository.name, package: .security_advisory.package.name, severity: .severity}'
```

**Secret Scanning Alerts:**
```bash
# List active secret alerts
gh api /orgs/{org}/secret-scanning/alerts?state=open --jq '.[] | {repo: .repository.name, secret_type: .secret_type, created_at: .created_at}'
```

#### Compliance Mappings
- **SOC 2:** CC7.2 (System monitoring)
- **NIST 800-53:** RA-5 (Vulnerability scanning)
- **ISO 27001:** A.12.6.1 (Technical vulnerability management)

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

**Step 1: Set Organization Action Policy**
1. **Organization Settings** → **Actions** → **General**
2. Under "Actions permissions":
   - Select **"Allow [org-name], and select non-[org-name], actions and reusable workflows"**
3. Under "Allow specified actions and reusable workflows":
   - ☑ **Allow actions created by GitHub** (GitHub-verified)
   - ☑ **Allow actions by Marketplace verified creators**
   - Add specific allow-listed actions:
     ```
     actions/*,
     github/*,
     docker/*,
     aws-actions/*,
     hashicorp/*
     ```
4. Click **"Save"**

**Time to Complete:** ~5 minutes

#### Code Implementation

```bash
# Set organization actions policy
gh api -X PUT /orgs/{org}/actions/permissions \
  -f enabled_repositories=all \
  -f allowed_actions=selected

# Configure allowed actions
gh api -X PUT /orgs/{org}/actions/permissions/selected-actions \
  -f github_owned_allowed=true \
  -f verified_allowed=true \
  -f patterns_allowed='["actions/*","github/*","docker/*","aws-actions/*","hashicorp/*"]'
```

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

**Bad:**
```yaml
- uses: actions/checkout@v3  # Tag can be repointed
```

**Good:**
```yaml
- uses: actions/checkout@f43a0e5ff2bd294095638e18286ca9a3d1956744  # SHA
```

**Automation to pin SHAs:**
```bash
# Use https://github.com/mheap/pin-github-action
npx pin-github-action .github/workflows/*.yml
```

#### Monitoring & Maintenance

**Alert on unapproved Action usage:**
```bash
# Scan all workflows for non-allowed actions
for repo in $(gh repo list $ORG --json name --jq '.[].name'); do
  gh api "/repos/${ORG}/${repo}/actions/workflows" --jq '.workflows[].path' | while read workflow; do
    gh api "/repos/${ORG}/${repo}/contents/${workflow}" --jq '.content' | base64 -d | grep -oP 'uses:\s+\K[^\s]+' | grep -v '^actions/' | grep -v '^github/'
  done
done
```

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
1. **Organization Settings** → **Actions** → **General**
2. Under "Workflow permissions":
   - Select **"Read repository contents and packages permissions"** (read-only)
   - ☐ Do NOT check "Allow GitHub Actions to create and approve pull requests"
3. Click **"Save"**

**Step 2: Per-Workflow Explicit Permissions**

In each workflow file, explicitly declare required permissions:

```yaml
# .github/workflows/ci.yml

name: CI

on: [push, pull_request]

permissions:
  contents: read       # Read code
  pull-requests: write # Comment on PRs (if needed)
  # Omit permissions not needed

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@f43a0e5ff2bd294095638e18286ca9a3d1956744
      - run: npm test
```

**Time to Complete:** ~5 minutes org-wide + per-workflow updates

#### Code Implementation

```bash
# Set organization default to read-only
gh api -X PUT /orgs/{org}/actions/permissions/workflow \
  -f default_workflow_permissions=read \
  -f can_approve_pull_request_reviews=false
```

#### Common Permission Combinations

**Read-Only (Most Workflows):**
```yaml
permissions:
  contents: read
```

**Build & Test with PR Comments:**
```yaml
permissions:
  contents: read
  pull-requests: write
  statuses: write
```

**Release/Publish:**
```yaml
permissions:
  contents: write      # Create releases
  packages: write      # Publish to GitHub Packages
  id-token: write      # OIDC token for signing
```

**Security Scanning:**
```yaml
permissions:
  contents: read
  security-events: write  # Upload SARIF results
```

#### Monitoring

**Audit workflows with excessive permissions:**
```bash
# Find workflows with 'write-all' or missing permissions
find .github/workflows -name "*.yml" -exec grep -L "permissions:" {} \;
```

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
**Attack:** Attacker forks your public repo, modifies workflow to exfiltrate secrets, opens PR. Workflow runs automatically and steals `${{ secrets }}`.

**Prevention:** Require maintainer to review and approve workflow runs from new contributors.

#### ClickOps Implementation

1. **Repository Settings** → **Actions** → **General**
2. Under "Fork pull request workflows from outside collaborators":
   - Select **"Require approval for first-time contributors"** (L2)
   - Or **"Require approval for all outside collaborators"** (L3)
3. Save

#### Code Implementation

```bash
# This setting is per-repository, configured via UI
# Can be enforced via organization policy requiring repos to enable it
```

#### Compliance Mappings
- **SLSA:** Build L2 (Source code integrity)
- **SOC 2:** CC6.1 (Logical access)

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
1. **Organization Settings** → **OAuth Apps** (or **GitHub Apps**)
2. Review each app:
   - When was it last used?
   - What permissions does it have?
   - Is it still needed?
3. Click app → "Review" → Check granted permissions

**Step 2: Revoke Unnecessary Apps**
- Click "Revoke" for unused apps
- For remaining apps, click "Restrict access" to limit to specific repositories

**Step 3: Restrict New App Installation**
1. **Organization Settings** → **OAuth application policy**
2. Select **"Restrict installation of OAuth Apps"**
3. Require admin approval for new app installations

**Time to Complete:** ~30 minutes for initial audit

#### Code Implementation

**List OAuth apps:**
```bash
# List org authorized OAuth apps
gh api /orgs/{org}/applications --jq '.[] | {name: .name, created_at: .created_at, url: .url}'

# List personal OAuth authorizations (run as each user)
gh api /user/applications --jq '.[] | {name: .name, scopes: .scopes}'
```

**Automation script:**
```python
#!/usr/bin/env python3
# automation/scripts/github/audit-oauth-apps.py

from github import Github
import os

g = Github(os.environ['GITHUB_TOKEN'])
org = g.get_organization('your-org')

print("Authorized OAuth Apps:")
print("=" * 60)

# Note: GitHub API doesn't provide full OAuth app list
# This must be done via UI or GraphQL API
# Placeholder for manual review tracking

apps = [
    {"name": "CircleCI", "last_used": "2025-12-01", "keep": True},
    {"name": "Old-CI-Tool", "last_used": "2023-06-15", "keep": False},
]

for app in apps:
    status = "✓ Keep" if app["keep"] else "✗ Revoke"
    print(f"{status}: {app['name']} (last used: {app['last_used']})")
```

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
Store sensitive credentials in GitHub Actions secrets (not hardcoded in code). Use environment protection rules to require approval for production secret access.

#### Rationale
**Attack Prevention:**
- Secrets in code → exposed in Git history forever
- Secrets in logs → leaked via CI/CD output
- Secrets in unprotected workflows → stolen via malicious PR

**Environment Protection:** Require manual approval before workflows can access production secrets.

#### ClickOps Implementation

**Step 1: Store Secrets**
1. **Repository Settings** → **Secrets and variables** → **Actions**
2. Click "New repository secret"
3. Name: `PROD_API_KEY` (use descriptive names)
4. Value: [paste secret]
5. Click "Add secret"

**For organization-wide secrets:**
- **Organization Settings** → **Secrets and variables** → **Actions** → "New organization secret"

**Step 2: Create Environment with Protection**
1. **Repository Settings** → **Environments**
2. Click "New environment", name it `production`
3. Configure protection rules:
   - ☑ **Required reviewers** (add team/users who must approve)
   - ☑ **Wait timer** (optional: delay before deployment)
   - ☑ **Deployment branches** (only `main` can deploy to production)
4. Add environment-specific secrets to this environment

**Step 3: Reference Secrets in Workflow**
```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production  # Requires approval to run
    steps:
      - uses: actions/checkout@f43a0e5ff2bd294095638e18286ca9a3d1956744
      - name: Deploy
        env:
          API_KEY: ${{ secrets.PROD_API_KEY }}
        run: |
          # Secret is available in $API_KEY env var
          # NOT visible in logs
          deploy.sh
```

**Time to Complete:** ~15 minutes

#### Code Implementation

**Create environment via API:**
```bash
REPO="org/repo"

# Create environment
gh api -X PUT "/repos/${REPO}/environments/production" \
  -f prevent_self_review=true \
  -f reviewers='[{"type":"Team","id":12345}]' \
  -f deployment_branch_policy='{"protected_branches":true,"custom_branch_policies":false}'

# Add secret to environment
gh secret set PROD_API_KEY --env production --body "secret-value"
```

#### Best Practices

**Secret Rotation:**
- Rotate secrets quarterly (minimum)
- Use short-lived credentials where possible (OIDC tokens)
- Track secret age:
  ```bash
  gh secret list --json name,updatedAt
  ```

**Secret Sprawl Prevention:**
- Use organization secrets for widely-used credentials
- Limit repository-specific secrets
- Document what each secret is for

**Never Do:**
- ❌ Echo secrets in workflow logs: `echo ${{ secrets.API_KEY }}`
- ❌ Write secrets to files that get uploaded as artifacts
- ❌ Pass secrets in URLs: `curl https://api.example.com?key=${{ secrets.API_KEY }}`

#### Monitoring

**Alert on secret access:**
```bash
# Check audit log for secret access
gh api /orgs/{org}/audit-log?phrase=secrets.read
```

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

**Step 2: Create IAM Role**
2. Create IAM role with trust policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:your-org/your-repo:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

**Step 3: Use in Workflow**
```yaml
name: Deploy to AWS

on:
  push:
    branches: [main]

permissions:
  id-token: write  # Required for OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@f43a0e5ff2bd294095638e18286ca9a3d1956744

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@010d0da01d0b5a38af31e9c3470dbfdabdecca3a
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsRole
          aws-region: us-east-1
          # No long-lived credentials needed!

      - name: Deploy
        run: |
          aws s3 sync ./build s3://my-bucket/
```

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
1. **Repository Settings** → **Code security and analysis**
2. Enable **Dependency graph** (should already be enabled from Section 2.2)

**Step 2: Add Dependency Review Action**
Create `.github/workflows/dependency-review.yml`:

```yaml
name: Dependency Review

on: [pull_request]

permissions:
  contents: read
  pull-requests: write

jobs:
  dependency-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@f43a0e5ff2bd294095638e18286ca9a3d1956744

      - name: Dependency Review
        uses: actions/dependency-review-action@c74b580d73376b7750d3d2a50bfb8adc2c937507
        with:
          fail-on-severity: moderate  # Block moderate+ vulnerabilities
          deny-licenses: GPL-2.0, GPL-3.0  # Optional: block incompatible licenses
```

**Time to Complete:** ~10 minutes

#### Code Implementation

Automated via workflow (see above). Can also use CLI:

```bash
# Manual dependency review
gh api /repos/{owner}/{repo}/dependency-graph/compare/main...feature-branch
```

#### Monitoring

**Track introduced vulnerabilities:**
```bash
# Check PR for new vulnerabilities
gh pr view 123 --json reviews
```

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

**npm (package-lock.json):**
```bash
# Commit package-lock.json (contains hashes)
git add package-lock.json

# Verify integrity on install
npm ci --audit
```

**Python (requirements.txt with hashes):**
```bash
# Generate requirements with hashes
pip-compile --generate-hashes requirements.in > requirements.txt

# Install with verification
pip install --require-hashes -r requirements.txt
```

**Go (go.sum):**
```bash
# go.sum contains hashes automatically
go mod verify
```

**Docker (digest pinning):**
```dockerfile
# Bad: tag can change
FROM node:18

# Good: digest is immutable
FROM node:18@sha256:a1b2c3d4...
```

#### Automated Pinning

Use Dependabot or Renovate to keep pins up-to-date while maintaining hash verification.

#### Compliance Mappings
- **SLSA:** Build L3 (Hermetic builds)
- **NIST 800-53:** SA-12

---

## 7. Monitoring & Audit Logging

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

1. **Organization Settings** → **Audit log** → **Log streaming**
2. Click "Configure stream"
3. Choose destination:
   - **Splunk** (HTTP Event Collector)
   - **Azure Event Hubs**
   - **AWS S3** (via partner integration)
   - **Datadog** (via partner integration)
4. Configure endpoint details
5. Test connection
6. Enable stream

**Time to Complete:** ~30 minutes

#### Code Implementation

```bash
# Enable audit log streaming via API (Enterprise Cloud)
gh api -X POST /orgs/{org}/audit-log/streams \
  -f destination=splunk \
  -f token=$SPLUNK_HEC_TOKEN \
  -f endpoint=https://splunk.example.com:8088/services/collector
```

#### Detection Queries

**Splunk:**
```spl
index=github action=org.add_member

| stats count by actor, user
| where count > 5
```

**Unusual repo cloning:**
```spl
index=github action=git.clone

| stats dc(repo) as unique_repos by actor
| where unique_repos > 50
```

**Secret scanning alert ignored:**
```spl
index=github action=secret_scanning.dismiss_alert

| table _time, actor, repo, alert_id
```

#### Compliance Mappings
- **SOC 2:** CC7.2 (System monitoring)
- **NIST 800-53:** AU-6 (Audit review, analysis, reporting)
- **ISO 27001:** A.12.4.1 (Event logging)

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
- ✅ OAuth scope: `repo`, `user:email`, `write:repo_hook` ONLY (not `admin:org`)
- ✅ Restrict to specific repositories (not all org repos)
- ✅ Use CircleCI OIDC for cloud credentials (not long-lived secrets)
- ✅ Enable IP allowlisting if CircleCI provides static IPs
- ⚠️ **Note:** CircleCI was breached in January 2023 - high-risk integration
- ✅ Rotate GitHub OAuth tokens quarterly
- ✅ Monitor audit logs for bulk repository access

**CircleCI IP Addresses (if available):**
Check CircleCI documentation for current static IPs for webhook allowlisting.

---

#### Snyk (Dependency Scanning)

**Data Access:** Medium (read repos, write security alerts)

**Recommended Controls:**
- ✅ OAuth scope: `repo:read`, `security_events:write`
- ✅ Use Snyk's GitHub App (scoped permissions) instead of OAuth app
- ✅ Enable only for repos with dependencies (not docs/config repos)
- ✅ Review Snyk alerts weekly, don't let them accumulate

---

#### Dependabot / Renovate (Dependency Updates)

**Data Access:** Medium-High (read repos, create PRs, update dependencies)

**Recommended Controls:**
- ✅ Use GitHub-native Dependabot (preferred, built-in)
- ✅ If using Renovate: Scope to `repo` only
- ✅ Require PR reviews for Dependabot/Renovate PRs (don't auto-merge)
- ✅ Enable branch protection to require status checks before merge
- ✅ Review dependency update PRs for unusual changes

---

#### Slack/Microsoft Teams (Notifications)

**Data Access:** Low-Medium (read repos, post notifications)

**Recommended Controls:**
- ✅ OAuth scope: `repo:read`, `notifications` (minimal)
- ✅ Use GitHub App with narrow repository selection
- ✅ Avoid granting write permissions
- ✅ Filter notifications to avoid leaking sensitive data in public Slack channels

---

#### SonarQube / SonarCloud (Code Quality)

**Data Access:** Medium (read repos, write code analysis results)

**Recommended Controls:**
- ✅ OAuth scope: `repo:read`, `statuses:write`, `checks:write`
- ✅ Use SonarCloud GitHub App for scoped permissions
- ✅ Review code analysis results before merging
- ✅ Ensure SonarQube doesn't store secrets from scanned code

---

## Appendix A: Edition Compatibility

| Control | GitHub Free | GitHub Team | Enterprise Cloud | Enterprise Server |
|---------|------------|-------------|-----------------|-------------------|
| 2FA Enforcement | ✅ | ✅ | ✅ | ✅ |
| Branch Protection | ✅ (basic) | ✅ | ✅ (advanced) | ✅ (advanced) |
| SAML SSO | ❌ | ❌ | ✅ | ✅ |
| Secret Scanning (private repos) | ❌ | ❌ | ✅ | ✅ |
| Code Scanning (private repos) | ❌ | ❌ | ✅ | ✅ |
| Audit Log Streaming | ❌ | ❌ | ✅ | ✅ |
| Required Workflows | ❌ | ❌ | ✅ | ✅ |
| IP Allowlisting | ❌ | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official GitHub Documentation:**
- [Hardening security for your enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/configuring-settings/hardening-security-for-your-enterprise)
- [Security hardening for GitHub Actions](https://docs.github.com/en/enterprise-cloud@latest/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions)
- [GitHub-recommended security configuration](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-code-security/securing-your-enterprise/applying-the-github-recommended-security-configuration-to-your-enterprise)

**Supply Chain Security Frameworks:**
- [SLSA Framework](https://slsa.dev/)
- [SLSA GitHub Generator](https://github.com/slsa-framework/slsa-github-generator)
- [OpenSSF Supply Chain Integrity WG](https://github.com/ossf/wg-supply-chain-integrity)
- [Achieving SLSA 3 with GitHub Actions](https://github.blog/security/supply-chain-security/slsa-3-compliance-with-github-actions/)

**Supply Chain Incident Reports:**
- [CircleCI Security Incident (January 2023)](https://circleci.com/blog/january-4-2023-security-alert/)
- [Codecov Bash Uploader Compromise (April 2021)](https://about.codecov.io/security-update/)
- [Heroku/Travis CI GitHub OAuth Token Leak (April 2022)](https://github.blog/2022-04-15-security-alert-stolen-oauth-user-tokens/)

**Community Resources:**
- [GitHub Hardening Guide by iAnonymous3000](https://github.com/iAnonymous3000/GitHub-Hardening-Guide)
- [Step Security - Harden-Runner for GitHub Actions](https://github.com/step-security/harden-runner)

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-13 | 1.0 | Initial GitHub hardening guide with supply chain security focus | How to Harden Community |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [CONTRIBUTING.md](/CONTRIBUTING.md)

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
- [SLSA Framework](https://slsa.dev/)
- [OpenSSF Supply Chain Integrity Working Group](https://github.com/ossf/wg-supply-chain-integrity)
- [Achieving SLSA 3 Compliance with GitHub Actions](https://github.blog/security/supply-chain-security/slsa-3-compliance-with-github-actions/)
