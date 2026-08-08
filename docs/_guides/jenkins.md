---
layout: guide
title: "Jenkins Hardening Guide"
vendor: "Jenkins"
slug: "jenkins"
tier: "2"
category: "DevOps"
description: "CI/CD security hardening for Jenkins including authorization, agent security, and pipeline protection"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

Jenkins is the most widely used open-source CI/CD automation server, powering build pipelines for **millions of projects** across enterprises worldwide. As a critical component deeply integrated into software delivery processes, Jenkins has access to source code, deployment credentials, and production systems. A single misconfiguration can compromise the entire build environment and supply chain.

### Intended Audience
- Security engineers managing CI/CD infrastructure
- DevOps administrators configuring Jenkins
- GRC professionals assessing build security
- Platform engineers implementing secure pipelines

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Jenkins security configurations including authentication, authorization, agent security, and pipeline hardening for both Jenkins Controller and Jenkins Cloud deployments.

---

## Table of Contents

1. [Authentication & Access Control](#1-authentication--access-control)
2. [Authorization & Permissions](#2-authorization--permissions)
3. [Controller & Agent Security](#3-controller--agent-security)
4. [Pipeline Security](#4-pipeline-security)
5. [Monitoring & Compliance](#5-monitoring--compliance)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & Access Control

### 1.1 Enable Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Enable authentication to prevent anonymous access to Jenkins. By default, older Jenkins installations may allow anonymous access.

#### Rationale
**Why This Matters:**
- Anonymous access allows anyone to view jobs, credentials, and configurations
- Attackers can trigger builds or modify pipelines without authentication
- Authentication is the foundation for authorization controls

**Attack Prevented:** Anonymous reconnaissance of jobs and configuration, unauthenticated build triggering, unauthorized pipeline modification

#### ClickOps Implementation

**Step 1: Enable Security**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. Check **Enable security** (if not already enabled)
3. Configure security realm (authentication method)

**Step 2: Configure Security Realm**
1. Select appropriate security realm:
   - **Jenkins' own user database:** For small deployments
   - **LDAP:** For enterprise directory integration
   - **SAML 2.0:** For SSO with identity providers (recommended)
2. Configure realm settings

**Step 3: Disable Anonymous Access**
1. Under Authorization, ensure anonymous users have no permissions
2. Do not select "Anyone can do anything"
3. Do not select "Logged-in users can do anything" (see 2.1)

**Time to Complete:** ~30 minutes

---

### 1.2 Configure LDAP or SAML SSO

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure centralized authentication using LDAP or SAML SSO for enterprise identity management.

#### Rationale
**Why This Matters:**
- Centralizes Jenkins login in the corporate IdP so MFA, conditional access, and password policy apply to every CI/CD user
- Local Jenkins user databases lack MFA and central deprovisioning, leaving orphaned accounts behind when staff leave
- Group and role attributes from the IdP drive Jenkins authorization, removing per-user permission drift
- Jenkins holds deployment credentials and source code, so weak standalone logins are a direct path into the supply chain

**Attack Prevented:** Credential stuffing, phishing, orphaned-account access, password reuse

#### Prerequisites
- LDAP directory or SAML IdP available
- LDAP Plugin or SAML Plugin installed

#### ClickOps Implementation (SAML)

**Step 1: Install SAML Plugin**
1. Navigate to: **Manage Jenkins** → **Plugins** → **Available plugins**
2. Search for "SAML"
3. Install **SAML Single Sign On(SSO)** plugin
4. Restart Jenkins

**Step 2: Configure SAML**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. Select **SAML 2.0** as Security Realm
3. Configure:
   - IdP Metadata URL or XML
   - Username attribute
   - Email attribute
   - Group attribute (for role mapping)
4. Configure SP settings and download metadata

**Step 3: Configure IdP**
1. Create application in IdP
2. Upload Jenkins SP metadata
3. Configure attribute mappings
4. Assign users/groups

**ClickOps Implementation (LDAP)

**Step 1: Configure LDAP**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. Select **LDAP** as Security Realm
3. Configure:
   - Server: `ldaps://ldap.example.com:636`
   - Root DN: `dc=example,dc=com`
   - User search base: `ou=users`
   - User search filter: `uid={0}`
   - Group search base: `ou=groups`
4. Test LDAP connection

---

### 1.3 Disable Self-Registration and Bound Session Lifetime

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Turn off open user self-registration in the Jenkins user database and bound how long an authenticated session stays valid.

#### Rationale
**Why This Matters:**
- Open self-registration lets any visitor create an account, which combined with a permissive authorization strategy (see 2.1) is a direct path from anonymous to privileged
- Accounts created outside the joiner process bypass identity proofing, group assignment, and deprovisioning entirely
- Long-lived sessions widen the window in which a stolen session artifact from a shared or compromised workstation remains usable
- Bounding session lifetime forces periodic re-authentication so timeout and MFA policy are re-evaluated rather than assumed

**Attack Prevented:** Unauthorized account creation, privilege escalation via self-registered accounts, session hijacking, unbounded persistent access

#### ClickOps Implementation

**Step 1: Disable Self-Registration**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. Uncheck **Allow users to sign up** (if using the Jenkins user database)
3. Provision accounts through LDAP/SAML instead (see 1.2) so joiner-mover-leaver processes apply

**Step 2: Bound Session Lifetime**
1. Configure a session timeout appropriate to the sensitivity of the instance
2. Re-verify the timeout after upgrades — session handling is servlet-container-level and can be reset by a container change

> **On "Remember me":** persistent login tokens are a real risk worth eliminating, but the mechanism for disabling them on current Jenkins could **not be fetch-verified during this revision**. Consult the current Jenkins security documentation for your version before changing it, and do not assume the steps above disable it — they do not. This note is deliberately unresolved rather than filled with an unverified system property or JCasC key.

---

## 2. Authorization & Permissions

### 2.1 Configure Matrix-Based Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure Matrix-based security for fine-grained permission control. This is recommended over "Logged-in users can do anything."

#### Rationale
**Why This Matters:**
- "Logged-in users can do anything" gives all authenticated users admin access
- Combined with open signup, anyone can become an admin
- Matrix security enables granular permission control

**Attack Prevented:** Privilege escalation via self-registration, blanket admin access for any authenticated user, unauthorized configuration and credential access

#### ClickOps Implementation

**Step 1: Enable Matrix Authorization**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. Under Authorization, select **Matrix-based security**

**Step 2: Configure Permissions**
1. Add users and groups to the matrix
2. Assign minimum necessary permissions:

| Permission | Admins | Developers | Viewers |
|-----------|--------|------------|---------|
| Overall/Administer | ✅ | ❌ | ❌ |
| Overall/Read | ✅ | ✅ | ✅ |
| Job/Build | ✅ | ✅ | ❌ |
| Job/Configure | ✅ | ❌ | ❌ |
| Job/Read | ✅ | ✅ | ✅ |
| Credentials/View | ✅ | ❌ | ❌ |

**Step 3: Remove Default Authenticated Group**
1. Remove or restrict the `authenticated` group permissions
2. Grant permissions to specific groups/users only

---

### 2.2 Configure Project-Based Matrix Authorization

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Enable project-based authorization for per-project access control.

#### Rationale
**Why This Matters:**
- Global-only permissions force a choice between over-granting access and blocking legitimate work across teams
- Per-project authorization confines each user to the jobs they need, containing the blast radius of a compromised account
- Limits which credentials and pipelines an attacker can reach if they gain one team member's access

**Attack Prevented:** Lateral movement, privilege creep, cross-team data exposure

#### Prerequisites
- Matrix Authorization Strategy Plugin installed

#### ClickOps Implementation

**Step 1: Enable Project-Based Matrix**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. Select **Project-based Matrix Authorization Strategy**

**Step 2: Configure Global Permissions**
1. Set minimal global permissions
2. Most permissions will be set at project level

**Step 3: Configure Project Permissions**
1. Navigate to: **Job** → **Configure** → **Enable project-based security**
2. Add users/groups with project-specific permissions
3. Example: "Joe can access projects A, B, and C, but not D"

---

### 2.3 Configure Role-Based Access Control

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Implement role-based access control for scalable permission management.

#### Rationale
**Why This Matters:**
- Matrix permissions assigned per user drift over time and become impossible to audit as the team grows
- Roles map permissions to job function once, so access stays consistent and reviewable as users join and leave
- Item-role patterns scope teams to their own job namespaces, preventing access to unrelated pipelines and credentials

**Attack Prevented:** Privilege creep, misconfigured access grants, cross-team unauthorized access

#### Prerequisites
- Role-based Authorization Strategy Plugin installed

#### ClickOps Implementation

**Step 1: Enable Role-Based Strategy**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. Select **Role-Based Strategy**

**Step 2: Define Roles**
1. Navigate to: **Manage Jenkins** → **Manage and Assign Roles** → **Manage Roles**
2. Create global roles:
   - `admin`: Full permissions
   - `developer`: Build and read permissions
   - `viewer`: Read-only permissions

**Step 3: Create Project Roles**
1. Create item roles with patterns:
   - Role: `team-a-dev`, Pattern: `team-a-.*`
   - Role: `team-b-dev`, Pattern: `team-b-.*`
2. Assign item-specific permissions

**Step 4: Assign Roles**
1. Navigate to: **Manage and Assign Roles** → **Assign Roles**
2. Assign global roles to users/groups
3. Assign item roles to users/groups

---

### 2.4 Restrict Script Console Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Restrict access to the Script Console to administrators only.

#### Rationale
**Why This Matters:**
- Script Console provides Groovy script execution
- Can access all Jenkins internals, credentials, and system
- Unlimited code execution capability

**Attack Prevented:** Remote code execution on the controller, mass credential extraction, security-control tampering, persistence

#### ClickOps Implementation

**Step 1: Verify Script Console Permissions**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. In authorization matrix, ensure only admins have `Overall/Administer`
3. Script Console requires `Overall/Administer` permission

**Step 2: Audit Script Console Access**
1. Review who has admin access
2. Consider separate admin accounts for privileged operations
3. Log and alert on Script Console usage

---

## 3. Controller & Agent Security

### 3.1 Verify Agent to Controller Access Control (Never Disable It)

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-4 |

#### Description
Confirm Agent → Controller Access Control is active and audit its allowlists. On current Jenkins this subsystem is always on, so the control is verification and allowlist hygiene rather than an enable step.

#### Rationale
**Why This Matters:**
- Agent processes could be taken over by malicious users
- Without controls, agents can send commands to controller
- This prevents agents from accessing sensitive controller data
- The protection is only as strong as its allowlists — a permissive file-path or command rule reopens the path it exists to close

**Attack Prevented:** Controller compromise from a hijacked agent, unauthorized command execution against the controller, exfiltration of controller-side configuration and secrets

> **Changed default — this is no longer a toggle you enable.** Agent → Controller Access Control was enabled by default through Jenkins 2.325 and has been **always enabled since Jenkins 2.326**. Jenkins states: "It is strongly recommended that you not disable the Agent → Controller Access Control system." Treat any instance where it has been disabled as a finding, and spend the review effort on the allowlists instead. Source: [Controller Isolation](https://www.jenkins.io/doc/book/security/controller-isolation/).

#### ClickOps Implementation

**Step 1: Verify Access Control Is Active**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. Under **Agent → Controller Security**, confirm access control has not been disabled
3. On Jenkins 2.326 and later there is no supported reason to turn it off — if it is off, restore it

**Step 2: Review Allowed Commands**
1. Navigate to: **Manage Jenkins** → **Security** → **Agent → Controller Security**
2. Review allowlisted file path rules
3. Review allowlisted commands
4. Remove unnecessary allowances — every entry is an exception to the isolation boundary

---

### 3.2 Disable Builds on Controller

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-7 |

#### Description
Configure Jenkins to run builds only on agents, not on the controller node.

#### Rationale
**Why This Matters:**
- Controller has access to all configurations, credentials, and secrets
- Builds running on controller can access sensitive data
- Compromised builds can attack Jenkins internals

**Attack Prevented:** Credential and secret theft by a malicious build, controller compromise via poisoned pipeline code, bypass of agent-to-controller isolation

#### ClickOps Implementation

**Step 1: Configure Controller Executors**
1. Navigate to: **Manage Jenkins** → **Nodes** → **Built-In Node** → **Configure**
2. Set **Number of executors** to **0**
3. Save configuration

**Step 2: Configure Labels**
1. Ensure jobs are configured to run on specific agent labels
2. Never use "any" or empty label restrictions

---

### 3.3 Use Ephemeral Agents

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Use ephemeral (disposable) agents that are created fresh for each build.

#### Rationale
**Why This Matters:**
- Long-lived agents accumulate build artifacts, cached credentials, and toolchains that one malicious build can poison for the next
- A fresh agent per build guarantees no state carries between jobs, eliminating cross-build contamination
- Disposable agents shrink the window an attacker has to establish persistence on build infrastructure

**Attack Prevented:** Cross-build contamination, persistence on build hosts, theft of cached credentials and artifacts

#### ClickOps Implementation

**Step 1: Configure Cloud Agents**
1. Navigate to: **Manage Jenkins** → **Clouds**
2. Configure cloud provider:
   - Kubernetes
   - Amazon EC2
   - Docker
3. Configure agent templates

**Step 2: Kubernetes Pod Template Example**
1. Install Kubernetes Plugin
2. Configure pod template (see CLI Code Pack below for K8s pod spec)

**Step 3: Configure Auto-Scaling**
1. Set minimum instances to 0
2. Configure scale-up triggers
3. Set idle timeout for termination

---

### 3.4 Secure Agent Communication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10 |
| NIST 800-53 | SC-8 |

#### Description
Secure communication between agents and controller using JNLP over TLS.

#### Rationale
**Why This Matters:**
- Unencrypted agent protocols expose build commands, source code, and secrets to anyone on the network path
- TLS prevents an attacker from intercepting or injecting traffic between the controller and its agents
- Legacy agent protocols have known weaknesses and should be disabled in favor of the TLS-encrypted protocol

**Attack Prevented:** Man-in-the-middle interception, traffic injection, credential and source-code eavesdropping

#### ClickOps Implementation

**Step 1: Configure Agent Protocols**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. Under **Agent protocols**, disable insecure protocols
3. Enable only **Inbound TCP Agent Protocol/4 (TLS encryption)**

**Step 2: Configure HTTPS**
1. Configure Jenkins to run behind HTTPS reverse proxy
2. Or configure HTTPS directly in Jenkins (see CLI Code Pack below)

---

### 3.5 Use WebSocket Transport for Inbound Agents

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.4, 3.10 |
| NIST 800-53 | SC-7, SC-8 |

#### Description
Connect inbound agents over WebSocket transport instead of a dedicated inbound TCP port, so agent traffic rides the existing HTTPS listener.

#### Rationale
**Why This Matters:**
- The classic inbound TCP agent protocol requires a separate listening port on the controller, which is one more externally reachable service to expose, firewall, and monitor
- Jenkins documents that with WebSocket transport "no extra TCP port need be enabled and no special security configuration is needed" — the agent connection reuses the controller's existing HTTP(S) endpoint
- Riding the HTTPS listener means agent traffic inherits the TLS configuration already terminating there, rather than depending on a separately configured agent protocol
- Agents that must cross corporate proxies or restrictive firewalls frequently cannot open an arbitrary inbound TCP port at all; WebSocket removes that as a reason to weaken network policy
- Fewer distinct listening services on the controller is a smaller attack surface for the host that holds every credential in the instance

**Attack Prevented:** Exposure of an additional inbound controller port, network-policy weakening to accommodate agent connectivity, use of legacy agent protocols with weaker transport protection

#### ClickOps Implementation

**Step 1: Confirm Version Support**
1. WebSocket agent transport is available as of **Jenkins 2.217** — verify the controller is at or above that release
2. Ensure any reverse proxy in front of Jenkins is configured to pass WebSocket upgrade requests through

**Step 2: Enable WebSocket on the Agent**
1. Navigate to: **Manage Jenkins** → **Nodes** → select the agent → **Configure**
2. For inbound agents, select the **Use WebSocket** option
3. Reconnect the agent and confirm it comes online over the HTTPS endpoint

**Step 3: Close the Legacy Port**
1. Once all inbound agents are on WebSocket, disable the inbound TCP agent port
2. Remove the corresponding firewall allowances

**Reference:** [Managing Security](https://www.jenkins.io/doc/book/security/managing-security/)

---

## 4. Pipeline Security

### 4.1 Enable CSRF Protection

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.13 |
| NIST 800-53 | SC-8 |

#### Description
Enable CSRF protection to prevent cross-site request forgery attacks.

#### Rationale
**Why This Matters:**
- Without CSRF tokens, a logged-in admin who visits a malicious page can be tricked into triggering Jenkins actions unknowingly
- Attackers can forge requests to start builds, change configuration, or alter permissions using the victim's active session
- The crumb issuer requires a per-session token on state-changing requests, blocking forged cross-origin calls

**Attack Prevented:** Cross-site request forgery, unauthorized configuration changes, forced build triggers

#### ClickOps Implementation

**Step 1: Enable CSRF Protection**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. Under **CSRF Protection**, select **Default Crumb Issuer**
3. Optionally enable **Enable proxy compatibility** if behind a reverse proxy

---

### 4.2 Secure Credentials Management

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Securely manage credentials using Jenkins Credentials Plugin with appropriate scoping.

#### Rationale
**Why This Matters:**
- Jenkins stores deployment keys, cloud tokens, and registry passwords that grant access far beyond Jenkins itself
- Global-scope credentials are reachable by every job, so one compromised pipeline can exfiltrate them all
- Folder- and domain-scoped credentials plus withCredentials binding limit exposure to only the jobs that need them
- Masked, bound credentials keep plaintext secrets out of build logs

**Attack Prevented:** Credential theft, secret leakage in build logs, lateral movement to production systems

#### ClickOps Implementation

**Step 1: Organize Credentials by Scope**
1. Navigate to: **Manage Jenkins** → **Credentials**
2. Create credential domains for different purposes:
   - `production-deployments`
   - `testing-resources`
   - `third-party-integrations`

**Step 2: Use Folder-Scoped Credentials**
1. Create folders for different teams/projects
2. Store credentials at folder level (not global)
3. Only jobs in folder can access credentials

**Step 3: Configure Credential Types**
1. Prefer:
   - SSH Username with private key
   - Secret file
   - Certificates
2. Avoid:
   - Username with password (when possible)

**Step 4: Audit Credential Usage**
1. Install Credentials Binding Plugin
2. Use `withCredentials` in pipelines for explicit binding
3. Audit which jobs use which credentials

> **Plugins routinely leak credentials IDs — and several fixes are still outstanding.** The [2026-08-05 advisory](https://www.jenkins.io/security/advisory/2026-08-05/) alone carries a cluster of Medium-severity issues where a plugin's HTTP endpoint omits a permission check and lets a lower-privileged user enumerate credentials IDs. Five were **unfixed at publication**: Violation Comments to GitLab (CVE-2026-70444, ≤2.62.0), Parameterized Remote Trigger (CVE-2026-70438, ≤3.2.2), Sauce OnDemand (CVE-2026-70445, ≤2.2.0), CodeSonar (CVE-2026-70446, ≤3.6.0), and AWS CodeBuild (CVE-2026-70447, ≤0.59). HCL AppScan (CVE-2026-70433) was fixed in 1.8.4.
>
> Credentials IDs are not the secrets themselves, but they are the targeting information an attacker needs to aim a follow-on attack at the right credential — which is why folder scoping matters more than it appears: an enumerable ID for a credential the attacker's jobs cannot reach is far less useful. Where an unfixed plugin is installed, restrict who holds job-configure permission on it, or remove the plugin.

---

### 4.3 Implement Pipeline Sandbox

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.1 |
| NIST 800-53 | CM-7 |

#### Description
Use Pipeline Groovy Sandbox to restrict what pipeline scripts can do.

#### Rationale
**Why This Matters:**
- Unrestricted pipelines can execute arbitrary Groovy code
- Can access Jenkins internals, file system, network
- Sandbox restricts to approved methods only

**Attack Prevented:** Arbitrary code execution via pipeline scripts, sandbox escape to Jenkins internals, unauthorized file system and network access from a build

#### ClickOps Implementation

**Step 1: Configure Script Security**
1. Navigate to: **Manage Jenkins** → **In-process Script Approval**
2. Review and approve only necessary script signatures
3. Do not approve requests without review

**Step 2: Use Declarative Pipelines**
1. Prefer declarative pipelines over scripted (see SDK Code Pack below for example)

**Step 3: Restrict Script Approval**
1. Limit who can approve scripts
2. Review all approval requests carefully
3. Consider security implications of each approval

---

### 4.4 Secure Jenkinsfile Configuration

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.9 |
| NIST 800-53 | CM-3 |

#### Description
Implement secure Jenkinsfile practices to prevent pipeline attacks.

#### Rationale
**Why This Matters:**
- A Jenkinsfile is executable code in the repository, so anyone who can open a pull request can influence what the pipeline runs
- Hardened pipeline patterns prevent untrusted input and forked PRs from executing privileged steps or reaching secrets
- Pinning tools, scoping credentials, and validating inputs in the Jenkinsfile shrink the supply-chain attack surface

**Attack Prevented:** Poisoned pipeline execution, malicious pull-request builds, secret exfiltration via pipeline code

#### Code Implementation

See the SDK Code Pack below for a secure Jenkinsfile template demonstrating hardened pipeline practices.

---

## 5. Monitoring & Compliance

### 5.1 Enable Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable comprehensive audit logging for security monitoring.

#### Rationale
**Why This Matters:**
- Without an audit trail, configuration changes, credential access, and build triggers leave no record to investigate
- Centralized logs shipped to a SIEM enable detection of anomalous admin actions and after-the-fact forensics
- Tamper-evident logging deters insider abuse and supplies compliance evidence for access and change control

**Attack Prevented:** Undetected configuration tampering, insider abuse, post-incident evidence loss

#### Prerequisites
- Audit Trail Plugin installed

#### ClickOps Implementation

**Step 1: Install Audit Trail Plugin**
1. Navigate to: **Manage Jenkins** → **Plugins** → **Available plugins**
2. Install **Audit Trail** plugin
3. Restart Jenkins

**Step 2: Configure Audit Trail**
1. Navigate to: **Manage Jenkins** → **System** → **Audit Trail**
2. Add logger:
   - **Log file:** `/var/log/jenkins/audit.log`
   - Or **Syslog server** for SIEM integration
3. Configure log pattern and events

**Key Events to Monitor:**
- Login/logout events
- Configuration changes
- Job creation/deletion
- Credential access
- Build triggers

---

### 5.2 Keep Jenkins Updated

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 7.3 |
| NIST 800-53 | SI-2 |

#### Description
Keep Jenkins and all plugins updated with security patches.

#### Rationale
**Why This Matters:**
- Jenkins core and its plugins receive frequent security advisories, and unpatched flaws are routinely exploited in the wild
- Outdated plugins are a leading source of remote code execution and authentication-bypass vulnerabilities in Jenkins
- Staying on the supported LTS line with prompt patching closes known exploit paths before attackers reach them

**Attack Prevented:** Exploitation of known CVEs, remote code execution, authentication bypass

> **Act now if you are below Jenkins 2.576 / LTS 2.568.2.** The [2026-08-05 security advisory](https://www.jenkins.io/security/advisory/2026-08-05/) patches a **Critical** core deserialization flaw plus three High-severity core issues, all affecting Weekly 2.575 and earlier and LTS 2.568.1 and earlier:
>
> | CVE | Jenkins ID | Severity | Issue |
> |-----|-----------|----------|-------|
> | CVE-2026-70426 | SECURITY-3911 | Critical | The JEP-200 class filter is not applied on a fallback resolution path in agent-to-controller communication, permitting deserialization of arbitrary types — a remote code execution path |
> | CVE-2026-70427 | SECURITY-3930 | High | Symbolic link handling during archive (tar) extraction allows arbitrary file creation |
> | CVE-2026-70428 | SECURITY-3927 | High | Path traversal in file parameters allows writing to arbitrary filesystem locations |
> | CVE-2026-70429 | SECURITY-3924 | High | Unicode case-sensitivity handling permits user impersonation and privilege escalation |
>
> CVE-2026-70426 undercuts an assumption this section's other controls rest on: JEP-200 deserialization filtering is a core defense for the agent-to-controller boundary hardened in 3.1, and a bypass path re-opens it regardless of how well that boundary is otherwise configured. Upgrade to **Jenkins 2.576** or **LTS 2.568.2**; there is no configuration-level mitigation for a core class-filter bypass.

#### ClickOps Implementation

**Step 1: Check for Updates**
1. Navigate to: **Manage Jenkins** → **Plugins** → **Updates**
2. Review available updates
3. Prioritize security updates

**Step 2: Configure Update Center**
1. Navigate to: **Manage Jenkins** → **Plugins** → **Advanced**
2. Verify update site URL
3. Consider using LTS release line for stability

**Best Practices:**
- Follow biweekly update cadence
- Stay on latest supported hot-patch release
- Test updates in non-production first
- Subscribe to Jenkins security advisories

---

## 6. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Jenkins Control | Guide Section |
|-----------|-----------------|---------------|
| CC6.1 | Authentication | [1.1](#11-enable-authentication) |
| CC6.1 | SSO | [1.2](#12-configure-ldap-or-saml-sso) |
| CC6.2 | Authorization | [2.1](#21-configure-matrix-based-security) |
| CC6.6 | Agent security | [3.1](#31-verify-agent-to-controller-access-control-never-disable-it) |
| CC7.2 | Audit logging | [5.1](#51-enable-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Jenkins Control | Guide Section |
|---------|-----------------|---------------|
| IA-2 | Authentication | [1.1](#11-enable-authentication) |
| AC-6 | Least privilege | [2.1](#21-configure-matrix-based-security) |
| AC-6(1) | RBAC | [2.3](#23-configure-role-based-access-control) |
| CM-7 | Minimize function | [3.2](#32-disable-builds-on-controller) |
| SC-7 | Agent transport boundary | [3.5](#35-use-websocket-transport-for-inbound-agents) |
| AU-2 | Audit logging | [5.1](#51-enable-audit-logging) |

---

## Appendix A: Essential Security Plugins

| Plugin | Purpose | Priority |
|--------|---------|----------|
| SAML Plugin | SSO authentication | High |
| Role-based Authorization Strategy | Fine-grained RBAC | High |
| Audit Trail | Security logging | High |
| Credentials Binding | Secure credential usage | High |
| Folders | Credential scoping | Medium |
| Configuration as Code | Automated security config | Medium |

---

## Appendix B: References

**Official Jenkins Documentation:**
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Managing Security](https://www.jenkins.io/doc/book/security/managing-security/)
- [Securing Jenkins](https://www.jenkins.io/doc/book/security/securing-jenkins/)
- [Jenkins Security Advisories](https://www.jenkins.io/security/advisories/)
- [Jenkins Security Page](https://www.jenkins.io/security/)

**API & Developer Resources:**
- [Remote Access API](https://www.jenkins.io/doc/book/using/remote-access-api/)
- [Jenkins CLI](https://www.jenkins.io/doc/book/managing/cli/)

**Plugins:**
- [SAML Plugin](https://plugins.jenkins.io/saml/)
- [Role-Based Authorization Strategy](https://plugins.jenkins.io/role-strategy/)
- [Microsoft Entra ID Plugin](https://plugins.jenkins.io/azure-ad/)
- [Audit Trail Plugin](https://plugins.jenkins.io/audit-trail/)

**Compliance Frameworks:**
- Jenkins is an open-source project and does not hold SOC 2, ISO 27001, or similar certifications as a product. Organizations self-hosting Jenkins are responsible for their own compliance posture. CloudBees, the commercial Jenkins vendor, maintains its own compliance certifications for CloudBees CI.

**Security Incidents:**
- **CVE-2026-70426 (SECURITY-3911, Critical):** The JEP-200 class filter is not applied on a fallback resolution path in agent-to-controller communication, allowing deserialization of arbitrary types and enabling remote code execution. Affects Jenkins Weekly 2.575 and earlier and LTS 2.568.1 and earlier. Fixed in Jenkins 2.576 and LTS 2.568.2. Published in the [2026-08-05 advisory](https://www.jenkins.io/security/advisory/2026-08-05/).
- **CVE-2026-70427 (SECURITY-3930, High):** Symbolic link handling during tar archive extraction permits arbitrary file creation. Same affected and fixed versions as above.
- **CVE-2026-70428 (SECURITY-3927, High):** Path traversal in file parameters permits writing to arbitrary filesystem locations. Same affected and fixed versions as above.
- **CVE-2026-70429 (SECURITY-3924, High):** Unicode case-sensitivity handling permits user impersonation and privilege escalation. Same affected and fixed versions as above.
- **Credentials-ID enumeration cluster (Medium, several unfixed):** the same advisory documents multiple plugins whose endpoints omit permission checks and expose credentials IDs — five unfixed at publication (Violation Comments to GitLab, Parameterized Remote Trigger, Sauce OnDemand, CodeSonar, AWS CodeBuild). See [4.2](#42-secure-credentials-management).
- **CVE-2024-23897 (CVSS 9.8):** Critical path traversal flaw in Jenkins CLI allowing unauthenticated arbitrary file read; actively exploited in ransomware attacks and added to CISA KEV catalog. Fixed in Jenkins 2.442 and LTS 2.426.3.
- Jenkins regularly publishes security advisories at [jenkins.io/security/advisories](https://www.jenkins.io/security/advisories/) covering core and plugin vulnerabilities.

**Third-Party Resources:**
- [Jenkins Security Best Practices - Wiz](https://www.wiz.io/lp/jenkins-security-best-practices-cheat-sheet)
- [Jenkins Security Best Practices - Cycode](https://cycode.com/blog/jenkins-security-best-practices/)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass: add the 2026-08-05 advisory (CVE-2026-70426 Critical JEP-200 class-filter bypass plus three High core issues; fixed 2.576 / LTS 2.568.2) to Appendix B and 5.2, and the unfixed credentials-ID-enumeration plugin cluster to 4.2; reframe 3.1 as verify-and-never-disable because Agent → Controller Access Control has been always-enabled since 2.326; add 3.5 (WebSocket agent transport, 2.217+); correct 1.3 — its steps disabled self-registration rather than remember-me, so the control was retitled to match what it does and the remember-me mechanism left explicitly unverified rather than invented; add **Attack Prevented:** to 1.1, 2.1, 2.4, 3.1, 3.2, 4.3 so they render in the cheat sheet; fix "Manage Plugins" path drift in 5.2. Tier 2 not surveyed this pass (the CIS index was not checked); Tier 3/4 not surveyed. | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2026-02-19 | 0.1.1 | draft | Migrate inline code to SDK/CLI Code Packs (1.3, 3.3, 3.4, 4.3, 4.4); remove lang= from includes | Claude Code (Opus 4.6) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with authentication, authorization, and pipeline security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
