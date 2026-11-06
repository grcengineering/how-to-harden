# chatgpt-work-codex code packs

Two read-only vendor CLI wrappers and nine native TOML emitters for local supported clients, including configuration-server bootstrap. Native policy support and precedence depend on runtime/version; local policy does not govern every hosted executor.

Set HTH_PROFILE_LEVEL to the selected level (1–4); the default is1 and a higher-level pack refuses to run until explicitly selected. Emitters print native snippets for review; they neither deploy policy nor verify enforcement. Merge snippets into the documented requirements delivery plane, inspect /debug-config and test each supported runtime. Do not concatenate independent TOML documents without merging their tables.

The Security wrapper invokes info and scan --dry-run only, using a trusted external non-symlink configuration. Review executable MCP/config content before any real scan. Configuration-server delivery needs an administrator-owned device bootstrap and server-side authentication where required.

Current public ChatGPT Admin policy/identity mutation schemas were not verified in this refresh. Removed placeholder policies and historical route assumptions are recorded in the source ledger; no tenant setting or credential was created. No product write runs from these packs.

Offline tests: bun test scripts/test-openai-workspace-refresh.test.ts from repository root. Tests use public fixtures and local fake transports/CLIs; they establish local behavior, not tenant authorization or enforcement. See [source reconciliation](../../docs/research/openai-source-coverage.md).
