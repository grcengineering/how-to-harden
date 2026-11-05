# chatgpt-dots code packs

One current Compliance exporter (CODEX_LOG family) plus three native TOML emitters. Filter Dots records after collection using the current documented client identity; the exporter does not invent a family or normalized event schema.

Set HTH_PROFILE_LEVEL to the selected level (1–4); the default is1 and a higher-level pack refuses to run until explicitly selected. Emitters print native snippets for review; they neither deploy policy nor verify enforcement. Merge snippets into the documented requirements delivery plane, inspect /debug-config and test each supported runtime. Do not concatenate independent TOML documents without merging their tables.

The exporters require Bash, curl, jq, CHATGPT_WORKSPACE_ID (workspace UUID), CHATGPT_ADMIN_KEY and an explicit HTH_AFTER timestamp. Inject approved credentials without logging them. Use a private HTH_LOG_DIR outside source control; logs can contain sensitive workspace content. The helpers supply credentials through curl stdin and follow HTTPS redirects without forwarding credentials across origins. A completed file can remain after a later failed download; the per-family checkpoint advances only after the full page succeeds. An empty or failed collection is not evidence of compliance.

Current public ChatGPT Admin policy/identity mutation schemas were not verified in this refresh. Removed placeholder policies and historical route assumptions are recorded in the source ledger; no tenant setting or credential was created. No product write runs from these packs.

Offline tests: bun test scripts/test-openai-workspace-refresh.test.ts from repository root. Tests use public fixtures and local fake transports/CLIs; they establish local behavior, not tenant authorization or enforcement. See [source reconciliation](../../docs/research/openai-source-coverage.md).
