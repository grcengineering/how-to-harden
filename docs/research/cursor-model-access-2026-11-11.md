# Cursor model access: scoped source coverage, 2026-11-11

Scope: tenant model selection, inference-host approval, team/organization API enforcement, and bypass/feature interactions. Not a full refresh of Cursor/SpaceXSI products. Existing control IDs preserved; new 2.7; 2.2 and relevant 9.2 claims corrected. Maturity remains `ai-drafted`; Tier 0+1; VERIFIED-LIVE = 0. No tenant credentials or live mutations used.

## Baseline and semantic disposition

Guide 0.6.0 (2026-11-05), platform SpaceXSI / stable `spacexai`, Common Controls. The existing 2.2 pack only read policy, checked new providers but not new models, and described legacy as unrestricted. Scope includes the separate group/BYOK and client/daemon/system-policy planes; GUI control coverage is not assumed complete merely because an API exists. Baseline corpus validation: five existing failures and six warnings; none introduced by this change. Full corpus and touched validation results are recorded in the PR.

| Candidate | Evidence / disposition |
|---|---|
| Model provider/model/parameter controls | [Models & Integrations](https://cursor.com/docs/enterprise/model-and-integration-management), [Team Admin API](https://cursor.com/docs/account/teams/admin-api#model-access), fetched 2026-11-11: 2.7 explicit allowlist, both disabled defaults, existing toggles separate from future defaults; parameters preserved |
| Group union / personal keys | Same first-party model-management page: baseline OR any group grant; group inspection mandatory; BYOK dashboard-only. Pack does not claim effective user permission |
| Organization scope | [Organization API](https://cursor.com/docs/account/organizations/organization-admin-api), fetched: paginated configurations and linked-team/bulk mutations; max100 per bulk, per-result failures with no rollback. Documented, not falsely presented as single-team pack coverage |
| Router dependencies | [Router](https://cursor.com/docs/cursor-router), fetched: policy respected, required models and limited pool; 2.2 retained,2.7 change-impact testing. No permanent required-model list encoded |
| Auto-review / Bugbot | Model-management reference, fetched: restricted dependencies can disable features; neutral Bugbot result is not successful review. No silent feature enable or broadened permissions |
| Developer versus inference host | [GLM 5.2](https://cursor.com/docs/models/glm-5-2), fetched: Z.ai developer, Fireworks hosting. Used as illustrative documented mapping, not a preferred model or exhaustive mapping |
| Kimi routes | [Kimi K3](https://cursor.com/docs/models/kimi-k3), fetched: generic inference partners; [official staff clarification](https://forum.cursor.com/t/kimi-k3-released-request/165964/54) names multiple US hosts (Fireworks, Together, Baseten). Not an exclusive host mapping and not encoded as executable policy |
| Background processing / privacy | [Privacy & Data Governance](https://cursor.com/docs/enterprise/privacy-and-data-governance), [security](https://cursor.com/security), fetched: provider processing and retention are distinct. No claim a model toggle excludes a host from every service; no unsupported incident allegation published |
| Client policy / network | Existing 11.2 and11.4 manage account/tenant restrictions, not native model permissions. 9.2 corrected: endpoint egress is not server-side host selection. Reviewed public deployment/network references via linked hardening reference; no invented settings key |

## Trust Center / implementation-guide discovery

Started from the [official security page](https://cursor.com/security) and its links to [Trust Center](https://trust.cursor.com), [Resources](https://trust.cursor.com/resources), and [Subprocessors](https://trust.cursor.com/subprocessors). These URLs opened, but direct text extraction of the Trust Center pages returned an empty JavaScript shell. Search-index queries for `site:trust.cursor.com/resources hardening secure configuration guide` and `site:trust.cursor.com` surfaced resource/FAQ/update and subprocessor material, including a candidate named **Cursor_CAIQ_Security_Self_Service_Guide.pdf**. Its document body and full catalog pagination were not accessible through these retrievals; it is **unread/unverified**, not absent. No access request, agreement acceptance, or speculative download URL was used. No claim of exhaustive Trust Center catalog coverage.

The security page separately links a public customer **[Security and Privacy Hardening](https://cursor.com/docs/enterprise/security-hardening)** guide. Its body was retrieved and relevant customer-managed model/privacy controls followed to current implementation references. It is not a substitute for the unread CAIQ candidate or evidence of a government-specific edition. Indexed subprocessors corroborate Fireworks as an inference provider, but the current GLM page supplies the explicit model mapping used in the guide. Exact per-request fallback/host coverage remains a vendor-confirmation requirement.

Direct command-line fetches timed out; current first-party document bodies were retrieved through web reading/search instead. No inaccessible page was described as a verified negative.

## Automation surface census

| Surface | Current evidence / status | Write/read decision |
|---|---|---|
| REST / GraphQL | Team and Organization API references above: model-access routes **preview**. GET configuration/providers and PUT configuration/provider/model documented. No GraphQL administration schema established by these references | Ship separate team audit and explicit-apply enforcement `api/` packs. Organization bulk and group/BYOK gaps explicit |
| CLI | [CLI overview](https://cursor.com/docs/cli/overview), current inventory and documented invocation/model choice: client execution, not centralized model policy | No fabricated `cli/` admin pack. Local selection cannot set a tenant baseline |
| SDK | [TypeScript](https://cursor.com/docs/sdk/typescript), [Python](https://cursor.com/docs/sdk/python): `Cursor.models.list()` and agent model/parameter selection. Examined references do not establish an admin-policy write SDK | Client selection not enforcement; use verified REST |
| Terraform | No first-party tenant model-policy resource/data-source inventory verified in bounded official-doc search; not a claim no community provider exists | Unverified; no invented resource |
| Config / MDM / daemon | Public hardening and deployment references: account/tenant restrictions complement policy; no local model picker preference asserted to enforce enterprise access | Reuse existing account restriction guidance; no made-up config-model key |
| SIEM | Team API writes document `team_settings` audit events; existing 10.1 exports logs | Reuse existing audit pack. No field-specific detection invented without event payload verification |

Only REST added here because it is the verified baseline write/read interface. Other planes have explicit dispositions rather than synthetic six-type coverage.

## Pack safety and limits

- Team identity bound to reviewed JSON; custom policy required before catalog access. Initial policy seeding deliberately left to dashboard review.
- Defaults and full catalog toggles explicitly reconciled; no assumption resolved disabled flags prove stored overrides.
- Dry plan default; `--apply` required, exact API origin, no redirects, curl default config disabled, API key passed on stdin, private temporary files, no key printing.
- Writes narrow before widening and preserve model parameter overrides by omitting them. Requests spaced for20/minute. No retries or automatic rollback; transport errors after writes mean unknown partial state.
- Read-back compares exact team baseline and catalog. Group union, BYOK, integration scope, provider mapping, client behavior, API entitlement and actual tenant execution remain **not live validated**.
- Offline mocked tests exercise schemas, outcomes and guards; not a claim the preview API was live-tested. No automation of live settings is performed by this research task.
