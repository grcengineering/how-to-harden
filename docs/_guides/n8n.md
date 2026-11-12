---
layout: guide
title: "n8n Hardening Guide"
vendor: "n8n"
slug: "n8n"
tier: "2"
category: "DevOps"
description: "Harden n8n workflow identity, credentials, node execution, outbound access, retained data, and audit visibility."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-12"
---

## Overview

n8n connects business systems through executable workflows. Its [current legal terms](https://n8n.io/legal/eula/) identify n8n GmbH as the provider. This standalone guide addresses product controls for Cloud and self-hosted deployments, not generic host administration. It reconciles [Pluto's n8n security recommendations](https://pluto.security/blog/n8n-security-issues/) with current first-party implementation documentation; it does not reproduce unverified vulnerability claims.

### Intended Audience

Instance owners, automation platform administrators, and security engineers responsible for workflow integrations.

### How to Use This Guide

Apply L1 (Crawl) fundamentals first, then L2 (Walk) restrictions after testing integrations. L3 (Run) and L4 (Fly) are available profile levels but no controls in this focused guide require them. Export configuration and establish recovery access before changing authentication. Cloud tenants cannot directly apply self-hosted environment files.

### Scope and Evidence Limits

Cloud plan and self-hosted license gates differ. Version conditions below matter; unknown settings must not be assumed effective. This documentation-based baseline has not been tested against a tenant. [n8n's Trust Center](https://trust.n8n.io/) exposes assurance reports and policies; private document contents were not available, so no claim of a complete private hardening catalog is made. No n8n-specific CIS, DISA STIG, or CISA SCuBA benchmark was located in the bounded public search; mappings below are control objectives, not certification.

## Table of Contents

1. [Identity and Workflow Ownership](#1-identity-and-workflow-ownership)
2. [Credentials and Execution Boundaries](#2-credentials-and-execution-boundaries)
3. [Exposure and Evidence](#3-exposure-and-evidence)
4. [References](#4-references)

## 1. Identity and Workflow Ownership

### 1.1 Require Strong Authentication and Accountable Projects

**Profile Level:** L1 (Crawl)

| Framework | Control |
|---|---|
| NIST 800-53 | IA-2, AC-6 |

#### Description

Use enforced MFA for password users and project-scoped workflow ownership. SSO sessions must satisfy MFA at the identity provider; local MFA enforcement does not cover SAML or OIDC.

#### Rationale

**Why This Matters:**
- A compromised editor can operate integrations with stored authority.
- Individual accounts and project roles make ownership and removal reviewable.

**Attack Prevented:** Account takeover and overprivileged workflow modification.

#### Prerequisites

Security policies require Cloud Enterprise or self-hosted Business/Enterprise. Environment-managed policy requires 2.18.0 or later; project/role availability varies by plan.

#### ClickOps Implementation

1. In **Settings > Policies**, enable **Enforce two-factor authentication**. For SSO, verify the IdP policy separately.
2. For accounts without enforced policy support, use **Settings > Profile & preferences > Enable 2FA** and audit enrollment; voluntary enrollment is not enforcement.
3. Select **Add project**, assign an accountable owner, then **Project settings > Project members** and grant the least necessary role.
4. Where licensed, restrict **Personal Space** sharing/publishing in Policies. Existing shares and published workflows remain active: inventory and review them separately. Preview workflow reviews are not a production security boundary.

#### Code Implementation

{% include pack-code.html vendor="n8n" section="1.1" %}

#### Validation & Testing

Use a test password account without MFA and confirm enrollment is required; test SSO independently. Confirm a project member cannot access unrelated credentials. Reconcile every production workflow to an owner and connected systems.

#### Compliance Mappings

| Framework | Control objective |
|---|---|
| NIST 800-53 | IA-2, AC-6 |

**Sources:** [Security policies](https://docs.n8n.io/deploy/host-n8n/configure-n8n/security/manage-security-policies), [Individual 2FA](https://docs.n8n.io/administer/manage-users-and-access/verify-user-identity/require-two-factor-auth.md), [Projects](https://docs.n8n.io/administer/manage-users-and-access/set-permissions-and-roles-rbac/organize-work-in-projects.md).

## 2. Credentials and Execution Boundaries

### 2.1 Scope Credentials and Protect Runtime Secrets

**Profile Level:** L1 (Crawl)

| Framework | Control |
|---|---|
| NIST 800-53 | IA-5, AC-6 |

#### Description

Use n8n credentials rather than secrets embedded in node parameters or exported workflows. Grant each integration only the upstream operations and resources it needs; encryption at rest does not constrain what an authorized workflow can do.

#### Rationale

**Why This Matters:**
- Credential access can bridge otherwise separated business systems.
- Global environment variables are not a substitute for scoped credential storage.

**Attack Prevented:** Credential disclosure and cross-project privilege reuse.

#### Prerequisites

External secret stores require Enterprise. Apply environment restrictions only to self-hosted instances after testing workflows that use environment expressions.

#### ClickOps Implementation

1. Inspect each workflow credential reference and replace embedded secrets with dedicated least-privilege integration credentials; rotate exposed values at their issuing service.
2. Enterprise administrators: open **Settings > External Secrets > Add secrets vault**, configure the approved provider, and save.
3. Edit the vault and use **Share > Project** rather than Global when access should be project-bound. Verify the upstream vault identity is independently scoped.
4. Apply the runtime protections below through the self-hosted deployment configuration; these settings have no corresponding documented editor toggle.

#### Code Implementation

{% include pack-code.html vendor="n8n" section="2.1" %}

#### Validation & Testing

Use a harmless test credential to verify intended workflows still work and unrelated projects cannot resolve it. Confirm environment access fails in node expressions. Protect and test recovery of the existing encryption key; never replace it casually on an established instance.

#### Compliance Mappings

| Framework | Control objective |
|---|---|
| NIST 800-53 | IA-5, AC-6 |

**Sources:** [External secrets](https://docs.n8n.io/administer/manage-credentials/use-external-secret-stores.md), [Runtime security settings](https://docs.n8n.io/deploy/host-n8n/configure-n8n/basic-configuration/use-environment-variables/security.md).

### 2.2 Limit Nodes and Isolate Code Execution

**Profile Level:** L2 (Walk)

| Framework | Control |
|---|---|
| NIST 800-53 | CM-7 |

#### Description

Disable unnecessary high-risk nodes and unreviewed community code. Node restrictions reduce available functionality but do not make malicious workflow authors harmless.

#### Rationale

**Why This Matters:**
- Community and custom nodes add executable supply-chain dependencies.
- Shell and filesystem capabilities can turn workflow access into host access.

**Attack Prevented:** Arbitrary command execution and unauthorized local file access.

#### Prerequisites

Self-hosted deployment configuration access; review existing node use before restarting. Code-node deployments need a separately tested external task-runner configuration.

#### ClickOps Implementation

1. Inventory workflows that use command, filesystem, community, or custom nodes before changing availability.
2. Merge the native environment values below into the deployment and restart using your normal change process. The [node exclusion documentation](https://docs.n8n.io/deploy/host-n8n/configure-n8n/security/block-specific-nodes.md) describes a startup configuration, not an editor toggle.
3. If Code nodes are required, follow the [external task-runner hardening instructions](https://docs.n8n.io/deploy/host-n8n/configure-n8n/security/harden-task-runners.md): separate containers, unprivileged execution, and constrained filesystem. Do not enable all module imports as a workaround.

#### Code Implementation

{% include pack-code.html vendor="n8n" section="2.2" %}

#### Validation & Testing

Test both an existing workflow and a newly created workflow using an excluded node; neither should execute that capability. Confirm approved workflows continue running. Review custom-node directories separately because community-package settings are not a universal custom-code sandbox.

#### Compliance Mappings

| Framework | Control objective |
|---|---|
| NIST 800-53 | CM-7 |

**Sources:** [Node configuration](https://docs.n8n.io/deploy/host-n8n/configure-n8n/basic-configuration/use-environment-variables/nodes.md), [Node exclusions](https://docs.n8n.io/deploy/host-n8n/configure-n8n/security/block-specific-nodes.md).

## 3. Exposure and Evidence

### 3.1 Restrict Outbound Destinations and Webhook Exposure

**Profile Level:** L2 (Walk)

| Framework | Control |
|---|---|
| NIST 800-53 | SC-7 |

#### Description

Enable n8n SSRF protection alongside network-level egress controls and authenticated inbound workflows. The application guard is defense in depth, not a firewall replacement.

#### Rationale

**Why This Matters:**
- A workflow can otherwise target internal services or cloud metadata.
- Public webhook URLs alone do not authenticate their callers.

**Attack Prevented:** Server-side request forgery and unauthorized workflow triggering.

#### Prerequisites

Self-hosted n8n 2.12.0 or later for the SSRF setting; network controls remain deployment-specific.

#### ClickOps Implementation

1. Configure the application setting below through the self-hosted deployment. Keep private, loopback, link-local, and metadata destinations blocked unless a documented integration needs an exception.
2. Review allowlists narrowly: allowed hostnames take precedence over blocked IP ranges. Never allow arbitrary user-controlled domains.
3. Run the security audit in 3.3 and inspect its unprotected webhook findings. Configure authentication appropriate to each trigger and verify authorization in the workflow.
4. Require TLS on editor/webhook ingress using the vendor [SSL guidance](https://docs.n8n.io/deploy/host-n8n/configure-n8n/security/set-up-ssl.md), and restrict network access to approved services.

#### Code Implementation

{% include pack-code.html vendor="n8n" section="3.1" %}

#### Validation & Testing

In a nonproduction instance, verify a request to a controlled private test endpoint is blocked while an approved public API works. Include redirect and DNS tests. Confirm an unauthenticated webhook request cannot trigger a protected operation.

#### Compliance Mappings

| Framework | Control objective |
|---|---|
| NIST 800-53 | SC-7 |

**Sources:** [SSRF protection](https://docs.n8n.io/deploy/host-n8n/configure-n8n/security/enable-ssrf-protection.md), [Security audit](https://docs.n8n.io/deploy/host-n8n/configure-n8n/security/run-security-audits.md).

### 3.2 Minimize Retained Execution Payloads

**Profile Level:** L2 (Walk)

| Framework | Control |
|---|---|
| NIST 800-53 | SI-12, AU-9 |

#### Description

Minimize persisted workflow payloads and select retention consistent with incident-response and legal requirements. Execution history can contain sensitive inputs even when credential fields are encrypted.

#### Rationale

**Why This Matters:**
- Successful and failed executions can duplicate business data.
- Unbounded histories increase the impact of instance compromise.

**Attack Prevented:** Sensitive-data exposure through execution history.

#### Prerequisites

Self-hosted configuration access for the pack. The sample omits payload saving and enables pruning; obtain retention approval before deployment because deleted history is not recoverable through n8n.

#### ClickOps Implementation

1. Review workflow-specific execution settings before applying the baseline; overrides must be assessed.
2. Apply the native execution variables below only after deciding what diagnostic evidence must be retained.
3. For Enterprise 2.26.0+, **Settings > Policies > Data redaction > Enforce data redaction** can impose a workflow minimum; select manual and production scope where required. Redaction is not equivalent to deleting stored data.

#### Code Implementation

{% include pack-code.html vendor="n8n" section="3.2" %}

#### Validation & Testing

Run successful, failing, and manual test workflows with harmless distinctive payloads. Verify retained records and pruning behavior; check per-workflow exceptions and avoid placing secrets in test data.

#### Compliance Mappings

| Framework | Control objective |
|---|---|
| NIST 800-53 | SI-12, AU-9 |

**Sources:** [Execution settings](https://docs.n8n.io/deploy/host-n8n/configure-n8n/basic-configuration/use-environment-variables/executions.md), [Redaction enforcement](https://docs.n8n.io/deploy/host-n8n/configure-n8n/security/manage-security-policies).

### 3.3 Audit the Estate, Monitor Changes, and Maintain Versions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|---|---|
| NIST 800-53 | CM-8, SI-2, AU-6 |

#### Description

Maintain an instance and workflow register and repeat the native security audit after changes. Treat audit findings as review inputs, not proof of complete coverage or automatic fixes.

#### Rationale

**Why This Matters:**
- Unowned instances and unused credentials survive outside normal change review.
- Configuration and dependency risks return after updates or new workflows.

**Attack Prevented:** Undetected workflow misuse and exposure to known vulnerabilities.

#### Prerequisites

The CLI pack requires the installed first-party n8n CLI in the actual instance environment with its configured database. Enterprise licensing is required for log streaming.

#### ClickOps Implementation

1. Assign owners for instances, production workflows, credentials, and external systems; review approved workflow templates and changes.
2. In a workflow using the **n8n** node, choose **Audit > Generate**; alternatively run the read-only CLI pack below. Investigate credentials, nodes, webhooks, and instance findings.
3. Enterprise: **Settings > Log Streaming > Add new destination**, choose an approved destination and **Events**, then save. Monitor credential sharing, package changes, workflow modification, and login failures.
4. Cloud owners: **Cloud console > Instance settings > Updates**, select an appropriate stable version/maintenance window and save. Self-hosted owners must test and deploy current supported releases through their deployment process.

#### Code Implementation

{% include pack-code.html vendor="n8n" section="3.3" %}

#### Validation & Testing

Record version, audit time, findings and owner remediation. Trigger a harmless workflow edit and verify the event reaches monitoring. Re-run after upgrades; an empty audit is not an inventory of all external systems or a penetration test.

#### Compliance Mappings

| Framework | Control objective |
|---|---|
| NIST 800-53 | CM-8, SI-2, AU-6 |

**Sources:** [Audit CLI and API](https://docs.n8n.io/deploy/host-n8n/configure-n8n/security/run-security-audits.md), [Log streaming](https://docs.n8n.io/administer/observe-and-log/stream-logs-to-external-systems.md), [Cloud updates](https://docs.n8n.io/deploy/use-n8n-cloud/update-your-version.md).

## 4. References

- [n8n security configuration](https://docs.n8n.io/deploy/host-n8n/configure-n8n/security.md)
- [Pluto n8n risk analysis](https://pluto.security/blog/n8n-security-issues/)
- [n8n documentation index](https://docs.n8n.io/llms.txt)

## Changelog

| Version | Date | Changes |
|---|---|---|
| 0.1.0 | 2026-11-12 | Initial focused baseline reconciling Pluto recommendations with n8n product controls. |
