# Guide-to-Pack Code Snippet Integration

## Status: COMPLETED (Okta) | PENDING (GitHub)

Implemented marker-based extraction: pack files contain `# hth:begin`/`# hth:end` comment markers around guide-worthy excerpts. A sync script extracts marked regions into `docs/_data/packs/okta.yml`. Jekyll includes render them as collapsible `<details>` blocks with GitHub source links.

## Completed Tasks

### 1. Marker System
- [x] Added `# hth:begin <name>` / `# hth:end <name>` markers to 57 pack files
- [x] 11 Terraform files: 1 `terraform` region each
- [x] 22 API scripts: 1-3 named regions each (37 total: `api-create-policy`, `api-list-tokens`, etc.)
- [x] 24 Sigma rules: 1 `detection` region each

### 2. Extraction Script
- [x] Created `scripts/sync-packs-to-data.sh`
- [x] Extracts marked regions, normalizes section numbers (1.01 → 1.1)
- [x] Generates `docs/_data/packs/{vendor}.yml` keyed by section + type
- [x] Handles whitespace-indented markers, multi-rule controls, arrays for Sigma

### 3. Jekyll Include Template
- [x] Created `docs/_includes/pack-code.html`
- [x] Renders collapsible `<details>` for each type (Terraform, API, Sigma)
- [x] Uses `<pre><code class="language-xxx">` for Tier 1/Tier 2 code enhancements
- [x] "View source on GitHub" links for each file
- [x] Guards: renders nothing if no data exists

### 4. CSS
- [x] Added ~85 lines to `docs/assets/css/style.css`
- [x] `.pack-details`, `.pack-summary`, `.pack-file-header`, type badges
- [x] Dark/light theme support via CSS variables
- [x] Mobile responsive at 640px breakpoint

### 5. Guide Layout
- [x] Updated `docs/_layouts/guide.html`
- [x] Added `<details>` toggle listener for Monaco lazy-loading in collapsed sections

### 6. Okta Guide
- [x] Added 25 `{% include pack-code.html %}` calls to `docs/_guides/okta.md`
- [x] 77 excerpts across 25 sections

### 7. Verification
- [x] Valid YAML: 25 sections, 77 excerpts, all balanced markers (77/77)
- [x] All 25 include sections match data entries
- [x] Blank line compliance verified around all includes
- [x] All bash scripts pass `bash -n` syntax check
- [x] Release binary builds successfully

## Remaining Work

### GitHub Guide
- [ ] Create pack code files for GitHub controls (currently only control YAMLs exist)
- [ ] Add markers to new pack files when created
- [ ] Run `bash scripts/sync-packs-to-data.sh` to generate `docs/_data/packs/github.yml`
- [ ] Add `{% include pack-code.html %}` calls to `docs/_guides/github.md`

### Future Enhancements
- [ ] GitHub Action to auto-run `sync-packs-to-data.sh` when pack files change
- [ ] Jekyll build verification in CI (requires Ruby/Jekyll in CI)
- [ ] **Automated Source Doc Staleness Detection (CI):** Scheduled CI jobs that check if a vendor's source documentation (hardening guides, product docs, API docs, Terraform provider docs, CLI docs) has been updated since the HTH guide's `last_updated` date. If changes detected, trigger Claude Code + PAI to analyze the delta and update the HTH guide accordingly. This keeps HTH guides perpetually current with vendor-provided security guidance. Implementation approach: store source doc URLs + last-known hashes/dates in `doc_links.yml` or a separate `doc_freshness.yml`, schedule weekly/monthly checks, use HTTP Last-Modified/ETag or content hashing, generate PRs with proposed guide updates.

## Architecture Reference

```
Pack files (hth:begin/end markers)
  └─▶ scripts/sync-packs-to-data.sh
       └─▶ docs/_data/packs/{vendor}.yml
            └─▶ {% include pack-code.html vendor="okta" section="1.1" %}
                 └─▶ Collapsible <details> with excerpts + source links
```

### Regenerating Data
After any pack file change:
```bash
bash scripts/sync-packs-to-data.sh
```
