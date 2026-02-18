---
layout: guide
title: "Bitbucket Cloud Hardening Guide"
vendor: "Bitbucket"
slug: "bitbucket"
tier: "2"
category: "DevOps"
description: "Code repository security hardening for Bitbucket Cloud including workspace security, branch permissions, and access controls"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Bitbucket Cloud is Atlassian's Git-based code hosting and collaboration platform used by **millions of developers** for source code management, CI/CD pipelines, and team collaboration. As a critical repository for intellectual property and deployment pipelines, Bitbucket security configurations directly impact code integrity and software supply chain security.

### Intended Audience
- Security engineers managing development platforms
- DevOps administrators configuring Bitbucket workspaces
- GRC professionals assessing code repository security
- Platform engineers implementing secure SDLC

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Bitbucket Cloud security configurations including workspace settings, authentication, branch permissions, and pipeline security. Bitbucket Data Center is covered in a separate guide.

---

## Table of Contents

1. [Authentication & Access Control](#1-authentication--access-control)
2. [Workspace Security](#2-workspace-security)
3. [Repository & Branch Protection](#3-repository--branch-protection)
4. [Pipelines Security](#4-pipelines-security)
5. [Monitoring & Compliance](#5-monitoring--compliance)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & Access Control

### 1.1 Enforce Two-Step Verification

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require two-step verification (2SV) for all workspace members to protect against credential compromise.

#### Rationale
**Why This Matters:**
- Prevents unauthorized access from stolen credentials
- 2SV enforcement is a Bitbucket Premium feature
- Security keys (FIDO U2F) provide phishing-resistant authentication

#### Prerequisites
- [ ] Bitbucket Premium or Atlassian Guard subscription

#### ClickOps Implementation

**Step 1: Configure Workspace 2SV Requirement**
1. Navigate to: **Workspace Settings** → **Security** → **Two-step verification**
2. Enable **Require two-step verification**
3. Set grace period for compliance
4. Review non-compliant members

**Step 2: Configure Atlassian Guard (Organization-wide)**
1. Navigate to: **admin.atlassian.com** → **Security** → **Authentication policies**
2. Create authentication policy
3. Enable **Enforce two-step verification**
4. Apply to organization members

**Step 3: Promote Security Keys**
1. Encourage use of FIDO U2F security keys
2. Document approved security key options
3. Provide setup guides for members

**Time to Complete:** ~30 minutes

---

### 1.2 Configure SAML Single Sign-On

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO using Atlassian Access to centralize identity management.

#### ClickOps Implementation

**Step 1: Verify Domain**
1. Navigate to: **admin.atlassian.com** → **Directory** → **Domains**
2. Add your organization's domain
3. Verify via DNS TXT record

**Step 2: Configure SAML SSO**
1. Navigate to: **Security** → **SAML single sign-on**
2. Click **Add SAML configuration**
3. Configure IdP settings:
   - Identity provider Entity ID
   - SSO URL
   - Public certificate
4. Download SP metadata for IdP configuration

**Step 3: Enable SSO Enforcement**
1. Create authentication policy
2. Enable **Enforce single sign-on**
3. Configure session timeout
4. Apply policy to members

---

### 1.3 Configure IP Allowlisting

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17, SC-7 |

#### Description
Restrict Bitbucket access to approved IP addresses to prevent access from unauthorized locations.

#### Rationale
**Why This Matters:**
- Prevents access even with stolen credentials
- Limits exposure to corporate networks
- Required for Premium/Atlassian Guard

#### Prerequisites
- [ ] Bitbucket Premium subscription

#### ClickOps Implementation

**Step 1: Configure IP Allowlist**
1. Navigate to: **Workspace Settings** → **Security** → **IP allowlist**
2. Click **Add IP address**
3. Add corporate network IP ranges
4. Add VPN egress IPs
5. Add CI/CD server IPs

**Step 2: Test Configuration**
1. Verify access from allowed IPs
2. Test blocked access from other IPs
3. Document emergency procedures

**Configuration Example:**
```text
Corporate Office: 203.0.113.0/24
VPN Egress: 198.51.100.0/24
CI/CD Servers: 192.0.2.0/24
```

---

### 1.4 Manage User Permissions and Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege access for workspace members and manage user lifecycle.

#### ClickOps Implementation

**Step 1: Review Workspace Members**
1. Navigate to: **Workspace Settings** → **User groups**
2. Review member list and permissions
3. Remove inactive or departed users
4. Never share accounts between users

**Step 2: Configure User Groups**
1. Create role-based groups:
   - `developers` - Read/write access
   - `reviewers` - Read access
   - `admins` - Administrative access
2. Assign minimum necessary permissions

**Step 3: Configure Invitation Policies**
1. Navigate to: **Workspace Settings** → **Security** → **Invitations**
2. Configure:
   - Restrict who can send invitations
   - Allow invitations only to specific email domains
   - Require admin approval for new members

**Step 4: Regular Access Reviews**
1. Quarterly review of all workspace members
2. Remove users who no longer need access
3. Audit group memberships

---

## 2. Workspace Security

### 2.1 Configure Project-Level Permissions

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Configure project-level permissions to manage access at scale across multiple repositories.

#### ClickOps Implementation

**Step 1: Create Project Structure**
1. Navigate to: **Workspace** → **Projects**
2. Create projects by team or function:
   - `frontend-apps`
   - `backend-services`
   - `infrastructure`
   - `sensitive-data`

**Step 2: Configure Project Permissions**
1. Navigate to: **Project Settings** → **User and group access**
2. Add groups with appropriate permissions:
   - **Admin:** Full project control
   - **Write:** Can push and merge
   - **Read:** View only
3. Permission changes apply to all repos in project

**Step 3: Restrict Repository Creation**
1. Configure who can create repositories
2. Require repositories to be in a project
3. Set default project for new repositories

---

### 2.2 Manage Third-Party App Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 12.8 |
| NIST 800-53 | AC-20 |

#### Description
Control which third-party applications can access workspace data.

#### ClickOps Implementation

**Step 1: Review Installed Apps**
1. Navigate to: **Workspace Settings** → **Installed apps**
2. Review all installed applications
3. Identify apps with broad permissions
4. Remove unused or unknown apps

**Step 2: Configure App Installation Policy**
1. Navigate to: **Workspace Settings** → **Security** → **App access rules**
2. Configure:
   - Restrict who can install apps
   - Require admin approval for new apps
   - Block specific apps if needed

**Step 3: Audit OAuth Authorizations**
1. Review user OAuth authorizations
2. Revoke unnecessary authorizations
3. Establish app approval process

---

### 2.3 Disable Repository Forking for Private Repos

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Prevent unauthorized code distribution by disabling forking for private repositories.

#### ClickOps Implementation

**Step 1: Configure Workspace Forking Policy**
1. Navigate to: **Workspace Settings** → **Settings**
2. Under **Forking**:
   - Disable **Allow forking** for private repositories
   - Or restrict forking to within workspace only

**Step 2: Configure Repository-Level Override**
1. For specific repos requiring forks:
2. Navigate to: **Repository Settings** → **Settings**
3. Configure fork settings as needed

---

## 3. Repository & Branch Protection

### 3.1 Configure Branch Permissions

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.9 |
| NIST 800-53 | CM-3, SI-7 |

#### Description
Configure branch permissions to protect important branches from unauthorized changes.

#### Rationale
**Why This Matters:**
- Prevents direct pushes to production branches
- Enforces code review requirements
- Protects against tampering

#### ClickOps Implementation

**Step 1: Configure Branch Permissions**
1. Navigate to: **Repository Settings** → **Branch restrictions**
2. Add branch restriction for `main`:
   - **Branch pattern:** `main` or `master`
   - Configure restrictions

**Step 2: Configure Merge Restrictions**
1. Add merge restriction:
   - **Type:** Require passing builds
   - **Type:** Require approvals
   - **Minimum approvals:** 1 (or 2+ for L2)

**Step 3: Configure Push Restrictions**
1. Prevent direct pushes:
   - Only allow specific users/groups to push
   - Prevent deletions
   - Prevent history rewrites (force push)

---

### 3.2 Require Pull Request Approvals

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.9 |
| NIST 800-53 | CM-3 |

#### Description
Require pull request reviews before code can be merged to protected branches.

#### ClickOps Implementation

**Step 1: Configure Default Reviewers**
1. Navigate to: **Repository Settings** → **Branch restrictions**
2. Configure merge checks:
   - **Minimum approvals:** 1 (L1) or 2+ (L2)
   - Enable **Reset approvals on source branch changes**

**Step 2: Configure Default Reviewers**
1. Navigate to: **Repository Settings** → **Default reviewers**
2. Add default reviewers for branches
3. Configure review requirements

**Step 3: Configure Merge Strategies**
1. Navigate to: **Repository Settings** → **Merge strategies**
2. Enable/disable merge strategies:
   - Merge commit
   - Squash
   - Fast-forward (requires linear history)

---

### 3.3 Enforce Signed Commits

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.9 |
| NIST 800-53 | SI-7 |

#### Description
Require GPG or SSH signed commits to verify commit authenticity.

#### ClickOps Implementation

**Step 1: Configure Signature Requirements**
1. Navigate to: **Repository Settings** → **Branch restrictions**
2. Add restriction for protected branches:
   - Require signed commits (if available)

**Step 2: Document Signing Requirements**
1. Provide GPG key setup guides
2. Configure signing key requirements
3. Document verification procedures

---

## 4. Pipelines Security

### 4.1 Secure Pipeline Variables

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Securely manage secrets and variables used in Bitbucket Pipelines.

#### ClickOps Implementation

**Step 1: Configure Repository Variables**
1. Navigate to: **Repository Settings** → **Repository variables**
2. Add variables with **Secured** option enabled
3. Secured variables are masked in logs

**Step 2: Configure Workspace Variables**
1. Navigate to: **Workspace Settings** → **Workspace variables**
2. Add shared secrets at workspace level
3. Enable **Secured** for sensitive values

**Step 3: Configure Deployment Variables**
1. Navigate to: **Repository Settings** → **Deployments**
2. Create deployment environments: `staging`, `production`
3. Add environment-specific variables
4. Configure deployment permissions

---

### 4.2 Configure Deployment Permissions

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.1 |
| NIST 800-53 | CM-3 |

#### Description
Restrict who can trigger deployments to production environments.

#### ClickOps Implementation

**Step 1: Configure Deployment Environments**
1. Navigate to: **Repository Settings** → **Deployments**
2. Create environments with appropriate restrictions

**Step 2: Configure Environment Restrictions**
1. For production environment:
   - Restrict deployment to specific branches
   - Require manual trigger
   - Restrict who can deploy

**Step 3: Pipeline Configuration**
```yaml
# bitbucket-pipelines.yml
pipelines:
  branches:
    main:
      - step:
          name: Build
          script:
            - npm install
            - npm run build
      - step:
          name: Deploy to Production
          deployment: production
          trigger: manual
          script:
            - ./deploy.sh
```

---

### 4.3 Scan for Secrets in Commits

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.4 |
| NIST 800-53 | IA-5 |

#### Description
Implement secret scanning to prevent credentials from being committed.

#### Code Implementation

**Using git-secrets (Pre-commit Hook):**
```bash
# Install git-secrets
brew install git-secrets

# Configure for repository
cd your-repo
git secrets --install
git secrets --register-aws

# Add custom patterns
git secrets --add 'PRIVATE KEY'
git secrets --add 'api[_-]?key'
```

**Using Pipeline-Based Scanning:**
```yaml
# bitbucket-pipelines.yml
pipelines:
  default:
    - step:
        name: Secret Scan
        script:
          - pip install trufflehog
          - trufflehog --regex --entropy=False .
```

---

## 5. Monitoring & Compliance

### 5.1 Enable Audit Logging

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs for security events and compliance.

#### ClickOps Implementation

**Step 1: Access Audit Log**
1. Navigate to: **Workspace Settings** → **Audit log**
2. Review recent events

**Step 2: Configure Atlassian Guard Audit Logs**
1. Navigate to: **admin.atlassian.com** → **Security** → **Audit log**
2. View organization-wide events
3. Export logs for SIEM integration

**Key Events to Monitor:**
- User login/logout events
- Permission changes
- Repository creation/deletion
- Branch permission changes
- App installations

**Step 3: SIEM Integration**
1. Use Atlassian Guard API for log export
2. Configure automated log forwarding
3. Set up security alerts

---

### 5.2 Regular Security Reviews

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.1 |
| NIST 800-53 | CA-7 |

#### Description
Conduct regular security reviews of workspace configuration and access.

#### Review Checklist

**Monthly Reviews:**
- [ ] Review workspace member list
- [ ] Audit admin access
- [ ] Review installed apps
- [ ] Check for public repositories

**Quarterly Reviews:**
- [ ] Full access review
- [ ] Branch protection audit
- [ ] Pipeline security review
- [ ] Secret rotation check

---

## 6. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Bitbucket Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.1 | Two-step verification | [1.1](#11-enforce-two-step-verification) |
| CC6.1 | SSO | [1.2](#12-configure-saml-single-sign-on) |
| CC6.6 | IP allowlisting | [1.3](#13-configure-ip-allowlisting) |
| CC6.2 | Least privilege | [1.4](#14-manage-user-permissions-and-access) |
| CC7.1 | Branch protection | [3.1](#31-configure-branch-permissions) |
| CC7.2 | Audit logging | [5.1](#51-enable-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Bitbucket Control | Guide Section |
|---------|-------------------|---------------|
| IA-2(1) | MFA | [1.1](#11-enforce-two-step-verification) |
| IA-8 | SSO | [1.2](#12-configure-saml-single-sign-on) |
| AC-6 | Least privilege | [1.4](#14-manage-user-permissions-and-access) |
| CM-3 | Branch protection | [3.1](#31-configure-branch-permissions) |
| AU-2 | Audit logging | [5.1](#51-enable-audit-logging) |

---

## Appendix A: Plan Compatibility

| Feature | Free | Standard | Premium |
|---------|------|----------|---------|
| Two-step verification | Optional | Optional | Enforced |
| IP allowlisting | ❌ | ❌ | ✅ |
| Merge checks | Basic | ✅ | ✅ |
| Deployment permissions | ❌ | ✅ | ✅ |
| Audit log (workspace) | ❌ | ❌ | ✅ |
| SAML SSO | ❌ | ❌ | Via Guard |

---

## Appendix B: References

**Official Atlassian Documentation:**
- [Atlassian Trust Center](https://www.atlassian.com/trust) | [Customer Trust Center](https://customertrust.atlassian.com/) (powered by Conveyor)
- [Bitbucket Cloud Support](https://support.atlassian.com/bitbucket-cloud/)
- [Bitbucket Cloud Security](https://support.atlassian.com/bitbucket-cloud/docs/security/)
- [Atlassian Guard Documentation](https://support.atlassian.com/security-and-access-policies/)
- [Security Advisories](https://www.atlassian.com/trust/security/advisories)
- [Bitbucket Server Security Advisories](https://confluence.atlassian.com/bitbucketserver/bitbucket-server-security-advisories-776640597.html)

**API & Developer Tools:**
- [Bitbucket Cloud REST API](https://developer.atlassian.com/cloud/bitbucket/rest/)
- [Integrating with Bitbucket Cloud](https://developer.atlassian.com/cloud/bitbucket/)
- [Bitbucket Data Center REST API](https://developer.atlassian.com/server/bitbucket/rest/v1000/)
- [Atlassian Developer Portal](https://developer.atlassian.com/)
- [GitHub Organization (Atlassian)](https://github.com/atlassian)

**Compliance Frameworks:**
- SOC 2 Type II, ISO/IEC 27001:2022 (as part of Atlassian Cloud platform) — via [Atlassian Compliance Resources](https://www.atlassian.com/trust/compliance/resources)
- SOX, PCI DSS compliance
- [Compliance FAQ](https://www.atlassian.com/trust/compliance/compliance-faq)

**Security Incidents:**
- **May 2024 — Plaintext Secrets Leak in Pipeline Artifacts:** Mandiant discovered that Bitbucket Cloud pipeline artifacts could unintentionally expose plaintext authentication secrets (including AWS credentials) stored in "Secured Variables." Attackers exploited this to attempt AWS account compromise. ([Vorlon Report](https://vorlon.io/saas-security-blog/bitbucket-springs-a-secrets-leak))
- **2024 — Bitbucket Data Center Vulnerabilities:** 20 high-severity vulnerabilities (CVSS > 7.4) patched across Bitbucket Data Center/Server, including CVE-2024-38819 (CVSS 7.5, path traversal). ([Stack.Watch Tracker](https://stack.watch/product/atlassian/bitbucket/))
- **2024 — Infrastructure Reliability:** 38 service incidents recorded with over 207 hours of total downtime; approximately half classified as major or critical impact. ([GitProtect Report](https://gitprotect.io/blog/the-state-of-atlassian-threat-landscape-2024-in-review/))

**Third-Party Resources:**
- [Bitbucket Security Best Practices - Snyk](https://snyk.io/blog/cheat-sheet-10-bitbucket-security-best-practices/)
- [Security Best Practices - Cycode](https://cycode.com/blog/security-best-practices-for-bitbucket/)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with workspace security, branch protection, and pipeline security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
