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
4. **Sweep the vendor's AUTOMATION documentation, not only its prose.** SOURCES.md Tier 1 covers "API/CLI references" — these are first-party sources, and skipping them is what produces a guide that is accurate and unautomatable. Fetch, for real, whichever exist:
   - the **Terraform provider registry index** — the full resource list *and* the full data-source list;
   - the **REST API reference index** (endpoint categories) and the **GraphQL schema** (introspect it if a token is available);
   - the vendor's row in [`docs/research/cli-inventory.md`](../../../docs/research/cli-inventory.md) — **no row means research the vendor and add one**, not "assume no CLI";
   - SDK references, and vendor-native **config files** (agent/daemon `*.cfg`, `*.jsonc`) — for infrastructure products this is often where the real security surface lives, not in the console at all.
5. **Fetch-verify every URL you intend to cite.** Blocked hosts (403/JS-shell) get a real-browser check. Unverifiable URL = not a source. Record verified URLs with one-line notes.
6. **Do not stop at the first good source.** Enumerate the vendor's documentation **by product area** (identity, access, agents/runners, data, logging, integrations, billing) and confirm each area was looked at. One excellent hardening page is a starting point, never a finish line — a vendor's security surface is routinely spread across areas that no single page indexes.
7. **Checkpoint:** you have (a) ≥1 verified Tier 1 hardening/admin doc, (b) a yes/no per Tier 2 body, (c) a short list of verified Tier 3/4 findings, **(d) a fetched-or-"none, verified" answer for each of the six automation surfaces in step 4**. If (a) is empty, STOP — a guide cannot be written without vendor configuration docs; report the gap instead of fabricating. If (d) is unanswered, Phase 2's automation column will be guesswork.

## Phase 2 — Control inventory design

1. List candidate controls from the Tier 1 docs: every security-relevant admin setting with its exact console path.
2. Add controls demanded by Tier 2 baselines (each SCuBA policy / CIS recommendation that maps to a real setting).
3. Add controls motivated by Tier 3/4 findings — but ONLY where Tier 1 documents an implementable setting for the mitigation.
4. For each control record: name · console path · profile level (L1 Crawl = everyone, L2 Walk = security-sensitive, L3 Run = regulated, L4 Fly = maximum-assurance, rare) · **automation surfaces (plural)** · source URL(s).

   The automation column is a **matrix, not a pick-one**. Record a verdict per surface — `terraform` (resource / data source) · `api` (REST / GraphQL) · `cli` · `sdk` · `config` · `siem` — each either a specific documented handle or `none (verified: {url})`. Never invent endpoints. Many admin surfaces are read-only: a read-only API still supports a **verification** pack, so "read-only" is not "no automation."

   > Writing this as a single slash-separated guess — *"Terraform/API/CLI resource IF documented"* — is what this column used to say, and it invites recording the first surface that comes to mind and moving on. Buildkite's guide was authored that way: 14 controls, one surface examined, 9 Terraform packs, 5 controls with nothing, while `bk` (GA-official, admin-capable) and the whole GraphQL mutation family sat unexamined.

5. Group into numbered `## N.` sections by theme (identity → protection → data/compliance → access → monitoring is the common arc; mirror `docs/_guides/gmail.md`).
6. **Checkpoint:** 8–20 controls, each with a verified source and a **complete** automation matrix. Fewer than 5 → consider whether the product belongs in a platform hub instead.

   A control count is not a coverage measure — it says how many things you wrote about, never how many you can automate. Before leaving this phase, state two numbers: **how many controls have at least one real automation surface**, and **how many distinct surfaces the vendor exposes**. If every control resolves to the same single surface, you have probably enumerated one surface rather than found one.

## Phase 3 — Frontmatter and scaffold

1. Copy `templates/vendor-guide-template.md` → `docs/_guides/{slug}.md`.
2. Fill frontmatter: `layout: guide`, `title`, `vendor`, `slug`, `tier`, `category` (must be in `scripts/validate-guides.sh` VALID_CATS), `description`, `version: "0.1.0"`, `maturity: ["ai-drafted"]`, `last_updated` (will be re-stamped at commit).

   **`maturity` is a LIST and a new guide holds exactly `["ai-drafted"]`.** Maturity is a matrix, not a ladder: three stages (`drafted` → `reviewed` → `validated`) × two agents (`ai` = a machine, `ni` = natural intelligence, i.e. a person), six statuses that combine rather than replace each other ([VERSIONS.md](../../../VERSIONS.md#maturity-statuses--the-matrix) defines each one). A guide this skill produces was written by a machine from documentation and has touched no tenant, which is exactly and only what `ai-drafted` asserts — however thorough the research was. Never write it as a scalar (`maturity: "ai-drafted"` fails Test 5b), never add a second status, and never write `ni-drafted` for a guide you wrote: that status belongs to a human author. Only a [`validate-hth-guide`](../validate-hth-guide/SKILL.md) run may add `ai-validated`, and only maintainers may add any `ni-*`. Do not add per-surface `status-mark.html` marks either: there is nothing yet to evidence them with.
3. **If this is a product guide in a multi-product platform**, add: `platform: "Platform Name"`, `platform_slug: "{platform-slug}"`, `product: "Product Name"`. The hub guide uses `product: "Common Controls"` and holds ONLY org-wide controls; product guides open with a one-line pointer to the hub and cross-reference instead of duplicating. Reference pairs: google-workspace + gmail; anthropic-claude + claude-code.
4. Write Overview / Intended Audience / How to Use / Scope, then a linked Table of Contents.

## Phase 4 — Author each control

Write every control with this exact anatomy (it is the cheat-sheet parser contract — `**Profile Level:**` alone creates the cheat row; each other piece fills a cell, and a missing piece renders as a silent blank gap in the row):

1. `### N.N Title` (H3, numbered)
2. `**Profile Level:** L1 (Crawl)` — leading bold key. The ONLY valid labels are `L1 (Crawl)` / `L2 (Walk)` / `L3 (Run)` / `L4 (Fly)` — never the retired `Baseline`/`Hardened`/`Maximum Security` names (AGENTS.md §Profile Levels)
3. Framework mini-table (CIS Controls / NIST 800-53 / SCuBA rows as applicable)
4. `#### Description` — one concrete paragraph
5. `#### Rationale` — `**Why This Matters:**` with 2-3 bullets, then `**Attack Prevented:**` one line; add `**Real-World Incidents:**` bullets where Tier 3/4 sources support them
6. `#### Prerequisites` — only when real (licenses, roles, dependencies)
7. `#### ClickOps Implementation` — numbered steps with **exact** console paths in bold, transcribed from the Tier 1 doc (never from memory)
8. `#### Code Implementation` — a pack include ONLY if a verified pack exists (create via create-code-pack). **If no pack exists, replace the heading with an explicit verdict, never with silence:**

   `**Automation:** ClickOps only — {vendor} exposes no write interface for this setting ({verified-url}, {date}).`

   Omitting both the pack and the verdict is not permitted (AGENTS.md Rule 4). A silent omission is indistinguishable from an oversight, so nobody can tell a genuinely ClickOps-only control from one whose surface was never checked — which is exactly how a guide reaches a third of its controls unautomated with every review passing.
9. `#### Validation & Testing` — how an admin proves the control is active
10. `#### Compliance Mappings` — table; never invent IDs (CIS numbering drifts between majors — map by name with a version note when unverifiable; prefer stable SCuBA policy IDs)

Sections that are NOT controls (reference tables, `### N.N.N` implementation walk-throughs) must NOT carry `**Profile Level:**` — that omission is what correctly excludes them from the cheat sheet.

## Phase 5 — Close out

1. Add the vendor to `docs/_data/doc_links.yml`: `product_docs`, `api_docs` (if real), `hardening_docs` per the SOURCES.md standard (literal hardening docs or omit; multi-source = list of `{label, url}`).
2. Compliance Quick Reference section + Appendices (edition table, references) + Changelog + Contributing per the template. Add the guide's row to the `VERSIONS.md` registry — regenerate from frontmatter rather than hand-typing one row.
3. Re-stamp `last_updated` and the changelog date to `date +%F`.
4. **Run the `verify-hth` skill.** Do not commit without it.

## Gotchas

- Profile-level names are Crawl/Walk/Run/Fly. If any copied scaffold text still shows `L1 (Baseline)`-style labels, replace them — the guide corpus and cheat sheets use the Crawl/Walk/Run/Fly names exclusively (this drift shipped once, in the first kernel guide draft).
- Jekyll eats literal `{{...}}` (Vault templates, Handlebars) — wrap in `{% raw %}...{% endraw %}`.
- Tables without a blank line before AND after do not render.
- Google-style doc hosts migrate (support.google.com/a → knowledge.workspace.google.com); cite the post-redirect canonical URL.
- SPAs can return HTTP 200 for nonexistent pages — confirm real content rendered, not a shell.
- When vendor and benchmark disagree on strictness (SPF `~all` vs SCuBA `-all`), document BOTH with a callout — never silently pick one (SOURCES.md conflict rules).
- A finished-feeling guide is still only `ai-drafted`. The status tracks who did what, not effort or polish — a machine wrote it from documents and nothing else has happened, which is the whole claim. Adding anything here would assert an act (a live run, a human reading it) that has not occurred.
- On Windows, repo scripts run through Git Bash (`bash scripts/...`).
