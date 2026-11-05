# Anthropic source-first coverage — November 2026

Opened 2026-11-05 before selecting additions to the guide/control list. Scope: all Anthropic guides and their code packs; public primary sources, no tenants declared — Tier 0+1 only. Existing guides: Common Controls, Claude Enterprise, Claude Code, Anthropic API. Research and native-interface/offline validation do not earn live validation.

## Discovery log and open candidates

The entries below were recorded from source content independently of the existing guide headings. Retrieval failures are evidence gaps, not capability absence. Dispositions will name actual controls and packs after reconciliation.

| Candidate / precise primary source | Plane | Conditions and observation | Disposition at discovery |
|---|---|---|---|
| [Enterprise security announcement](https://claude.com/resources/articles/claude-enterprise-security-updates), Security Center | Enterprise organization | 2026-11-05 web search body read after direct-open failure. Beta; recommended values, manual attestations, PDF, Compliance API. Screenshot alt text says 13 of 16 passed; does not establish a fixed global checklist. | Gap: research the authoritative individual checks; do not manufacture a 16-check inventory. |
| [Security Center help](https://support.claude.com/en/articles/18246629-review-your-organization-s-security-posture-with-the-security-center), access, statuses, report | Org / chats / Cowork / Code and device settings | 2026-11-05 search body read after direct-open failure. Owners and Primary Owner only, not Admins; Passed/Failed/Not attested/Shown for information. Describes workflow but no complete individual-check list. | Gap: document workflow and its assurance limits; individual inventory unverified publicly. |
| [Effective organization settings](https://platform.claude.com/docs/en/api/compliance/organizations/settings/retrieve) and [Compliance org data](https://platform.claude.com/docs/en/manage-claude/compliance-org-data) | Compliance read API | 2026-11-05 pages retrieved, substantive schema inspection pending. Settings are not automatically Security Center checks or recommendations. | Gap: independently inspect schema and distinguish inventory/read from enforcement/posture status. |
| [Cowork security best practices resource](https://trust.anthropic.com/resources?name=claude-cowork-security-best-practices&s=uukz8hyx7jmdmo80lys36s) | Client / organization | 2026-11-05 text fetch has zero readable lines; browser inspection pending. Trust-host title alone proves no configuration claim. | Unverified: content/access, not absent. |
| [Security announcement](https://claude.com/resources/articles/claude-enterprise-security-updates), centralized management | Parent admin.claude.com / child organizations | Beta; parent SSO, SCIM, groups, multiple IdPs and cross-org Compliance keys. Parent roles do not grant child access. Last approval completes irreversible setup. | Gap: follow admin setup/role/reference sources; no enrollment or live changes authorized. |
| Same announcement, incident response and network | Admin API / sessions / IP | Sign-out beta does not revoke API keys, running cloud sessions or schedules/routines; re-login remains possible. IP allowlisting supports most products, not all. | Gap: retrieve exact endpoints and exclusions before code or recommendations. |
| Same announcement, DLP / desktop / EDR | Inference hooks / cloud admin / MDM / local VM | Prompt and pre-tool hooks GA on supported products; desktop cloud settings beta; local EDR beta is detection-only, excludes cloud. | Gap: follow deployment, version, precedence and supported-platform references. |
| [Workload identity federation](https://platform.claude.com/docs/en/manage-claude/workload-identity-federation), rules, exchange, SDK precedence | API organization / service accounts / runtime | 2026-11-05 full body read. Subject/claims/CEL constraints, explicit rule ID; token lifetime bounds; API key/auth-token precedes federation. | Gap: reconcile against API guide and official SDK, authentication and workspace blast radius. |
| [Release notes](https://support.claude.com/en/articles/12138966-release-notes) and [beta inventory](https://support.claude.com/en/articles/14503520-available-beta-and-research-preview-features) | Product/ownership index | 2026-11-05 full bodies read. Unified chat/Cowork, Duet research preview, Managed Agents beta, connectors/plugins/memory; Claude Code Security Center is a distinct feature. | Gap: inventory product planes and related admin controls independently of four existing guides; avoid marketing-only stubs. |
| [Plugin security](https://code.claude.com/docs/en/plugins/security), trust and automatic updates | Code plugins / host runtime | 2026-11-05 full body read. Plugin code can run outside tool sandbox via hooks/MCP/LSP/background/JS; tool permissions do not contain plugin-owned host code. | Gap: verify installed-code supply-chain controls and managed policy. |
| [Server-managed settings](https://code.claude.com/docs/en/server-managed-settings) | Code cloud policy / cached local client | 2026-11-05 retrieved lead; detailed supported platforms/auth and failure behavior pending. | Gap: read precedence and rollout behavior; do not infer all clients receive settings. |

## Validation boundary

## Public best-practices resource recovered

The Trust Center rendered a public resource titled **Claude Cowork and Unified Claude Security Best Practices** with a download link. Browser download stalled and the browser subsequently became unavailable; a bounded public `curl` download succeeded. The eight-page PDF identifies itself as **Unified Claude and Cowork Security Best Practices, version 1.3, 2026-09-17**. SHA-256: `a5dd38170e51961de623a96c58562c604cf9f0332d3b5298b60dfe617cbc9fa0`. Read with `pdftotext -layout` on 2026-11-05, including both baseline tables and appendices. The PDF is not checked into this repository. [Public resource](https://trust.anthropic.com/resources?name=claude-cowork-security-best-practices&s=uukz8hyx7jmdmo80lys36s); [download observed in browser](https://trust.anthropic.com/doc/trust?rid=6aa2110030a7f2cf301af4fd&r=iz673w96495gyjer8h78n&download=true).

This is a published recommended baseline, **not a documented mapping to the Security Center's checks**. Its prose calls Part 2 “16 Cowork-specific settings” and Part 3 “13 organization-level settings”; do not use those counts as a native posture inventory. Retain the actual table subjects below, including optional controls, and resolve inconsistent/dated claims against current configuration pages. The scheduled-tasks row repeats remote-control text; it is not a reliable source for a task-specific default. The remote-control rows conflict about the trusted-device default; current Remote Control docs say off. Current Chrome docs say Enterprise defaults on (except HIPAA), scanning docs record the October 2 default change, and unified-experience docs specify the November 16 rollout. Current retention docs distinguish chat-linked cloud sessions from standalone remote sessions; the older PDF's blanket cloud exclusion is stale.

| Source-derived subjects (PDF sections 2–3 unless specified) | Plane / conditions to reconcile | Discovery disposition |
|---|---|---|
| Cowork access; unified chat/Cowork; cloud execution; disabling desktop Cowork | Org/role controls versus MDM; unified does not depend on the older Cowork switches | Gaps; separate controls and verify future default dates. |
| Remote control; trusted devices; scheduled tasks | Linked computers, local execution and cloud persistence; existing sessions and sign-out exclusions | Gaps; current Remote Control and unified setup references govern actual behavior. |
| VM egress; workspace folders; web search; web fetch; inline visualizations | Separate sandbox, server-side tools, local folders and optional capability; no generic egress-all claim | Gaps; narrow allowlists and scope each boundary. |
| Chrome; connectors; MCP tunnels; locally configured MCP; desktop extension allowlist | Browser sessions and connector credentials; tunnel does not limit downstream tool power | Gaps; follow current per-tool/per-role policies and Desktop system-policy keys. |
| Automatic approval; sharing chats with cloud sessions | Approval mode independent from tool policy; sharing requires both chat and cloud-session settings | Gaps; distinguish Code auto-mode from Cowork auto-approval. |
| Compliance API; Cowork OpenTelemetry | Server evidence versus opt-in telemetry; local/cloud/provider retention differs | Gaps; minimal scopes, content sensitivity and event semantics. |
| SSO/SCIM/domains; domain capture; block new organizations | Parent identity, directory and irreversible account migration | Gaps; no migration execution; current prerequisite/recovery reference required. |
| Session length; tenant restrictions; required org on devices | Session duration affects schedules; proxy overwrite versus Desktop policy | Gaps; seven days is the PDF recommendation, not a fixed Security Center check. |
| Plugin marketplaces; skill/plugin scanning | Cloud library publishing versus Code host executable plugins | Gaps; October scanning and November publishing default changes. |
| Organization instructions; inference hooks | Prompt context versus enforceable signed inline verdicts | Gaps; instructions are not a security boundary; hook failure policy/coverage matters. |
| Retention window; optional CMEK | Chat/project/artifact policies, local data, remote sessions, irreversible key binding | Gaps; newer docs and product-specific exceptions supersede the PDF. |

## Additional surface discoveries (2026-11-05)

| Evidence read this session | Specific observation | Discovery disposition |
|---|---|---|
| [Settings reference](https://platform.claude.com/docs/en/api/compliance/organizations/settings/retrieve), full enum and types; [org data](https://platform.claude.com/docs/en/manage-claude/compliance-org-data) | 64 boolean names, integer session duration, two nullable worker strings, three string lists, provisioning and retention. Effective values, omitted rows not off; separately enabled per-parent access can return 404. No recommended values or Passed/Failed statuses in this schema. | Build explicitly operator-baselined read assessment, never a native Security Center emulator. |
| [Official CLI quickstart](https://platform.claude.com/docs/en/cli-sdks-libraries/cli/quickstart), [authentication](https://platform.claude.com/docs/en/cli-sdks-libraries/cli/authentication), [using](https://platform.claude.com/docs/en/cli-sdks-libraries/cli/using), [official source](https://github.com/anthropics/anthropic-cli) | `ant` now provides organization administration; old CLI inventory mentioning only `claude` is incomplete. Official v2.7.0 archive checksum matched published checksum; local version/help inspected without login. Namespaces use colons (`organization:users`), not guessed nested subcommands. | Add real read CLI packs and update inventory; no sign-in or credential creation. |
| [Official TypeScript SDK](https://github.com/anthropics/anthropic-sdk-typescript), package and organization/users source | Current package 1.6.0; `client.organization.users.list` supports auto-pagination. Full installed resource-tree search found no native Compliance settings resource in v1.6.0; REST exists independently. This is version-bounded evidence, not global API absence. | Native SDK membership inventory; do not invent a settings method. |
| [Community Terraform provider](https://registry.terraform.io/providers/jianyuan/anthropic/latest/docs), full resources and data-source directories | v0.3.0; resources: organization invite, service account, service-account workspace member, workspace, workspace member. Data: organization, organization invites, service account(s), user(s), workspace(s), workspace member(s), workspace rate limits. No documented Enterprise posture/SSO enforcement handle in this bounded list. | API-plane workspace write and read pack possible; community lifecycle and irreversible archive/state effects explicit. |
| [API retention](https://platform.claude.com/docs/en/manage-claude/api-and-data-retention) | Current standard conversation retention differs from old blanket 30-day claim; Covered Models and stateful features are exceptions. Compliance local, remote and Tag transcripts have distinct retention; ZDR does not cover Console/Managed Agents. | Correct API and Enterprise data-handling claims. |
| [IP allowlisting](https://platform.claude.com/docs/en/manage-claude/ip-allowlisting) | Public-source ranges; Console and Enterprise lists independent. Single-org admin/compliance keys covered; parent-wide keys and some apps differ. Managed Agents API coverage does not cover runtime network. | Add boundary and lockout/recovery guidance, not blanket all-app containment. |
| [Enterprise user management](https://platform.claude.com/docs/en/manage-claude/user-management), sign-out section | Beta `admin-user-sign-out-2026-10-08`; no body; `write:members`, one-org key. Whole-account sessions versus org-only OAuth; primary owner cannot be signed out; keys/cloud sessions/routines/linked computers persist. | Add explicit guarded response pack and verification, not a kill-switch claim. |
| [Plugin scanning](https://support.claude.com/en/articles/15927065-get-started-with-skill-and-plugin-scanning) and [provisioning skills](https://support.claude.com/en/articles/13119606-provision-and-manage-skills-for-your-organization) | Scanning defaults on from Oct 2 for undecided Enterprise orgs; Publishing can change to Open from Nov 4 with scanning. Owners' own submissions bypass manual review. | Add explicit publishing choice, review exceptions and default-date caveat. |
| [Desktop system policy](https://support.claude.com/en/articles/12622667-enterprise-configuration-for-claude-desktop), [EDR](https://support.claude.com/en/articles/17828685-run-your-endpoint-detection-and-response-edr-sensor-in-claude-cowork-on-claude-desktop) | Desktop domain differs from Code. Local-VM EDR beta requires v4.4212.0+, approved signed package, Windows MSIX; telemetry bypasses Cowork egress. Removing policy does not uninstall sensor. | Native payload generator and readback guidance; no live deployment. |
| [Permission limitations](https://code.claude.com/docs/en/permissions), [plugin security](https://code.claude.com/docs/en/plugins/security) | Bash command text matching is not a program isolation boundary; plugin-owned host code is outside tool sandbox. | Correct hard-boundary and full-default-access claims. |

## Six-surface census

| Surface | Read / write / status, bounded evidence | Pack decision |
|---|---|---|
| Terraform | Community provider v0.3.0 resources/data sources above; available. Enterprise posture writes not documented in that list. | Workspace segmentation/residency plus data-source verification; no fabricated posture resource. |
| REST / GraphQL | Public Admin and Compliance references; Enterprise settings GET exists, Security Center individual-check API schema unverified. No GraphQL interface documented in the inspected official references; not a claim of global absence. | Read settings/roles/spend/activity and guarded sign-out; do not POST effective settings. |
| First-party CLI | `ant` v2.7.0 read and beta sign-out/analytics handles verified in native help; `claude` local client commands separate. | Add administrative reads and local policy diagnostics; do not conflate `ant auth status` exit zero with a successful health check. |
| SDK | Official TypeScript v1.6.0 native org users; beta analytics usage/cost, native spend/role and Managed Agents resource schemas inspected. | Native membership inventory, pinned dependency and mocked transport; no invented Compliance method. |
| Native configuration | Code managed JSON / OS policy and Desktop MDM are separate; Enterprise console policy precedence/availability varies. | Actual managed-settings excerpts and Desktop policy emitter; assess local files without claiming effective cloud/MDM enforcement. |
| SIEM | Compliance Activity Feed documents real events; Cowork/Code OTel has separate privacy and coverage semantics. | Collect documented sign-out activity through the feed and detect the documented inference-hook circuit-breaker event; no invented posture-change event ID. |

No live tenant, credentials or OCEAN instance declared. No Security Center PDF or authenticated Compliance output supplied. No live settings, centralized-management approvals, credentials or mutating code packs will be executed. Complete public-source coverage and offline/native-interface checks first; report remaining inaccessible or tenant-dependent areas precisely.

## Final semantic reconciliation

This is an evidence-led refresh of the four existing guides, not a claim to have obtained a complete tenant-specific native posture checklist or a dedicated benchmark for every preview. All original control numbers/headings remain; 21 controls were appended, for 58 authored controls. The public baseline subjects below are reconciled independently of those counts. The effective-settings enum is an additional candidate inventory, not an Anthropic recommendation to enable or disable every feature.

| Source-derived candidate | Final disposition and actual guidance | Executable / validation boundary |
|--------------------------|----------------------------------------|----------------------------------|
| Security Center access, automatic statuses, manual attestations, report/export | **Covered:** Enterprise 2.3. Owner/Primary Owner access, status semantics and evidentiary limits. **Unverified:** complete individual-control/status schema and universal checklist. | No native-score emulator or guessed posture endpoint/event ID. A current authorized Owner report is required to close the tenant-specific inventory gap. |
| Effective settings and key metadata | **Covered:** Enterprise 2.4; explicit operator baseline, all 72 documented setting names inventoried below. | REST plus typed local assessor; 64 boolean cases and missing/null/duplicate/wrong-org/type/error tests. No effective-settings POST or implicit false. |
| SSO/MFA/SCIM, parent identity, multiple IdPs/split domains, domain capture and shadow orgs | **Covered:** hub 1.1/1.2/1.6/1.7 and Enterprise 1.1–1.3. Parent role does not grant child membership; SCIM/invite-only and irreversible enrollment/migration caveats. | API/CLI/official SDK inventories and scoped role reads; no enrollment, migration, credentials or IdP changes executed. |
| Session duration and tenant/org restrictions | **Covered:** hub 1.4/1.5; Enterprise 3.6/3.8; Code 1.1. PDF seven-day recommendation distinguished from native checks; schedules and first-party/provider clients differ. | Existing restriction checker and new Desktop payload; no live proxy, lost-device or IdP recovery test. |
| IP allowlisting and session incident response | **Covered:** hub 1.8 and Enterprise 1.4. Parent-wide keys/product exemptions, propagation, recovery path, unfinished cloud work and partial revocation documented. | Explicit read-by-default, exact-user-confirmed sign-out pack; no live mutation or billing calls. |
| Unified/Cowork/cloud access and November rollout | **Covered:** Enterprise 3.4; explicit November 16 choice/prerequisites, role inheritance and CMEK/ZDR/HIPAA exclusions. | Effective-setting read where available; no unsupported universal write handle. |
| VM egress, folders, search/fetch, inline visualizations, approvals | **Covered:** Enterprise 3.4/3.6/3.8 and Code 1.2/3.1/5.2. Tool, VM, server-side, device and cloud boundaries separated. | Native Desktop emitter; Code policy examples; browser fetch/search bypass, command-text rules and plugin host code are not treated as network enforcement. |
| Chrome, connectors, private tunnels and managed auth | **Covered:** Enterprise 3.1–3.3/3.9. Reviewed destinations, downstream authority, consent and current enablement defaults. | Operator settings assessment only for returned rows; per-tool grants/MDM/effective downstream access remain separate checks. |
| Local MCP, extension allowlist and plugin marketplaces | **Covered:** Enterprise 3.5/3.6; Code 2.1/2.2. Separate system paths, managed hooks, host executables and updates. | Native config/MDM payloads; no installed third-party protection package or fabricated security guarantee. |
| Scanning, publishing and approval exceptions | **Covered:** Enterprise 3.5. October 2 scanning and November 4 publishing changes; owner/self-submission and older-share caveats. | Public-source workflow and available settings; no native scanning/publishing status assumed from a generic feature flag. |
| Remote control, trusted devices, schedules/routines | **Covered:** Enterprise 3.8; Code 1.3. New-session scope, 18-hour verification and sign-out exclusions. | Native Code disable flags and sign-out safety tests; no live remote pairing or session start. |
| Desktop/VM EDR | **Covered:** Enterprise 3.6/3.7. Separate policy domain/HKLM, v4.4212.0+, Windows packaging, signed approved sensor and detection-only local VM boundary. | Parse actual macOS plist and Windows payload; no sensor deployment or uninstall/telemetry claim. |
| Audit, Compliance, OTel, inference hooks | **Covered:** Enterprise 2.1/2.2; Code 5.1/5.3; hub 2.3. Capture toggle exceptions, local/cloud content sensitivity, signed request validation, fail/sampling/role/coverage/circuit-breaker behavior. | Scoped bounded feed export; experimental Sigma for documented outage type. No tenant SIEM pipeline, signed endpoint deployment or custom hook service supplied. |
| Organization instructions, memory, sharing, support/feedback and optional feature data paths | **Covered:** Enterprise 5.3 and API 3.2. Purpose/audience decisions and actual feature settings recorded; instructions are advisory. | Explicit baseline input only; feature enum is not a native recommendation. Existing public links/data require separate cleanup. |
| Retention and optional CMEK | **Covered:** Enterprise 5.1/5.2; API 3.2/3.3. Current chat/project/artifact/cloud/provider/feature coverage, Covered Models, irreversible prospective binding and recovery caveats. | No destructive deletion, key operation or live retention test; organization flag does not prove every workspace/record is covered. |
| WIF, key precedence, API scope, workspace residency/isolation and spend | **Covered:** hub 1.3/2.2; API 1–4 and Enterprise 4.1. Native data_residency field, fractional cents, inheritance and provider distinctions. | Fixed-host REST; stdin-only auth; native ant, official SDK and community Terraform; mocked plans, pagination and mutation guards. |
| Managed Agents tools/vault/runtime | **Covered:** API 3.4. Limited networking, default-denied tools, ask/auto distinction, header-injected host-scoped secrets, session/workspace boundaries and repo instructions. | Real separate native Agent/Environment bodies; no creation or unsupported runtime-isolation claim. Generic host/Kubernetes/provider infrastructure excluded under PHILOSOPHY. |
| Tag/Slack, Science, Design, M365, artifacts, hosted Security/Code Review and Agent SDK | **Covered admission/boundary review:** Enterprise 3.10/5.1/5.3; Code 1.3/4.2; API 3.4. Tag inheritance and Science version/offline/local/network constraints explicitly discussed. **Limited:** not a full independent benchmark for each specialized app/preview. | No invented shared retention, IP, inference-hook or downstream-permission coverage. Product-specific setup/eligibility/effective access still require review before adoption. |
| Server-managed policy fetch/cache/precedence and newer native settings | **Covered:** Code 1.1. forceRemoteSettingsRefresh, startup-only credential selectors, v2.1.223 env exceptions, v2.1.259 provided MCP and v2.1.299 sign-in caveat. | Optional actual native fail-closed fragment; local-file checks explicitly cannot prove effective cloud/MDM state. |
| Third-party incident and sandbox/tool claims inherited from old guide | **Reconciled:** Code 3.2/4.1/4.2. Removed unrefreshed incident statistics and automatic external wrapper installation/rollback; current vendor container and trusted-dispatch examples. | Heuristic scanner remains a review aid. No claim that a clean scan proves injection absence or audit-mode monitoring blocks egress. |
| CIS/CISA platform benchmarks | Bounded public searches performed for Anthropic-specific CIS/SCuBA material yielded no usable result. **Unverified**, not a claim that none exists. | Vendor configuration sources remain primary; generic infrastructure controls excluded. |

## Government / federal source reconciliation

Public files were downloaded without login/access requests and inspected as text/JSON. Artifacts are not checked into the repo.

| Artifact | Observed scope and use | SHA-256 |
|----------|------------------------|---------|
| [C4G FedRAMP Secure Configuration Guide v2.1 (2026-07-16)](https://trust.anthropic.com/doc/trust?rid=6ab43afba6eead3d68716b5c&r=iz673w96495gyjer8h78n&download=true) | 22 pages, C4G claude.fedstart.com, Rev. 5; required/recommended customer controls. Identity/SCIM, scoped secret lifecycle, deny-egress/folders, vetted MCP/approvals, updates, device tenant restriction and telemetry scope mapped in hub baseline appendix. Current online C4G audit API supersedes printed endpoint/lookback assumptions. | 14f136620284835af0d72e3a546c3f18082da21237368e316599aad1612a8e9c |
| [Claude Code FISMA Best Practices v1.0 (January 2026)](https://trust.anthropic.com/doc/trust?rid=698639ba9484b19b52b6f1d2&r=iz673w96495gyjer8h78n&download=true) | Agency-managed endpoints, approved provider routing, IAM/MFA, logs, drift, integrity, data and incident governance. Code 1.4 uses current AWS_PROFILE and DISABLE_TELEMETRY rather than stale printed CLAUDE_CODE_AWS_PROFILE / CLAUDE_CODE_DISABLE_TELEMETRY. | 1c4ab4052647fe75ad142f54f1d308d792b9a3414586fecbcf713059c0c5e649 |
| [Enterprise 20x package overview JSON](https://trust.anthropic.com/doc/trust?rid=6a8dcddb0fb2cfb4ca5be4ab&r=iz673w96495gyjer8h78n&download=true) | Separate commercial Enterprise service/package metadata; neither a hardening baseline nor independent evidence of a completed authorization. No C4G control transfer inferred from schema. | 2feb224ff02db96d6e3c6a2703388a553f260a29b99b7eade5899b9b085c6eef |

The [current C4G API](https://claude.com/docs/government/org-admin/compliance-api) uses the deployment host, gateway-api route, a since bound and a 30-day query window; commercial retention, credentials, scopes and content availability are not transplanted. The older PDF's cross-references are also stale. Government-specific device bootstrap/deployment chooser/tenant-header keys remain scoped guidance, not payloads for commercial Desktop. No dedicated Government guide or tested Government pack was added.

## Effective-setting candidate inventory (72 names)

Derived from the [full settings reference](https://platform.claude.com/docs/en/api/compliance/organizations/settings/retrieve), independently of the final controls. Each name is supported by the typed assessor; omitted means unavailable/not admin-controllable, not false. The mapping is an HTH review destination, not evidence of a Security Center recommendation. Booleans include convenience/product-admission fields; enabling/disabling them requires an explicit risk/plan decision. Worker IDs, visibility and fast-mode flags have no universal hardened value established by this source.

| Returned setting | Type | Review destination / disposition |
|------------------|------|----------------------------------|
| access_transparency_enabled | boolean | Enterprise 2.2; capture exception and scoped evidence |
| ai_powered_artifacts_enabled | boolean | Enterprise 5.3 / 2.4; explicit purpose/audience/privacy decision, no native recommended value asserted |
| api_workbench_feedback_collection_enabled | boolean | API 3.2 and Enterprise 5.1/5.3; eligibility and data-use review, no inferred certification |
| api_zero_data_retention_enabled | boolean | Enterprise 5.1 / API 3.2; product-specific coverage |
| artifact_connectors_enabled | boolean | Enterprise 5.3 / 2.4; explicit purpose/audience/privacy decision, no native recommended value asserted |
| ask_your_org_enabled | boolean | Enterprise 5.3 / 2.4; explicit purpose/audience/privacy decision, no native recommended value asserted |
| chat_cowork_unified_enabled | boolean | Enterprise 3.1/3.4/3.6; independent org, tool, VM and device boundaries |
| chat_enabled | boolean | Enterprise 3.1/3.4/3.6; independent org, tool, VM and device boundaries |
| claude_academy_inference_enabled | boolean | Enterprise 3.10/5.3; admission/data-boundary review, no full specialized benchmark claimed |
| claude_ai_ccr_support_sharing_enabled | boolean | Enterprise 5.3 / 2.4; explicit purpose/audience/privacy decision, no native recommended value asserted |
| claude_ai_chat_sharing_enabled | boolean | Enterprise 5.3 / 2.4; explicit purpose/audience/privacy decision, no native recommended value asserted |
| claude_ai_feedback_collection_enabled | boolean | Enterprise 5.3 / 2.4; explicit purpose/audience/privacy decision, no native recommended value asserted |
| claude_ai_integration_sharing_enabled | boolean | Enterprise 5.3 / 2.4; explicit purpose/audience/privacy decision, no native recommended value asserted |
| claude_ai_skill_plugins_scanning_enabled | boolean | Enterprise 3.5 / Code 2.2; publishing/scanning/host-code and role review |
| claude_code_desktop_bypass_permissions_enabled | boolean | Code 1.1/1.3/5.1; Enterprise 3.8; feature admission, separate policy and telemetry |
| claude_code_desktop_enabled | boolean | Code 1.1/1.3/5.1; Enterprise 3.8; feature admission, separate policy and telemetry |
| claude_code_fast_mode_enabled | boolean | Code 1.3; record actual runtime/model choice; no universal recommended value verified |
| claude_code_metrics_logging_enabled | boolean | Code 1.1/1.3/5.1; Enterprise 3.8; feature admission, separate policy and telemetry |
| claude_code_remote_control_enabled | boolean | Code 1.1/1.3/5.1; Enterprise 3.8; feature admission, separate policy and telemetry |
| claude_code_review_enabled | boolean | Code 1.1/1.3/5.1; Enterprise 3.8; feature admission, separate policy and telemetry |
| claude_code_routines_enabled | boolean | Code 1.1/1.3/5.1; Enterprise 3.8; feature admission, separate policy and telemetry |
| claude_code_security_enabled | boolean | Code 1.1/1.3/5.1; Enterprise 3.8; feature admission, separate policy and telemetry |
| claude_code_trusted_devices_required | boolean | Code 1.1/1.3/5.1; Enterprise 3.8; feature admission, separate policy and telemetry |
| claude_code_web_enabled | boolean | Code 1.1/1.3/5.1; Enterprise 3.8; feature admission, separate policy and telemetry |
| claude_code_workflows_enabled | boolean | Code 1.1/1.3/5.1; Enterprise 3.8; feature admission, separate policy and telemetry |
| claude_design_enabled | boolean | Enterprise 3.10/5.3; admission/data-boundary review, no full specialized benchmark claimed |
| claude_enterprise_claude_code_zero_data_retention_enabled | boolean | Enterprise 5.1 / API 3.2; product-specific coverage |
| claude_in_slack_enabled | boolean | Enterprise 3.10/5.3; admission/data-boundary review, no full specialized benchmark claimed |
| claude_science_custom_connectors_enabled | boolean | Enterprise 3.10; capability, version, offline and downstream boundary review |
| claude_science_custom_skills_enabled | boolean | Enterprise 3.10; capability, version, offline and downstream boundary review |
| claude_science_enabled | boolean | Enterprise 3.10; capability, version, offline and downstream boundary review |
| claude_science_local_work_import_enabled | boolean | Enterprise 3.10; capability, version, offline and downstream boundary review |
| claude_science_managed_network_allowlist_enabled | boolean | Enterprise 3.10; capability, version, offline and downstream boundary review |
| claude_science_memory_enabled | boolean | Enterprise 3.10; capability, version, offline and downstream boundary review |
| claude_science_modal_enabled | boolean | Enterprise 3.10; capability, version, offline and downstream boundary review |
| claude_science_scientific_model_endpoints_enabled | boolean | Enterprise 3.10; capability, version, offline and downstream boundary review |
| claude_science_ssh_hosts_enabled | boolean | Enterprise 3.10; capability, version, offline and downstream boundary review |
| cmek_enabled | boolean | Enterprise 5.2 / API 3.3; flag not full key/data coverage |
| code_execution_enabled | boolean | Enterprise 3.1/3.4/3.6; independent org, tool, VM and device boundaries |
| code_execution_network_egress_enabled | boolean | Enterprise 3.1/3.4/3.6; independent org, tool, VM and device boundaries |
| connector_tools_default_always_allow | boolean | Enterprise 3.1/3.4/3.6; independent org, tool, VM and device boundaries |
| content_redaction_enabled | boolean | Enterprise 5.3 / 2.4; explicit purpose/audience/privacy decision, no native recommended value asserted |
| desktop_extension_allowlist_enabled | boolean | Enterprise 3.1/3.4/3.6; independent org, tool, VM and device boundaries |
| directory_sync_enabled | boolean | Hub 1.1/1.6/1.7; Enterprise 1.1/1.2; read and identity enforcement separate |
| frontier_data_use_enabled | boolean | Enterprise 5.3 / 2.4; explicit purpose/audience/privacy decision, no native recommended value asserted |
| group_skill_sharing_enabled | boolean | Enterprise 3.5 / Code 2.2; publishing/scanning/host-code and role review |
| hipaa_compliance_enabled | boolean | API 3.2 and Enterprise 5.1/5.3; eligibility and data-use review, no inferred certification |
| inline_visualizations_enabled | boolean | Enterprise 3.1/3.4/3.6; independent org, tool, VM and device boundaries |
| ip_allowlist_enabled | boolean | Hub 1.8; exemption/recovery boundaries |
| location_metadata_enabled | boolean | Enterprise 5.3 / 2.4; explicit purpose/audience/privacy decision, no native recommended value asserted |
| member_usage_dashboard_visible | boolean | Enterprise 5.3 / 2.4; explicit purpose/audience/privacy decision, no native recommended value asserted |
| memory_enabled | boolean | Enterprise 5.3 / 2.4; explicit purpose/audience/privacy decision, no native recommended value asserted |
| org_wide_skill_sharing_enabled | boolean | Enterprise 3.5 / Code 2.2; publishing/scanning/host-code and role review |
| project_sharing_enabled | boolean | Enterprise 5.3 / 2.4; explicit purpose/audience/privacy decision, no native recommended value asserted |
| public_projects_enabled | boolean | Enterprise 5.3 / 2.4; explicit purpose/audience/privacy decision, no native recommended value asserted |
| skill_sharing_enabled | boolean | Enterprise 3.5 / Code 2.2; publishing/scanning/host-code and role review |
| skills_enabled | boolean | Enterprise 3.5 / Code 2.2; publishing/scanning/host-code and role review |
| sso_claude_ai_enforced | boolean | Hub 1.1/1.6/1.7; Enterprise 1.1/1.2; read and identity enforcement separate |
| sso_console_enforced | boolean | Hub 1.1/1.6/1.7; Enterprise 1.1/1.2; read and identity enforcement separate |
| sso_enabled | boolean | Hub 1.1/1.6/1.7; Enterprise 1.1/1.2; read and identity enforcement separate |
| third_party_interactive_content_enabled | boolean | Enterprise 5.3 / 2.4; explicit purpose/audience/privacy decision, no native recommended value asserted |
| user_skill_creation_enabled | boolean | Enterprise 3.5 / Code 2.2; publishing/scanning/host-code and role review |
| web_search_enabled | boolean | Enterprise 3.1/3.4/3.6; independent org, tool, VM and device boundaries |
| work_across_apps_enabled | boolean | Enterprise 5.3 / 2.4; explicit purpose/audience/privacy decision, no native recommended value asserted |
| account_session_duration_seconds | integer | Hub 1.5; explicit duration and schedule impact |
| claude_code_default_worker_environment_id | string | Code 1.3; record actual runtime/model choice; no universal recommended value verified |
| claude_code_default_worker_pool_id | string | Code 1.3; record actual runtime/model choice; no universal recommended value verified |
| allowed_invite_domains | string_list | Hub 1.1/1.6/1.7; Enterprise 1.1/1.2; read and identity enforcement separate |
| disabled_admin_request_types | string_list | Enterprise 5.3 / 2.4; explicit purpose/audience/privacy decision, no native recommended value asserted |
| ip_allowlist_ip_ranges | string_list | Hub 1.8; exemption/recovery boundaries |
| sso_provisioning_mode | provisioning_mode | Hub 1.1/1.6/1.7; Enterprise 1.1/1.2; read and identity enforcement separate |
| data_retention_periods | data_retention | Enterprise 5.1 / API 3.2; product-specific coverage |

## Native-interface and verification record

- Official ant 2.7.0 archive matched published checksum (34c60aa4536d405354962a6e8fef7ee476b7af1eb604ee9b698467827d5b7664). Version/help and a localhost two-page fixture used a fake key only. JSON output is a stream of item objects, **not an array**; the wrapper now normalizes it and tests ambient profile removal and late-failure handling.
- Official SDK 1.6.0 actual transport is mocked, not reimplemented. Member pages use raw native responses because the SDK Page class defaults missing has_more to false. Roles/permissions and spend limits use next_page-only PageCursor; usage/cost uses has_more plus next_page; member/activity cursor paths are separate and opaque cursors are encoded.
- New Enterprise baseline assessor does not call an undocumented Security Center endpoint or treat 64 booleans as 64 native checks. Missing/unknown/different outcomes remain distinct and incomplete evidence exits nonzero.
- Community Terraform 0.3.0 installed from the registry, schema-validated and exercised with mocked plans only. The default empty workspace-name set creates no planned resources; no live plan/apply, destroy, credential creation or tenant change.
- Source retrieval failures (early direct-open/text/browser-download issues) were followed by official search bodies or public bounded downloads. The Trust PDF was ultimately recovered. No document was called absent because retrieval failed. Browser session availability remains an independent render-check constraint.
- Tier 0+1 only: no tenant or OCEAN instance declared; live ClickOps/Code controls and device/IdP/SIEM/recovery behavior remain unvalidated. All four changed guides are ai-drafted; the hub’s earlier live status marks were removed where the procedures changed. Structural, rendered and mocked checks establish different things and are reported separately.

Authored corpus: 58 leveled controls (hub 11, Enterprise 22, Code 13, API 12) and 47 native pack files across the two historical/current vendor directories (30 pack files at base). Seventeen net additions include REST, CLI, SDK, native config, community Terraform and an experimental Sigma rule. Counts describe the authored corpus, not a complete native checklist. SDK readers explicitly disable optional SDK OpenTelemetry to avoid ambient telemetry export during inventory.

Final offline verification on 2026-11-05: 131 Bun tests / 520 assertions passed, including actual pinned SDK transport/serialization, typed baselines, native CLI object streams, pagination-family/cursor errors, evidence permissions, shadow credentials, sign-out guards and real policy payload parsing. Terraform validate passed; both mock-plan runs passed. Canonical full pack sync and focused regeneration succeeded. Guide lint passed with zero warnings; no inline guide fences, all original numbered headings preserved, and all 58 controls have parser-required description/rationale/Why/Attack/ClickOps content. Strict Jekyll build passed. In-app browser inspected all four rendered cheat sheets: 11/22/13/12 rows, zero empty cells; 6/13/16/18 code panels with zero empty code blocks. The full corpus advisory still has the same five pre-existing failure groups and six warnings as the baseline (unrelated collisions, shell syntax, type-table violations and an empty Azure DevOps Terraform pack); no Anthropic YAML freshness or CLI-inventory issue remains. Branch-touched checks and remote CI are reported separately after commit/publication.
