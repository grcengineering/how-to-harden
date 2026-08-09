---
name: update-hth-guide
description: Update an existing How to Harden guide with current, verified hardening guidance through a prescriptive research-verify-apply process — currency research against vendor docs/CIS/CISA/expert research, error correction, and new controls — without breaking the cheat sheet or numbering. USE WHEN updating a guide, refreshing guidance, adding a control to an existing guide, fixing an inaccuracy, or running a currency pass. NOT FOR creating new guides (use create-hth-guide) or pack code (use create-code-pack).
---

# Update an HTH Guide

A step-by-step currency-and-correction process for `docs/_guides/{slug}.md`. Companion standards: [SOURCES.md](../../../SOURCES.md), [AGENTS.md](../../../AGENTS.md).

## Phase 1 — Baseline the guide

1. Read the guide's frontmatter (`version`, `last_updated`), changelog, and full control list (`### N.N` headings with their claims).
2. Note every dated or versioned claim the guide makes (token lifetimes, deprecation dates, product names, benchmark versions, plan tiers, cited URLs) — these are the highest-probability rot points.
3. **Checkpoint:** a written list of the guide's controls and its falsifiable claims.

## Phase 2 — Currency research (fetch-gated)

Hunt MATERIAL deltas per source tier (SOURCES.md):

1. **Tier 1:** the vendor's security/admin docs and release notes/changelogs since `last_updated`. Verify each of the guide's falsifiable claims against current docs.
2. **Tier 2:** current CIS Benchmark version (numbering shifts between majors — a guide citing v3.1 when v7.0.0 is current is a finding), DISA STIG updates, CISA SCuBA baselines and BODs, KEV entries for the product.
3. **Tier 3/4:** standing-list vendors and admitted researchers, last ~12 months, product-specific only. Citing a source not yet on the standing list? Add it there with a real fetch-verified example URL (SOURCES.md Maintenance rule) — never a placeholder.
4. **MATERIAL means:** new security control/setting shipped · changed default · deprecated mechanism the guide still recommends · new attack class with a documented mitigation · authoritative baseline unmapped · factual error in the guide. Blog rehashes and marketing are not material.
5. **The fetch gate:** every finding needs a URL fetched successfully in-session (real-browser check for blocked hosts). Unverifiable finding = dropped, not softened. Record findings as: `TYPE | title | what the guide should say | verified-url | target section`.
6. When fanning out research agents, hand them this phase verbatim including the gate and the record format.
7. **Checkpoint:** a findings list where every row carries a verified URL. Zero findings is a valid outcome — say so and stop.

## Phase 3 — Apply (errors first, structure-safe)

1. **Corrections first.** A guide instructing a removed setting or asserting a stale fact gets corrected IN PLACE, keeping its number. (Real examples this repo shipped: a control for Google's Less Secure Apps toggle after Google deleted the feature; "Dependabot has no cooldown" after it became a default; Zoom token lifetimes off by two orders of magnitude; "Atlassian Access" a full product-rename behind.)
2. **Changed defaults** become a bolded callout INSIDE the affected control with the source link — not loose prose.
3. **New controls** go at the END of the best-fit `## N.` section with the next free `### N.M`. NEVER renumber existing controls — pack includes and inbound anchors depend on them. A genuinely new theme may add a new `## N.` section before the compliance/reference sections.
4. Every new control follows the full anatomy in `create-hth-guide` Phase 4 (the cheat-parser contract) — a control with `**Profile Level:**` but a missing rationale piece renders a cheat row with a silent blank cell; one without `**Profile Level:**` misses the sheet entirely.
5. **No pack includes for new controls** unless a verified pack exists (create via create-code-pack). Most SaaS admin settings are ClickOps-only — state the automation surface honestly.
6. If a pack automated a now-removed setting, delete the pack file and re-run `bash scripts/sync-packs-to-data.sh` — automation for a nonexistent setting is fabrication.
7. Update References/Appendix links that rotted (redirect-chasing per SOURCES.md verification rules).

## Phase 4 — Bookkeeping and verification

1. Changelog: new top row — date `date +%F`, version bump (minor for new controls, patch for corrections only), a one-line summary naming what changed.
2. Frontmatter `version` and `last_updated` must equal the new changelog row.
3. Escape any literal `{{...}}` introduced (Vault templates etc.) with `{% raw %}...{% endraw %}`.
4. **Run the `verify-hth` skill.** Its battery has caught real slips in this exact workflow (missing changelog rows, unescaped Liquid) — never skip it.

## Gotchas

- The most dangerous finding type is the one that looks fine: a control for a setting the vendor REMOVED still reads plausibly. Verify claims against current Tier 1 docs, not against whether the prose sounds right.
- Conflicting strictness between vendor and benchmark is documented as BOTH-with-callout, never silently resolved (SOURCES.md conflict rules).
- When two research sources disagree on a date/status, re-fetch the primary; if still ambiguous, state the claim cautiously without asserting the disputed specifics.
- Version bumps and changelog rows move together — the linter checks structure, not consistency; consistency is on you.
- On Windows, repo scripts run through Git Bash (`bash scripts/...`).
