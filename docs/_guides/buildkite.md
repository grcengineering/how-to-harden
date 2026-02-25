---
layout: guide
title: "Buildkite Hardening Guide"
vendor: "Buildkite"
slug: "buildkite"
tier: "2"
category: "DevOps"
description: "CI/CD platform hardening for Buildkite including SAML SSO, team permissions, agent security, and pipeline controls"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Buildkite is a CI/CD platform enabling organizations to run fast, secure builds on their own infrastructure. As a platform managing build pipelines and deployment workflows, Buildkite security configurations directly impact software supply chain security.

### Intended Audience
- Security engineers managing CI/CD platforms
- Platform engineers configuring Buildkite
- DevOps teams managing pipelines
- GRC professionals assessing build security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Buildkite security including SAML SSO, team permissions, agent security, and pipeline controls.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Agent Security](#3-agent-security)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for Buildkite users.

#### Prerequisites
- Buildkite organization admin access
- Enterprise or Business tier
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Organization Settings** → **SSO**
2. Select SAML provider type

**Step 2: Configure SAML**
1. Configure IdP settings:
   - SSO URL
   - Entity ID
   - Certificate
2. Configure attribute mapping
3. Map groups to teams

**Step 3: Test and Enforce**
1. Test SSO authentication
2. Enable SSO enforcement
3. Document admin fallback

**Time to Complete:** ~1-2 hours

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="1.1" %}

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Buildkite users.

#### ClickOps Implementation

**Step 1: Enable 2FA Requirement**
1. Navigate to: **Organization Settings** → **Security**
2. Enable **Require two-factor authentication**
3. All users must configure 2FA

**Step 2: Configure via IdP**
1. Enable MFA in identity provider
2. Use phishing-resistant methods for admins
3. All SSO users subject to IdP MFA

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="1.2" %}

---

## 2. Access Controls

### 2.1 Configure Team Permissions

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Buildkite teams.

#### ClickOps Implementation

**Step 1: Create Teams**
1. Navigate to: **Organization Settings** → **Teams**
2. Create teams by function
3. Define team permissions

**Step 2: Assign Pipeline Access**
1. Assign pipelines to teams
2. Configure permission levels:
   - Read & Build Access
   - Full Access
3. Apply least privilege

**Step 3: Regular Access Reviews**
1. Review team membership quarterly
2. Update access as needed
3. Remove inactive members

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="2.1" %}

---

### 2.2 Configure Pipeline Permissions

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control access to specific pipelines.

#### ClickOps Implementation

**Step 1: Configure Pipeline Visibility**
1. Set pipeline visibility per pipeline
2. Restrict sensitive pipelines
3. Use team-based access

**Step 2: Configure Build Permissions**
1. Control who can trigger builds
2. Restrict manual builds on production
3. Audit build triggers

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="2.2" %}

---

### 2.3 Limit Admin Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review organization owners/admins
2. Document admin access
3. Identify unnecessary privileges

**Step 2: Apply Restrictions**
1. Limit admin to 2-3 users
2. Require 2FA/SSO for admins
3. Monitor admin activity

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="2.3" %}

---

## 3. Agent Security

### 3.1 Configure Agent Tokens

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Securely manage agent registration tokens.

#### ClickOps Implementation

**Step 1: Create Scoped Tokens**
1. Navigate to: **Agents** → **Agent Tokens**
2. Create tokens per environment
3. Limit token scope

**Step 2: Secure Tokens**
1. Store tokens securely
2. Rotate tokens regularly
3. Revoke unused tokens

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="3.1" %}

---

### 3.2 Configure Agent Clusters

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Isolate agents by environment or sensitivity.

#### ClickOps Implementation

**Step 1: Create Agent Clusters**
1. Create separate clusters for:
   - Production deployments
   - Development builds
   - Security-sensitive builds
2. Tag agents appropriately

**Step 2: Configure Pipeline Targets**
1. Target pipelines to specific clusters
2. Restrict production access
3. Audit cluster assignments

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="3.2" %}

---

### 3.3 Secure Agent Infrastructure

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Secure agent host infrastructure.

#### ClickOps Implementation

**Step 1: Harden Agent Hosts**
1. Use ephemeral agents where possible
2. Minimize installed software
3. Apply OS hardening

**Step 2: Network Security**
1. Restrict agent network access
2. Use private networks
3. Monitor agent traffic

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="3.3" %}

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logging

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs.

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Organization Settings** → **Audit Log**
2. Review logged events
3. Configure retention

**Step 2: Monitor Events**
1. User authentication
2. Pipeline changes
3. Permission modifications
4. Agent token usage

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="4.1" %}

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Buildkite Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Team permissions | [2.1](#21-configure-team-permissions) |
| CC6.7 | Agent tokens | [3.1](#31-configure-agent-tokens) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Buildkite Control | Guide Section |
|---------|-------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | 2FA | [1.2](#12-enforce-two-factor-authentication) |
| AC-6 | Team permissions | [2.1](#21-configure-team-permissions) |
| SC-12 | Agent tokens | [3.1](#31-configure-agent-tokens) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |

---

## Appendix A: References

**Official Buildkite Documentation:**
- [Buildkite Trust Center](https://trust.buildkite.com/)
- [Buildkite Security](https://buildkite.com/about/security/)
- [Buildkite Documentation](https://buildkite.com/docs)
- [Security Controls Best Practices](https://buildkite.com/docs/pipelines/best-practices/security-controls)
- [SSO Configuration](https://buildkite.com/docs/integrations/sso)
- [Team Permissions](https://buildkite.com/docs/team-management/permissions)
- [Securing Your Agent](https://buildkite.com/docs/agent/v3/securing)

**API Documentation:**
- [Buildkite APIs](https://buildkite.com/docs/apis)
- [REST API Reference](https://buildkite.com/docs/apis/rest-api)
- [GraphQL API](https://buildkite.com/docs/apis/graphql-api)

**Compliance Frameworks:**
- SOC 2 Type II (annual audit covering Pipelines, Package Registries, and Test Engine) — via [Buildkite Trust Center](https://trust.buildkite.com/)

**Security Incidents:**
- No major public security breaches identified. Buildkite maintains annual third-party penetration testing and a private HackerOne bug bounty program.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, teams, and agent security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
