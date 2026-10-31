# Factory Code Pack

23 packs support sixteen of the nineteen controls in the [Factory hardening guide](https://howtoharden.com/guides/factory/). They use documented Factory organization settings, REST reads, the first-party Droid CLI and the official Python SDK. Domain/SSO setup, SCM installation associations and managed connector availability retain their documented console/IdP/SCM workflows.

**Validation scope:** documentation checks and offline mocks only. No Factory tenant, IdP, live SDK catalog, policy engine or sandbox was exercised. The guide remains `ai-drafted`.

## Contents

| Type | Files | Purpose |
|------|-------|---------|
| `config/` | 11 JSONC fragments, 3 shell generators | Organization policy candidates; generators print JSON without installing it. |
| `api/` | 3 verification scripts | Member inventory, workload-key metadata and managed-settings revision history. |
| `cli/` | 5 verification scripts | Candidate/resolved permission previews, MCP/approval inventory, installed plugins, available tools and visible computers. |
| `sdk/` | 1 Python verification script | Compare the selectable model catalog with reviewed model IDs, without opening a session or making a model call. |

`common.sh` and `api/common.sh` are shared helpers, not additional control packs. Download the whole directory if running a shell pack. No Terraform provider, GraphQL endpoint, general audit-log export route, SIEM table or deprecated scanner definitions are fabricated.

## Safe use

Run scripts explicitly with Bash or Python from a trusted checkout. Use an approved, supported Droid release. Native permission rules additionally need organization rollout activation. Documentation was checked across 2026-10-30 and 2026-10-31; no installed Factory version was tested.

All scripts validate `HTH_PROFILE_LEVEL` (1–4, default 1) and refuse to run below their minimum. JSONC templates have a fixed profile in the header and no runtime gate. Inspect each fragment before deploying it; do not bulk-apply every pack.

Configuration fragments belong at **organization scope**. Merge them with the existing policy, preserving unrelated fields, and validate the complete result through the supported management workflow. The CLI candidate check validates permission rules only, not the entire organization schema. Never copy one fragment over an existing managed settings file. A present invalid system-managed file resolves to **empty org policy**; successful JSON parsing alone does not prove schema validity or enforcement.

The system-managed file takes precedence over remote org settings. Deployment locations are macOS `/Library/Application Support/Factory/settings.json`, Linux/WSL `/etc/factory/settings.json`, and Windows `C:\Program Files\Factory\settings.json`. Protect that file and any referenced hook scripts through endpoint management. No pack here writes those locations.

## Inputs and results

Scripts use `jq`, Python 3 and Bash; API scripts also use `curl`. The live Python SDK requires Python 3.10+, the official `droid-sdk` package, a supported `droid` binary and authenticated CLI state or an injected Factory credential. Offline tests do not install or invoke the real SDK.

| Pack | Required inputs beyond profile level | Result |
|------|-------------------------------------|--------|
| API 1.2 | `FACTORY_API_KEY`, `FACTORY_MEMBERS_OUTPUT` | Complete paginated user inventory; does not establish roles or SCIM ownership. |
| API 1.3 | Human Manager/Owner `FACTORY_API_KEY`, `FACTORY_KEYS_OUTPUT` | Service accounts and key metadata, including revoked/expired records; no credential creation or revocation. |
| API 5.2 | Authorized human admin `FACTORY_API_KEY`, `FACTORY_HISTORY_OUTPUT` | Complete paginated settings history, not the full organization audit log or effective device policy. |
| CLI 2.2 | `FACTORY_PROJECT_DIR`, `FACTORY_SETTINGS_FILE`, `FACTORY_RULE_REPORT_OUTPUT` | Candidate and resolved JSON previews for `git push origin main`; the command is never executed. |
| CLI 3.1 | `FACTORY_PROJECT_DIR`, `FACTORY_MCP_OUTPUT` | Private server and persistent-approval inventory. Runtime components can load; use a trusted managed project. |
| CLI 3.2 | `FACTORY_PROJECT_DIR`, `FACTORY_PLUGINS_OUTPUT` | Private installed-plugin list; installation is not effective enablement. |
| CLI 2.5 | `FACTORY_PROJECT_DIR`, `FACTORY_TOOLS_OUTPUT` | Available tools from `droid exec --list-tools`; exits without a model task. |
| CLI 4.4 | `FACTORY_PROJECT_DIR`, `FACTORY_COMPUTERS_OUTPUT` | Computers visible to the authenticated identity; no provisioning/removal. |
| Config 4.1 | `FACTORY_ALLOWED_IPS_FILE` | JSON source-IPv4 policy fragment; no defaults, no automatic deployment. |
| Config 4.2 | `FACTORY_APPROVED_MODEL_IDS_FILE` | JSON model allowlist, no user BYOK or automatic future-model admission; separate image-generation disablement. |
| Config 5.1 | `FACTORY_OTLP_ENDPOINT` | JSON org telemetry fragment with a literal `${FACTORY_OTLP_TOKEN}` credential reference. |
| SDK 4.2 | `FACTORY_PROJECT_DIR`, `FACTORY_APPROVED_MODEL_IDS_FILE`, `FACTORY_MODEL_OUTPUT`; authenticated Droid | Compare selectable IDs to the reviewed list; privately retain drift details. |

`FACTORY_PROJECT_DIR` must be an absolute trusted directory. Approval input files are strict JSON arrays: nonempty IPv4 addresses/CIDRs or unique current model IDs. `FACTORY_SETTINGS_FILE` is a reviewed strict JSON settings object containing `permissionRules`; strip JSONC comments during your configuration preparation. The CLI pack extracts that container because `droid rules check --file` rejects a full settings wrapper.

Evidence output paths must name **new files in existing trusted directories outside version control**. Scripts refuse existing files and symlinks and create evidence with mode 0600. The private data may contain identities, settings and configured server information. Keep it under the organization's access and retention rules. Standard output contains only collection status/counts or generator output, not API response bodies or tokens.

Inject `FACTORY_API_KEY` through a secret manager. The API transport sends the header through curl's stdin, disables user curl configuration, uses the fixed `https://api.factory.ai` origin, requires HTTPS, refuses redirects, and never mutates an API resource. `FACTORY_API_BASE` overrides are rejected. Service-account administration APIs require a **human Manager or Owner**; a workload's service-account key is not accepted for this administration surface.

| Exit code | Meaning |
|-----------|---------|
| `0` | Collection/generation/check completed. For SDK catalog verification only: the selectable IDs matched. A collection result is not a hardened-state verdict. |
| `1` | SDK catalog differs from the approved list. |
| `2` | Unknown/not run: missing precondition, invalid input, HTTP/SDK/CLI error, incomplete evidence or refused output path. |

Pagination uses documented `limit=100` and cursor parameters. A page limit, repeated cursor, inconsistent envelope, malformed record or later-page error discards partial evidence. `HTH_MAX_PAGES` defaults to 1000 (valid 1–9999). Inventory APIs without documented pagination are not assigned invented paging parameters.

## Examples

After injecting a human admin credential, collect members into a new private file:

```bash
HTH_PROFILE_LEVEL=1 FACTORY_MEMBERS_OUTPUT=/trusted/evidence/factory-members.json \
  bash packs/factory/api/hth-factory-1.02-inventory-members.sh
```

Generate a model-policy candidate from an already reviewed current ID list:

```bash
HTH_PROFILE_LEVEL=2 FACTORY_APPROVED_MODEL_IDS_FILE=/trusted/policy/models.json \
  bash packs/factory/config/hth-factory-4.02-build-model-policy.sh
```

Do not pipe a generator directly into a managed-policy location. The source-IP generator cannot verify your current egress or recovery path; prove both before applying its output. The telemetry generator prints a credential reference, not a secret. Provision `FACTORY_OTLP_TOKEN` separately on managed devices; missing variables disable the customer sink for that session.

## Limits to preserve

- Built-in Search/Fetch and Factory-managed connector availability have separate controls from MCP. Connector availability has no verified public configuration endpoint; it is console-only in this guide.
- Native rules match ordered tokens, not every equivalent command. `git -C /repo push` is intentionally a nonmatch for the sample `git push` prefix. Checker exit 0 is independent of the preview decision and does not enable enforcement.
- Sandbox reads default to allowed except `denyRead`; Factory/WorkOS domains remain permitted. Whole-process behavior depends on host support. The sample GitHub domain list needs review for each workflow.
- MCP allowlisting is disabled unless `enabled` is true. Remote matchers constrain hostnames, not scheme, port or path; broad stdio launcher matchers can admit unrelated packages.
- Strict plugin policy can disable Factory defaults. Organization-added marketplaces remain admitted, and removed policy can reactivate previously installed plugins.
- Managed-hook loading policy does not protect a user-writable script or make nonblocking hook errors fail closed. Organization-enabled plugin hooks remain eligible.
- Model-policy IDs do not govern image models. Unknown IDs may be dropped; verify the resolved catalog. The starter disables user BYOK and does not configure a private inference gateway.
- Customer telemetry settings do not disable Factory's own collector. Aggregate metadata still includes session/repository/tool information. Raw content opt-in has no secret or PII redaction.

## Offline verification

```bash
python3 scripts/test-factory-packs.py
bash scripts/sync-packs-to-data.sh
bash scripts/validate-guides.sh
bash scripts/validate-packs.sh factory
shellcheck -x -P SCRIPTDIR packs/factory/common.sh packs/factory/api/*.sh \
  packs/factory/cli/*.sh packs/factory/config/*.sh
```

The pack validator still scans the full corpus even with a vendor argument; that argument scopes the coverage report. Compare pre-existing findings with the baseline and read the touched-file verdict after a local commit. See [source evidence](../../docs/research/factory-source-evidence.md) for per-control surfaces and the [validation report](../../docs/research/factory-validation.md) for the actual results and untested live behavior.
