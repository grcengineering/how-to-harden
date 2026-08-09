---
layout: guide
title: "HCP Terraform (formerly Terraform Cloud) Hardening Guide"
vendor: "HCP Terraform"
slug: "terraform-cloud"
tier: "3"
category: "IaC"
description: "IaC platform security for HCP Terraform (formerly Terraform Cloud): workspace variables, team access, audit trails, and run triggers"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---


## Overview

**HCP Terraform** is the product HashiCorp renamed from **Terraform Cloud** in 2024 ([HCP Terraform overview](https://developer.hashicorp.com/terraform/cloud-docs/overview)); documentation still lives under `/terraform/cloud-docs/` paths. HCP Terraform state files containing plaintext secrets, cloud provider credentials, and workspace configurations make IaC platforms high-value targets. Vault-backed dynamic credentials via OIDC federation represent best practice for eliminating stored secrets. State file exposure reveals database passwords and API keys; malicious provider backdoors infrastructure.

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
This guide covers HCP Terraform (formerly Terraform Cloud) security configurations including authentication, access controls, audit trails, and integration security. Terraform Enterprise (self-hosted) differences are called out where they matter.

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
Require SAML single sign-on with MFA through your corporate IdP for all HCP Terraform organization access, and scope team API tokens to least privilege with expiration and regular rotation.

#### Rationale
**Why This Matters:**
- Centralizes HCP Terraform authentication in your IdP so MFA and conditional access apply to every user login
- Local logins and long-lived personal tokens bypass IdP controls and are prime targets for credential stuffing and phishing
- Enforcing SSO with SCIM provisioning deprovisions departed users automatically, eliminating orphaned accounts that retain infrastructure access
- HCP Terraform can plan and apply changes to production cloud accounts, so a single compromised login can rewrite or destroy infrastructure

**Attack Prevented:** Credential theft, phishing, MFA bypass, orphaned-account access, token abuse

#### ClickOps Implementation

> **Changed availability:** Single sign-on is now **available to all HCP Terraform organizations** — it is no longer gated to a paid edition. Source: [HCP Terraform single sign-on](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/single-sign-on).

**Step 1: Configure SSO**
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

#### Code Implementation

{% include pack-code.html vendor="terraform-cloud" section="1.2" %}

---

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

**Step 3: Webhook Secret Hygiene**

> **Security advisory (HCSEC-2026-09, 2026-04-20):** GitHub inadvertently included webhook secrets in the HTTP headers of outbound webhook deliveries between **September 2025 and January 2026**. HashiCorp fully automated rotation of all potentially affected GitHub webhook secrets for HCP Terraform SaaS; **Terraform Enterprise customers must follow the manual remediation paths** in the advisory. Source: [HCSEC-2026-09](https://discuss.hashicorp.com/t/hcsec-2026-09-remediation-and-improved-secret-management-for-github-webhook-secret-exposure/77357).

1. Treat VCS webhook secrets as rotatable credentials: inventory every VCS connection (OAuth client) and record where its webhook secret is used
2. On Terraform Enterprise, follow the HCSEC-2026-09 manual remediation steps to rotate GitHub webhook secrets; on HCP Terraform SaaS, confirm the automated rotation covered your organization
3. Monitor audit trail events for unexpected `oauth_client` changes (see the Sigma rule in this guide's pack) — removal or re-creation of a VCS OAuth client outside a change window is a tampering signal

#### Code Implementation

{% include pack-code.html vendor="terraform-cloud" section="2.1" %}

---

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
- State files record every resource attribute Terraform manages, including values providers mark sensitive — database passwords, API keys, and connection strings persist in state as plaintext
- Anyone who can read or download state effectively holds the credentials to the infrastructure it describes, without ever touching the cloud console
- State is also a complete infrastructure blueprint, giving an attacker the reconnaissance map needed to target the highest-value resources first
- Restricting state access to the smallest possible set of teams limits the blast radius of any single compromised account or token

**Attack Prevented:** State file exfiltration, credential harvesting from state, infrastructure reconnaissance via the state blueprint.

#### ClickOps Implementation

**Step 1: Enable State Encryption**
- HCP Terraform encrypts state at rest by default
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
Mark workspace and variable-set values that contain secrets as sensitive so HCP Terraform masks them in the UI, run logs, and API responses and never exposes them in plan output.

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

### 4.3 Patch and Isolate the Terraform MCP Server

**Profile Level:** L2 (Walk)
**NIST 800-53:** SI-2, SC-7

#### Description
If you expose HCP Terraform to AI agents or IDE assistants through HashiCorp's `terraform-mcp-server`, treat the MCP server as a credential-bearing integration path: keep it patched to at least version 1.1.0, restrict which clients can reach it, and never share one server instance across trust boundaries.

#### Rationale
**Why This Matters:**
- **HCSEC-2026-23 (2026-07-28)** disclosed three vulnerabilities in `terraform-mcp-server` versions 0.2.1 through 1.0.0, fixed in **1.1.0**: an SSRF letting an unauthenticated client redirect the server's bearer token to an attacker-controlled endpoint (**CVE-2026-14869**), a stateful-mode authorization bypass exposing another user's cached Terraform credentials (**CVE-2026-16496**), and stateless-mode cross-tenant credential reuse (**CVE-2026-16498**)
- The MCP server holds HCP Terraform API tokens on behalf of its clients — a compromised or shared server is a direct path to the same credentials this guide's token controls protect
- MCP is a new integration surface that typically bypasses the review gates applied to VCS and CI/CD integrations

**Attack Prevented:** Bearer-token exfiltration via SSRF, cross-user and cross-tenant credential exposure through a shared MCP server.

#### ClickOps Implementation

**Step 1: Inventory and Patch**
1. Identify every `terraform-mcp-server` deployment (developer laptops, shared gateways, CI agents)
2. Upgrade all instances to **version 1.1.0 or later** per [HCSEC-2026-23](https://discuss.hashicorp.com/t/hcsec-2026-23-multiple-vulnerabilities-impacting-hashicorp-terraform-mcp-server/77606)

**Step 2: Isolate**
1. Run one MCP server instance per user or per trust boundary — do not share a stateful instance across users
2. Network-restrict the server so only intended AI clients can reach it
3. Scope the HCP Terraform token the server holds to least privilege (team token with minimum workspace permissions, with expiry)

#### Validation & Testing
1. Confirm every deployed instance reports a version ≥ 1.1.0
2. Confirm the token used by each MCP server appears in your token inventory with an owner and an expiry

---

## 5. Monitoring & Detection

### 5.1 Audit Logging

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Continuously pull HCP Terraform audit trail events into your SIEM so authentication, authorization, workspace, run, and variable changes are recorded and monitored for anomalies. The audit trail is **pull-only**: `GET /organization/audit-trail` with `since` (ISO 8601 UTC), `page[number]`, and `page[size]` (default 1,000 events per page). Events are retained for **14 days**, and there is **no streaming, no log drain, and no push destination** — a scheduled pull job is the only way to preserve the trail. Availability: **Standard and Premium editions only; the audit trails API is not available for Terraform Enterprise.** Source: [Audit trails API](https://developer.hashicorp.com/terraform/cloud-docs/api-docs/audit-trails).

#### Rationale
**Why This Matters:**
- Comprehensive audit logs are required to detect unauthorized access, privilege changes, and suspicious run activity in time to respond
- The 14-day platform retention makes a continuous scheduled pull mandatory, not optional — events older than 14 days are unrecoverable
- Forwarding logs to a SIEM enables alerting and correlation that the platform console alone cannot provide; HashiCorp names the **HCP Terraform for Splunk app** as the reference SIEM integration ([audit trail tokens doc](https://developer.hashicorp.com/terraform/cloud-docs/api-docs/audit-trails-tokens))
- Without centralized logging, attacker actions such as rogue token creation or state tampering can go undetected until damage is done

**Attack Prevented:** Undetected intrusion, privilege abuse, repudiation, delayed breach detection

#### Detection Focus

Audit trail events use a nested payload — filter on `resource.type` and `resource.action` (for example `oauth_client` + `destroy` for VCS integration tampering; see the Sigma rule in the pack below). The Terraform pack verifies audit-trail API reachability and enforces organization-level 2FA.

#### Code Implementation

{% include pack-code.html vendor="terraform-cloud" section="5.1" %}

---

### 5.2 Govern Audit Trail Tokens

**Profile Level:** L2 (Walk)
**NIST 800-53:** IA-5, AC-6

#### Description
Audit trail data cannot be read with user or team tokens — it requires an **organization token or a dedicated audit trail token**, created via `POST /organizations/:organization_name/authentication-token?token=audit-trails`. Treat audit trail tokens as a distinct credential class with their own issuance, expiry, vaulting, and rotation policy. Source: [Audit trail tokens](https://developer.hashicorp.com/terraform/cloud-docs/api-docs/audit-trails-tokens).

#### Rationale
**Why This Matters:**
- The token secret is **shown once and unrecoverable** — it must be vaulted at creation or it will end up in scripts and chat logs
- `expired-at` is optional and **null means the token never expires**; an unexpiring credential that reads your full security telemetry is exactly what an attacker wants for silent reconnaissance
- Only owners-team members, owners-team API tokens, and organization API tokens may create or delete audit trail tokens (all others receive 404) — so creation events are a small, auditable set worth alerting on
- A leaked audit trail token exposes 14 days of organization-wide activity, including who changed what and when

**Attack Prevented:** Silent long-lived access to security telemetry, unaccounted-for credential sprawl, reconnaissance via stolen audit data.

#### ClickOps Implementation

**Step 1: Issue with Expiry**
1. Create audit trail tokens only via the documented endpoint, always setting `expired-at` — never accept the never-expires default
2. Store the one-time secret directly into your secrets manager

**Step 2: Restrict and Rotate**
1. Limit creation to the owners team; alert on any `authentication_token` create event in the audit trail
2. Rotate on a fixed schedule (quarterly) and whenever the consuming SIEM integration changes
3. Prefer the dedicated audit trail token over the organization token for SIEM pullers — it limits blast radius to audit reads

#### Validation & Testing
1. List issued tokens and confirm none have `expired-at: null`
2. Confirm the SIEM puller works with the dedicated audit trail token and that the organization token is not embedded in any pipeline

---

## Appendix A: Edition Compatibility

HCP Terraform's current editions are **Free, Essentials, Standard, and Premium** — HashiCorp states "each higher paid upgrade plan is a strict superset of any lower plans" ([HCP Terraform overview](https://developer.hashicorp.com/terraform/cloud-docs/overview)). The former Free / Team / Business tiers no longer exist.

| Control | Free | Essentials | Standard | Premium |
|---------|------|------------|----------|---------|
| SSO | ✅ | ✅ | ✅ | ✅ |
| Team management | ❌ | ✅ | ✅ | ✅ |
| Audit trails API | ❌ | ❌ | ✅ | ✅ |
| Dynamic credentials (OIDC) | ✅ | ✅ | ✅ | ✅ |

Notes:

- SSO is "available to all HCP Terraform organizations" ([single sign-on doc](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/single-sign-on)); the team management feature set starts at Essentials.
- The audit trails API is **Standard and Premium only**, and is **not available for Terraform Enterprise** ([audit trails API](https://developer.hashicorp.com/terraform/cloud-docs/api-docs/audit-trails)).
- Policy enforcement (Sentinel/OPA) entitlements vary by edition — confirm your organization's entitlement against the current HCP Terraform overview before depending on Control 2.2.

---

## Appendix B: References

**Official HashiCorp Documentation (HCP Terraform):**
- [HCP Terraform Documentation](https://developer.hashicorp.com/terraform/cloud-docs)
- [HCP Terraform Overview and Editions](https://developer.hashicorp.com/terraform/cloud-docs/overview)
- [Recommended Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices)
- [Single Sign-On](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/single-sign-on)
- [Audit Trails API](https://developer.hashicorp.com/terraform/cloud-docs/api-docs/audit-trails)
- [Audit Trail Tokens](https://developer.hashicorp.com/terraform/cloud-docs/api-docs/audit-trails-tokens)

**API & Developer Tools:**
- [HCP Terraform API Documentation](https://developer.hashicorp.com/terraform/cloud-docs/api-docs)
- [Terraform CLI](https://developer.hashicorp.com/terraform/cli)
- [Terraform Registry](https://registry.terraform.io/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27017, ISO 27018 — audit reports available to customers/prospects under NDA (contact customertrust@hashicorp.com)

**Security Incidents:**
- (2021) HashiCorp's GPG private key used for signing product download hashes was exposed in the Codecov supply-chain attack (January-April 2021). The key was revoked and replaced.
- (2025) Terraform Enterprise access control vulnerability (HCSEC-2025-34) allowed users with insufficient permissions to create state versions. Fixed in versions 1.1.1 and 1.0.3. No data breach reported.
- (2026) [HCSEC-2026-09](https://discuss.hashicorp.com/t/hcsec-2026-09-remediation-and-improved-secret-management-for-github-webhook-secret-exposure/77357) — GitHub inadvertently included webhook secrets in outbound webhook delivery headers (September 2025 – January 2026). HashiCorp automated rotation of affected GitHub webhook secrets for HCP Terraform SaaS; Terraform Enterprise requires manual remediation. See Control 2.1.
- (2026) [HCSEC-2026-17](https://discuss.hashicorp.com/t/hcsec-2026-17-terraform-enterprise-vulnerable-to-arbitrary-file-read/77549) — Terraform Enterprise arbitrary file read (CVE-2026-14468): VCS ingestion of registry modules did not correctly enforce the boundary on packaged module content, letting an authenticated user include and download files from outside the intended repository. Affects TFE v202506-1, v202507-1, and 1.0.0–2.0.3; fixed in 2.0.4 and 1.2.4.
- (2026) [HCSEC-2026-23](https://discuss.hashicorp.com/t/hcsec-2026-23-multiple-vulnerabilities-impacting-hashicorp-terraform-mcp-server/77606) — three vulnerabilities in `terraform-mcp-server` (CVE-2026-14869 SSRF token redirect, CVE-2026-16496 stateful-mode authorization bypass, CVE-2026-16498 stateless-mode cross-tenant credential reuse). Affects 0.2.1–1.0.0; fixed in 1.1.0. See Control 4.3.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass: renamed guide to HCP Terraform (formerly Terraform Cloud); rebuilt Appendix A on current Free/Essentials/Standard/Premium editions; added audit-trail specifics to 5.1 (pull-only endpoint, 14-day retention, Standard+Premium availability, Splunk app); new controls 4.3 (terraform-mcp-server, HCSEC-2026-23) and 5.2 (audit trail token governance); webhook-secret hygiene in 2.1 (HCSEC-2026-09); fixed 3.1 cheat-parser miss; added HCSEC-2026-09/-17/-23 incidents; retired a Sigma rule matching a nonexistent log-drain event and rewrote the workspace rule against the documented audit payload; purged trust-center references | Claude Code (Fable 5) |
| 2025-12-14 | 0.1.0 | draft | Initial Terraform Cloud hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
