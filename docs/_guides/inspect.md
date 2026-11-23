---
layout: guide
title: "Inspect Hardening Guide"
vendor: "Inspect"
slug: "inspect"
tier: "2"
category: "AI/ML Platform"
description: "Limit Ramp Inspect agent, connector, repository, workload-identity, automation, approval, and audit exposure using documented controls and reviewable Code Packs."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-23"
---

## Overview

Inspect is Ramp’s agent platform for coding and connected workflows. Its hosted sessions, reusable agents, connectors and unattended triggers can combine repository code, credentials and external content. Harden the actual permission and execution boundaries, not only natural-language instructions.

**Placement:** Ramp Business Corporation → standalone Inspect guide. The [Inspect connector-security documentation](https://docs.inspect.com/security/connectors) identifies Ramp as the operator. The existing [Ramp guide](/guides/ramp/) covers the financial application, not this separate Inspect console; its sign-in controls, certifications and roles must not be assumed to transfer. No control-plane inheritance is asserted.

### Intended Audience

- Inspect organization administrators and repository owners
- Security and identity engineers managing integrations and workload trust
- GRC practitioners collecting configuration evidence

### How to Use This Guide

- **L1 (Crawl):** Constrain entry points, repositories and credentials; preserve human review and audit evidence.
- **L2 (Walk):** Harden shared execution, workload identity, private networking and instruction integrity.
- Pilot changes on nonproduction repositories and identities. Record current settings before modifying them.
- Read-only inventories show the authenticated caller’s visible objects. They are not a tenant-wide compliance score. Write packs require explicit opt-in after preview.

### Scope

The current public Inspect documentation, including its API and customer-controlled organization, repository, agent, connector and automation surfaces. Availability varies by deployment; OIDC connectors and organization Approval policies have specific rollout caveats. The public docs do not enumerate complete sign-in/provider settings, RBAC administration paths, retention commitments or an audit API contract. Those remain gaps rather than invented controls.

No tenant was accessed or configured. ClickOps paths are documentation-derived; offline tests and schema checks do not prove live effectiveness. See the [validation record](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/inspect-validation.md) and [source coverage ledger](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/inspect-source-coverage.md) for discovery boundaries and the [maturity definitions](https://github.com/grcengineering/how-to-harden/blob/main/VERSIONS.md#maturity-statuses--the-matrix). Prompt injection cannot be completely prevented by a prompt or connector wrapper: least-privilege provider identities and review of consequential actions remain necessary.

## Table of Contents

1. [Identity and Entry Points](#1-identity-and-entry-points)
2. [Repositories, Agents and Connectors](#2-repositories-agents-and-connectors)
3. [Secrets and Execution Boundaries](#3-secrets-and-execution-boundaries)
4. [Approvals and Unattended Work](#4-approvals-and-unattended-work)
5. [Monitoring and Configuration Integrity](#5-monitoring-and-configuration-integrity)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

## 1. Identity and Entry Points

### 1.1 Restrict Sign-In and Provisioning

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | IA-2 Identification and Authentication (Organizational Users) |

#### Description

Limit the people and identity providers allowed to join the Inspect organization. Apply workforce authentication policy in the approved identity provider rather than assuming Ramp financial-product login controls also govern Inspect.

#### Rationale

**Why This Matters:**

- An overly broad join policy exposes coding environments and connected services.
- Identity-provider approval requirements can affect rollout and recovery.

**Attack Prevented:** Unauthorized enrollment and access through an unintended identity provider.

#### ClickOps Implementation

1. As a workspace administrator, open **Organization → Security → Sign-in and provisioning**.
2. Choose the permitted join policy and providers; review the provider approval requirements shown before saving. The public guide does not enumerate every provider or policy value.
3. Test an approved pilot identity and a disallowed identity before broad rollout. Preserve a separate working administrator session and record a recovery owner.

**Sources:** [getting-started/organization-setup](https://docs.inspect.com/getting-started/organization-setup) (checked 2026-11-17).

**Automation:** ClickOps configuration. No matching administration endpoint or complete native configuration contract was found in the reviewed [public API reference](https://docs.inspect.com/api) and linked [OpenAPI schema](https://docs.inspect.com/api/openapi.json) on 2026-11-17. This is a bounded documentation result, not proof that no private interface exists; see the source ledger for other surfaces.

#### Validation & Testing

Verify allowed users can sign in and out-of-scope identities cannot join. Check the corresponding sign-in policy/provider events in Organization → Audit logs.

#### Operational Impact

Restrictive changes can lock out users. Restore the prior approved policy from a working administrator session if the pilot fails.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| NIST SP 800-53 Rev. 5 | IA-2 Identification and Authentication (Organizational Users) | Supports this control objective; configuration alone does not establish compliance. |

### 1.2 Separate and Protect API Credentials

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | IA-5 Authenticator Management |

#### Description

Give each integration a distinct Inspect API key and keep keys in a secret manager. Remove unused credentials rather than reusing one person’s key for every workload.

#### Rationale

**Why This Matters:**

- A shared credential obscures ownership and expands incident impact.
- API keys authenticate application actions and must not appear in frontend code or logs.

**Attack Prevented:** Reuse or disclosure of a privileged integration credential.

#### ClickOps Implementation

1. Open **Settings → API keys** using the documented API keys page.
2. Use **Create API key** with an application-specific descriptive name. Capture it directly into the approved secret manager when displayed; the full value is not shown again.
3. Review the application owner and use of existing keys. Revoke unused or exposed keys and keys whose integration no longer has an owner; coordinate replacement before breaking a required service.

**Sources:** [settings/developer/api-keys](https://docs.inspect.com/settings/developer/api-keys) (checked 2026-11-17).

**Automation:** ClickOps configuration. No matching administration endpoint or complete native configuration contract was found in the reviewed [public API reference](https://docs.inspect.com/api) and linked [OpenAPI schema](https://docs.inspect.com/api/openapi.json) on 2026-11-17. This is a bounded documentation result, not proof that no private interface exists; see the source ledger for other surfaces.

#### Validation & Testing

Verify a retained integration authenticates without printing the key. Confirm revoked credentials fail and review api_key lifecycle events. Never put a real key in test fixtures.

#### Operational Impact

Revocation can stop callers immediately. Restore service with an approved replacement credential, not by republishing an exposed key.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| NIST SP 800-53 Rev. 5 | IA-5 Authenticator Management | Supports this control objective; configuration alone does not establish compliance. |

### 1.3 Disable Unused Email Session Initiation

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-3 Access Enforcement |

#### Description

Turn off Inspect email initiation when the organization has no approved email workflow. When retained, treat mailbox access and reply recipients as part of the agent’s trust boundary.

#### Rationale

**Why This Matters:**

- Email prompts execute with the sender’s Inspect access.
- Inspect replies copy other people on a shared email thread; input authentication does not make recipients appropriate for sensitive output.

**Attack Prevented:** Unnecessary agent activation from a compromised mailbox and unintended disclosure to thread recipients.

#### ClickOps Implementation

1. As an organization administrator, open **Settings → Integrations** and locate **Email**.
2. Leave email off unless a documented workflow requires it; the **Enabled** badge identifies an active integration. Turning it off stops new messages from invoking Inspect but does not erase existing sessions.
3. If enabled, verify the sender domain has SPF, DKIM and DMARC and limit recipients before adding Inspect. Deactivate departed users. Public documentation does not provide an email-only role policy or recipient allowlist.

**Sources:** [settings/email](https://docs.inspect.com/settings/email) (checked 2026-11-17).

**Automation:** ClickOps configuration. No matching administration endpoint or complete native configuration contract was found in the reviewed [public API reference](https://docs.inspect.com/api) and linked [OpenAPI schema](https://docs.inspect.com/api/openapi.json) on 2026-11-17. This is a bounded documentation result, not proof that no private interface exists; see the source ledger for other surfaces.

#### Validation & Testing

With a harmless test message, confirm the intended enabled/disabled behavior and sender identity. Inspect silently ignores rejected messages, so absence of a bounce is not a success receipt.

#### Operational Impact

Disabling interrupts email workflows; users can continue existing sessions in the web app. Re-enable only after reviewing the requirement.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| NIST SP 800-53 Rev. 5 | AC-3 Access Enforcement | Supports this control objective; configuration alone does not establish compliance. |

## 2. Repositories, Agents and Connectors

### 2.1 Limit Connected GitHub Repositories

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-6 Least Privilege |

#### Description

Connect only repositories approved for Inspect and reconcile the visible repository inventory with that approved set. An API inventory is not proof of the GitHub App’s installation permissions.

#### Rationale

**Why This Matters:**

- Every connected repository is an additional source and execution context.
- New repositories can also broaden automations configured for all repositories.

**Attack Prevented:** Overbroad source-code access and unintended repository execution.

#### ClickOps Implementation

1. During **Inspect GitHub app** installation, select only the repositories Inspect may use.
2. If needed, link the GitHub account and return to **setup → Connect** for the installation.
3. In **Repository settings**, review repositories made available to users, Teams and Projects. Remove unnecessary access through the supported installation/repository controls after checking dependent sessions and automations.

**Sources:** [getting-started/organization-setup](https://docs.inspect.com/getting-started/organization-setup), [settings/repositories](https://docs.inspect.com/settings/repositories) (checked 2026-11-17).

#### Code Implementation

{% include pack-code.html vendor="inspect" section="2.1" %}

#### Validation & Testing

Compare the read-only inventory with the approved repository list and inspect GitHub installation permissions separately. Confirm a pilot session cannot access a repository excluded from its approved context.

#### Operational Impact

Removing repositories can break sessions, builds and automations. Re-add only the explicitly approved repository, not all repositories.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| NIST SP 800-53 Rev. 5 | AC-6 Least Privilege | Supports this control objective; configuration alone does not establish compliance. |

### 2.2 Review Custom Agent Access

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-6 Least Privilege |

#### Description

Review each custom agent’s full configuration, repository selection, skills and owners. Use the detail API rather than list summaries when reviewing prompts and access-related fields.

#### Rationale

**Why This Matters:**

- Purpose-built agents can be reused by Slack, child sessions and automations.
- A stale skill or repository assignment can silently propagate across many runs.

**Attack Prevented:** Privilege accumulation and unexpected behavior in reused agents.

#### ClickOps Implementation

1. Open **Customize → Agents** and select the agent.
2. Review its prompt, model, repository access, skills and intended delivery. Grant only the repositories and tools needed for its job.
3. Review Slack invocation and automatic-reply channels. Messages from workflows or other apps can invoke a custom agent; do not treat all channel input as trusted.

**Sources:** [customize/agents](https://docs.inspect.com/customize/agents), [api/agents/getAgent](https://docs.inspect.com/api/agents/getAgent) (checked 2026-11-17).

#### Code Implementation

{% include pack-code.html vendor="inspect" section="2.2" %}

#### Validation & Testing

Read the exact agent with the audit pack, compare it to the approved configuration, and run a benign scoped task. Deprecated capability flags are not an authorization boundary; in particular, git_write=false does not guarantee that pushes or pull requests are blocked.

#### Operational Impact

Narrowing a reusable agent affects future invocations. Record its prior configuration; only prompts are versioned, so restoring a prompt does not restore the whole agent.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| NIST SP 800-53 Rev. 5 | AC-6 Least Privilege | Supports this control objective; configuration alone does not establish compliance. |

### 2.3 Make Sensitive Connectors Private

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-6 Least Privilege |

#### Description

Mark connectors private when their data or authorization must not be visible in workspace-visible sessions. Personal credentials and private-session visibility are separate decisions.

#### Rationale

**Why This Matters:**

- A personal connector still can be used in a public session unless its access level prevents that.
- Shared organization credentials may expose the same data to many eligible sessions.

**Attack Prevented:** Disclosure of personal or restricted connector results through shared sessions.

#### ClickOps Implementation

1. Open **Customize → Connectors** and select the connector.
2. Choose private access for sensitive data or personal authorization that must not be exposed organization-wide.
3. Use a harmless private-connector task to verify the session becomes private. Review existing shared sessions and recipients separately; changing a connector is not documented to retract previously shared output.

**Sources:** [customize/connectors](https://docs.inspect.com/customize/connectors), [security/connectors](https://docs.inspect.com/security/connectors) (checked 2026-11-17).

**Automation:** ClickOps configuration. No matching administration endpoint or complete native configuration contract was found in the reviewed [public API reference](https://docs.inspect.com/api) and linked [OpenAPI schema](https://docs.inspect.com/api/openapi.json) on 2026-11-17. This is a bounded documentation result, not proof that no private interface exists; see the source ledger for other surfaces.

#### Validation & Testing

Verify the session visibility after using the private connector and test access with an unauthorized organization member. Do not infer visibility from the fact that OAuth used a personal account.

#### Operational Impact

Private access restricts collaboration. Retain it unless the data owner approves broader visibility; do not broaden access to solve a test failure.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| NIST SP 800-53 Rev. 5 | AC-6 Least Privilege | Supports this control objective; configuration alone does not establish compliance. |

### 2.4 Constrain Shared Connector Credentials and Revocation

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-6 Least Privilege |

#### Description

Use dedicated, least-privilege provider identities for shared connectors. Inspect connector-management roles govern configuration, not per-tool authorization after a shared connection exists.

#### Rationale

**Why This Matters:**

- The external provider’s permission model remains the final boundary.
- The live MCP tool catalog can change independently of Inspect; tool descriptions are untrusted content.

**Attack Prevented:** Compromised connector or prompt-injection abuse of excessive provider permissions.

#### ClickOps Implementation

1. In **Customize → Connectors**, inventory organization credentials and confirm the external account, scopes and owner before authorizing.
2. Use a dedicated organization-managed Linear service user where applicable, limited to required teams and issues. Apply similarly narrow permissions in each provider’s documented controls.
3. For custom MCP servers, verify the remote HTTPS endpoint and operator; expose only needed tools. Do not embed credentials in the server definition.
4. Disable/disconnect an unneeded connector. If immediate cutoff is required, revoke the credential at the provider too: an already running prompt may retain an authenticated connection until it ends.

**Sources:** [customize/connectors](https://docs.inspect.com/customize/connectors), [security/connectors](https://docs.inspect.com/security/connectors) (checked 2026-11-17).

**Automation:** ClickOps configuration. No matching administration endpoint or complete native configuration contract was found in the reviewed [public API reference](https://docs.inspect.com/api) and linked [OpenAPI schema](https://docs.inspect.com/api/openapi.json) on 2026-11-17. This is a bounded documentation result, not proof that no private interface exists; see the source ledger for other surfaces.

#### Validation & Testing

Test an allowed operation and a benign denied operation at the provider; review successful connector lifecycle events. Inspect audit logs do not include failed connection attempts.

#### Operational Impact

Provider revocation can interrupt all uses of a shared identity. Prefer a dedicated identity so containment does not disrupt unrelated integrations.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| NIST SP 800-53 Rev. 5 | AC-6 Least Privilege | Supports this control objective; configuration alone does not establish compliance. |

### 2.5 Verify Inspect OIDC Connector Identity

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | IA-9 Service Identification and Authentication |

#### Description

For organizations where Inspect OIDC connectors are available, authenticate requests with verified short-lived JWTs and authorize the stable user subject at the MCP server.

#### Rationale

**Why This Matters:**

- A valid signature without exact issuer and audience checks accepts the wrong trust domain.
- Email and acting-person fields are not permanent authorization identifiers.

**Attack Prevented:** Cross-organization token confusion and improper authorization at a custom MCP server.

#### ClickOps Implementation

1. Open **Customize → Connectors → Add connector**, enter the approved server URL, and select **Authentication → Inspect OIDC**. Availability is deployment-dependent.
2. Open **View token verification details** and configure the server’s maintained JWT library with the displayed issuer, audience and JWKS. Require RS256, valid expiry and supported claim version.
3. Authorize on sub; treat email as display/lookup data and act as audit context. Match the exact organization-bound audience, and reject reused jti values if the service requires replay prevention.

**Sources:** [customize/inspect-oidc-connectors](https://docs.inspect.com/customize/inspect-oidc-connectors) (checked 2026-11-17).

**Automation:** The vendor documents custom MCP JSON with auth set to inspect_oidc and server-side JWT verification, but does not publish a complete standalone connector JSON schema or official verifier SDK in the reviewed references. No guessed connector payload or cryptographic implementation is supplied; use the documented UI and a maintained JWT library.

#### Validation & Testing

Use nonproduction fixtures to reject wrong issuer, audience, signature, expired token and unsupported version. If replay prevention is required, verify duplicate jti rejection. A valid token may otherwise be reused during its five-minute lifetime.

#### Operational Impact

Deployment moves change the issuer. Coordinate server trust updates; do not temporarily disable verification. This guide does not provide a handwritten JWT validator.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| NIST SP 800-53 Rev. 5 | IA-9 Service Identification and Authentication | Supports this control objective; configuration alone does not establish compliance. |

### 2.6 Enforce an Agent Repository Allowlist

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-6 Least Privilege |

#### Description

Apply an explicit approved repository list to an existing custom agent after reviewing its current configuration. Keep the write operation separate from the read-only assessment.

#### Rationale

**Why This Matters:**

- A default/all-repository choice can expand access when new repositories are connected.
- A targeted update is easier to review than replacing unrelated agent configuration.

**Attack Prevented:** Unintended expansion of a reusable agent’s repository scope.

#### ClickOps Implementation

1. Open **Customize → Agents** and the exact agent approved for the change.
2. Select only the required repositories and compare with the reviewed baseline from control 2.2.
3. Save the scoped selection and start a nonproduction task using that agent. The API pack previews its proposed update before explicit application.

**Sources:** [customize/agents](https://docs.inspect.com/customize/agents), [api/agents/updateAgent](https://docs.inspect.com/api/agents/updateAgent), [api/agents/getAgent](https://docs.inspect.com/api/agents/getAgent) (checked 2026-11-17).

#### Code Implementation

{% include pack-code.html vendor="inspect" section="2.6" %}

#### Validation & Testing

Read back the agent’s repository configuration and test a permitted and an excluded repository. This does not constrain separate provider credentials or make deprecated capability flags enforceable.

#### Operational Impact

Agents and automations may lose required context. Roll back only the reviewed repository selection using the recorded pre-change values.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| NIST SP 800-53 Rev. 5 | AC-6 Least Privilege | Supports this control objective; configuration alone does not establish compliance. |

## 3. Secrets and Execution Boundaries

### 3.1 Keep Secrets Typed and Narrowly Scoped

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | SC-28 Protection of Information at Rest |

#### Description

Store sensitive environment values as Secret and select only their necessary Build and Runtime scopes. Prefer nonproduction, least-privilege credentials.

#### Rationale

**Why This Matters:**

- Organization variables reach every repository unless overridden.
- Changing Secret to Plain text exposes saved values to people who can view repository variables.

**Attack Prevented:** Credential disclosure through visible settings, builds and excessive runtime exposure.

#### ClickOps Implementation

1. Open **Repository settings → Environment variables** for repository-specific values; use **Settings → Environment** only for values that genuinely need organization-wide scope. Organization variables require the Manage secrets role.
2. Set sensitive values to **Secret**, not **Plain text**. Select Build, Runtime or both according to the actual consumer.
3. For bulk changes, select rows and use **Edit scopes** or **Change type** deliberately: scopes replace the selected combination, and type changes do not replace saved values. Review same-key repository overrides, which replace the organization variable entirely.

**Sources:** [settings/repositories/environment-variables](https://docs.inspect.com/settings/repositories/environment-variables) (checked 2026-11-17).

**Automation:** ClickOps configuration. No matching administration endpoint or complete native configuration contract was found in the reviewed [public API reference](https://docs.inspect.com/api) and linked [OpenAPI schema](https://docs.inspect.com/api/openapi.json) on 2026-11-17. This is a bounded documentation result, not proof that no private interface exists; see the source ledger for other surfaces.

#### Validation & Testing

Verify variable names, types and scopes without dumping values. Check build/runtime availability using a nonsecret test value. Review environment_variable events; secret values are not logged.

#### Operational Impact

Saved changes apply immediately; build-scoped changes apply on subsequent builds. Restore approved type/scope selections if necessary, never reveal values to diagnose access.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| NIST SP 800-53 Rev. 5 | SC-28 Protection of Information at Rest | Supports this control objective; configuration alone does not establish compliance. |

### 3.2 Constrain Shared Build Scripts and Images

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | CM-3 Configuration Change Control |

#### Description

Limit shared setup scripts to required repositories and keep credentials out of prebuilt images. Treat shared scripts as code executed across every selected repository and new session.

#### Rationale

**Why This Matters:**

- A compromised shared setup script scales across many environments.
- Files written by scripts persist into later setup steps even though exported variables do not.

**Attack Prevented:** Supply-chain execution and credential persistence in reusable build images.

#### ClickOps Implementation

1. Open **Settings → Environment → Scripts** with the Manage secrets role.
2. Scope each script to its approved repositories rather than all repositories unless explicitly necessary. Review its order with **Move up/Move down** and inspect the applicable list in each repository’s **Build scripts** tab.
3. Read credentials from scoped Secret variables, not script literals. Make scripts safe to run twice; remove generated credential files before snapshot creation.
4. Rebuild after reviewed script, dependency or toolchain changes and inspect a clean environment before allowing sensitive work.

**Sources:** [settings/repositories/build](https://docs.inspect.com/settings/repositories/build), [settings/repositories/environment-variables](https://docs.inspect.com/settings/repositories/environment-variables), [settings/sandbox-workload-identity](https://docs.inspect.com/settings/sandbox-workload-identity) (checked 2026-11-17).

**Automation:** ClickOps configuration. No matching administration endpoint or complete native configuration contract was found in the reviewed [public API reference](https://docs.inspect.com/api) and linked [OpenAPI schema](https://docs.inspect.com/api/openapi.json) on 2026-11-17. This is a bounded documentation result, not proof that no private interface exists; see the source ledger for other surfaces.

#### Validation & Testing

Verify applicable script order and that setup fails safely in image builds. Test the session path too: a shared-script failure there produces a warning rather than stopping setup. Check resulting files without printing secrets.

#### Operational Impact

New sessions use script changes immediately; images update on rebuild. Existing images can remain in use while a replacement builds. Revert the approved script and rebuild if the test fails.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| NIST SP 800-53 Rev. 5 | CM-3 Configuration Change Control | Supports this control objective; configuration alone does not establish compliance. |

### 3.3 Bind Sandbox Workload Identity to Exact Trust

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-6 Least Privilege |

#### Description

Prefer the AWS MCP connector when controlled external tools meet the task. Use sandbox OIDC only for processes that need direct authentication, with exact audience and repository/lifecycle trust.

#### Rationale

**Why This Matters:**

- Every process affecting the sandbox or image build can read the projected bearer token.
- Short token lifetime does not make an over-permissioned destination role safe.

**Attack Prevented:** Cross-repository or cross-organization credential use and persistent static cloud secrets.

#### ClickOps Implementation

1. Open **Organization → Security → Workload identities** as an organization administrator; leave the list empty when no direct workload identity is needed.
2. Create only the required name and audience. For AWS use sts.amazonaws.com; obtain the displayed issuer and exact organization/repository subject prefix.
3. At the relying party, bind the exact issuer, audience and narrowest repository/lifecycle subject. For AWS the documented console sequence is **IAM → Identity providers → Add provider → OpenID Connect**, then **IAM → Roles → Web identity**. Keep build/runtime roles separate where possible.
4. In repository **Environment variables**, set the role ARN and the documented token file path /run/inspect/oidc-tokens/aws with only required Build/Runtime scopes. Do not copy tokens into source, logs or snapshots.

**Sources:** [settings/sandbox-workload-identity](https://docs.inspect.com/settings/sandbox-workload-identity) (checked 2026-11-17).

#### Code Implementation

The config pack emits a proposed AWS trust policy with exact issuer, audience, repository and lifecycle conditions. It does not create an Inspect identity, attach AWS permissions or apply the policy. Review the output and configure the documented environment variables separately.

{% include pack-code.html vendor="inspect" section="3.3" %}

#### Validation & Testing

From a controlled sandbox/build, verify the resulting identity belongs to the intended role and excluded repositories cannot assume it. Removing an identity stops new minting after polling, not existing JWTs (up to one hour) or downstream credentials; use destination-side revocation for immediate containment.

#### Operational Impact

Trust changes can break builds. Keep a reviewed previous policy for rollback, but never broaden organization or owner wildcards to fix failures. Repository renames/transfers change subjects.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| NIST SP 800-53 Rev. 5 | AC-6 Least Privilege | Supports this control objective; configuration alone does not establish compliance. |

### 3.4 Leave Private Networking Off Unless Required

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | SC-7 Boundary Protection |

#### Description

Enable private networking only for approved tasks and narrow tunnel identities and destination-service permissions. Network reachability is not application authorization.

#### Rationale

**Why This Matters:**

- Sandbox code and agent tools can reach services permitted by the tunnel.
- Inspect does not supply standard egress logs for private tunnel requests.

**Attack Prevented:** Lateral access from compromised repository code or an agent to internal services.

#### ClickOps Implementation

1. As an organization administrator, open **Organization → Security** and keep private networking disabled unless an approved workflow needs it.
2. For an approved use, install/authenticate the supported tunnel inside a controlled sandbox with a dedicated least-privilege identity and specific routes. Keep service-side authentication and VPN ACLs.
3. Continue using Inspect’s injected HTTP/HTTPS proxy; do not add NO_PROXY bypasses or assume a default/exit-node route authorizes private access.
4. Start a new session after changing the setting when immediate application is required; already running sandboxes retain their startup setting.

**Sources:** [settings/private-networking](https://docs.inspect.com/settings/private-networking) (checked 2026-11-17).

**Automation:** ClickOps configuration. No matching administration endpoint or complete native configuration contract was found in the reviewed [public API reference](https://docs.inspect.com/api) and linked [OpenAPI schema](https://docs.inspect.com/api/openapi.json) on 2026-11-17. This is a bounded documentation result, not proof that no private interface exists; see the source ledger for other surfaces.

#### Validation & Testing

Test required private HTTP/HTTPS access and a benign excluded service. Verify VPN/destination logs provide needed visibility. Turning the Inspect setting off does not instantly change existing sandboxes.

#### Operational Impact

Disabling may interrupt new private-service sessions. Restore only the approved setting and tunnel ACLs, and explicitly replace affected sandboxes.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| NIST SP 800-53 Rev. 5 | SC-7 Boundary Protection | Supports this control objective; configuration alone does not establish compliance. |

## 4. Approvals and Unattended Work

### 4.1 Default Automated Approval to Human Review

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | CM-3 Configuration Change Control |

#### Description

Keep Approval agent disabled until repository policies have been reviewed. Start from a deny-by-default policy and preserve independent human Required Reviews.

#### Rationale

**Why This Matters:**

- An automated approval is an authorization signal, not proof of a safe merge.
- Sensitive policy and CI changes must not be able to approve themselves through permissive defaults.

**Attack Prevented:** Automated approval of security-sensitive or uncovered changes.

#### ClickOps Implementation

1. Review the organization-wide switch in **Settings → Approval agent**; enabling it permits evaluation but does not make every repository eligible.
2. Review .inspect/approvals/path_rules.yaml on the repository’s default branch. Start with default deny and explicit denial of sensitive paths; only add narrow allow/classify rules after policy review.
3. Use /configure-approvals to draft changes in a controlled session if helpful, then inspect the proposed files before merging. Preserve independent GitHub human review requirements.
4. If **Organization policies** is available, use it for additional mandatory requirements. The docs mark this feature coming soon; do not assume it exists in every tenant.

**Sources:** [pull-requests/approval-agent](https://docs.inspect.com/pull-requests/approval-agent) (checked 2026-11-17).

#### Code Implementation

{% include pack-code.html vendor="inspect" section="4.1" %}

#### Validation & Testing

Use nonproduction PRs for sensitive and uncovered paths; both should need human review. Confirm a matching allow rule cannot cancel a deny. If organization policy preview is available, Try on pull requests does not execute classifiers.

#### Operational Impact

The provided policy intentionally enables no automated approval. Relaxing it is a separate governance decision. Roll back reviewed policy changes through code review, not by deleting human review protections.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| NIST SP 800-53 Rev. 5 | CM-3 Configuration Change Control | Supports this control objective; configuration alone does not establish compliance. |

### 4.2 Review the Exact Revision and Verification Gaps

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | SA-11 Developer Testing and Evaluation |

#### Description

Enable review coverage for the intended repositories and require evidence for the exact pushed commit. A Verification agent pass can still contain skipped claims and is not production validation.

#### Rationale

**Why This Matters:**

- Model review and local behavior tests cover different failure modes.
- Broad skipped-branch patterns can cause required checks to pass without review.

**Attack Prevented:** Merging unreviewed changes or relying on stale/incomplete test evidence.

#### ClickOps Implementation

1. Open **Settings → Review agent → Repositories** and choose the intended **Repository-wide → Every PR** coverage; My PRs affects only the current user.
2. Review **Skipped branches** and keep patterns narrowly scoped to the intended merge-queue branches. Matching branches receive skipped checks; do not use broad exemptions.
3. Set up the repository Verification agent via /setup-verification-agent and review its .inspect/verification/config.yml and real repository skill. In **Settings → Agent**, retain **Run Verification agent on Pull Requests** when appropriate.
4. For the exact PR revision, open the session **Reviews → Verification agent**; use **Verify again** or **Retry verification** when needed, and inspect every skipped/not_verified claim before accepting the result.

**Sources:** [pull-requests/review-agent](https://docs.inspect.com/pull-requests/review-agent), [pull-requests/verification-agent](https://docs.inspect.com/pull-requests/verification-agent) (checked 2026-11-17).

#### Code Implementation

The config pack emits review or verification configuration from an existing repository skill; it neither invents the skill nor installs the configuration. Inspect review rules use .inspect/reviews/rules.yml. The API pack requires the exact session, repository, PR and expected head SHA, previews by default, and starts verification only with explicit application opt-in. It can incur model cost, supersede older runs and invoke verification even when automatic verification is off. It rechecks the head, but the API offers no atomic SHA precondition, so a concurrent push remains a race. A 202 response means started or already running, not passed.

{% include pack-code.html vendor="inspect" section="4.2" %}

#### Validation & Testing

Confirm review applies to the intended authors, the head SHA is current, and verification exercised relevant behaviors. A pass requires at least one verified claim and no failures, not all claims verified; changes with no observable behavior may have no result.

#### Operational Impact

Review costs and setup failures can delay work. Repair the repository skill/config rather than silently removing checks. Verify after new pushes and avoid editing the workspace during a run.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| NIST SP 800-53 Rev. 5 | SA-11 Developer Testing and Evaluation | Supports this control objective; configuration alone does not establish compliance. |

### 4.3 Narrow Automation Triggers and Destinations

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-3 Access Enforcement |

#### Description

Review all triggers, repositories, execution identity and destinations for each automation. Prefer explicit repositories, channels, event conditions and approved recipients over broad defaults.

#### Rationale

**Why This Matters:**

- A trigger can convert untrusted issue/comment content into agent work.
- All repositories includes subsequently connected repositories, and conditionless Slack triggers match every selected event.

**Attack Prevented:** Unintended unattended execution and disclosure through broad result destinations.

#### ClickOps Implementation

1. Open the automation editor and inspect each independently enabled trigger under **Add trigger**.
2. For GitHub triggers, select explicit repositories and the documented branch/file/author conditions needed for the workflow. For Slack, restrict channels and author/type/text/reaction conditions with stable IDs, not display names.
3. Review **Custom agent, model & repositories** and the result destination. Keep credentials and generated sensitive output out of automation_state.
4. Test with a harmless matching event and a nonmatching event; review the resulting session before expanding scope.

**Sources:** [automations](https://docs.inspect.com/automations), [automations/github](https://docs.inspect.com/automations/github), [automations/slack](https://docs.inspect.com/automations/slack) (checked 2026-11-17).

#### Code Implementation

{% include pack-code.html vendor="inspect" section="4.3" %}

#### Validation & Testing

Use the API inventory as evidence for the authenticated user’s accessible automations, not a guarantee of complete organization coverage. Review redacted fields in the UI using appropriate privileges. A recorded configuration is not proof of delivery or safe model behavior.

#### Operational Impact

Narrowing conditions may suppress intended work. Restore only a tested condition/destination. State snapshots are captured at run creation, so overlapping runs do not see later state changes.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| NIST SP 800-53 Rev. 5 | AC-3 Access Enforcement | Supports this control objective; configuration alone does not establish compliance. |

### 4.4 Set Session and Review Spend Limits

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | SC-5 Denial-of-Service Protection |

#### Description

Set finite soft and hard session limits and a Review agent cost limit appropriate to the workload. Treat these as cost containment rather than action authorization.

#### Rationale

**Why This Matters:**

- Unattended or looping agent work can consume resources unexpectedly.
- A soft stop can be continued; a hard stop cannot continue the same session.

**Attack Prevented:** Unbounded agent resource consumption.

#### ClickOps Implementation

1. Open **Usage & Limits → Limits**.
2. With permission to manage security settings, set the **Session soft limit** and **Session hard limit** to approved amounts. People who manage code review set **Review agent cost limit**.
3. Document who may select **Continue** after a soft pause and review new-session creation following a hard stop.

**Sources:** [settings](https://docs.inspect.com/settings) (checked 2026-11-17).

**Automation:** ClickOps configuration. No matching administration endpoint or complete native configuration contract was found in the reviewed [public API reference](https://docs.inspect.com/api) and linked [OpenAPI schema](https://docs.inspect.com/api/openapi.json) on 2026-11-17. This is a bounded documentation result, not proof that no private interface exists; see the source ledger for other surfaces.

#### Validation & Testing

Use a controlled inexpensive test or observed limit event to confirm the pause/stop behavior. Confirm API prompts are rejected for sessions past their limit; inspect the transcript and owner notification.

#### Operational Impact

Low limits interrupt legitimate work. Raise only to a reviewed budget, not unlimited access. These limits do not replace permission or data controls.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| NIST SP 800-53 Rev. 5 | SC-5 Denial-of-Service Protection | Supports this control objective; configuration alone does not establish compliance. |

### 4.5 Disable Unneeded Scheduled and Event Automations

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | CM-7 Least Functionality |

#### Description

Disable the exact automation’s scheduled/event execution when it is no longer required. Review the effect separately from current runs, manual invocations and other automations.

#### Rationale

**Why This Matters:**

- Old automation configurations can retain access and continue acting unnoticed.
- Disabling a future trigger is not equivalent to revoking credentials or stopping an active session.

**Attack Prevented:** Continued unattended activity from stale automation jobs.

#### ClickOps Implementation

1. Open the exact automation editor and review its triggers and owner.
2. Pause/disable the relevant recurring/event execution after reviewing dependencies. Use the API pack to preview the targeted enabled-state change before explicit application.
3. Inspect already-running sessions and any required credential containment separately. Retain configuration evidence for rollback.

**Sources:** [automations](https://docs.inspect.com/automations), [api/automations/updateAutomation](https://docs.inspect.com/api/automations/updateAutomation), [api/automations/getAutomation](https://docs.inspect.com/api/automations/getAutomation) (checked 2026-11-17).

#### Code Implementation

{% include pack-code.html vendor="inspect" section="4.5" %}

#### Validation & Testing

Read back the saved state and test that a harmless subsequent scheduled/event condition does not start an unintended run. The pack does not disable manual-only execution or stop running sessions.

#### Operational Impact

Disabling can interrupt reports or maintenance. Restore only the approved execution state after a scoped review; do not archive or delete a job merely to pause it.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| NIST SP 800-53 Rev. 5 | CM-7 Least Functionality | Supports this control objective; configuration alone does not establish compliance. |

## 5. Monitoring and Configuration Integrity

### 5.1 Export Administrative Audit Evidence

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AU-6 Audit Record Review, Analysis, and Reporting |

#### Description

Review and export Inspect administrative audit events to a controlled archive with the retention needed by the organization. Do not assume an undocumented retention window or complete agent-activity logging.

#### Rationale

**Why This Matters:**

- The default view covers the current month, so an unadjusted export can miss older evidence.
- Audit logs omit prompts, tool calls and network request history; private traffic needs separate logs.

**Attack Prevented:** Undetected administrative access changes and loss of investigation evidence.

#### ClickOps Implementation

1. As an organization administrator, open **Organization → Audit logs**.
2. Set an explicit date range and review sign-in policy, roles, API keys, connectors, environment variables, repositories and automation changes. Search does not include event-specific details.
3. Choose **Export CSV** for all matching records, then store the export in an access-controlled archive. Validate date coverage, fields and event counts independently.
4. Include provider/VPN logs in investigations; Inspect has no documented fixed retention period, scheduled audit export, continuous streaming or built-in SIEM forwarding.

**Sources:** [security/audit-logs](https://docs.inspect.com/security/audit-logs), [settings/private-networking](https://docs.inspect.com/settings/private-networking) (checked 2026-11-17).

**Automation:** The audit-log documentation mentions an administrator-only API but does not specify its endpoint or schema in the reviewed public reference. No guessed audit API collector is supplied. CSV export is documented; continuous forwarding and scheduled export are explicitly unavailable. A downstream SIEM rule requires a defined ingestion/normalization contract.

#### Validation & Testing

Verify the CSV contains an expected harmless recent administrative event and the intended date range. Only API key prefixes, not full credentials, are recorded. An empty field can mean not applicable or a deleted related entity.

#### Operational Impact

Exports contain identities, IPs and event details. Restrict archive access and test retention/retrieval. Restore an export from a verified archive rather than assuming the vendor retains it indefinitely.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| NIST SP 800-53 Rev. 5 | AU-6 Audit Record Review, Analysis, and Reporting | Supports this control objective; configuration alone does not establish compliance. |

### 5.2 Protect Agent and Review Instruction Files

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | CM-3 Configuration Change Control |

#### Description

Review effective repository instruction precedence and protect agent/review policy changes through code review. Instructions guide behavior but do not constitute an access-control boundary.

#### Rationale

**Why This Matters:**

- An overlooked higher-precedence file can replace expected repository instructions.
- Review agent orchestration instructions come from the PR head, which is untrusted until reviewed.

**Attack Prevented:** Policy drift and prompt manipulation through repository-controlled instructions.

#### ClickOps Implementation

1. In **Repository settings**, confirm the repository and base branch used for sessions.
2. Review root instruction files in documented order: AGENTS.override.md, AGENTS.md, AGENTS.MD, CLAUDE.md, CLAUDE.MD, REVIEW.md; Inspect uses the first readable one.
3. Inspect .inspect/AGENTS.md, which takes precedence for conflicts, and relevant directory-scoped files. Nested .inspect/AGENTS.md files are not automatically loaded.
4. Review .inspect/reviews/ADDITIONAL_ORCHESTRATION.md, review/approval policies and referenced skills as security-relevant changes. Keep approval policy paths in the deny set from control 4.1.

**Sources:** [settings/repositories](https://docs.inspect.com/settings/repositories), [pull-requests/review-agent](https://docs.inspect.com/pull-requests/review-agent), [customize/skills](https://docs.inspect.com/customize/skills) (checked 2026-11-17).

**Automation:** Repository instruction and skill files are documented native text configuration, not executable enforcement. No prose-only Code Pack is created. Review them with the repository’s ordinary diff and protected-change workflow; the approval config pack in 4.1 protects sensitive path categories.

#### Validation & Testing

Use a benign task to confirm expected instructions and check for shadowing. Each loaded instruction file has a 16 KiB initial limit; verify the complete file is read before depending on content beyond it.

#### Operational Impact

Instruction changes can affect every new task. Restore the reviewed file content through normal change control; do not rely on prompts to deny technically granted access.

#### Compliance Mappings

| Framework | Control | Relationship |
|-----------|---------|--------------|
| NIST SP 800-53 Rev. 5 | CM-3 Configuration Change Control | Supports this control objective; configuration alone does not establish compliance. |

## 6. Compliance Quick Reference

The mappings are implementation relationships, not certification claims or evidence that Inspect satisfies a framework. The [NIST SP 800-53 catalog](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) provides the reference vocabulary. No Inspect-specific CIS, DISA STIG, SCuBA, NSA or ACSC baseline was identified in the bounded source search; generic guidance is not substituted for a product benchmark.

| Objective | NIST SP 800-53 Rev. 5 | Inspect controls |
|-----------|---------------------|------------------|
| Identity and authentication | IA-2, IA-5, IA-9 | 1.1–1.2, 2.5 |
| Access enforcement and least privilege | AC-3, AC-6 | 1.3, 2.1–2.4, 2.6, 3.3, 4.3 |
| Configuration governance | CM-3, CM-7 | 3.2, 4.1, 4.5, 5.2 |
| Protection and boundary containment | SC-5, SC-7, SC-28 | 3.1, 3.4, 4.4 |
| Testing and evidence | SA-11, AU-6 | 4.2, 5.1 |

## Appendices

### Applicability and Prerequisites

| Area | Requirement or boundary |
|------|-------------------------|
| Organization settings | Administrative or delegated feature permission; exact grants vary by surface. |
| OIDC connectors | Not available to every organization; use displayed verification details. |
| Workload identities | Organization administrator; trust at the destination remains mandatory. |
| Organization Approval policies | Documented as coming soon/rolling out; do not assume availability. |
| API packs | A suitable API key, the packs’ fixed supported app.inspect.com origin, and declared local dependencies. |
| Audit records | Organization administrators; no documented fixed retention period or continuous export. |

### References

- [Inspect documentation index](https://docs.inspect.com/llms.txt)
- [Inspect public API reference](https://docs.inspect.com/api)
- [Inspect OpenAPI schema](https://docs.inspect.com/api/openapi.json)
- [Connector security and trust boundaries](https://docs.inspect.com/security/connectors)
- [Source coverage and unresolved gaps](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/inspect-source-coverage.md)

## Changelog

| Version | Date | Maturity | Changes | Author |
|---------|------|----------|---------|--------|
| 0.1.0 | 2026-11-23 | ai-drafted | Initial Inspect controls, source-boundary research, and documented automation surfaces. No live tenant validation. | OpenAI Codex |

## Contributing

Report source drift, edition differences and reproducible validation results through the [contribution process](https://github.com/grcengineering/how-to-harden/blob/main/CONTRIBUTING.md). Never include credentials, private tenant exports or customer code in an issue or pull request.
