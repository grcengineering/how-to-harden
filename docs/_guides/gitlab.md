---
layout: guide
title: "GitLab Hardening Guide"
vendor: "GitLab"
slug: "gitlab"
tier: "2"
category: "DevOps"
description: "DevOps platform security for CI/CD pipelines, repository access, and runners"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
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
7. [Compliance Quick Reference](#7-compliance-quick-reference)

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
1. Navigate to: **Admin → Settings → General → Account and limit**
2. Configure:
   - **Maximum allowable lifetime for access tokens:** 90 days
   - **Limit project access token creation:** Enable

**Step 2: Disable API Scope for Non-Essential Tokens**
- Audit tokens with `api` scope
- Replace with minimal scopes (read_repository, write_repository)

---


{% include pack-code.html vendor="gitlab" section="1.3" %}

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

## 7. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | GitLab Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO enforcement | 1.1 |
| CC6.2 | Project permissions | 1.2 |
| CC7.2 | Audit events | 6.1 |
| CC8.1 | Protected branches | 1.2 |

### NIST 800-53 Mapping

| Control | GitLab Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | SSO with MFA | 1.1 |
| AC-6 | Role-based access | 1.2 |
| CM-3 | Push rules | 4.1 |
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
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2026-02-19 | 0.1.2 | draft | Migrate all remaining inline code to Code Packs (2.1, 2.3, 3.1, 4.1, 4.2, 6.1); zero inline blocks | Claude Code (Opus 4.6) |
| 2026-02-19 | 0.1.1 | draft | Migrate inline code to CLI Code Packs (1.1, 3.1, 3.2, 5.1) | Claude Code (Opus 4.6) |
| 2025-12-14 | 0.1.0 | draft | Initial GitLab hardening guide | Claude Code (Opus 4.5) |
