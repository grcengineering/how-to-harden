# Find customer hardening guidance in vendor Trust Centers

Use this during new-guide research, full currency/coverage passes and research into a new product area, alongside [source discovery](source-discovery.md). A narrow correction stays within its affected product/control; an editorial-only edit does not require a new vendor-wide survey. A Trust Center search is a required discovery step for hardening research, not permission to change products or access settings.

## 1. Locate the portal and its catalog

Confirm the portal belongs to the vendor from its official website/docs or a verified first-party link. It may use a vendor subdomain, another official brand or a Trust Center provider. Search the vendor's Trust Center/security portal as well as the usual docs; not every vendor has one. Record the portal URL and provenance, or the bounded searches performed and `not found in this search` / `unverified`. Do not invent a portal or call one nonexistent after a failed fetch.

Open the portal's **Resources/Documents/Downloads** catalog, not just the single resource linked by a launch post. Inspect public category/filter lists and any supported pagination. Review the catalog broadly enough to find adjacent product editions, installed clients, government/regulatory deployments, shared-responsibility and secure-implementation material. A source filed under **FedRAMP**, **HIPAA**, **Deployment** or **Other documents** can be configuration guidance even when the **Best Practices** category already yielded a useful guide.

Look for *secure configuration*, *secure implementation*, *deployment/hardening guide*, *security best practices*, *customer responsibilities* and relevant product/edition names. These are discovery terms, not admission rules: a title alone proves no recommendation, and an older document can still reveal a missed control. Do not stop after the first useful PDF, a clean changelog or the product's marketing Security page.

### Structured catalogs and shells

A JS shell or empty text extraction does not establish an empty catalog. Check publicly advertised machine-readable catalogs, document manifests, rendered resource lists or a **known, evidenced public catalog route** for that portal. Use only the public read surface and its exposed parameters; do not guess private API paths, enumerate resource IDs or reconstruct restricted download links.

A verified example, **not a cross-vendor standard**, is the Vanta-hosted [Anthropic Trust Center public JSON](https://trust.anthropic.com/json), checked 2026-11-06. Its resource metadata is under `resources.categories[].items[]`, including category, title/description, resource ID, `isPublic`, `hasAccess`, `isViewOnly`, `url` and `downloadUrl`. On that portal `/json` exposes documents missed by a single filtered resource page. For a known Vanta portal this is a bounded discovery lead to re-verify, not proof that every Vanta customer exposes that route or schema. Other providers can expose different public indexes or no structured catalog. Record the observed structure instead of imposing this one.

- Distinguish a **document catalog** from asset/signature manifests, JSON-LD organization metadata, framework badges or certification-package JSON. JSON does not automatically mean a resource inventory or hardening guide.
- Enumerate metadata across the relevant categories and all pages the observed interface exposes. Preserve filters, cursor/page sequence and counts when reliable. If paging fails, totals disagree or the interface provides only a subset, report partial coverage; do not infer a complete inventory from the returned subset.
- Do not bulk-download the portal. Select plausible configuration/baseline candidates and read those documents, recording exclusions for assurance-only entries where relevant.

## 2. Read the actual document within the access boundary

Use public documents or explicitly authorized existing access only. Respect visibility, view-only and access-request indicators. Publicly visible metadata for a restricted document is a discovery lead, not permission to download it. Without explicit user authorization, do not submit access requests, contact the vendor, accept an NDA/terms or create an account/credential to close a research gap. Never bypass access controls or reconstruct restricted links by altering IDs; authorization-sensitive actions and challenges must follow the tool’s approval/handoff rules. Record what access is missing and continue independent public research. Follow the tool's access/approval rules for any fallback.

Follow the catalog's real view/download link. Verify the final body, not only the title, HTTP 200, file extension or presence of a download button. PDFs must contain readable document content; an HTML sign-in page saved as `.pdf`, cover-only preview or failed OCR remains unverified. Use an approved reader/text extraction and visual inspection when tables/images need it. Record retrieval and extraction failures separately from successful fallbacks; do not execute code embedded in a document. Do not commit credentials, signed session URLs or restricted contents to public research artifacts.

For a readable candidate, retain:

| Evidence | What to record |
|----------|----------------|
| Discovery chain | Official vendor link → portal/catalog route → category and resource ID/title → actual document/view/download |
| Retrieval | Checked date, public/authorized access, method, final URL or safe canonical reference, body/content observation; snapshot/hash for a downloaded file when useful |
| Document identity | Cover title, publisher, version/date, relevant pages/sections; distinguish document revision from upload/catalog timestamp |
| Applicability | Product/edition, commercial vs government deployment, admin/client/runtime plane, plan/platform/version, customer vs vendor responsibility |
| Candidate disposition | Actual customer requirement and supporting section; covered control/pack IDs, specific exclusion, gap or unverified area |

A catalog listing means **discovered**. Reading usable configuration content means **content verified**. Applying it to the requested product needs an **applicability decision**. Neither is live implementation validation.

## 3. Admit content and reconcile boundaries

Apply [SOURCES.md](../../../SOURCES.md) to the document's substance, not its hostname. A vendor-published secure configuration/implementation guide hosted in a Trust Center or linked delivery service can be Tier 1 when it gives customers real settings, steps or auditable requirements. Portal landing pages, badges, SOC reports, vendor-infrastructure assurances and certification-package overviews cannot originate customer configuration merely because they are authoritative or downloadable. A catalog is a discovery source, not a `hardening_docs` destination.

Keep adjacent-edition baselines in the ledger even when the requested guide is commercial. Decide which requirements transfer, which need product-specific verification and which are excluded with a reason. Government/compliance labels do not make two offerings equivalent; a package schema/ID is not evidence of completed authorization. Do not transplant government hosts, headers, role names, defaults, retention, CLI variables or recovery procedures into commercial packs. Do not expand the assignment into a new product guide without scope/authorization.

Reconcile dated PDFs with current feature/setup, API/CLI and system-policy references. Preserve real conflicts and version/edition conditions. A published baseline does not, by itself, enumerate a native posture engine's checks or supply pass/fail statuses. A settings schema or a screenshot count does not establish that mapping either.

## 4. Close discovery with evidence, not a promise of completeness

Before claiming coverage, record **both** the catalog-search boundary and each relevant document's disposition in the source-first ledger. Include the categories/pages/filters checked, structured routes used or unavailable, adjacent editions considered, actual documents read, and remaining access/content/applicability gaps. Link candidate requirements to actual guidance/packs; finding a useful document is not the final reconciliation.

Use precise outcomes: `content verified + applicable`, `content verified + excluded (scope reason)`, `discovered + inaccessible`, `retrieval failed/partial`, `applicability unverified`, or `not found in the stated search`. Unread documents remain unverified even if the rest of the task can proceed. Report relevant gaps instead of claiming no guide exists or all recommendations are covered. Public searching, fixture tests and rendered guides earn no live-validation status.

Exercise the [Trust Center behavioral cases](evals/trust-center-discovery/cases.md) when changing this workflow. Fixture/structural tests support evaluation; they do not prove that an agent will exhaust every live vendor catalog.
