---
name: create-hth-guide
description: Create a new How to Harden vendor guide (or a product guide inside a multi-product platform) through a prescriptive research-first process that produces a complete cheat sheet and passes the verification battery. USE WHEN creating a new guide, authoring a vendor hardening guide, adding a product guide to a platform (like Gmail under Google Workspace), checking which company and platform a product belongs to, or converting a placeholder/stub guide into a real one. NOT FOR updating existing guide content (use update-hth-guide) or authoring pack code (use create-code-pack).
---

# Create an HTH Guide

A step-by-step process any agent or human can follow to produce `docs/_guides/{slug}.md`. Companion standards: [SOURCES.md](../../../SOURCES.md) (what counts as a source), [AGENTS.md](../../../AGENTS.md) (formatting rules), [templates/vendor-guide-template.md](../../../templates/vendor-guide-template.md) (structure).

## Phase 0 — Place the guide: company → platform → product

Know where the guide will live before researching what goes in it. Every guide sits on a three-level chain ([AGENTS.md](../../../AGENTS.md#company--platform--product-placing-a-guide-in-a-multi-product-platform)): the **company** that owns the product, the **platform** card the homepage groups it under, and the **product** this guide hardens. Skipping this is how the site showed two OpenAI cards, and how Cursor stayed filed under "Anysphere" for two months after SpaceX bought its maker.

1. **Name the owner from a source fetched in this run:** the product's own about, legal or terms pages and newsroom, the acquirer's announcement, or a regulator filing ([SOURCES.md](../../../SOURCES.md) Verification Rule 5). Training data is the least reliable source here: an ownership change after a model's cutoff is the normal case, not the edge case.
2. **Check the last ~24 months for a change of control:** acquisitions, mergers, rebrands, spin-outs, and the parent changing its own brand (xAI became SpaceXAI). Record each as announced or closed, with its date. An announced deal does not move the guide yet; the Overview says it is pending.
3. **Look the owner up in the corpus** under its current and former names and the names of its other products:
   - `rg -l '^platform: "{Owner}"' docs/_guides/` finds an existing platform
   - `rg -il '^vendor: .*{Owner}' docs/_guides/` finds standalone guides by the same company
4. **Decide the placement** and write it down as one line, `{Company} → {Platform, or standalone} → {Product}`, with its source URL:

   | What step 3 found | Placement |
   |---|---|
   | The owner has a platform | A product guide in that platform (Phase 3 step 3) |
   | The owner has a standalone guide but no platform | A new platform. The existing guide that already holds the org-wide admin plane becomes the hub, with no control renumbered, and this guide joins it as a product. Converting an existing guide is a restructure, so the request must cover it or a maintainer must confirm it |
   | The owner has nothing else in the corpus | A standalone guide; name the owner in the Overview when it differs from the brand |

5. **A shared owner is not a shared control plane.** A product that keeps its own console, identity and contract (Ona under OpenAI) still joins its owner's platform, but its pointer and the hub's Products row both say the hub's controls do not configure it. Never imply an inheritance the product does not have.

## Phase 1 — Source collection (do this before writing anything)

1. **Find the vendor's Tier 1 hardening documentation** (see SOURCES.md for the taxonomy). Search for: `{vendor} security best practices site:{vendor-docs-domain}`, `{vendor} hardening guide`, `{vendor} admin security settings`. You are looking for admin-facing CONFIGURATION documentation.
   - **Search purpose-built Trust Centers too:** follow the [catalog/document discovery workflow](../_shared/trust-center-discovery.md), including known public structured catalogs, relevant categories/pages and adjacent product/government baselines. Read the actual documents before judging applicability.
   - Reject assurance-only marketing, badges, SOC reports and vendor-infrastructure whitepapers as configuration evidence; a verified customer secure-implementation guide hosted in a Trust Center can be Tier 1. The test is content and scope, not hostname.
2. **Check every Tier 2 body for product coverage:** CIS Benchmark (search `CIS Benchmark {product}` — note GitHub/GitLab live under the "Software Supply Chain Security" benchmark, not product slugs), DISA STIG, CISA SCuBA baseline (ScubaGear/ScubaGoggles repos), NIST/NSA/ACSC guidance. Record which exist — they seed the compliance mappings.
3. **Sweep Tier 3/4 research** from the SOURCES.md standing list for product-specific attack research and incidents from the last ~24 months. These seed rationale sections and often reveal controls the vendor under-documents. If a source you cite isn't yet on the standing list, add it there with a real fetch-verified example URL (SOURCES.md Maintenance rule) — never a placeholder, and never only cite it inline without adding the row.
4. **Sweep the vendor's AUTOMATION documentation, not only its prose.** SOURCES.md Tier 1 covers "API/CLI references" — these are first-party sources, and skipping them is what produces a guide that is accurate and unautomatable. Fetch, for real, whichever exist:
   - the **Terraform provider registry index** — the full resource list *and* the full data-source list;
   - the **REST API reference index** (endpoint categories) and the **GraphQL schema** (introspect it if a token is available);
   - the vendor's row in [`docs/research/cli-inventory.md`](../../../docs/research/cli-inventory.md) — **no row means research the vendor and add one**, not "assume no CLI";
   - SDK references, and vendor-native **config files** (agent/daemon `*.cfg`, `*.jsonc`) — for infrastructure products this is often where the real security surface lives, not in the console at all.
5. **Fetch-verify every URL you intend to cite.** Blocked hosts (403/JS-shell) get a real-browser check. Unverifiable URL = not a source. Record verified URLs with one-line notes.
6. **Discover candidates before choosing controls.** Follow the [shared source-discovery workflow](../_shared/source-discovery.md): enumerate relevant product areas and management planes, follow security-relevant feature/setup links, and keep a source-first candidate ledger. Include client/daemon and system-policy surfaces when they exist; a central policy/provider census does not cover them. Posture attributes and vendor incident explanations can reveal features the main hardening page omits.
7. **Checkpoint:** you have (a) ≥1 verified Tier 1 configuration doc, (b) an evidenced result or explicit unverified gap per Tier 2 body, (c) a short list of verified Tier 3/4 findings, (d) a status for each applicable automation surface, and **(e) source-derived candidates with scope and evidence, including the Trust Center search boundary and candidate-document dispositions**. Use the shared workflow's documented / bounded-absence / not-applicable / unverified distinctions. If (a) is empty, report the source gap instead of fabricating a guide; continue independent research where useful. Unknown evidence is not verified absence.

## Phase 2 — Control inventory design

1. Reconcile the source-first candidate ledger against the proposed controls. Include relevant product-controlled settings regardless of whether they live in a console, client, daemon or system policy. Record a documented implementation path or evidenced no-GUI verdict.
2. Add controls demanded by Tier 2 baselines (each SCuBA policy / CIS recommendation that maps to a real setting).
3. Add controls motivated by Tier 3/4 findings — but ONLY where Tier 1 documents an implementable setting for the mitigation.
4. For each control record: name · implementation path/plane · profile level (L1 Crawl = everyone, L2 Walk = security-sensitive, L3 Run = regulated, L4 Fly = maximum-assurance, rare) · **automation surfaces (plural)** · source URL(s) · platform/version/default/prerequisite conditions.

   The automation column is a **matrix, not a pick-one**. Record a verdict per surface — `terraform` (resource / data source) · `api` (REST / GraphQL) · `cli` · `sdk` · `config` · `siem` — using the evidence distinctions above. Never invent endpoints or convert an inaccessible reference to `none`. Many admin surfaces are read-only: a read-only API still supports a **verification** pack, so "read-only" is not "no automation."

   > Writing this as a single slash-separated guess — *"Terraform/API/CLI resource IF documented"* — is what this column used to say, and it invites recording the first surface that comes to mind and moving on. Buildkite's guide was authored that way: 14 controls, one surface examined, 9 Terraform packs, 5 controls with nothing, while `bk` (GA-official, admin-capable) and the whole GraphQL mutation family sat unexamined.

5. Group into numbered `## N.` sections by theme (identity → protection → data/compliance → access → monitoring is the common arc; mirror `docs/_guides/gmail.md`).
6. **Checkpoint:** each selected control has a verified source and an evidenced automation matrix; each source candidate is covered, specifically excluded, or reported as a gap/unverified area. Roughly 8–20 controls is sizing guidance, not permission to drop a relevant candidate. Fewer than 5 → consider whether the product belongs in a platform hub instead.

   A control count is not a coverage measure — it says how many things you wrote about, never how many you can automate. Before leaving this phase, state two numbers: **how many controls have at least one real automation surface**, and **how many distinct surfaces the vendor exposes**. If every control resolves to the same single surface, you have probably enumerated one surface rather than found one.

## Phase 3 — Frontmatter and scaffold

1. Copy `templates/vendor-guide-template.md` → `docs/_guides/{slug}.md`.
2. Fill frontmatter: `layout: guide`, `title`, `vendor`, `slug`, `tier`, `category` (must be in `scripts/validate-guides.sh` VALID_CATS), `description`, `version: "0.1.0"`, `maturity: ["ai-drafted"]`, `last_updated` (will be re-stamped at commit).

   **`maturity` is a LIST and a new guide holds exactly `["ai-drafted"]`.** Maturity is a matrix, not a ladder: three stages (`drafted` → `reviewed` → `validated`) × two agents (`ai` = a machine, `ni` = natural intelligence, i.e. a person), six statuses that combine rather than replace each other ([VERSIONS.md](../../../VERSIONS.md#maturity-statuses--the-matrix) defines each one). A guide this skill produces was written by a machine from documentation and has touched no tenant, which is exactly and only what `ai-drafted` asserts — however thorough the research was. Never write it as a scalar (`maturity: "ai-drafted"` fails Test 5b), never add a second status, and never write `ni-drafted` for a guide you wrote: that status belongs to a human author. Only a [`validate-hth-guide`](../validate-hth-guide/SKILL.md) run may add `ai-validated`, and only maintainers may add any `ni-*`. Do not add per-surface `status-mark.html` marks either: there is nothing yet to evidence them with.
3. **If Phase 0 placed this guide in a platform**, add `platform` and `platform_slug` copied exactly from the hub, plus `product: "Product Name"`, and set `vendor` to the product name. The hub guide uses `product: "Common Controls"` and holds ONLY org-wide controls; product guides open with a one-line pointer to the hub and cross-reference instead of duplicating. Then update the hub: add the product to its "Products in This Platform" table (and its "**Product guides:**" line, if it has one). Reference pairs: google-workspace + gmail; anthropic-claude + claude-code; chatgpt-enterprise + ona (a product with its own console).
4. Write Overview / Intended Audience / How to Use / Scope, then a linked Table of Contents.

## Phase 4 — Author each control

Write every control with this exact anatomy (it is the cheat-sheet parser contract — `**Profile Level:**` alone creates the cheat row; each other piece fills a cell, and a missing piece renders as a silent blank gap in the row):

1. `### N.N Title` (H3, numbered)
2. `**Profile Level:** L1 (Crawl)` — leading bold key. The ONLY valid labels are `L1 (Crawl)` / `L2 (Walk)` / `L3 (Run)` / `L4 (Fly)` — never the retired `Baseline`/`Hardened`/`Maximum Security` names (AGENTS.md §Profile Levels)
3. Framework mini-table (CIS Controls / NIST 800-53 / SCuBA rows as applicable)
4. `#### Description` — one concrete paragraph
5. `#### Rationale` — `**Why This Matters:**` with 2-3 bullets, then `**Attack Prevented:**` one line; add `**Real-World Incidents:**` bullets where Tier 3/4 sources support them
6. `#### Prerequisites` — only when real (licenses, roles, dependencies)
7. `#### ClickOps Implementation` — numbered steps with **exact** documented console paths in bold. For a genuinely CLI/config-only setting, keep the heading and cite the vendor's no-GUI limitation; identify a real MDM/deployment-console path only if documented. Put the supported operation in Code rather than inventing a menu or omitting the control.
8. `#### Code Implementation` — a pack include ONLY if a verified pack exists (create via create-code-pack). **If no pack exists, replace the heading with the actual evidence verdict, never with silence.** For a verified absence of a write interface, for example:

   `**Automation:** ClickOps only — {vendor} exposes no write interface for this setting ({verified-url}, {date}).`

   If documentation or access is missing, say `**Automation:** Unverified — {surface, missing evidence and precondition}` instead. Do not use the absence template for an unknown capability.

   Omitting both the pack and the verdict is not permitted (AGENTS.md Rule 4). A silent omission is indistinguishable from an oversight, so nobody can tell a genuinely ClickOps-only control from one whose surface was never checked — which is exactly how a guide reaches a third of its controls unautomated with every review passing.
9. `#### Validation & Testing` — how an admin proves the control is active
10. `#### Compliance Mappings` — table; never invent IDs (CIS numbering drifts between majors — map by name with a version note when unverifiable; prefer stable SCuBA policy IDs)

Sections that are NOT controls (reference tables, `### N.N.N` implementation walk-throughs) must NOT carry `**Profile Level:**` — that omission is what correctly excludes them from the cheat sheet.

## Phase 5 — Close out

1. Add the vendor to `docs/_data/doc_links.yml`: `product_docs`, `api_docs` (if real), `hardening_docs` per the SOURCES.md standard (literal hardening docs or omit; multi-source = list of `{label, url}`).
2. Compliance Quick Reference section + Appendices (edition table, references) + Changelog + Contributing per the template. Add the guide's row to the `VERSIONS.md` registry — regenerate from frontmatter rather than hand-typing one row.
3. Re-stamp `last_updated` and the changelog date to `date +%F`.
4. If the guide joined or formed a platform: name it under its company in README's category table, bump the hub's version with its own changelog row, and regenerate both VERSIONS.md rows.
5. **Run the `verify-hth` skill.** Do not commit without it. Its `validate-guides.sh` Test 5c fails a platform with no hub or two, a hub and product guide that do not link each other, and a company that would get two homepage cards.

## Gotchas

- Profile-level names are Crawl/Walk/Run/Fly. If any copied scaffold text still shows `L1 (Baseline)`-style labels, replace them — the guide corpus and cheat sheets use the Crawl/Walk/Run/Fly names exclusively (this drift shipped once, in the first kernel guide draft).
- Jekyll eats literal `{{...}}` (Vault templates, Handlebars) — wrap in `{% raw %}...{% endraw %}`.
- Tables without a blank line before AND after do not render.
- Google-style doc hosts migrate (support.google.com/a → knowledge.workspace.google.com); cite the post-redirect canonical URL.
- SPAs can return HTTP 200 for nonexistent pages — confirm real content rendered, not a shell.
- When vendor and benchmark disagree on strictness (SPF `~all` vs SCuBA `-all`), document BOTH with a callout — never silently pick one (SOURCES.md conflict rules).
- A finished-feeling guide is still only `ai-drafted`. The status tracks who did what, not effort or polish — a machine wrote it from documents and nothing else has happened, which is the whole claim. Adding anything here would assert an act (a live run, a human reading it) that has not occurred.
- A brand is not an owner. Cursor's site says "Cursor" and its terms say Anysphere, Inc., while SpaceX's 8-K says Anysphere is a SpaceX subsidiary. The guide is placed by the owner.
- Announced is not acquired. OpenAI announced Ona on 2026-06-11 and Ona reported the close on 2026-08-10; between those dates the honest sentence was "OpenAI has agreed to acquire Ona".
- On Windows, repo scripts run through Git Bash (`bash scripts/...`).
