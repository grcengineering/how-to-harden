---
name: create-code-pack
description: Author or modify a How to Harden Code Pack through a prescriptive gate-verify-wire process — real, verified, executable code wired into a guide via the sync pipeline. USE WHEN creating a code pack, adding Terraform/API/CLI/SDK/db/SIEM/Sigma/config code for a guide control, wiring a pack include, or fixing pack numbering/rendering. NOT FOR guide prose (use create-hth-guide / update-hth-guide).
---

# Create an HTH Code Pack

A step-by-step process for shipping code under `packs/{vendor}/{type}/` that is real against the vendor's documented interface and renders in the guide. Companion standards: [SOURCES.md](../../../SOURCES.md), [AGENTS.md](../../../AGENTS.md) (type table + collision rule).

## Phase 1 — Enumerate the surface (NOT "find an interface")

> **This phase asks "what are ALL the ways to automate this?" — never "does an interface exist?"** The old wording said *identify **the** claimed interface*, and an existence gate is satisfied by the first surface an agent thinks of. That is how Buildkite shipped 9 packs that were 100% Terraform while its real security surface lived in agent config files and GraphQL, and how 14 vendors ended up with a single-type pack corpus. Enumeration is the fix; everything downstream depends on it.

1. Name the control the pack serves (guide + section number).
2. **Census every surface** the vendor exposes — all six, one line each, even to write "none, verified":

   | Surface | What to enumerate | Where |
   |---------|-------------------|-------|
   | `terraform` | the provider's **full resource list AND full data-source list** — not just the one resource you had in mind | registry docs index |
   | `api` | REST endpoint categories **and** GraphQL (introspect the schema, or fetch the schema docs) | vendor API reference |
   | `cli` | **look the vendor up in [`docs/research/cli-inventory.md`](../../../docs/research/cli-inventory.md) — never judge from memory** | that file, then vendor CLI docs |
   | `sdk` | official language SDKs with admin/security methods | vendor SDK reference |
   | `config` | vendor-native config files (`*.cfg`, `*.jsonc`, agent/daemon config) | vendor config reference |
   | `siem` | does the product export logs a SIEM can carry? | audit-log/export docs |

3. **FETCH Tier 1 documentation this session for every surface you claim exists**, and record its URL. No verified doc → that surface is "none, verified" and gets no pack. Report gaps honestly; never infer a surface from a plausible-sounding name.
4. **Record `status` for every handle you intend to use** — `available` / `deprecated` / `removed` / `beta`. Registry pages carry deprecation banners; a resource can be perfectly documented and unusable. Buildkite's `buildkite_agent_token` is documented and unavailable to any org created after 2024-02-26. A deprecated handle needs a note in the pack header saying so, or a different handle.
5. **Write and read are separate packs.** For each surface ask both: *what SETS this control* (resource, write endpoint, mutation) and *what PROVES it* (Terraform **data source**, read-only endpoint, audit script). Corpus-wide this repo has 692 `resource` blocks and 40 `data` blocks — the verification half is the half that gets skipped. Read-only APIs support verification packs (audit scripts, assessment tooling like ScubaGoggles/ScubaGear, DNS checks) — never enforcement packs claiming to SET what only the console can set.
6. Apply the type-fit tests:
   - `db/` only for vendor-NATIVE query surfaces (Snowflake/Databricks SQL, BigQuery log-export SQL, SOQL, DAX). This repo once shipped six Okta `.sql` files against a nonexistent `okta_system_log` table — that class of fabrication is the cardinal sin here.
   - `siem/` (`.spl`, `.kql`) for SIEM-resident detections — only if the product actually exports logs a SIEM can carry, and never filed under `db/`.
   - `siem/sigma/` only if a real log source would carry the event.
   - `cli/` only for FIRST-PARTY vendor CLIs. **Decide from `cli-inventory.md`, not from the examples in this list.** `GA-Official`/`PowerShell-Only` with admin coverage **Yes** → a `cli/` pack is *expected*. `None`/`Vendor-Adjacent`/`Deprecated` → a `cli/` pack would be fabrication. **No row → research the vendor and add one in this PR.**
7. **Checkpoint — all four, or stop and report:**
   - a six-row surface census, each row either a fetched URL or "none, verified";
   - `status` recorded for every handle you will use;
   - a write/read decision per surface;
   - types chosen from the AGENTS.md table.

   **If the census shows three or more surfaces and you are about to author packs of exactly one type, that is a monoculture — stop and justify it in the guide, or widen.** `validate-packs.sh` Check 16 flags it; Check 17 flags a skipped CLI.

## Phase 2 — Collision check (silent-failure prevention)

1. List existing pack files for your section across your chosen type: `ls packs/{vendor}/{type}/ | grep "{N.NN}"`.
2. The sync keeps exactly ONE file per (section, type) — last alphabetically wins, silently. Only `siem/sigma/` supports multiple files per section (`-b`, `-c` suffixes).
3. If a same-type file already holds your section: merge into it, or take a genuinely free number and plan its own include. Never add a second file on the same (section, type) key.

## Phase 3 — Author the file

1. Name: `hth-{vendor}-{N.NN}-{slug}.{ext}` (the number becomes the yml key: `1.01` → `"1.1"`).
2. Header comment: control number/title, profile level, framework refs, guide URL.
3. Wrap each guide-visible region in excerpt markers (comment style per language — `#`, `--`, or `//`):

```bash
# HTH Guide Excerpt: begin descriptive-region-name
...extractable code...
# HTH Guide Excerpt: end descriptive-region-name
```

4. Content rules: every resource/endpoint/flag transcribed from the fetched doc — nothing from memory; JSON needing markers uses `.jsonc`; never `.txt`, prose-in-markers, tree diagrams, or checklists. `packs/{vendor}/controls/*.yaml` are scanner definitions with their own convention — not pack code.
5. **A pack must contain executable code.** A file whose every non-blank line is a comment is prose wearing a `.tf` extension — it renders as an empty code block and reads to a user as "automation exists here" when none does. Six shipped that way before Check 15 existed. If the honest answer is "no automation for this control," the answer belongs in the *guide* as the AGENTS.md Rule 4 `**Automation:** ClickOps only — … ({url}, {date})` line, and **no pack file at all**. Never create a placeholder pack to fill a gap.

## Phase 4 — Wire and verify

1. `bash scripts/sync-packs-to-data.sh` (Git Bash on Windows) → your vendor must print `✓` (a `✗` means invalid YAML was generated and the vendor's data is now stale — fix before proceeding).
2. Confirm the key landed: `grep '"{N.N}":' docs/_data/packs/{vendor}.yml`.
3. Add `{% include pack-code.html vendor="{vendor}" section="{N.N}" %}` under the control's `#### Code Implementation` heading. The include's `vendor=` is explicit, so product guides can render packs from a platform's shared dir (claude-code includes `vendor="anthropic-claude"`).
4. Older vendors (github) key includes to historical pack numbers that differ from guide headings — match the existing convention in the guide you're editing; never "fix" one side alone.
5. `bash scripts/validate-packs.sh {vendor}` → zero FAILs. **Read the coverage output, do not just check the exit code:** Check 15 (a pack with no executable content), Check 16 (single-type monoculture + how many of this vendor's leveled controls have a pack), Check 17 (a documented admin CLI you skipped). These are the only checks that measure whether Phase 1's census was real.
6. **Run the `verify-hth` skill** (covers dead includes, fences, lint).

## Gotchas

- The (section, type) collision is SILENT — the page renders the wrong pack with no error anywhere. Phase 2 is not optional.
- An include whose section key doesn't exist in the vendor yml renders NOTHING, silently — always grep the yml after sync.
- Excerpt marker names must be unique within a file; the region content lands in the guide verbatim, so keep regions self-contained.
- The sync script validates generated YAML with python3; on Windows it needs Git Bash (cygpath shims are built in).
- If a control's setting gets removed by the vendor later, the pack must be deleted with it — see update-hth-guide Phase 3.
