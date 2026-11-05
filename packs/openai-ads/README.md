# OpenAI Ads packs

These packs cover the Ads account/API plane. Ads account keys and OAuth grants are separate from ChatGPT workspace identity and API Platform Admin keys. See the [guide](https://howtoharden.com/guides/openai-ads/) and [source reconciliation](https://howtoharden.com/research/openai-ads-source-coverage/).

Download the complete directory; API scripts require `api/common.sh`. Inject credentials through a secret manager. Transport uses private staging and stdin curl configuration, ignores curlrc, bounds requests/responses, and restricts destinations to documented production origins. `HTH_FIXTURE_LOOPBACK=1` permits an explicit loopback fixture origin only; fixture values must not be credentials. Paginated inventory publishes no partial stdout when a later page fails, and errors omit raw vendor bodies. Set `umask 077` before redirecting stdout to a reviewed evidence destination outside this repository; caller-created files do not inherit the pack's private staging permissions.

Entrypoints validate `HTH_PROFILE_LEVEL` 1–4, defaulting to 1. Conversion validation forces `validate_only` and uses a private request body; review synthetic payloads before use. SDK files export functions and do not execute on import. Their isolated package and lock pin the official `openai` SDK to 7.51.0; install with `bun install --frozen-lockfile --ignore-scripts` inside `sdk/`.

Native configuration emitters produce only the documented Ads fields and do not change an account. Offline fixtures exercise SDK serialization, pagination, redaction and transport boundaries. No live Ads account, OAuth consent, campaign update, real conversion or new live-validation claim was performed.
