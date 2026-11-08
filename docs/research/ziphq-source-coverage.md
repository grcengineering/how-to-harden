---
layout: default
title: "ZipHQ source coverage and validation ledger"
permalink: /research/ziphq-source-coverage/
---

# ZipHQ source coverage and validation ledger

Checked: **2026-11-08**. Subject: ZipHQ, Inc.'s commercial Zip procurement platform and its supplier Vendor App. No tenants declared — Tier 0+1 only. Public and authorized authenticated product documentation was read. No buyer/supplier account was created, no tenant API records were requested, and no tenant settings, contracts or payments were changed. Documentation access is not live/OCEAN validation.

## Placement and discovery boundary

**ZipHQ, Inc. → standalone → Zip procurement.** [Current privacy notice](https://zip.com/zip-privacy-notice), [terms](https://zip.com/terms-of-use), [about page](https://zip.com/about), and [newsroom](https://zip.com/newsroom) identify the company. First-party ownership/acquisition searches covering approximately November 2024–November 2026 did not identify a completed change of control; this is a bounded finding, not a guarantee. No other ZipHQ-owned platform or guide was found in the repository.

The initial public-only pass of the [Help Center](https://docs.ziphq.com/hc/en-us) and all three displayed categories were inspected: For Vendors, Integrations, Product Training. The public [Zendesk article index](https://docs.ziphq.com/api/v2/help_center/en-us/articles.json?per_page=100) returned three articles and `next_page: null`: Vendor App sign-in, API access, and Zip Academy. This is the public article set, not the authenticated content corpus. API/SSO/SCIM/roles/permissions/audit/webhook/AI searches also followed official integration and capability pages. The [Academy article](https://docs.ziphq.com/hc/en-us/articles/33097908439323-Zip-Academy) requires a Zip session to enter training.

Customer planes considered: buyer workforce identity, buyer authorization, procurement approval/payment workflows, supplier onboarding, integrations, AI/MCP, logs, data/network configuration, and possible client/daemon/MDM surfaces. No installed-client configuration reference was discovered in the bounded public documentation; do not infer it cannot exist.

## Trust Center catalog evidence

Provenance: [Zip Trust](https://zip.com/trust) → **Security Resource Center** → [Zip verified vendor profile](https://app.ziphq.com/vendor-profile/verified/7302e692-35ff-4ade-a26a-4c375e73a409).

- The public profile route returned a JavaScript shell without a readable document listing. Catalog retrieval is **partial/unverified**.
- Categories, document titles/IDs, catalog pagination, filters, and downloadable customer hardening guides could not be enumerated. No specific document is claimed absent or read.
- The public trust pages mention audit reports and privacy resources. These are discovery leads, not customer configuration evidence. No restricted download, access request, NDA, or account signup was performed.
- The [November 2025 Information Security Policy](https://assets.ziphq.com/legal/zip-information-security-policy-11-2025.pdf) describes vendor security commitments. It was read as indexed policy content, not admitted as exact customer UI/API configuration.
- Commercial-versus-government/adjacent-edition implementation baselines remain unverified because the catalog was not readable. No government authentication hosts, flags, roles, retention promises, or certifications were transplanted.
- Closing this gap requires an authorized readable catalog and the actual applicable secure-implementation documents, not a generic SOC 2 badge or marketing page.

## Authenticated API documentation coverage

The authorized source review covered the [API reference](https://developers.ziphq.com/zipapidocs/reference/createaddress), [implementation guides](https://developers.ziphq.com/zipapidocs/docs/getting-started), [changelog](https://developers.ziphq.com/zipapidocs/changelog), and linked [OpenAPI download](https://developers.ziphq.com/zipapidocs/openapi/openapi.yaml). The download returned JSON despite its `.yaml` filename: OpenAPI info version **1.0.11**, production server `https://api.ziphq.com`, **102 paths and 159 operations**. The authenticated download does not contradict the public Help article's statement that no **public** specification is supplied.

- All **159 operation IDs** matched successfully retrieved canonical reference pages. Methods: 76 GET, 31 POST, 31 PATCH, 15 DELETE, 6 PUT. Reading a mutation's documentation did not execute it.
- All **51 implementation guides**, the changelog landing page and **three changelog entries** were retrieved. Latest entries were 2026-11-04 (item receipt/return behavior) and 2026-10-29 (invoice receipt-matching fields). These describe business-integrity functions, not new identity enforcement settings.
- The link sweep visited 298 distinct same-host documentation URLs: 215 returned 200 (159 reference pages, 51 guides, four changelog pages, one specification), two returned 301, 47 category aliases returned 302, five older `-2` links returned 404, and 29 older `-2` links returned 429. Redirects were not automatically followed; the observed Guides destination was separately reviewed. The canonical operation pages and complete specification were available, but broken/rate-limited legacy links are not claimed read.
- Normalized JSON specification snapshot SHA-256: `713e34c2285d7d2af81936212fb92aaca12befd70e12fb8aba806fd9c1abc3d1`. Raw authenticated HTML, session material, account navigation and tenant data are not committed to this repository.
- A later authorized browser review accessed the authenticated Help Center and its 17 categories, summarized below. The public three-article set was not the administration corpus. Trust Center catalog, external Academy courses, embedded videos and some attachment bodies remain separate gaps.

The **48 API tags** were reconciled independently of the proposed controls:

| Product surface | Tags reviewed | Security disposition |
|-----------------|---------------|----------------------|
| Identity and approval evidence | Users, User Groups, Roles, Delegations, Audit logs, Approvals, Queues, Workflows, Agent sessions | User/group evidence, restricted credentials, delegations, queue confidentiality and audit controls admitted. Hierarchical roles are not RBAC; approvals/agent metadata do not establish complete authorization policy. |
| Vendor governance and risk | Engagements, Risk Assessments, Risk Levels, Vendors, Vendor Contacts, Vendor Sites | Risk Orchestration/caller-access gates matter; unavailable/unauthorized is not clean. Business-risk assessment and vendor-owner roles are not tenant security settings. |
| Procurement and financial records | Requests, Agreements, Amortization Schedule, Invoices, E-Invoices, Line Items, Item Receipts, Payment Methods, Payouts, Purchase Orders, Change Orders, Vendor Credits, Saving Line Items | Content/financial data excluded from default hardening collection. `is_approved` on a payment method does not reveal the approval policy. No purchases/payments or write probes. |
| Content | Comments, Documents | Binary documents and comments are not ACL/retention inventories; excluded from default collectors. |
| Catalog | Catalog, Products, Vendor Item Groups, Vendor Items | Business inventory, not proven access-control policy. |
| Master/configuration data | Addresses, Budgets, Budget actuals, Currencies, Departments, Expense Categories, GL Accounts, Item Accounts, Locations, Lookups, Option Filter Rules, Payment Terms, Subsidiaries, Tax Codes | Hide/status/taxonomy/selection options are not assumed authorization boundaries. Multi-ERP subsidiary access is retained as conditional user evidence, not inferred globally. |

## Authenticated Help Center coverage

The authenticated [Help Center](https://docs.ziphq.com/hc/en-us) exposed **17 categories**. Category and nested-section navigation was enumerated; readers explicitly checked visible pagination. No next-page controls appeared in the reviewed category/section lists. This is a navigation census, not a claim that every body, attachment, video, or externally hosted course was exhaustively read. Only product documentation was used; no customer procurement records or tenant settings were inspected.

| Category scope | Catalog coverage | Body-review boundary |
|----------------|------------------|----------------------|
| Company Setup & Administration | All nested sections; 60 listed article pages | All 60 bodies opened and captured; key security/admin articles read in full, remaining articles reviewed through security-focused extracts. Images, customer comments, and every linked external artifact not comprehensively reviewed. |
| AI Agents, AI Assistant, Risk Orchestration | 20 + 3 + 4 listed articles; all section navigation | All 27 rendered article bodies read, plus directly linked AI settings and governance. |
| For Requesters, Sourcing, Product Training, Legal Disclosures | 14 + 27 + 2 + 3 articles; all nine sections | All 46 rendered articles read, with governance reused from the earlier pass. Combined AI/follow-up scope: 74 distinct pages. External training/videos/performance dataset not opened. |
| For Approvers, Intake-to-Procure, Procure-to-Pay, Vendor Onboarding & Management, Contract Orchestration | 368 distinct article URLs across five categories and 80 nested sections | 46 full body reads and two targeted reads, including one related article. 321 cataloged articles remained title-only; no universal full-body-review claim. |
| Integrations, Reporting & Insights, Product Updates | 72 + 25 + 27 article links across all visible sections | 32 body/security reads in this category scope, plus two full admin cross-reference reads. Wrappers and targeted release extracts are not counted as full implementation-guide reads. Unread connector/ERP attachments remain gaps. |
| For Vendors | 25 articles across all six sections | 15 security-relevant bodies fully read; ten indexed only. The public sign-in page alone was not assumed complete. |

Counts overlap between categories and directly linked articles; do not sum them as a unique global body count. The guide admits security controls only where the relevant source body was actually read. Large operational catalogs were screened for security relevance rather than copied into the public repository.

**Attached implementation guides:** the 42-page [SSO/SCIM implementation PDF](https://docs.ziphq.com/hc/en-us/article_attachments/52061657892379) was read in full; its own revision is October 17, 2025, not its wrapper's recent update date. The 10-page [Slack PDF](https://docs.ziphq.com/hc/en-us/article_attachments/57229098509851) and 12-page [Teams PDF](https://docs.ziphq.com/hc/en-us/article_attachments/56591748348827) were also read in full. The ServiceNow guide was read across nine pages, for 73 attachment pages total. The integration/reporting/release/vendor scope inventoried 149 articles: 47 in-scope body/security reads, 102 indexed-only, plus two full admin cross-references. These are documentation reads, not integration installations.

## Source-first candidate reconciliation

`Documented` means source bodies/contracts were read, not exercised in a tenant. Guide sections preserve configuration defaults, privilege requirements, edition boundaries, and negative tests.

| Candidate and plane | Body evidence | Disposition and implementation boundary |
|---------------------|---------------|-----------------------------------------|
| Buyer SSO and exceptions | [Security](https://docs.ziphq.com/hc/en-us/articles/25604138623899-Security-Page); [elevated users](https://docs.ziphq.com/hc/en-us/articles/54131008985883-Securing-Elevated-Users-with-SSO-or-MFA) | 1.1/1.5 native setup and enforcement; per-user exception turns global enforcement off. REST reads flags but cannot PATCH enforcement. Monthly SSO-or-MFA downgrade is not deactivation or phishing-resistant MFA. |
| IdP assignment and strong MFA | [Entra assignment](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/assign-user-or-group-access-portal); [authentication strength](https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-mfa-strength) | 1.2/1.3 preserve IdP-only boundary and licensed applicability. |
| SCIM lifecycle and group synchronization | [SCIM groups](https://docs.ziphq.com/hc/en-us/articles/43537045547931-Syncing-SCIM-Permission-Groups); [user transitions](https://docs.ziphq.com/hc/en-us/articles/19897886535707-Manage-User-Transitions); [field mapping](https://docs.ziphq.com/hc/en-us/articles/54272655042075-SCIM-Custom-Field-Mapping) | 1.4/4.1 no password sync, exact group-name mapping, no two-populated-group merge, failure fallback, manager/reassignment edge cases and bounded SCIM log visibility. Multi-provider conflict retained. |
| Permission policy | [Advanced groups](https://docs.ziphq.com/hc/en-us/articles/18921746955035-Permission-Settings-and-Groups); [basic groups](https://docs.ziphq.com/hc/en-us/articles/17459160359195-Permission-Groups) | 1.6 additive grants, framework-specific scopes, record-involvement exceptions, high-impact permissions. Native group inventory does not expose full policy. |
| Sessions, network and support access | [Security](https://docs.ziphq.com/hc/en-us/articles/25604138623899-Security-Page); [IP allowlists](https://docs.ziphq.com/hc/en-us/articles/46225974720795-IP-Allowlists) | 1.7–1.9 native settings; exact timeout choices/defaults not invented; last-key-IP-group deletion fails open; standing Zip Support admin access defaults on with support-delay tradeoff. |
| Sandboxes | [Environments](https://docs.ziphq.com/hc/en-us/articles/27197993336859-Setting-Up-an-Environment) | 1.10 Premier, separate access/SSO, new-environment enforcement off, shared local passwords, retained refresh connections and destructive refresh. Blanket isolation wording not trusted over detailed caveats. |
| Native MFA/recovery | [Signing In](https://docs.ziphq.com/hc/en-us/articles/42249526512923-Signing-In-to-Zip); [users](https://docs.ziphq.com/hc/en-us/articles/17459091719451-Users-and-Permissions) | 1.11 verified reset process and native/IdP distinction; no destructive real-account recovery tests. |
| Notifications | [Notifications](https://docs.ziphq.com/hc/en-us/articles/17459091797531-Notifications-Settings); Slack/Teams PDFs above | 2.1 channel overrides, field/attachment defaults and private-channel exposure. Teams private channels unsupported; no mandatory full-permission integration claim. |
| Keys and webhooks | [API Page](https://docs.ziphq.com/hc/en-us/articles/20210802709275-API-Page); [webhooks](https://developers.ziphq.com/zipapidocs/docs/webhooks) | 2.2/2.3 restricted per-record grants, expiry/IP settings, whole-object payloads, failed-endpoint auto-disable, API re-fetch. No invented key-management or HMAC API. |
| Delegations and queues | [Delegation settings](https://docs.ziphq.com/hc/en-us/articles/21484342605211-Out-of-Office-Delegations-Page); [Queues](https://docs.ziphq.com/hc/en-us/articles/19202122220315-Queues) | 2.4/2.5 self-delegation on/hierarchy restriction off, no-role bypass, queue visibility on also grants approval completion. Eight packs remain evidence only. |
| Export and warehouse disclosure | [Saved Reports](https://docs.ziphq.com/hc/en-us/articles/17441961704091-Creating-Custom-Saved-Reports); [SFTP settings](https://docs.ziphq.com/hc/en-us/articles/49955438054299-Imports-and-Exports-Page); [warehouse sharing](https://docs.ziphq.com/hc/en-us/articles/31336577028123-Data-Warehouse-Sharing) | 2.6 recipient-permission bypass, editor sharing, unencrypted email CSV, optional fingerprint/PGP, downstream warehouse grants. No fabricated inheritance of UI permissions. |
| Customer key custody | [EKM](https://docs.ziphq.com/hc/en-us/articles/53342372030491-Enterprise-Key-Management-Onboarding) | 2.7 optional AWS multi-region keys, minimum cross-account crypto grant, per-replica review, designated onboarder/legal gates, independent CloudTrail. AWS CLI is not a Zip CLI; no mislabeled pack. |
| Supplier identity and joining | [Vendor App sign-in](https://docs.ziphq.com/hc/en-us/articles/17459154258715-Signing-In-to-the-Zip-Vendor-App) | 3.1–3.3 supplier-only MFA, domain/joining exceptions, administrative groups and profile sharing; buyer cannot administer supplier identities as workforce records. Later Domain permissions path now verified; mismatch is warning/limited access, not universal denial. |
| Auditing | [Audit Readiness](https://docs.ziphq.com/hc/en-us/articles/17459193825435-Audit-Readiness); [event API](https://developers.ziphq.com/zipapidocs/reference/queryauditlogs) | 4.2 metadata/count minimization and UI grant/membership exports. Entitlement language differs; no retention/SIEM guarantee. |
| Approval integrity | [Approvals](https://docs.ziphq.com/hc/en-us/articles/17459136461851-Approvals); [November updates](https://docs.ziphq.com/hc/en-us/articles/57263347793947-November-2026-Product-Updates) | 5.1 default self-approval/prior-step gaps, no-login rollout, required tasks. Test actor/routing behavior, not only assignee fields. |
| Payment safeguards | [Payment Method Settings](https://docs.ziphq.com/hc/en-us/articles/17459152993179-Payment-Method-Settings-Page); [payments workflow](https://docs.ziphq.com/hc/en-us/articles/17442001430171) | 5.2/5.3 maker-checker off by default, required notification queue, imported-invoice bypass and missing requester, nonblocking bank/risk indicators. |
| Document and external ACLs | [Google Docs review](https://docs.ziphq.com/hc/en-us/articles/55686126397339-Contract-Orchestration-Reviewing-with-Google-Docs); [vendor email](https://docs.ziphq.com/hc/en-us/articles/47943247989403-Contract-Orchestration-How-to-Email-Vendors-from-Zip) | 5.4 external writer grants are additive and not revoked by removing request participants; broad email defaults and recipient review. Do not recommend disabling Word Protected View. |
| Workflow change and portals | [Versioning](https://docs.ziphq.com/hc/en-us/articles/44969980445595-Workflow-Versioning); [Workflow Settings](https://docs.ziphq.com/hc/en-us/articles/17459136745243-Workflow-Settings) | 5.5 safe change review, version-lock limits and portal lock. Test requests can send real webhooks/integration actions. |
| AI configuration and data | [Superagents](https://docs.ziphq.com/hc/en-us/articles/56539139834139-Superagent-Configuration-Guide); [Inbox AI](https://docs.ziphq.com/hc/en-us/articles/53717456493467-Inbox-AI-Agent); [MCP](https://docs.ziphq.com/hc/en-us/articles/51721321856539-Zip-MCP) | 6.1–6.4 separate traditional/new agent policies, all-user Chat, transcript and context exposure, action/plan approvals, recipient bypass. Outbound MCP is read-only OAuth, not Superagent action connectors. |
| RFx, fields and risk review | [RFx template](https://docs.ziphq.com/hc/en-us/articles/19012195466139-Creating-an-RFx-Template); [conditional fields](https://docs.ziphq.com/hc/en-us/articles/43912307589659-Conditionally-Hide-or-Require-Fields); [scheduled reviews](https://docs.ziphq.com/hc/en-us/articles/17459120089371-Vendor-Record-Scheduled-Reviews) | Supporting workflow/data cautions: default survey editors and audience, advisory/late-finalization requirements, completion-based review recurrence and canceled reviews for inactive/banned/deleted vendors. Ordinary taxonomy/branding is out of hardening scope. |
| Client/daemon/MDM and vendor creation restriction | API guide index/public organization; [vendor integration](https://developers.ziphq.com/zipapidocs/docs/third-party-erp-integration-vendors) | No native client-policy contract established. Manual vendor-creation restriction is CSM-mediated with exact setting unverified; retained as a gap, not an invented menu. |

## Contract conflicts and conservative handling

- **Authentication/version:** [Versioning](https://developers.ziphq.com/zipapidocs/docs/versioning) calls 2024-06-06 latest; the specification describes OAuth bearer as required from 2026-07-01, but does not expose an OAuth token endpoint or provisioning procedure. Packs explicitly pin documented **legacy API-key mode** (2024-06-06), never claim latest compatibility, and require tenant support confirmation before use. No credential exchange/creation is automated.
- **Permissions versus hierarchy:** permission groups are additive grants; hierarchical roles describe approval amounts/titles; beta vendor-owner roles at `/vendors/roles` are a third concept. No name-based administrator inference. Current group PATCH only changes description; older broad “no modification” wording is not repeated as a universal API absence.
- **User population:** the `deactivated` parameter exists but its omitted default is not established. Collectors label results as observed users only and do not assume omission returns all users. Complete-roster reconciliation remains a separate administrator review. Missing flags/membership arrays are unknown, not false/empty.
- **Audit:** `total=10000` is a lower bound. Cursor exhaustion, not total, determines collection completion. The prose guide lists record-specific filters absent from the specification; initial code uses verified common fields only. The `data` object is incomplete for some event types. Default evidence omits `api_key`, user identity/IP, descriptions and arbitrary record data.
- **Actor attribution:** USER/MCP/SUPER_AGENT/API_KEY/SYSTEM is a resolved actor classification. An MCP-channel event with a visible human creator resolves as USER; actor_type=MCP cannot enumerate all MCP traffic.
- **Webhooks:** main webhook guide documents invoice.approved/invoice.coded while Getting Started mentions invoice.updated; select the events actually offered by the tenant and do not assert a closed universal list. approval.updated excludes bill/payment approval-status changes. Signing, replay controls, delivery ordering/retry and retention guarantees remain unverified.
- **Delegations:** prose contains an inconsistent “start of day (23:59:59)” phrase. Collectors use returned epoch-second starts_at/ends_at and do not implement the ambiguous scheduling text. is_active=true includes active and upcoming. 405 is a feature gate, not empty success.
- **Queues:** no global list operation; explicit queue IDs define the collector's scope. Null flags or absent policies are unknown. Assignment-logic descriptions conflict between fields (the specific-member value differs); collectors do not reinterpret or modify the setting.

- **Native permission generations:** advanced Help permits removing Default after another group is assigned; older API guidance says the UI cannot remove it. Both are retained as a framework/version distinction requiring tenant verification. CSV imports add memberships; API group_ids replaces them.
- **Multi-provider SCIM:** October 2026 release notes and field-mapping docs describe provider-specific SCIM, while Security Page still warns that multiple providers support SAML only. No silent reconciliation; confirm enablement and provider ownership with Zip.
- **IP limits:** Security Page says 20 entries per group and dedicated IP article says 150. No fixed capacity is used in a pack or universal implementation claim.
- **Environment copying:** detailed App Studio sections distinguish creation from refresh and retain organization-owned connections on refresh, while summary isolation/secret-copy statements conflict. Verify actual connections; never assume a test request cannot reach a live system.
- **AI generations:** Teams availability and direct context attachment differ between Superagent articles; older Intake AI no-history wording does not override current saved/transcript-access behavior. AI-vendor-description display off does not disable enrichment; model-improvement opt-in default is unstated.
- **Supplier sharing:** sharing article contradicts initial public-profile visibility. Explicitly set the required audience. Existing-customer invitation behavior also differs between domain-joining articles; test that separate path. One recipient's NDA acceptance can satisfy the entire invite batch.
- **Sourcing:** two visibility toggles appear to have swapped prose descriptions. Their exact enforcement needs tenant testing; do not assert blind-review semantics from labels alone.
- **Key custody:** published sample key-policy JSON contains comments/trailing commas and is illustrative, not directly valid JSON. Exact data coverage, all effective access and production recovery need customer/Zip verification.

## Automation surface census

All packs are read-only and return review-required evidence. Enforcement and evidence collection are distinguished; a read result never certifies policy or grants permission to modify a tenant.

| Surface | Native evidence and disposition | IdP boundary |
|---------|---------------------------------|--------------|
| Terraform resources and data sources | No verified native provider contract in the source set; registry retrieval was incomplete. Not asserted absent. | General supported Entra provider work belongs in its guide. |
| REST and GraphQL | Full current REST specification reviewed. Users, groups, delegation, queue and audit evidence used; relevant write side effects explicitly excluded from these collectors. No native GraphQL schema verified. | Three documented Microsoft Graph v1.0 GET collectors retained. |
| First-party CLI | No official admin CLI contract in the 51 guides, API reference or public repository listing. Inventory remains Unverified. | Entra/Graph tools are not a Zip CLI. |
| Official SDK | Language snippets in ReadMe do not establish a vendor-maintained SDK. No native SDK package/version contract verified. | Graph SDK existence is not denied; raw REST is the small collector dependency baseline. |
| Vendor-native configuration | No exportable security-policy/client/daemon config format established. JSON record bodies are API payloads, not native configuration-as-code. | No offline questionnaire or invented Zip policy file. |
| SIEM/Sigma | Native event schemas and event types now documented. No destination mapping/deployed parser verified, so no fictional index/table or production-ready detection claim. | Entra provisioning telemetry remains a separate source. |

**Counts:** thirty-two numbered controls; eight directly wired packs (three Entra and five native REST) cover eight sections. Section 4.1 reuses 1.4. API-key/webhook settings are evidenced ClickOps controls, not fake API-management scripts. Help-based settings with no operation in the complete REST census use documented ClickOps. Other native automation surfaces remain explicit gaps. A single transport type is not an exhaustive automation claim.

| Pack | Verified operation and evidence | Privilege/applicability boundary |
|------|--------------------------------|--------------------------------|
| 1.01 | [GET servicePrincipal](https://learn.microsoft.com/en-us/graph/api/serviceprincipal-get?view=graph-rest-1.0) | Entra Application.Read.All; SAML evidence only |
| 1.02 | [GET appRoleAssignedTo](https://learn.microsoft.com/en-us/graph/api/serviceprincipal-list-approleassignedto?view=graph-rest-1.0) | Entra Application.Read.All; principal-type counts |
| 1.04 | [GET synchronization jobs](https://learn.microsoft.com/en-us/graph/api/synchronization-synchronization-list-jobs?view=graph-rest-1.0) | Delegated Synchronization.Read.All; already-consented application equivalent supported; no write permission added |
| 1.05 | GET /users | Existing restricted key with necessary user read access; flags/unknowns, no SSO enforcement |
| 1.06 | GET /users | Membership evidence only; underlying group grants not exposed |
| 2.04 | GET /delegations?is_active=true | Feature enabled; active/upcoming population only; no routing changes |
| 2.05 | GET /queues/{queueId} | Explicit approved queue UUID; not global discovery; counts/nullable flags only |
| 4.02 | GET /event_logs with created_after/created_before | Premier, read-only audit access, finite window, sensitive fields excluded |

The key-administration guide names **Read only**, **Read and write**, and blank/no access, but does not enumerate every record-dropdown label or machine-readable read scope. Do not fabricate `users.read` or similar scope names. National-cloud or alternate regional production API hosts were not verified.

## Benchmark and threat-research sweep

Searches used `ZipHQ` and `Zip procurement` with the official CIS, DISA, CISA/SCuBA, NSA, ACSC and NIST domains. No product-specific configuration baseline was identified. The general [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) supports framework mappings, not invented product settings. These are bounded search findings, not certified exhaustive catalog absences.

The SOURCES.md Tier 3/4 standing list was searched in domain groups for ZipHQ vulnerability/breach/configuration research: Wiz, Datadog Security Labs, Mandiant/Google, Trail of Bits, Legit, Snyk Labs, PromptArmor, Cyata, Pluto, Harmonic, Pillar, StepSecurity, Obsidian, Push, Unit 42, Rapid7, Praetorian, AppOmni, GitGuardian, Mitiga, Varonis, Zenity, Check Point, Radware, BeyondTrust, Tenable, Adversa, NeuralTrust, Brave, Dirk-jan Mollema, Embrace The Red, Simon Willison, and Krebs. No original product-specific technical report meeting the admission rules was identified in those searches. Unrelated procurement advertising and partner how-to pages were excluded. No incident claim was invented or attached to Zip by analogy.

## Access options for gated documentation

The public [request-demo flow](https://zip.com/request-demo) is sales-led; [AP automation pricing](https://zip.com/solutions/ap-automation) directs prospects to sales. Official-domain searches did not identify a verified self-service freemium account, trial provisioning flow, paid checkout, or personal-credit-card acceptance policy. This is an unverified access option, not a claim that trials or personal cards are categorically forbidden.

Zip's [privacy notice](https://zip.com/zip-privacy-notice) targets enterprise organizations/representatives rather than personal/household use. A personal card used for legitimate business procurement is a separate question and remains unverified. The [product walkthrough](https://zip.com/walkthroughs/zip-intake-to-procure) is not evidence of a provisioned tenant. A supplier account requires an invitation and does not establish entitlement to buyer API/admin documentation.

The [API access article](https://docs.ziphq.com/hc/en-us/articles/49398321531675-How-to-Access-API-Documentation) documents two supported routes for a reviewer: a customer-provided read-only Zip account, or relevant excerpts requested through the customer's Zip contact. This update used authorized authenticated product documentation; no raw restricted documents or tenant details are published. A next access inquiry should explicitly ask about an evaluation tenant, documentation entitlements, cost/duration, and personal-card payment for a business subscription. No inquiry, signup, purchase, or contract acceptance was performed in this research.

## Validation ledger

- Source review: the documented paths above are **DRIFT-CHECKED-ONLY**, never VERIFIED-LIVE.
- Native API contracts were **DRIFT-CHECKED-ONLY** against all current operations and guides. Help administration and MCP setup are documentation-backed. External Academy, incomplete Trust Center catalog, unread operational articles/attachments, documentation conflicts and actual tenant behavior remain unverified.
- Live buyer/IdP/supplier proof: **SKIPPED — no tenants declared**. No authentication changes, assignments, provisioning actions, real notifications, account enrollment, or data exports were attempted.
- OCEAN conformance: **SKIPPED — no OCEAN checkout or tenant declared**. No new deprecated `controls/*.yaml` definitions were created.
- Local structural checks: `validate-guides.sh` passed with zero warnings; `validate-packs.sh --touched` passed. Parser/anatomy checks confirmed 32 complete, unique controls, eight resolved pack includes, preserved original control IDs, zero guide fences, and matching version/date/maturity bookkeeping.
- Offline execution: all six Entra test groups and eight native Zip test groups passed, and all eight Bash packs passed `bash -n`. These mocked fixtures do not prove live authentication or tenant response behavior.
- Full pack-corpus validation still reports five pre-existing failure groups outside Zip: two section/type collisions, separate HashiCorp Vault and Docker Hub shell syntax failures, 11 extension/type violations, and one Azure DevOps pack with no executable content. The branch gate attributes no failure to Zip. The API-only coverage warning remains visible: eight of 32 controls have packs; the automation census records why unsupported surfaces were not invented.
- Jekyll build and rendered browser/cheat-sheet proof: **SKIPPED — Ruby/Bundler unavailable locally and no deployment**. Structural checks do not substitute for rendering. Generated pack YAML retains the sync script's indentation on blank lines; hand-authored changes pass whitespace checks.
- These checks do not earn `ai-validated` or human-review status. Publication and remote CI are separate from local checks.
- Post-deployment cheat-sheet check: deferred until maintainers merge/deploy. Draft PR publication is not deployment.
