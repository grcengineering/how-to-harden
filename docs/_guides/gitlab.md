---
layout: guide
title: "GitLab Hardening Guide"
vendor: "GitLab"
slug: "gitlab"
tier: "2"
category: "DevOps"
description: "DevOps platform security for CI/CD pipelines, repository access, and runners"
version: "0.2.1"
maturity: "draft"
last_updated: "2026-08-08"
---


## Overview

GitLab is used by **50%+ of Fortune 100** with 30,000+ paying customers. Integrated CI/CD pipelines, container registry, and secrets management concentrate attack surface. Runner tokens, project API keys, and OAuth integrations with cloud providers enable code injection and infrastructure access. A compromised GitLab instance provides attackers with source code, CI/CD secrets, and deployment capabilities.

### Intended Audience
- Security engineers hardening GitLab instances
- DevOps engineers configuring CI/CD security
- GRC professionals assessing DevSecOps compliance
- Platform teams managing GitLab infrastructure

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers GitLab security configurations including authentication, CI/CD pipeline security, runner hardening, and third-party integration controls.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [CI/CD Pipeline Security](#2-cicd-pipeline-security)
3. [Runner Security](#3-runner-security)
4. [Repository Security](#4-repository-security)
5. [Secrets Management](#5-secrets-management)
6. [Monitoring & Detection](#6-monitoring--detection)
7. [AI Assistant Governance (GitLab Duo)](#7-ai-assistant-governance-gitlab-duo)
8. [Compliance Quick Reference](#8-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1)

#### Description
Require SAML/OIDC SSO with MFA for all GitLab authentication, eliminating password-based access.

#### Rationale
**Why This Matters:**
- GitLab credentials provide access to source code and CI/CD pipelines
- Compromised accounts can inject malicious code
- SSO enables centralized access control and MFA enforcement

**Attack Prevented:** Credential-based account takeover, malicious code injection into source and CI/CD pipelines

**Attack Scenario:** Malicious .gitlab-ci.yml injects backdoor during build; stolen runner token enables unauthorized deployments.

#### ClickOps Implementation (GitLab.com Premium/Ultimate)

**Step 1: Configure SAML SSO**
1. Navigate to: **Group → Settings → SAML SSO**
2. Configure:
   - **Identity provider SSO URL:** Your IdP endpoint
   - **Certificate fingerprint:** From IdP
   - **Enforce SSO:** Enable
3. Click **Save changes**

**Step 2: Enforce Group-Managed Accounts**
1. Navigate to: **Group → Settings → SAML SSO**
2. Enable: **Enforce SSO-only authentication for web activity**
3. Enable: **Enforce SSO-only authentication for Git and Dependency Proxy activity**

**Step 3: Disable Password Authentication**
1. Navigate to: **Admin → Settings → General → Sign-in restrictions**
2. Disable: **Password authentication enabled for web interface**
3. Disable: **Password authentication enabled for Git over HTTP(S)**

#### Code Implementation

{% include pack-code.html vendor="gitlab" section="1.1" %}

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2(1) | MFA for network access |

---

### 1.2 Implement Granular Project Permissions

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure project-level access controls using GitLab's role-based permissions.

#### Rationale
**Why This Matters:**
- GitLab's role hierarchy (Guest through Owner) limits each user to only the actions their job requires, shrinking the blast radius of any single compromised account
- Protected branches with a forced merge-request workflow stop unreviewed or malicious code from reaching production branches directly
- Mandatory multi-approver review with author self-approval blocked prevents one insider or one hijacked account from shipping changes unilaterally

**Attack Prevented:** Privilege escalation, unauthorized code changes, insider tampering, malicious merge to protected branches

#### ClickOps Implementation

**Step 1: Define Role Strategy**

| Role | Permissions | Use Case |
|------|-------------|----------|
| Guest | View issues, wiki | External stakeholders |
| Reporter | Clone, view CI/CD | QA, read-only developers |
| Developer | Push to non-protected branches | Development team |
| Maintainer | Merge to protected, manage CI/CD | Tech leads |
| Owner | Full control | Project owners only |

**Step 2: Configure Protected Branches**
1. Navigate to: **Project → Settings → Repository → Protected branches**
2. Protect `main` and `release/*`:
   - **Allowed to merge:** Maintainers
   - **Allowed to push:** No one (force MR workflow)
   - **Require approval from code owners:** Enable

**Step 3: Enable Required Approvals**
1. Navigate to: **Project → Settings → Merge requests**
2. Configure:
   - **Approvals required:** 2 (minimum)
   - **Prevent approval by author:** Enable
   - **Prevent editing approval rules:** Enable

---

### 1.3 Configure Personal Access Token Policies

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Restrict personal access token (PAT) creation and enforce expiration policies.

#### Rationale
**Why This Matters:**
- Personal access tokens authenticate to the API and Git without MFA, so a leaked long-lived token grants persistent, password-less access to source and pipelines
- Enforcing a maximum token lifetime guarantees stolen or forgotten tokens expire automatically instead of remaining valid indefinitely
- Restricting tokens to minimal scopes ensures a leaked read token cannot be used to push code or alter CI/CD configuration

**Attack Prevented:** Credential theft, token replay, over-privileged token abuse, persistent unauthorized access

#### ClickOps Implementation

**Step 1: Set Token Expiration Limits**

Expiration is no longer optional on current GitLab. Every new personal, group, and project access token must have an expiration date; if the creator does not set one, GitLab applies a default of 365 days, and the platform ceiling is 400 days (GitLab 17.6 and later). Non-expiring tokens are deprecated — on upgrade, existing tokens without an expiration date have one applied automatically. Treat any shorter figure as an organizational policy choice made *within* that 400-day ceiling, not as a platform default.

1. Navigate to: **Admin → Settings → General → Account and limit**
2. Configure:
   - **Maximum allowable lifetime for access tokens:** 90 days (recommended organizational policy; the platform hard ceiling is 400 days)
   - **Limit project access token creation:** Enable
3. Keep the service account token expiration settings enabled — do not use the allowance for non-expiring service account credentials, which reintroduces the exact persistence problem the mandatory expiry removed.

**Step 2: Disable API Scope for Non-Essential Tokens**
- Audit tokens with `api` scope
- Replace with minimal scopes (read_repository, write_repository)

**Source:** [Personal access tokens](https://docs.gitlab.com/user/profile/personal_access_tokens/)

---


{% include pack-code.html vendor="gitlab" section="1.3" %}

---

### 1.4 Enforce Approvals with Merge Request Approval Policies

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.1 |
| NIST 800-53 | CM-3, AU-10 |

#### Description
Move approval enforcement out of per-project approval rules and into merge request approval policies, which live in a separate security policy project that only Owners can link. Includes the `any_merge_request` rule that requires approval whenever a merge request contains unsigned commits. Source: [Merge request approval policies](https://docs.gitlab.com/user/application_security/policies/merge_request_approval_policies/).

#### Rationale
**Why This Matters:**
- Project approval rules (control 1.2) are configured in project settings, where any Maintainer can edit or delete them — the same people whose code the rules are meant to gate can turn the gate off
- Merge request approval policies are defined in a linked security policy project, and only the Owner role can link that project, so the enforcement configuration and the code being enforced sit under different administrators
- Policies attach at the group level and apply to every project underneath, so a newly created project inherits approval enforcement instead of starting with none
- The `any_merge_request` rule type can require approval whenever a merge request contains unsigned commits, which makes the commit-signing control in 4.2 enforceable rather than advisory

**Attack Prevented:** Approval-rule tampering by a compromised or malicious Maintainer, unilateral merge of attacker-authored code, unsigned and spoofed commits reaching protected branches without review

#### ClickOps Implementation

**Step 1: Create and Link a Security Policy Project**
1. Navigate to: **Group → Secure → Policies**
2. Click **Edit policy project** and create or select a dedicated security policy project
3. Restrict membership on that project to the security team — its members control enforcement for every project in the group
4. Confirm only Owners hold the ability to change the linked policy project

**Step 2: Create the Merge Request Approval Policy**
1. Navigate to: **Group → Secure → Policies → New policy → Merge request approval policy**
2. Set the scope to all projects in the group (or an explicit project list)
3. Add a rule of type **Any merge request** targeting protected branches
4. Set the commit attribute to **unsigned commits** so the rule triggers when any commit in the merge request is unsigned
5. Set **Approvals required** to at least 1 and assign an approver group outside the project's own Maintainers
6. Set the policy status to **Enabled** and save

**Step 3: Keep Project Rules as Defense in Depth**
1. Leave the project-level approval rules from control 1.2 in place
2. Treat them as a convenience layer, not the enforcement layer — the policy is what survives a Maintainer with bad intent

#### Validation & Testing
1. Sign in as a user with the Maintainer role on a covered project and confirm the policy cannot be edited or removed from **Secure → Policies**
2. Open a merge request containing at least one unsigned commit against a protected branch and confirm an additional policy-sourced approval requirement appears and blocks merge
3. Delete a project-level approval rule as a Maintainer and confirm the policy requirement still applies to a new merge request
4. Review **Group → Secure → Policies** quarterly to confirm the policy is still enabled and scoped to every project

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC8.1 | Change management authorization |
| **NIST 800-53** | CM-3 | Configuration change control |
| **NIST 800-53** | AU-10 | Non-repudiation of code authorship |

---

## 2. CI/CD Pipeline Security

### 2.1 Protect CI/CD Variables

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Configure CI/CD variables with appropriate protection levels and masking.

#### Rationale
**Why This Matters:**
- CI/CD variables typically hold deployment credentials, API keys, and cloud secrets that grant access far beyond GitLab itself
- Masking keeps secret values from being printed in job logs, which are visible to anyone who can view the pipeline
- Marking variables as protected confines them to protected branches, so a feature branch or fork cannot exfiltrate production secrets
- Environment-scoping prevents a staging pipeline from reading production credentials

**Attack Prevented:** Secret exposure in logs, credential exfiltration via untrusted branches, cross-environment secret leakage

#### ClickOps Implementation

**Step 1: Configure Variable Protection**
1. Navigate to: **Project → Settings → CI/CD → Variables**
2. For each sensitive variable:
   - **Protect variable:** Enable (only available in protected branches)
   - **Mask variable:** Enable (hidden in job logs)
   - **Expand variable reference:** Disable

**Step 2: Use Group-Level Variables**
1. Navigate to: **Group → Settings → CI/CD → Variables**
2. Define shared secrets at group level
3. Limit duplication across projects

**Step 3: Environment-Scoped Variables**
1. Create separate variables for each environment:
   - `PROD_API_KEY` (protected)
   - `STAGING_API_KEY`
2. Scope to specific environments

#### Code Implementation

{% include pack-code.html vendor="gitlab" section="2.1" %}

### 2.2 Implement Pipeline Security Controls

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7, SI-7

#### Description
Restrict pipeline execution and prevent unauthorized CI/CD modifications.

#### Rationale
**Why This Matters:**
- Fork-based merge requests run attacker-authored pipeline code, so requiring approval before they execute stops poisoned-pipeline attacks
- Limiting the CI/CD job token scope to only the projects a pipeline truly needs prevents lateral movement between repositories if a job is compromised
- Requiring pipelines to succeed and discussions to resolve before merge enforces that security and quality checks actually gate the codebase

**Attack Prevented:** Poisoned pipeline execution, lateral movement via job tokens, bypass of security gates

#### ClickOps Implementation

**Step 1: Require Pipeline Approval for Forks**
1. Navigate to: **Project → Settings → CI/CD → General pipelines**
2. Enable: **Protect CI/CD variables in pipeline subscriptions**
3. Enable: **CI/CD job token scope:** Limit access to necessary projects

**Step 2: Configure Merge Request Pipelines**
1. Navigate to: **Project → Settings → Merge requests**
2. Enable: **Pipelines must succeed before merge**
3. Enable: **All discussions must be resolved**

**Step 3: Limit Who Can Run Pipelines**
1. Navigate to: **Project → Settings → CI/CD**
2. Configure: **Who can run pipelines on protected branches**
3. Restrict manual job triggers

---

### 2.3 Harden .gitlab-ci.yml Configuration

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-7

#### Description
Implement secure CI/CD configuration practices. See the CLI Code Pack below for a security-hardened .gitlab-ci.yml example.

#### Rationale
**Why This Matters:**
- The .gitlab-ci.yml file is executable code that runs with pipeline privileges, making it a prime target for supply-chain injection
- Pinning image and dependency versions, avoiding untrusted includes, and restricting privileged execution reduce the chance a build step is hijacked
- A hardened pipeline definition limits what a compromised job can reach, containing damage to a single stage rather than the whole environment

**Attack Prevented:** CI/CD supply-chain injection, malicious build steps, privileged container escape, untrusted include abuse

{% include pack-code.html vendor="gitlab" section="2.3" %}

---

### 2.4 Apply Fine-Grained CI/CD Job Token Permissions

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.8 |
| NIST 800-53 | AC-6 |

#### Description
Replace blanket job token inheritance with per-allowlist-entry endpoint scopes, so each project you authorize receives only the specific `READ_*` or `ADMIN_*` API permissions it needs. Generally available in GitLab 18.3. Source: [Fine-grained permissions for CI/CD job tokens](https://docs.gitlab.com/ci/jobs/fine_grained_permissions/).

#### Rationale
**Why This Matters:**
- Without fine-grained permissions, a CI/CD job token carries the permissions of the user who triggered the pipeline — so a routine job triggered by an Owner can reach everything that Owner can reach in every allowlisted project
- The allowlist alone (control 2.2) answers "which projects" but not "to do what"; fine-grained permissions add the missing second question by scoping each entry to explicit endpoint groups such as reading packages or reading jobs
- Job tokens are a primary target in poisoned-pipeline attacks because they are present in the job environment by design; a token limited to read-only endpoints degrades a stolen credential from a lateral-movement primitive into a low-value one
- Self-managed administrators can enforce the allowlist instance-wide, which closes the gap where individual project Maintainers opt out of scoping entirely

**Attack Prevented:** Lateral movement between projects using a harvested job token, privilege inheritance from a highly privileged triggering user, unauthorized API writes (member additions, pipeline changes) from a compromised job

#### ClickOps Implementation

**Step 1: Confirm the Allowlist Is Active**
1. Navigate to: **Project → Settings → CI/CD → Job token permissions**
2. Confirm inbound access is limited to an explicit list of authorized groups and projects rather than open access
3. Remove allowlist entries that no longer have a working pipeline dependency

**Step 2: Scope Each Allowlist Entry**
1. For each entry in the authorized groups and projects list, open its permissions
2. Select only the endpoint scopes the consuming pipeline actually calls — for example a read scope for packages or jobs
3. Avoid granting any `ADMIN_*` scope unless a pipeline provably needs to write; document the justification for every one you keep
4. Save and re-run the dependent pipeline to confirm nothing broke

**Step 3 (Self-Managed): Enforce the Allowlist Instance-Wide**
1. Navigate to: **Admin → Settings → CI/CD → Job token permissions**
2. Enable: **Enable and enforce job token allowlist for all projects**
3. Communicate the change ahead of time — projects relying on unscoped token access will fail until their allowlist entries are configured

#### Validation & Testing
1. From a pipeline job in an authorized inbound project, call an API endpoint outside the granted scope using the job token and confirm the request is rejected with a 401 or 403
2. Call an endpoint inside the granted scope and confirm it succeeds, proving the scoping is precise rather than simply broken
3. Review each project's **Job token permissions** page and record any entry still holding an `ADMIN_*` scope for the next access review
4. On self-managed, confirm a project that has not configured an allowlist cannot receive inbound job token access once enforcement is enabled

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.3 | Least-privilege access to resources |
| **NIST 800-53** | AC-6 | Least privilege |
| **NIST 800-53** | AC-3 | Access enforcement |

---

### 2.5 Enforce Security Scans with Pipeline Execution Policies

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.1 |
| NIST 800-53 | CM-7, SI-7 |

#### Description
Inject mandatory CI/CD jobs into every targeted project from a security policy project, so required scans run regardless of what the project's own `.gitlab-ci.yml` says. Generally available in GitLab 17.3 (Ultimate). Source: [Pipeline execution policies](https://docs.gitlab.com/user/application_security/policies/pipeline_execution_policies/).

#### Rationale
**Why This Matters:**
- Security jobs defined only in a project's `.gitlab-ci.yml` can be edited or deleted by anyone who can push that file, meaning the scans gating a release are controlled by the same people whose code they inspect
- A pipeline execution policy stores the mandatory configuration in a separate security policy project and injects it at pipeline creation, so scans still run when a project's configuration is empty, broken, or deliberately stripped
- Compliance pipelines — the older mechanism that attached a pipeline configuration to a compliance framework — are deprecated; migrating now keeps enforcement on a supported path instead of one scheduled for removal
- A per-project cap of five pipeline execution policies keeps enforcement auditable, so the set of mandatory jobs stays small enough for a reviewer to actually read

**Attack Prevented:** Removal or bypass of mandatory security scanning, malicious edits to pipeline definitions that disable gates, silent enforcement gaps left behind by deprecated compliance pipelines

#### ClickOps Implementation

**Step 1: Create the Pipeline Execution Policy**
1. Navigate to: **Group → Secure → Policies → New policy → Pipeline execution policy**
2. Confirm the linked security policy project is the restricted-membership project from control 1.4
3. Point the policy at the CI configuration file held in that security policy project — the policy itself is stored under `.gitlab/security-policies/policy.yml` as a `pipeline_execution_policy` entry

**Step 2: Choose the Injection Strategy**
1. Select `inject_policy` to add the policy's jobs alongside the project's own pipeline — this is the current strategy and the right default for most groups
2. Do not adopt `inject_ci`; it is the deprecated predecessor to `inject_policy` and existing policies using it should be migrated
3. Select `override_project_ci` only where the policy's configuration must fully replace the project's pipeline, such as tightly regulated deployment repositories

**Step 3: Scope and Cap**
1. Set the policy scope to the projects or compliance-framework-labeled projects that must carry the mandatory jobs
2. Keep the total at or below the limit of five pipeline execution policies per project
3. Enable the policy and save

**Step 4: Migrate Off Compliance Pipelines**
1. Identify compliance frameworks that still specify a pipeline configuration file
2. Recreate the equivalent jobs as a pipeline execution policy
3. Clear the pipeline configuration from the compliance framework once the policy is verified, so a single mechanism owns enforcement

#### Validation & Testing
1. Create a scratch project in scope with a minimal `.gitlab-ci.yml`, run a pipeline, and confirm the policy-injected jobs appear and execute
2. Delete every job from the project's own CI configuration, re-run, and confirm the mandatory jobs still run
3. As a project Maintainer, attempt to modify the injected jobs and confirm the change does not take effect
4. Count the pipeline execution policies applying to your most heavily governed project and confirm the total is five or fewer

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC7.1 | Detection of configuration deviations |
| **NIST 800-53** | CM-7 | Least functionality in build configuration |
| **NIST 800-53** | SI-7 | Software and information integrity |

---

### 2.6 Pin and Vet CI/CD Catalog Components

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.4 |
| NIST 800-53 | SR-3, CM-7 |

#### Description
Treat CI/CD catalog components as third-party dependencies: pin every reference to an immutable version, prefer commit SHAs, and review the component's source before adoption. Source: [CI/CD components](https://docs.gitlab.com/ci/components/).

#### Rationale
**Why This Matters:**
- A catalog component is third-party code that executes inside your pipeline with access to the job token, masked variables, and the runner's network position — it is a dependency with credentials, not a convenience snippet
- Referencing a floating version such as `latest` or a branch name means an upstream change lands in your production pipeline with no review, no approval, and no record of what changed
- Pinning to a commit SHA makes the resolved content reproducible and blocks a compromised or careless maintainer from swapping the code behind a moving reference; a release tag is the acceptable fallback where SHA pinning is impractical
- Catalog badges are provenance signals with different meanings: GitLab-Maintained components are maintained by GitLab, GitLab Partner components are published by partners on an as-is basis without GitLab support, and self-managed instances can show a verified-creator badge for namespaces the administrator has verified — none of these is a security audit of the component's behavior

**Attack Prevented:** Supply-chain injection through mutable component references, adoption of a look-alike or partner-published component with no support commitment, credential theft by a component that reads job variables it does not need

#### ClickOps Implementation

**Step 1: Review Before Adoption**
1. Navigate to the CI/CD Catalog and open the component you intend to use
2. Record its badge — GitLab-Maintained, GitLab Partner (as-is, unsupported by GitLab), or verified creator on self-managed — and treat a partner or unbadged component as requiring deeper review
3. Open the component's source project and read its templates: check whether it reads CI/CD variables it does not need, makes outbound network calls, or executes downloaded scripts
4. Reject or fork any component whose behavior you cannot explain from its source

**Step 2: Pin Every Reference**
1. Reference components by commit SHA wherever possible — a 40-character SHA is the only genuinely immutable reference
2. Where a SHA is impractical, use a published release tag; never reference `latest` or a branch name in any project that builds or deploys production code
3. Record approved components and their pinned versions in an internal allowlist so reviewers have something to compare a merge request against

**Step 3: Control Upgrades**
1. Treat a version bump as a code change: review the upstream diff between the pinned SHA and the new one before merging
2. Route component upgrades through the merge request approval policy from control 1.4 so a second person sees the change
3. Re-review the component's source at upgrade time, not only at first adoption

#### Validation & Testing
1. Use group-level code search for component include statements and confirm no result resolves to `latest` or a branch name
2. Confirm every component reference in projects that deploy to production resolves to a commit SHA
3. Pick one pinned component and verify the SHA in your configuration matches a commit that actually exists in the upstream source project
4. Review the approved-component allowlist against what pipelines actually reference each quarter and reconcile the difference

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC8.1 | Change authorization for third-party code |
| **NIST 800-53** | SR-3 | Supply chain controls and processes |
| **NIST 800-53** | CM-7 | Least functionality in pipeline configuration |

---

## 3. Runner Security

### 3.1 Isolate CI/CD Runners

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-7

#### Description
Deploy isolated runners for different trust levels and environments.

#### Rationale
**Why This Matters:**
- Runners execute arbitrary pipeline code, so a shared runner that touches production is a single point an attacker can use to pivot from any project to sensitive systems
- Segmenting runners by trust level and environment ensures a compromised low-trust job cannot reach production networks or credentials
- Ephemeral, single-use runner containers prevent one job from tampering with the environment of the next job on the same host

**Attack Prevented:** Runner-based lateral movement, cross-job contamination, production network pivot, persistent runner compromise

#### Implementation

**Step 1: Create Runner Tiers**
1. **shared-runners** -- general use, Docker executor, ephemeral containers
2. **group-runners** -- team-specific, isolated per business unit
3. **project-runners** -- sensitive projects, dedicated to single project
4. **production-runners** -- deployment only, network access to production, limited users

{% include pack-code.html vendor="gitlab" section="3.1" %}

---

### 3.2 Rotate Runner Tokens

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5(1)

#### Description
Implement regular runner token rotation to limit exposure from compromised tokens.

#### Rationale
**Why This Matters:**
- A runner registration or authentication token lets anyone register a runner that receives and executes pipeline jobs, including access to CI/CD secrets
- Regular rotation ensures a leaked token has a short useful lifespan instead of granting indefinite access
- Resetting tokens immediately on suspected exposure invalidates any rogue runners an attacker may have registered

**Attack Prevented:** Rogue runner registration, token theft, unauthorized job execution, secret harvesting

#### ClickOps Implementation

**Step 1: Reset Runner Token**
1. Navigate to: **Admin → CI/CD → Runners → [Runner]**
2. Click **Reset registration token**
3. Update runner configuration with new token

{% include pack-code.html vendor="gitlab" section="3.2" %}

---

## 4. Repository Security

### 4.1 Enable Push Rules

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-3

#### Description
Configure push rules to prevent accidental secret commits and enforce commit hygiene.

#### Rationale
**Why This Matters:**
- Secrets accidentally committed to a repository remain in Git history even after deletion and are frequently harvested by attackers scanning repos
- Push rules that block secret files and verify author identity stop credential leaks and commit spoofing at the point of push
- Combining push rules with secret detection in the pipeline provides defense in depth against hardcoded credentials reaching the repository

**Attack Prevented:** Secret leakage in commits, credential harvesting, commit author spoofing

#### ClickOps Implementation

**Step 1: Configure Project Push Rules**
1. Navigate to: **Project → Settings → Repository → Push rules**
2. Enable:
   - **Prevent pushing secret files:** Enable
   - **Reject unsigned commits:** Enable (L2)
   - **Check author email against verified:** Enable

**Step 2: Configure Secret Detection**

See the CLI Code Pack below for the .gitlab-ci.yml secret detection configuration.

{% include pack-code.html vendor="gitlab" section="4.1" %}

### 4.2 Enable Commit Signing

**Profile Level:** L2 (Walk)
**NIST 800-53:** AU-10

#### Description
Require GPG or SSH signed commits to verify commit authorship.

#### Rationale
**Why This Matters:**
- Git lets anyone set an arbitrary author name and email, so unsigned commits provide no real proof of who wrote the code
- Requiring cryptographically signed commits verifies that changes come from a known, key-holding identity rather than an impersonator
- Rejecting unsigned commits and unverified users blocks an attacker from forging history or attributing malicious code to a trusted developer

**Attack Prevented:** Commit spoofing, author impersonation, unauthorized code attribution, repository history forgery

#### ClickOps Implementation

**Step 1: Configure Signature Requirements**
1. Navigate to: **Project → Settings → Repository → Push rules**
2. Enable: **Reject unsigned commits**
3. Enable: **Reject unverified users**

**Step 2: User Setup**
1. Navigate to: **User Settings → GPG Keys**
2. Add GPG public key
3. Configure git client (see CLI Code Pack below)

{% include pack-code.html vendor="gitlab" section="4.2" %}

---

### 4.3 Enable Secret Push Protection

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.12 |
| NIST 800-53 | IA-5, SC-28 |

#### Description
Block pushes that contain detected secrets at the pre-receive hook, so credentials are rejected before they ever enter repository history. Generally available in GitLab 17.5 (Ultimate). Source: [Secret push protection](https://docs.gitlab.com/user/application_security/secret_detection/secret_push_protection/).

#### Rationale
**Why This Matters:**
- Pipeline-based secret detection runs after the commit has been pushed, so by the time it reports a finding the credential is already in history, already replicated to anyone who fetched, and must be treated as compromised
- Secret push protection evaluates the push at the pre-receive hook and rejects it outright, which means the credential never lands on the server and the developer fixes the commit locally instead of filing an incident
- Purging a leaked secret from history is disruptive and frequently incomplete — forks, mirrors, clones, and cached views retain it — so prevention at push time is materially cheaper than remediation after the fact
- The control complements rather than replaces the push rules in 4.1: push rules match file names and patterns you define, while secret push protection matches known credential formats maintained by GitLab

**Attack Prevented:** Credential leakage into Git history, harvesting of secrets from forks and mirrors after a rushed deletion, costly and error-prone history rewrites following a leak

#### ClickOps Implementation

**Step 1 (Self-Managed): Allow the Feature Instance-Wide**
1. Navigate to: **Admin → Settings → Security and compliance**
2. Enable: **Allow secret push protection**
3. Save changes — this makes the feature available to projects but does not turn it on for them

**Step 2: Enable Per Project**
1. Navigate to: **Project → Secure → Security configuration**
2. Enable: **Secret push protection**
3. Repeat for every project handling production credentials; start with the repositories whose history a leak would be most expensive to clean

**Step 3: Plan the Rollout**
1. Notify developers before enabling — the first rejected push is otherwise reported as a broken remote
2. Document the remediation path: remove the secret from the commit, rotate the exposed credential regardless, and re-push
3. Document the skip mechanism (`secret_push_protection.skip_all` as a push option) and treat every use of it as an event to review, not a routine workaround

#### Validation & Testing
1. In a scratch project with the feature enabled, commit a test value in a recognized credential format (for example a `glpat-` prefixed token) and push; confirm the push is rejected and the message identifies the detected secret
2. Confirm the remote history contains no trace of the rejected commit
3. Push a benign change to the same project and confirm normal pushes are unaffected
4. Review use of the skip push option periodically and confirm each instance had a documented justification

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Protection of credentials and logical access |
| **NIST 800-53** | IA-5 | Authenticator management |
| **NIST 800-53** | SC-28 | Protection of information at rest |

---

## 5. Secrets Management

### 5.1 Use External Secrets Management

**Profile Level:** L2 (Walk)
**NIST 800-53:** SC-28

#### Description
Integrate with external secrets managers instead of storing secrets in GitLab.

#### Rationale
**Why This Matters:**
- Storing secrets directly in GitLab couples their security to GitLab's access model and risks exposure through logs, exports, or a platform compromise
- An external secrets manager like Vault issues short-lived, dynamically generated credentials that are far harder to steal and reuse
- Centralizing secrets externally provides a single audited place to rotate, revoke, and govern access independent of the CI/CD platform

**Attack Prevented:** Static secret theft, credential reuse, broad exposure from a platform compromise, unaudited secret access

#### HashiCorp Vault Integration

{% include pack-code.html vendor="gitlab" section="5.1" %}

**Step 1: Configure Vault Integration**
1. Navigate to: **Project → Settings → CI/CD → Secure Files**
2. Configure JWT authentication with Vault
3. Map CI/CD variables to Vault paths

---

## 6. Monitoring & Detection

### 6.1 Enable Audit Events

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Configure comprehensive audit logging for GitLab operations.

#### Rationale
**Why This Matters:**
- Without comprehensive audit logging, malicious actions such as repository deletion, permission changes, or runner registration go undetected
- Streaming audit events to a SIEM preserves a tamper-resistant record off-platform, surviving attempts to cover tracks inside GitLab
- Alerting on high-risk events enables fast detection and response to account takeover and privilege abuse before damage spreads

**Attack Prevented:** Undetected privilege abuse, log tampering, delayed breach detection, repository destruction

#### ClickOps Implementation

**Step 1: Configure Audit Event Streaming**
1. Navigate to: **Group → Security & Compliance → Audit events**
2. Enable streaming to SIEM
3. Configure: All event types

**Step 2: Alert on Critical Events**
- Repository deletion
- Protected branch modification
- Runner registration
- Admin privilege changes

#### Detection Queries

See the DB Code Pack below for SQL queries that detect unusual repository cloning and pipeline variable modifications.

{% include pack-code.html vendor="gitlab" section="6.1" %}

---

## 7. AI Assistant Governance (GitLab Duo)

### 7.1 Govern GitLab Duo Availability

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.8 |
| NIST 800-53 | CM-7, SA-9 |

#### Description
Make an explicit decision about where GitLab Duo may operate, using the instance-level availability setting and its group and project cascade, instead of inheriting the on-by-default posture. Source: [Turn GitLab Duo on or off](https://docs.gitlab.com/user/gitlab_duo/turn_on_off/).

#### Rationale
**Why This Matters:**
- GitLab Duo is on by default, so an organization that has never discussed it has already granted an AI assistant access to source code, issues, and merge request content across the instance — the absence of a decision is itself a decision
- The availability setting has three states (always on, off by default, always off) and cascades down the group and project hierarchy, so setting the posture once at the top establishes a default for every future project rather than requiring per-project cleanup forever
- Duo Core is controlled by its own checkbox in the same configuration, so turning Duo "off" without checking that box can leave functionality enabled that reviewers assumed was disabled
- Experiment and beta features operate under different terms than generally available features; leaving them off until legal and security have reviewed them prevents proprietary code from flowing through paths nobody evaluated

**Attack Prevented:** Unreviewed exposure of proprietary source code to AI processing, shadow AI adoption inside individual projects, silent expansion of data handling as new experimental features ship

#### ClickOps Implementation

**Step 1: Set the Instance Posture**
1. Navigate to: **Admin → GitLab Duo → Change configuration**
2. Set availability to the state your organization has actually decided on: **Always on**, **Off by default**, or **Always off**
3. Prefer **Off by default** where you intend to allow Duo only in specific groups — it makes enablement an explicit, attributable act
4. Review the **Duo Core** checkbox in the same configuration and set it deliberately rather than leaving it at its shipped value

**Step 2: Control Experimental Features**
1. In the same configuration, locate the experiment and beta features toggle
2. Leave it disabled until the data handling terms for those features have been reviewed
3. Re-review after each GitLab upgrade, since the set of features behind that toggle changes between releases

**Step 3: Cascade to Groups and Projects**
1. Navigate to: **Group → Settings → General → GitLab Duo features**
2. Enable Duo only for groups whose repositories you are comfortable exposing to AI processing
3. Confirm the setting at project level for any project that handles regulated or customer-sensitive code
4. Keep public and fork-accepting projects out of scope by default — see control 7.2 for why

#### Validation & Testing
1. Sign in as a standard user in a project where Duo should be unavailable and confirm Duo Chat and code suggestions do not appear
2. Sign in to a project where Duo is intentionally enabled and confirm it works, proving the cascade is scoped rather than globally broken
3. Review group-level GitLab Duo settings across the instance and list any group that has overridden the instance default
4. After each upgrade, revisit **Admin → GitLab Duo → Change configuration** and confirm availability, Duo Core, and the experiment toggle still match the documented decision

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Authorized access to information assets |
| **NIST 800-53** | CM-7 | Least functionality |
| **NIST 800-53** | SA-9 | External information system services |

---

### 7.2 Treat Repository Content as Untrusted GitLab Duo Input

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.1 |
| NIST 800-53 | SI-10, SA-9 |

#### Description
Assume anything Duo reads from a repository may contain instructions written by an attacker, and constrain Duo's scope and output handling accordingly. Source: [Remote prompt injection in GitLab Duo](https://www.legitsecurity.com/blog/remote-prompt-injection-in-gitlab-duo).

#### Rationale
**Why This Matters:**
- Duo composes answers from merge request descriptions, comments, commit messages, and source files — every one of which is attacker-controllable in any project that accepts outside contributions, so untrusted text reaches the assistant by design
- Legit Security demonstrated this concretely: instructions hidden with Base16 encoding and white-text KaTeX rendering were followed by Duo, and because responses streamed raw HTML, injected image tags caused the contents of private merge request diffs to be sent to an attacker-controlled server
- GitLab remediated the exfiltration path by blocking rendering of unsafe external HTML in Duo responses, but the underlying problem — that untrusted repository text can become instructions — is a property of how assistants read context, not a single bug that a patch retires
- Because the residual risk sits in scope and review rather than in the product's code, the durable controls are limiting which projects Duo can read and keeping a human between Duo's output and anything that merges

**Attack Prevented:** Remote prompt injection through merge request and commit content, exfiltration of private source code via markup rendered in assistant responses, attacker-steered code suggestions accepted without review

#### ClickOps Implementation

**Step 1: Scope Duo to Trusted Projects**
1. Using the group and project settings from control 7.1, disable Duo in projects that accept merge requests from outside your organization
2. Prioritize public projects, community-contribution repositories, and any project where fork pipelines run
3. Document which groups are in scope so the decision survives staff turnover

**Step 2: Stay Patched**
1. Confirm your instance is running a GitLab version that includes the fix blocking unsafe external HTML rendering in Duo responses
2. On self-managed, treat Duo-related security fixes as a reason to upgrade promptly — they ship with GitLab releases and do not reach you until you upgrade
3. Track GitLab release announcements for further AI-related security changes

**Step 3: Keep a Human in the Loop**
1. Never let Duo output flow into a merge without human approval — the merge request approval policy from control 1.4 is what enforces this structurally
2. Do not grant automation the ability to act on Duo output without review
3. Treat Duo summaries of a merge request as a convenience, not as evidence that the merge request was reviewed

**Step 4: Train Reviewers**
1. Teach reviewers that hidden content is a real technique: invisible or same-colour text, unusual encodings, and rendering tricks in descriptions and comments
2. Instruct reviewers to be suspicious when a Duo answer contains links or images they did not expect, and to report rather than click
3. Add "check for hidden instructions in contributed text" to the review checklist for projects that accept outside contributions

#### Validation & Testing
1. In a scratch project, place text containing hidden instructions in a merge request description, ask Duo to summarize the merge request, and confirm the response neither follows the instructions nor emits external image or link markup
2. Confirm the instance version in **Admin → Overview** includes the fix for unsafe external HTML rendering
3. Confirm Duo is unavailable in at least one representative fork-accepting project, matching the scoping decision from Step 1
4. Sample recent merges in Duo-enabled projects and confirm each carried a human approval, not an automated one

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.8 | Prevention of unauthorized or malicious software behavior |
| **NIST 800-53** | SI-10 | Information input validation |
| **NIST 800-53** | SA-9 | External information system services |

---

## 8. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | GitLab Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO enforcement | 1.1 |
| CC6.1 | Secret push protection | 4.3 |
| CC6.2 | Project permissions | 1.2 |
| CC6.3 | Fine-grained job token permissions | 2.4 |
| CC6.8 | Duo prompt injection controls | 7.2 |
| CC7.1 | Pipeline execution policies | 2.5 |
| CC7.2 | Audit events | 6.1 |
| CC8.1 | Protected branches | 1.2 |
| CC8.1 | Merge request approval policies | 1.4 |
| CC8.1 | CI/CD catalog component pinning | 2.6 |

### NIST 800-53 Mapping

| Control | GitLab Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | SSO with MFA | 1.1 |
| AC-6 | Role-based access | 1.2 |
| AC-6 | Fine-grained job token permissions | 2.4 |
| CM-3 | Push rules | 4.1 |
| CM-3 | Merge request approval policies | 1.4 |
| CM-7 | Pipeline execution policies | 2.5 |
| CM-7 | GitLab Duo availability | 7.1 |
| SR-3 | CI/CD catalog component pinning | 2.6 |
| SI-10 | Duo untrusted input handling | 7.2 |
| IA-5 | Secret push protection | 4.3 |
| SC-28 | CI/CD variable protection | 2.1 |

---

## Appendix A: Edition Compatibility

| Control | Free | Premium | Ultimate |
|---------|------|---------|----------|
| SAML SSO | ❌ | ✅ | ✅ |
| Push Rules | Basic | ✅ | ✅ |
| Audit Events | ❌ | ✅ | ✅ |
| SAST/DAST | ❌ | ❌ | ✅ |
| Compliance Dashboard | ❌ | ❌ | ✅ |
| Fine-grained Job Token Permissions | ✅ | ✅ | ✅ |
| Secret Push Protection | ❌ | ❌ | ✅ |
| Merge Request Approval Policies | ❌ | ❌ | ✅ |
| Pipeline Execution Policies | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official GitLab Documentation:**
- [Trust Center](https://trust.gitlab.com/)
- [GitLab Documentation](https://docs.gitlab.com/)
- [Security Hardening](https://docs.gitlab.com/security/hardening/)
- [GitLab Security](https://about.gitlab.com/security/)

**API & Developer Tools:**
- [REST API Reference](https://docs.gitlab.com/api/rest/)
- [GraphQL API](https://docs.gitlab.com/api/graphql/)
- [GitLab CLI (`glab`)](https://gitlab.com/gitlab-org/cli)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3, ISO/IEC 27001:2022, ISO 27017, ISO 27018, PCI DSS (SAQ D) -- via [Trust Center](https://trust.gitlab.com/)
- [External Audits, Certifications, and Attestations](https://handbook.gitlab.com/handbook/security/security-assurance/security-compliance/certifications/)

**Security Incidents:**
- **CVE-2023-7028 (Jan 2024):** Critical account takeover vulnerability (CVSS 10.0) via password reset emails to unverified addresses; actively exploited in the wild. Patched in GitLab 16.7.2+.
- **Red Hat Consulting GitLab Instance Breach (Sep 2025):** Attacker accessed Red Hat's self-managed GitLab CE instance, exposing consulting data for organizations such as Bank of America, T-Mobile, and U.S. government agencies. GitLab confirmed no breach of its managed SaaS infrastructure.

**Community Resources:**
- [CIS Software Supply Chain Security Benchmark](https://www.cisecurity.org/benchmark/software_supply_chain_security)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.1 | draft | Cheat-sheet cell repair: added missing Attack Prevented line(s) to §1.1 (no content-facts changed) | Claude Code (Fable 5) |
| 2026-08-03 | 0.2.0 | draft | Add fine-grained job token permissions (2.4), pipeline execution policies (2.5), CI/CD catalog component trust (2.6), merge request approval policies (1.4), secret push protection (4.3), and new AI Assistant Governance section (7.1 Duo availability, 7.2 Duo prompt injection); correct 1.3 token expiry to mandatory-expiry model (365-day default, 400-day ceiling); renumber Compliance Quick Reference to 8 | Claude Code (Sonnet 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2026-02-19 | 0.1.2 | draft | Migrate all remaining inline code to Code Packs (2.1, 2.3, 3.1, 4.1, 4.2, 6.1); zero inline blocks | Claude Code (Opus 4.6) |
| 2026-02-19 | 0.1.1 | draft | Migrate inline code to CLI Code Packs (1.1, 3.1, 3.2, 5.1) | Claude Code (Opus 4.6) |
| 2025-12-14 | 0.1.0 | draft | Initial GitLab hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
