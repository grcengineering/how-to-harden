# Authoritative Sources for HTH Content

The standard for what counts as a legitimate source when deriving How to Harden guide content, and how to use each tier. Every control, rationale claim, and hardening link in this repo traces to a source admitted under this taxonomy.

**The bright line:** a vendor's Trust Center, company "Security" marketing page, compliance-badge page, or "we take security seriously" whitepaper about the vendor's OWN infrastructure is **never** a hardening source. The test for any page: *does it give an administrator configuration steps, settings, or auditable requirements for hardening the product?* If it describes the vendor's certifications or internal practices instead, it fails.

---

## Tier 1 — First-Party Vendor Hardening Documentation

**What qualifies:** the vendor's own security best-practices guides, hardening guides, admin configuration references, security-relevant release notes and changelogs, and official deployment/operations security guides.

**Role:** the source of truth for control *existence and implementation*. Every ClickOps step, console path, setting name, and API capability in a guide comes from Tier 1. If Tier 1 doesn't document a setting, the control doesn't exist — no matter who else claims it does.

**Examples that qualify:** GitHub's "Security hardening for GitHub Actions", Vault's "Production Hardening", Snowflake's authentication-policies docs, Google Workspace Admin Help articles, Zscaler's "ZIA Policy Leading Practices Guide".

**Examples that do NOT qualify:** `trust.vendor.com`, `vendor.com/security` marketing pages, SOC 2 attestation pages, a security whitepaper describing the vendor's own datacenter controls.

## Tier 2 — Authoritative Benchmark and Government Bodies

**What qualifies (standing list):**

| Body | Use for |
|------|---------|
| CIS (Center for Internet Security) | Benchmarks — per-product numbered hardening baselines. Numbering shifts between major versions: verify IDs against the current release or map by control name with a version note |
| DISA | STIGs — the strictest per-product baselines; use for L3 targets and compliance tables |
| CISA | SCuBA baselines (ScubaGear for M365/Entra, ScubaGoggles for Google Workspace) with stable machine-checkable policy IDs; Binding Operational Directives; KEV catalog; advisories |
| NIST | 800-53 control mappings, 800-63 (authentication), CSF, AI RMF |
| NSA | Cybersecurity Information Sheets and joint guidance (often with CISA) |
| ACSC (Australia) | Essential Eight and per-product hardening guidance |
| BSI (Germany) | IT-Grundschutz modules |
| CSA (Cloud Security Alliance) | CCM mappings, SaaS/cloud governance guidance |
| OWASP | ASVS, Top 10s (incl. LLM Top 10), cheat sheets — for application-adjacent controls |
| SANS | Whitepapers and posters where they carry concrete configuration guidance (skip the marketing-adjacent ones) |

**Role:** the source of truth for *baselines and compliance mappings*, and a legitimate source of controls the vendor under-documents. Prefer CISA SCuBA policy IDs in compliance tables where a baseline exists — they are stable; CIS IDs drift.

## Tier 3 — Expert Security Vendors (Product-Specific Research)

**Admission criteria (all three):** (1) original research on the *specific product* being hardened, not generic thought leadership; (2) named findings that are reproducible or vendor-acknowledged; (3) a track record of responsible disclosure.

**Standing list (extend via the criteria, not vibes):** Wiz, Datadog Security Labs, Mandiant/Google Threat Intelligence, Trail of Bits, Praetorian, Unit 42 (Palo Alto), Rapid7 Research, Legit Security, Obsidian Security, Push Security, AppOmni, StepSecurity, GitGuardian, Mitiga, Varonis Threat Labs, Harmonic Security, Pillar Security, PromptArmor, Cyata.

**Role:** the source of *attack classes, incidents, and rationale* — the "why this matters" of a control, and gap-discovery (a Tier 3 finding often reveals a missing control whose implementation you then ground in Tier 1). Tier 3 alone never supplies implementation steps.

## Tier 4 — Established Independent Researchers

**Admission criteria (any one):** CVE credit for the product; vendor-acknowledged disclosure; presented at a recognized conference (Black Hat, DEF CON, BSides, fwd:cloudsec, etc.); or repeatedly cited by Tier 2/3 sources. Example: dirkjanm.io (CVE-2025-55241 Entra research).

**Role:** same as Tier 3 (rationale, attack classes, gaps) with an extra corroboration preference: link the researcher's own writeup AND the vendor advisory/CVE record when both exist. A blog with no CVE, no acknowledgment, and no conference pedigree is not a source.

---

## Verification Rules (all tiers)

1. **Fetch or it didn't happen.** Every cited URL must be fetched successfully in the working session. Hosts that block fetchers (403s, JS-only shells) get verified in a real browser before citation. A URL that can't be verified is dropped — never cited "from memory". Beware SPAs that return HTTP 200 for nonexistent pages (LastPass-style): confirm the page renders real content, not a shell.
2. **Currency check.** Prefer the canonical/current URL over one that 301-redirects (redirects rot). If a vendor migrated doc hosts (e.g., Google's support.google.com/a → knowledge.workspace.google.com), cite the new host.
3. **Capability claims need Tier 1.** "The vendor now supports X" must be shown in vendor docs, not inferred from a Tier 3 post.

## Conflict Resolution

- **Tier 1 vs Tier 2 strictness conflicts** (e.g., Google recommends SPF `~all`; CISA SCuBA requires `-all`): document BOTH in the control — the vendor position as the noted default, the stricter benchmark position as the hardened target — with a callout naming the divergence and citing each. Never silently pick one.
- **Tier 3/4 vs Tier 1 factual conflicts:** Tier 1's *current* docs win on what the product can do; Tier 3/4 win on exploitability and risk claims until the vendor addresses them. If a Tier 3 finding contradicts Tier 1 capability claims, re-fetch Tier 1 — the docs may have changed.
- **Stale guide vs current source:** the current verified source always wins; correct the guide in place (see the update-hth-guide skill).

## Changelog

| Date | Changes |
|------|---------|
| 2026-08-08 | Initial version — taxonomy formalized from the August 2026 full-repo audit (A–Z link audit, currency waves, trust-center purge). |
