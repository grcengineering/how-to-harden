---
layout: guide
title: "Bitbucket Cloud Hardening Guide"
vendor: "Bitbucket"
slug: "bitbucket"
platform: "Atlassian"
platform_slug: "atlassian"
product: "Bitbucket"
tier: "2"
category: "DevOps"
description: "Code repository security hardening for Bitbucket Cloud — workspace membership and app access, project permissions, forking, branch restrictions and merge checks, signed commits, and Pipelines secrets and deployment controls."
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

Bitbucket Cloud is Atlassian's Git-based code hosting and collaboration platform used by **millions of developers** for source code management, CI/CD pipelines, and team collaboration. As a critical repository for intellectual property and deployment pipelines, Bitbucket security configurations directly impact code integrity and software supply chain security.

This is a **product guide within the [Atlassian platform](/guides/atlassian/)**. Organization-wide controls — SAML SSO and enforced authentication policies, two-step verification, SCIM provisioning, IP allowlisting, Marketplace app governance, API token policy, data security policies, and the organization audit log — live in the Atlassian **Common Controls** hub and are referenced here rather than duplicated. Everything below is Bitbucket-specific: what you configure inside a workspace, a project, a repository, or a pipeline.

### Intended Audience
- Security engineers managing development platforms
- DevOps administrators configuring Bitbucket workspaces
- GRC professionals assessing code repository security
- Platform engineers implementing secure SDLC

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

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

> **Organization authentication is configured in the platform hub.** SAML SSO, enforced authentication policies, two-step verification, SCIM provisioning, and IP allowlisting are Atlassian organization controls that apply to Bitbucket along with every other Atlassian product — configure them once at `admin.atlassian.com` following the [Atlassian Common Controls guide](/guides/atlassian/) §1.1 and §1.4. The control below covers what remains genuinely Bitbucket-specific: workspace membership, groups, and invitation policy.

### 1.1 Manage User Permissions and Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege access for workspace members and manage user lifecycle.

#### Rationale
**Why This Matters:**
- Least-privilege groups limit how much code and infrastructure any single compromised account can reach
- Removing departed and inactive users closes standing access that attackers and insiders exploit
- Role-based groups make access auditable and prevent permission sprawl as teams grow
- Shared accounts destroy attribution, so audit logs cannot tie actions to an individual

**Attack Prevented:** Privilege escalation, insider abuse, orphaned-account access, lateral movement

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Configure project-level permissions to manage access at scale across multiple repositories.

#### Rationale
**Why This Matters:**
- Project-scoped permissions enforce consistent least-privilege access across every repository in a project
- Grouping sensitive repositories under restricted projects keeps confidential code away from the broader workspace
- Centralized project access reduces the chance of a misconfigured individual repo exposing data
- Managing access at the project tier prevents the permission drift that accumulates when each repo is configured by hand

**Attack Prevented:** Unauthorized code access, privilege sprawl, data exposure, misconfiguration

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 12.8 |
| NIST 800-53 | AC-20 |

#### Description
Control which third-party applications can access workspace data. This is the workspace-scoped layer of app governance — organization-wide Marketplace app approval, the app block list, and OAuth scope review are configured in the [Atlassian Common Controls guide](/guides/atlassian/) §2.1 and §3.3. Configure both: the organization policy decides which apps may be installed at all, and the workspace app access rules decide which of those may reach this workspace's repositories.

#### Rationale
**Why This Matters:**
- OAuth apps and integrations often hold broad, long-lived access to source code and can become a supply-chain entry point
- Reviewing and removing unused apps shrinks the attack surface exposed to third-party compromise
- Requiring admin approval prevents users from silently granting risky apps access to the workspace
- A compromised or malicious app can exfiltrate code, secrets, and pipeline configuration at scale

**Attack Prevented:** Supply-chain compromise, OAuth token abuse, data exfiltration, unauthorized access

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

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Prevent unauthorized code distribution by disabling forking for private repositories.

#### Rationale
**Why This Matters:**
- Forks of private repos create uncontrolled copies of proprietary code outside protected-branch and access policies
- Disabling forking keeps intellectual property and any embedded secrets within governed repositories
- Forked copies are not covered by the original repo's branch restrictions, scanning, or audit controls
- Restricting forks to within the workspace limits how easily code can leave the organization's boundary

**Attack Prevented:** Source code exfiltration, intellectual property theft, secret leakage, policy bypass

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.9 |
| NIST 800-53 | CM-3, SI-7 |

#### Description
Configure branch restrictions to protect release and default branches from unauthorized or unreviewed changes.

#### Rationale
**Why This Matters:**
- Without a branch restriction, anyone with write access can push straight to the default branch, so a single compromised developer credential puts code into the build with no review step in between
- Blocking force pushes and deletions preserves history, which is what makes tampering detectable after the fact — an attacker who can rewrite history can hide the commit that introduced a backdoor
- Merge checks that require passing builds and a minimum number of approvals turn review from a convention into an enforced gate that cannot be skipped under deadline pressure
- Branch restrictions are the enforcement point that gives the rest of the pipeline its meaning: signed commits, secret scanning, and deployment permissions all assume code arrived through the protected path

**Attack Prevented:** Direct push of unreviewed code to production branches, history rewriting to conceal malicious commits, branch deletion, review bypass

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.9 |
| NIST 800-53 | CM-3 |

#### Description
Require pull request reviews before code can be merged to protected branches.

#### Rationale
**Why This Matters:**
- Mandatory peer review catches malicious or accidental changes before they reach protected branches
- Resetting approvals on new commits prevents an attacker from sneaking changes in after a clean review
- Default reviewers ensure the right code owners examine sensitive changes every time
- Required approvals enforce separation of duties so no single account can merge unreviewed code to production

**Attack Prevented:** Malicious code injection, unauthorized changes, insider tampering, separation-of-duties bypass

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

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.9 |
| NIST 800-53 | SI-7 |

#### Description
Require GPG or SSH signed commits to verify commit authenticity.

#### Rationale
**Why This Matters:**
- Signed commits cryptographically verify that code originates from a trusted, identified author
- Verification blocks attackers from spoofing commit author identities to slip in malicious changes
- Signature requirements defend the integrity of the software supply chain at the commit level
- Unsigned commits can be forged with any name and email, undermining attribution and trust

**Attack Prevented:** Commit spoofing, author impersonation, supply-chain tampering, repudiation

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Securely manage secrets and variables used in Bitbucket Pipelines.

#### Rationale
**Why This Matters:**
- Secured variables mask secrets in build logs, preventing credential exposure to anyone with log or artifact access
- Scoping secrets to the right repository, workspace, or deployment level limits the blast radius if one is leaked
- Centrally managed pipeline secrets avoid hardcoding credentials in source, where they persist in Git history
- Leaked CI/CD credentials grant attackers access to cloud accounts, registries, and production systems

**Attack Prevented:** Secret leakage, credential theft, hardcoded-secret exposure, pipeline compromise

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

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.1 |
| NIST 800-53 | CM-3 |

#### Description
Restrict who can trigger deployments to production environments.

#### Rationale
**Why This Matters:**
- Restricting production deployments to authorized users prevents unauthorized or accidental releases
- Branch and manual-trigger restrictions ensure only reviewed code reaches production environments
- Environment-scoped permissions enforce separation between staging and production access
- Unrestricted deploy access lets a single compromised account push malicious code straight to production

**Attack Prevented:** Unauthorized deployment, malicious release, production tampering, separation-of-duties bypass

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

{% include pack-code.html vendor="bitbucket" section="4.2" %}

---

### 4.3 Scan for Secrets in Commits

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.4 |
| NIST 800-53 | IA-5 |

#### Description
Implement secret scanning to prevent credentials from being committed.

#### Rationale
**Why This Matters:**
- Secret scanning catches API keys, tokens, and passwords before they are committed and exposed
- Committed secrets persist in Git history even after deletion, so prevention at commit time is critical
- Automated scanning provides consistent coverage that manual review of every diff cannot match
- Leaked credentials in repositories are a primary target for attackers harvesting source code

**Attack Prevented:** Credential leakage, hardcoded-secret exposure, supply-chain compromise, account takeover

#### Code Implementation

{% include pack-code.html vendor="bitbucket" section="4.3" %}

---

## 5. Monitoring & Compliance

### 5.1 Enable Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor the **Bitbucket workspace audit log** for repository and workspace events. This is the Bitbucket-specific log; the organization-wide Atlassian audit log and its SIEM streaming are configured in the [Atlassian Common Controls guide](/guides/atlassian/) §5.1. Forward both — the organization log records identity and app events, while the workspace log records the repository, branch-restriction, and permission changes that the organization log does not.

#### Rationale
**Why This Matters:**
- The workspace audit log is the only record of repository-level actions — repository creation and deletion, branch restriction changes, and workspace permission grants — and none of those appear in the organization audit log
- An attacker who has obtained write access typically relaxes a branch restriction before pushing; that change is visible in the workspace log and nowhere else, which makes it one of the highest-value events to alert on
- Monitoring permission changes and repository activity surfaces unauthorized access while it is still actionable rather than after the code has already left
- Without audit trails, incident response cannot reconstruct what an attacker touched, and cannot establish which repositories need to be treated as compromised

**Attack Prevented:** Undetected intrusion, silent relaxation of branch protections, insider abuse, privilege misuse, delayed incident response

#### ClickOps Implementation

**Step 1: Access the Workspace Audit Log**
1. Navigate to: **Workspace Settings** → **Audit log**
2. Review recent events

**Key Bitbucket Events to Monitor:**
- Repository creation and deletion
- Branch restriction and merge-check changes
- Workspace and project permission changes
- User group membership changes
- App installations and access-rule changes

**Step 2: Forward to Your SIEM Alongside the Organization Log**
1. Configure organization audit log streaming per the [Atlassian Common Controls guide](/guides/atlassian/) §5.1 (SIEM webhook forwarding requires Atlassian Guard Premium)
2. Collect the workspace audit log in addition, and confirm your SIEM retention exceeds Bitbucket's native retention window
3. Alert specifically on branch restriction removal and on repository deletion — both are low-frequency, high-signal events

---

### 5.2 Regular Security Reviews

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.1 |
| NIST 800-53 | CA-7 |

#### Description
Conduct regular security reviews of workspace configuration and access.

#### Rationale
**Why This Matters:**
- Recurring reviews catch configuration drift and excess access before attackers exploit it
- Periodic audits of members and apps remove standing access that accumulates silently over time
- Reviewing for public repositories prevents accidental exposure of proprietary code
- Without regular reviews, misconfigurations and stale permissions persist as an open attack surface

**Attack Prevented:** Configuration drift, privilege creep, accidental exposure, stale-access abuse

#### Review Checklist

**Monthly Reviews:**
- Review workspace member list
- Audit admin access
- Review installed apps
- Check for public repositories

**Quarterly Reviews:**
- Full access review
- Branch protection audit
- Pipeline security review
- Secret rotation check

---

## 6. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Bitbucket Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.2 | Workspace membership least privilege | [1.1](#11-manage-user-permissions-and-access) |
| CC6.3 | Project-level permissions | [2.1](#21-configure-project-level-permissions) |
| CC6.7 | Forking restrictions | [2.3](#23-disable-repository-forking-for-private-repos) |
| CC7.1 | Branch protection | [3.1](#31-configure-branch-permissions) |
| CC8.1 | Pull request approvals | [3.2](#32-require-pull-request-approvals) |
| CC7.2 | Workspace audit logging | [5.1](#51-enable-audit-logging) |

**Organization-level criteria** (CC6.1 SSO and 2SV, CC6.6 IP allowlisting) map to the [Atlassian Common Controls guide](/guides/atlassian/) §1.1 and §1.4.

### NIST 800-53 Rev 5 Mapping

| Control | Bitbucket Control | Guide Section |
|---------|-------------------|---------------|
| AC-6 | Workspace membership least privilege | [1.1](#11-manage-user-permissions-and-access) |
| AC-3 | Project-level permissions | [2.1](#21-configure-project-level-permissions) |
| AC-20 | Third-party app access | [2.2](#22-manage-third-party-app-access) |
| CM-3 | Branch protection | [3.1](#31-configure-branch-permissions) |
| SI-7 | Signed commits | [3.3](#33-enforce-signed-commits) |
| SC-12 | Pipeline secret management | [4.1](#41-secure-pipeline-variables) |
| AU-2 | Workspace audit logging | [5.1](#51-enable-audit-logging) |

**Organization-level controls** (IA-2(1) MFA, IA-8 SSO, AC-17 remote access restriction) map to the [Atlassian Common Controls guide](/guides/atlassian/) §1.1 and §1.4.

---

## Appendix A: Plan Compatibility

| Feature | Free | Standard | Premium |
|---------|------|----------|---------|
| Workspace user groups and invitation policy (1.1) | ✅ | ✅ | ✅ |
| Project-level permissions (2.1) | ✅ | ✅ | ✅ |
| Workspace app access rules (2.2) | Basic | ✅ | ✅ |
| Forking restrictions (2.3) | ✅ | ✅ | ✅ |
| Merge checks (3.1, 3.2) | Basic | ✅ | ✅ |
| Deployment permissions (4.2) | ❌ | ✅ | ✅ |
| Audit log (workspace) (5.1) | ❌ | ❌ | ✅ |

**Organization-level features** — SAML SSO, enforced two-step verification, and IP allowlisting — depend on the Atlassian Guard subscription and product plan rather than the Bitbucket plan alone. See the [Atlassian Common Controls guide](/guides/atlassian/) Appendix A for the Guard capability matrix.

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
| 2026-08-08 | 0.2.0 | draft | Restructure as a product guide under the Atlassian platform hub: add `platform`/`platform_slug`/`product` frontmatter and a hub pointer. Remove duplicated organization-level controls — former 1.1 two-step verification and 1.2 SAML SSO now live in Atlassian §1.1, former 1.3 IP allowlisting now lives in Atlassian §1.4. Renumber former 1.4 to 1.1; sections 2-5 unchanged. Scope 5.1 to the Bitbucket workspace audit log with a hub cross-reference, cross-reference org app governance from 2.2, and complete the 3.1 rationale with an Attack Prevented line | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.2 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with workspace security, branch protection, and pipeline security | Claude Code (Opus 4.5) |
| 2026-02-19 | 0.1.1 | draft | Extract inline code blocks to Code Pack files (sections 4.2, 4.3) | Claude Code (Opus 4.6) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
