---
name: create-hth-guide
description: Create a new How to Harden vendor guide (or a product guide inside a multi-product platform) that renders a complete cheat sheet, passes the repo verification battery, and follows the current template. USE WHEN creating a new guide, authoring a vendor hardening guide, adding a product guide to a platform (like Gmail under Google Workspace), or converting a placeholder/stub guide into a real one. NOT FOR updating existing guide content (use update-hth-guide) or authoring pack code (use create-code-pack).
---

# Create an HTH Guide

Produce `docs/_guides/{slug}.md` whose every control renders as a complete cheat-sheet row, whose every claim traces to a fetched vendor/authority doc, and which passes the verification battery — then hand off to `verify-hth`.

## Non-negotiables

1. **Research before writing.** Every control's console path, setting name, and checkbox label comes from a vendor doc you fetched THIS session. If a URL doesn't fetch, it doesn't get cited. Hosts that block fetchers (403/JS-shell) get verified in a real browser or the claim is dropped.
2. **Honest automation surface.** State per control whether it is API/Terraform-manageable or ClickOps-only. Many admin surfaces (e.g., Gmail Safety settings — the Cloud Identity Policy API is read-only for all eight Gmail settings) have NO write API: say so, never invent one, and create no pack for it.
3. **Zero inline code fences.** `grep -cE '^ *```' docs/_guides/{slug}.md` must return 0. Code goes through create-code-pack.
4. **Compliance IDs are looked up, never recalled.** CIS benchmark numbering shifts between major versions; if you can't verify the exact ID, map by control NAME with a benchmark-version note. CISA SCuBA policy IDs (GWS.*, MS.*) are stable and preferred where a baseline exists (ScubaGoggles / ScubaGear repos).

## The cheat-sheet parser contract (why guides render cheat sheets)

The cheat sheet is built client-side from the rendered guide DOM (`docs/_includes/cheat-sheet.html`). A control appears as a row ONLY if its section has ALL of:

- Heading `### N.N Title` (H3, numbered)
- A leading bold key `**Profile Level:** L1 (Crawl)` (or L2 Walk / L3 Run)
- `#### Description` followed by a non-empty paragraph
- `#### Rationale` containing `**Why This Matters:**` bullets, plus a `**Attack Prevented:**` line

Sections that are intentionally NOT controls (reference tables like "Key Events to Monitor", "Integration Risk Assessment Matrix", compliance quick-reference subsections, and `### N.N.N` implementation walk-throughs) must NOT carry `**Profile Level:**` — that is what excludes them, correctly, from the cheat sheet.

## Control anatomy (mirror an existing strong guide, e.g. docs/_guides/gmail.md)

Per control: heading → Profile Level → framework mini-table → `#### Description` → `#### Rationale` (Why bullets + Attack Prevented) → `#### Prerequisites` (when real) → `#### ClickOps Implementation` (numbered steps, exact console paths in bold) → `#### Code Implementation` with a pack include ONLY if a verified pack exists → `#### Validation & Testing` → `#### Compliance Mappings` table. Blank line before AND after every table (Jekyll breaks otherwise).

## Frontmatter

Required: `layout: guide`, `title`, `vendor`, `slug`, `tier`, `category` (must be in scripts/validate-guides.sh VALID_CATS), `description`, `version`, `maturity: "draft"`, `last_updated`. Set `last_updated` and the changelog row's date to the COMMIT date (`date +%F`), never the drafting date.

**Multi-product platform guides** add three keys: `platform: "Platform Name"`, `platform_slug: "platform-slug"`, `product: "Product Name"`. The hub guide uses `product: "Common Controls"` and keeps org-wide controls only; product guides open with a one-line "This is a product guide within the [platform](/guides/{hub-slug}/)" pointer and cross-reference the hub instead of duplicating platform-wide controls. The homepage groups by `platform_slug` automatically. Reference implementations: google-workspace (hub) + gmail/google-chat/google-drive; anthropic-claude (hub) + claude-enterprise/claude-code/anthropic-api.

## Doc links

Add the vendor to `docs/_data/doc_links.yml`. `hardening_docs` must point at LITERAL hardening/security-configuration documentation or an authoritative benchmark — never a Trust Center, marketing security page, or compliance-badge page. If no honest link exists, omit the key (no button beats a dishonest one). Multiple sources use the list form, which renders an expandable button:

```yaml
hardening_docs:
  - label: "Vendor Hardening Guide"
    url: "https://..."
  - label: "CIS Benchmark"
    url: "https://..."
```

## Gotchas (each one has bitten this repo)

- Vault/Handlebars-style `{{...}}` in prose or inline code is eaten by Jekyll — wrap in `{% raw %}...{% endraw %}`.
- The guide renders "Last updated" from frontmatter; a stale date misleads readers.
- Changelog row and frontmatter `version` must move together.
- On this repo's Windows setups, run scripts through Git Bash (`bash scripts/...`); they contain cygpath/UTF-8 shims for native Python.

## Done means

Run the `verify-hth` skill. Additionally for a new guide: load `/guides/{slug}/?view=cheat` after deploy (or trust the parser-contract check pre-deploy) and confirm every control appears with all three cells populated.
