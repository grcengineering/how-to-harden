# Inspect source coverage and limitations

Checked 2026-11-17. This is a documentation-discovery ledger, not live product validation or a claim of exhaustive tenant coverage. Sources were collected before control selection from the current first-party index and feature references. No Inspect credentials, tenant or private documents were accessed.

## Placement and product boundary

Ramp Business Corporation → standalone Inspect. [Connector security](https://docs.inspect.com/security/connectors) explicitly identifies Ramp as operating the Inspect gateway and application functions. The existing Ramp financial-application guide has a different console and permission model. This change cross-links it without restructuring it into a common-control hub or implying inherited identity policies. Searches for Inspect/Ramp ownership changes did not surface an acquisition or owner change; that is a bounded search result, not a corporate-history guarantee.

## Retrieval record

- The documentation home page returned no readable lines through web extraction. The official [llms.txt index](https://docs.inspect.com/llms.txt) and [llms-full.txt body](https://docs.inspect.com/llms-full.txt) were successfully downloaded and read. The full file contained the product areas and page bodies used below, not only navigation titles.
- The [API reference](https://docs.inspect.com/api) was read through web extraction. Its linked [OpenAPI schema](https://docs.inspect.com/api/openapi.json) was downloaded and used for exact pack methods, parameters and response contracts. Schema and fixture testing do not confirm live endpoint behavior.
- Current source content includes explicit rollout caveats, deprecated capability flags and missing audit API details. These were retained rather than filled from the separate Ramp finance API.
- Documentation paths shown below were read in the first-party full-document export on this date. Page references link back to their canonical feature pages; this is not a claim that every page was individually walked in the console.

## Source-first candidate reconciliation

| Candidate and source | Plane / conditions | Disposition |
|----------------------|--------------------|-------------|
| [Sign-in and provisioning](https://docs.inspect.com/getting-started/organization-setup#configure-sign-in): join policy and provider approval | Organization administrator; exact policy values and full provider list not enumerated | Covered 1.1; precise MFA/SCIM enforcement details remain unverified, not imported from Ramp financial docs. |
| [API keys](https://docs.inspect.com/settings/developer/api-keys): separate keys, safe storage, revocation | User credentials; key revealed once | Covered 1.2; no invented key scopes, expiry field or key-administration endpoint. |
| [Email](https://docs.inspect.com/settings/email): organization enablement, sender checks and reply audience | Organization integration; each prompt uses sender access | Covered 1.3; native recipient restrictions not documented. |
| [GitHub setup](https://docs.inspect.com/getting-started/organization-setup#configure-github-app) and [repositories](https://docs.inspect.com/settings/repositories) | GitHub App installation and Inspect repository visibility | Covered 2.1; API inventory is not installation permission proof. |
| [Agents](https://docs.inspect.com/customize/agents): prompt, skills, model, repositories, Slack and child-session reuse | Customize → Agents; only prompt history is versioned | Covered 2.2 and 2.6; API capabilities are deprecated and explicitly not security boundaries. |
| [Private connectors](https://docs.inspect.com/customize/connectors#private-connectors) | Personal credentials do not imply private visibility | Covered 2.3. Existing shared output retraction is not established. |
| [Shared connector permissions and revocation](https://docs.inspect.com/security/connectors) | Provider permissions remain final boundary; existing run can retain authenticated connection | Covered 2.4; no per-tool authorization invented. |
| [Inspect OIDC connectors](https://docs.inspect.com/customize/inspect-oidc-connectors) | Limited availability; short-lived JWT, exact issuer/audience, subject identity, optional replay prevention | Covered 2.5; no complete custom-connector schema or official JWT SDK assumed. |
| [Environment variables](https://docs.inspect.com/settings/repositories/environment-variables) | Secret/plain text; Build/Runtime; repository replaces same-key organization value entirely | Covered 3.1; values never included in fixtures/output. |
| [Shared build scripts](https://docs.inspect.com/settings/repositories/build) | Manage secrets role; selected/all repositories; build failure stops, session failure warns | Covered 3.2; snapshot credential cleanup retained. |
| [Sandbox workload identity](https://docs.inspect.com/settings/sandbox-workload-identity) | Organization identity projection; all sandbox processes can read; exact version-3 subject and lifecycle | Covered 3.3 with config emitter; no live IAM or Inspect write. AWS MCP preferred when sufficient. |
| [Private networking](https://docs.inspect.com/settings/private-networking) | Startup-time setting; tunnel-specific routes; VPN/service ACLs; no Inspect private egress logging | Covered 3.4; no custom NO_PROXY/route bypass recommendation. |
| [Approval agent](https://docs.inspect.com/pull-requests/approval-agent) | Organization switch plus default-branch policy; deny accumulates; human Required Reviews separate | Covered 4.1 with deny-by-default config. Organization policies explicitly rollout/coming-soon, not universal. |
| [Review agent](https://docs.inspect.com/pull-requests/review-agent) | Personal vs repository-wide settings; skipped-branch checks; rules.yml and head-read orchestration | Covered 4.2 and 5.2; config pack requires real skill, no fictitious model/skill. |
| [Verification agent](https://docs.inspect.com/pull-requests/verification-agent) | Exact pushed commit, local not production; pass may include skipped claims; seven-day inactivity exception | Covered 4.2; config and explicit-opt-in API invocation. 202 is not validation success. |
| [Automations](https://docs.inspect.com/automations), [GitHub](https://docs.inspect.com/automations/github), [Slack](https://docs.inspect.com/automations/slack) | Independent trigger state; all-repo expansion; conditionless Slack match; per-run state snapshot | Covered 4.3 and 4.5; disable does not stop existing runs or manual-only invocation. |
| [Spend limits](https://docs.inspect.com/settings#spend-limits) | Security-setting and review permissions; soft continuation vs hard stop | Covered 4.4; not an authorization policy. |
| [Audit logs](https://docs.inspect.com/security/audit-logs) | Administrator-only; date filters/export; undefined retention; no continuous streaming | Covered 5.1; API route/schema absent from public catalog, no fabricated collector or SIEM field mapping. |
| [Repository instructions](https://docs.inspect.com/settings/repositories#repository-instructions), [skills](https://docs.inspect.com/customize/skills) | Root precedence, .inspect/AGENTS.md override, per-file 16 KiB initial limit | Covered 5.2; prose guidance is not executable security enforcement. |
| [Sessions](https://docs.inspect.com/home/sessions), [Slack entry points](https://docs.inspect.com/settings/slack) | Shared conversation inputs and outputs; child vs shared-workspace subagents | Reconciled into 2.2–2.4 and 4.3. No undocumented global session-sharing toggle or subagent isolation policy invented. |
| [Inspect MCP](https://docs.inspect.com/settings/developer/inspect-mcp) | External client connections use Inspect credentials/access | Covered by API key/integration trust boundaries; no blanket claim that each client's policy is Inspect policy. |
| [Review providers](https://docs.inspect.com/pull-requests/review-providers) | Inbound review publication; third-party reviewer display integration | Context reviewed; excluded as a separate hardening control because publishing findings is not enforcing review correctness or branch protection. |
| Artifacts, memories, previews and deployments in public API | Content/metadata lifecycle rather than organization policy | Inventory reviewed for scope; no invented global DLP, retention or sharing policy. Endpoint availability is not a requirement to generate destructive packs. |
| Datadog, LaunchDarkly, Sentry, scheduled and Inspect-event trigger setup | Trigger-specific authentication/source scope and event conditions | Shared narrow-trigger guidance in 4.3; provider setup is not replaced by generic filters. Use linked feature-specific docs before provisioning. |

## Automation surface census

| Surface | Observed evidence and status | Included boundary |
|---------|------------------------------|-------------------|
| Terraform | No Inspect provider linked in the reviewed official index/API/MCP documentation or targeted search. | Bounded absence of documented native Inspect provider, not proof none exists. AWS relying-party trust JSON is not an Inspect Terraform provider. |
| REST / GraphQL | Public REST v2 OpenAPI is documented. No GraphQL schema surfaced in the reviewed reference/search. | Read-only repository, agent and automation evidence; targeted agent repository update and automation disable; explicit-opt-in verification start. No guessed organization setting endpoints. |
| First-party CLI | No first-party Inspect administrative CLI surfaced in the official index/API/MCP pages or targeted search. Ramp's finance CLI is a different product. | No CLI pack. See the CLI inventory row. |
| SDK | No official administrative SDK surfaced in the reviewed index/API reference. | Curl/API scripts rather than relabeling a custom Python utility as official SDK. |
| Vendor-native config | Approval YAML, review rules.yml, verification config.yml, repository instructions and documented workload trust/env examples exist. | Executable config emitters, not comment-only or prose-only pack files; real referenced skill required for review/verification. |
| SIEM | Admin CSV export is documented. Scheduled export, continuous audit streaming and built-in SIEM forwarding are expressly unavailable. | No fabricated endpoint or log-field schema. External ingestion requires an independently verified mapping. |

These are source-scoped verdicts. Undocumented/internal interfaces remain unverified, not nonexistent. The guide intentionally does not claim every control is automatable or that one API read proves enforcement.

## Trust Center and adjacent-edition search

Official [Ramp support](https://support.ramp.com/how-to-obtain-ramps-soc-1-report/) linked [trust.ramp.com](https://trust.ramp.com/). The public web extraction was readable (310 lines): Overview, Compliance, Documents with All/Public/Private filter labels, featured PCI/SOC reports, Product Security, Reports, Self-Assessments, Data Security and App Security categories. Sensitive-document access requires a request and NDA. No access request, NDA or download of restricted material was performed.

The full interactive All/Public/Private catalogs were not enumerated in this run. Featured documents and category metadata are discovery evidence, not proof of complete catalog coverage. No Inspect-specific customer implementation document was verified through that catalog. RampGov/commercial Ramp assurances cannot be transferred to Inspect. Restricted and unenumerated material remains an explicit coverage gap.

The public portal also displayed a Fireworks incident notice. It is provider-risk context, not evidence that Inspect was compromised or a documented Inspect model allowlist setting. No new hardening control is derived from that banner. Inspect's privacy-notice URL surfaced through search, but direct extraction returned a JavaScript shell; no legal terms or retention promise from it is asserted here as content-verified configuration evidence.

No account setup was needed for the accessible configuration documentation. Access to gated assurance material would require a separate vendor access request; neither account creation nor NDA acceptance was attempted.

## Benchmarks and attack-research boundary

Targeted searches combined Ramp/Inspect with CIS, DISA STIG, CISA SCuBA, NIST, NSA and ACSC domains. No product-specific benchmark was identified; irrelevant physical inspection results were excluded. This is not a claim that every unpublished or gated baseline is absent. Generic NIST SP 800-53 references supply objective mappings only, not Inspect settings.

Targeted product-specific security/vulnerability/prompt-injection searches, including Wiz, PromptArmor, Embrace The Red, Trail of Bits and Snyk domains, did not yield a verified Inspect-specific exploit or incident. Ramp's own security-scanning research describes using Inspect to find defects in Ramp code, not an Inspect compromise. Findings about Ramp Sheets or other agent products were not transplanted into Inspect. No invented incident is included.

## Remaining gaps

- No live ClickOps walkthrough, tenant API execution or policy application; no ai-validated or human-review status earned.
- Full provider/sign-in matrix, native MFA/SCIM policy, user-role management navigation and emergency recovery paths require tenant/vendor verification.
- Complete Trust Center catalog/private document review and Inspect-specific applicability remain unverified.
- No documented public audit API route/schema or fixed retention period; CSV export is not continuous collection.
- Deployment-specific rollout of OIDC connectors and organization Approval policies is unknown.
- Inventories are caller-scoped; redaction, access permissions and incomplete pagination responses must not be treated as complete org evidence.
- Native API capabilities marked deprecated do not create enforceable tool boundaries. Destination identities, repository selection and human protections still matter.
