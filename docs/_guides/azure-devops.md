---
layout: guide
title: "Azure DevOps Hardening Guide"
vendor: "Azure DevOps"
slug: "azure-devops"
tier: "2"
category: "DevOps"
description: "Microsoft DevOps security for pipelines, service connections, and artifact feeds"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

Azure DevOps provides deep Microsoft ecosystem integration with enterprise-wide pipeline and repository access. Service connections store long-lived credentials for Azure Resource Manager, AWS, and GCP. OIDC federation (workload identity federation) should replace static secrets, but legacy configurations with stored credentials remain vulnerable to supply chain attacks.

### Intended Audience
- Security engineers hardening DevOps infrastructure
- Platform engineers managing Azure DevOps
- GRC professionals assessing CI/CD compliance
- DevOps teams implementing secure pipelines

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

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

**Profile Level:** L1 (Crawl)
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1)

#### Description
Require Azure AD authentication with Conditional Access policies including MFA, device compliance, and location-based restrictions.

#### Rationale
**Why This Matters:**
- Azure DevOps controls code, pipelines, and deployment secrets
- Service connections store cloud provider credentials
- Compromised access enables code injection and infrastructure access

**Attack Prevented:** Credential stuffing and password-only account takeover, MFA bypass through legacy authentication paths, access from unmanaged devices and untrusted networks

#### ClickOps Implementation

**Step 1: Configure Microsoft Entra ID Connection**
1. Navigate to: **Organization Settings → Microsoft Entra** (formerly Azure Active Directory)
2. Connect to the Entra ID tenant
3. Enable: **Only allow Microsoft Entra users**

**Step 2: Create Conditional Access Policy (Entra ID)**
1. Navigate to: **Azure Portal → Microsoft Entra ID → Security → Conditional Access**
2. Create policy for Azure DevOps:
   - **Users:** All users
   - **Cloud apps:** Azure DevOps
   - **Conditions:**
     - Sign-in risk: Block high risk
     - Device platforms: Require managed devices (L2)
   - **Grant:** Require MFA

**Step 3: Bind Conditional Access to Non-Interactive Traffic**
1. Navigate to: **Organization Settings → Policies**
2. Enable: **Enable IP Conditional Access policy validation on non-interactive flows**
3. Without this policy, Entra ID Conditional Access IP restrictions are evaluated on interactive sign-in only. Non-interactive traffic — PATs, SSH, and other token-bearing access — is not bound by the IP conditions, which leaves the most attractive path to an attacker holding a stolen token unrestricted. ([Change application connection and security policies](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/change-application-access-policies))

**Step 4: Restrict Legacy and Third-Party Authentication Paths**
1. Navigate to: **Organization Settings → Policies**
2. Review the application connection policies:
   - **Third-party application access via OAuth:** keep disabled. **Changed default:** Microsoft now ships this policy **off by default for new organizations**, so the task here is confirming nobody turned it on rather than turning it off. Note the scope — it governs the legacy Azure DevOps OAuth app model only, and does **not** govern Entra ID OAuth applications, which are controlled in Entra ID. ([Change application connection and security policies](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/change-application-access-policies))
   - **SSH authentication:** leave enabled only where Git-over-SSH is genuinely needed, and keep **Validate SSH key expiration** on — it is on by default. With it enabled, expired SSH keys become invalid immediately, and users are notified 7 days before expiry. There is no "restrict to managed keys" setting; key hygiene is enforced through expiration validation, not an allowlist.
   - **Alternate credentials:** this mechanism no longer exists in Azure DevOps. If your runbook still carries a "disable alternate authentication" step, treat it as historical — verify nothing still authenticates that way, then delete the step rather than hunting for a toggle that was removed.

**Step 5: Retire Public Projects**
1. Microsoft has retired public projects: creating new ones is blocked, and existing public projects are scheduled to convert automatically to private in 2027. ([Azure DevOps security overview](https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-overview))
2. Rather than toggling a policy, inventory any public projects that remain and convert them on your own schedule, so the change lands as a planned migration instead of an imposed one.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2(1) | MFA for network access |

#### Code Implementation

{% include pack-code.html vendor="azure-devops" section="1.1" %}

---

### 1.2 Implement Project-Level Security Groups

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure granular project permissions using Azure DevOps security groups.

#### Rationale
**Why This Matters:**
- Default Azure DevOps groups like Project Administrators and Contributors grant broad permissions that violate least privilege
- Granular security groups separate build, release, and service-connection management so no single role can both write code and push to production
- Dedicated pipeline service accounts with minimum permissions limit the blast radius if an account or token is compromised
- Without scoped groups, any Contributor can modify pipelines, service connections, and deployment targets

**Attack Prevented:** Privilege escalation, lateral movement, unauthorized pipeline modification, insider misuse

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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Restrict PAT creation and enforce expiration policies.

#### Rationale
**Why This Matters:**
- Personal Access Tokens are bearer credentials that bypass interactive MFA and Conditional Access once issued
- Full-scoped, long-lived PATs leaked in scripts, logs, or repositories grant standing programmatic access to code and pipelines
- Enforced expiration and scope limits shrink the window an exposed token remains usable
- Restricting global PATs prevents a single token from reaching every organization the user can access

**Attack Prevented:** Token theft, credential leakage, MFA bypass, long-lived unauthorized access

#### ClickOps Implementation

**Step 1: Configure the Tenant PAT Policies**

The three policies that actually constrain PAT scope and lifetime are **tenant** policies, not organization policies, and they live in a different place than most guidance suggests. ([Manage PATs with policies](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/manage-pats-with-policies-for-administrators))

1. Navigate to: **Organization settings → Microsoft Entra**
2. You need the **Azure DevOps Administrator** role in Entra ID to change these — organization owners without that role cannot set them.
3. Configure, noting that **all three are off by default**:
   - **Restrict full-scoped personal access token creation** — forces every new PAT to carry an explicit scope
   - **Maximum personal access token lifespan** — set to 90 days or lower
   - **Restrict global personal access token creation** — stops one token from reaching every organization the user can access
4. Each policy carries its own Entra allowlist. Use it for the narrow set of identities that genuinely need an exception, and review the allowlists on the same cadence as the tokens themselves — an allowlist entry silently defeats the policy for that identity.

**Step 2: Configure the Organization PAT Creation Policy**
1. Navigate to: **Organization Settings → Policies**
2. Enable: **Restrict personal access token (PAT) creation**
3. This is a separate, organization-scoped control from the tenant policies above. Its subpolicies let you allow PAT creation for packaging scopes only, and maintain an allowlist of users who may still create tokens with any scope.

**Step 3: Leave Leaked-Token Auto-Revocation On**

**Do not disable this.** The tenant policy **Automatically revoke leaked personal access tokens** is **on by default**, and it revokes PATs that are committed to public GitHub repositories. It is one of the few controls that acts after the mistake has already been made, and turning it off buys nothing.

**Step 4: Prefer Entra Tokens Over Service-Account PATs**

Long-lived PATs issued to shared service accounts are the hardest PATs to rotate and the ones most likely to end up in a script. Replace them with 1-hour Microsoft Entra tokens, service principals, or managed identities wherever the consuming system supports it. ([Azure DevOps security overview](https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-overview))

**Step 5: Audit Existing PATs**

See the Code Pack below for a PowerShell script that lists all PATs via the Azure DevOps REST API.

#### Code Implementation

{% include pack-code.html vendor="azure-devops" section="1.3" %}

---

## 2. Service Connection Security

### 2.1 Migrate to Workload Identity Federation

**Profile Level:** L1 (Crawl) - CRITICAL
**NIST 800-53:** IA-5

#### Description
Replace service connections with stored credentials with workload identity federation (OIDC), eliminating static secrets.

#### Rationale
**Why This Matters:**
- Service connections store long-lived credentials
- Static credentials don't expire without rotation
- OIDC federation provides short-lived, automatically rotated tokens
- A stored cloud credential in a service connection is a standing path from a compromised pipeline definition straight into the subscription it targets

**Attack Prevented:** Cloud account takeover through leaked service connection secrets, credential reuse after exposure, long-lived standing access to subscriptions from CI

#### Deprecation: The Azure DevOps Issuer Is Being Retired

Workload identity federation itself is not going away — the **issuer** behind it is changing, and existing connections will break if left alone.

- The Azure DevOps issuer (`https://vstoken.dev.azure.com`) was deprecated on **2026-07-01** and is scheduled for **retirement on 2027-07-01**.
- New service connections are created against the Entra issuer (`https://login.microsoftonline.com/`) instead.
- Azure DevOps flags affected connections. Convert one via **Project settings → Service connections → (flagged connection) → Update**. Where the automatic conversion does not apply, add a federated credential on the app registration manually using the Issuer and Subject values Azure DevOps displays for that connection.
- Out of scope for the automatic path: multitenant app registrations, and the Azure Government, 21Vianet, and Azure Stack clouds — plan these conversions by hand.

Sources: [WIF Azure DevOps issuer retirement](https://learn.microsoft.com/en-us/azure/devops/release-notes/roadmap/wif-azdo-issuer-retirement) · [Convert service connections](https://learn.microsoft.com/en-us/azure/devops/pipelines/release/convert-service-connections)

#### ClickOps Implementation

**Step 1: Create Workload Identity Federation Service Connection**
1. Navigate to: **Project Settings → Service connections**
2. Click **New service connection → Azure Resource Manager**
3. Select: **Workload Identity federation (automatic)**
4. Configure:
   - **Subscription:** Target subscription
   - **Service connection name:** Descriptive name
   - **Grant access to all pipelines:** Disable
5. Scope the connection to a **resource group** rather than the whole subscription wherever the pipeline's work allows it, and avoid classic service connections entirely — they carry broader standing access than the ARM equivalent and are the harder of the two to audit. ([Azure DevOps security overview](https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-overview))

**Step 2: Migrate Existing Service Connections**
1. Identify connections using stored credentials
2. Create new OIDC-based connections
3. Update pipeline references
4. Delete old credential-based connections
5. Separately, work the flagged-connection list from the issuer retirement above — a connection can already be OIDC-based and still be pointed at the retiring issuer

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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5(1)

#### Description
Audit service connections with stored credentials and implement rotation schedule.

#### Rationale
**Why This Matters:**
- Service connections holding stored Azure, AWS, or Docker credentials grant direct access to cloud infrastructure
- Static credentials that are never rotated remain valid indefinitely after exposure or an employee departs
- A scheduled audit and rotation cadence limits how long a leaked secret stays usable and surfaces forgotten connections
- Until full OIDC migration is complete, rotation is the primary control reducing exposure of legacy stored secrets

**Attack Prevented:** Credential reuse, stale secret abuse, cloud account takeover, supply chain compromise

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

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-3

#### Description
Require approval for pipeline use of sensitive service connections.

#### Rationale
**Why This Matters:**
- Approval checks insert human review before a pipeline can use a connection that deploys to production or touches sensitive cloud resources
- Branch control ensures only protected branches can invoke privileged connections, blocking exploits from feature branches or forks
- Without gates, a malicious or compromised pipeline definition can silently use a powerful connection to reach production
- Approvals create an auditable record of who authorized each sensitive deployment

**Attack Prevented:** Poisoned pipeline execution, unauthorized production deployment, malicious YAML changes

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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Configure secure YAML pipeline practices and restrict classic pipelines.

#### Rationale
**Why This Matters:**
- YAML pipelines live in source control, so every change is reviewable, versioned, and subject to branch policies — unlike classic UI pipelines
- Requiring reviews on azure-pipelines.yml prevents an attacker from injecting build steps that exfiltrate secrets or tamper with artifacts
- Disabling classic pipelines removes a parallel, harder-to-audit path that bypasses code review
- Pipelines run with access to secrets and deployment credentials, making the definition itself a critical security boundary

**Attack Prevented:** Pipeline injection, secret exfiltration, build tampering, supply chain attacks

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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3

#### Description
Restrict pipeline access to resources and require approvals for production.

#### Rationale
**Why This Matters:**
- Environment approvals require a human to authorize production deployments, stopping unreviewed or fully automated pushes to live systems
- Branch control limits deployments to the main branch, preventing release of unvetted code from other branches
- Scoping pipeline permissions to specific users and groups prevents arbitrary pipelines from queuing builds or consuming protected resources
- Production deployment paths carry the highest blast radius and need the strongest authorization controls

**Attack Prevented:** Unauthorized deployment, unreviewed code release, resource abuse, privilege escalation

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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-7

#### Description
Configure agent pools with appropriate security controls.

#### Rationale
**Why This Matters:**
- Self-hosted agents execute pipeline code and hold cached credentials, so a shared or persistent agent can leak secrets between jobs
- Tiered pools isolate production and security workloads from lower-trust development builds, containing a compromised agent
- Restricting pool permissions to specific pipelines prevents an untrusted pipeline from running on a privileged production agent
- Running agents under dedicated least-privilege service accounts limits what an exploited build can do to the host

**Attack Prevented:** Cross-job credential theft, agent poisoning, lateral movement, privilege escalation

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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-3

#### Description
Implement branch policies to enforce code review and prevent direct pushes.

#### Rationale
**Why This Matters:**
- Required reviewers ensure no single developer can merge code unilaterally, catching malicious or accidental changes before they reach main
- Build validation blocks merges that fail security scans or tests, keeping vulnerable code out of protected branches
- Path-based policies route changes to pipeline and infrastructure files to the right security and platform reviewers
- Without branch protection, a compromised account can push directly to main and trigger deployments without oversight

**Attack Prevented:** Unauthorized code changes, malicious commits, review bypass, insider tampering

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

**Step 3: Require Advanced Security Status Checks on Pull Requests**

If you have GitHub Advanced Security for Azure DevOps enabled (see [4.2](#42-enable-secret-and-code-scanning-with-github-advanced-security)), its findings can gate merges rather than merely appearing in a tab.

1. Navigate to: **Project settings → Repos → Policies → Status checks**
2. Add a status check with **Genre** `AdvancedSecurity` and one of:
   - `AdvancedSecurity/AllHighAndCritical` — blocks the merge while any high or critical alert exists on the branch
   - `AdvancedSecurity/NewHighAndCritical` — blocks only on alerts the pull request introduces, which is the practical starting point for a repository with existing findings
3. Start with `NewHighAndCritical` to stop the bleeding, then move to `AllHighAndCritical` once the backlog is worked down. ([Configure GitHub Advanced Security features](https://learn.microsoft.com/en-us/azure/devops/repos/security/configure-github-advanced-security-features))

#### Code Implementation

{% include pack-code.html vendor="azure-devops" section="4.1" %}

---

### 4.2 Enable Secret and Code Scanning with GitHub Advanced Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** RA-5

#### Description
Enable GitHub Advanced Security for Azure DevOps (GHAzDO) to detect secrets committed to repositories and block new ones at push time.

#### Rationale
**Why This Matters:**
- Secrets committed to repositories are exposed to everyone with read access and persist in git history even after deletion
- Automated credential scanning catches keys, tokens, and passwords before they merge, enabling immediate revocation
- Hardcoded secrets in code are a leading cause of cloud breaches and supply chain compromise
- Continuous scanning in CI provides defense in depth alongside developer discipline and pre-commit hooks

**Attack Prevented:** Secret leakage, hardcoded credential exposure, repository data theft, cloud account takeover

#### Prerequisites
- The scanning capability is licensed separately as **GitHub Advanced Security for Azure DevOps**. It is also sold unbundled as **GitHub Secret Protection for Azure DevOps** (secret scanning and push protection) and **GitHub Code Security for Azure DevOps** (code scanning and dependency scanning), so you can buy the secret-scanning half alone.
- Project Administrator or organization-level permissions, depending on the scope you enable at.

#### ClickOps Implementation

**Step 1: Enable at the Right Scope**
1. Navigate to: **Organization settings → Repositories**
2. Use **Enable all** to turn Advanced Security on across the organization, or enable it per project or per repository if you are rolling out incrementally.
3. Enabling **Secret Protection** automatically turns on both **push protection** and **repository secret scanning** for the scope you enabled — you do not configure those separately.

**Step 2: Work the Alerts**
1. Navigate to the repository's **Advanced Security** tab
2. Triage secret alerts by revoking the exposed credential first and removing it from the code second — rotation is the control, deletion from the branch is cleanup.
3. Gate merges on findings using the Advanced Security status checks described in [4.1](#41-configure-branch-policies).

Source: [Configure GitHub Advanced Security features](https://learn.microsoft.com/en-us/azure/devops/repos/security/configure-github-advanced-security-features)

#### Code Implementation

{% include pack-code.html vendor="azure-devops" section="4.2" %}

---

## 5. Variable & Secret Management

### 5.1 Secure Variable Groups

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Configure variable groups with appropriate security controls.

#### Rationale
**Why This Matters:**
- Variable groups distribute secrets to pipelines, so unrestricted access lets any pipeline read production credentials
- Linking groups to Azure Key Vault centralizes secret storage, rotation, and access auditing instead of holding plaintext in Azure DevOps
- Scoping pipeline and user permissions ensures only authorized pipelines and administrators can consume sensitive variable groups
- Separating production, staging, and shared configuration prevents lower environments from leaking production secrets

**Attack Prevented:** Secret exposure, unauthorized credential access, environment crossover, privilege escalation

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

**Profile Level:** L2 (Walk)
**NIST 800-53:** SC-28

#### Description
Pass secrets at runtime rather than storing in pipelines. See the CLI Code Pack below for a pipeline YAML example using runtime parameters.

#### Rationale
**Why This Matters:**
- Passing secrets at runtime keeps them out of pipeline definitions stored in source control and out of git history
- Runtime parameters reduce the chance of secrets being logged or echoed during build steps
- Secrets embedded in pipeline YAML are visible to anyone with repository read access and survive in version history
- Decoupling secret values from pipeline code limits exposure when a definition is forked, cloned, or shared

**Attack Prevented:** Secret leakage in source control, credential exposure in logs, history mining

#### Code Implementation

{% include pack-code.html vendor="azure-devops" section="5.2" %}

---

## 6. Monitoring & Detection

### 6.1 Enable Audit Logging

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Configure and monitor Azure DevOps audit logs.

#### Rationale
**Why This Matters:**
- Audit logs record service connection changes, permission grants, and pipeline modifications that signal compromise or insider activity
- Exporting events to a SIEM enables alerting, correlation, and retention beyond the platform's limited native window
- Without monitoring, attacker actions like adding a backdoor service connection or escalating permissions go undetected
- Audit trails are required evidence for SOC 2, ISO 27001, and incident investigation

**Attack Prevented:** Undetected compromise, insider threat, configuration tampering, delayed incident response

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Organization Settings → Auditing**
2. Review events:
   - Service connection changes
   - Permission changes
   - Pipeline modifications

**Step 2: Stream Audit Events to Your SIEM**
1. Navigate to: **Organization Settings → Auditing → Streams**
2. Create a stream pointed at your SIEM target. Streaming is the primary export path: it delivers events continuously, needs no code of your own, and it is what carries events past Azure DevOps's limited native retention window. ([Azure DevOps security overview](https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-overview))
3. Confirm the stream is receiving events before you retire any polling job that currently covers this.

**Step 3: Fallback — Scheduled REST Export**

Where no stream target exists for your SIEM, fall back to polling the audit log API on a schedule. See the Code Pack below for a PowerShell script that exports audit logs via the Azure DevOps REST API with pagination support.

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
- [Azure DevOps Documentation](https://learn.microsoft.com/en-us/azure/devops/)
- [Azure DevOps Security Overview](https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-overview) (canonical security guidance; the former `security-best-practices` URL now redirects here)
- [Change Application Connection and Security Policies](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/change-application-access-policies)
- [Manage PATs with Policies (Administrators)](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/manage-pats-with-policies-for-administrators)
- [Workload Identity Federation](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure)
- [WIF Azure DevOps Issuer Retirement](https://learn.microsoft.com/en-us/azure/devops/release-notes/roadmap/wif-azdo-issuer-retirement)
- [Convert Service Connections to the Entra Issuer](https://learn.microsoft.com/en-us/azure/devops/pipelines/release/convert-service-connections)
- [Configure GitHub Advanced Security Features](https://learn.microsoft.com/en-us/azure/devops/repos/security/configure-github-advanced-security-features)
- [Audit Logging](https://learn.microsoft.com/en-us/azure/devops/organizations/audit/azure-devops-auditing)
- [Azure Compliance Documentation](https://learn.microsoft.com/en-us/azure/compliance/)

**API & Developer Tools:**
- [Azure DevOps REST API](https://learn.microsoft.com/en-us/rest/api/azure/devops/)
- [Azure DevOps CLI Extension](https://learn.microsoft.com/en-us/azure/devops/cli/)
- [Azure DevOps SDKs (.NET, Python, Node.js)](https://learn.microsoft.com/en-us/azure/devops/integrate/)
- [GitHub Organization (Microsoft)](https://github.com/microsoft)

**Compliance Frameworks:**
- SOC 2 Type II (an Azure DevOps-specific attestation report is available separately from Microsoft under NDA)
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
| 2026-08-08 | 0.2.0 | draft | Currency pass. **1.1:** Entra rename; third-party OAuth is now off by default for new organizations and does not govern Entra ID OAuth apps; replace the non-existent "restrict to managed keys" SSH setting with **Validate SSH key expiration** (default on); reframe alternate credentials as removed rather than disableable; reframe public projects as retired (new creation blocked, existing convert to private in 2027); add the **Enable IP Conditional Access policy validation on non-interactive flows** policy; convert `Attack Scenario` to `Attack Prevented`. **1.3:** correct the three PAT policies to Microsoft Entra **tenant** policies (Organization settings → Microsoft Entra, Azure DevOps Administrator role, per-policy Entra allowlists, all default off), add the separate org-level PAT creation policy, add the default-on leaked-PAT auto-revocation as a do-not-disable callout, and add Entra-token/service-principal/managed-identity guidance for service accounts. **2.1:** add the workload identity federation issuer retirement (Azure DevOps issuer deprecated 2026-07-01, retired 2027-07-01) with the conversion path and out-of-scope clouds, add resource-group scoping and the avoid-classic-connections rule, add a missing `Attack Prevented` line. **4.1:** add Advanced Security pull-request status checks. **4.2:** retitle to GitHub Advanced Security for Azure DevOps (also sold as GitHub Secret Protection / Code Security) and add enablement and triage steps. **6.1:** native audit streaming becomes the primary SIEM path, REST export becomes the fallback. **Appendix B:** replace the redirecting `security-best-practices` link with the canonical security overview, add the newly cited docs, and remove the Service Trust Portal rows. Changelog order reconstructed and the duplicate 0.1.1 resolved (the 2026-06-29 row is renumbered 0.1.3). Not surveyed this pass: the sprint-by-sprint Azure DevOps release notes, and Tier 3/4 research. No CIS Azure DevOps Benchmark exists, so no benchmark mappings were added | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.3 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2026-02-19 | 0.1.2 | draft | Migrate all remaining inline code to Code Packs (1.2, 2.1, 3.1, 3.3, 4.2, 5.2, 6.1); zero inline blocks | Claude Code (Opus 4.6) |
| 2026-02-19 | 0.1.1 | draft | Migrate inline PowerShell to CLI Code Packs (1.3, 2.2, 3.3, 6.1) | Claude Code (Opus 4.6) |
| 2025-12-14 | 0.1.0 | draft | Initial Azure DevOps hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
