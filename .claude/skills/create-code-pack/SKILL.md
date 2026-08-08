---
name: create-code-pack
description: Author or modify a How to Harden Code Pack — real, verified, executable code wired into a guide via the sync pipeline. USE WHEN creating a code pack, adding Terraform/API/CLI/SDK/db/SIEM/Sigma/config code for a guide control, wiring a pack include, or fixing pack numbering/rendering. NOT FOR guide prose (use create-hth-guide / update-hth-guide).
---

# Create an HTH Code Pack

Ship code under `packs/{vendor}/{type}/` that is real against the vendor's documented interface, renders in the guide through the sync pipeline, and never collides with an existing pack.

## Gate zero: does this pack deserve to exist?

A pack exists ONLY when there is a genuine, documented, programmatic way to scan for, detect, or implement the control. Before writing a line:

- Confirm the interface in the vendor's official docs (Terraform provider registry page, API reference, CLI docs, SDK docs, Sigma logsource support). Fetch it this session.
- No SQL files for vendors without a real query surface. `db/` means vendor-native querying only: Snowflake/Databricks SQL, BigQuery log-export SQL (Google Workspace), Salesforce SOQL, Power BI DAX. This repo once shipped six Okta `.sql` files against a nonexistent `okta_system_log` table — that class of fabrication is the cardinal sin here.
- No Sigma rule without a real log source that would carry the event.
- Many admin surfaces have NO write API (read-only Policy APIs, console-only settings). The honest pack for those is verification-style (assessment tools like ScubaGoggles/ScubaGear, DNS checks, read-only API audits) or NO pack at all.

## Types and homes

| Type dir | Content | Extensions |
|----------|---------|------------|
| `terraform/` | Config-as-Code from a real provider | `.tf` |
| `api/` | bash+curl/jq against documented REST APIs | `.sh` |
| `cli/` | Scripts invoking a vendor's FIRST-PARTY CLI (`gh`, `vault`, `databricks`…) — no first-party CLI, no cli/ pack | `.sh`, `.yml` |
| `sdk/` | Official SDK scripts | `.py`, `.ps1`, `.js`, `.go`, `.groovy`, `.rb` |
| `db/` | Vendor-native queries only (see gate zero) | `.sql`, `.kql` (vendor-native), `.dax` |
| `siem/` | SIEM-resident detection queries — Splunk SPL, Sentinel/Log Analytics KQL. These run in the SIEM, never in a vendor database: NEVER file them under db/ | `.spl`, `.kql` |
| `siem/sigma/` | Sigma rules (multiple files per section allowed, `-b`/`-c` suffixes) | `.yml` |
| `config/` | Vendor-native config files and config-emitting scripts | `.jsonc`, `.yml`, `.sh` |

Never: `.txt`, prose-in-code-markers, tree diagrams, checklists. `packs/{vendor}/controls/*.yaml` are scanner control-definitions (no excerpt markers), not pack code — leave them to their own convention.

## File contract

- Name: `hth-{vendor}-{N.NN}-{slug}.{ext}`. The number becomes the yml section key (`1.01` → `"1.1"`).
- Wrap guide-visible regions in excerpt markers (comment style per language: `#`, `--`, or `//`):

```bash
# HTH Guide Excerpt: begin descriptive-region-name
...extractable code...
# HTH Guide Excerpt: end descriptive-region-name
```

- For JSON content needing markers, use `.jsonc` (JSON cannot carry comments).
- Header comment: control number/title, profile level, framework refs, guide URL.

## The collision rule (this silently breaks rendering)

The sync keeps exactly ONE file per (section, type) — the last alphabetically wins, silently. Only `siem/sigma/` supports multiple files per section. Before choosing a number, list existing files for that section across your type: a second `api/` file on section 2.2 will shadow or be shadowed. The repo previously had six controls silently rendering the wrong pack because of this. If two same-type files genuinely serve one control, merge them or give the secondary a free number with its own include.

## Wiring and verification

1. `bash scripts/sync-packs-to-data.sh` (Git Bash on Windows) — must print `✓ {vendor}`.
2. Confirm the section key landed: `grep '"{N.N}":' docs/_data/packs/{vendor}.yml`.
3. Add `{% include pack-code.html vendor="{vendor}" section="{N.N}" %}` under the control's `#### Code Implementation`. The include's `vendor=` is explicit, so product guides can render packs from a platform's shared pack dir (e.g., claude-code includes vendor="anthropic-claude").
4. Include tags reference the PACK's yml key, which may differ from the guide heading number in older vendors (github) — match existing convention in the guide you're editing; never "fix" one side alone.
5. Run the `verify-hth` skill (dead-include and fence checks cover the pack wiring).
