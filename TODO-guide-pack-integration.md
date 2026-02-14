# Follow-Up: Guide-to-Pack Code Snippet Integration

These tasks should be executed after the file-per-control restructure is committed. The goal is to eliminate duplicate code snippets by having HTH guides pull content directly from code pack files, add GitHub source links, and make code blocks collapsible.

## Task 1: Build-Time Snippet Extraction Script

Create `scripts/extract-pack-snippets.sh` that:
- Reads each per-control `.tf`, `.sh`, `.yml` file from `packs/`
- Generates `docs/_data/pack_snippets.yml` with content keyed by `{vendor}-{section}-{type}`
- Runs as part of the Jekyll build process (add to build script or Makefile)
- Handles multi-rule controls (e.g., `-b`, `-c` suffixes) by concatenating into a single entry

## Task 2: Jekyll Include Template for Code Snippets

Create `docs/_includes/pack-code.html` that:
- Takes parameters: `vendor`, `control`, `type` (terraform/api/sigma)
- Renders a collapsible `<details><summary>` block with syntax-highlighted code
- Adds a "View source on GitHub" link pointing to the raw file in the repo
- Example usage in guides:
  ```liquid
  {% include pack-code.html vendor="okta" control="1.01" type="terraform" %}
  ```

## Task 3: Update Okta Guide

Update `docs/_guides/okta.md` to:
- Replace inline Terraform snippets with `{% include pack-code.html %}` references
- Replace inline API/CLI snippets with equivalent includes
- Add Sigma rule references for controls that have detection rules
- Verify blank-line compliance around all tables and HTML blocks
- Test with `cd docs && bundle exec jekyll serve`

## Task 4: Update GitHub Guide

Update `docs/_guides/github.md` similarly:
- Replace inline code snippets with `{% include pack-code.html %}` references
- Add links to source files for each control
- Note: GitHub pack only has control YAMLs currently (no terraform/api/siem yet)

## Task 5: Collapsible Code Blocks

Make all code snippets in guides collapsible/expandable, collapsed by default:
- Use kramdown-compatible `<details><summary>` HTML blocks
- Pattern:
  ```html
  <details>
  <summary>Terraform (click to expand)</summary>

  ```hcl
  resource "okta_authenticator" "fido2" { ... }
  ```

  </details>
  ```
- Ensure blank lines around markdown content inside `<details>` for kramdown
- Test syntax highlighting works correctly inside collapsed blocks

## Task 6: Source File Links

For each control in an HTH guide that has a corresponding code pack file:
- Add a link to the source file in the GitHub repo
- Format: `[View source](https://github.com/grcengineering/how-to-harden/blob/main/packs/okta/terraform/hth-okta-1.01-enforce-phishing-resistant-mfa.tf)`
- Include links for all types: Terraform, API script, Sigma rule(s)

## Task 7: Test Jekyll Build

After all changes:
- Run `cd docs && bundle exec jekyll serve`
- Verify collapsible sections render correctly
- Verify code syntax highlighting works inside `<details>`
- Verify GitHub source links resolve correctly
- Verify no blank-line violations around tables or HTML blocks
- Check mobile responsiveness of collapsible blocks

## Dependencies

- Task 1 must complete before Tasks 3-4 (snippets need to exist for includes)
- Task 2 must complete before Tasks 3-4 (template needs to exist)
- Tasks 3, 4, 5, 6 can run in parallel after Tasks 1-2
- Task 7 runs last as final verification

## Notes

- kramdown supports `<details>` natively -- no Jekyll plugins needed
- The `pack_snippets.yml` data file approach avoids needing Jekyll to access files outside `docs/`
- Consider caching the extraction script output to speed up Jekyll builds
- The include template should gracefully handle missing snippets (control exists in guide but not in pack)
