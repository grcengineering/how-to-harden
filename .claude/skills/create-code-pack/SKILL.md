---
name: create-code-pack
description: Author or modify a How to Harden Code Pack through a prescriptive gate-verify-wire process — real, verified, executable code wired into a guide via the sync pipeline. USE WHEN creating a code pack, adding Terraform/API/CLI/SDK/db/SIEM/Sigma/config code for a guide control, wiring a pack include, or fixing pack numbering/rendering. NOT FOR guide prose (use create-hth-guide / update-hth-guide).
---

# Create an HTH Code Pack

A step-by-step process for shipping code under `packs/{vendor}/{type}/` that is real against the vendor's documented interface and renders in the guide. Companion standards: [SOURCES.md](../../../SOURCES.md), [AGENTS.md](../../../AGENTS.md) (type table + collision rule).

## Phase 1 — Gate zero: does this pack deserve to exist?

1. Name the control the pack serves (guide + section number).
2. Identify the claimed interface and FETCH its Tier 1 documentation this session: Terraform provider registry page for the exact resource, API endpoint reference, first-party CLI docs, SDK reference, or Sigma logsource support. No verified interface doc → **no pack**. Report the gap honestly instead.
3. Apply the type-fit tests:
   - `db/` only for vendor-NATIVE query surfaces (Snowflake/Databricks SQL, BigQuery log-export SQL, SOQL, DAX). This repo once shipped six Okta `.sql` files against a nonexistent `okta_system_log` table — that class of fabrication is the cardinal sin here.
   - `siem/` (`.spl`, `.kql`) for SIEM-resident detections — only if the product actually exports logs a SIEM can carry, and never filed under `db/`.
   - `siem/sigma/` only if a real log source would carry the event.
   - `cli/` only for FIRST-PARTY vendor CLIs (`gh`, `vault`, `databricks`); no first-party CLI → use `api/`/`terraform/`/`config/`.
   - Read-only APIs support VERIFICATION packs (audit scripts, assessment tooling like ScubaGoggles/ScubaGear, DNS checks) — never enforcement packs claiming to SET what only the console can set.
4. **Checkpoint:** interface doc URL verified + type chosen from the AGENTS.md table. Anything shaky → stop and report.

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

## Phase 4 — Wire and verify

1. `bash scripts/sync-packs-to-data.sh` (Git Bash on Windows) → your vendor must print `✓` (a `✗` means invalid YAML was generated and the vendor's data is now stale — fix before proceeding).
2. Confirm the key landed: `grep '"{N.N}":' docs/_data/packs/{vendor}.yml`.
3. Add `{% include pack-code.html vendor="{vendor}" section="{N.N}" %}` under the control's `#### Code Implementation` heading. The include's `vendor=` is explicit, so product guides can render packs from a platform's shared dir (claude-code includes `vendor="anthropic-claude"`).
4. Older vendors (github) key includes to historical pack numbers that differ from guide headings — match the existing convention in the guide you're editing; never "fix" one side alone.
5. **Run the `verify-hth` skill** (covers dead includes, fences, lint).

## Gotchas

- The (section, type) collision is SILENT — the page renders the wrong pack with no error anywhere. Phase 2 is not optional.
- An include whose section key doesn't exist in the vendor yml renders NOTHING, silently — always grep the yml after sync.
- Excerpt marker names must be unique within a file; the region content lands in the guide verbatim, so keep regions self-contained.
- The sync script validates generated YAML with python3; on Windows it needs Git Bash (cygpath shims are built in).
- If a control's setting gets removed by the vendor later, the pack must be deleted with it — see update-hth-guide Phase 3.
