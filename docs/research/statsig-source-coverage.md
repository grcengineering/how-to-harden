---
layout: default
title: "Statsig source-first coverage — 2026-11-05"
permalink: /research/statsig-source-coverage/
---

# Statsig source-first coverage — 2026-11-05

Research preceded control selection. The working candidate inventory was opened at `research/statsig-discovery.md` in the task workspace before guide/pack authoring. This durable ledger reconciles its leads against the final 13-control guide; a count of controls or packs is not discovery completeness. All observations below were retrieved on 2026-11-05. Official documentation bodies and implementation sources originate configuration claims. No live tenant, login, key creation, integration connection or setting change was used.

## Product and ownership boundary

The [official documentation index](https://docs.statsig.com/llms.txt) was read in full (96lines): feature gates, dynamic configs, experiments/layers/Autotunes/Parameter Stores, Cloud product analytics/web analytics/replay, Warehouse Native, integrations, SDK/API, CLI and agent skills. Those products share the relevant Statsig project plane; warehouse delegated access and browser capture have separate controls. AI Experimentation is Early Access and not accepting new customers; existing deployments need provider/data review, not an assertion of general availability.

The [2025 OpenAI acquisition announcement](https://openai.com/index/vijaye-raji-to-become-cto-of-applications-with-acquisition-of-statsig/) is conditional. The current [OpenAI Core Experimentation role](https://openai.com/careers/engineering-manager-core-experimentation-seattle/) explicitly describes Statsig's post-acquisition journey. Together these support current OpenAI family placement, not a precise closing date or inherited ChatGPT administration.

## Retrieval and source quality

Official web body reads succeeded. Direct curl of llms.txt and the Console OpenAPI endpoint timed out connecting after8seconds, including an escalated attempt; web retrieval supplied the index and targeted public schema reads. `/introduction`, guessed `/access-management/roles` and a guessed Warehouse quickstart URL were inaccessible; linked canonical project/data-privacy bodies supplied the relevant evidence. These failures are not feature-absence evidence. The112595-line OpenAPI was not locally parsed end-to-end; endpoint/field claims below are bounded to actual targeted reads and pinned source. No screenshots or search snippets alone originate a setting. Ownership search evidence was read in the actual official role body.

Bounded secondary-baseline discovery used “Statsig hardening CIS benchmark”, “Statsig DISA STIG security configuration” and “Statsig security hardening guide OIDC project keys”, plus the current [CIS catalog](https://www.cisecurity.org/cis-benchmarks). No qualifying Statsig-specific prescriptive baseline was obtained. That is a search result, not universal absence. Vendor security/compliance pages describe provider practices; they do not prove customer-configurable switches. Framework labels in this guide map intent, not a product benchmark. In particular, no configurable customer disk cipher, forced keychain mode or session timeout was invented from assurance prose.

## Candidate reconciliation

| Lead | Configuration source and observed boundary | Disposition |
|------|--------------------------------------------|-------------|
| S01 OIDC/Strict SSO/Owner recovery | [SSO](https://docs.statsig.com/access-management/sso/overview): Enterprise organization connection, project enforcement and Owner exemption | Covered1.1; IdP MFA is upstream, not a Statsig local MFA toggle |
| S02 Visibility, roles, invites | [Organizations](https://docs.statsig.com/access-management/organizations), [Projects](https://docs.statsig.com/access-management/projects): moved projects OPEN; granular create/edit/delete behavior | Covered1.2; ordinary role API can reset per-type creation permissions |
| S03 SCIM groups/offboarding | [Overview](https://docs.statsig.com/access-management/scim/overview), [concepts](https://docs.statsig.com/access-management/scim/concepts): aliases need re-add/full sync; unassignment deactivates/wipes roles | Covered1.3; no generic project-delete endpoint claimed |
| S04 Key identity and authority | [Keys](https://docs.statsig.com/access-management/api-keys): client/server/Console/personal distinctions, shared key Admin authority | Covered2.1; collector limited to caller-visible metadata |
| S05 Environment/Target Apps/bootstrap | [Target Apps](https://docs.statsig.com/sdks/target-apps): Enterprise, dependencies not inherited, server union/client filtering | Covered2.1, with evaluation availability impact |
| S06 Client definition exposure | Key documentation's optional config-spec download scope | Covered2.1; public client key does not mean every granted payload is harmless |
| S07 Review bypass/environment | [Reviews](https://docs.statsig.com/guides/setting-up-reviews), [workflow](https://docs.statsig.com/guides/fomo): production default, other environments/bypass separate | Covered3.1; settings flags do not prove effective independence |
| S08 MCP confirmation vs review | [Tool reference](https://docs.statsig.com/integrations/mcp/tool-reference): discovered operations, confirmation varying by tool, approve vs commit | Covered4.2; no machine confirmation promoted to human approval |
| S09 Dependency history | [History](https://docs.statsig.com/guides/config-history): nested gate/segment changes omitted | Covered3.3 and5.1 |
| S10 Audit/export | History describes console/indefinite retention; MCP documents get_audit_logs | Covered5.1; exact complete REST/export contract unverified, no guessed API/Sigma |
| S11 Public/project MCP and EMA | [Overview](https://docs.statsig.com/integrations/mcp/overview), [EMA](https://docs.statsig.com/integrations/mcp/enterprise-managed-auth), [client](https://docs.statsig.com/integrations/mcp/claude-code): user membership, exact issuer, project Tenant ID, read-only scopes | Covered4.2; no account enrollment performed |
| S12 Siggy credential/config plane | [CLI introduction](https://docs.statsig.com/statsigcli/introduction), [commands](https://docs.statsig.com/statsigcli/commands): official @statsig/siggy, version/read/write/config commands | Covered3.3 version-only; no credential-config dump or unverified settings-output parser |
| S13 IaC full census/lifecycle | Pinned provider2.2.1 docs and internal provider/resource source | Covered1.2/3.1/3.3; no import invented, defaults no resources |
| S14 SDK local data/cache/fallback | [Current JS SDK](https://docs.statsig.com/client/javascript-sdk): localStorage evaluations/queued events, stable ID, disableStorage/logging options; released EventLogger buffers disabled events and replays on enable | Covered2.2; logging/storage disabled is not a consent barrier. Old cached data, all SDKs/custom adapters and app fallback require deployment review |
| S15 Replay | [Privacy](https://docs.statsig.com/session-replay/privacy), [configuration](https://docs.statsig.com/session-replay/configure): Passwords default, selectors/console overrides, sampling/conditional/forced/retention | Covered4.1/5.2; no browser recording initialized |
| S16 Autocapture | [Overview](https://docs.statsig.com/webanalytics/overview), actual installed3.33.7 options/plugin/metadata builder | Covered4.1. Prose suggests copied-text capture but released captureCopyText defaults false. Peer review caught an initial nonnative pageUrl fixture; native fields are page_url/current_url, both query-overwritable. Corrected to independent actual browser location plus matching native fields; actual released metadata-helper regressions cover query spoofing. Console/copy capture remain false, default deny |
| S17 Warehouse trust/egress | [Data privacy](https://docs.statsig.com/statsig-warehouse-native/analysis-tools/data-privacy): source read/job, isolated staging write/delete, samples and aggregate egress | Covered4.3/5.2; generic database/host encryption excluded, exact warehouse editor unverified |
| S18 Ingestion/export integration plane | Warehouse privacy source and linked integration index | Native delegated data and external copies covered4.3/5.2; no unsupported connector schemas or full warehouse catalog completeness claim |
| S19 Pre-commit webhook | [Contract](https://docs.statsig.com/guides/pre-commit-webhooks): authenticated delivery, independent creation enablement, callback and commit distinctions, UI recovery | Covered3.2; receiver/deployment/key generation excluded from this update |
| S20 Slack audiences | [Slack](https://docs.statsig.com/integrations/slack): project connection+filters, separate personal notifications | Covered4.3; no Slack message sent or connection made |
| S21 Agent/automation source trust | [Agent skills](https://docs.statsig.com/integrations/agent-skills), CLI/provider source | Covered3.3/4.2; no global skill install or automatic write authorization |
| S22 Deletion/retention | [Enterprise deletion](https://docs.statsig.com/compliance/user_data_deletion_requests): user_id only, SERVER key, uncancellable/batched, POST status read | Covered5.2; status-only pack, never deletion submission |
| S23 Ownership/control inheritance | Current official role+conditional announcement above | Separate product guide; no Statsig setting attributed to ChatGPT |
| S24 Lifecycle | Current index's AI Experimentation admission restriction; current v3 MCP/JS SDK and pinned provider | Scope and explicit version boundaries; not an absence finding |
| S25 AI instrumentation | [OpenAI integration](https://docs.statsig.com/integrations/openai) includes historical provider code and telemetry examples | Covered4.3 data boundary; deprecated credential/model snippets not copied, actual prompt capture requires app review |
| S26 Granular role API drift | Current Projects body: shared keys Admin; per-type creation not API-manageable and reset on role updates | Covered1.2; role-writing TF/API packs deliberately excluded |
| S27 GitHub AI repository ingestion | [GitHub AI](https://docs.statsig.com/integrations/github-ai-integration): Early Access App, selected repositories/shared org installation, temporary code processing/knowledge graph, cleanup PRs | Covered4.3; no repository connected or PR-generating integration enabled |

## Six-surface pack census

| Surface | Evidence obtained | Result and limitation |
|---------|-------------------|-----------------------|
| Terraform resources and data sources | [v2.2.1](https://github.com/statsig-io/terraform-provider-statsig/tree/v2.2.1): all docs/resource filenames and provider.go read |17resources: dynamic_config, entity_property, environments, experiment, gate, keys, metric, metric_source, qualifying_event, role, segment, settings_project, settings_reviews, settings_roles, settings_teams, tag, unit_id_type. DataSources returns empty at this tag, verified absence for this version. Two relevant settings used; flat role writes unsafe for granular roles |
| REST/GraphQL | [Console introduction](https://docs.statsig.com/console-api/introduction), linked [20240601 OpenAPI](https://api.statsig.com/openapi/20240601.json), [keys list](https://docs.statsig.com/api-reference/keys/list-keys), deletion docs, provider source | GET project/review settings and paginated keys verified; deletion status POST verified. REST key header/version and pagination validated. GraphQL administration not established; unverified rather than absent. Full schema not locally parsed |
| CLI/companion | Official Siggy introduction/commands | Native version read supplied. Config may reveal secrets; credential-storage enforcement and output schema not established, no companion daemon invented |
| SDK | Current JS3.33.7 docs, actual package+locked dependencies, private-attribute docs | Native user parameter and actual AutoCapture plugin factory. No SDK initialization; serverSDK/custom adapters require perdeployment review |
| Native configuration | Console SSO/roles/reviews/capture, native SDK options, provider settings; no generic JSONC policy | Supported parameters represented without pretending one project policy enforces all planes. No console/daemon encryption setting inferred from vendor disk assurance |
| SIEM | Audit console/history and MCP log-read capability | Complete event field/export schema unverified; no sample Sigma promoted into a detection |

Nine numbered packs cover seven controls through five types. This is an automation coverage result; six manual/unverified-interface controls remain valid guide content. No unsupported/unavailable capability was mislabeled as verified absence. The only explicit version-scoped absence established here is the provider's empty DataSources implementation.
