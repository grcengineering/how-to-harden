---
layout: guide
title: "Terraform Cloud Hardening Guide"
vendor: "Terraform Cloud"
slug: "terraform-cloud"
tier: "3"
category: "IaC"
description: "IaC platform security for workspace variables, team access, and run triggers"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---


## Overview

Terraform Cloud state files containing plaintext secrets, cloud provider credentials, and workspace configurations make IaC platforms high-value targets. Vault-backed dynamic credentials via OIDC federation represent best practice for eliminating stored secrets. State file exposure reveals database passwords and API keys; malicious provider backdoors infrastructure.

### Intended Audience
- Security engineers managing IaC platforms
- Platform engineers configuring Terraform
- GRC professionals assessing infrastructure compliance
- DevOps teams implementing secure IaC


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Terraform Cloud security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Workspace Security](#2-workspace-security)
3. [State File Security](#3-state-file-security)
4. [Secrets Management](#4-secrets-management)
5. [Monitoring & Detection](#5-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML single sign-on with MFA through your corporate IdP for all Terraform Cloud organization access, and scope team API tokens to least privilege with expiration and regular rotation.

#### Rationale
**Why This Matters:**
- Centralizes Terraform Cloud authentication in your IdP so MFA and conditional access apply to every user login
- Local logins and long-lived personal tokens bypass IdP controls and are prime targets for credential stuffing and phishing
- Enforcing SSO with SCIM provisioning deprovisions departed users automatically, eliminating orphaned accounts that retain infrastructure access
- Terraform Cloud can plan and apply changes to production cloud accounts, so a single compromised login can rewrite or destroy infrastructure

**Attack Prevented:** Credential theft, phishing, MFA bypass, orphaned-account access, token abuse

#### ClickOps Implementation

**Step 1: Configure SSO (Business)**
1. Navigate to: **Organization → Settings → SSO**
2. Configure SAML with your IdP
3. Enforce SSO for all users

**Step 2: Configure Team Tokens**
1. Create team tokens with minimum permissions
2. Set expiration
3. Rotate quarterly

---

### 1.2 Team-Based Access Control

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Define teams that map to job functions and grant each team only the minimum workspace permissions it needs (for example, plan-only for developers, view-only for auditors) rather than broad organization-wide access.

#### Rationale
**Why This Matters:**
- Least-privilege team permissions ensure a compromised account or token can only affect the workspaces it legitimately needs
- Separating plan from apply prevents developers from pushing unreviewed changes directly to production infrastructure
- Role-mapped teams make access reviews and audits straightforward and reduce standing privilege
- Over-broad "owners" membership turns any single account compromise into full control of every workspace and its cloud credentials

**Attack Prevented:** Privilege escalation, lateral movement, unauthorized infrastructure changes, insider misuse

#### ClickOps Implementation

**Step 1: Define Teams**

| Team | Permissions |
|------|-------------|
| owners | Full organization access |
| platform | Manage workspaces |
| developers | Plan only (no apply) |
| read-only | View only |

**Step 2: Assign Workspace Permissions**
1. Navigate to: **Workspace → Team Access**
2. Grant minimum permissions per team

---


{% include pack-code.html vendor="terraform-cloud" section="1.2" %}

## 2. Workspace Security

### 2.1 Configure Workspace Restrictions

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-3

#### Description
Harden workspace execution settings by using remote execution, disabling auto-apply for production, and requiring pull-request review with branch protection before any VCS-triggered apply.

#### Rationale
**Why This Matters:**
- Disabling auto-apply forces human review of every plan before it mutates production infrastructure
- Requiring PR review and branch protection ensures changes are peer-reviewed and traceable to an approved commit
- Speculative plans surface the impact of a change before it is merged, catching destructive or misconfigured edits early
- Without these gates, a single malicious or accidental commit to the connected VCS branch can be applied to production automatically

**Attack Prevented:** Unauthorized and unreviewed infrastructure changes, poisoned-pipeline execution, accidental destruction, malicious commits

#### ClickOps Implementation

**Step 1: Execution Mode**
1. Navigate to: **Workspace → Settings → General**
2. Configure: **Execution Mode:** Remote
3. Enable: **Auto-apply:** Disabled for production

**Step 2: VCS Integration Security**
1. Configure branch protection
2. Require PR review before apply
3. Enable speculative plans

---


{% include pack-code.html vendor="terraform-cloud" section="2.1" %}

### 2.2 Sentinel Policy Enforcement

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-7

#### Description
Use Sentinel policy-as-code to define and enforce guardrails (such as required tags, allowed regions, instance limits, and prohibited public access) that every run must satisfy before apply.

#### Rationale
**Why This Matters:**
- Policy-as-code enforces security and compliance guardrails automatically on every run, independent of reviewer vigilance
- Hard-mandatory policies block non-compliant infrastructure such as public buckets, unencrypted volumes, and open security groups before it is provisioned
- Codified policies provide consistent, auditable evidence that controls are applied uniformly across all workspaces
- Without policy enforcement, drift and misconfiguration depend entirely on manual review, which is error-prone at scale

**Attack Prevented:** Misconfiguration, compliance drift, public exposure of resources, unencrypted data stores

#### Implementation

{% include pack-code.html vendor="terraform-cloud" section="2.2" %}

## 3. State File Security

### 3.1 State File Protection

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Ensure Terraform state is encrypted at rest and restrict who can read or download it, since state holds the full record of provisioned infrastructure along with any secrets it captured.

#### Rationale
**Why This Matters:**
- State files contain plaintext secrets
- Database passwords, API keys exposed
- State file = infrastructure blueprint

**Attack Scenario:** State file exposure reveals database passwords and API keys; malicious provider backdoors infrastructure.

#### ClickOps Implementation

**Step 1: Enable State Encryption**
- Terraform Cloud encrypts state at rest by default
- Verify encryption settings

**Step 2: Restrict State Access**
1. Navigate to: **Workspace → Settings → General**
2. Configure: **Terraform State:** API access restricted
3. Limit who can view/download state

---

### 3.2 Sensitive Variable Handling

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Mark workspace and variable-set values that contain secrets as sensitive so Terraform Cloud masks them in the UI, run logs, and API responses and never exposes them in plan output.

#### Rationale
**Why This Matters:**
- Marking variables sensitive prevents credentials and keys from appearing in plan output, run logs, and the UI
- Unmarked secrets leak into CI/CD logs and audit trails that are visible to far more users than the secret itself
- Sensitive variable sets let you centrally manage and rotate shared credentials instead of duplicating them per workspace
- Leaked variable values can grant attackers direct access to the cloud accounts and services Terraform manages

**Attack Prevented:** Secret exposure in logs, credential leakage, downstream cloud-account compromise

#### Implementation

{% include pack-code.html vendor="terraform-cloud" section="3.2" %}

---

## 4. Secrets Management

### 4.1 Dynamic Credentials (OIDC)

**Profile Level:** L2 (Walk)
**NIST 800-53:** IA-5

#### Description
Use OIDC workload identity instead of static credentials.

#### Rationale
**Why This Matters:**
- OIDC workload identity issues short-lived, automatically expiring credentials per run instead of long-lived stored secrets
- Eliminating static cloud keys removes the highest-value secret an attacker could exfiltrate from a workspace or state file
- Federated trust is scoped to specific workspaces and run phases, so credentials cannot be replayed outside the intended context
- Long-lived access keys in workspace variables never expire, are hard to rotate, and grant standing access if leaked

**Attack Prevented:** Credential theft, key exfiltration, replay attacks, standing-access abuse

#### AWS Configuration

See the Terraform pack below for OIDC provider and workspace variable configuration.

{% include pack-code.html vendor="terraform-cloud" section="4.1" %}

---

### 4.2 Vault Integration

**Profile Level:** L2 (Walk)

#### Description
Integrate HashiCorp Vault so Terraform pulls secrets and dynamically generated, short-lived credentials at run time rather than storing them as static workspace variables.

#### Rationale
**Why This Matters:**
- Vault-generated dynamic secrets are short-lived and scoped, drastically shrinking the window an exposed credential is usable
- Sourcing secrets from Vault keeps them out of workspace variables and state files where they would otherwise persist in plaintext
- Centralized secret management provides unified rotation, leasing, and audit logging across all Terraform runs
- Static long-lived credentials stored in the platform are a single point of failure that an attacker can harvest and reuse

**Attack Prevented:** Secret sprawl, credential theft, static-credential reuse, plaintext secret exposure

#### Implementation

{% include pack-code.html vendor="terraform-cloud" section="4.2" %}

---

## 5. Monitoring & Detection

### 5.1 Audit Logging

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Enable Terraform Cloud audit logging and forward the events to your SIEM so authentication, authorization, workspace, run, and variable changes are recorded and monitored for anomalies.

#### Rationale
**Why This Matters:**
- Comprehensive audit logs are required to detect unauthorized access, privilege changes, and suspicious run activity in time to respond
- Forwarding logs to a SIEM enables alerting and correlation that the platform console alone cannot provide
- Records of who changed which workspace, variable, or run create the accountability needed for incident response and compliance evidence
- Without centralized logging, attacker actions such as rogue token creation or state tampering can go undetected until damage is done

**Attack Prevented:** Undetected intrusion, privilege abuse, repudiation, delayed breach detection

#### Detection Focus

See the DB pack below for audit detection queries.

---


{% include pack-code.html vendor="terraform-cloud" section="5.1" %}

## Appendix A: Edition Compatibility

| Control | Free | Team | Business | Enterprise |
|---------|------|------|----------|------------|
| SSO | ❌ | ❌ | ✅ | ✅ |
| Sentinel | ❌ | ❌ | ✅ | ✅ |
| Audit Logs | ❌ | ❌ | ✅ | ✅ |
| OIDC | ✅ | ✅ | ✅ | ✅ |

---

## Appendix B: References

**Official HashiCorp Documentation:**
- [Security at HashiCorp](https://www.hashicorp.com/en/trust/security)
- [Terraform Cloud Documentation](https://developer.hashicorp.com/terraform/cloud-docs)
- [Recommended Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices)

**API & Developer Tools:**
- [Terraform Cloud API Documentation](https://developer.hashicorp.com/terraform/cloud-docs/api-docs)
- [Terraform CLI](https://developer.hashicorp.com/terraform/cli)
- [Terraform Registry](https://registry.terraform.io/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27017, ISO 27018 -- via [HashiCorp Compliance Overview](https://www.hashicorp.com/en/trust/compliance)
- Audit reports available to customers/prospects under NDA (contact customertrust@hashicorp.com)

**Security Incidents:**
- (2021) HashiCorp's GPG private key used for signing product download hashes was exposed in the Codecov supply-chain attack (January-April 2021). The key was revoked and replaced.
- (2025) Terraform Enterprise access control vulnerability (HCSEC-2025-34) allowed users with insufficient permissions to create state versions. Fixed in versions 1.1.1 and 1.0.3. No data breach reported.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Terraform Cloud hardening guide | Claude Code (Opus 4.5) |
