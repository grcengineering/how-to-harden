# Poke Code Pack

Companion to the [Poke guide](https://howtoharden.com/guides/poke/). Sources fetched 2026-11-05: [API](https://poke.com/docs/api), [CLI/recipes](https://poke.com/docs/creating-recipes), [MCP/tunnels](https://poke.com/docs/mcp-servers). Poke has a separate account and does not inherit Devin SSO.

| Control | Pack | Default and limits |
|---------|------|--------------------|
| 1.2 | CLI identity | Runs only whoami using trusted preinstalled local package; private evidence, no login/account change |
| 2.1 | API message | Offline JSON preview; --send performs one action-capable POST with existing V2 key |
| 3.2 | CLI tunnel | Preview only; --start begins attended loopback exposure, Ctrl+C ends it |

Prerequisites: Bash and jq; curl only for explicit API send; npx plus an independently approved already installed Poke package for CLI use. These scripts never install/download a product package or create credentials. Run from the trusted project containing that package. Set an existing trusted HTH_EVIDENCE_DIR for identity evidence (new mode-0700 directory, mode-0600 files). Review contents privately; do not commit evidence. npm offline/no-install prevents network package fetches but is not package authenticity validation.

API preview: select HTH_PROFILE_LEVEL=2 (or 3/4), then invoke the API script with a reviewed FILE.json containing exactly one nonempty JSON object. JSONL/multiple values are rejected. Entire body is assistant context with connected email/calendar/integration authority. The 64 KiB ceiling is HTH policy, not an asserted vendor limit. Only --send uses POKE_API_KEY injected from a secret manager. It rejects legacy pk_ keys, redirects, invalid acknowledgment and transport errors. No automatic retry: an uncertain delivery may have already caused actions. HTTP/API delivery does not prove downstream completion or authorization. No administrative read interface or SDK is invented from generic HTTP examples.

Tunnel preview requires HTH_PROFILE_LEVEL=2 (or 3/4) and takes http://127.0.0.1:PORT/mcp and a reviewed name. Only --start invokes the vendor CLI; the MCP service must already be independently secured. No background process or enrollment is created by preview. Tool sync and credential revocation must be reviewed separately.

Exit 0 means only the documented preview/collection/acknowledgment completed; exit 2 means unknown/invalid/failed prerequisites. An attended tunnel propagates the first-party CLI exit status.

Validation: bun test --timeout 30000 scripts/test-cognition-refresh.test.ts uses synthetic JSON and offline curl/npx stubs. No real message, identity lookup, tunnel, login or key creation occurred. UI/consent, private enterprise interfaces, actual package runtime and downstream policy remain unverified.
