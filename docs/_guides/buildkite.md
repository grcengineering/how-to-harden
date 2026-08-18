---
layout: guide
title: "Buildkite Hardening Guide"
vendor: "Buildkite"
slug: "buildkite"
tier: "2"
category: "DevOps"
description: "CI/CD platform hardening for Buildkite including SAML SSO, team permissions, agent security, and pipeline controls"
version: "0.3.0"
maturity: "draft"
last_updated: "2026-08-18"
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

#### Prerequisites

- **ClickOps: none.** The Security page toggle is available on every plan.
- **Terraform: a plan that includes the API IP allowlist feature.** The `buildkite_organization` resource fails to create without it, even when your configuration sets only `enforce_2fa` and never mentions IP allowlisting — the provider touches that field regardless. Verified against a live organization: `Unable to create Organization settings: input: The API IP allowlist feature is not available for your organization. Please upgrade your plan to access it.` The same resource backs [4.1](#41-configure-audit-logging), so that control inherits the constraint. On plans without the feature, use the ClickOps path below; `terraform validate` and `terraform plan` both pass, so this surfaces only at `apply`.

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

**Step 3: Set the Organization-Level Pipeline Toggles**
1. Go to **Settings → Security → Pipelines** and review the six organization-wide toggles: **Create Pipelines**, **Delete Pipelines**, **Change Pipeline Visibility**, **Manage Notification Services**, **Manage Agent Registration Tokens**, and **Stop Agents**.
2. These are distinct from the team-level `members_can_create_pipelines` setting in [2.1](#21-configure-team-permissions) — a team can be denied pipeline creation while the organization still permits every member to create one.
3. **Change Pipeline Visibility** is the toggle that most directly undoes Step 1: leaving it open means any member can flip a private pipeline public regardless of how the pipeline itself is configured.

**Automation:** ClickOps only — Buildkite exposes no write interface for these six toggles. REST `/organizations` is GET-only, none of the 85 GraphQL mutations sets them, and `buildkite_organization` exposes only `allowed_api_ip_addresses` and `enforce_2fa` ([organization settings](https://buildkite.com/docs/pipelines/security/permissions), verified against the live schema 2026-08-18). This step is Enterprise-gated and must be verified in the console.

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

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="2.4" %}

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
2. **A portal is not automatically a downgrade in privilege.** Portal tokens carry administrator-level permissions *within the operations the portal exposes*, and they are long-lived. A portal whose query is written loosely is an admin credential with a friendlier name — scope the query itself, and set the portal's IP allowlist.

**Step 4: Monitor Token Use**
1. Review token activity in the audit log (see [4.1](#41-configure-audit-logging)) and revoke tokens that stop appearing — an unused token is pure standing risk.

**Step 5: Automate Revocation of Inactive Tokens**
1. Set the organization's **inactive token revocation period** so Buildkite revokes tokens that go unused for a chosen window (30, 60, 90, 180 or 365 days). This turns Step 4 from a recurring human task into a platform guarantee, and it is the single highest-leverage organization-wide setting on this control.
2. The setting is **Enterprise**-gated. The current value is readable on any plan, so you can at least detect that it is unset.

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="2.5" %}

Source: [Buildkite security controls](https://buildkite.com/docs/pipelines/best-practices/security-controls)

---

### 2.6 Remove Dormant Organization Members

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2(3) |

#### Description
Find organization members who have stopped using Buildkite and remove them, as a recurring review rather than a one-off cleanup.

#### Rationale
**Why This Matters:**
- SCIM deprovisioning only catches people who left the company; it does nothing about a current employee who moved to another team two years ago and still holds pipeline access
- A dormant account is the ideal account to compromise precisely because nobody is watching it — there is no legitimate activity for malicious activity to stand out against
- Buildkite membership survives changes that feel like they should have removed it, including team deletion and repository access changes, so access accumulates by default
- Nobody notices an account that does nothing, which means the window between compromise and detection on a dormant account is bounded only by your audit-log retention

**Attack Prevented:** Persistent access via abandoned accounts, privilege accumulation across internal role changes, undetected credential reuse against accounts with no baseline activity

#### ClickOps Implementation

**Step 1: Establish a Dormancy Threshold**
1. Pick an inactivity window that matches your access-review cadence — 90 days is a common starting point, and it should be shorter than your audit-log retention so you can still investigate what a dormant account did before you remove it.
2. Write the threshold down as policy, because a threshold that lives only in someone's head produces inconsistent reviews.

**Step 2: Review Members Against It**
1. Go to **Settings → Users** and sort by last activity.
2. For each member past the threshold, confirm with their manager whether the access is still needed rather than assuming dormancy means departure.

**Step 3: Remove and Record**
1. Remove members whose access is no longer needed.
2. Record the review itself — an access review you cannot evidence is an access review you cannot claim in an audit.

**Note on availability:** the Inactive User List and the `inactiveSince` filter are Enterprise features that also require Audit Logging. On lower plans, read `lastSeenAt` per member and filter client-side; the Code Pack does this automatically when the filter is unavailable.

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="2.6" %}

Source: [Buildkite user management](https://buildkite.com/docs/platform/team-management/permissions)

---

### 2.7 Govern Cross-Pipeline Access with Rules

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.8 |
| NIST 800-53 | AC-3, AC-4 |

#### Description
Use Buildkite **Rules** to declare explicitly which pipelines may trigger which other pipelines and read each other's artifacts, instead of relying on the implicit permissions that team membership grants.

#### Rationale
**Why This Matters:**
- Rules **override the usual trigger-step permission checks**, so a rule is not a tightening of existing permissions — it is a separate grant that can widen them, and an unreviewed rule is a standing authorization nobody audited
- Artifact-read rules cross **cluster boundaries**, which means a rule can quietly undo the isolation that [3.2](#32-configure-agent-clusters) was configured to enforce
- A public pipeline can be granted the ability to trigger a private one, turning a low-trust entry point into a path to high-trust infrastructure
- Cross-pipeline triggering is the most direct lateral-movement primitive Buildkite offers, and without an inventory of rules there is no way to answer "what can this pipeline reach"

**Attack Prevented:** Lateral movement from a compromised low-trust pipeline into production pipelines, cross-cluster artifact exfiltration, privilege escalation through unreviewed trigger grants

#### ClickOps Implementation

**Step 1: Inventory What Exists**
1. Go to **Settings → Rules** and list every rule currently defined.
2. For each, identify the source pipeline, the target pipeline, and who added it — a rule with no owner is a rule to remove.

**Step 2: Apply Deny-by-Default**
1. Remove rules that are not tied to a documented workflow. Cross-pipeline access should be the exception you justified, not the default you inherited.
2. Where a rule is needed, scope it to the narrowest source and target pair that makes the workflow function.

**Step 3: Review Rules on the Same Cadence as Permissions**
1. Add rules to your access-review cycle. They grant access, so they age the same way permissions do.

**Note:** Rules are in public preview and available on all plans. They are exposed through Terraform, GraphQL (`ruleCreate`/`ruleUpdate`/`ruleDelete`) and REST (`/v2/organizations/{org}/rules`).

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="2.7" %}

Source: [Buildkite rules](https://buildkite.com/docs/pipelines/security/rules)

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
2. **Lockout warning — this allowlist strands agents.** The list is enforced at *registration*, so an agent whose egress address falls outside it cannot register at all. A wrong CIDR silently takes every agent presenting that token offline on its next restart, and an empty list means unrestricted rather than blocked. Derive the ranges from your runners' **observed** egress addresses, not from the VPC block you assume they use, and leave the allowlist unset rather than guessing at it. The undo path here is *not* self-sealing — unlike the API IP allowlist in [4.1](#41-configure-audit-logging), your API and console access are unaffected, so you can widen or clear the list to recover the fleet.

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
1. **JWKS file:** generate a key set with `buildkite-agent tool keygen`, then configure the agent with `signing-jwks-file` and `signing-jwks-key-id` on uploading agents, and `verification-jwks-file` on executing agents.
   **Note:** `--jwks-file` and `--jwks-key-id` are flags on the `buildkite-agent tool sign` **command**, not agent configuration keys. Setting them where an agent config key belongs does nothing.
2. **AWS KMS:** keep the private key in a managed KMS so it is never on the agent host at all, via `signing-aws-kms-key`.
   **On GCP KMS:** the agent configuration reference lists a `signing-gcp-kms-key` option, but Buildkite's signed-pipelines documentation describes AWS KMS only. Confirm current support with Buildkite before designing around GCP KMS.

**Step 2: Enable Signing and Verification**
1. Configure the signing key on the agents responsible for uploading pipelines, and the verification key on every agent that executes steps.
2. **Configuring `verification-jwks-file` is what turns verification on.** The agent gates the entire verification path on a verification key being present, so an agent with `verification-failure-behavior=block` and no key configured executes unsigned jobs anyway. Setting the behavior without the key is security theater.
3. `verification-failure-behavior` defaults to **`block`**. The rollout therefore runs in the opposite direction to the usual pattern: temporarily set `warn` while you bring uploaders onto signing, then remove the override to return to `block`. An agent that has a verification key but whose uploaders are not yet signing will fail every build until you either finish the rollout or loosen the behavior deliberately.

**Step 3: Keep Signing Diagnostics Out of Production**

**Do not leave `--debug-signing` enabled.** It writes signing diagnostics into build logs and can expose secret values there. Use it to troubleshoot a rollout and turn it off immediately afterward.

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="3.4" %}

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
3. Work within the documented limits: keys up to 255 characters and **keys are immutable** — changing a key name means creating a new secret and deleting the old one.
   **On value size:** Buildkite's secrets documentation states 32 KB while the Terraform provider documentation states 8 KB. The two have not been reconciled; design against the lower figure until Buildkite confirms which applies to your path.

**Step 3: Never Put Secrets in Pipeline Settings**
1. Do not place secrets in a pipeline's `env` block, step configuration, or pipeline settings. Buildkite states plainly that **pipeline settings are often returned in REST and GraphQL API payloads** — so a secret there is exposed to every token that can read the pipeline, not only to the build.
2. This is a separate exposure path from log echo, and log redaction does not close it.
3. Where a literal `$` must survive into a command, escape it as `$$`. An unescaped `$` is interpolated at upload time, which both breaks the value and can print it.
4. Uploaded pipelines are visible in the build's timeline, so a secret interpolated into an uploaded step is exposed there too.

**Step 4: Scope and Review**
1. Keep production secrets in the production cluster only, so a development agent has no path to them.
2. Review secrets alongside the cluster's agent tokens, since the two together define what a compromised agent can reach.

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="3.5" %}

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

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="3.6" %}

Source: [Buildkite security controls](https://buildkite.com/docs/pipelines/best-practices/security-controls)

---

### 3.7 Delegate Cluster Administration

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-5, AC-6(1) |

#### Description
Name explicit **cluster maintainers** so that managing a cluster's agent tokens, queues, and secrets does not require granting organization-wide administrator access.

#### Rationale
**Why This Matters:**
- Without maintainers, the only way to let someone manage a cluster is to make them an organization admin — so the isolation boundary [3.2](#32-configure-agent-clusters) establishes is routinely undone by the access needed to operate it
- Cluster maintainers hold authority over agent tokens, queues **and cluster secrets**, which makes an unmanaged maintainer list equivalent to an unmanaged list of people who can read production credentials
- Maintainer grants are invisible from the organization member list, so an access review that only reads roles will miss them entirely
- The set of people who need to operate a cluster changes faster than the set of people who should administer the organization, and conflating the two guarantees the wider grant persists

**Attack Prevented:** Privilege escalation through unnecessary org-admin grants, unaudited access to cluster secrets, persistence via maintainer grants that survive an org-role review

#### ClickOps Implementation

**Step 1: Inventory Current Maintainers**
1. Go to **Agents → Clusters**, open each cluster, and review its **Maintainers** list.
2. Record whether each entry is a user or a team — team-scoped maintainers age better, because team membership is already reviewed.

**Step 2: Replace Org-Admin Grants**
1. For each person who holds organization admin solely to operate a cluster, add them as a maintainer of that cluster and remove the org-admin grant per [2.3](#23-limit-admin-access).

**Step 3: Prefer Teams Over Individuals**
1. Assign maintainership to a team rather than named individuals wherever the workflow allows, so joiner/leaver handling flows through the existing team process instead of a second list nobody remembers.

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="3.7" %}

Source: [Buildkite clusters](https://buildkite.com/docs/agent/v3/clusters)

---

### 3.8 Attest Build Artifacts

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.1 |
| NIST 800-53 | SI-7, SR-4 |

#### Description
Generate SLSA build provenance for the artifacts a pipeline produces, so a consumer can verify **where an artifact came from** rather than only that the pipeline definition was signed.

#### Rationale
**Why This Matters:**
- Pipeline signing ([3.4](#34-enable-pipeline-signing-and-verification)) proves the *instructions* were not tampered with; it says nothing about the *artifact* those instructions produced, and the two are separate integrity claims
- Without provenance, an artifact in a registry is an anonymous blob — nothing binds it to the commit, pipeline, and build that created it, so a substituted artifact is indistinguishable from a legitimate one
- Downstream consumers cannot enforce a policy such as "only deploy artifacts built by our pipeline from our main branch" unless the artifact carries a verifiable statement of that fact
- Provenance is what makes a compromise investigable after the fact: without it, establishing which builds produced which shipped artifacts is archaeology rather than a query

**Attack Prevented:** Artifact substitution between build and deploy, laundering a malicious artifact through a trusted registry, unverifiable software supply chains during incident response

#### ClickOps Implementation

**Step 1: Decide What Must Carry Provenance**
1. Identify the artifacts that cross a trust boundary — anything published to a registry, shipped to customers, or deployed to production.
2. Artifacts that never leave the build are lower priority; start where the blast radius is largest.

**Step 2: Enable Attestation Generation**
1. Add the provenance plugin to the pipelines producing those artifacts. It runs as a post-artifact hook and emits an in-toto Statement wrapped in a DSSE v1.0 Envelope, meeting SLSA Build Level 1.

**Step 3: Verify Downstream**
1. Make the deploy step *check* the attestation rather than merely accepting that one exists. An attestation nobody verifies provides no security property.

**Note on plan gating:** generating attestations is ungated. **Publishing** them to Buildkite Package Registries requires Enterprise. On other plans, publish the same in-toto statements to your own registry or use cosign — the generation half is unchanged.

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="3.8" %}

Source: [Buildkite build provenance](https://buildkite.com/docs/package-registries/security/build-provenance)

---

### 3.9 Harden the Agent Execution Environment

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6, CM-7 |

#### Description
Configure the agent's own execution behavior — host-key handling, workspace hygiene between jobs, and the bootstrap path — as distinct from the input controls in [2.4](#24-control-untrusted-input-to-pipelines).

#### Rationale
**Why This Matters:**
- `no-ssh-keyscan` defaults to **false**, which means the agent blindly accepts whatever host key your git server presents on first checkout — a textbook trust-on-first-use window against the source of everything it builds
- On a persistent agent, the workspace survives between jobs, so one poisoned build can leave artifacts, credentials, or modified tooling behind for the next unrelated build to pick up
- These settings live on the agent host and cannot be overridden by a `pipeline.yml`, which makes them the controls a malicious pipeline definition genuinely cannot switch off
- The controls are individually small and collectively decisive, which is exactly the profile of settings that get skipped because no single one looks urgent

**Attack Prevented:** Man-in-the-middle against the source host during checkout, build-to-build contamination on persistent agents, tampering with the bootstrap path

#### ClickOps Implementation

**Step 1: Disable Automatic Host-Key Acceptance**
1. Set `no-ssh-keyscan=true` in `buildkite-agent.cfg` and pre-populate `known_hosts` on the agent host with the verified key for your git server. Provisioning the key deliberately is the point; disabling keyscan without it just breaks checkout.

**Step 2: Force a Clean Workspace**
1. Set `BUILDKITE_CLEAN_CHECKOUT=true`. **This is not a `buildkite-agent.cfg` key** — it is a bootstrap/job environment variable, and writing it into the config file is silently ignored. Set it through an `environment` hook, or run ephemeral agents with `disconnect-after-job` instead.

**Step 3: Consider a Bootstrap Handler**
1. For maximum control, point `bootstrap-script` at a wrapper that applies your own admission logic before calling `buildkite-agent bootstrap`. Keep the wrapper thin — Buildkite documents no handler contract beyond invoking bootstrap, so elaborate logic here is building on unspecified behavior.

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="3.9" %}

Source: [Buildkite agent configuration](https://buildkite.com/docs/agent/v3/configuration)

---

### 3.10 Standardize Pipeline Steps with Templates

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-2, CM-6 |

#### Description
Define pipeline templates centrally and assign them to pipelines, which makes the assigned pipeline's step configuration **read-only** to pipeline editors.

#### Rationale
**Why This Matters:**
- Without templates, anyone who can edit a pipeline can delete the security scan step from it, and the pipeline keeps passing — the control disappears and the signal it produced disappears with it
- A mandated step that lives in each pipeline's own configuration is mandated only by convention; a template makes it structural
- Templates give you one place to fix a step across every pipeline, rather than a migration every time a scanning tool changes its invocation
- The difference matters most for the pipelines nobody looks at, which are also the pipelines where a removed control goes unnoticed longest

**Attack Prevented:** Silent removal of security gates by an insider or a compromised maintainer account, configuration drift between pipelines that were meant to enforce the same controls

#### ClickOps Implementation

**Step 1: Author the Template**
1. Go to **Settings → Pipeline Templates** and define the step sequence every pipeline of that class must run.

**Step 2: Assign It**
1. Assign the template to each pipeline. Once assigned, the pipeline's step configuration becomes read-only in the UI and via the API.

**Step 3: Decide Whether Templates Are Mandatory**
1. Organization-wide "require templates" strictness is set in the console. There is **no Terraform resource for it** — do not assume infrastructure-as-code covers this setting; verify it in the UI.

**Automation:** Terraform manages template definition and assignment. The org-level strictness toggle is **ClickOps only** — Buildkite exposes no Terraform resource and no documented mutation for it ([pipeline templates](https://buildkite.com/docs/pipelines/templates), 2026-08-18).

**Note on plan gating:** pipeline templates are an **Enterprise** feature.

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="3.10" %}

Source: [Buildkite pipeline templates](https://buildkite.com/docs/pipelines/templates)

---

### 3.11 Govern Inbound OIDC Trust

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-3, IA-9 |

#### Description
Constrain which pipelines may authenticate **into** Buildkite-hosted services — package registries and test suites — using OIDC policies, the inbound counterpart to the outbound cloud federation in [3.6](#36-use-oidc-instead-of-static-cloud-credentials).

#### Rationale
**Why This Matters:**
- [3.6](#36-use-oidc-instead-of-static-cloud-credentials) governs Buildkite authenticating outward to your cloud; this governs pipelines authenticating inward to your registries, and they are different trust directions with different blast radii
- Publish authority to a registry is a supply-chain control: whoever can publish decides what your consumers install, which makes "which pipeline may publish here" a first-class security question
- The alternative is a long-lived static registry token, and a test suite's `api_token` is exactly the standing credential an OIDC policy exists to displace
- Without a policy, any pipeline holding the token can publish — the registry cannot distinguish your release pipeline from a pull-request build that happened to read the same secret

**Attack Prevented:** Malicious package publication from a non-release pipeline, supply-chain compromise via a leaked static registry token, branch-based trust bypass during publication

#### ClickOps Implementation

**Step 1: Identify Publication Points**
1. List every registry and test suite that a pipeline writes to, and the single pipeline that legitimately writes to each.

**Step 2: Write the Policy**
1. Define an OIDC policy scoping the issuer, scopes, and claims — `organization_slug`, `pipeline_slug`, `build_branch`, `repository`, `actor`. Constrain `build_branch` where publication should only happen from your release branch.

**Step 3: Remove the Static Credential**
1. Once the policy works, stop distributing the static token. Leaving it live means you added a path rather than closing one.

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="3.11" %}

Source: [Buildkite package registries OIDC](https://buildkite.com/docs/package-registries/security/oidc)

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
- **Terraform (L3 IP restriction only): a plan including the API IP allowlist feature**, and the same `buildkite_organization` caveat described in [1.2](#12-enforce-two-factor-authentication) — the two controls share one singleton resource, so adopt one Terraform path or merge them, never both.

> **Lockout warning — API IP allowlist.** `allowed_api_ip_addresses` is a hard allowlist on REST and GraphQL access. A CIDR list that omits the network you automate from severs your own API access the moment it applies, including the access required to reverse it. The undo path (`organizationApiIpAllowlistUpdate`) is itself an API call, so a wrong list is self-sealing. Confirm your egress address is covered before applying, and keep a route in from an allowlisted network. The agent-token IP allowlist in [3.1](#31-configure-agent-tokens) is lockout-capable in its own way — a wrong CIDR strands every agent presenting that token — but it differs in one respect that matters here: it does not seal its own undo path, because it restricts agent registration only and leaves your API and console access intact.

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

### 4.2 Contain a Compromised Build Fleet

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 17.4 |
| NIST 800-53 | IR-4 |

#### Description
Establish and rehearse the mechanisms for stopping work on a compromised cluster — pausing queue dispatch, pausing or stopping agents, and revoking agent tokens — before an incident requires them.

#### Rationale
**Why This Matters:**
- **Revoking an agent token does not disconnect agents that are already connected.** A responder who revokes tokens and believes the fleet is contained has stopped new agents from registering while the compromised ones keep running jobs
- Containment has an order — pause dispatch, then stop agents, then revoke tokens — and working it out during an incident costs the time the incident is consuming
- Pausing queue dispatch stops new work without deleting the queue and losing its configuration, which is the difference between containment and an outage you then have to rebuild from
- There is no `buildkite_agent` Terraform resource, so the agent half of containment is CLI and API only; a team whose entire operational muscle is `terraform apply` has no path to the controls that matter here

**Attack Prevented:** Continued execution of malicious jobs during an incident, credential exfiltration from agents that survived an incomplete containment, destruction of evidence by builds that keep running

#### ClickOps Implementation

**Step 1: Pause Dispatch First**
1. Go to **Agents → Clusters → Queues** and pause dispatch on the affected queue. New jobs stop being handed out; running jobs are unaffected, which is why this is first rather than sufficient.

**Step 2: Stop the Agents**
1. Stop the affected agents. Use a forced stop only when you accept losing the running job's output — sometimes that output is the evidence.

**Step 3: Revoke Tokens**
1. Revoke the cluster's agent tokens so nothing re-registers. Do this **after** stopping agents, not instead of it.

**Step 4: Rehearse It**
1. Run the sequence against a non-production cluster at least once. A containment procedure nobody has executed is a hypothesis.

**Step 5: Restore Deliberately**
1. Resume dispatch only after issuing fresh tokens and confirming the agent hosts were rebuilt rather than restarted.

#### Code Implementation

{% include pack-code.html vendor="buildkite" section="4.2" %}

Source: [Buildkite agent lifecycle](https://buildkite.com/docs/agent/v3/securing)

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
| 2026-08-18 | 0.3.0 | draft | Close the Buildkite reconciliation: end the Terraform monoculture and make every leveled control carry a real automation verdict. **New controls:** 2.6 dormant organization members, 2.7 cross-pipeline access via Buildkite Rules, 3.7 delegated cluster administration, 3.8 build-artifact attestation (SLSA provenance), 3.9 agent execution environment, 3.10 pipeline templates, 3.11 inbound OIDC trust, 4.2 build-fleet incident containment. **New Code Packs:** 21 files across four surfaces — `api/` (6), `cli/` (3), `config/` (5) and `terraform/` (15) — where the corpus previously shipped Terraform only; non-comment HCL in control packs rises from 61 to 1,009 lines, and the GraphQL, REST, CLI and agent-config surfaces go from 0% coverage to shipped code. **Corrections:** 2.2 documents the six organization-level pipeline toggles as ClickOps-only with evidence that no write interface exists; 2.5 adds inactive-token auto-revocation and warns that Portal tokens are admin-privileged and long-lived; 3.4 fixes `--jwks-file`/`--jwks-key-id` being presented as agent config keys when they are `tool sign` flags, records that `verification-failure-behavior` already defaults to `block` (so the rollout runs the other way), states that verification is gated on a configured JWKS — without one, unsigned jobs execute regardless — and flags the unverified GCP KMS claim; 3.5 adds the API-payload exposure path, `$$` escaping, and the unreconciled 32 KB / 8 KB value-size discrepancy. | Claude Code (Opus 5) |
| 2026-08-17 | 0.2.1 | draft | Replace three prose-only Code Packs with real, schema-verified code. **1.1:** the Terraform provider exposes no SSO resource (21 resources, 16 data sources, none for SSO), so the empty `.tf` is replaced by a GraphQL `api/` pack using the live-introspected `ssoProvider*` mutation family, with the disable path documented as the way back from an SSO lockout. **2.3:** now a real verification pack over the `buildkite_organization_members` data source and `buildkite_team_member` roles, stating honestly that org-level role is not exposed to Terraform and lives in GraphQL. **3.3:** now real cluster isolation — `buildkite_cluster`, `buildkite_cluster_queue`, and cluster-scoped `buildkite_cluster_agent_token` with the lockout-capable IP allowlist. | Claude Code (Opus 5) |
| 2026-08-08 | 0.2.0 | draft | Currency pass. **1.1:** correct the plan gate to Pro or Enterprise (no "Business" tier exists) and expand enforcement — SSO required/optional is per user, organization-wide enforcement works by disabling 2FA authentication as a login method, session timeout ranges from 6 hours to 1 year, IP address pinning revokes a session on IP change (Enterprise), SCIM deprovisioning (Enterprise), and members are provisioned just-in-time on first login. **3.1:** correct agent tokens to cluster-scoped, and add expiration timestamps (API-only, at least 10 minutes out, immutable once set; web-UI tokens have no expiry) and the Allowed IP Addresses CIDR allowlist. **3.2:** add the unclustered agents and tokens deprecation, unavailable to organizations created after 2024-02-26. **4.1:** correct the non-existent retention setting — the audit log is Enterprise-only at Organization Settings → Audit → Audit Log, events are stored indefinitely, the UI browses 12 months with older events via GraphQL, and search covers 90 days with 3 terms and 250 characters; add EventBridge streaming and REST/GraphQL retrieval. **New controls:** 2.4 untrusted-input pipeline controls, 2.5 API access token hygiene, 3.4 pipeline signing and verification, 3.5 build secrets management, 3.6 OIDC instead of static cloud credentials. **§5:** add mappings for the new controls and record that no CIS, DISA, or SCuBA baseline exists for Buildkite. **Appendix A:** remove the Trust Center and marketing security-page rows and add the newly cited documentation. Not surveyed this pass: Tier 3/4 research | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, teams, and agent security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
