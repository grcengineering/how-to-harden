---
name: create-hth-guide
description: Create a new How to Harden vendor guide (or a product guide inside a multi-product platform) through a prescriptive research-first process that produces a complete cheat sheet and passes the verification battery. USE WHEN creating a new guide, authoring a vendor hardening guide, adding a product guide to a platform (like Gmail under Google Workspace), or converting a placeholder/stub guide into a real one. NOT FOR updating existing guide content (use update-hth-guide) or authoring pack code (use create-code-pack).
---

# Create an HTH Guide

A step-by-step process any agent or human can follow to produce `docs/_guides/{slug}.md`. Companion standards: [SOURCES.md](../../../SOURCES.md) (what counts as a source), [AGENTS.md](../../../AGENTS.md) (formatting rules), [templates/vendor-guide-template.md](../../../templates/vendor-guide-template.md) (structure).

## Phase 1 — Source collection (do this before writing anything)

1. **Find the vendor's Tier 1 hardening documentation** (see SOURCES.md for the taxonomy). Search for: `{vendor} security best practices site:{vendor-docs-domain}`, `{vendor} hardening guide`, `{vendor} admin security settings`. You are looking for admin-facing CONFIGURATION documentation.
   - **Reject on sight:** Trust Centers, `/security` marketing pages, compliance-badge pages, whitepapers about the vendor's own infrastructure. The test: does the page give an administrator settings and steps? If it describes certifications instead, it is not a source.
2. **Check every Tier 2 body for product coverage:** CIS Benchmark (search `CIS Benchmark {product}` — note GitHub/GitLab live under the "Software Supply Chain Security" benchmark, not product slugs), DISA STIG, CISA SCuBA baseline (ScubaGear/ScubaGoggles repos), NIST/NSA/ACSC guidance. Record which exist — they seed the compliance mappings.
3. **Sweep Tier 3/4 research** from the SOURCES.md standing list for product-specific attack research and incidents from the last ~24 months. These seed rationale sections and often reveal controls the vendor under-documents. If a source you cite isn't yet on the standing list, add it there with a real fetch-verified example URL (SOURCES.md Maintenance rule) — never a placeholder, and never only cite it inline without adding the row.
4. **Fetch-verify every URL you intend to cite.** Blocked hosts (403/JS-shell) get a real-browser check. Unverifiable URL = not a source. Record verified URLs with one-line notes.
5. **Checkpoint:** you have (a) ≥1 verified Tier 1 hardening/admin doc, (b) a yes/no per Tier 2 body, (c) a short list of verified Tier 3/4 findings. If (a) is empty, STOP — a guide cannot be written without vendor configuration docs; report the gap instead of fabricating.

## Phase 2 — Control inventory design

1. List candidate controls from the Tier 1 docs: every security-relevant admin setting with its exact console path.
2. Add controls demanded by Tier 2 baselines (each SCuBA policy / CIS recommendation that maps to a real setting).
3. Add controls motivated by Tier 3/4 findings — but ONLY where Tier 1 documents an implementable setting for the mitigation.
4. For each control record: name · console path · profile level (L1 Crawl = everyone, L2 Walk = security-sensitive, L3 Run = regulated) · automation surface (Terraform/API/CLI resource IF documented, else "ClickOps only" — never invent endpoints; many admin surfaces have read-only APIs) · source URL(s).
5. Group into numbered `## N.` sections by theme (identity → protection → data/compliance → access → monitoring is the common arc; mirror `docs/_guides/gmail.md`).
6. **Checkpoint:** 8–20 controls, each with a verified source and an honest automation note. Fewer than 5 → consider whether the product belongs in a platform hub instead.

## Phase 3 — Frontmatter and scaffold

1. Copy `templates/vendor-guide-template.md` → `docs/_guides/{slug}.md`.
2. Fill frontmatter: `layout: guide`, `title`, `vendor`, `slug`, `tier`, `category` (must be in `scripts/validate-guides.sh` VALID_CATS), `description`, `version: "0.1.0"`, `maturity: "draft"`, `last_updated` (will be re-stamped at commit).
3. **If this is a product guide in a multi-product platform**, add: `platform: "Platform Name"`, `platform_slug: "{platform-slug}"`, `product: "Product Name"`. The hub guide uses `product: "Common Controls"` and holds ONLY org-wide controls; product guides open with a one-line pointer to the hub and cross-reference instead of duplicating. Reference pairs: google-workspace + gmail; anthropic-claude + claude-code.
4. Write Overview / Intended Audience / How to Use / Scope, then a linked Table of Contents.

## Phase 4 — Author each control

Write every control with this exact anatomy (it is the cheat-sheet parser contract — miss a piece and the control silently vanishes from the cheat sheet):

1. `### N.N Title` (H3, numbered)
2. `**Profile Level:** L1 (Crawl)` — leading bold key
3. Framework mini-table (CIS Controls / NIST 800-53 / SCuBA rows as applicable)
4. `#### Description` — one concrete paragraph
5. `#### Rationale` — `**Why This Matters:**` with 2-3 bullets, then `**Attack Prevented:**` one line; add `**Real-World Incidents:**` bullets where Tier 3/4 sources support them
6. `#### Prerequisites` — only when real (licenses, roles, dependencies)
7. `#### ClickOps Implementation` — numbered steps with **exact** console paths in bold, transcribed from the Tier 1 doc (never from memory)
8. `#### Code Implementation` — a pack include ONLY if a verified pack exists (create via create-code-pack); otherwise omit the heading entirely
9. `#### Validation & Testing` — how an admin proves the control is active
10. `#### Compliance Mappings` — table; never invent IDs (CIS numbering drifts between majors — map by name with a version note when unverifiable; prefer stable SCuBA policy IDs)

Sections that are NOT controls (reference tables, `### N.N.N` implementation walk-throughs) must NOT carry `**Profile Level:**` — that omission is what correctly excludes them from the cheat sheet.

## Phase 5 — Close out

1. Add the vendor to `docs/_data/doc_links.yml`: `product_docs`, `api_docs` (if real), `hardening_docs` per the SOURCES.md standard (literal hardening docs or omit; multi-source = list of `{label, url}`).
2. Compliance Quick Reference section + Appendices (edition table, references) + Changelog + Contributing per the template.
3. Re-stamp `last_updated` and the changelog date to `date +%F`.
4. **Run the `verify-hth` skill.** Do not commit without it.

## Gotchas

- Jekyll eats literal `{{...}}` (Vault templates, Handlebars) — wrap in `{% raw %}...{% endraw %}`.
- Tables without a blank line before AND after do not render.
- Google-style doc hosts migrate (support.google.com/a → knowledge.workspace.google.com); cite the post-redirect canonical URL.
- SPAs can return HTTP 200 for nonexistent pages — confirm real content rendered, not a shell.
- When vendor and benchmark disagree on strictness (SPF `~all` vs SCuBA `-all`), document BOTH with a callout — never silently pick one (SOURCES.md conflict rules).
- On Windows, repo scripts run through Git Bash (`bash scripts/...`).
