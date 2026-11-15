# Anthropic Unified Claude public baseline follow-up — 2026-11-14

Scope: investigate the separately listed Unified Claude best-practices resource discovered during weekly maintenance. This is a document reconciliation, not a whole-Anthropic currency pass or live validation. The [November source inventory](anthropic-source-coverage-2026-11.md) and [Pluto reconciliation](pluto-anthropic-reconciliation-2026-11.md) cover the earlier work.

## Discovery and document identity

The official [Anthropic Trust Center](https://trust.anthropic.com/) exposes a [public catalog](https://trust.anthropic.com/json). All returned category metadata was examined for configuration candidates, including Best Practices and Whitepapers, FedRAMP, HIPAA and Other Documents. The known Vanta category/item structure was used; resource IDs were taken from that response, not guessed or enumerated. Restricted entries were not requested and no NDA, account creation or purchase was submitted.

| Resource | Content/access observation | Disposition |
|----------|----------------------------|-------------|
| Unified Claude Security Best Practices, ID `6ac6e323207f07f198a36a5b` | Catalog public/accessible; followed its actual download link. PDF cover: **Unified Claude Security Best Practices**, **v1.3.6**, **2026-11-07**, **21 pages**. SHA-256 `fa9166961a371df60109eefd309018c2db4b55dedc0f4393e56a918c5910658e`. | **Content verified.** Read all pages with Poppler text extraction and inspected the baseline table visually. Mapped to existing controls below; no tenant status earned. |
| Claude Cowork and Unified Claude Security Best Practices, ID `6aa2110030a7f2cf301af4fd` | Public body still identifies v1.3, September 17, 2026; SHA-256 `a5dd38170e51961de623a96c58562c604cf9f0332d3b5298b60dfe617cbc9fa0`. | Already reconciled in November inventory; older baseline, not a substitute for the separate November 7 document. |
| Claude for Government FedRAMP Secure Configuration Guide, ID `6ab43afba6eead3d68716b5c` | Public body identifies C4G on its government deployment, v2.1, July 16, 2026; SHA-256 `14f136620284835af0d72e3a546c3f18082da21237368e316599aad1612a8e9c`. | Existing government reconciliation retained. No government deployment defaults transplanted into commercial guides. |
| Desktop Security Overview on third-party platforms, ID `69e7ac86fabefab0a5e7605f` | Catalog marks public, but the fetched document displays a restricted-distribution notice. | **Excluded from public content use.** No implementation derived from that body; public setup references remain the source. |
| HIPAA-Ready Offering Implementation Guide and Cowork Desktop Security Architecture Overview | Catalog marks restricted with no authorized download. | **Discovered + inaccessible.** No access request or reconstructed link. |

No PDF, signed download URL, account metadata or private document content is committed. The resource IDs and hashes identify the public discovery evidence without reproducing those documents.

## Candidate reconciliation

The November 7 document discusses unified cloud execution, device bridges, connector custody, sandbox versus host tools, approval modes, retention and baseline settings. These are mapped to existing guidance rather than treated as new native posture checks:

| Candidate group | Existing guidance / remaining boundary |
|-----------------|----------------------------------------|
| Unified access and execution | Claude Enterprise 3.4; current rollout timing verified separately below. |
| Host/VM tools, folders and local MCP | Claude Enterprise 3.6–3.8; runtime/device-policy interaction still requires live testing. |
| Identity, domains and organization confinement | Anthropic hub 1.1–1.8; Enterprise 3.3/3.6. |
| Plugin scanning, connectors and approvals | Enterprise 3.1–3.5/3.8; no generic sandbox boundary inferred for installed plugin code. |
| Audit, telemetry, retention and keys | Enterprise 2.1–2.4/5.1–5.2; local, standalone-cloud and chat-linked records remain distinct. |

These mappings identify existing text, not a fresh verification of every claim or automation surface. No new setting/API/CLI handle is originated by this investigation, and no new pack or maturity mark is warranted solely by reading a PDF.

## Current-reference checks and conflicts

- **Unified rollout:** [current setup reference](https://support.claude.com/en/articles/17444462-set-up-and-manage-the-new-unified-claude-experience-for-your-enterprise-organization) explicitly documents the November 16, 2026 automatic-enable condition and preserving an explicit prior choice. Enterprise 3.4 already records that boundary; retain the current reference over the PDF's default-only table.
- **Scanning:** [current scanning reference](https://support.claude.com/en/articles/15927065-get-started-with-skill-and-plugin-scanning) documents the October 2 default change for undecided Enterprise organizations. Enterprise 3.5 already distinguishes it; do not restore the PDF's opt-in/off wording.
- **Retention:** the PDF's own introduction distinguishes unified chat-linked sessions, while its later generic cloud-retention text is broader. [Current retention](https://support.claude.com/en/articles/10440198-configure-custom-data-retention-controls-for-enterprise-plans) and the unified setup page govern those records; Enterprise 5.1 already preserves the distinction.
- **Local VM and remote-control defaults:** architecture wording varies across the PDF, and its linked [cross-device user article](https://support.claude.com/en/articles/15520349) is not a complete administrator/default contract. Keep this **unverified at the deployment/version level**, rather than making a new blanket default claim.

Retrieval: public HTTPS bodies with Chrome-compatible user agent; successful text fallbacks distinguished from initial web/curl failures. The public PDF body was available after an earlier web-tool failure. A Trust Center metadata flag alone was insufficient to admit the restricted-distribution adjacent document. This investigation makes no complete catalog-body, commercial/government equivalence or live-enforcement claim.
