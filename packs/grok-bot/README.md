# Grok Bot packs

Use complete pack folders, including `api/common.sh`, and read each action's prerequisites before running it. Team API keys and Organization API keys are different authorities. These packs do not use Grok inference or workspace credentials. Enterprise, rollout and unavailable-surface limits remain documented in [the guide](../../docs/_guides/grok-bot.md).

The shared API transport accepts only `https://api.cursor.com` in production. It disables user curl configuration, limits connect time to 10 seconds and each request to 30 seconds, limits responses to 10 MiB, and follows no redirects. Basic credentials travel in stdin configuration, not process arguments; unsafe whitespace/control characters, colon, quotes and backslash are refused. Raw vendor error messages are suppressed. Environment proxy/TLS trust and the installed `curl`, `jq` and `base64` binaries remain operator-managed prerequisites.

Tests can explicitly set `HTH_LOOPBACK_FIXTURE=1` and `CURSOR_API_BASE=http://127.0.0.1:<valid-port>`. That escape accepts only the literal `HTH_SYNTHETIC_FIXTURE_KEY`; it refuses vendor credentials and other origins. It is not an alternate deployment endpoint. Offline regression tests use a private synthetic curl fixture and never authenticate to a vendor.

Verification exits 1 for findings, 2 for a failed precondition, and 3 with `RESULT: UNKNOWN` when an API cannot establish part of the control. A readable baseline, event window or current membership is not proof of complete policy or stable team identity. The offboarding/containment actions are separately documented runbooks with dry-run defaults; their exit 0 is an action result, not a compliance verdict. Cross-plane mutation requires an authoritative matching team ID and fails UNKNOWN when it cannot be established.

The offboarding pack's `delete_vm_and_data` action erases the computer and durable disk only. Bots and conversations remain. The broader native `delete_grok_bot_data` action is described separately in the guide and is not silently substituted by the pack. Review shared-Bot, Slack, routine, source-service credential and IdP effects independently.
