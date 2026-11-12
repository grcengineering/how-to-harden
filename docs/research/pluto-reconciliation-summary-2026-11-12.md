# Pluto Security reconciliation — 2026-11-12

## Scope and disposition

The [source inventory](pluto-source-inventory-2026-11-12.md) enumerates all 82 published blog articles, all nine Plutonium references, and the six website sitemap families. Pagination was checked against the site's actual archive data source, not merely repeated archive pages. Every blog article links to a disposition. Vendor documentation was used to validate configuration claims; Pluto's advice was not treated as an API specification or proof of current product behavior.

Changes cover 15 guides: Anthropic API, Claude Code, Claude Enterprise, ChatGPT Dots, Grok Bot, Microsoft Copilot Studio (new), Microsoft 365 (product navigation), GitHub, Cursor, Devin Desktop, CircleCI, GitLab, Google Workspace, Microsoft Intune, and n8n (new). Copilot Studio has 14 controls; n8n has six. Existing controls were reused where sufficient rather than duplicating recommendations.

## Reconciliation ledgers

- [Anthropic](pluto-anthropic-reconciliation-2026-11.md): Code, Cowork, Tag, Managed Agents, API and Enterprise boundaries.
- [OpenAI](pluto-openai-reconciliation.md): Dots, Codex, local/cloud execution and approval boundaries.
- [Grok](pluto-grok-bot-reconciliation.md): Bot sharing, credentials, routines, Slack and execution controls.
- [Copilot Studio](pluto-copilot-reconciliation-2026-11-12.md): identity, maker credentials, connectors, DLP, publication and audit surfaces.
- [Browser management and n8n](pluto-browser-n8n-reconciliation-2026-11-12.md): extension provenance and policy, workflow credentials and execution boundaries.
- [Cross-cutting sources](pluto-crosscut-20261112.md): supply-chain and developer-tool controls plus individually disposed contextual/marketing articles.

## Validation and limitations

Guide structural validation passes without warnings and the Jekyll production build succeeds. Offline regression coverage includes Anthropic, OpenAI, Grok, Devin, Copilot Studio, browser-inventory and supply-chain pack tests. Tests use fixtures/mocks or configuration checks; they do not establish live tenant enforcement or justify a tenant-validated badge. Native configuration artifacts must be adapted and reviewed before deployment; no production settings were changed.

Purpose-built Trust Centers and automation surfaces were considered in each product ledger. Gated assurance documents, undocumented write schemas and untested tenant behavior remain explicitly unverified. A public catalog failing to reveal a guide is not a claim that no private guide exists. No fabricated APIs or policies were added to fill these limits. Article-specific incident allegations and broad recommendations without a validated product control were excluded or mapped to existing controls with a stated reason.

Publication is pending pull-request review and merge; a local site build is not evidence of live howtoharden.com deployment.
