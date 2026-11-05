# Grok API packs

Download this complete folder. The numbered Bash entrypoints execute adjacent Bun/TypeScript helpers; copying only a rendered three-line entrypoint is insufficient. Bun is required. The native automation contract is REST; these helpers are not a vendor SDK.

| Entrypoint | Required existing authority | Output and boundary |
|---|---|---|
| `api/hth-grok-api-1.02-audit-inference-keys.sh` | `XAI_MANAGEMENT_API_KEY`, `XAI_TEAM_ID`, `HTH_TEAM_ADMIN_CONFIRMED=1` | Authenticates the management key's authoritative team scope, then paginates all key metadata. The admin attestation is required because member keys list only their own keys. Counts expiry, ACL and limit review conditions; no key values or names printed |
| `api/hth-grok-api-3.01-audit-public-file-links.sh` | `XAI_API_KEY`; optional `HTH_MAX_PUBLIC_URL_HOURS` (default 24) | Lists file metadata for that inference key's authority. Counts public URLs, unbounded links and over-policy expiry. Does not fetch or print URLs, names or contents |
| `api/hth-grok-api-5.01-count-audit-events.sh` | `XAI_MANAGEMENT_API_KEY`, `XAI_TEAM_ID`, `HTH_AUDIT_FROM`, `HTH_AUDIT_TO` | Verifies team scope and counts paginated administrative event metadata within the explicit ISO timestamp window. This is a count, not a retained evidence export |
| `config/hth-grok-api-4.03-prepare-moderation-request.sh` | None | Emits synthetic JSON containing native request moderation fields. Offline preparation only; no inference or enforcement occurs |

Run an entrypoint with `bash path/to/entrypoint.sh`. Reads use fixed first-party HTTPS hosts, GET only, bounded pagination, no redirect forwarding and suppressed response bodies on error. An inventory returns JSON `status: REVIEW` with exit 0 when the read completes; this means operator review is required, not whole-control compliance. Missing credentials, schema drift, transport failure or incomplete evidence return JSON `status: UNKNOWN` with exit 3. Bash preconditions such as missing Bun exit 2.

No pack creates, rotates, disables or deletes a credential, changes team settings, revokes links or removes stored data. Apply the separately documented native lifecycle actions after reviewing ownership and impact. Sources and live-test limitations are in [the guide](../../docs/_guides/grok-api.md) and [coverage ledger](../../docs/research/spacexai-source-coverage.md).
