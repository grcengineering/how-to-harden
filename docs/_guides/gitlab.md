---
layout: guide
title: "GitLab Hardening Guide"
vendor: "GitLab"
slug: "gitlab"
tier: "2"
category: "DevOps"
description: "DevOps platform security for CI/CD pipelines, repository access, and runners"
version: "0.1.0"
maturity: "draft"
last_updated: "2026-02-19"
---


## Overview

GitLab is used by **50%+ of Fortune 100** with 30,000+ paying customers. Integrated CI/CD pipelines, container registry, and secrets management concentrate attack surface. Runner tokens, project API keys, and OAuth integrations with cloud providers enable code injection and infrastructure access. A compromised GitLab instance provides attackers with source code, CI/CD secrets, and deployment capabilities.

### Intended Audience
- Security engineers hardening GitLab instances
- DevOps engineers configuring CI/CD security
- GRC professionals assessing DevSecOps compliance
- Platform teams managing GitLab infrastructure

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

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

**Profile Level:** L1 (Baseline)
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

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure project-level access controls using GitLab's role-based permissions.

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

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Restrict personal access token (PAT) creation and enforce expiration policies.

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

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### Description
Configure CI/CD variables with appropriate protection levels and masking.

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

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7, SI-7

#### Description
Restrict pipeline execution and prevent unauthorized CI/CD modifications.

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

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CM-7

#### Description
Implement secure CI/CD configuration practices. See the CLI Code Pack below for a security-hardened .gitlab-ci.yml example.

{% include pack-code.html vendor="gitlab" section="2.3" %}

---

## 3. Runner Security

### 3.1 Isolate CI/CD Runners

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-7

#### Description
Deploy isolated runners for different trust levels and environments.

#### Implementation

**Step 1: Create Runner Tiers**
1. **shared-runners** -- general use, Docker executor, ephemeral containers
2. **group-runners** -- team-specific, isolated per business unit
3. **project-runners** -- sensitive projects, dedicated to single project
4. **production-runners** -- deployment only, network access to production, limited users

{% include pack-code.html vendor="gitlab" section="3.1" %}

---

### 3.2 Rotate Runner Tokens

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5(1)

#### Description
Implement regular runner token rotation to limit exposure from compromised tokens.

#### ClickOps Implementation

**Step 1: Reset Runner Token**
1. Navigate to: **Admin → CI/CD → Runners → [Runner]**
2. Click **Reset registration token**
3. Update runner configuration with new token

{% include pack-code.html vendor="gitlab" section="3.2" %}

---

## 4. Repository Security

### 4.1 Enable Push Rules

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-3

#### Description
Configure push rules to prevent accidental secret commits and enforce commit hygiene.

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

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AU-10

#### Description
Require GPG or SSH signed commits to verify commit authorship.

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

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-28

#### Description
Integrate with external secrets managers instead of storing secrets in GitLab.

#### HashiCorp Vault Integration

{% include pack-code.html vendor="gitlab" section="5.1" %}

**Step 1: Configure Vault Integration**
1. Navigate to: **Project → Settings → CI/CD → Secure Files**
2. Configure JWT authentication with Vault
3. Map CI/CD variables to Vault paths

---

## 6. Monitoring & Detection

### 6.1 Enable Audit Events

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### Description
Configure comprehensive audit logging for GitLab operations.

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
| 2026-02-19 | 0.1.2 | draft | Migrate all remaining inline code to Code Packs (2.1, 2.3, 3.1, 4.1, 4.2, 6.1); zero inline blocks | Claude Code (Opus 4.6) |
| 2026-02-19 | 0.1.1 | draft | Migrate inline code to CLI Code Packs (1.1, 3.1, 3.2, 5.1) | Claude Code (Opus 4.6) |
| 2025-12-14 | 0.1.0 | draft | Initial GitLab hardening guide | Claude Code (Opus 4.5) |
