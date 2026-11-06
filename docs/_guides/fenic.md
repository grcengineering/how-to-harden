---
layout: guide
title: "Fenic Hardening Guide"
vendor: "Fenic"
slug: "fenic"
platform: "Factory"
platform_slug: "factory"
product: "Fenic"
tier: "2"
category: "AI/ML Platform"
description: "Review Fenic's native LLM-response cache, provider identities and routing, local/cloud execution boundary and MCP tool exposure."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-05"
---

## Overview

Fenic is the Python DataFrame/LLM library linked by [Typedef](https://www.typedef.ai/), whose [acquisition announcement](https://factory.com/news/typedef) connects it to the [Factory platform](/guides/factory/). The [Fenic documentation](https://docs.fenic.ai/) and released [v0.13.0 source](https://github.com/typedef-ai/fenic/tree/v0.13.0) define a distinct, application-local configuration surface. **Factory's Droid organization policy, SSO, keys and managed settings do not configure Fenic.** This guide does not assert that Typedef's hosted service has the same settings or lifecycle.

**Validation status:** no tenants declared — Tier 0+1 only. Source and released SDK class checks support the three controls below. No `Session` was created, model invoked, MCP server started, cloud account configured or data deleted. Maturity remains [ai-drafted](https://github.com/grcengineering/how-to-harden/blob/main/VERSIONS.md#maturity-statuses--the-matrix).

### Intended Audience

- Application owners selecting Fenic cache and model settings
- Security teams approving provider credentials and data destinations
- Operators exposing Fenic catalog tools through MCP

### How to Use This Guide

- **L1 (Crawl):** Review which MCP tools and datasets an agent can reach.
- **L2 (Walk):** Bound retained model responses and approve every provider identity and destination.
- Apply settings to every actual application configuration; no central Factory tenant policy enforces them.

### Scope

Three controls cover native library cache, provider/runner configuration and Fenic's own MCP exposure. Generic DataFrame transformations, application programming, database/host tuning, model quality and cost tuning are excluded. The cache is distinct from DataFrame `.cache()`, catalogs, source files, logs and provider-side retention. The [family ledger](/research/factory-source-coverage/) records unresolved physical deletion/encryption, cloud identity, hosted Typedef administration and MCP authentication contracts.

**Version-sensitive documentation:** the v0.13.0 reference's `enabled=False` cache example is inconsistent with its class fields. The released class ignores that extra field. `SemanticConfig.llm_response_cache=None` is the verified disabled value. OpenRouter examples also show `exclude`, while the released provider class defines `ignore`. Use the actual versioned fields and verify upgrades; a documentation example alone is insufficient evidence of enforcement.

## Table of Contents

1. [Response Cache](#1-response-cache)
2. [Provider and Execution Boundaries](#2-provider-and-execution-boundaries)
3. [MCP Exposure](#3-mcp-exposure)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

## 1. Response Cache

### 1.1 Disable or Bound the Native LLM Response Cache

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | SI-12, CM-6 |

#### Description

Disable Fenic's LLM-response cache for data that must not be reused from a local response store. Where caching is approved, set a reviewed TTL, size and namespace and separately establish the physical storage/deletion contract. Disabling future caching does not prove removal of previous responses.

#### Rationale

**Why This Matters:**

- Model responses can contain sensitive derived data even when source data is stored elsewhere.
- A silently ignored `enabled=False` field can leave an actual cache configuration active.

**Attack Prevented:** Unintended response retention or reuse through an incorrectly configured native cache.

#### Prerequisites

An application owner, the exact deployed Fenic version and its actual `SessionConfig`. Use synthetic data for runtime validation; do not create a session just to inspect a config export.

#### ClickOps Implementation

1. Fenic has no verified hosted UI for these library settings. Review the `SessionConfig` used before `Session.get_or_create`. In v0.13.0, `SemanticConfig.llm_response_cache` defaults to `None`, meaning disabled; constructing `LLMResponseCacheConfig(...)` enables that configuration. The cache object has `backend`, `ttl`, `max_size_mb` and `namespace`, **no `enabled` field**. Do not use `LLMResponseCacheConfig(enabled=False)`.
2. For the disabled policy, merge `semantic.llm_response_cache: null` into the actual strict JSON configuration, or set the Python field to `None`. Preserve unrelated model settings. A candidate file does not change an already running session.
3. If caching is justified, review the native defaults (`LOCAL`, `1h`, 128 MB, namespace `default`) and set a short approved TTL and size. The documented format is digits plus `s`, `m`, `h` or `d`. The source validator does not apply its documented 30-day maximum consistently to seconds/minutes; validate total duration independently. A namespace is a cache grouping mechanism, not an access-control or encryption guarantee.
4. Establish the actual cache path/backend, prior-instance cleanup and physical deletion/backups with the deployed version before promising data removal. No supported public purge method, at-rest encryption setting or complete storage-path contract was verified. TTL/LRU eviction is not proof of secure erasure, and cache-off does not remove catalogs, DataFrame caches, logs or provider data.

Sources: [Session configuration reference](https://docs.fenic.ai/latest/reference/fenic/api/session/config/), [v0.13.0 actual fields and resolution](https://github.com/typedef-ai/fenic/blob/v0.13.0/src/fenic/api/session/config.py), checked 2026-11-05.

#### Code Implementation

The native configuration fragment sets the disabled value. The separate read-only SDK pack inspects an existing `SessionConfig.to_json()` export and reports only cache status, TTL and size. It rejects unrecognized cache keys, malformed exports and invalid duration bounds. Exit 0 means the exported cache is disabled; exit 1 means enabled; exit 2 means unknown. It does not prove deployment or deletion. Python is the verified official SDK language, a necessary exception to the repository's preference for new Bun/TypeScript authoring.

{% include pack-code.html vendor="fenic" section="1.1" %}

#### Validation & Testing

- Compare the actual application configuration and exported cache field after an approved restart. Test cache behavior only with harmless fixtures in an authorized isolated application.
- Verify previous-store cleanup separately. An empty cache status, `null` export or passing pack is not evidence of historical deletion or provider retention.

#### Monitoring & Maintenance

Review versioned class fields after upgrades and retain private configuration/deployment evidence. Never store provider keys, model content or response records in validation reports.

#### Operational Impact

Disabling caching increases repeated inference and provider traffic. Short TTL/size reduces reuse. A configuration export does not update existing application processes.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | SI-12, CM-6 | Supports information-retention and configuration objectives; no product certification claim. |

---

## 2. Provider and Execution Boundaries

### 2.1 Restrict Provider Identities and Data Destinations

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-4, IA-5 |

#### Description

Approve each model/provider identity, endpoint, fallback and execution boundary in the effective Fenic configuration. Supply credentials through the existing runner's secret-injection workflow, and apply downstream provider-account controls independently of Fenic or Factory policy.

#### Rationale

**Why This Matters:**

- Semantic operations send selected data to external model providers even when execution is local.
- Routing profiles, fallback models and optional PDF parsing can introduce additional data recipients.

**Attack Prevented:** Sensitive context routed with an overprivileged identity or sent to an unapproved model, provider or parser.

#### Prerequisites

An approved provider/model inventory, existing credentials and the exact application configuration. Do not generate credentials or enable a provider to run a candidate generator.

#### ClickOps Implementation

1. Review `SessionConfig.semantic.language_models`, `embedding_models`, defaults and every selectable profile. Match provider identities to the approved application and inject the documented environment keys only into its existing runner: examples include `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GOOGLE_API_KEY`, `COHERE_API_KEY` and `OPENROUTER_API_KEY`. Do not commit `.env` contents or embed literal secrets in exported configs. Native credential storage/rotation/encryption enforcement was not established; downstream provider controls remain necessary.
2. Review custom `base_url` fields where supported. Local execution is not local inference. Inspect `SessionConfig.db_path` and optional `cloud` configuration separately: a local database path says where the application catalog resides, not that response cache, logs or providers retain nothing. Cloud execution requires its own supported identity/data contract; no Factory SSO inheritance or private-cloud retention guarantee is implied.
3. For OpenRouter, review each `OpenRouterLanguageModel.Profile`, its `models` fallback list and `provider` routing. Set `provider.only` to approved provider IDs and `data_collection="deny"` where the account requires that routing preference. `order` and price/latency sorting are preferences, not destination allowlists. The released field for provider exclusions is `ignore`; the topic example's `exclude` is rejected. Review every profile and default; restricting one does not constrain another.
4. Remove unneeded fallback models and review `parsing_engine`, including the optional `mistral-ocr` path. The generated fragment sets an empty fallback list for one profile; it does not validate model availability, account policy, provider retention/compliance or all other model aliases. OpenRouter and its routed providers remain separate recipients.
5. Reconcile existing credentials, model access and retained data during offboarding through the relevant provider's supported workflow. Deleting a Fenic config or disabling its cache does not revoke a provider key or purge provider data.

Sources: [Fenic setup and supported providers](https://docs.fenic.ai/), [OpenRouter integration](https://docs.fenic.ai/latest/topics/openrouter/), [actual v0.13.0 provider and SessionConfig classes](https://github.com/typedef-ai/fenic/blob/v0.13.0/src/fenic/api/session/config.py), checked 2026-11-05.

#### Code Implementation

The official SDK generator constructs one OpenRouter model fragment using explicit reviewed model/provider inputs. It sets `only`, `data_collection="deny"`, one default profile and no fallback models. Merge under the reviewed `semantic.language_models` alias and separately select the intended default. It reads no provider keys and creates no `Session` or model-bearing `SemanticConfig`: whole-config model validation can fetch OpenRouter's live model catalog, so the offline pack deliberately avoids that path.

{% include pack-code.html vendor="fenic" section="2.1" %}

#### Validation & Testing

- Review all effective profiles, embedding models, endpoints and fallbacks, then verify actual recipients using synthetic data in an approved application. The generator validates local fields only.
- Confirm provider-side retention and access policy independently. `data_collection="deny"` is a native routing request, not an independently verified deletion, encryption or contractual compliance guarantee.

#### Monitoring & Maintenance

Review provider/model catalogs, SDK changes and credentials after each routing or runner change. Keep destination evidence separate from prompt/response contents and secrets.

#### Operational Impact

Allowlisting providers or removing fallbacks can make a model unavailable. Verify acceptable behavior before rollout; do not automatically widen destinations to recover availability.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-4, IA-5 | Supports approved information flow and credential scope; no provider certification or retention guarantee. |

---

## 3. MCP Exposure

### 3.1 Limit Served Catalog Tools and MCP Reachability

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 Rev. 5 | AC-6, AC-4 |

#### Description

Expose only approved Fenic catalog tools and tables to MCP clients, constrain returned data and verify the actual listener/authentication boundary. Treat this native server separately from the public Fenic documentation MCP endpoint.

#### Rationale

**Why This Matters:**

- The documented CLI default serves registered catalog tools; broad discovery can expose unintended data operations.
- Auto-generated tools include row reads, content search and SQL analysis, not merely schema documentation.

**Attack Prevented:** Agent access to unintended datasets and sensitive row content through an overly broad MCP server.

#### Prerequisites

A reviewed catalog and tool inventory, authorized MCP clients and an isolated test application. No production MCP server is needed for source-only review.

#### ClickOps Implementation

1. Inventory the actual `fenic-serve` invocation or programmatic `create_mcp_server`. The CLI documentation says its default serves registered tools; use explicit approved `--tools` and review `--tables` for auto-generated tools. Programmatic setup should pass selected user tools and explicit `SystemToolConfig.table_names`, rather than blindly exposing every catalog table.
2. Review each tool's query, parameter schema and `result_limit`. For generated tools, set a small reviewed `max_result_rows`/CLI `--sql-max-rows`, but do not treat pagination/row caps as an authorization boundary. The built-in tool set includes Read, Search Content and Analyze/raw SQL; descriptions alone do not restrict sensitive fields or reachable data.
3. Review `--transport`, `--host`, `--port`, `--path` and any ASGI middleware in the deployed service. The CLI source defaults to HTTP on `127.0.0.1:8000`; helper defaults and caller arguments must be checked separately. Prefer stdio or an explicit loopback listener for local-only use. Loopback still admits other local clients and is not identity authentication. A different HTTP path is not an access control.
4. For remote access, obtain and verify the exact supported authentication/authorization and network boundary for the deployed MCP/FastMCP stack before exposing it. The fetched Fenic helper reference does not establish a ready-made Fenic tenant SSO policy, role matrix or caller-scoped catalog ACL. ASGI middleware support is not proof those controls are configured.
5. Do not confuse `https://mcp.fenic.ai` (the project's API/documentation knowledge service) with the application server serving your own catalog. Review each integration independently and remove obsolete tools/listeners through its actual deployment workflow.

Sources: [Fenic MCP topic](https://docs.fenic.ai/latest/topics/fenic-mcp/), [v0.13.0 CLI](https://github.com/typedef-ai/fenic/blob/v0.13.0/src/fenic/scripts/fenic_serve.py), [server helpers](https://github.com/typedef-ai/fenic/blob/v0.13.0/src/fenic/api/mcp/server.py), [system-tool configuration](https://github.com/typedef-ai/fenic/blob/v0.13.0/src/fenic/api/mcp/tools.py), checked 2026-11-05.

**Automation:** native CLI/SDK exposure settings are documented and available, but serving a catalog creates a running application/session and is not a read-only security audit. No safe standalone configuration-inspection API, caller ACL or auth schema was verified. This control stays manual; no server is started and no generic gateway/host configuration is substituted as a Fenic pack.

#### Validation & Testing

- In an authorized synthetic catalog, verify the actual MCP tool list and returned fields as each intended client. Test an excluded tool/table and verify denial, not just absence from a description.
- Inspect actual listener/interface and configured authentication. Do not probe a production or third-party server, or infer private access from the default host string alone.

#### Monitoring & Maintenance

Review catalog/tool growth, FastMCP/Fenic versions and deployment arguments after every change. A new table or tool must not silently expand the approved integration boundary.

#### Operational Impact

Removing tools/tables or changing transport can break client workflows. Preserve an approved inventory and validate intended operations with harmless fixtures before rollout.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-6, AC-4 | Supports least privilege and information-flow review; a row cap alone is not authorization. |

---

## 4. Compliance Quick Reference

| Objective | Controls | NIST SP 800-53 Rev. 5 families |
|-----------|----------|-----------------------------|
| Native retained-response configuration | 1.1 | SI, CM |
| Provider credentials and destinations | 2.1 | AC, IA |
| Exposed tools, datasets and listeners | 3.1 | AC |

These are supporting objectives. Product-specific CIS, DISA, CISA SCuBA, NSA/ACSC baselines and independent product incident coverage were not verified; no verified absence or certification is claimed.

## Appendix A: Automation and Evidence Limits

Three controls, two pack-backed, three packs across native config and the official Python SDK. The read pack proves only the status of a supplied local config export. No actual application, provider, hosted account, cloud identity, deletion path or MCP enforcement boundary was validated. The released SDK was imported in an isolated environment with its missing `tqdm`/`httpx` runtime imports supplied; its class signatures and silent extra-field behavior were checked without creating a session. See the [validation report](/research/factory-refresh-validation/).

| Surface | Evidence status and read/write decision |
|---------|-----------------------------------------|
| Terraform resources/data sources | Vendor-native catalog unverified; no infrastructure substitute. |
| REST/GraphQL | Hosted Typedef/Fenic admin categories/schema unverified. Provider APIs are different services. |
| First-party CLI | Available `fenic` and `fenic-serve` in official package; server CLI native exposure arguments verified from v0.13.0 source. No server-launch pack for source-only verification. |
| Official SDK | Available Python v0.13.0 native config classes; local cache read and provider-fragment generator. No verified TypeScript equivalent, hosted admin SDK or live inference test. |
| Native config/system policy | Available SessionConfig JSON/Python fields. No inherited Factory MDM policy, keystore enforcement, physical purge or central policy distribution established. |
| SIEM/native query | Application catalog/SQL exists; no stable security-audit exporter/event schema or SIEM table verified. Ordinary data SQL is outside scope. |

## Appendix B: References

- [Fenic documentation](https://docs.fenic.ai/) and [released v0.13.0 source](https://github.com/typedef-ai/fenic/tree/v0.13.0)
- [Session configuration](https://docs.fenic.ai/latest/reference/fenic/api/session/config/), [OpenRouter](https://docs.fenic.ai/latest/topics/openrouter/), [MCP](https://docs.fenic.ai/latest/topics/fenic-mcp/)
- [Family source coverage ledger](/research/factory-source-coverage/)

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-05 | 0.1.0 | ai-drafted | Three native library/integration controls; actual released cache/provider fields, Python SDK exception and explicit storage/auth limits; no live validation. | Codex (GPT-6) |

## Contributing

Report corrections through [GitHub issues](https://github.com/grcengineering/how-to-harden/issues), with the exact SDK version, source and validation scope. Follow the [contribution guidelines](/contributing/).
