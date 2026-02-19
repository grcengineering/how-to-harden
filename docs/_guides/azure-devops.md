---
layout: guide
title: "Azure DevOps Hardening Guide"
vendor: "Azure DevOps"
slug: "azure-devops"
tier: "2"
category: "DevOps"
description: "Microsoft DevOps security for pipelines, service connections, and artifact feeds"
version: "0.1.0"
maturity: "draft"
last_updated: "2026-02-19"
---


## Overview

Azure DevOps provides deep Microsoft ecosystem integration with enterprise-wide pipeline and repository access. Service connections store long-lived credentials for Azure Resource Manager, AWS, and GCP. OIDC federation (workload identity federation) should replace static secrets, but legacy configurations with stored credentials remain vulnerable to supply chain attacks.

### Intended Audience
- Security engineers hardening DevOps infrastructure
- Platform engineers managing Azure DevOps
- GRC professionals assessing CI/CD compliance
- DevOps teams implementing secure pipelines

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Azure DevOps security configurations including authentication, service connection hardening, pipeline security, and variable group management.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Service Connection Security](#2-service-connection-security)
3. [Pipeline Security](#3-pipeline-security)
4. [Repository Security](#4-repository-security)
5. [Variable & Secret Management](#5-variable--secret-management)
6. [Monitoring & Detection](#6-monitoring--detection)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Azure AD Authentication with Conditional Access

**Profile Level:** L1 (Baseline)
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1)

#### Description
Require Azure AD authentication with Conditional Access policies including MFA, device compliance, and location-based restrictions.

#### Rationale
**Why This Matters:**
- Azure DevOps controls code, pipelines, and deployment secrets
- Service connections store cloud provider credentials
- Compromised access enables code injection and infrastructure access

**Attack Scenario:** Compromised service connection credentials enable infrastructure modification; variable group exposure leaks secrets to unauthorized pipelines.

#### ClickOps Implementation

**Step 1: Configure Azure AD Connection**
1. Navigate to: **Organization Settings → Azure Active Directory**
2. Connect to Azure AD tenant
3. Enable: **Only allow Azure AD users**

**Step 2: Create Conditional Access Policy (Azure AD)**
1. Navigate to: **Azure Portal → Azure AD → Security → Conditional Access**
2. Create policy for Azure DevOps:
   - **Users:** All users
   - **Cloud apps:** Azure DevOps
   - **Conditions:**
     - Sign-in risk: Block high risk
     - Device platforms: Require managed devices (L2)
   - **Grant:** Require MFA

**Step 3: Disable Alternate Authentication**
1. Navigate to: **Organization Settings → Policies**
2. Disable:
   - **Third-party application access via OAuth:** Disable or restrict
   - **SSH authentication:** Restrict to managed keys
   - **Allow public projects:** Disable

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2(1) | MFA for network access |

#### Code Implementation

{% include pack-code.html vendor="azure-devops" section="1.1" %}

---

### 1.2 Implement Project-Level Security Groups

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure granular project permissions using Azure DevOps security groups.

#### ClickOps Implementation

**Step 1: Define Security Group Strategy**

See the CLI Code Pack below for the recommended security group hierarchy.

**Step 2: Configure Project Permissions**
1. Navigate to: **Project Settings → Permissions**
2. For each group, configure:
   - **Contributors:** Cannot manage service connections
   - **Build Administrators:** Can manage build pipelines only
   - **Release Administrators:** Can manage release pipelines

**Step 3: Restrict Service Account Permissions**
1. Create dedicated service accounts for pipelines
2. Grant minimum permissions needed
3. Do not add to Project Administrators

#### Code Implementation

{% include pack-code.html vendor="azure-devops" section="1.2" %}

---

### 1.3 Configure Personal Access Token Policies

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Restrict PAT creation and enforce expiration policies.

#### ClickOps Implementation

**Step 1: Configure Organization PAT Policy**
1. Navigate to: **Organization Settings → Policies**
2. Configure:
   - **Restrict creation of full-scoped PATs:** Enable
   - **Maximum PAT lifetime:** 90 days
   - **Restrict global PATs:** Enable

**Step 2: Audit Existing PATs**

See the Code Pack below for a PowerShell script that lists all PATs via the Azure DevOps REST API.

#### Code Implementation

{% include pack-code.html vendor="azure-devops" section="1.3" %}

---

## 2. Service Connection Security

### 2.1 Migrate to Workload Identity Federation

**Profile Level:** L1 (Baseline) - CRITICAL
**NIST 800-53:** IA-5

#### Description
Replace service connections with stored credentials with workload identity federation (OIDC), eliminating static secrets.

#### Rationale
**Why This Matters:**
- Service connections store long-lived credentials
- Static credentials don't expire without rotation
- OIDC federation provides short-lived, automatically rotated tokens

#### ClickOps Implementation

**Step 1: Create Workload Identity Federation Service Connection**
1. Navigate to: **Project Settings → Service connections**
2. Click **New service connection → Azure Resource Manager**
3. Select: **Workload Identity federation (automatic)**
4. Configure:
   - **Subscription:** Target subscription
   - **Service connection name:** Descriptive name
   - **Grant access to all pipelines:** Disable

**Step 2: Migrate Existing Service Connections**
1. Identify connections using stored credentials
2. Create new OIDC-based connections
3. Update pipeline references
4. Delete old credential-based connections

**Step 3: Restrict Service Connection Access**
1. Navigate to: **Service connection → Security**
2. Configure:
   - **Pipeline permissions:** Specific pipelines only
   - **User permissions:** Administrators only
   - **Allow all pipelines:** Disable

#### Code Implementation (Pipeline)

{% include pack-code.html vendor="azure-devops" section="2.1" %}

---

### 2.2 Audit and Rotate Legacy Service Connections

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5(1)

#### Description
Audit service connections with stored credentials and implement rotation schedule.

#### ClickOps Implementation

**Step 1: Audit Service Connections**
1. Navigate to: **Project Settings → Service connections**
2. Review each connection type:
   - Azure Resource Manager (check for stored creds vs OIDC)
   - AWS (check for access keys)
   - Docker Registry (check for passwords)
   - Generic (check for stored secrets)

**Step 2: Document Rotation Schedule**

| Connection Type | Rotation Frequency | Last Rotated |
|-----------------|-------------------|--------------|
| Azure (stored creds) | 90 days | [Date] |
| AWS Access Keys | 90 days | [Date] |
| Docker Registry | 90 days | [Date] |

**Step 3: Implement Rotation**

See the Code Pack below for a PowerShell script that updates service connection credentials via the Azure DevOps REST API.

#### Code Implementation

{% include pack-code.html vendor="azure-devops" section="2.2" %}

---

### 2.3 Implement Service Connection Approval Gates

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CM-3

#### Description
Require approval for pipeline use of sensitive service connections.

#### ClickOps Implementation

**Step 1: Configure Approvals and Checks**
1. Navigate to: **Service connection → Approvals and checks**
2. Add checks:
   - **Required approvers:** Security team member
   - **Business hours:** Production deployments only during business hours
   - **Branch control:** Only from protected branches

#### Code Implementation

{% include pack-code.html vendor="azure-devops" section="2.3" %}

---

## 3. Pipeline Security

### 3.1 Implement YAML Pipeline Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### Description
Configure secure YAML pipeline practices and restrict classic pipelines.

#### ClickOps Implementation

**Step 1: Disable Classic Pipelines (L2)**
1. Navigate to: **Organization Settings → Pipelines → Settings**
2. Disable:
   - **Disable creation of classic build pipelines:** Enable
   - **Disable creation of classic release pipelines:** Enable

**Step 2: Require YAML Pipeline Reviews**
1. Navigate to: **Project Settings → Repositories → Policies**
2. Configure branch policies for azure-pipelines.yml:
   - **Require approval:** Enable
   - **Minimum reviewers:** 2

**Step 3: Implement Secure Pipeline Template**

See the CLI Code Pack below for a secure pipeline template with build, security scan, and deploy stages.

#### Code Implementation

{% include pack-code.html vendor="azure-devops" section="3.1" %}

---

### 3.2 Configure Pipeline Permissions and Approvals

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3

#### Description
Restrict pipeline access to resources and require approvals for production.

#### ClickOps Implementation

**Step 1: Configure Environment Approvals**
1. Navigate to: **Pipelines → Environments → production**
2. Add approvals and checks:
   - **Approvers:** Required for deployment
   - **Branch control:** Only main branch
   - **Business hours:** Optional restriction

**Step 2: Configure Pipeline Permissions**
1. Navigate to: **Pipeline → Security**
2. Configure:
   - **Pipeline permissions:** Specific users/groups
   - **Queue builds:** Restricted to authorized users

#### Code Implementation

{% include pack-code.html vendor="azure-devops" section="3.2" %}

---

### 3.3 Secure Agent Pool Configuration

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-7

#### Description
Configure agent pools with appropriate security controls.

#### ClickOps Implementation

**Step 1: Create Tiered Agent Pools**
1. **Azure Pipelines** -- Microsoft-hosted, ephemeral (built-in)
2. **Development-Agents** -- self-hosted, lower trust
3. **Production-Agents** -- self-hosted, restricted access
4. **Security-Agents** -- isolated, scanning tools only

**Step 2: Configure Pool Permissions**
1. Navigate to: **Organization Settings → Agent pools**
2. For production pool:
   - **Pipeline permissions:** Production pipelines only
   - **User permissions:** Administrators only

**Step 3: Self-Hosted Agent Security**

See the Code Pack below for a PowerShell script that installs a self-hosted agent with security best practices (service account, unattended configuration).

#### Code Implementation

{% include pack-code.html vendor="azure-devops" section="3.3" %}

---

## 4. Repository Security

### 4.1 Configure Branch Policies

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-3

#### Description
Implement branch policies to enforce code review and prevent direct pushes.

#### ClickOps Implementation

**Step 1: Configure Protected Branches**
1. Navigate to: **Repos → Branches → main → Branch policies**
2. Enable:
   - **Require a minimum number of reviewers:** 2
   - **Check for linked work items:** Required
   - **Check for comment resolution:** Required
   - **Build validation:** Required pipeline must pass
   - **Automatically include reviewers:** Code owners

**Step 2: Configure Path-Based Policies**
1. Add path filters for sensitive directories:
   - `azure-pipelines.yml`: Require security team review
   - `terraform/`: Require platform team review

#### Code Implementation

{% include pack-code.html vendor="azure-devops" section="4.1" %}

---

### 4.2 Enable Credential Scanning

**Profile Level:** L1 (Baseline)
**NIST 800-53:** RA-5

#### Description
Enable Microsoft Security DevOps to detect secrets in repositories.

#### Implementation

{% include pack-code.html vendor="azure-devops" section="4.2" %}

---

## 5. Variable & Secret Management

### 5.1 Secure Variable Groups

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### Description
Configure variable groups with appropriate security controls.

#### ClickOps Implementation

**Step 1: Create Environment-Specific Variable Groups**
1. Navigate to: **Pipelines → Library → Variable groups**
2. Create groups:
   - `production-secrets` (linked to Key Vault)
   - `staging-secrets`
   - `shared-config`

**Step 2: Link to Azure Key Vault**
1. Create variable group linked to Key Vault
2. Configure:
   - **Azure subscription:** Service connection
   - **Key vault name:** Production vault
   - **Secrets:** Select required secrets

**Step 3: Configure Variable Group Permissions**
1. Navigate to: **Variable group → Security**
2. Configure:
   - **Pipeline permissions:** Specific pipelines only
   - **User permissions:** Administrators only

#### Code Implementation

{% include pack-code.html vendor="azure-devops" section="5.1" %}

---

### 5.2 Use Runtime Parameters for Secrets

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-28

#### Description
Pass secrets at runtime rather than storing in pipelines. See the CLI Code Pack below for a pipeline YAML example using runtime parameters.

#### Code Implementation

{% include pack-code.html vendor="azure-devops" section="5.2" %}

---

## 6. Monitoring & Detection

### 6.1 Enable Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### Description
Configure and monitor Azure DevOps audit logs.

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Organization Settings → Auditing**
2. Review events:
   - Service connection changes
   - Permission changes
   - Pipeline modifications

**Step 2: Export to SIEM**

See the Code Pack below for a PowerShell script that exports audit logs via the Azure DevOps REST API with pagination support.

#### Detection Queries

See the DB Code Pack below for Azure Sentinel / Log Analytics KQL queries that detect service connection modifications, permission changes, and unusual build activity.

#### Code Implementation

{% include pack-code.html vendor="azure-devops" section="6.1" %}

---

## 7. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Azure DevOps Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | Azure AD + Conditional Access | 1.1 |
| CC6.2 | Project permissions | 1.2 |
| CC8.1 | Branch policies | 4.1 |

### NIST 800-53 Mapping

| Control | Azure DevOps Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | Azure AD MFA | 1.1 |
| IA-5 | Service connection OIDC | 2.1 |
| CM-3 | Branch policies | 4.1 |
| AU-2 | Audit logging | 6.1 |

---

## Appendix A: Edition Compatibility

| Control | Basic | Basic + Test Plans | Azure DevOps Server |
|---------|-------|-------------------|---------------------|
| Azure AD | ✅ | ✅ | ✅ |
| Conditional Access | ✅ | ✅ | AD FS |
| Audit Logs | ✅ | ✅ | ✅ |
| Workload Identity | ✅ | ✅ | ✅ |
| Advanced Security | Add-on | Add-on | Add-on |

---

## Appendix B: References

**Official Microsoft Documentation:**
- [Microsoft Service Trust Portal](https://servicetrust.microsoft.com/) (SOC reports, compliance documentation)
- [Azure DevOps Documentation](https://learn.microsoft.com/en-us/azure/devops/)
- [Security Best Practices](https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-best-practices)
- [Workload Identity Federation](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure)
- [Audit Logging](https://learn.microsoft.com/en-us/azure/devops/organizations/audit/azure-devops-auditing)
- [Azure Compliance Documentation](https://learn.microsoft.com/en-us/azure/compliance/)

**API & Developer Tools:**
- [Azure DevOps REST API](https://learn.microsoft.com/en-us/rest/api/azure/devops/)
- [Azure DevOps CLI Extension](https://learn.microsoft.com/en-us/azure/devops/cli/)
- [Azure DevOps SDKs (.NET, Python, Node.js)](https://learn.microsoft.com/en-us/azure/devops/integrate/)
- [GitHub Organization (Microsoft)](https://github.com/microsoft)

**Compliance Frameworks:**
- SOC 2 Type II (Azure DevOps specific attestation report available separately) — via [Service Trust Portal](https://servicetrust.microsoft.com/)
- ISO/IEC 27001:2022 — via [Azure ISO 27001](https://learn.microsoft.com/en-us/azure/compliance/offerings/offering-iso-27001)
- SOC 1 Type II, ISO 27017, ISO 27018, CSA STAR, FedRAMP (High and Moderate)
- PCI DSS, HIPAA, HITRUST

**Security Incidents:**
- **2025 — Critical SSRF and CRLF Injection Vulnerabilities:** Multiple critical vulnerabilities in Azure DevOps endpointproxy and Service Hooks components enabled DNS rebinding attacks and unauthorized access to internal services. Microsoft released patches and awarded a $15,000 bug bounty. ([Legit Security Report](https://www.legitsecurity.com/blog/azure-devops-zero-click-ci/cd-vulnerability))
- **May 2025 — CVE with CVSS 10.0 in Azure DevOps Server:** Microsoft patched a maximum-severity vulnerability affecting Azure DevOps Server. ([The Hacker News Report](https://thehackernews.com/2025/05/microsoft-fixes-78-flaws-5-zero-days.html))
- **H1 2025 — 74 Service Incidents:** Azure DevOps experienced 74 unique incidents from January-June 2025, including a 159-hour global Pipelines degradation in January. ([GitProtect Report](https://gitprotect.io/blog/devops-threats-unwrapped-mid-year-report-2025/))

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial Azure DevOps hardening guide | Claude Code (Opus 4.5) |
| 2026-02-19 | 0.1.2 | draft | Migrate all remaining inline code to Code Packs (1.2, 2.1, 3.1, 3.3, 4.2, 5.2, 6.1); zero inline blocks | Claude Code (Opus 4.6) |
| 2026-02-19 | 0.1.1 | draft | Migrate inline PowerShell to CLI Code Packs (1.3, 2.2, 3.3, 6.1) | Claude Code (Opus 4.6) |
