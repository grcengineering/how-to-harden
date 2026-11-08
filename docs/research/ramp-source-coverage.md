# Ramp source coverage and automation census

Checked 2026-11-08. This is documentation research, not a live-tenant assessment. The candidate observations below were collected from source reading, then reconciled to the guide; pack coverage is a separate measure. No account, credential, connection, payment, policy, or Trust access request was created.

## Scope and retrieval

Product: commercial Ramp, published by Ramp Business Corporation. The [official security page](https://ramp.com/security) establishes the first-party link to [trust.ramp.com](https://trust.ramp.com/). No Ramp platform hub or sibling guide existed at the starting repository revision. RampGov is a **distinct** offering, not an equivalent configuration baseline. Router, Sheets, and experimental agent features are considered as adjacent discovery leads, not silently incorporated as the same product.

Sources were read with public web extraction, official plain-text developer exports and OpenAPI, and a rendered browser for the Trust Center and sandbox request form. Developer HTML pages are JavaScript shells: the vendor's own [machine-readable index](https://docs.ramp.com/llms.txt) instructs readers to use `/llms-guides/<slug>.txt` and `/llms-api.txt`. The combined [full export](https://docs.ramp.com/llms-full.txt) and [OpenAPI](https://docs.ramp.com/openapi/developer-api.json) supplied workflow and schema evidence. Successful HTML status alone was not accepted as content verification.

Retrieved artifact fingerprints, SHA-256:

| Artifact | Observation | Digest |
|---|---|---|
| llms.txt | Official guide/reference index, including CLI, MCP, agent payments, identity lifecycle, cards, funds, receipt integrations, webhooks, and changelog | 462f37f51e232492dc68760334ca01519f8969bdc3e394db3948152545456aff |
| llms-full.txt | Combined workflow and API reference text; exact origin, token, provisioning, payment-method, and webhook conditions read | d72de09a612fb132d69451c4dade23dd99882323d13e898c7b25b5d0b59a18da |
| developer-api.json | 189 paths; production server https://api.ramp.com; paths, scopes, response properties, pagination, and event enums inspected | 29571a47002f5d08d5c7686a31551bb9b66a6c40f06b66597b3f1f5b26d35808 |

These fingerprints identify the research inputs, not immutable vendor URLs or live validation. Full copyrighted exports and restricted documents are not committed.

## Source-first candidate ledger

All rows below were checked on 2026-11-08. Support-page rows were read as public article content. Developer rows were read in the official full text and cross-checked with OpenAPI where they describe API handles. Trust rows use the rendered content and catalog record below.

| Candidate and precise source section | Plane | Conditions and observed behavior | Disposition and evidence |
|---|---|---|---|
| [SSO setup and Login methods](https://support.ramp.com/setting-up-single-sign-on-sso-and-login-controls-in-ramp/); [Exceptions](https://support.ramp.com/managing-login-controls-in-ramp/); [SAML troubleshooting](https://support.ramp.com/troubleshooting-sso-sign-in-issues/) | Admin / IdP | Company security → Account access → Configure. Per-role methods and exceptions; Guest password cannot be disabled. SP-initiated SAML only; locked-out admin uses Support. | Covered 1.1, including pilot and recovery. No fabricated bypass or SAML-MFA assumption. |
| [MFA overview](https://support.ramp.com/multi-factor-authentication-mfa-overview/), strict MFA and authenticator sections | User / IdP | Password on untrusted devices requires MFA; Google conditional; SAML relies on IdP. Strict mode restricts fallback. Five authenticator registrations. | Covered 1.2. Exact administrator strict-mode toggle remains unverified, explicitly not invented. |
| [Passkey setup and limitations](https://support.ramp.com/logging-in-with-passkeys/) | User client / web | Web enrollment, supported device/security key, maximum six passkeys; additional MFA needed for step-up. | Covered 1.2; no claim enrollment proves an administrator-enforced tenant mandate. |
| [Base/additional roles](https://support.ramp.com/user-roles-overview/); [customizable permissions](https://support.ramp.com/customizing-roles-and-permissions/); [custom roles](https://support.ramp.com/creating-a-custom-role/) | Admin | Plus customization; permissions accumulate. Some implied permissions cannot be disabled; Owner/Admin cannot be scoped like ordinary users. | Covered 1.3. API read pack intentionally does not claim effective/additive assignment coverage. |
| [SCIM settings and offboarding](https://support.ramp.com/setting-up-scim-and-managing-user-provisioning/); [deactivation](https://support.ramp.com/deactivating-and-removing-users-from-ramp/); [API lifecycle](https://docs.ramp.com/developer-api/v1/user-lifecycle) | IdP / admin / API | Okta, Entra, Rippling; authoritative IdP fields; manager mapping can elevate role. Deactivate blocks access/spend but does not terminate cards/funds or reassign workflows. Separate auto-termination behavior. | Covered 1.4. Explicit suspended-user read inventory; no unsafe deactivation loop. Trust shorthand “delete” does not override the detailed support lifecycle. |
| [Unified login](https://support.ramp.com/unified-login/); [new sign-in notifications](https://support.ramp.com/new-sign-in-notifications/) | Personal session / recovery | Sign out everywhere. Google password reset does not revoke Ramp sessions. Always-on emails cover password/Google, not SAML/passkey/email OTP. | Covered 1.5; no fictitious alert-enable toggle. |
| [Guest expiration and CSV caveat](https://support.ramp.com/user-role-deep-dive-guest/) | Admin / import / API | Plus. UI/Developer API six-month default; CSV and Dashboard API do not prefill. Expiry deactivates, not terminates. | Covered 1.6, with 1.4 read verification and explicit end-date review. |
| [Authorization: grants, scopes, security](https://docs.ramp.com/developer-api/v1/authorization) | Developer app / OAuth | Client credentials are business-wide within scopes. Exact HTTPS redirects, verified random state, token protection; use expires_in. | Covered 2.1; no token generation or persistent access expansion in packs. |
| [Connected AI tools](https://support.ramp.com/managing-connected-ai-tools/); [MCP permissions](https://docs.ramp.com/developer-api/v1/ramp-mcp); [CLI](https://docs.ramp.com/developer-api/v1/cli) | Admin / user connection / CLI | Company-wide controls on all plans, per-role Plus. Connection visibility rollout-gated. CLI read-only login; role-bound, not Developer API scope choice. | Covered 2.2; existing-session CLI inventory only. Manual auth-status interpretation, no login/revoke automation. |
| [Agentic Payments: methods and authority](https://docs.ramp.com/developer-api/v1/agent-payments) | Agent / user / funds | Connected user's existing permissions. Custom-role MPP capability required; eligible Agent Cards/MPP funds differ from separately funded x402 wallet. Standalone agents limited early access. | Covered in 2.2 and 3.1, plus role governance 1.3. No wallet setup, financial transaction, credential issuance, or assumption that card limits constrain x402. |
| [Alpha SDK README and generated agent source](https://github.com/ramp-public/ramp-python/tree/21dcf421a7fa0754f77f4ca532ccbdd91f0db21b), agent lifecycle and wallet policy | Agent / SDK | Source-available 0.1.0 Alpha. Agent owner/role/status/secret management; AgentWallet policy list/publish. Distinct from human MCP consent and business-scoped generic client. | Conditional owner/role/lifecycle review covered 2.2. Wallet-policy schema and approval semantics unverified; documented write capability is not claimed absent and no unsafe mutation example supplied. |
| [Accounting setup](https://support.ramp.com/integrations/set-up-accounting-integrations/); API all-connections | Admin / ERP / API | Provider-specific setup; GET all-connections is current. Legacy active-connection endpoint/status field deprecated. | Covered 2.3 with current is_active/connection_type inventory; ERP permissions remain a separate review. |
| [Employee mailbox](https://support.ramp.com/employee-mailbox-integration/), Allow employee mailbox access | Admin / user | Disabling individual inbox access does not disable company-wide integration; removed connections leave earlier receipts. | Covered 2.4; per-email opt-out API not misrepresented as a business-wide mailbox revocation. |
| [Receipt auto-capture](https://support.ramp.com/receipt-auto-capture/), merchant collection; [extension security brief](https://support.ramp.com/ramp-chrome-extension-receipt-fetching-security-brief/) | Admin / connector / installed client | Standard merchant sharing differs from stored merchant credentials; current merchant credential flow US-specific. Extension receipt scripts use local merchant session. | Covered 2.4. Do not conflate browser credential locality with cloud merchant credential storage. |
| [Webhooks: authentication, retry, event IDs](https://docs.ramp.com/developer-api/v1/webhooks) | Receiver / API | X-Ramp-Signature HMAC over exact raw bytes. Durable event-ID deduplication needed; delivery retries do not prove freshness. GET metadata has no named OAuth scope in current schema. | Covered 2.5. Inventory does not verify receiver code, replay defense, or secret rotation. |
| Trust Product Security: Phishing Protection; [extension](https://support.ramp.com/ramp-chrome-extension/); [managed Chrome installation](https://support.ramp.com/install-ramp-for-chrome-for-employees-in-google-admin/) | Installed client / device policy | Exact extension ID idefohglmnkliiadgfofeokcpjobdeik. Managed force-install enables License Intelligence tracking by default; employee opt-out available. | Covered 2.6. Inert config recipe, deliberate privacy decision, pilot and rollback. No separate phishing-enable switch invented. |
| [Card and fund controls](https://support.ramp.com/setting-up-controls-on-ramp-cards-and-funds/); [Spend Controls](https://docs.ramp.com/developer-api/v1/spend-controls) | Admin / API | Merchant/category restrictions, transaction caps, start/lock dates, shared funds. Merchant variants and policy overrides need review. | Covered 3.1. Read-only funds/programs metadata; no financial authority changes. |
| [Vendor approvals: policies, separation of duties, defaults](https://support.ramp.com/vendor-approvals/) | Vendor workflow | New/edit source-specific chains; Owner-only SoD governance. Fallback/sole Owner cases and existing objects may differ. | Covered 3.2, including independent reviewer and nonretroactive testing. |
| [Vendor Network: auto-updates and disconnect](https://support.ramp.com/ramp-vendor-network/) | Vendor network | Specific verified-ACH auto-approval setting. Shared bills can be visible before approval; disconnection preserves saved vendor details. | Covered 3.3; no claim approval blocks all data sharing. |
| [Bill approval](https://support.ramp.com/bill-pay-approvals/); [payment release](https://support.ramp.com/bill-pay-payment-release/) | AP / release policy | Approval and release distinct; Plus release. Policy-change approval requires two active editors; author cannot approve. Existing pending chains and off-Ramp/credit/direct-debit exceptions. | Covered 3.4; no test payment. |
| [Spend-request approvals and automatic approval](https://support.ramp.com/setting-up-spend-request-approvals/) | Workflow | Conditional/terminal branches, annual thresholds, owner fallback and admin-created requests. | Covered 3.5; no assumption every request traverses the default chain. |
| [Banking approvals](https://support.ramp.com/ramp-banking-approvals/) | Banking workflow | Banking enabled; transfers/automations and policy-change governance separate from card/Bill Pay. | Covered 3.6 as configuration review only; no account opening, funding, transfers or investment action. |
| [Entity restrictions and exceptions](https://support.ramp.com/managing-entity-restrictions-for-accounting-accounts-payable-and-finance-admin-roles/) | Admin / data visibility | Plus, multiple entities; immediate changes. Owner/Admin and aggregate visibility exceptions; retain at least one entity. | Covered 4.1; negative/positive visibility test required. |
| [Virtual Cards: verify origins, token handling, backend authorization](https://docs.ramp.com/developer-api/v1/virtual-cards) | Integration / embed | Exact verified HTTPS production origin; Sandbox-only localhost. Business-specific iframe. Never persist embed tokens; backend authorizes requested card. | Covered 4.2; no PAN/CVV or embed-token retrieval pack. |
| [Audit log limits](https://support.ramp.com/ramp-audit-log/); OpenAPI audit-logs/events | Admin / API | Plus; Owner/Admin; some admin events absent, including integration setup. from_date/to_date and pagination. | Covered 5.1. Five-field NDJSON projection is not a full forensic archive or retention guarantee. |
| OpenAPI event_type enumeration; audit log article | SIEM | Exact security-change strings, including login/MFA/SSO/roles/approval policy. No universal SIEM dataset/index. | Covered 5.2 with experimental Sigma and explicit ingestion mapping/false positives. |
| Trust Product Security: IT & Security Contact; [fraud-awareness](https://support.ramp.com/fraud-awareness-how-to-protect-your-ramp-account/) | Admin / response | Active contact linked to Company settings → Security; exact edit/save button labels not public. | Covered 5.3, without invented button text. |
| Trust Product Security: Login History | Personal evidence | Last 30 days at personal-settings/security/login-history. Read-only history, not a retention knob. | Covered in 1.5 validation; excluded as a separate enforcement toggle. |
| Trust Product Security: Sunshine Act | Data-use boundary | Ramp states not HIPAA compliant and must not hold/process ePHI. HCP Sunshine reporting is a separate Plus feature. | Data restriction included in scope; HCP reporting excluded as non-security functionality. |
| Trust subscribe and vulnerability reporting | Operational notification | Optional subscription; public report route app.ramp.com/disclose. | Excluded from numbered tenant enforcement controls; no registration/report submitted. |
| OpenAPI “IP allowlist updated” event; admin session/strict-MFA questions | Discovery leads | An event name is not configuration documentation. No verified native IP allowlist or session-timeout setup path in the checked references. | Unverified, not absent. Kept as explicit follow-up gaps; no guessed endpoint/control value. |

## Trust Center catalog and document boundary

Discovery chain: ramp.com/security → trust.ramp.com (SafeBase portal) → expanded Documents and All/Public/Private filters → actual document titles. Initial HTTP extraction returned the landing shell, and one direct fetch returned 403; **rendered browser inspection subsequently succeeded**. No restricted route was reconstructed, no hidden API IDs enumerated, and no account/access request or NDA accepted.

Rendered catalog: All exposed **19 titles**, Public **2**, Private **17**. No additional Documents pagination/load-more appeared after expansion. The six pages of **Updates** are not document pagination. Public categories inspected for relevant leads included Compliance, Documents, Product Security, Reports, Self-Assessments, Data Security, App Security, Legal, Access Control, Infrastructure, Endpoint Security, Network Security, Corporate Security, Policies, Security Grades, and Knowledge Base FAQ. Actual Product Security, Compliance, and Policies modal content was read. No publicly advertised structured document manifest was established; a guessed `/json` convention from another provider was not used.

| Listed document | Access/content | Applicability and disposition |
|---|---|---|
| ISO/IEC 27001 | Public metadata; certificate body not downloaded | Assurance certificate, not a customer configuration origin. |
| ISO/IEC 42001:2023 | Public metadata; certificate body not downloaded | Assurance certificate, not a customer configuration origin. |
| PCI DSS | Private; unread | Assurance lead, customer responsibilities unverified. |
| SOC 1 Type 2 Report | Private; unread | Assurance lead, customer responsibilities unverified. |
| SOC 2 Type 2 Report | Private; unread | Assurance lead, customer responsibilities unverified. |
| Ramp Customer Privacy FAQ | Private; unread | Plausible data-handling candidate, **inaccessible/unverified**, not rejected from title. |
| Certificate of Insurance (COI) | Private; unread | Insurance evidence; not used to originate settings. |
| Email Integration Security Brief | Private; unread | Plausible integration-hardening candidate, **inaccessible/unverified**. |
| Ramp AI Whitepaper | Private; unread | Plausible AI security/shared-responsibility candidate, **inaccessible/unverified**. |
| 2026 Ramp Web, Mobile and API Penetration Test Report | Private; unread | Assurance/research lead, findings/remediations unverified. |
| ISO 27001 Statement of Applicability (SOA) | Private; unread | Assurance/customer-responsibility applicability unverified. |
| Architecture Diagram | Private; unread | Architecture/shared-responsibility applicability unverified. |
| SIG Lite | Private; unread | Questionnaire, not a setting inferred from metadata. |
| CAIQ | Private; unread | Questionnaire, not a setting inferred from metadata. |
| W-9 | Private; unread | Tax form outside configuration scope. |
| 2026 Ramp Router - Penetration Test Report | Private; unread | Adjacent Router assurance; not a commercial admin baseline. |
| ISO 42001 Statement of Applicability (SOA) | Private; unread | AI assurance/shared-responsibility applicability unverified. |
| Cyber Essentials Plus | Private; unread | Assurance title, underlying recommendations unverified. |
| Certificate of Good Standing | Private; unread | Corporate legal evidence, outside configuration scope. |

The [Product Security modal](https://trust.ramp.com/?itemName=product_features&source=click) contains actual customer configuration guidance, not only badges. Read headings: Audit Logging, Bank Connections, Integrations, IT & Security Contact, Login History, Multi-Factor Authentication, Onboarding to Ramp, Phishing Protection, Role-Based Access Control, SSO Support, Sunshine Act Compliance. This is the precise `hardening_docs` destination. Its SSO/MFA/SCIM/least-privilege recommendations map to 1.1–1.4; newer support details take precedence over its provisioning shorthand. Bank linkage context is not authority to disconnect the last required banking connection.

The Compliance modal explicitly separates **RampGov** from commercial Ramp and limits it to Corporate Card and Expense Management. [Public-sector material](https://ramp.com/public-sector) corroborates FedRAMP **Ready**, GovRAMP **Ready**, and TX-RAMP **Provisional**. These are not “Authorized”; no commercial residency, government API host or control baseline is transplanted. No government customer configuration document appeared in the inspected public catalog. Public Policies summaries describe Ramp's own workforce/infrastructure/AI governance, not customer toggles, so they do not originate controls.

### Can an individual self-serve gated access?

No verified personal-credit-card checkout unlocks these documents. Distinguish product onboarding from Trust access:

- [Pricing](https://ramp.com/pricing) advertises Free and paid Plus/Enterprise, but [U.S. application requirements](https://support.ramp.com/applying-and-signing-up-for-ramp-us-based/) require a registered business (not an individual/sole proprietor), EIN, business email, U.S. address/operations, linked U.S. business bank and at least $25,000 cash, with identity/underwriting steps. Canadian businesses have a separate route; do not universalize U.S. eligibility.
- [Managing Plus](https://support.ramp.com/managing-ramp-plus/) describes a one-month trial for eligible businesses, otherwise a demo route. [Plus billing](https://support.ramp.com/ramp-plus-billing-policy/) uses a chosen bank account, automatic renewal and nonrefundable charges, not a documented personal-card subscription. No source promises Trust entitlement with Plus.
- [Developer sandbox access](https://docs.ramp.com/developer-api/v1/sandbox-access) was inspected in a real browser. The form asks for email, name, business, website, API use case and API-agreement acceptance. No payment field was visible. This proves a self-serve **request**, not instant/free guaranteed provisioning, acceptance of personal applicants, or Trust-document access. Sandbox API/UI are isolated from real financial movement, but the packs deliberately remain production read-only inventories and were not run there.
- Trust separately says request access → emailed invitation → NDA. No subscription entitlement or personal-card shortcut was found. A user-authorized access request and agreement review, not speculative purchase, is the remaining route to verify private content.

No form was submitted, agreement accepted, signup completed, credential issued, or payment made during research.

## Automation surface census

The six surfaces were checked separately. “Not found” is bounded to the stated evidence, not a product-wide absence claim. Lifecycle and capability are distinct.

| Surface | Evidence and lifecycle | Read/write decision and authored coverage |
|---|---|---|
| terraform | No native Ramp tenant-management provider found in public Registry searches for Ramp/financial platform or the official developer index. Opal's [resource](https://github.com/opalsecurity/terraform-provider-opal/blob/main/docs/resources/resource.md) / [data source](https://github.com/opalsecurity/terraform-provider-opal/blob/main/docs/data-sources/resource.md) Ramp role/fund references and [Fivetran’s Ramp connector](https://fivetran.com/docs/connectors/applications/ramp/api-configuration) are adjacent service integrations, not native SSO/MFA policy surfaces. | No Terraform pack or invented resources. Native provider capability remains not found in this search; adjacent provider authorization should be assessed in those products' own guides. |
| api | **Available:** official 189-path REST/OpenAPI catalog. Security-relevant categories include Users, Roles, Funds, Spend Programs, Accounting, Webhooks, Audit Logs, Receipt Integrations, Embedded Cards and OAuth. No GraphQL schema/reference found in the official index and bounded public search; internal/partner interfaces unverified. **Deprecated:** legacy accounting active-connection and status field. | Six read-only API packs: 1.3, 1.4, 2.3, 2.5, 3.1, 5.1. Documented write operations deliberately not automated where they change financial authority, persistent access, identity lifecycle without sufficient guards, or disclose card credentials. |
| cli | **Available/GA-Official:** ramp-public/ramp-cli and official CLI reference. Auth status, users me, read-only login, role-bound resource operations. Source commit a29141b5293c4e1ad15befc9587314b52c1b0bc6. Companion command spec inspected, not just install page. Deprecated/unsupported `--scope`; use role/access model. | 2.2 uses existing auth status and identity lookup with required rationale, explicit JSON and production target. No installation/login/logout, secret output, or payment command. Existing authorized sessions may refresh. CLI inventory row added. |
| sdk | **Source-available Alpha:** official ramp-public/ramp-python 0.1.0, commit 21dcf421a7fa0754f77f4ca532ccbdd91f0db21b, README pre-first-public-release/no PyPI package. Generated users.roles, agent_tools.users, agents lifecycle/role/secret management, and AgentWallet list/publish_policy methods exist. The generic Developer API client stays business-scoped; the SDK does not turn it into a standalone agent. | SDK is not absent or payments-only. No SDK pack: unpublished/unstable distribution, existing documented REST roles coverage, unverified wallet-policy schema/approval semantics, and agent lifecycle/secret writes not appropriate for an uncredentialed inventory task. No fake install command. |
| config | **Available:** Ramp's managed-extension instructions plus Chromium ExtensionInstallForcelist policy and Linux JSON policy deployment. No native commercial SaaS server/daemon configuration file documented in the checked index. | 2.6 inert JSONC policy example: deploy only after conversion, merge review, privacy approval and pilot. Not an automatic installer or assertion of native Ramp console enforcement. |
| siem | **Available:** Plus audit GET with documented event_type schema. No universal SIEM connector/index/table established by these docs. | 5.1 projected NDJSON feeds 5.2 experimental Sigma. Exact backend mapping and real delivery remain operator validation. No invented `db/` SQL. |

SDK source handles were read at the pinned [README](https://github.com/ramp-public/ramp-python/blob/21dcf421a7fa0754f77f4ca532ccbdd91f0db21b/README.md) and [generated agent_tools.py](https://github.com/ramp-public/ramp-python/blob/21dcf421a7fa0754f77f4ca532ccbdd91f0db21b/src/ramp/_generated/agent_tools.py): wallet policy methods lines 14777–14835, agents lifecycle/role/secret methods lines 14899–15067, roles read near line 16459. `publish_policy` is a real POST surface, but its dictionaries do not establish safe constraint values or approval semantics. This is an unresolved experimental plane, not a tenant-wide absence finding.

### API handles used and important omitted writes

All listed read handles were current, not deprecated, in the retrieved OpenAPI. Scope names are literal schema requirements; no unnamed scope was invented.

| Handle | Scope / condition | Pack or boundary |
|---|---|---|
| GET /developer/v1/users | users:read; default excludes suspended, explicit status supported | 1.3; 1.4 also requests USER_SUSPENDED; paginated |
| GET /developer/v1/roles | users:read | 1.3 custom-role definitions; not user assignment join |
| GET /developer/v1/accounting/all-connections | accounting:read | 2.3 current metadata, deprecated status omitted |
| GET /developer/v1/webhooks | OAuth bearer; no named scope in operation security array | 2.5 inventory, not receiver enforcement |
| GET /developer/v1/funds | funds:read | 3.1 restrictions; paginated |
| GET /developer/v1/spend-programs | spend_programs:read | 3.1 restrictions; paginated |
| GET /developer/v1/audit-logs/events | audit_logs:read; Ramp Plus | 5.1 explicit interval, pagination and five-field projection |
| PATCH /developer/v1/users/{user_id}/deactivate and related lifecycle writes | users:write | Documented but not automated: response cannot establish caller/effective additional-role privileges for safe protected-user exclusions. |
| POST/PATCH funds, spend-programs, payments, banking and cards | Operation-specific write scopes | Excluded from execution packs: changes financial authority or performs financial actions. Configuration review is still described. |
| Webhook create/verify/delete; OAuth token; embedded-card token and Vault operations | Operation-specific access/secret handling | Documented surface, not run or packaged as harmless inspection. |
| Receipt-integration per-email opt-out | Operation-specific permission | Not equivalent to business mailbox/merchant credential revocation; no misleading pack. |

No native SSO, MFA, session timeout, IT contact, or financial approval-policy **configuration** endpoint was found in this public OpenAPI catalog. Event enums or unrelated policy fields do not prove that such write APIs exist. The SDK/CLI/partner scope remains separately bounded above.

## Other sources, conflicts, and limits

Bounded searches covered CIS, DISA/STIG, CISA/SCuBA, NSA, NIST and ACSC with Ramp plus hardening/benchmark/secure-configuration terms. No applicable Ramp fintech baseline was found in those searches. Generic FedRAMP, Ramp Network crypto, LiveRamp and cybercrime-forum RAMP results were excluded as entity mismatches. [CIS Controls v8](https://www.cisecurity.org/controls/v8) and [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) were read for objective crosswalks, not to invent product settings or claim certification.

AppOmni, Obsidian Security and Adaptive Shield product-hardening searches did not yield applicable Ramp configuration guidance. [PromptArmor's original Ramp Sheets disclosure](https://www.promptarmor.com/resources/ramps-sheets-ai-exfiltrates-financials) describes indirect prompt injection inserting an IMAGE exfiltration formula; it reports a Ramp fix on March 16, 2026. This is adjacent-product attack context, not evidence of a currently unpatched tenant bug or of a native customer mitigation toggle. Claude-for-Excel remediation in that article is not transferred to Ramp. PromptArmor already appears in SOURCES.md, so no redundant source registration was needed. The Trust Center's 2026 PHP investigation update was not treated as evidence of a Ramp breach or a customer setting.

### Remaining research and validation gaps

- Private Trust documents, especially the email brief, AI whitepaper, privacy FAQ, architecture and customer responsibilities, remain unread. The complete accessible catalog is not complete document coverage.
- Native IP allowlist setup, administrator strict-MFA navigation, configurable session lifetime, Alpha AgentWallet policy schema/approval semantics, and partner-only APIs remain unverified.
- Exact plan/region/feature-flag behavior and UI labels require an authorized tenant. Source-reading and API-schema tests do not resolve rollout differences.
- Chrome policy application, IdP integration, payment-approval branches, webhook authentication, SIEM ingestion and all live API/CLI operations were not exercised.
- Published packs cover **9 of 23 authored controls** across four types. This ratio does not measure all possible product protections. Remaining controls have explicit ClickOps or intentionally omitted automation boundaries.

See [validation record](ramp-validation.md) for actual check results. Maturity remains `ai-drafted`; no live or human review status is earned by this research.
