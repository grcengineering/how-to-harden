# Factory source and automation evidence

Research window: 2026-10-30–2026-10-31 UTC. Author: Codex (GPT-6). Subject: standalone `Factory → Factory/Droid` guide and its code packs. No tenants declared — Tier 0+1 only. No credential source or live Factory/OCEAN configuration was declared. No live policy, IdP, API, SDK or sandbox validation is asserted.

## Placement and source selection

Factory's [individual terms](https://factory.com/legal/terms-individual) identify The San Francisco AI Factory, Inc. as the provider. The current [news index](https://factory.com/news) and a scoped 2025–2026 acquisition/ownership search did not identify a change of control of Factory itself. Marketplace announcements do not establish an ownership change. No other Factory guide/platform was present in the verified base `761bd5165d8323d61efba7e8392c35b0d2d74d15`, so the guide is standalone. This is source-based placement, not a legal ownership opinion.

The admission standard is [SOURCES.md](../../SOURCES.md). Factory's marketing security page and Trust Center were inspected for discovery but are not used to originate configuration controls or as `hardening_docs` links.

## Fetched Tier 1 documentation

Each URL below returned identifiable documentation content through the research browser during this run, not merely an HTTP 200 shell. The older `docs.factory.ai` and several `/docs/` links redirect to the canonical `docs.factory.com` URLs cited here. Some direct fetches initially failed; successful subsequent canonical/page-link fetches supplied the content. Mac curl separately timed out connecting to the documentation host; this did not prevent browser-side source verification.

| Area | Verified primary source | Evidence used |
|------|-------------------------|---------------|
| Product and API entry points | [Docs](https://docs.factory.com/), [API](https://docs.factory.com/api-reference) | Product surfaces, bearer authentication, public origin `https://api.factory.ai`, API groups. |
| Identity | [Identity & Access](https://docs.factory.com/enterprise/identity-and-access) | Domain prerequisite, assisted WorkOS SSO/SCIM, role mapping, soft deactivation, service-account ownership and SCM non-inheritance. |
| Organization and access | [Organization Model](https://docs.factory.com/enterprise/organization-model), [Admin Console](https://docs.factory.com/enterprise/enterprise-admin-console) | Root identity boundary, per-org controls, Directory and Security & Identity navigation, local versus root roles. |
| Managed policy | [Enterprise Controls](https://docs.factory.com/enterprise/hierarchical-settings-and-org-control) | Full field census, hard controls/defaults, merge semantics, protected system paths, invalid-file empty-policy behavior, network/sync/retention, model, image, plugin, computer and key-administration fields. |
| Runtime safety | [Agent Safety](https://docs.factory.com/enterprise/llm-safety-and-agent-controls) | Layered enforcement and authenticated source-IP scope. |
| Commands | [Permission Rules](https://docs.factory.com/autonomy-and-safety/permission-rules) | Ordered exact prefixes, mandatory examples, rollout requirement, block/ask/allow precedence, legacy coexistence and invalid-local-rule skipping. |
| Sandbox | [Sandbox](https://docs.factory.com/autonomy-and-safety/sandbox) | Whole-process versus per-command, supported host primitives, default read/write/network behavior, always-permitted Factory/WorkOS domains. |
| Secret scanning | [Droid Shield](https://docs.factory.com/autonomy-and-safety/droid-shield) | Droid-mediated Git coverage, scan behavior and private-preview status of Shield 2.0. |
| Managed connectors | [Connectors](https://docs.factory.com/harness/connectors) | Per-organization availability, server-side enforcement, saved-credential persistence and separate downstream grants; no documented public writer inferred. |
| MCP | [MCP](https://docs.factory.com/harness/mcp) | Enforcement default, empty-list deny-all, hostname-only remote matching, stdio normalization, tool filters, persistent approvals and secret handling. |
| Plugins | [Internal Marketplaces](https://docs.factory.com/enterprise/internal-plugin-marketplaces) | Strict plugin and source governance; pinning and deployment caveats. |
| Hooks | [Hooks](https://docs.factory.com/harness/hooks) | Managed loading, plugin exception, global disablement, PreToolUse exit-2 denial, ordinary nonzero errors and PostToolUse timing. |
| First-party CLI | [CLI Reference](https://docs.factory.com/droid-cli/cli-reference) | `rules check`, its standalone file contract and independent exit status; MCP and plugin inspection. Current tool-selection flags are `--only-tools`, `--add-tools`, `--remove-tools`; no legacy/invented flag is used. |
| Local settings conflict | [CLI Settings](https://docs.factory.com/droid-cli/settings) | Secondary schema description differs on source-IP versus outbound semantics; see conflict record below. |
| Python SDK | [Python SDK](https://docs.factory.com/sdk/python) | Official `droid-sdk` / `droid_sdk`, Python 3.10+, `list_models(include_disabled=True, cwd=...)`, model `id`/`disabled`, one-shot discovery without a session/model call. |
| Organization API | [Organization API](https://docs.factory.com/api-reference/organization) | Paginated user and revision reads; documented `limit`, `cursor`, `pagination.hasMore`, `pagination.nextCursor` shapes. User listings do not establish roles/SCIM ownership. |
| Service-account API | [Service Accounts](https://docs.factory.com/api-reference/service-accounts) | All-account and per-account key listings, non-paginated documented responses, human Manager+ administration, key timestamp units, destructive operations excluded. |
| Telemetry | [Telemetry](https://docs.factory.com/enterprise/telemetry), [Privacy](https://docs.factory.com/enterprise/telemetry/privacy) | Org-only sink settings, member-readable configuration, literal environment references, startup/missing-credential behavior, aggregate/GenAI semantics and raw-content risks. |
| Audit | [Audit Log](https://docs.factory.com/enterprise/audit-log) | Enterprise Owner access under Team Settings, organization event categories; no exact general export route or stable event schema inferred. |
| Deployment/data | [Data Flows](https://docs.factory.com/enterprise/privacy-and-data-flows), [Compliance](https://docs.factory.com/enterprise/compliance-audit-and-monitoring) | Hosted control plane remains the Private default; inference/storage are separate; compliance restrictions require written Factory requests. |

## Benchmark and incident sweep

| Source class | Search and result |
|--------------|-------------------|
| CIS | Scoped `site:cisecurity.org "Factory" "Droid"` and product benchmark searches found no applicable Factory/Droid benchmark. Android device results are unrelated and excluded. The CIS Controls family mapping is not a product benchmark claim. |
| CISA SCuBA | Scoped cisagov/SCuBA product searches did not identify Factory coverage. No SCuBA IDs are assigned. |
| DISA STIG | No applicable product artifact identified; public index coverage could not be verified. Recorded as unverified, not proof of absence. |
| NIST / NSA / ACSC | No Factory-specific configuration baseline identified in scoped official-domain searches. [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) supplies framework objectives, not configuration steps. |
| Tier 3/4 | Searched Factory/Droid with vulnerability, prompt-injection and incident terms, including standing-list research domains. No product-specific incident source meeting the admission standard was used. Generic agent evaluations and scorecards were excluded; no Factory breach or CVE was invented. |

## Automation census

Status below describes the fetched interface, not a live execution result. All implemented handles are documented as available; permission rules require activation/version support. Deprecated command lists are mentioned only for migration and are not authored. Private-preview Shield 2.0 is not enabled by any pack.

| Surface | Write decision | Read/verification decision | Status/evidence |
|---------|----------------|----------------------------|-----------------|
| Terraform resources/data sources | No pack. No official Factory/Droid provider or resource/data-source catalog identified in official docs and scoped registry search. | None identified. | Research limit, not a claim that no third-party provider could exist. |
| REST / GraphQL | Public REST user, limit and service-account writes exist; none is a documented managed-policy/SSO/SCM-association writer. Setup/secret issuance remains in the approved console workflow. No managed-settings PATCH or GraphQL operation invented. | Implemented the three reads below. No general audit export route inferred from prose. | [API index](https://docs.factory.com/api-reference), [Organization](https://docs.factory.com/api-reference/organization), [Service Accounts](https://docs.factory.com/api-reference/service-accounts). No public GraphQL contract identified. |
| First-party CLI | No live mutation pack. Org settings are enforced through the supported managed-policy surface, not an invented `droid admin` command. | Rules checker, MCP/server approvals, plugin inventory, available tools and visible computers. | [CLI](https://docs.factory.com/droid-cli/cli-reference), [MCP](https://docs.factory.com/harness/mcp); added to CLI inventory. |
| Official SDK | Session execution exists but is unnecessary for these controls; no model execution supplied. No org-policy admin method identified. | Official Python model discovery, compared to reviewed IDs. | [SDK](https://docs.factory.com/sdk/python). |
| Native config | Eleven org-settings fragments plus three stdout-only generators. No automatic installation. | Candidate rules preview and model-catalog checks provide limited independent verification; schema/effective-device proof remains live work. | [Managed schema](https://docs.factory.com/enterprise/hierarchical-settings-and-org-control). |
| SIEM | No product setting through a SIEM. | OTLP telemetry can be ingested. No query or rule without a verified target ingestion/event schema. | [Telemetry](https://docs.factory.com/enterprise/telemetry), [Audit](https://docs.factory.com/enterprise/audit-log). |

The implemented REST handles are exactly:

- `GET /api/v0/organization/users?limit=100[&cursor=...]` → `users` plus `pagination`.
- `GET /api/v0/service-accounts` → `serviceAccounts` (all records; no invented pagination).
- `GET /api/v0/service-accounts/{encodedId}/api-keys` → `apiKeys` (all active/inactive metadata).
- `GET /api/v0/organization/enterprise-controls/history?limit=100[&cursor=...]` → `changes` plus `pagination`.

The CLI checker accepts only `{version,rules}` or an array with `--file`. It returns exit 0 for a successful preview even when the decision is Block. Packs collect reports without assuming an undocumented report-field schema or presenting checker exit 0 as enforcement proof.

### Per-control surface matrix

An em dash means no applicable supported implementation is claimed for that control after the census above. Config means an **org-level** fragment, not an ordinary project setting. REST 1.2 is membership inventory, not role/provisioning proof; REST 5.2 is settings history, not complete audit export.

| Control | Terraform | REST | CLI | SDK | Config | SIEM |
|---------|-----------|------|-----|-----|--------|------|
| 1.1 | — | — | — | — | — | — |
| 1.2 | — | GET users | — | — | — | — |
| 1.3 | — | GET service accounts/keys | — | — | org settings | — |
| 2.1 | — | — | — | — | org settings | — |
| 2.2 | — | — | rules check | — | org settings | — |
| 2.3 | — | — | — | — | org settings | — |
| 2.4 | — | — | — | — | org settings | — |
| 2.5 | — | — | tool catalog | — | org-only network tools | — |
| 3.1 | — | — | MCP/approval inventory | — | org settings | — |
| 3.2 | — | — | plugin list | — | org settings | — |
| 3.3 | — | — | — | — | org settings | — |
| 3.4 | — | — | — | — | — | — |
| 3.5 | — | — | — | — | — | — |
| 4.1 | — | — | — | — | org settings | — |
| 4.2 | — | — | — | list_models | org settings | — |
| 4.3 | — | — | — | — | org settings | — |
| 4.4 | — | — | visible computers | — | org settings | — |
| 5.1 | — | — | — | — | org settings | — |
| 5.2 | — | GET revision history | — | — | — | — |

Coverage: **16/19 controls**, **23 source packs**, **four implemented surface types**. Controls 1.1, 3.4 and 3.5 carry explicit evidenced automation verdicts. Helpers have no guide excerpts and are not counted as packs. Every represented (section,type) is unique.

## Conflicts and limits retained in the guide

1. **Source IP versus egress:** CLI Settings describes `networkPolicy.allowedIps` as outbound restriction. The dedicated Enterprise Controls and Agent Safety docs instead define allowed source IPv4/CIDRs for authenticated Factory web/CLI/API requests. The guide explicitly reports this contradiction and uses the dedicated admin definition; command egress uses `sandbox.network.allowedDomains`.
2. **Defaults versus hard controls:** `sessionDefaultSettings` is locally overridable. `maxAutonomyLevel`, model access and other documented hard-control fields provide ceilings. No default is described as immutable enforcement.
3. **Malformed system policy:** present malformed/schema-invalid system-managed JSON yields empty org policy. A missing/unreadable file falls back to remote org settings. Offline JSON syntax tests do not discharge live schema validation.
4. **Rules:** native-rule activation is independent of checking. Ordered token prefixes have known path/order gaps; block > ask > allow after ID resolution. Invalid local definitions may be skipped. Effective blocks survive permission-prompt bypass.
5. **MCP:** enforcement defaults false; enabled plus empty allowlist denies all. Remote matching ignores URL paths/ports/schemes; stdio launchers and normalized arguments can be broad. Stored approvals require a separate review.
6. **Sandbox:** read access defaults allowed except explicit denies; Factory/WorkOS network destinations remain permitted. Per-command leaves the main process outside OS isolation; whole-process refuses startup without isolation support.
7. **Hooks/plugins:** ordinary nonzero hook errors are nonblocking. Managed-loading policy permits org-enabled plugin hooks and does not secure user-writable script contents. Older clients may ignore strict plugin fields.
8. **Privacy:** image models need separate controls; session sync does not configure AutoWiki sync. VPC execution alone does not establish private inference/storage. Aggregate telemetry retains session/repository/tool metadata, while content opt-in exports raw unredacted data.
9. **Built-in tools/connectors:** org-only Search disablement does not disable Fetch; a Fetch approval threshold is not a hard block. Managed connector execution runs remotely and has a separate server-side availability policy. Disabling an app does not erase member connections or downstream grants.
10. **Evidence:** history is not current resolved device policy and organization audit is not every agent action. No unexecuted surface receives a maturity mark. Live proof remains skipped for lack of a declared tenant and credentials.

Actual offline outcomes, baseline comparison and build limitations are recorded in [factory-validation.md](factory-validation.md).
