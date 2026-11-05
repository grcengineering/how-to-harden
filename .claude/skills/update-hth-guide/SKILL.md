---
name: update-hth-guide
description: Update an existing How to Harden guide with current, verified hardening guidance through a prescriptive research-verify-apply process — currency research against vendor docs/CIS/CISA/expert research, error correction, and new controls — without breaking the cheat sheet or numbering. USE WHEN updating a guide, refreshing guidance, adding a control to an existing guide, fixing an inaccuracy, running a currency pass, or re-homing a guide after its product changed owner (acquisition, merger, rebrand). NOT FOR creating new guides (use create-hth-guide) or pack code (use create-code-pack).
---

# Update an HTH Guide

A step-by-step currency-and-correction process for `docs/_guides/{slug}.md`. Companion standards: [SOURCES.md](../../../SOURCES.md), [AGENTS.md](../../../AGENTS.md).

## Phase 1 — Baseline the guide

1. Read the guide's frontmatter (`version`, `last_updated`), changelog, and full control list (`### N.N` headings with their claims).
2. Note every dated or versioned claim the guide makes (token lifetimes, deprecation dates, product names, benchmark versions, plan tiers, cited URLs) — these are the highest-probability rot points.
3. **Baseline the automation too, not just the prose.** Every step above reads `docs/_guides/{slug}.md`; none opens `packs/{vendor}/`. Run `bash scripts/validate-packs.sh {vendor}` and record its Check 16/17 output: which pack types exist, how many leveled controls have a pack, whether the vendor is a single-type monoculture, whether a documented admin CLI was skipped. A currency pass that never looks at the pack corpus cannot find automation rot — and automation rot is invisible from the guide text, because a guide with a stale surface reads perfectly.
4. **Record the guide's place on the company → platform → product chain:** its `vendor`, its `platform`/`platform_slug`/`product` if set, and what its Overview says about who owns the product. That record is a claim like any other, and it rots the same way: a guide's `vendor` records who owned the product when the guide was written.
5. **Checkpoint:** a written list of the guide's controls, its falsifiable claims, **its current automation coverage numbers, and its recorded ownership chain**.

## Phase 2 — Currency research (fetch-gated)

Hunt MATERIAL deltas per source tier (SOURCES.md):

1. **Tier 1 — current claims and older omissions:** verify the guide's claims and read release notes since `last_updated`, then perform the [source-first coverage reconciliation](../_shared/source-discovery.md) for the requested scope. Inspect current feature indexes and relevant client/daemon/system-policy/posture references independently of the guide's headings. A full currency pass must look for existing security features the guide never covered, even when they predate its date. A narrow correction stays scoped and makes no whole-guide coverage claim.
1b. **Tier 1 — automation surfaces.** SOURCES.md Tier 1 includes "API/CLI references"; a currency pass that reads only prose will report a perfectly current guide that has silently fallen a whole provider version behind. Re-check, and diff against the Phase 1 baseline:
   - the **Terraform provider changelog** — new resources, new **data sources**, and resources newly marked *deprecated* (a resource can be fully documented and unusable: Buildkite's `buildkite_agent_token` is unavailable to any org created after 2024-02-26);
   - the **REST/GraphQL API changelog** — new endpoints and mutations;
   - the vendor's row in [`docs/research/cli-inventory.md`](../../../docs/research/cli-inventory.md), companion daemon/admin commands and native/system-policy references — include surfaces the earlier census may have missed, not only newly shipped ones.
1c. **Corporate chain.** Re-check who owns the product, from first-party sources ([SOURCES.md](../../../SOURCES.md) Verification Rule 5): acquisitions announced or closed since `last_updated`, mergers, rebrands, divestitures, and the parent's own rebrands. Then repeat [create-hth-guide](../create-hth-guide/SKILL.md) Phase 0 step 3's corpus lookup for the current owner. A changed owner, or a guide sitting outside its owner's existing platform, is a MATERIAL finding of type `OWNERSHIP`. (grok-bot said "xAI (SpaceXAI)" and cursor said "Anysphere" for weeks after SpaceX owned both.)
2. **Tier 2:** current CIS Benchmark version (numbering shifts between majors — a guide citing v3.1 when v7.0.0 is current is a finding), DISA STIG updates, CISA SCuBA baselines and BODs, KEV entries for the product.
3. **Tier 3/4:** standing-list vendors and admitted researchers, last ~12 months, product-specific only. Citing a source not yet on the standing list? Add it there with a real fetch-verified example URL (SOURCES.md Maintenance rule) — never a placeholder.
4. **MATERIAL means** — *what the guide says or omits:* new security control/setting shipped · existing documented mitigation missing (`OMISSION`, regardless of age) · changed or platform/version-dependent default · deprecated mechanism the guide still recommends · new attack class with a documented mitigation · authoritative baseline unmapped · factual error in the guide.

   **…and equally, *what the guide can do*:** a control that was ClickOps-only when written but is now Terraform-managed · a new data source that finally makes a control verifiable · a first-party CLI that shipped or reached GA · a resource the packs use that is now deprecated or removed · a pack surface the original pass never enumerated at all.

   > These six "can do" cases produce **zero findings** under the "what it says" list — the setting is not new, no default changed, nothing the guide mentions was deprecated. That asymmetry is why guides stay textually current for years while their automation silently rots or never existed. Blog rehashes and marketing are not material.
5. **The fetch gate:** every publishable factual finding needs a URL fetched successfully in-session (a documented fallback for blocked hosts). Do not publish an unverified claim; retain the candidate and failed retrieval as an **unverified research gap**, not a finding of absence. Record verified findings as: `TYPE | title | what the guide should say | verified-url | target section`; keep coverage dispositions and evidence separately.
6. When fanning out research agents, hand them this phase verbatim including the gate and the record format.
7. **Checkpoint:** a findings list with verified evidence, plus the source-first candidate reconciliation for the declared scope. Zero verified findings is a valid outcome only after checking older omissions; report any unverified areas instead of presenting them as zero gaps. Do not stop solely because existing claims are current or the changelog has no new entries.

## Phase 3 — Apply (errors first, structure-safe)

1. **Corrections first.** A guide instructing a removed setting or asserting a stale fact gets corrected IN PLACE, keeping its number. (Real examples this repo shipped: a control for Google's Less Secure Apps toggle after Google deleted the feature; "Dependabot has no cooldown" after it became a default; Zoom token lifetimes off by two orders of magnitude; "Atlassian Access" a full product-rename behind.)
2. **Changed defaults** become a bolded callout INSIDE the affected control with the source link — not loose prose.
3. **New controls** go at the END of the best-fit `## N.` section with the next free `### N.M`. NEVER renumber existing controls — pack includes and inbound anchors depend on them. A genuinely new theme may add a new `## N.` section before the compliance/reference sections.
4. Every new control follows the full anatomy in `create-hth-guide` Phase 4 (the cheat-parser contract) — a control with `**Profile Level:**` but a missing rationale piece renders a cheat row with a silent blank cell; one without `**Profile Level:**` misses the sheet entirely.
5. **No pack includes for new controls** unless a verified pack exists (create via create-code-pack). Where genuinely no surface exists, use AGENTS.md Rule 4's evidenced automation verdict; where evidence is missing, report `Automation: Unverified` and the gap instead of asserting absence. CLI/config-only controls retain the documented no-GUI verdict and supported Code path from create-hth-guide Phase 4.

   > This step used to open with *"Most SaaS admin settings are ClickOps-only."* Even if true on average, it is a prior an agent can apply **without checking**, and it makes "no pack" the expected answer rather than a finding requiring evidence. Determine this vendor's surface from `create-code-pack` Phase 1's census; do not inherit it from a generalisation.
6. If a pack automated a now-removed setting, delete the pack file and re-run `bash scripts/sync-packs-to-data.sh` — automation for a nonexistent setting is fabrication.
7. Update References/Appendix links that rotted (redirect-chasing per SOURCES.md verification rules).
8. **Re-home on an `OWNERSHIP` finding,** as its own change and never folded silently into a content pass, and only when the request covers it or a maintainer confirms it. Set the platform fields and `vendor` per create-hth-guide Phase 3 step 3, add the product-guide pointer, add the product to the hub's Products table, and remove any prose that justified the old placement. Keep every control number and the pack directory unchanged. If the owner has no platform yet, form one per create-hth-guide Phase 0 step 4. A deal that is only announced changes the Overview's ownership sentence and nothing else.

## Phase 4 — Bookkeeping and verification

1. Changelog: new top row — date `date +%F`, version bump (minor for new controls, patch for corrections only; a re-home with no control change is a patch), a one-line summary naming what changed. A re-home also changes the hub, so the hub gets its own patch bump and row, README's category table names the product under its company, and both VERSIONS.md rows are regenerated.
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
- Re-homing a guide does not touch its `maturity`. Ownership is not a control: an `ai-validated` guide that moves platform keeps the status, because nothing it was validated against has changed.
- On Windows, repo scripts run through Git Bash (`bash scripts/...`).
