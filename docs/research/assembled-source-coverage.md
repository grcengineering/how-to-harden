# Assembled Source Coverage and Validation Ledger

Checked **2026-11-16** against `origin/main` at `403af67`. The main checkout contains unrelated edits; authoring, synchronization and tests run only in `/tmp/hth-assembled-20261116` on `feat/assembled-hth-20261116`. At start, open PRs #95 and #38 concerned repository security/bootstrap work; no Assembled PR was found.

## Placement and Discovery Boundary

**Assembled, Inc. → Assembled platform → Common Controls / Workforce Management / AI Agents & Copilot.** The [terms](https://www.assembled.com/terms-of-service) identify the entity; [About Assembled](https://support.assembled.com/hc/en-us/articles/39589572987789-About-Assembled) distinguishes WFM and AI. Company/official-site searches for acquisitions, mergers and rebrands over approximately 24 months did not establish a change of control. This is a bounded result, not proof no transaction exists. No existing Assembled guide or pack existed in current main.

The public Zendesk Help Center catalog was fetched through `https://support.assembled.com/api/v2/help_center/en-us/articles.json?per_page=100`, following `next_page` through all pages: **224 article bodies**. Read the article bodies below from this first-party JSON representation; cite their human-readable canonical `html_url`. The body observations were recorded before final control reconciliation. `docs.assembled.com` was fetched as full HTML and read by endpoint category, authentication, parameters and response shape. `developer.assembledhq.com` failed discovery; it is not the API documentation host and is not cited as evidence.

Management planes checked: shared identity and roles, WFM/BPO sites and reports, exports and Chrome tracking, AI chat/email/voice, Copilot, knowledge sources/access, backend tools, web widget, native mobile SDK discovery, retention/memories, workflow activation/tests/QA, billing and security release/incident notices. No native Assembled authentication/admin audit-export API, tenant login IP allowlist or adjustable session lifetime was established; these remain unverified gaps rather than claims of nonexistence.

## Trust Center Search

Provenance: the first-party Security and compliance article links `https://trust.assembled.com/` and identifies its **Resources** tab. Automated fetches of the portal and the known Vanta `/json` discovery lead returned **403**. An isolated Interceptor background browser check on 2026-11-16 rendered only an access-request/reclaim form (first name, last name, work email, company and reason). No Resources/category list, pagination, document titles or public download catalog was exposed. No request, NDA, account creation or private download was attempted. The owned research tab group was closed and its absence checked.

**Outcome: discovered + inaccessible.** Catalog categories/pages, adjacent product/regulatory documents and their contents remain unverified. SOC reports, penetration tests and policies mentioned by the help article are discovery leads, not read documents. No Trust Center landing page appears in `hardening_docs`; actual customer configuration articles do.

## Benchmark and Threat Research

| Body / tier | Search boundary and outcome |
|-------------|-----------------------------|
| CIS Benchmarks | Assembled + workforce/WFM product searches on cisecurity.org; no product-specific baseline found in this search; not proof of absence |
| DISA STIG | cyber.mil Assembled/workforce search; no product match established; authoritative download catalog coverage remains unverified |
| CISA SCuBA | cisa.gov product search and SCuBA project scope; no Assembled baseline established |
| NIST / NSA / ACSC | Product searches for Assembled/WFM did not establish product-specific prescriptive guidance. NIST SP 800-53 Rev. 5 is used for thematic mappings, not invented Assembled settings |
| Tier 3 / 4 | Bounded product-specific searches across standing-list research domains (including Mandiant/Google, Obsidian, AppOmni, Wiz and PromptArmor) did not identify an admitted Assembled-specific original research source. Do not reinterpret unrelated uses of the word assembled as product coverage |
| First-party incident | November 13, 2026 notice (updated November 15) read in full. Used as current integration blast-radius context; RCA and account-specific IoCs remain unavailable, not invented |

SOC 2 and ISO references in the guides are thematic only. No numbered SOC/ISO/PCI/STIG compliance claim is inferred from a certification or from NIST control similarity.

## Source-First Candidate Reconciliation

All rows below were retrieved on 2026-11-16 using the public Help Center JSON article bodies. A successful catalog request alone was not treated as reading the article; the source sections listed were inspected. A covered row means documentation reconciliation, **not** live validation.

| Source and precise candidate | Plane / guide disposition | Content observation and limit |
|------------------------------|---------------------------|-------------------------------|
| [About Assembled](https://support.assembled.com/hc/en-us/articles/39589572987789-About-Assembled) — WFM and AI products; shared console | Placement | Hub plus WFM and AI guides; no additional identity plane for BPO, chat/email/voice or legacy Assist established. |
| [SAML single sign-on](https://support.assembled.com/hc/en-us/articles/14654026012173-SAML-single-sign-on) — SAML setup and Require SSO for everyone | Hub 1.1 | Support supplies tenant-specific values and enforces SSO; no invented console enforcement toggle. |
| [Okta single sign-on](https://support.assembled.com/hc/en-us/articles/4423959887117-Okta-single-sign-on) — Okta sign-in setup | Hub 1.1 | Alternative IdP route; do not silently equate client-secret Okta setup with generic SAML metadata. |
| [Microsoft Entra ID single sign-on](https://support.assembled.com/hc/en-us/articles/48123087821965-Microsoft-Entra-ID-single-sign-on) — Entra enterprise application and enforcement | Hub 1.1 | Alternative IdP route; unique ACS and Entity ID, support rollout. |
| [Roles and permissions](https://support.assembled.com/hc/en-us/articles/4414692774285-Roles-and-permissions) — Role editing/assignment and permission tabs | Hub 1.2; WFM 1.2–1.3 | Pro/Enterprise custom roles; report filters do not configure other pages. |
| [SCIM provisioning](https://support.assembled.com/hc/en-us/articles/45775797385613-SCIM-provisioning) — WorkOS sync, suspension vs removal, group mapping, returning users | Hub 1.3 | SCIM through WorkOS; no guessed /scim endpoint; API directory record cannot prove login deactivation. |
| [Deactivate, delete, and restore people](https://support.assembled.com/hc/en-us/articles/4414677145613-Deactivate-delete-and-restore-people) — Deactivate, delete and restore distinctions | Hub 1.3 | Deactivation verification in console; no automated DELETE during this task. |
| [Custom integrations](https://support.assembled.com/hc/en-us/articles/47949671516813-Custom-integrations) — Assembled API key creation | Hub 3.1 | Configure > Assembled API; no fabricated scopes, TTL or key-management endpoint. |
| [Third-party integrations](https://support.assembled.com/hc/en-us/articles/4414692932109-Third-party-integrations) — Connector identity, disable/reconnect, status rows | Hub 3.2, 5.1 | Disabling retains stored data; agent-state gaps are not backfilled. |
| [Assembled MCP server](https://support.assembled.com/hc/en-us/articles/45407559982221-Assembled-MCP-server) — MCP permissions override other restrictions; WFM tools | Hub 3.3 | Inbound OAuth MCP server distinct from outbound AI connectors. New API write tools not executed. |
| [Assembled MCP server setup](https://support.assembled.com/hc/en-us/articles/50301337480973-Assembled-MCP-server-setup) — External client setup | Hub 3.3 | Client-specific OAuth setup is not an additional admin automation surface. |
| [Restricted sites](https://support.assembled.com/hc/en-us/articles/17167908394125-Restricted-sites) — Restricted sites, aggregate data exception, own-account restriction | WFM 1.1 | Explicit site list and recovery limits; no assertion REST filter configures the policy. |
| [Google Sheets exports](https://support.assembled.com/hc/en-us/articles/27204929306381-Google-Sheets-exports) — Export destinations, service identity and recurring jobs | WFM 2.1 | Dedicated restricted destination; Google Sheets card > Edit recurring exports; deletion retains exported data. |
| [Website tracking with the Assembled Chrome extension](https://support.assembled.com/hc/en-us/articles/42088963628045-Website-tracking-with-the-Assembled-Chrome-extension) — Approved websites and extension tracking | WFM 2.2 | Chrome-only; website addresses rather than page paths; historical data unchanged. |
| [Scheduling history](https://support.assembled.com/hc/en-us/articles/46702243244941-Scheduling-history) — Schedule history actor/change records and restore scope | WFM 3.1 | Read-only review; restore is intentionally not performed. |
| [AI agent permissions](https://support.assembled.com/hc/en-us/articles/43989515767565-AI-agent-permissions) — Default AI editors, tool/knowledge/reviewer settings | AI 1.1 | Granular channel permissions and scoped QA. |
| [Knowledge access levels](https://support.assembled.com/hc/en-us/articles/27380002716045-Knowledge-access-levels) — Internal/External article defaults and high-risk overrides | AI 2.1 | Check chat and brand overrides; Copilot can use internal articles. |
| [User segments](https://support.assembled.com/hc/en-us/articles/38109895225869-User-segments) — Customer-selected segments and tag filters | AI 2.1 | Segments are not an authentication or authorization boundary. |
| [Google Drive integration](https://support.assembled.com/hc/en-us/articles/21982462990093-Google-Drive-integration) — Shared knowledge folder and Internal default | AI 2.1 | Limit approved source content; no invented source-content ACL inheritance. |
| [Knowledge management](https://support.assembled.com/hc/en-us/articles/26722701998733-Knowledge-management) — Knowledge ingestion/index | AI 2.1 | Source content review, article access levels and overrides rather than duplicating connector instructions. |
| [Chat widget installation](https://support.assembled.com/hc/en-us/articles/33739474023693-Chat-widget-installation) — JWT signing, verified-data switch, activation | AI 2.2, 5.1 | Signing secret stays server-side; anonymous chat still available. |
| [Chat user authentication in a Zendesk help center](https://support.assembled.com/hc/en-us/articles/50086951170189-Chat-user-authentication-in-a-Zendesk-help-center) — Help-center identity integration | AI 2.2 | Zendesk-only account details remain unverified without backend product identity; signed-token route required for trust. |
| [Chat widget advanced setup](https://support.assembled.com/hc/en-us/articles/33739515754637-Chat-widget-advanced-setup) — Session clearing, CSP and page activation precedence | AI 2.3, 5.1 | Official browser JS SDK pack; teardown timeout is not proof session clearing succeeded. |
| [Browser and page data in chat workflows](https://support.assembled.com/hc/en-us/articles/39327947694605-Browser-and-page-data-in-chat-workflows) — Automatically sent page/browser metadata | AI 2.2 | Context is untrusted; no published collection-disable toggle found; privacy/data minimization gap retained. |
| [MCP connectors](https://support.assembled.com/hc/en-us/articles/42078579457549-MCP-connectors) — MCP auth, tool types, real direct tests, static egress | AI 3.1–3.2, 5.2 | No-auth default is not approval; regular resync can change tools; addresses must be read in tenant. |
| [Custom API endpoints](https://support.assembled.com/hc/en-us/articles/36300687233677-Custom-API-endpoints) — API domain, endpoint/step read-write types and preview | AI 3.1 | Preview sends real requests; headers/parameters are not an Assembled policy-as-code format. |
| [Custom actions in Copilot](https://support.assembled.com/hc/en-us/articles/42747029750669-Custom-actions-in-Copilot) — Copilot custom-action filters | AI 3.3 | Visibility filter is not downstream authorization; support-enabled feature. |
| [Database connectors](https://support.assembled.com/hc/en-us/articles/46918836914957-Database-connectors) — Dedicated database account, saved parameterized SELECT, SSL, row/time bounds | AI 3.4 | Snowflake/Databricks/Redshift documented; no generic schema invented for a db pack. |
| [AI data security](https://support.assembled.com/hc/en-us/articles/21987166296589-AI-data-security) — Pre-model redaction and irreversible stored-data cleanup | AI 4.1–4.2 | Different timing and scope; 7–365 days with 90 default; contact support for pre-model redaction. |
| [User memories](https://support.assembled.com/hc/en-us/articles/41212723066125-User-memories) — Chat/voice user memories and browser session identifier | AI 4.3 | Disable when unneeded; retention/deletion of past memories unverified. |
| [Workflow activation](https://support.assembled.com/hc/en-us/articles/35787875078669-Workflow-activation) — Channel activation and email Agent review | AI 5.1 | Chat/voice do not have the same review mode; per-channel inactive rollback. |
| [Workflow bulk testing](https://support.assembled.com/hc/en-us/articles/38942099792397-Workflow-bulk-testing) — Positive/negative selection tests and error exclusion | AI 5.1 | Bulk accuracy measures selection, not answer quality or authorization. |
| [Automated knowledge answers in the email agent](https://support.assembled.com/hc/en-us/articles/43637851710605-Automated-knowledge-answers-in-the-email-agent) — Fallback email knowledge answers activation, modes and filters | AI 5.1 | Independent activation must be reviewed; default operation mode Automated while activation starts Inactive. |
| [Quality review](https://support.assembled.com/hc/en-us/articles/21869938807437-Quality-review) — QA review, scoring and test-case feedback | AI 5.2 | Manual review evidence; no security-event API invented. |
| [Snowflake data share](https://support.assembled.com/hc/en-us/articles/48637323714701-Snowflake-data-share) — Enterprise secure-view share | Unverified / data export boundary | Documented downstream metrics share, not security audit source; tenant provisioning, destination grants and data schema not exercised. General Snowflake hardening belongs to its own guide. |
| [Security and compliance](https://support.assembled.com/hc/en-us/articles/40487316559629-Security-and-compliance) — Trust Center Resources and access process | Discovery only | Assurance page does not originate controls; Resources catalog is access-gated. |
| [Privacy and data handling](https://support.assembled.com/hc/en-us/articles/40488058050701-Privacy-and-data-handling) — Privacy and data-handling overview | Corroboration / scope | Assurances are not configurable controls; actual AI settings come from AI data security. |
| [November 13, 2026 security incident](https://support.assembled.com/hc/en-us/articles/50413354064909-November-13-2026-security-incident) — November 13 incident, last updated November 15 | Hub incident context; all integration controls | Outbound stored credentials and chat JWT keys affected; customer-created Assembled API keys differentiated. Account IoCs and RCA not public in this run. |
| [Billing](https://support.assembled.com/hc/en-us/articles/4414692943245-Billing) — Billing controls | Excluded | Billing administration does not itself add a supported security setting within the selected scope. |
| [Team member attributes](https://support.assembled.com/hc/en-us/articles/4414677343373-Team-member-attributes) — Team attributes and BPO sites | WFM 1.1 | Hierarchy and site setup; operational skills/forecasting excluded. |
| [Event types](https://support.assembled.com/hc/en-us/articles/4414684329357-Event-types) — Event type visibility and historical effects | WFM 1.3 / scope limit | Editing permissions covered; operational classification/mapping is not security authorization. Agent visibility is not an access boundary for schedulers. |
| [Assembled Chrome extension](https://support.assembled.com/hc/en-us/articles/40070352948877-Assembled-Chrome-extension) — Chrome extension install and permissions | WFM 2.2 / unverified | Approved deployment prerequisite; a supported enterprise extension policy/export schema was not established. |
| [Chat SDKs for iOS and Android](https://support.assembled.com/hc/en-us/articles/41403616169357-Chat-SDKs-for-iOS-and-Android) — Native mobile chat SDKs | Unverified | Separate iOS/Android lifecycle controls require platform-specific testing; browser teardown evidence is not transferred to native SDKs. |
| [Early access features](https://support.assembled.com/hc/en-us/articles/50155904385421-Early-access-features) — Early access feature switches | Hub 1.2 / excluded | Restrict broad configuration roles; no extra control to enable beta features. No beta handle used in packs. |
| [Global workflow settings](https://support.assembled.com/hc/en-us/articles/36272147758093-Global-workflow-settings) — Global workflow settings | AI 5.1 / scope | Review company defaults alongside per-workflow overrides; no unsupported policy API claimed. |

## Automation Surface Census

| Surface | Evidence status, read/write decision and lifecycle |
|---------|--------------------------------------------------|
| Terraform resources AND data sources | **Unverified availability / bounded not found.** Vendor API index and registry search found no Assembled administrative provider. The registry provider API fetch failed; Fivetran connector configuration mentioning Assembled is a different product surface. No resource/data-source pack is invented |
| REST | **Documented, available:** Basic-auth REST at `https://api.assembledhq.com/v0`; keys are usernames with an empty password, no bearer auth. Reference index enumerates: people, assignments (early access), roles, agent states, activities/types, event changes, conversations, sites/teams/skills/queues, forecasts, staffing, events, time off, reports and integrations. Packs use only GET people/roles/event_changes. No early-access/deprecated handle is used |
| REST writes | **Documented but not authored:** people PATCH/DELETE and operational writes exist. Role mutation docs mix singular `role` examples with `roles` object fields, and `deleted` differs from console deactivation semantics. No identity mutation pack is supplied on that ambiguous basis. Role configuration, SCIM setup, API-key policy, AI knowledge/tool/retention/activation settings have no public supported write endpoint found in the checked reference. Manual/support paths are documented |
| GraphQL | **Bounded not found / unverified:** no first-party GraphQL reference or schema linked from the vendor API index or Help Center corpus. Third-party generic GraphQL actions are not evidence. No guessed `/graphql` request or private console API used |
| First-party CLI | **Bounded not found:** official API/Help Center references document REST and no admin CLI; added census row to cli-inventory.md. curl is an HTTP client, not an Assembled CLI |
| SDK | **Documented browser JavaScript API, available:** `window.assembled.teardown({clearSession:true})`, init/authenticate documented in chat advanced setup. Session-reset SDK module supplied. Native iOS/Android SDKs discovered but not exercised; no transfer of browser validation. No official server-language admin SDK established |
| Config / client / daemon / system policy | **Documented web integration attributes**, including `data-activated` overriding console state. Covered in AI activation guidance. No supported admin policy-as-code, companion daemon or enterprise extension policy format established. Browser SDK belongs under sdk; no fake central config pack |
| SIEM | **Documented schedule REST feed**, available. Custom polling yields minimal NDJSON; Splunk SPL consumes those documented fields. This is a customer ingestion convention, not a vendor-certified add-on or a global audit export. SPL command syntax and the distinction between repository metadata and executable query comments checked against [Splunk command reference](https://docs.splunk.com/Documentation/Splunk/8.2.12/SearchReference/ListOfSearchCommands) and [comment syntax](https://help.splunk.com/en/splunk-enterprise/search/search-manual/9.2/using-the-search-app/add-comments-to-searches). No authentication, credential-abuse or AI tool Sigma events invented |
| MCP | **Documented, available:** inbound WFM OAuth server (read and two write tools) and distinct outbound AI tool connectors. No public role-policy mutation tool found; permissions configured manually. No private-tenant MCP calls made |
| SQL / downstream warehouses | Database connector tools and Enterprise Snowflake metrics share are documented. Neither is an Assembled-native tenant security SQL interface. Customer schemas and grants unverified, so no fabricated query pack |

**Coverage:** 26 leveled controls (hub 7, WFM 6, AI 13); **4 controls have executable pack support**, with **5 source packs across 3 types** (`api`, `sdk`, `siem`). There are 3 Assembled REST request shapes plus an additional include-deleted query variant, the official browser widget surface, the custom SIEM consumer and two distinct MCP directions. No single number combines MCP permissions with role/report restrictions. Pack coverage is deliberately narrower than control coverage; manual settings and unverified private interfaces remain visible in each control. Absence of a pack is not evidence that no automation could ever exist.

## Validation Scope and Results

`no tenants declared — Tier 0+1 only`. No Assembled credential source or 1Password Environment was declared. No live ClickOps, API request, chat session mutation, connector test, destination write or Splunk execution was performed. Mutating widget code was exercised only with fixtures. No `ai-validated`, `ai-reviewed`, `ni-*` or validation marks were added.

| Check | Result |
|-------|--------|
| `bash scripts/validate-guides.sh` | PASS — ALL TESTS PASSED (0 warnings) |
| Corpus zero-fence scan | PASS — zero fenced blocks in guides |
| Parser-exact control anatomy | PASS — 7 hub / 6 WFM / 13 AI controls; Description, rationale and Attack Prevented populated |
| `python3 scripts/test-assembled-packs.py` / Make target | PASS — 18 offline behavioral tests; no live calls |
| ShellCheck / bash syntax / JavaScript module syntax | PASS for the new packs |
| `actionlint .github/workflows/assembled-packs.yml` | PASS; action refs resolved from official repositories and pinned to immutable SHAs |
| Full pack-to-data sync | PASS — every emitted vendor ✓, no ✗; unrelated generated timestamp changes restored in this isolated worktree |
| New includes, keys and marked excerpts | PASS — four include keys / five rendered pack bodies; no collisions or empty excerpts |
| Strict Jekyll build | PASS — locked dependencies installed only under `/tmp`, site built to `/tmp/hth-assembled-site` |
| Real-browser local preview | PASS — 7 / 6 / 13 actual control rows, zero blank cells, zero missing attack rationales; all five code bodies rendered; one Assembled platform group with three products |
| Live production-site spot check | SKIPPED — draft PR authoring; no merge/deployment authorized |
| Corpus pack validator | Final corrected full run: five existing failure groups / six warnings, none in Assembled paths. These are pre-existing collisions, shell syntax, extension and empty-code debt. A transient SPL marker defect was corrected and the same validator rerun; marker hygiene and generated freshness now pass. The committed changed-file gate requires a successful commit and is not yet claimed |

Full-corpus warnings on deprecated control YAML, contract backfill, single-type vendors and skipped first-party CLIs were read. New coverage is 2/7 hub, 1/6 WFM and 1/13 AI controls; the six-surface census above explains manual/unsupported/unverified paths rather than treating lower pack coverage as complete automation.
- The repository's deprecated scanner control YAML format is not added. OCEAN integration is outside this new-guide authoring scope; no scanner check or live OCEAN result is claimed.
- Public documentation checks are **DRIFT-CHECKED-ONLY**. Live console/API/SDK/SIEM checks are **SKIPPED / NEEDS-TENANT** (and Splunk needs an ingested customer log source).

## Remaining Gaps

Private Trust Center catalog/documents; full product-specific benchmark availability; undocumented/private admin automation; login IP/session policy; precise plan/rollout entitlements not stated in public docs; native mobile chat lifecycle; historical-memory retention/deletion; browser metadata collection-disable policy; tenant Snowflake-share grants; live permission enforcement, JWT/session isolation and connector authorization; incident RCA/account indicators. None is represented as a green test or a verified absence. Maintainers should re-stamp dates if this draft is published on a later day.
