# Authoritative Sources for HTH Content

The standard for what counts as a legitimate source when deriving How to Harden guide content, and how each tier may be used. Every control, rationale claim, and hardening link in this repo traces to a source admitted under this taxonomy.

**The bright line:** a vendor's Trust Center, company "Security" marketing page, compliance-badge page, or "we take security seriously" whitepaper about the vendor's OWN infrastructure is **never** a hardening source. The test for any page: *does it give an administrator configuration steps, settings, or auditable requirements for hardening the product?* If it describes the vendor's certifications or internal practices instead, it fails.

**Tier semantics:** each tier is marked by what it may do — **ORIGINATE** a control (be the reason a control exists and the source of its steps), **SET VALUES** (determine the recommended setting), or **CORROBORATE** (supply rationale, incidents, and attack context).

---

## Tier 1 — First-Party Vendor Configuration Documentation

*May: ORIGINATE controls · authoritative on FACTS (whether a setting exists, its name, its default, its console path)*

**What qualifies:** the vendor's own admin guides, security-configuration docs, hardening guides, API/CLI references, and security-relevant release notes — on the official vendor docs domain.

**Role:** the mandatory source class. Every control must trace to at least one Tier 1 citation proving the setting exists as described; every ClickOps step and console path is transcribed from Tier 1.

**Built-in conflict of interest:** vendor docs prove what EXISTS, but vendor-recommended values favor adoption and compatibility. On strictness questions, Tier 1 does not outrank Tier 2 (see Conflict Resolution).

**Qualifies:** GitHub's "Security hardening for GitHub Actions", Vault's "Production Hardening", Google Workspace Admin Help, Zscaler's "ZIA Policy Leading Practices Guide".
**Never qualifies:** `trust.vendor.com`, `vendor.com/security` marketing pages, SOC 2 attestation pages, whitepapers about the vendor's own datacenters.

## Tier 2 — Configuration-Prescriptive Benchmark Bodies

*May: ORIGINATE controls · authoritative on VALUES (what to set)*

**Standing list:**

| Body | Use for |
|------|---------|
| CIS Benchmarks | Per-product numbered baselines. Numbering shifts between major versions — verify IDs against the current release or map by control name with a version note |
| DISA STIGs | The strictest per-product baselines; L3 targets and compliance tables |
| CISA | SCuBA baselines (ScubaGear for M365/Entra, ScubaGoggles for Google Workspace — stable machine-checkable policy IDs, preferred for compliance tables); Binding Operational Directives; KEV catalog |
| NSA | Cybersecurity Information Sheets where product-specific and configuration-prescriptive |
| ACSC (Australia) | Only where it publishes explicit control values (Essential Eight maturity settings); otherwise Tier 2b |

**Role:** set the recommended values, seed compliance mappings, and legitimately originate controls the vendor under-documents.

## Tier 2b — Framework and Advisory Bodies

*May: CORROBORATE and supply compliance mappings · may NOT originate a configuration step*

**Standing list:** NIST (800-53, 800-63, CSF, AI RMF), CSA (CCM), ENISA, BSI IT-Grundschutz, SANS (where concretely technical), OWASP (authoritative for application-layer security — ASVS, LLM Top 10 — but out of lane for SaaS tenant-admin toggles).

**Role:** control-family catalogs and abstractions by design; they justify and map controls but always need a Tier 1/2 source to instantiate an actual setting.

## Tier 3 — Expert Security-Vendor Research

*May: CORROBORATE always · ORIGINATE only where no Tier 2 baseline covers the surface, and only after Tier 1 cross-verification*

**Admission criteria (all three):** (1) demonstrated ORIGINAL product-specific research — a novel misconfiguration, attack chain, or detection they built; not vendor size, not content marketing; (2) named authors; (3) technical reproducibility — claims reference actual admin-console settings or API endpoints.

**Standing list (extend via the criteria, not vibes):** Wiz, Datadog Security Labs, Mandiant/Google Threat Intelligence, Trail of Bits, Praetorian, Unit 42, Rapid7 Research, Legit Security, Obsidian Security, Push Security, AppOmni, StepSecurity, GitGuardian, Mitiga, Varonis Threat Labs, Harmonic Security, Pillar Security, PromptArmor, Cyata.

**Where Tier 3 leads:** for new attack surfaces with no CIS/STIG/SCuBA coverage yet (AI SaaS: Claude, ChatGPT Enterprise, Copilot-class products), Tier 3 is often the only source with real content — it may originate controls there, flagged **"no benchmark equivalent yet"**, and every step still cross-verified against the vendor's real admin UI/API (Tier 1) before shipping. A Tier 3 claim alone never ships unverified.

## Tier 4 — Established Independent Researchers

*May: CORROBORATE and enrich · originate only with explicit Tier 1 verification*

**Admission criteria:** named researcher with verifiable identity and track record (CVE credits, vendor-acknowledged disclosures, recognized conference talks — Black Hat, DEF CON, BSides, fwd:cloudsec); technical specificity (exact settings, reproducible steps); published on an accountable venue. Example: dirkjanm.io (CVE-2025-55241 Entra research).

**Never:** anonymous blogs, aggregator/SEO content, citation-of-a-citation — always resolve to the primary source.

---

## Verification Rules (all tiers)

1. **Fetch or it didn't happen.** Every cited URL must be fetched successfully in the working session. Hosts that block fetchers (403s, JS-only shells) get a real-browser check before citation. Unverifiable URL = not a source. Beware SPAs that return HTTP 200 for nonexistent pages (LastPass-style): confirm real content rendered, not a shell.
2. **Currency.** Cite the canonical/current URL, not one that 301-redirects (redirects rot; vendors migrate doc hosts — e.g., Google's support.google.com/a → knowledge.workspace.google.com).
3. **Capability claims need Tier 1.** "The vendor now supports X" must be shown in vendor docs, not inferred from a Tier 3 post; if a Tier 3 finding contradicts Tier 1, re-fetch Tier 1 — the docs may have changed.
4. **Cite specifically.** Tier 2 citations carry benchmark name + version + recommendation ID; re-verify on each benchmark release.

## Conflict Resolution

**Do not average. Tier 1 wins on FACTS; Tier 2 wins on VALUES.**

- **Strictness conflicts** (e.g., Google recommends SPF `~all`; CISA SCuBA requires `-all`): the strictest defensible position from a prescriptive source is the documented recommendation; the more permissive vendor position is retained as an explicitly labeled compatibility note with the risk delta explained — never suppressed, never silently averaged.
- **Value precedence when tiers disagree:** Tier 2 (conflict-of-interest-free) > Tier 1 vendor recommendation > Tier 3 > Tier 4.
- **Fact disputes** (does the setting exist, what is it called, what is the default): Tier 1's current docs always win.
- **Stale guide vs current source:** the current verified source wins; correct the guide in place (update-hth-guide skill).

## Maintenance

Tiers 1-2/2b are standing allowlists that rarely change. Tiers 3-4 are standing lists plus per-citation review against the admission criteria; prune quarterly for dead links, acquisitions, and quality drift.

## Changelog

| Date | Changes |
|------|---------|
| 2026-08-08 | Council-refined revision: Tier 2/2b split (prescriptive bodies vs framework catalogs), originate/values/corroborate semantics per tier, facts-vs-values conflict rule with strictest-defensible precedence, Tier 3 elevation for un-benchmarked surfaces with mandatory Tier 1 cross-verification, maintenance cadence. Two council seats (formal semantics, provenance rigor) were synthesized conservatively — revisit if those areas prove contentious. |
| 2026-08-08 | Initial version — taxonomy formalized from the August 2026 full-repo audit (A–Z link audit, currency waves, trust-center purge). |
