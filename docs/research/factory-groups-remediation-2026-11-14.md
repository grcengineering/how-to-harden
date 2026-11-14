# Factory group policy and CVE remediation — 2026-11-14

This scoped follow-up starts from `5e9504e2901313138d86fdc610eb4d754bff7a92` and Factory v0.2.0. It resolves new group-policy, Security Factory/CVE remediation and related audit-contract gaps. It is not a fresh whole-Factory or acquisition-family audit. The [November 5 inventory](factory-source-coverage.md) remains historical evidence for other controls.

No tenants declared — Tier 0+1 only. No live credentials, settings, scanner, listener, workstream or inference task were used. Current `ai-drafted` maturity is retained. Read-only collectors were exercised against synthetic responses, never a vendor tenant.

## Source-first reconciliation

Configuration bodies below were retrieved in this session through public HTTPS or web retrieval and read as text. Discovery announcements were also read through web retrieval; failed curl attempts are not counted as successful reads. A successful HTTP status alone was not used as configuration evidence.

| Candidate and precise source | Plane and conditions | Disposition |
|------------------------------|----------------------|-------------|
| [User Groups](https://docs.factory.com/enterprise/user-groups), model resolution and group setup | Root Owner, synced IdP groups; per-organization settings. Group model access unavailable customer-hosted and not enabled everywhere. | **Covered:** new 1.4 and corrected 4.2. Organization list is a default; group Allow and individual exceptions can widen it. Model-only groups require console/IdP review. |
| Same source, usage-limit resolution and API | Individual cap, then highest group cap, then global cap; changes resolve on the next request. Group API controls credits, not model access. | **Covered:** 1.4. New GET inventory is supporting evidence only. Documented PUT exists but is not a model-policy writer; credit-setting deployment is left to the reviewed console workflow. |
| Same source, multi-organization saves and audit | One save can normalize differing values; unchecked organizations lose mappings. Stable directory IDs survive renames. | **Covered:** 1.4 rollout/rollback and monitoring. An empty credit mapping response does not prove no model-only groups. |
| [CVE remediation](https://docs.factory.com/automations/cve-remediation), setup and Security and access | Private Preview; macOS/Linux listener and fix machines; desktop/web Tasks. Plans/merges use instructions and existing machine credentials. | **Covered:** new 3.8. Separate scanner reads, source-control enforcement, workstream/session permissions and isolated build credentials. No separate administration tenant inferred from the product name. |
| Same source, Setup choices and Known limitations | Trial pace, fixed scanner coverage/paging limits, disabled alert types, explicit pause/retire, stalled agents, permanent task closure on defer/accept | **Covered:** 3.8. Failed/missing coverage is not a clean security result; existing tasks and credentials require separate containment. |
| [Organization API](https://docs.factory.com/api-reference/organization), GET group limits | Required `groupLimits` array and nullable name/limit; no paging contract | **Implemented:** API 1.04. Schema/duplicate/partial-response checks, field minimization, new private file. Does not read membership or model exceptions. |
| Same source, GET audit events | Enterprise human Owner, fixed time filters, opaque cursor; source means product surface rather than IP. Authority/scope changes can require restart. Root-wide queries can exclude other regions. | **Implemented:** API 5.03 and new 5.3; corrected former 5.2 export gap. Active organization only; complete-window restart after error; deduplicate organization/event ID; omit actor/payload/target. No streaming or universal event coverage claim. |
| [Audit console](https://docs.factory.com/enterprise/audit-log) | Enterprise Owner; administrative changes, separate from agent runtime | **Covered:** 5.2–5.3. Review full details in the console and correlate with source-system evidence. |
| [Factory news](https://factory.com/news/security-factory), November 10; [User Groups announcement](https://factory.com/news/user-groups), November 6 | Product discovery, not an API specification | Leads reconciled against the configuration references above. No extra control is derived from marketing claims. |

## Six-surface census for this follow-up

| Surface | Current evidence/status | Write/read decision |
|---------|-------------------------|---------------------|
| Terraform resources **and** data sources | **Unverified** for group model overrides, audit or listener administration. Bounded Registry/docs searches did not establish a vendor-native provider contract. | No provider/resource/data-source invented; generic compute providers do not configure these controls. |
| REST / GraphQL | Group credits GET/PUT and audit GET are **available** in the current Organization API. Group model writes are explicitly excluded from the credits API. Public GraphQL and CVE-listener read/write contracts remain **unverified**. | Separate read packs for 1.4 and 5.3. No listener writer, model setter or partial aggregate audit collector. |
| First-party CLI | Inventory row 128 plus [current CLI reference](https://docs.factory.com/droid-cli/cli-reference): existing documented rules/MCP/plugin/compute inventories. CVE setup/status slash commands belong in the orchestrator chat. | Existing CLI packs retained. No invented shell command for group models/audit or a launch command mislabeled read-only. |
| Official SDK | [Python SDK](https://docs.factory.com/sdk/python) documents agent/model discovery; no new group/audit/listener administration method verified. | Existing 4.2 selectable-model read remains useful under representative identities. No fake SDK wrapper. |
| Native config | [Enterprise Controls](https://docs.factory.com/enterprise/hierarchical-settings-and-org-control) documents organization model policy; group precedence is a separate current layer. | Existing 4.2 generator retained with corrected scope. No guessed group settings schema or CVE instruction bundle. |
| SIEM | Documented audit metadata and existing OTLP export; no validated ingested index or CVE task-event schema. | Collect available audit metadata; leave source-system correlation explicit. No speculative detector/event name. |

All newly used handles were documented without a deprecation notice in the inspected sections. The only new executable surfaces are the two scoped reads; no new write surface for model policy or listener administration was established. Multiple existing Factory pack types remain supported; this is not claimed as complete automation coverage.

## Trust Center discovery

Discovery chain: the official [Factory website](https://factory.com/news) links [trust.factory.com](https://trust.factory.com/). The landing body is a Vanta JavaScript shell, not an empty catalog. The known Vanta [public JSON catalog](https://trust.factory.com/json) returned substantive metadata, SHA-256 `5d165b8f2a0fb2099ad93f81d03a2bdd81bac0c071955a436d70a871633d0eb1`.

Both returned categories were examined: **Documentation** (7 entries) and **FedRAMP 20X** (4 entries). The returned resource structure exposes categories/items without pagination; no claim is made about private/unlisted documents. Documentation entries are gated SOC/ISO assurance material. The FedRAMP category exposes a marketplace link and gated milestones, ongoing report and certification-package overview. The overview identifies Factory for Government, version 1.1, November 9, 2026, but its body was not read. These entries do not establish commercial customer settings or completed authorization. No access request, NDA acceptance, account creation or purchase occurred.

Result: **catalog content verified; no public customer configuration baseline found in the two returned categories**. Restricted documents remain unread, not absent. The guide's hardening buttons point to actual configuration references rather than the Trust Center.

## Verification and limits

- Baseline `validate-packs.sh --all` on unchanged main: **5 failures, 6 warnings**. The vendor argument scopes coverage reporting; it does not scope the corpus checks. Existing failures include unrelated collisions, shell syntax, invalid extensions and an empty executable pack.
- Factory authored coverage moves from **18/24** to **20/27** leveled controls; pack count **26 → 28**, still using config, API, CLI and SDK. Counts describe the authored corpus, not discovery completeness or live enforcement.
- Offline tests exercise nullable group fields, duplicate/invalid/partial responses, audit windows, cursor encoding/repeats/limits, later-page restart errors, field minimization, credential handling and private-output preservation.
- **DRIFT-CHECKED-ONLY:** all changed product guidance. **SKIPPED:** live policy, IdP/group propagation, model catalog, audit console/API, SCM bypass and remediation lifecycle tests; no approved test tenant/credentials were declared. **VERIFIED-LIVE:** zero. No maturity/status marks added.
- No government baseline is applied to the commercial product. Other Factory-family products and remaining provider/GraphQL/SDK contracts were not newly audited.
