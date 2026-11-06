# Claude Enterprise packs

These packs support the [Enterprise guide](https://howtoharden.com/guides/claude-enterprise/). They do not reproduce the native Security Center score or configure every product. The [research ledger](../../docs/research/anthropic-source-coverage-2026-11.md) records sources, scope, interface versions and unknowns.

| Pack | Purpose and authority |
|------|-----------------------|
| API 1.03 | Members, custom roles and permissions; existing `read:members` Admin key |
| CLI / SDK 1.03 | Native official `ant` / `@anthropic-ai/sdk` membership reads |
| API 1.04 | Read target by default; optional exact-user-confirmed sign-out needs `write:members` and the documented beta |
| API 2.01 | Bounded child-org Activity Feed export; existing `read:compliance_activities` key |
| API / CLI / SDK 2.02 | Native Compliance recording singleton; existing authorized admin credential, minimum selectable Enterprise scope unverified; never creates/broadens a key |
| API 2.04 | Effective settings compared with an explicit operator baseline; existing `read:compliance_org_data` key, per-parent feature enablement |
| Config 3.06 | Emit macOS Desktop profile or Windows HKLM policy; no installation or tenant change |
| API 4.01 | Complete effective monthly spend-limit read; `read:spend_limits` |
| Sigma 2.01 | Experimental rule for the documented inference-hook circuit-breaker activity; requires ingest mapping |

Use Bash, curl, jq and Node.js 22+ where declared. SDK: install its pinned lockfile with `bun install --frozen-lockfile --ignore-scripts` in `sdk/`. CLI: official `ant` 2.7.0 or a separately verified compatible release. The CLI helper clears ambient Anthropic credentials/profiles and uses an empty private config directory, a fixed first-party HTTPS host and stdin key. Its JSON item stream is normalized; it is not a native page-envelope validator. Use the API/SDK evidence paths for strict response-metadata validation. No key is created by a pack; inject existing scoped credentials through your approved secret workflow.

The settings assessor requires `HTH_ORGANIZATION_ID` (linked child bare UUID) and `HTH_BASELINE_FILE`. That file is an **HTH assessment input**, not Anthropic configuration or the native checklist. For example, after reviewing plan applicability and your policy, a file could contain:

```json
[
  {"name":"sso_claude_ai_enforced","type":"boolean","value":true},
  {"name":"directory_sync_enabled","type":"boolean","value":true},
  {"name":"account_session_duration_seconds","type":"integer","value":604800},
  {"name":"connector_tools_default_always_allow","type":"boolean","value":false}
]
```

The seven-day duration comes from the published Cowork baseline, not an asserted native posture check. Choose values appropriate to your data, plan, schedules and approved exceptions. Missing rows return unavailable, never false. Exact matches exit 0; differences exit 1; unavailable/unknown/invalid/incomplete evidence exits 2 (transport failures also exit nonzero). Match means only agreement with the input baseline. Raw settings include key metadata and internal configuration, so protect the private evidence directory and apply an approved retention policy.

The Desktop emitter needs an organization UUID and a nonempty JSON list of narrow approved folders in `HTH_WORKSPACE_FOLDERS`. Run it with `macos` (default) or `windows` and review the emitted payload before deployment. The Desktop policy domain/HKLM path is separate from Code policy. Optional EDR fields require an approved vendor/package pair; the emitter does not download or install it. XML/registry parsing is not proof of effective MDM enforcement.

For sign-out, read the guide's account/session scope and residual work first. The default only retrieves the target. Mutation additionally requires `HTH_APPLY=1` and `HTH_CONFIRM_USER_ID` exactly matching the selected user. It cannot target the Primary Owner and does not revoke API keys, stop cloud jobs/routines or unlink computers. No mutation is a default validation step.

Government, provider-specific endpoints and live tenant/device behavior are outside these packs' tested boundary. No live credentials or tenant were used in validation.
