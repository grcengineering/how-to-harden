---
layout: default
title: "Cognition: Product, Source, and Automation Census"
permalink: /research/cognition-sources/
---

# Cognition: Product, Source, and Automation Census

**Checked:** 2026-10-29. **Scope:** the Devin Cloud/common-controls, Devin CLI, Devin Desktop, and DeepWiki drafts. This is a research ledger, not evidence of a configured tenant. The team fetched vendor documentation bodies, the current OpenAPI, and the official provider source. No authenticated tenant, live client, Terraform plan/apply, or deployment was tested. Recheck interfaces and entitlements before implementation.

## Product and Ownership Decisions

| Surface | Decision and primary evidence |
|---------|-------------------------------|
| Devin Cloud | Cognition's cloud software-engineering agent; the common-controls hub covers its organization and enterprise administration. [Product documentation](https://docs.devin.ai/get-started/devin-intro) |
| Devin CLI | A distinct local-agent hardening surface, not a new cloud tenant. Its harness also underlies Desktop's Devin Local agent. [CLI product page](https://devin.ai/cli), [Devin Local](https://docs.devin.ai/desktop/devin-local) |
| Devin Desktop | Current successor/name of Windsurf, with acquired lineage. The July 2025 announcement alone was a signed agreement; the July 2026 retrospective explicitly describes the closed deal and combined products. Do not call Windsurf originally created by Cognition. [Original announcement](https://cognition.com/blog/windsurf), [one-year retrospective](https://cognition.com/blog/one-year-of-building-together), [Desktop launch](https://cognition.com/blog/introducing-devin-desktop), [current Desktop page](https://devin.ai/desktop) |
| DeepWiki | Cognition-created public repository documentation/Q&A service, with an unauthenticated public MCP endpoint. Private repository documentation belongs to authenticated Devin. A narrow standalone guide is appropriate. [MCP launch](https://cognition.com/blog/deepwiki-mcp-server), [public MCP documentation](https://docs.devin.ai/work-with-devin/deepwiki-mcp), [private documentation](https://docs.devin.ai/work-with-devin/deepwiki) |
| Review, Security/Swarm, Oncall, Automations, Outposts, Ask Devin | Capabilities or deployment surfaces within Devin, not justification for duplicate independent tenant guides. [Current documentation index](https://docs.devin.ai/llms.txt) |
| SWE models, Fusion, Adaptive, FrontierCode | Models, routing/harness capabilities, or a benchmark; no separate product administration guide inferred from a launch name. [Cognition product/research announcements](https://cognition.com/blog) |
| Poke | Predates its maker joining Cognition. Excluded from “products created by Cognition,” rather than silently expanding the task to all acquired consumer products. The announcement says existing Poke use continues. [Welcoming The Interaction Company](https://cognition.com/blog/interaction) |

The Desktop guide is included because it is now a principal Devin surface; its origin is explicitly disclosed. A current product list is not an assertion that each feature has an independent control plane.

## Six Automation Surfaces

### 1. Terraform: Resources and Data Sources Both Checked

The official provider is **`cognitionai/devin`**, not a hypothetical provider. The reviewed release is **v0.5.0**, commit **`a5422c70a64723138990eaccf0bcb8a93f66bf68`**. [Vendor provider guide](https://docs.devin.ai/api-reference/terraform-provider), [immutable provider tree](https://github.com/CognitionAI/terraform-provider-devin/tree/a5422c70a64723138990eaccf0bcb8a93f66bf68/docs).

Reviewed resource names (all prefixed `devin_`): `automation`, `blueprint`, `blueprint_file`, `enterprise_blueprint`, `enterprise_idp_group_role`, `enterprise_knowledge_note`, `enterprise_playbook`, `enterprise_service_user_role`, `git_permission`, `idp_group`, `ip_access_list`, `knowledge_note`, `oncall_responder`, `org_group_limits`, `org_idp_group_role`, `org_service_user_role`, `org_tags`, `org_user_role`, `organization`, `playbook`, `repository_indexing`, `schedule`, and `secret`. The schedule resource is deprecated in favor of automation.

Reviewed data sources (same prefix): `git_connections`, `idp_groups`, `knowledge_folders`, `oncall_schemas`, `organizations`, `repositories`, `roles`, `service_users`, and `users`.

Security-relevant boundaries:

- [`devin_ip_access_list`](https://github.com/CognitionAI/terraform-provider-devin/blob/a5422c70a64723138990eaccf0bcb8a93f66bf68/docs/resources/ip_access_list.md) manages the enterprise singleton. Export and back up the complete current list before management; replacement can lock out operators and destroy clears restrictions. No import operation is documented for this resource. A lifecycle guard is not a recovery channel.
- [`devin_git_permission`](https://github.com/CognitionAI/terraform-provider-devin/blob/a5422c70a64723138990eaccf0bcb8a93f66bf68/docs/resources/git_permission.md) is one grant, not proof that overlapping broad grants have been removed.
- [`devin_repository_indexing`](https://github.com/CognitionAI/terraform-provider-devin/blob/a5422c70a64723138990eaccf0bcb8a93f66bf68/docs/resources/repository_indexing.md) enables indexing; optional `branch_names` adds to the default branch. Creating/adding starts jobs; destroy disables indexing and clears configured branches. The [`devin_repositories` data source](https://github.com/CognitionAI/terraform-provider-devin/blob/a5422c70a64723138990eaccf0bcb8a93f66bf68/docs/data-sources/repositories.md) exposes repository identifiers and indexing enablement, not a full branch-indexing audit.
- Secret resources can put sensitive values in Terraform state. Do not supply blanket credential-provisioning examples.
- This release has no resources for Desktop device policy, CLI local permission files, public DeepWiki administration, SSO connection enforcement, or PAT policy. That scoped gap does not mean Cognition lacks automation.

### 2. REST / GraphQL

Reviewed the [API index](https://docs.devin.ai/_llms/en/api.txt), [API overview](https://docs.devin.ai/api-reference/overview), and [current OpenAPI](https://docs.devin.ai/v3-openapi.json). Use documented **v3** routes rather than copying legacy v1/v2 examples. Security-profile routes are **v3beta1**, even though their human documentation URLs contain `/v3/`. No public GraphQL administration surface was identified in these inventories; no private dashboard endpoints were reverse-engineered.

| Verified read surface | Shape / implementation boundary |
|-----------------------|---------------------------------|
| `GET /v3/self` | Can identify a service-user principal. Prefer dedicated service users for automation over human PATs. |
| `GET /v3/enterprise/roles` and `/roles/{role_id}` | Listing is not the full permission definition; get role details when auditing permission names. |
| `GET /v3/enterprise/members/service-users` | Supports `include_inactive`; preserve role assignments and distinguish inactive principals. |
| `GET /v3/enterprise/ip-access-list` | `ip_ranges` array. Even GET requires **ManageIPWhitelist**, a write-capable permission. |
| `GET /v3beta1/enterprise/security-profiles` and `/security-profile-settings` | List definitions separately from their default binding. Matching enterprise **Manage security profiles** is required by the product's API/governance prose; the raw OpenAPI does not spell this out. Access/entitlement errors are unknown, not compliance. |
| `GET /v3/enterprise/audit-logs` | `items`, `end_cursor`, `has_next_page`; `first` 1–200. Requires **ViewAccountAuditLogs**. UTC Unix-second filters support at most 100 days when bounded. A pack's 31-day cap is a local safety choice, not the vendor limit. |
| `GET /v3/organizations/{org_id}/repositories/indexing` | Cursor-paginated rows include `repository_path`, `indexing_enabled`, `branches`, and nullable indexing status. Use this for private indexing inventory rather than guessing an MCP mutation tool. |

Pagination must finish before a successful evidence verdict. Empty results do not establish that logging/indexing works. Protect identity/audit data, reject redirects and unexpected origins when transporting tokens, and do not log raw response bodies on failure. API examples are not proof of least privilege or live enforcement. [Authentication](https://docs.devin.ai/api-reference/authentication), [pagination](https://docs.devin.ai/api-reference/concepts/pagination), [audit endpoint](https://docs.devin.ai/api-reference/v3/audit-logs/enterprise-audit-logs), [security-profile API/governance](https://docs.devin.ai/product-guides/security-profiles).

Desktop also has a separate **alpha** model-policy API at `https://server.codeium.com/api/v2alpha/models`. [GET List Models](https://docs.devin.ai/desktop/accounts/api-reference/list-models) accepts a `cog_` service-user key with **Use Devin Desktop** and enabled Desktop access; legacy Windsurf keys are rejected. Its `allowed` flags reflect team/org/group restrictions. The response includes stored `allowed_model_uids`, `allowed_model_tags`, and an ETag. [PUT Update Model Allowlist](https://docs.devin.ai/desktop/accounts/api-reference/update-models) replaces both lists and additionally requires **account.windsurf.admin** plus an exact `If-Match` ETag (`*` is not accepted). Do not infer these policies from a selected default model, and do not claim all Desktop administration lacks a write API. Prefer GET-only verification; no model-policy write was performed here.

### 3. First-Party CLI

The real [Devin CLI command reference](https://docs.devin.ai/cli/reference/commands) includes `auth status`, `mcp list/get`, rules/skills/plugins inventory, local-agent execution, and cloud commands. In particular, **`devin cloud drs`** can inspect/create/write blueprints, start builds, and create organization secrets. It is inaccurate to say the CLI has no cloud-management capabilities. Its documented command catalog does not establish writers for SSO enforcement, PAT policy, IP access lists, or enterprise security-profile defaults.

Safe inventory can inspect config and supported list/status commands. Agent prompts are not deterministic administrative verification. `devin connect` approves cloud access to the local computer; `--public` changes the privacy behavior. These are not harmless discovery commands. Outpost worker startup is execution infrastructure, not an enterprise-settings audit. [Local Hands](https://docs.devin.ai/work-with-devin/local-hands), [Outposts](https://docs.devin.ai/cloud/outposts/overview).

### 4. Official SDK

No general cloud-administration SDK was identified in the fetched main/API indexes. Do not invent npm/Python package names from third-party articles. The official **federal** [`windsurf_analytics.py` SDK](https://docs.devin.ai/federal/api/python-sdk) is real, but deployment-specific: portal-downloaded, service-key authenticated, with analytics, groups, and ACU-limit commands. It is not a substitute for the commercial cloud v3 API or a Desktop policy SDK.

### 5. Native Configuration

| Surface | Supported configuration and limits |
|---------|------------------------------------|
| CLI / Devin Local | User and project JSON config, permission rules, separate MCP config, lifecycle hooks, managed `system.json`, and team settings. OS sandbox is a separate control. [Configuration](https://docs.devin.ai/cli/reference/configuration/config-file), [permissions](https://docs.devin.ai/cli/reference/permissions), [system config](https://docs.devin.ai/cli/enterprise/system-config), [MCP configuration](https://docs.devin.ai/cli/extensibility/mcp/configuration) |
| Desktop | Release-shipped GPO/MDM policy templates; Linux `/etc/vscode/policy.json`; `AllowedExtensions` is a JSON-encoded string. `.devinignore` and Cascade `hooks.json` are separate file formats. [Device policy](https://docs.devin.ai/desktop/enterprise-policies), [ignore files](https://docs.devin.ai/desktop/context-awareness/devin-ignore), [Cascade hooks](https://docs.devin.ai/desktop/cascade/hooks) |
| DeepWiki | `.devin/wiki.json` steers documentation content, not repository authorization or a confidentiality filter. Public MCP client config can select the canonical HTTPS endpoint without credentials. [Wiki configuration](https://docs.devin.ai/work-with-devin/deepwiki), [public MCP](https://docs.devin.ai/work-with-devin/deepwiki-mcp) |
| Cloud | Environment blueprints, OIDC setup actions, and security-profile configuration. Do not translate these into local CLI or Outpost firewall guarantees. [Blueprints](https://docs.devin.ai/onboard-devin/environment/blueprints), [OIDC](https://docs.devin.ai/product-guides/oidc), [security profiles](https://docs.devin.ai/product-guides/security-profiles) |

### 6. SIEM / Logging

The commercial-cloud audit API supports downstream export, but no built-in Splunk/Elastic connector or universal SIEM table was established for the controls in these guides. Cascade hooks can emit operator-defined local events; their payloads can contain sensitive context and should not be copied wholesale to logs.

There is an important **out-of-scope exception**: the [federal air-gapped on-disk-format reference](https://docs.devin.ai/federal/air-gapped/on-disk-formats) documents a versioned local audit JSONL schema, rotation, owner-only access, and Splunk/Elastic collection examples. Those files and events must not be attributed to ordinary commercial clients. Its `file_read`/`file_write` events describe permission scope, not proven successful I/O. Do not assert “Cognition has no SIEM integration” without this deployment qualification.

## Tier 1 Control Evidence and Crucial Caveats

| Area | Fetched official source | Implementation caveat |
|------|-------------------------|-----------------------|
| SSO | [SSO onboarding](https://docs.devin.ai/enterprise/security-access/sso/guide) | SSO setup alone leaves default email/GitHub/Google connections enabled. Ask Cognition to disable them and test alternative routes. |
| Lifecycle | [SCIM](https://docs.devin.ai/enterprise/security-access/scim) | Current docs describe actual SCIM provisioning/deprovisioning. Verify JIT is off; token creation's attempt can fail or lack permission. |
| Roles | [Custom roles](https://docs.devin.ai/enterprise/security-access/custom-roles) | One org role per org and one account role per user. Account administration and org assignment rights differ. |
| Credentials | [Authentication](https://docs.devin.ai/api-reference/authentication), [PAT policy](https://docs.devin.ai/api-reference/personal-access-tokens) | Current credentials use `cog_`; PATs inherit human rights. Enterprise policy and lifetime/revocation are separate from service-user creation. |
| Ingress | [IP access lists](https://docs.devin.ai/enterprise/security-access/ip-access-lists) | POST adds; PUT replaces; DELETE or an empty list removes restriction. Preserve an allowed recovery route. |
| Session/build/Outpost boundaries | [Security profiles](https://docs.devin.ai/product-guides/security-profiles), [Outposts reference](https://docs.devin.ai/cloud/outposts/reference) | Mandatory profiles constrain lower selections; running sessions retain their last boot/wake policy. Build defaults replace session defaults and constrain only network. Outpost operators must enforce queued `spec.network_policy`; cloud profiles do not install their firewall. MCP reachability is governed independently from network allowlists. |
| Repository integration | [Enterprise Git integrations](https://docs.devin.ai/enterprise/integrations/git-integrations), [GitHub](https://docs.devin.ai/integrations/gh) | Connecting SCM is distinct from granting repositories to orgs. Narrow source-provider and Devin grants; review overlapping grants. |
| Secrets / federation | [Secrets](https://docs.devin.ai/product-guides/secrets), [OIDC](https://docs.devin.ai/product-guides/oidc) | Org secrets serve all org sessions; personal/repository/session scopes differ. Pin reviewed setup actions and scope relying-party trust. Do not put credentials in prompts, snapshots, code, or logs. |
| Guardrails | [AI Guardrails](https://docs.devin.ai/enterprise/features/ai-guardrails) | `warn_user` and `log_only` do not block. `kill_session` is historical, not configurable. Initial/follow-up messages and PR comments are not every possible injection source. |
| Desktop precedence | [Complete admin controls](https://docs.devin.ai/desktop/controls) | Team Extension policy replaces local/MDM `AllowedExtensions`; marketplace MDM wins over team/user. “MDM always wins” is false. Cascade and Devin Local controls differ. |
| Cascade | [Terminal](https://docs.devin.ai/desktop/terminal), [hooks](https://docs.devin.ai/desktop/cascade/hooks) | Command denylist requests approval, not absolute denial. A pre-hook exit 2 blocks the specific action, but hooks do not run in Restricted Mode and are not an OS sandbox. |
| CLI sandbox | [Sandbox](https://docs.devin.ai/cli/sandbox), [team settings](https://docs.devin.ai/cli/enterprise/team-settings) | Required mode fails closed when unavailable; native Windows is unsupported. Network filtering is explicitly unstable. Excluded commands escape the sandbox; empty domain lists are not deny-all. |
| CLI managed login | [System config](https://docs.devin.ai/cli/enterprise/system-config) | Malformed/unreadable `system.json` fails open; saved credentials are not retroactively revalidated. Deploy before login and verify effective account/host policy. |
| Public versus private MCP | [DeepWiki MCP](https://docs.devin.ai/work-with-devin/deepwiki-mcp), [Devin MCP](https://docs.devin.ai/work-with-devin/devin-mcp) | `https://mcp.deepwiki.com/mcp` is public and credential-free. Authenticated `https://mcp.devin.ai/mcp` also exposes management tools; it is not inherently read-only. Never route private code or tokens to the public endpoint. |
| Indexing | [Repository indexing](https://docs.devin.ai/onboard-devin/index-repo), [DeepWiki](https://docs.devin.ai/work-with-devin/deepwiki) | Additional branches and approved repository inventory need review. Wiki steering is not an ACL. |

### Documentation Conflicts / Version Sensitivities

- CLI [global/project scope reference](https://docs.devin.ai/cli/reference/configuration/global-vs-local) lists a narrower project-key set than the current [plugin governance documentation](https://docs.devin.ai/cli/extensibility/plugins/overview), which explicitly permits project `requiredPlugins`, `optionalPlugins`, and `forbiddenPlugins`. Conservative templates use proven fields; do not claim all other project keys are unsupported.
- Desktop policy prose has a generic product-specific-path statement, but its explicit Linux instructions say the file is shared with VS Code. Use the platform-specific `/etc/vscode/policy.json` instruction and merge existing policy; do not rename it to `/etc/devin/policy.json`.
- API schema does not always include permission prose. Read the product/endpoint page too: enterprise audit needs `ViewAccountAuditLogs`; profile enumeration requires **Manage security profiles** even for a GET-only script.
- Legacy MCP tool/token descriptions coexist with newer tool tables. Discover the actual tool set and scope; do not assert every historical key or tool name behaves identically.
- DeepWiki documents `page_notes` as an optional array without an explicit item schema. The `repo_notes` object schema is explicit; applying that shape to page notes would be an inference, not a verified vendor guarantee. The pack therefore returns unknown for nonempty `page_notes` and requires manual schema review.
- An installed file, mocked response, or valid JSON establishes only that observation. A new-session/runtime test is required before claiming enforcement.

## Plans and Deployment Limits

- [Current self-serve plans](https://docs.devin.ai/admin/billing/self-serve) are Free/Pro/Max/Teams, not the older Core/Team naming. Teams full versus flex seats differ; do not hardcode old pricing or infer enterprise privileges from a paid seat.
- [Enterprise deployment](https://docs.devin.ai/enterprise/deployment/overview) distinguishes multitenant Cloud from dedicated infrastructure. The cloud agent brain remains Cognition-operated; dedicated machines or Outposts do not imply a fully self-hosted platform.
- [Customer-managed keys](https://docs.devin.ai/enterprise/security-access/security/customer-managed-keys) are Enterprise Assured and provisioning-time; obtain the account-specific trust details rather than inventing AWS principals or making an in-place migration claim.
- [Federal air-gapped Desktop/CLI](https://docs.devin.ai/federal/air-gapped/overview) is a separate beta entitlement with offline licensing and customer model endpoints. Its SDK, configuration, and audit formats are not interchangeable with cloud-connected deployments.
- “No training” is not synonymous with zero retention. Contract, optional model-retention settings, and actual feature data flows require review; a trust badge is not an administrator hardening control. [Security information](https://docs.devin.ai/admin/security), [Desktop data-retention controls](https://docs.devin.ai/desktop/controls).

## Tier 2 Benchmark Sweep

Names searched: **Cognition, Devin, Devin Desktop, Windsurf, DeepWiki**. This records the accessible-source outcome on the check date, not proof that no document can exist.

| Source/body | Investigation and result |
|-------------|--------------------------|
| CIS | Fetched the [full benchmark index](https://www.cisecurity.org/cis-benchmarks) and [AI benchmark page](https://www.cisecurity.org/benchmark/ai-benchmarks). No named Cognition/Devin/Windsurf/DeepWiki benchmark was identified. **MCP Server 1.0.0 is listed** as a generic AI benchmark. Its listing does not establish a vendor-specific control ID or justify claiming these packs implement its full content. |
| CISA SCuBA | Fetched official [ScubaGear](https://github.com/cisagov/ScubaGear) and [ScubaGoggles](https://github.com/cisagov/ScubaGoggles) repositories: Microsoft 365 and Google Workspace coverage, respectively; no Cognition product baseline identified. |
| DISA | The official [STIG downloads page](https://www.cyber.mil/stigs/downloads/) returned no inspectable catalog body in this research environment. Search did not identify a named product STIG, but catalog coverage remains **unverified**. Do not claim a definitive absence. |
| NIST / NSA / ACSC | Product-name searches on their official domains did not identify a product-specific preset. General frameworks can support mappings, not invented Devin settings or benchmark IDs. The guides' [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) relationships are implementation mappings, not certifications. |

## Tier 3 / Tier 4 Threat Research

These original reports inform threat rationale only; current control instructions come from Tier 1. No exploit payload or automatic current-vulnerability claim is imported into a pack.

| Source | Relevance and limitation |
|--------|--------------------------|
| Tier 3: Wiz, Maor Dokhanian, 2026-07-08, [GhostApproval](https://www.wiz.io/blog/ghostapproval-a-trust-boundary-gap-in-ai-coding-assistants) | Original trust-boundary/symlink-approval research. Lists a tested Windsurf version and vendor status at publication. Supports careful workspace/symlink and real execution-boundary review; does not prove the current Desktop release is vulnerable or fixed. |
| Tier 4: Johann Rehberger, 2025-08-08, [Devin exposed-port kill chain](https://embracethered.com/blog/posts/2025/devin-ai-kill-chain-exposing-ports/) | Historical prompt-injection/public-port data-exposure demonstration. Supports egress, credentials, and human-approval boundaries; do not assume today's approvals behave like the tested release. |
| Tier 4: Johann Rehberger, 2025-08-21, [Windsurf exfiltration research](https://embracethered.com/blog/posts/2025/windsurf-data-exfiltration-vulnerabilities/) | Original untrusted-content data-exfiltration report with disclosure history. Supports narrowing readable context and external-tool reach. Report dates/status are not a current patch-status assertion. |

Secondary vendor directories, SEO API examples, and search snippets were not used to invent SDKs, command flags, endpoints, or settings. The absence of a discovered writer is recorded as a scoped documentation finding, not an invitation to call a private endpoint.
