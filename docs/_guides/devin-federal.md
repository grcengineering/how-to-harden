---
layout: guide
title: "Devin Federal Hardening Guide"
vendor: "Devin Federal"
slug: "devin-federal"
platform: "Cognition"
platform_slug: "cognition"
product: "Devin Federal"
tier: "2"
category: "AI/ML Platform"
description: "Harden the separate federal portal and air-gapped beta: SSO, group/model limits, signed licenses, host OIDC, inference credentials, CA/proxy trust and structured local audit."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-05"
---

## Overview

This is a product guide within the [Cognition platform](/guides/devin/). Harden the separate federal portal and air-gapped beta: SSO, group/model limits, signed licenses, host OIDC, inference credentials, CA/proxy trust and structured local audit.

### Intended Audience

- Account and endpoint administrators
- Integration/developer-platform owners
- Security and GRC teams reviewing effective access and evidence

### How to Use This Guide

- **L1 (Crawl):** Establish identity ownership and protect sensitive state.
- **L2 (Walk):** Restrict effective integration and execution authority.
- Pilot changes in a disposable environment with recovery and approved rollback. Configuration evidence and denial tests are separate from policy intent.

### Scope

Two related planes are deliberately separated: multi-tenant federal portal administration and air-gapped Desktop/CLI beta host files. Group APIs are multi-tenant gated; they do not configure an offline host. The air-gapped bundle does not inherit commercial cloud login, Cascade or automatic updates. Supported OS/architecture and feature availability must match the current [air-gapped runbook](https://docs.devin.ai/federal/air-gapped/overview). Third-party inference, IdP, MCP and SIEM administration remains with those owners.

**Validation status:** no tenants declared — Tier 0+1 only. This guide was researched from public configuration documentation and tested with local fixtures/stubs. No login, key creation, enrollment, integration, live product call or policy change was performed. It remains ai-drafted.

## Table of Contents

1. [Federal Portal Identity & Policy](#1-federal-portal-identity-policy)
2. [Air-gapped Authentication & Releases](#2-airgapped-authentication-releases)
3. [Models & Network Trust](#3-models-network-trust)
4. [State & Audit Evidence](#4-state-audit-evidence)

## 1. Federal Portal Identity & Policy

### 1.1 Enforce Federal Portal SSO, Roles and Service-Key Lifecycle

**Profile Level:** L1 (Crawl)

#### Description

Administer the federal portal through its own SSO, role and service-key workflow. Commercial Devin Authentication settings do not configure this plane.

#### Rationale

**Why This Matters:**
- The federal portal requires Cognition-assisted OIDC/SAML SSO and inherits MFA from the IdP.
- A displayed permission category can exist even when the corresponding portal feature is unavailable.

**Attack Prevented:** Excess portal privileges and surviving service credentials after offboarding.

#### Prerequisites

Federal deployment, portal/IdP administrator and account-team configuration. Use the actual assigned federal portal URL.

#### ClickOps Implementation

1. Configure portal SSO with Cognition and require MFA at the IdP; no email/password fallback is documented for the federal portal.
2. Open **Settings → Role Management** and grant only the required permissions; review **Manage Team → Edit Role** assignments. Do not interpret unavailable Indexing/Fine-Tuning/SSO permission tabs as available federal features.
3. Under **Settings → Service Keys**, review scopes and rotate by creating an approved replacement, updating consumers, verifying success, then deleting the old key. On offboarding remove roles and service keys, then delete the user/release the seat through **Manage Team**. Review the separate portal Auth Token workflow for current cloud CLI/Desktop login: a Profile API key is not that login token ([federal changelog](https://docs.devin.ai/federal/changelog)).

**Automation:** Federal group APIs and the portal-downloaded SDK use scoped service keys, but their existence does not prove a portal SSO/role-policy setter. These settings use the documented portal/account-team workflow; no commercial API or Terraform resource is substituted. Analytics is not a universal security-audit export.

#### Validation & Testing

Use an authorized pilot to confirm SSO/MFA and denied operations for a limited role. Review both user membership and associated keys. No portal login or credential creation was performed.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | AC-2, AC-6, IA-2, IA-5 | Supports configuration and access objectives |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Federal security administration](https://docs.devin.ai/federal/security) (retrieved 2026-11-05; no live validation).

---

### 1.2 Reconcile Group Model Access and ACU Limits

**Profile Level:** L2 (Walk)

#### Description

In eligible multi-tenant federal deployments, compute effective model access and spending limits across team, group and manual user overrides.

#### Rationale

**Why This Matters:**
- Nonempty group model selections combine by union and can widen access; an empty selection is no opinion.
- Group ACU limits resolve to the highest group cap unless a manual user override applies; no applicable cap can mean unlimited within the team cap.

**Attack Prevented:** Unexpected model access or spend after overlapping group assignments.

#### Prerequisites

Multi-tenant self-hosted group feature; Teams Read-Only/Analytics Read for reads, Teams Update for writes and portal Settings access. Portal SDK download requires authorized access.

#### ClickOps Implementation

1. Open **Settings → Groups**. Compare group membership and separate Cascade/Command model selections against the team’s upper-bound policy; CLI and Devin Local use Cascade policy.
2. Inspect team ACU limit, group defaults and **Manage Team → user actions → Edit Custom Limit**. Record the effective cap rather than taking the smallest group value. Legacy per-user caps can require Cognition support to remove.
3. Review partial-save warnings. Default-group membership applies to new users only; removing a group does not remove team access. Group deletion is irreversible and is not an offboarding operation.

#### Code Implementation

The API collector uses documented read-only JSON POSTs and follows every cursor; it records group effective/configured policy in a protected file. Group examples use `nextPageToken` while the API overview says `next_page_token`; the pack accepts either, rejects contradictions, and treats a missing cursor as unknown. The CLI wrapper invokes the actual portal-provided `windsurf_analytics.py list-groups` with an environment credential. The SDK itself is not available publicly in this run and is not replaced by a fake implementation. No commercial Terraform support is claimed.

{% include pack-code.html vendor="devin-federal" section="1.2" %}

#### Validation & Testing

Compare a pilot user in overlapping groups and one with a manual cap against router/model-picker behavior. Confirm missing-entitlement or malformed/partial responses fail unknown, not compliant. The wrapper was tested with argument stubs only; no real SDK or portal endpoint was called.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | AC-3, AC-6, SI-4 | Supports configuration and access objectives |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Groups](https://docs.devin.ai/federal/groups), [Model provisioning](https://docs.devin.ai/federal/model-provisioning), [ACU](https://docs.devin.ai/federal/acu-limits), [Group APIs](https://docs.devin.ai/federal/api/group-management), [SDK](https://docs.devin.ai/federal/api/python-sdk) (retrieved 2026-11-05; no live validation).

---

## 2. Air-gapped Authentication & Releases

### 2.1 Require Air-gapped OIDC When License-Only Access Is Insufficient

**Profile Level:** L2 (Walk)

#### Description

Deploy the air-gapped `auth.json` with `mode: sso` and a required IdP group when user authentication is required. A signed license alone does not enforce organizational identity.

#### Rationale

**Why This Matters:**
- A missing auth file defaults to license-only operation; OIDC is optional, not automatic.
- Logout deletes the local token cache, while IdP revocation/group changes are observed through refresh/expiry with documented skew.

**Attack Prevented:** Use by an unauthorized local user holding a valid license and stale group authorization.

#### Prerequisites

Air-gapped beta, reachable approved IdP endpoints, public PKCE S256 OIDC client without client secret, required group and machine configuration management.

#### ClickOps Implementation

1. There is no native portal GUI for this host policy. Deploy strict JSON to `/etc/devin/auth.json` (Windows `C:\ProgramData\Devin\auth.json`) or the reviewed `DEVIN_AUTH_FILE` override; protect the file and parents against user modification.
2. Use the emitter’s confirmed HTTPS issuer, client ID and required group. Retain `openid` scope and exact additional endpoint hosts only where discovery requires them; the additional list does not relax TLS validation.
3. Configure the supported loopback callback at `127.0.0.1` with random port and `/callback`. Use short appropriate ID-token lifetimes and review offline-access/refresh behavior. Do not store a client secret in a public-client config.

#### Code Implementation

The native emitter produces schema-version-0 OIDC policy with explicit required group and an empty additional-host list. Review the real IdP configuration, then deploy through host management; it never logs in or writes machine files. Reads use first-party auth status/doctor separately from commercial CLI.

{% include pack-code.html vendor="devin-federal" section="2.1" %}

#### Validation & Testing

On an authorized pilot test allowed and missing-group identities, issuer/endpoint restrictions and ID-token expiry. Include the documented `DEVIN_AUTH_FILE` environment override in that test: a protected default file alone does not prove users cannot select a different policy. Manage the actual launch environment and executable through host management; the fetched reference does not establish an immutable environment lock. Running sessions check validity every 60 seconds and force refresh at 15 minutes; expiry permits 120 seconds of skew, and refresh without a new ID token can retain cached claims for up to 24 hours. In-flight work is not instantaneously recalled. Local logout is not IdP-wide token revocation. Keep an approved recovery path rather than deleting the auth policy to bypass failures.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | IA-2, AC-3, IA-5 | Supports configuration and access objectives |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Air-gapped SSO](https://docs.devin.ai/federal/air-gapped/sso) (retrieved 2026-11-05; no live validation).

---

### 2.2 Protect Offline Licenses and Verified Release Bundles

**Profile Level:** L1 (Crawl)

#### Description

Manage signed per-seat licenses and air-gapped release bundles as controlled deployment artifacts. A valid offline license does not replace SSO or a review of the deployed version.

#### Rationale

**Why This Matters:**
- The CLI validates the license locally, with expiry/skew and periodic revalidation rather than instant remote revocation.
- Air-gapped Desktop bundles a matching CLI and lacks ordinary cloud auto-update assumptions.

**Attack Prevented:** Unauthorized license reuse and continued execution of an unreviewed or expired build.

#### Prerequisites

Portal license administrator, assigned seats, approved bundle source and release/change owner.

#### ClickOps Implementation

1. In the federal portal use **Team → Airgapped licenses → Generate License** only for approved labeled/assigned seats and duration. Revoke/reissue seats through the supported portal/support workflow.
2. Deploy the signed token at the documented machine path or reviewed `DEVIN_LICENSE_FILE`; keep machine folders administrator-owned. Verify the full release bundle against the vendor-provided checksums before transfer/install.
3. Inventory CLI/Desktop release versions and review the federal changelog before updating. Desktop and its bundled CLI come from the same commit; do not silently replace one with an unrelated commercial build. The portal serves one bundle at a time without a version picker or notification, so retain the approved prior package and its checksum for rollback. Quit clients before replacing the package; updates preserve external policy, history and SSO state. Revalidate models and license signing-key compatibility after updating.

#### Code Implementation

The first-party CLI wrapper only runs version, auth status, model validation and airgap doctor, saving private output. Those diagnostics can run without a valid license. It does not install licenses, download a release or start an agent. Portal-side revocation and installed offline expiry have different propagation.

{% include pack-code.html vendor="devin-federal" section="2.2" %}

#### Validation & Testing

Inspect a synthetic/approved pilot license expiry and configured path without logging the token. Document the expiry plus allowed clock-skew window (24 hours) and running-session revalidation before the next turn; do not claim immediate offline revocation. OS/Git email attribution is not cryptographic SSO identity.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | CM-8, SI-2, IA-5 | Supports configuration and access objectives |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Air-gapped overview](https://docs.devin.ai/federal/air-gapped/overview), [Licenses](https://docs.devin.ai/federal/air-gapped/license), [Updates and rollback](https://docs.devin.ai/federal/air-gapped/updates), [Federal changelog](https://docs.devin.ai/federal/changelog) (retrieved 2026-11-05; no live validation).

---

## 3. Models & Network Trust

### 3.1 Restrict Model Endpoints and Credential References

**Profile Level:** L2 (Walk)

#### Description

Maintain a reviewed machine-level models file with approved HTTPS inference endpoints, bounded model context and environment-referenced credentials.

#### Rationale

**Why This Matters:**
- All configured models can expose prompts/code to the chosen endpoint.
- Plaintext static authorization headers and a wrong process environment can disclose or fail credentials.

**Attack Prevented:** Sensitive context sent to an unintended model host and stored API secrets in shared configuration.

#### Prerequisites

Air-gapped beta; approved model, inference API type/context size and secret delivery to the actual CLI/Desktop process.

#### ClickOps Implementation

1. There is no cloud administration substitute for the native model file. Deploy the reviewed schema-version-0 `/etc/devin/models.json` (Windows ProgramData equivalent) or `DEVIN_MODELS_FILE` override.
2. Use `api_key.env` references and supported API types; do not store Authorization/Proxy-Authorization secrets in static headers. Supply the environment variable even when the selected endpoint does not require a real secret.
3. For Desktop deliver the environment to the launched agent (`devin.acp.agentEnv` where documented) and restart the agent process. Confirm only the approved model is the default.

#### Code Implementation

The emitter produces one real operator-supplied model entry, refuses URL credentials/query/fragment and references a named environment variable without reading its value. Current model reference text permits query strings, but the newer November 3 changelog says query/fragment values now fail `MDL010`; this pack follows the stricter released behavior. Run `devin models validate` for the installed build.

{% include pack-code.html vendor="devin-federal" section="3.1" %}

#### Validation & Testing

Validate offline shape then use first-party validation on an authorized installed build. Test the documented `DEVIN_MODELS_FILE` environment override: ownership of the default file alone does not prove the endpoint selection is immutable. Manage the real launch environment and executable through host management; no tamper-proof environment lock was verified. Confirm the real endpoint, trust and environment separately; model-file parsing does not prove secret delivery, router authorization or data residency. Restore the approved prior file through configuration management if deployment fails.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | AC-6, SC-7, IA-5 | Supports configuration and access objectives |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Model schema](https://docs.devin.ai/federal/air-gapped/models-file), [November 3 change](https://docs.devin.ai/federal/changelog) (retrieved 2026-11-05; no live validation).

---

### 3.2 Validate Air-gapped CA and Proxy Policy

**Profile Level:** L2 (Walk)

#### Description

Use OS trust plus the documented `DEVIN_CA_BUNDLE` where private PKI is needed, and govern the machine proxy and no-proxy exceptions.

#### Rationale

**Why This Matters:**
- The custom CA bundle applies to model, OIDC and diagnostic connections, not just inference.
- An invalid bundle can warn and fall back to OS roots at runtime while doctor reports `CFG004`; a warning is not evidence the intended CA loaded.

**Attack Prevented:** Trusting the wrong endpoint or silently losing intended private-CA/proxy configuration.

#### Prerequisites

Approved CA bundle, endpoint/network administrator and access to installed air-gapped diagnostics.

#### ClickOps Implementation

1. No product GUI deploys this machine trust policy. Manage the approved root bundle and protected path through endpoint tooling; set `DEVIN_CA_BUNDLE` for the actual process. Keep TLS verification enabled.
2. Review HTTPS endpoints and exact OIDC endpoint-host exceptions. HTTP is documented only for loopback development endpoints; this guide recommends HTTPS for managed services.
3. Use native system proxy policy and reviewed `no_proxy`; system policy overrides conflicting user configuration by refusing startup. Validate CLI and Desktop process environments independently.

**Automation:** Native CA-file/env and system-proxy policy are documented; the [CLI system policy pack](/guides/devin-cli/#11-pin-device-identity) covers the shared proxy schema, while [Federal 2.2 diagnostics](#22-protect-offline-licenses-and-verified-release-bundles) run first-party doctor. No CA trust-disable key, cloud API or SDK setter is invented.

#### Validation & Testing

On an authorized pilot run airgap doctor and test expected endpoint trust. Treat invalid-bundle warnings, `CFG004` or conflicting proxies as a failed deployment. Do not remove TLS checks to hide the failure.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | SC-8, SC-17, SC-7 | Supports configuration and access objectives |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Air-gapped networking and trust](https://docs.devin.ai/federal/air-gapped/network-and-certificates) (retrieved 2026-11-05; no live validation).

---

## 4. State & Audit Evidence

### 4.1 Protect Token, History and Isolated Desktop State

**Profile Level:** L1 (Crawl)

#### Description

Inventory the actual federal token, conversation and isolated Desktop directories, preserving administrator-controlled host policy and owner-only sensitive user state.

#### Rationale

**Why This Matters:**
- `sso_tokens.toml` and `cli-federal/sessions.db` contain reusable identity and conversation data outside the workspace.
- Air-gapped Desktop isolates state and MCP configuration; its shared config symlink does not mean every cloud/local file is shared.

**Attack Prevented:** Credential/history disclosure through backups, other users or incorrect cleanup.

#### Prerequisites

Known XDG/Windows paths, endpoint retention policy and an incident-hold decision.

#### ClickOps Implementation

1. Resolve `$XDG_DATA_HOME/devin` or `~/.local/share/devin` (Windows `%APPDATA%\devin`); restrict `sso_tokens.toml`, `cli-federal` conversation/audit state and backups to approved owners.
2. Inventory Desktop `~/.devin-airgap-config`, isolated extensions and its separate user-data/language-server folders. Only the documented config link is shared; MCP files are not automatically shared. Existing regular files can override the expected symlink behavior.
3. Use approved retention and reinstall procedures. Do not delete shared folders, active databases or machine auth/models policy to troubleshoot. Review diagnostics before exporting, even though the supported redacted report omits secrets/prompts.

**Automation:** The native runbook documents file layout and protection, but no universal retention writer. Existing host policy/diagnostic packs do not prove filesystem ACLs, backup retention or running-client state. No destructive cleanup script or commercial-state-path substitution is supplied.

#### Validation & Testing

Inspect owner/mode or Windows ACLs and the actual Desktop link/file resolution on a disposable installed profile. Verify local logout removes the token cache while treating upstream IdP tokens and history/backups separately. No real token or database was read in this refresh.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | AU-9, IA-5, SI-12 | Supports configuration and access objectives |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [On-disk formats and isolated Desktop state](https://docs.devin.ai/federal/air-gapped/on-disk-formats) (retrieved 2026-11-05; no live validation).

---

### 4.2 Collect and Interpret Local Structured Audit Events

**Profile Level:** L2 (Walk)

#### Description

Forward the always-on air-gapped JSONL audit stream before its bounded local rotation evicts evidence. Parse schema-version-1 events while retaining unknown fields/event types.

#### Rationale

**Why This Matters:**
- Local rotation is about 110 MiB across active plus ten rotated files, not durable enterprise retention.
- File events describe permission scope, not verified I/O; actor attribution requires joining to session_start.

**Attack Prevented:** Loss of activity evidence and incorrect attribution or claims of completed file access.

#### Prerequisites

Air-gapped build, authorized collector account/root, protected SIEM retention and reviewed user/group/path data handling.

#### ClickOps Implementation

1. Collect the always-on stream at `cli-federal/audit/audit*.jsonl` from every relevant user’s actual state path; preserve owner-only permissions instead of chmodding logs for a collector.
2. Use supported Filebeat/Splunk ingestion and keep unknown fields/events. Schema 1 has `ts`, `pid`, `event`; auth uses `event=auth` with an `action`, not `event=sso_login_denied`.
3. Join tool/file/model events by `session_id` to `session_start` for actor identity. Treat missing session_end as abnormal exit possibility, not certain malicious activity. Keep paths and IdP group names protected.

#### Code Implementation

The Filebeat fragment uses a dedicated `devin` namespace to avoid the ECS `event` type collision, watches rotated files and uses the documented 64-byte fingerprint behavior. Replace paths/output using the real deployment. The Splunk query inventories authentication actions including refusals/revalidation failures; it is a SIEM-resident query, not a collector or retention setter.

{% include pack-code.html vendor="devin-federal" section="4.2" %}

#### Validation & Testing

On an authorized pilot start/end a harmless session and locate matching events in the SIEM, then verify rotation continuity and alert routing. Test parsing with synthetic future event fields. No live audit events or collector were accessed here; ingestion/retention and beta timestamp processing remain deployment validation.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | AU-2, AU-6, AU-9, AU-12 | Supports configuration and access objectives |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Audit schema and supported collection](https://docs.devin.ai/federal/air-gapped/on-disk-formats) (retrieved 2026-11-05; no live validation).

---

## 5. Compliance Quick Reference

Mappings support control objectives; they are not a product benchmark or certification. The bounded November search found no product-specific prescriptive CIS/SCuBA baseline; gated/unpublished coverage is unverified.

| Framework | Objectives | Controls |
|-----------|------------|----------|
| SOC 2 | CC6 access, CC7 monitoring | All controls as mapped individually |
| NIST SP 800-53 Rev. 5 | AC/IA, CM, SC and AU families | See each control’s specific mapping |
| ISO 27001:2022 | Access and secure configuration | A.5.15, A.8.9 objectives |

## Appendix A: Edition and Deployment Compatibility

| Surface | Applicability |
|---------|---------------|
| Federal portal | Cognition-assisted SSO and portal RBAC/service keys; commercial SSO settings do not apply |
| Groups/model/ACU | Eligible multi-tenant deployment and documented read/update permissions |
| Air-gapped beta | Supported macOS/Linux/Windows build; local signed license always required |
| OIDC | Optional layered authentication; no auth file means license-only |
| Native audit | Air-gapped local JSONL only; not a claim of equivalent commercial CLI auditing |
| Portal-downloaded SDK | Authorized download unavailable in this run; wrapper tests cover dispatch, not SDK behavior |

## Appendix B: References and Automation Coverage

The [November source-first inventory](/research/cognition-source-coverage-2026-11/) records product naming, precise configuration evidence, six automation surfaces, read/write differences and retrieval failures. Unverified is not verified absence. The [Code Pack](https://github.com/grcengineering/how-to-harden/tree/main/packs/devin-federal) contains native or documented first-party interfaces only. No GraphQL, fabricated SDK, generic SQL, or guessed enterprise console is supplied. No live evidence or maturity promotion is claimed.

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-05 | 0.1.0 | ai-drafted | Initial source-first 8-control guide with separate identity/deployment boundaries and offline-tested packs; live product verification unavailable. | Codex (GPT-6) |

## Contributing

Report corrections through [GitHub issues](https://github.com/grcengineering/how-to-harden/issues) and the [contribution guide](/contributing/). Share redacted version-specific evidence without tokens, account data or proprietary content.
