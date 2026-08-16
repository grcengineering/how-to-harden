---
layout: guide
title: "Buildkite Hardening Guide"
vendor: "Buildkite"
slug: "buildkite"
tier: "2"
category: "DevOps"
description: "CI/CD platform hardening for Buildkite including SAML SSO, team permissions, agent security, and pipeline controls"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

Buildkite is a CI/CD platform enabling organizations to run fast, secure builds on their own infrastructure. As a platform managing build pipelines and deployment workflows, Buildkite security configurations directly impact software supply chain security.

### Intended Audience
- Security engineers managing CI/CD platforms
- Platform engineers configuring Buildkite
- DevOps teams managing pipelines
- GRC professionals assessing build security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for Buildkite users.

#### Rationale
**Why This Matters:**
- Centralizes Buildkite authentication in your corporate IdP, enforcing MFA, conditional access, and session policy on every login
- Local Buildkite passwords bypass IdP controls and are prime targets for credential stuffing and phishing
- Group-to-team mapping plus IdP deprovisioning removes departed employees' access automatically, eliminating orphaned accounts
- Buildkite pipelines hold deployment credentials and source-build access, so a single compromised login can poison the software supply chain

**Attack Prevented:** Credential theft, phishing, MFA bypass, orphaned-account access

#### Prerequisites
- Buildkite organization admin access
- **Pro or Enterprise plan.** SSO is not available below Pro, and there is no "Business" tier — if a runbook or vendor questionnaire references one, it is wrong.
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Organization Settings** → **Single Sign On**
2. Select SAML provider type

**Step 2: Configure SAML**
1. Configure IdP settings:
   - SSO URL
   - Entity ID
   - Certificate
2. Configure attribute mapping
3. Map groups to teams

**Step 3: Test and Enforce**
1. Test SSO authentication with a non-admin account before touching enforcement.
2. Set SSO to **required** rather than optional. Buildkite tracks this per user, so an organization is only actually covered once every member is on the required setting — a partially-required organization still has password login paths open.
3. Enforce SSO organization-wide by **disabling 2FA authentication** as a login method. This is the counterintuitive part: leaving password-plus-2FA available is what keeps a non-SSO path alive, so disabling it is how the IdP becomes the only front door.
4. New members are provisioned **just-in-time on first login** through the IdP, so group-to-team mapping needs to be correct before you enforce, not after.
5. Document the admin fallback path before enforcement, so an IdP outage does not lock the organization out.

**Step 4: Tighten Session and Network Controls**
1. Set the **session timeout** to the shortest value your teams will tolerate. The supported range runs from 6 hours to 1 year; a year-long session on a CI platform holding deployment credentials is functionally a permanent one.
2. **IP address pinning (Enterprise):** enable it to revoke a session the moment the source IP changes. This is a cheap and effective defense against a stolen session cookie being replayed from elsewhere.
3. **SCIM deprovisioning (Enterprise):** connect SCIM so that removing someone in the IdP removes their Buildkite access rather than leaving an orphaned account behind.

Source: [Buildkite SSO](https://buildkite.com/docs/platform/sso)

**Time to Complete:** ~1-2 hours

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="1.1" %}

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Buildkite users.

#### Rationale
**Why This Matters:**
- A second factor blocks attackers who have already obtained a valid Buildkite password through phishing, reuse, or a breach
- CI/CD accounts can trigger builds and deployments, so a single-factor takeover can reach production
- Org-wide enforcement closes the gap left by users who would otherwise never enable 2FA voluntarily
- Phishing-resistant factors for admins protect the highest-privilege accounts against real-time relay attacks

**Attack Prevented:** Credential stuffing, password reuse, phishing, account takeover

#### ClickOps Implementation

**Step 1: Enable 2FA Requirement**
1. Navigate to: **Organization Settings** → **Security**
2. Enable **Enforce Two-factor authentication**
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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Buildkite teams.

#### Rationale
**Why This Matters:**
- Scoping each team to only the pipelines it needs limits the blast radius if any one account is compromised
- Granular permission levels (Read & Build versus Full Access) prevent over-broad rights that let any user modify pipeline configuration
- Quarterly membership reviews catch privilege creep and remove access from people who changed roles
- Function-based teams make access auditable and map cleanly to compliance least-privilege requirements

**Attack Prevented:** Privilege escalation, lateral movement, insider misuse, unauthorized pipeline changes

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

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control access to specific pipelines.

#### Rationale
**Why This Matters:**
- Per-pipeline visibility keeps sensitive production and deployment pipelines hidden from users who have no need to see them
- Restricting who can trigger builds prevents unauthorized or accidental runs against production
- Limiting manual builds on production reduces the chance of an attacker forcing a malicious deployment
- Auditing build triggers creates accountability for every pipeline execution

**Attack Prevented:** Unauthorized deployment, pipeline tampering, supply chain injection, information disclosure

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### Rationale
**Why This Matters:**
- Organization admins can change SSO, permissions, agent tokens, and billing, so a compromised admin account compromises everything
- Keeping admins to a small set reduces the number of high-value targets an attacker can phish
- Requiring SSO and 2FA on admins ensures the most powerful accounts get the strongest authentication
- Monitoring admin activity surfaces anomalous configuration changes before they cause damage

**Attack Prevented:** Admin account takeover, privilege escalation, configuration tampering, persistence

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

### 2.4 Control Untrusted Input to Pipelines

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.1 |
| NIST 800-53 | SI-10, CM-7 |

#### Description
Constrain what a build is allowed to do when the code or configuration driving it comes from somewhere you do not fully control — forks, third-party plugins, or a `pipeline.yml` that an untrusted contributor can edit.

#### Rationale
**Why This Matters:**
- A build triggered by a fork runs contributor-authored code on your agents with whatever credentials those agents hold, which turns an open-source contribution into a credential-harvesting opportunity
- Plugins are third-party code executed inside your build; an unpinned plugin reference means whatever the plugin author publishes next runs in your pipeline without review
- Command evaluation and interpolation let a `pipeline.yml` upload arbitrary steps mid-build, so a repository writer can escape the pipeline definition that was actually reviewed
- Agent-side controls are the only ones a malicious `pipeline.yml` cannot switch off, which is why the defense has to live on the agent rather than in the pipeline file

**Attack Prevented:** Poisoned pipeline execution from fork builds, supply-chain compromise via mutable third-party plugins, secret exfiltration through injected build steps, agent takeover from untrusted contributions

#### ClickOps Implementation

**Step 1: Close the Fork Path on Public Pipelines**
1. For any pipeline with public visibility, disable builds triggered by forked repositories unless you have a specific reason to allow them and an agent pool with no production credentials to run them on.

**Step 2: Constrain Plugins**
1. Prefer plugins you host privately over public ones.
2. Pin every plugin reference to a specific version or commit — a floating reference is an unreviewed dependency.
3. On agents that should never load third-party code at all, run the agent with `--no-plugins`.

**Step 3: Disable Command Evaluation Where It Is Not Needed**
1. Configure agents to reject command evaluation and dynamic step uploads on pools that run untrusted code, so the reviewed pipeline definition is the only definition that executes.
2. Enable the agent's **reject-secrets** guard so builds that try to surface secret-looking values are stopped rather than logged.

**Step 4: Bound the Blast Radius**
1. Set job time limits so a hijacked build cannot mine, scan, or exfiltrate indefinitely.
2. Put your enforcement in **agent lifecycle hooks**, which live on the agent host and cannot be overridden by `pipeline.yml`.

Source: [Buildkite security controls](https://buildkite.com/docs/pipelines/best-practices/security-controls)

---

### 2.5 Manage API Access Token Hygiene

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | IA-5, AC-6 |

#### Description
Govern Buildkite **API access tokens** — the user-scoped REST and GraphQL credentials — as a separate credential class from the agent tokens covered in [3.1](#31-configure-agent-tokens).

#### Rationale
**Why This Matters:**
- API access tokens and agent tokens are routinely conflated, and rotating one while forgetting the other leaves half the credential surface untouched
- An API token carries the permissions of the user who created it, so a broad token from an admin is an admin credential sitting in a script
- Tokens without expiry accumulate silently in CI systems, laptops, and automation until nobody knows which ones are still live
- GraphQL is expressive enough that a token with unnecessary scope can read far more of the organization than the integration it was created for ever needed

**Attack Prevented:** Standing API access from leaked tokens, privilege inheritance from over-scoped admin tokens, undetected token reuse, data harvesting via over-broad GraphQL access

#### ClickOps Implementation

**Step 1: Scope and Time-Bound Every Token**
1. Grant each token the narrowest scope set that its integration actually uses — start from nothing and add scopes until the integration works, rather than trimming from full access.
2. Give tokens an expiry and automate their rotation, so expiry is a scheduled event rather than an outage.

**Step 2: Restrict Where Tokens Can Be Used**
1. Apply an IP range restriction to each token so a stolen token is unusable from outside your network egress.

**Step 3: Narrow GraphQL Exposure**
1. Where an integration only needs a fixed set of queries, use **Portals** to expose those specific operations instead of handing out a general GraphQL token.

**Step 4: Monitor Token Use**
1. Review token activity in the audit log (see [4.1](#41-configure-audit-logging)) and revoke tokens that stop appearing — an unused token is pure standing risk.

Source: [Buildkite security controls](https://buildkite.com/docs/pipelines/best-practices/security-controls)

---

## 3. Agent Security

### 3.1 Configure Agent Tokens

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Securely manage agent registration tokens.

#### Rationale
**Why This Matters:**
- Agent tokens let any holder register a build agent and execute pipeline jobs, so a leaked token is effectively code execution in your CI
- Scoping tokens per environment confines a leaked token to a single cluster rather than the whole organization
- Regular rotation shrinks the window an exposed token remains usable
- Revoking unused tokens removes standing credentials that attackers could discover in code, logs, or images

**Attack Prevented:** Agent impersonation, unauthorized job execution, credential leakage, supply chain compromise

#### ClickOps Implementation

**Step 1: Create Tokens Inside a Cluster**
1. Navigate to the cluster's **Agent tokens** page — agent tokens are **cluster-scoped**. A token belongs to exactly one cluster and cannot be used to register an agent into a different cluster or organization, which means the scoping work is largely done for you once your clusters are right (see [3.2](#32-configure-agent-clusters)).
2. Create a separate token per cluster rather than reusing one across environments.

**Step 2: Bound the Token in Time**
1. Set an **expiration timestamp** when creating the token. Two constraints matter operationally:
   - Expirations can only be set through the API — tokens created in the web UI have **no expiry at all** and must be rotated by hand.
   - The expiry must be at least 10 minutes in the future, and once set it is **immutable**. Rotation means creating a replacement token, not extending the existing one, so build the replacement step into your rotation runbook.

**Step 3: Bound the Token in Space**
1. Set **Allowed IP Addresses** on the token — a CIDR allowlist of the networks your agents register from. A token that leaks outside those ranges is inert.

**Step 4: Handle Tokens Safely**
1. Store tokens in a secrets manager, never in an agent AMI, container image, or repository.
2. Rotate on a schedule and revoke tokens that no agent is presenting.

Sources: [Buildkite agent tokens](https://buildkite.com/docs/agent/v3/tokens) · [Manage clusters](https://buildkite.com/docs/pipelines/clusters/manage-clusters)

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="3.1" %}

---

### 3.2 Configure Agent Clusters

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Isolate agents by environment or sensitivity using clusters, which are now the standard organizing unit for agents rather than an optional enhancement.

#### Deprecation: Unclustered Agents

Unclustered agents and unclustered agent tokens are **deprecated**, and organizations created after **2024-02-26** cannot use them at all — for those organizations every agent lives in a cluster by construction. Older organizations that still run unclustered agents should follow Buildkite's documented migration path onto clusters rather than treating clustering as optional hardening. ([Manage clusters](https://buildkite.com/docs/pipelines/clusters/manage-clusters))

#### Rationale
**Why This Matters:**
- Separating production, development, and sensitive builds prevents a compromised low-trust agent from reaching production secrets
- Targeting pipelines to specific clusters enforces a hard boundary that a malicious build cannot cross
- Restricting production cluster access limits which jobs can touch deployment credentials and live systems
- Cluster-level isolation contains the blast radius of any single compromised build host

**Attack Prevented:** Lateral movement, secret exfiltration, cross-environment contamination, privilege escalation

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

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Secure agent host infrastructure.

#### Rationale
**Why This Matters:**
- Agents execute arbitrary pipeline code, so a hardened host is the primary defense against builds being used to attack your network
- Ephemeral agents destroy any attacker foothold after each job, preventing persistence and cross-build contamination
- Minimizing installed software and applying OS hardening reduces the exploitable attack surface on every build host
- Restricting agent network access prevents a compromised build from pivoting to internal systems or exfiltrating data

**Attack Prevented:** Build host compromise, persistence, lateral movement, data exfiltration

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

### 3.4 Enable Pipeline Signing and Verification

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.9 |
| NIST 800-53 | SI-7 |

#### Description
Cryptographically sign pipeline steps so agents will only execute a pipeline whose commands are provably the ones Buildkite was given, rejecting anything altered in transit or injected along the way.

#### Rationale
**Why This Matters:**
- Without signing, an agent executes whatever step definition reaches it, and the agent has no way to distinguish a legitimate command from a substituted one
- Signing moves the trust boundary to a key you control rather than to the integrity of every system between the pipeline definition and the agent
- Verification happens on the agent, which is the last point before execution and therefore the only place the check cannot be bypassed by an earlier compromise
- **This is not on by default.** An organization that has never configured signing keys is running unverified pipelines, which is easy to miss because nothing about the build output looks different

**Attack Prevented:** Command injection into pipeline steps, tampering with step definitions in transit, execution of unauthorized build commands, supply-chain compromise between pipeline definition and agent

#### ClickOps Implementation

**Step 1: Choose a Key Backend**
1. **JWKS file:** point the agent at a key set with `--jwks-file`, selecting the signing key with `--jwks-key-id`.
2. **AWS KMS** or **GCP KMS:** keep the private key in a managed KMS so it is never on the agent host at all. Prefer this where your agents run in a cloud you already trust with key material.

**Step 2: Enable Signing and Verification**
1. Configure the signing key on the agents responsible for uploading pipelines, and the verification key on every agent that executes steps.
2. Roll out verification in a warning posture first, then move to rejecting unsigned steps once the fleet is covered — an agent that verifies before the uploaders sign will fail every build.

**Step 3: Keep Signing Diagnostics Out of Production**

**Do not leave `--debug-signing` enabled.** It writes signing diagnostics into build logs and can expose secret values there. Use it to troubleshoot a rollout and turn it off immediately afterward.

Source: [Signed pipelines](https://buildkite.com/docs/agent/v3/cli-pipeline#signed-pipelines)

---

### 3.5 Manage Build Secrets

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12, SC-28 |

#### Description
Deliver secrets to builds through a managed secret store rather than environment variables baked into agent hosts, pipeline settings, or repositories.

#### Rationale
**Why This Matters:**
- Secrets set as plain pipeline or agent environment variables are visible to every step in the build, including third-party plugins, and frequently end up echoed into logs
- A secret stored on the agent host outlives the job, so one compromised build can harvest credentials belonging to every other pipeline that agent serves
- Cluster-scoped storage means a secret is reachable only by agents in that cluster, which turns the cluster boundary established in [3.2](#32-configure-agent-clusters) into a secrets boundary as well
- Automatic log redaction removes the most common exposure path — an accidental `echo` — without relying on every pipeline author to be careful

**Attack Prevented:** Secret leakage through build logs, credential theft from agent hosts, cross-pipeline secret exposure, hardcoded credentials in repositories

#### Prerequisites
- Buildkite agent **v3.106.0 or later** for Buildkite-managed secrets.

#### ClickOps Implementation

**Step 1: Prefer an External Secret Service Where You Have One**

Buildkite's own first recommendation is to use an external secrets service — HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, or equivalent — retrieved at job time. If you already run one, that remains the primary path, and Buildkite secrets are the option for teams that do not.

**Step 2: Use Cluster-Scoped Buildkite Secrets**
1. Create secrets on the cluster that needs them. Each cluster has its own encryption key, and secrets are encrypted in transit and at rest.
2. Values are **automatically redacted from build logs**.
3. Work within the documented limits: keys up to 255 characters, values up to 32 KB, and **keys are immutable** — changing a key name means creating a new secret and deleting the old one.

**Step 3: Scope and Review**
1. Keep production secrets in the production cluster only, so a development agent has no path to them.
2. Review secrets alongside the cluster's agent tokens, since the two together define what a compromised agent can reach.

Sources: [Buildkite secrets](https://buildkite.com/docs/pipelines/security/secrets/buildkite-secrets) · [Managing secrets](https://buildkite.com/docs/pipelines/security/secrets/managing)

---

### 3.6 Use OIDC Instead of Static Cloud Credentials

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | IA-5, IA-9 |

#### Description
Let builds obtain short-lived cloud credentials by exchanging a Buildkite OIDC token, rather than storing long-lived cloud access keys anywhere in the CI system.

#### Rationale
**Why This Matters:**
- A static cloud access key stored for CI never expires on its own, so its exposure window is bounded only by how quickly someone notices
- OIDC-issued credentials are minted per job and expire on their own, which makes a leaked build log far less valuable to an attacker
- The trust relationship is pinned to a specific pipeline and organization in the cloud provider's policy, so a token from elsewhere in your CI cannot assume the role
- Removing static keys removes the single highest-value target in most CI environments — the credential that grants production cloud access

**Attack Prevented:** Cloud account takeover through leaked CI credentials, long-lived standing access to cloud accounts, credential reuse outside the build that earned it

#### ClickOps Implementation

**Step 1: Establish the Trust Relationship**
1. In your cloud provider, configure Buildkite as an OIDC identity provider and constrain the trust policy to your organization and the specific pipelines that need the role.

**Step 2: Adopt the Exchange Plugins**
1. **AWS:** use the `aws-assume-role-with-web-identity` plugin to trade the Buildkite OIDC token for temporary STS credentials.
2. **GCP:** use the `gcp-workload-identity-federation` plugin.
3. **HashiCorp Vault:** use the `vault-secrets` plugin to authenticate and fetch secrets without a static Vault token in the pipeline.

**Step 3: Remove What You Replaced**
1. Delete the static access keys the pipelines previously used, and confirm in the cloud provider that they are no longer being exercised. A migration that leaves the old key live has added a path rather than closed one.

Source: [Buildkite security controls](https://buildkite.com/docs/pipelines/best-practices/security-controls)

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs.

#### Rationale
**Why This Matters:**
- Audit logs of authentication, pipeline changes, and permission edits are the primary evidence for detecting and investigating compromise
- Monitoring agent token usage surfaces stolen tokens being used from unexpected sources
- Appropriate retention ensures records survive long enough to support incident response and compliance audits
- Without logging, attacker actions such as permission changes and malicious pipeline edits go unnoticed

**Attack Prevented:** Undetected intrusion, repudiation, delayed incident response, audit gaps

#### Prerequisites
- **Buildkite Enterprise.** The audit log is an Enterprise-plan feature; organizations below Enterprise have no audit log to review, and compliance commitments that assume one need to account for that gap.

#### ClickOps Implementation

**Step 1: Access the Audit Log**
1. Navigate to: **Organization Settings** → **Audit** → **Audit Log**
2. **There is no retention setting to configure.** Buildkite stores audit events indefinitely; what varies is where you can reach them:
   - The web UI browses the most recent **12 months**
   - Older events are retrieved through the **GraphQL API**
3. Understand the search limits before relying on the UI for an investigation: search covers the **last 90 days** and accepts at most **3 terms** totalling **250 characters**. Anything wider than that is a query against the API, not a search in the console.

**Step 2: Monitor Events**
1. User authentication
2. Pipeline changes
3. Permission modifications
4. Agent token usage
5. API access token activity (see [2.5](#25-manage-api-access-token-hygiene))

**Step 3: Export Rather Than Browse**
1. **Amazon EventBridge:** stream audit events continuously into your own pipeline, which is the practical way to alert on them rather than discover them later.
2. **REST and GraphQL APIs:** retrieve events programmatically — the GraphQL API is also the only route to events older than the 12-month UI window.

Source: [Buildkite audit log](https://buildkite.com/docs/pipelines/security/audit-log)

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="4.1" %}

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Buildkite Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Team permissions | [2.1](#21-configure-team-permissions) |
| CC6.6 | API access token restrictions | [2.5](#25-manage-api-access-token-hygiene) |
| CC6.7 | Agent tokens | [3.1](#31-configure-agent-tokens) |
| CC6.7 | Build secrets management | [3.5](#35-manage-build-secrets) |
| CC7.1 | Untrusted input controls | [2.4](#24-control-untrusted-input-to-pipelines) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |
| CC8.1 | Pipeline signing | [3.4](#34-enable-pipeline-signing-and-verification) |

### NIST 800-53 Rev 5 Mapping

| Control | Buildkite Control | Guide Section |
|---------|-------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | 2FA | [1.2](#12-enforce-two-factor-authentication) |
| AC-6 | Team permissions | [2.1](#21-configure-team-permissions) |
| SI-10 | Untrusted input controls | [2.4](#24-control-untrusted-input-to-pipelines) |
| IA-5 | API access token hygiene | [2.5](#25-manage-api-access-token-hygiene) |
| SC-12 | Agent tokens | [3.1](#31-configure-agent-tokens) |
| SI-7 | Pipeline signing | [3.4](#34-enable-pipeline-signing-and-verification) |
| SC-28 | Build secrets management | [3.5](#35-manage-build-secrets) |
| IA-9 | OIDC federation for cloud access | [3.6](#36-use-oidc-instead-of-static-cloud-credentials) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |

**On benchmark coverage:** there is no CIS Benchmark, DISA STIG, or CISA SCuBA baseline for Buildkite — the CIS Benchmark index was checked and returned no Buildkite entry. The mappings above are to the general control catalogs only, and no product-specific benchmark IDs exist to cite.

---

## Appendix A: References

**Official Buildkite Documentation:**
- [Buildkite Documentation](https://buildkite.com/docs)
- [Security Controls Best Practices](https://buildkite.com/docs/pipelines/best-practices/security-controls)
- [SSO](https://buildkite.com/docs/platform/sso)
- [Team Permissions](https://buildkite.com/docs/team-management/permissions)
- [Securing Your Agent](https://buildkite.com/docs/agent/v3/securing)
- [Agent Tokens](https://buildkite.com/docs/agent/v3/tokens)
- [Manage Clusters](https://buildkite.com/docs/pipelines/clusters/manage-clusters)
- [Signed Pipelines](https://buildkite.com/docs/agent/v3/cli-pipeline#signed-pipelines)
- [Buildkite Secrets](https://buildkite.com/docs/pipelines/security/secrets/buildkite-secrets) · [Managing Secrets](https://buildkite.com/docs/pipelines/security/secrets/managing)
- [Audit Log](https://buildkite.com/docs/pipelines/security/audit-log)

**API Documentation:**
- [Buildkite APIs](https://buildkite.com/docs/apis)
- [REST API Reference](https://buildkite.com/docs/apis/rest-api)
- [GraphQL API](https://buildkite.com/docs/apis/graphql-api)

**Compliance Frameworks:**
- SOC 2 Type II — Buildkite undergoes an annual audit covering Pipelines, Package Registries, and Test Engine; request the current report through your Buildkite account team

**Security Incidents:**
- No major public security breaches identified. Buildkite maintains annual third-party penetration testing and a private HackerOne bug bounty program.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass. **1.1:** correct the plan gate to Pro or Enterprise (no "Business" tier exists) and expand enforcement — SSO required/optional is per user, organization-wide enforcement works by disabling 2FA authentication as a login method, session timeout ranges from 6 hours to 1 year, IP address pinning revokes a session on IP change (Enterprise), SCIM deprovisioning (Enterprise), and members are provisioned just-in-time on first login. **3.1:** correct agent tokens to cluster-scoped, and add expiration timestamps (API-only, at least 10 minutes out, immutable once set; web-UI tokens have no expiry) and the Allowed IP Addresses CIDR allowlist. **3.2:** add the unclustered agents and tokens deprecation, unavailable to organizations created after 2024-02-26. **4.1:** correct the non-existent retention setting — the audit log is Enterprise-only at Organization Settings → Audit → Audit Log, events are stored indefinitely, the UI browses 12 months with older events via GraphQL, and search covers 90 days with 3 terms and 250 characters; add EventBridge streaming and REST/GraphQL retrieval. **New controls:** 2.4 untrusted-input pipeline controls, 2.5 API access token hygiene, 3.4 pipeline signing and verification, 3.5 build secrets management, 3.6 OIDC instead of static cloud credentials. **§5:** add mappings for the new controls and record that no CIS, DISA, or SCuBA baseline exists for Buildkite. **Appendix A:** remove the Trust Center and marketing security-page rows and add the newly cited documentation. Not surveyed this pass: Tier 3/4 research | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, teams, and agent security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
