# Discover controls from sources, then reconcile the guide

Use this for a new guide, a full currency/coverage pass, or research into a new product area. For a narrow correction, apply it to the affected area and state that boundary; do not turn a link fix into an unsolicited whole-product audit. Source admission still follows [SOURCES.md](../../../SOURCES.md), and scope follows [PHILOSOPHY.md](../../../PHILOSOPHY.md).

## Find the relevant management planes

A hardening page and a provider index are starting points. Read the official feature/documentation index and follow security-relevant links from the chosen sources: mitigation/setup pages, deployment references, defaults, limitations and recovery instructions. Search the official docs for uncovered areas rather than stopping at the guide's existing headings.

Check the planes the product actually has:

- Organization/admin console, identity and integration controls.
- Installed clients, agents, runners and companion daemons, including their separate command references.
- Device management, system policies/MDM and vendor-native configuration files, as well as central policy files.
- Posture/status attributes, diagnostics and logs that reveal a security capability not yet represented in the guide.
- Security-relevant release notes and vendor incident/engineering explanations that point to mitigations. Follow those leads to an admitted configuration source before originating a control.

Not every product has every plane. Record what was checked and the evidence for a scoped absence; a failed fetch is an unresolved research area. Do not treat a complete REST or Terraform inventory as a complete product security inventory.

An attribute reporting whether product identity state is protected is a discovery lead: follow it to the feature and setup documentation. Reading that attribute does not configure the protection. A generic posture control covers it only if the actual guidance addresses that requirement and its enforcement limits.

## Search vendor Trust Centers, not only docs indexes

For hardening research, follow the [Trust Center discovery workflow](trust-center-discovery.md). Locate a verified vendor portal or record the bounded unsuccessful search; inspect the public catalog and known structured indexes, relevant categories/pages and adjacent product/government baselines. Read candidate documents and record access/content/applicability separately. Do not stop at a single linked resource or reject real customer configuration guidance because of its Trust Center hostname. Catalog metadata is not configuration evidence.

## Keep a source-first candidate ledger

Record candidates while reading sources, **before** selecting the final control list. Keep the evidence with the research (for example, `docs/research/{slug}-source-coverage.md`); a compact table is sufficient. Do not generate this inventory solely by parsing the authored guide back into a source matrix.

| Candidate and precise source section | Plane | Conditions and behavior | Disposition and evidence |
|---|---|---|---|
| Security requirement or mitigation; URL/anchor | Console, client, daemon, MDM, policy, etc. | Platform/version/plan; default; prerequisites; restart/recovery; read versus write | Covered: control IDs and actual implementation; excluded: scope reason; gap: missing guidance; unverified: evidence/access missing |

Group related recommendations into one control when appropriate; one source row need not mean one control. Retain relevant candidates that cannot yet be verified instead of silently dropping them.

For each source, retain the checked date, retrieval method and a content-specific observation or snapshot reference. For Trust Center research, retain the portal → catalog → document chain and the categories/pages/filters checked; document identity and product applicability must come from the actual content. Log failed attempts and successful fallbacks distinctly. A URL in a bibliography, a page title, or HTTP 200 alone does not show that the claimed content was read. An unavailable page must not become a successful verification record through later metadata generation.

## Resolve scope and implementation honestly

- **Product setting versus generic infrastructure:** vendor-controlled protection of its own client/agent credentials, keys, sessions or identity state can be in scope even when it uses an OS keystore or TPM. Generic disk/database/host hardening remains outside scope. Decide from the control and threat, not the word “encryption.”
- **No GUI is a supported outcome:** if a current vendor reference says a setting is CLI/config/system-policy only, keep the control. Under `ClickOps Implementation`, record the evidenced absence of a native GUI and any real management-console path; put the supported operation in Code. Do not invent a console toggle.
- **Capability evidence and lifecycle are separate:** record a documented handle, a bounded verified absence, a scope-based not-applicable verdict, or an unverified gap. “Could not fetch,” “not researched” and “not found in this search” do not prove absence. Keep `available`/`beta`/`deprecated`/`removed` separately for handles that have evidence.
- **Defaults have conditions:** check platform, package variant and version history around a feature, including changes older than the guide's date. Capture prerequisites, restart/lockout/recovery effects and verification signals before recommending a change. Never enable a hardware-dependent setting merely to test it without the required authorization and recovery conditions.

## Reconcile before closing coverage

Compare the source-derived candidates with the actual guide and packs. For each candidate, require **covered**, **excluded with a specific scope reason**, **gap**, or **unverified**, with evidence. Resolve documented gaps within the authorized task; report the rest and the missing precondition. Do not expand a narrow task or imply permission to touch a live system.

For a full currency pass, do this independently of release dates and existing claims: a security feature omitted when the guide was written is an omission even if it predates `last_updated`. “No recent change” is not “nothing missing.”

Report the research boundary and candidate dispositions separately from pack coverage. “17/18 authored controls have packs,” six implementation types, successful rendering and mocked tests describe the authored corpus; none establishes that all relevant controls were discovered. Do not claim complete coverage while gaps or unverified areas remain. This reconciliation is documentation evidence and earns no live-validation or human-review status.

When changing this workflow, use the [behavioral regression cases](evals/source-discovery/cases.md). They test discovery and decisions, not whether these instructions contain particular phrases.
