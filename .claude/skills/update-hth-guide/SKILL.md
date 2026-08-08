---
name: update-hth-guide
description: Update an existing How to Harden guide with current, verified hardening guidance — currency research against vendor docs/CIS/CISA/expert research, error correction, and new controls — without breaking the cheat sheet or numbering. USE WHEN updating a guide, refreshing guidance, adding a control to an existing guide, fixing an inaccuracy, or running a currency pass. NOT FOR creating new guides (use create-hth-guide) or pack code (use create-code-pack).
---

# Update an HTH Guide

Bring `docs/_guides/{slug}.md` to verified-current state: find what changed in the world, correct what the guide gets wrong, add what it lacks — every claim on a fetched source.

## Phase 1 — Currency research (before touching the file)

Read the guide's control list (`### N.N` headings), `last_updated`, and changelog. Then hunt MATERIAL deltas from:

1. Vendor official security/admin docs and release notes/changelogs
2. CIS Benchmarks (check the CURRENT version — numbering shifts across majors; GitHub/GitLab live under the CIS Software Supply Chain Security benchmark, not product slugs)
3. CISA: SCuBA baselines (ScubaGoggles for Google Workspace, ScubaGear for M365/Entra), advisories, BOD directives
4. Expert research from the last ~12 months: Wiz, Datadog Security Labs, Legit Security, Obsidian, Push Security, Trail of Bits, Praetorian, Mandiant/GTIG, AppOmni, etc.
5. Incidents that changed best practice

MATERIAL = new security control/setting shipped · changed default · deprecated mechanism the guide still recommends · new attack class with a documented mitigation · authoritative baseline to map · factual error in the guide. Blog rehashes and marketing are not material.

**Verification gate:** every source URL must fetch successfully in-session (or verify in a real browser when the host blocks fetchers). A finding without a verified source is dropped, not softened. When research fan-out is large, dispatch research agents with this same gate and the pipe-delimited findings format: `guide | TYPE | title | what-to-say | verified-url | target-section`.

## Phase 2 — Apply

- **Errors first.** A guide instructing a removed setting (this repo shipped one: a control for Google's Less Secure Apps toggle, deleted by Google in 2025) or asserting a stale fact (Dependabot "has no cooldown"; Zoom tokens "14 days") gets corrected in place, keeping its number.
- **New controls** go at the END of the best-fit `## N.` section with the next free `### N.M` — never renumber existing controls (pack includes and inbound anchors depend on them). A genuinely new theme may add a new `## N.` section before the compliance/reference sections.
- Every new control follows the full anatomy in `create-hth-guide` (the cheat-parser contract section) — otherwise it silently misses the cheat sheet.
- Update notes on changed defaults go INSIDE the affected control as a bolded callout with the source link, not as loose prose.
- **No pack includes for new controls** unless a verified pack exists (create it via create-code-pack; most SaaS admin settings are ClickOps-only — say so honestly).
- If a pack automated a now-removed setting, delete the pack file too and re-run the sync — automation for a nonexistent setting is fabrication.

## Phase 3 — Bookkeeping and verification

- Changelog: new top row, date = commit date (`date +%F`), version bumped (minor for new controls, patch for corrections); frontmatter `version` + `last_updated` must match it.
- Escape any literal `{{...}}` (Vault templates, Handlebars) with `{% raw %}...{% endraw %}` — the repo linter catches this (Test 8) but only outside code spans it recognizes.
- Run the `verify-hth` skill. Its battery has caught real agent slips (missing changelog rows, unescaped Liquid) — do not skip it.
