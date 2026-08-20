---
name: update-hth-guide
description: Update an existing How to Harden guide with current, verified hardening guidance through a prescriptive research-verify-apply process — currency research against vendor docs/CIS/CISA/expert research, error correction, and new controls — without breaking the cheat sheet or numbering. USE WHEN updating a guide, refreshing guidance, adding a control to an existing guide, fixing an inaccuracy, or running a currency pass. NOT FOR creating new guides (use create-hth-guide) or pack code (use create-code-pack).
---

# Update an HTH Guide

A step-by-step currency-and-correction process for `docs/_guides/{slug}.md`. Companion standards: [SOURCES.md](../../../SOURCES.md), [AGENTS.md](../../../AGENTS.md).

## Phase 1 — Baseline the guide

1. Read the guide's frontmatter (`version`, `last_updated`), changelog, and full control list (`### N.N` headings with their claims).
2. Note every dated or versioned claim the guide makes (token lifetimes, deprecation dates, product names, benchmark versions, plan tiers, cited URLs) — these are the highest-probability rot points.
3. **Baseline the automation too, not just the prose.** Every step above reads `docs/_guides/{slug}.md`; none opens `packs/{vendor}/`. Run `bash scripts/validate-packs.sh {vendor}` and record its Check 16/17 output: which pack types exist, how many leveled controls have a pack, whether the vendor is a single-type monoculture, whether a documented admin CLI was skipped. A currency pass that never looks at the pack corpus cannot find automation rot — and automation rot is invisible from the guide text, because a guide with a stale surface reads perfectly.
4. **Checkpoint:** a written list of the guide's controls, its falsifiable claims, **and its current automation coverage numbers**.

## Phase 2 — Currency research (fetch-gated)

Hunt MATERIAL deltas per source tier (SOURCES.md):

1. **Tier 1 — prose docs:** the vendor's security/admin docs and release notes/changelogs since `last_updated`. Verify each of the guide's falsifiable claims against current docs.
1b. **Tier 1 — automation surfaces.** SOURCES.md Tier 1 includes "API/CLI references"; a currency pass that reads only prose will report a perfectly current guide that has silently fallen a whole provider version behind. Re-check, and diff against the Phase 1 baseline:
   - the **Terraform provider changelog** — new resources, new **data sources**, and resources newly marked *deprecated* (a resource can be fully documented and unusable: Buildkite's `buildkite_agent_token` is unavailable to any org created after 2024-02-26);
   - the **REST/GraphQL API changelog** — new endpoints and mutations;
   - the vendor's row in [`docs/research/cli-inventory.md`](../../../docs/research/cli-inventory.md) — has a CLI appeared, changed status, or been deprecated since it was last refreshed?
2. **Tier 2:** current CIS Benchmark version (numbering shifts between majors — a guide citing v3.1 when v7.0.0 is current is a finding), DISA STIG updates, CISA SCuBA baselines and BODs, KEV entries for the product.
3. **Tier 3/4:** standing-list vendors and admitted researchers, last ~12 months, product-specific only. Citing a source not yet on the standing list? Add it there with a real fetch-verified example URL (SOURCES.md Maintenance rule) — never a placeholder.
4. **MATERIAL means** — *what the guide says:* new security control/setting shipped · changed default · deprecated mechanism the guide still recommends · new attack class with a documented mitigation · authoritative baseline unmapped · factual error in the guide.

   **…and equally, *what the guide can do*:** a control that was ClickOps-only when written but is now Terraform-managed · a new data source that finally makes a control verifiable · a first-party CLI that shipped or reached GA · a resource the packs use that is now deprecated or removed · a pack surface the original pass never enumerated at all.

   > These six "can do" cases produce **zero findings** under the "what it says" list — the setting is not new, no default changed, nothing the guide mentions was deprecated. That asymmetry is why guides stay textually current for years while their automation silently rots or never existed. Blog rehashes and marketing are not material.
5. **The fetch gate:** every finding needs a URL fetched successfully in-session (real-browser check for blocked hosts). Unverifiable finding = dropped, not softened. Record findings as: `TYPE | title | what the guide should say | verified-url | target section`.
6. When fanning out research agents, hand them this phase verbatim including the gate and the record format.
7. **Checkpoint:** a findings list where every row carries a verified URL. Zero findings is a valid outcome — say so and stop.

## Phase 3 — Apply (errors first, structure-safe)

1. **Corrections first.** A guide instructing a removed setting or asserting a stale fact gets corrected IN PLACE, keeping its number. (Real examples this repo shipped: a control for Google's Less Secure Apps toggle after Google deleted the feature; "Dependabot has no cooldown" after it became a default; Zoom token lifetimes off by two orders of magnitude; "Atlassian Access" a full product-rename behind.)
2. **Changed defaults** become a bolded callout INSIDE the affected control with the source link — not loose prose.
3. **New controls** go at the END of the best-fit `## N.` section with the next free `### N.M`. NEVER renumber existing controls — pack includes and inbound anchors depend on them. A genuinely new theme may add a new `## N.` section before the compliance/reference sections.
4. Every new control follows the full anatomy in `create-hth-guide` Phase 4 (the cheat-parser contract) — a control with `**Profile Level:**` but a missing rationale piece renders a cheat row with a silent blank cell; one without `**Profile Level:**` misses the sheet entirely.
5. **No pack includes for new controls** unless a verified pack exists (create via create-code-pack). Where genuinely no surface exists, say so in the control with AGENTS.md Rule 4's `**Automation:** ClickOps only — … ({url}, {date})` line; silence is not an option.

   > This step used to open with *"Most SaaS admin settings are ClickOps-only."* Even if true on average, it is a prior an agent can apply **without checking**, and it makes "no pack" the expected answer rather than a finding requiring evidence. Determine this vendor's surface from `create-code-pack` Phase 1's census; do not inherit it from a generalisation.
6. If a pack automated a now-removed setting, delete the pack file and re-run `bash scripts/sync-packs-to-data.sh` — automation for a nonexistent setting is fabrication.
7. Update References/Appendix links that rotted (redirect-chasing per SOURCES.md verification rules).

## Phase 4 — Bookkeeping and verification

1. Changelog: new top row — date `date +%F`, version bump (minor for new controls, patch for corrections only), a one-line summary naming what changed.
2. Frontmatter `version` and `last_updated` must equal the new changelog row.
3. **`maturity` is not yours to add to — and may well need statuses removed.** Maturity is a matrix, not a ladder: three stages (`drafted` → `reviewed` → `validated`) × two agents (`ai` = a machine, `ni` = a person), held as a **list** ([VERSIONS.md](../../../VERSIONS.md#maturity-statuses--the-matrix)). Only a [`validate-hth-guide`](../validate-hth-guide/SKILL.md) run may add `ai-validated`, and only maintainers may add any `ni-*`. A currency pass reads documents; it does not touch a tenant and it is not a human practitioner's judgement, so it can never earn a status. It can however **invalidate** one: if you corrected a guide holding `ai-validated` — a moved console path, a removed setting, a changed default — that status is now a claim about a world that has moved. Remove it from the set (usually leaving `["ai-drafted"]`), delete the per-surface `{% include status-mark.html %}` marks on every implementation heading you changed, and say so in the changelog row, whose Maturity column carries the full set as of that row so the narrowing is visible. A stale status is worse than none: it is the site telling a reader that something was checked when what was checked is gone.
4. Escape any literal `{{...}}` introduced (Vault templates etc.) with `{% raw %}...{% endraw %}`.
5. **Run the `verify-hth` skill.** Its battery has caught real slips in this exact workflow (missing changelog rows, unescaped Liquid) — never skip it.

## Gotchas

- The most dangerous finding type is the one that looks fine: a control for a setting the vendor REMOVED still reads plausibly. Verify claims against current Tier 1 docs, not against whether the prose sounds right.
- Conflicting strictness between vendor and benchmark is documented as BOTH-with-callout, never silently resolved (SOURCES.md conflict rules).
- When two research sources disagree on a date/status, re-fetch the primary; if still ambiguous, state the claim cautiously without asserting the disputed specifics.
- Version bumps and changelog rows move together — the linter checks structure, not consistency; consistency is on you.
- Correcting a validated guide silently downgrades its truth without downgrading its badge. The frontmatter set still contains `ai-validated` and the control still wears the mark, because nothing in the lint compares a badge to the text beside it — that check is this step, done by you.
- On Windows, repo scripts run through Git Bash (`bash scripts/...`).
