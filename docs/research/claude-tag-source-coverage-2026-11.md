---
layout: default
title: "Claude Tag source coverage — November 2026"
---

# Claude Tag source-first coverage ledger

Checked 2026-11-11. Scope: commercial Claude Tag Team/Enterprise public beta. Source verification and mocked execution only; no live tenant, secret creation or configuration changes. Read the tracked HTH authoring and source-discovery skills. This is a bounded public-document review, not proof that all unpublished features or tenant-specific Security Center checks are covered.

## Discovery and provenance

The official [documentation index](https://claude.com/docs/llms.txt) enumerated 78 Claude Tag pages. We inventoried those links and retrieved/read the relevant admin, conceptual and user-operation pages, including all current federation references (46 Markdown pages retrieved for this review). Per-service connector recipes and use-case examples remain discovery leads, not claims of individually tested integrations. The product exists under its published name; it is not a presumed typo for Claude Code. Current detailed docs take precedence over older launch/blog roadmap language: federated agent access is now documented, not merely future intent.

## Trust Center search and applicability

The vendor links to [Anthropic Trust Center](https://trust.anthropic.com). Its known public [JSON catalog](https://trust.anthropic.com/json), resource page and previously evidenced C4G PDF were attempted using web retrieval and direct HTTP clients. Current retrieval failed (inaccessible web response / TLS connection failure; a separate direct curl attempt timed out after 20 seconds). Therefore **current category enumeration, pagination and updated PDF bodies were not verified**. No assertion that a Tag-specific guide is absent, or that this run exhausted the catalog, is warranted.

Prior repository evidence in the [Anthropic November ledger](/research/anthropic-source-coverage-2026-11) identified:

| Candidate | Prior identity | Current disposition |
|-----------|----------------|---------------------|
| Unified Claude/Cowork Security Best Practices | v1.3, 2026-09-17 | Previously reviewed adjacent/common baseline; fresh body unavailable. Current Tag-specific controls supersede assumptions that its retention/network policy simply follows chat/Cowork. |
| Claude for Government FedRAMP Secure Configuration Guide | v2.1, 2026-07-16; [resource](https://trust.anthropic.com/resources?s=et14tktjw9g4cze3kc2ef&name=claude-for-government-(c-4-g)-fed-ramp-secure-configuration-guide) | Discovered prior verified government edition; fresh retrieval failed. Commercial Tag applicability not established. No government endpoints, headers, role defaults or authorization claims transplanted. |
| Claude Code FISMA guide | v1, January 2026 | Adjacent client/runtime edition, not proof of Tag compliance or a Tag-specific checklist. |
| Enterprise 20x certification package | Prior catalog entry | Assurance overview is not a customer configuration baseline or proof that commercial Tag is authorized. |

Follow-up gap: re-open the public catalog when reachable and reconcile any newly published Tag secure-configuration document. No account, NDA, purchase or access request was initiated. Current [Tag healthcare](https://claude.com/docs/claude-tag/admins/healthcare) and [data lifecycle](https://claude.com/docs/claude-tag/concepts/data-lifecycle) documents directly establish important boundaries instead of assuming transfer from those adjacent editions.

## Candidate disposition independent of pack availability

| Source candidate and exact source | Disposition in guide |
|----------------------------------|----------------------|
| [Scope inheritance and channel-name rules](https://claude.com/docs/claude-tag/admins/attach-to-scope) | 1.1, 1.3, 2.1: union, explicit-target incompleteness, root/workspace/channel and name-rule review |
| [Invocation, roles, guests, search, DMs and shutdown](https://claude.com/docs/claude-tag/admins/restrict-access) | 1.2, 3.1, 3.2: built-in role grants, toggle gate, explicit channel disabling, DMs, search overrides, restricted guests, channel-only exceptions and Enterprise Grid root-only/shared-channel cases |
| [Service accounts and connector creation](https://claude.com/docs/claude-tag/admins/add-connections) | 2.1–2.2: dedicated accounts, first-credential all-Slack default, scoped creation, destination/path/method restrictions |
| [Agent identity](https://claude.com/docs/claude-tag/concepts/agent-identity) | Overview, 2.3: agent identity versus human identity, separate permission and invocation planes |
| [Security and data handling](https://claude.com/docs/claude-tag/concepts/security-and-data) | 2.2, 4.1, 5.1: proxies, independent egress union, GitHub exception, artifact audience and compliance exclusions |
| [Network requirements](https://claude.com/docs/claude-tag/admins/network-requirements) | 2.2: shared egress IP is not tenant identity; publicly reachable authenticated HTTP(S) endpoints. Private network connectivity not promised. |
| [Personal connectors](https://claude.com/docs/claude-tag/concepts/personal-connectors) | 3.2: Enterprise mandatory review, Team control gap, underlying connector controls, Opus 5 dependency, no recipient ACL guarantee |
| [Federated access overview](https://claude.com/docs/claude-tag/admins/federated-access/overview), [token reference](https://claude.com/docs/claude-tag/admins/federated-access/token-reference) | 2.3: four connection types, hosted-channel restriction, exact subject authorization and rotating keys; not user/device delegation |
| [Gateway](https://claude.com/docs/claude-tag/admins/federated-access/connect-a-gateway), [AWS](https://claude.com/docs/claude-tag/admins/federated-access/aws), [GCP](https://claude.com/docs/claude-tag/admins/federated-access/gcp), [authorization server](https://claude.com/docs/claude-tag/admins/federated-access/authorization-server), [limits](https://claude.com/docs/claude-tag/admins/federated-access/limits) | 2.3–2.4: control subject isolation, cross-tenant negative tests, IAM plus subject/audience, GCP minting guard, token residual lifetime. No unvalidated gateway/cloud provisioning code shipped. |
| [GitHub access](https://claude.com/docs/claude-tag/admins/configure-github) | 4.1: GitHub App installation plus channel repository grants; branch/CI protection. Fixed Actions authority includes workflow dispatch/enable/disable and log/artifact deletion; held deployment approval and repository_dispatch are prohibited. Two reviews plus stale-review dismissal prevent requester-only approval of bot-authored PRs. |
| [Customization](https://claude.com/docs/claude-tag/admins/customize), [skills repo](https://claude.com/docs/claude-tag/admins/skills-repo) | 4.2: supply-chain review, scoped allow-rule bypass, Sonnet 5 checker, Enterprise model-access gate versus unreliable managed-allowlist enforcement in channel sessions, fresh-thread tests |
| [Routines](https://claude.com/docs/claude-tag/users/proactivity), [automatic replies](https://claude.com/docs/claude-tag/users/when-claude-responds) | 4.2, 5.2: schedules/creators, pause, automatic response limits, channel rather than personal identity |
| [Memory](https://claude.com/docs/claude-tag/users/memory), [data lifecycle](https://claude.com/docs/claude-tag/concepts/data-lifecycle), [healthcare](https://claude.com/docs/claude-tag/admins/healthcare) | 5.1: shared context, artifact audience, no beta automatic transcript/memory expiry, deletion distinctions, no Tag BAA |
| [Audit](https://claude.com/docs/claude-tag/admins/audit), [spend limits](https://claude.com/docs/claude-tag/admins/set-spend-limit) | 5.2: incomplete network events, independent service logs and Enterprise transcripts, billing-boundary review |
| Per-service setup recipes and use-case library in the official index | Outside a claim of connector-by-connector benchmark completeness. Generic service identity, least privilege and tested grants apply; target-service permissions require the relevant service guide. |
| Older product launch posts / identity-roadmap articles | Discovery/context only where superseded by current technical references; no invented future controls represented as available. |

## Six-surface automation census

Primary authority: [Claude Tag API](https://platform.claude.com/docs/en/manage-claude/claude-tag-api). The API is Enterprise-only even though the Tag product also supports Team. Management uses a scoped **claude.ai organization key**, not a Console key. API beta/version headers and read/write scopes are encoded in the API packs. Missing scope or entitlement is not an empty account.

| Surface | Evidence / outcome | Pack or boundary |
|---------|--------------------|------------------|
| Terraform | No Tag resource verified in the reviewed official references; this is unverified, not a universal absence claim | Do not invent provider resources; cloud IAM relies on provider-specific validated code outside this release |
| REST / GraphQL | Official 14-endpoint Tag Admin API verified, including pagination and inherited reads; no Tag GraphQL management surface verified | 1.01 audit; 1.02 exact existing-channel containment. Bundle contents/default access/rule-derived access remain console evidence. |
| CLI | Exact `ant` retrieval, inherited-read and safe key/stdin flags verified in official Tag/CLI Markdown; local executable unavailable | 1.01 read-only exact-channel effective settings; fixture-tested, native execution remains a verification gap |
| SDK | Official Python `client.beta.organization.claude_tag` bundle/target iterators documented | 1.03 read-only paginated target inventory; current compatible SDK required |
| Config / system policy | Scope environment, setup scripts, plugins, skills and host runtime policy are distinct from Tag Admin API | 4.1–4.2 and linked Code guide; no false claim a local config file governs hosted Slack scopes |
| SIEM / audit | Activity network export best-effort, excludes git/MCP and may miss other requests; Enterprise Compliance API and upstream logs complement it | 5.2. No invented universal event names or Sigma fields; validate actual tenant event schemas first |

## Pack safety and validation boundary

- API audit traverses pages, including empty pages with a continuation; no partial success after a pagination failure. Grid IDs must be supplied because listing does not discover them.
- Inventory minimizes output (no bundle instructions/descriptions/secrets), but IDs and snapshots still require restricted handling.
- Containment is preview-only unless exact channel identifiers and explicit apply confirmation are supplied. It changes only `enabled` and `guest_policy`, verifies stored/effective read-back and saves private snapshots. Other channels, DMs and upstream tokens are unchanged.
- The API is last-write-wins without conditional writes. Pause concurrent administrators; read-back detects but cannot eliminate all races. No automatic retry or rollback after an uncertain write. Asynchronous session termination is not proven by settings read-back.
- No pack provisions credentials, grants a new bundle, deletes data or performs a business action.
- Offline tests validate transport, pagination, schema handling, plan/apply guards and SDK fixture behavior, not real product state. All packs and guides remain unvalidated against a tenant.
