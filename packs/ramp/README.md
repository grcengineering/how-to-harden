# Ramp Code Packs

Documentation-derived, offline-tested examples. No live tenant validation is claimed. Review the [guide](https://howtoharden.com/guides/ramp/) before running. Assessment scripts and detections are read-only; the optional Chrome configuration in control 2.6 changes browser policy if an administrator deploys it. These are inventories and detections, not automatic enforcement or compliance verdicts.

## Requirements and execution

Use Bash, curl (supporting `--max-filesize`), Python 3, and an existing short-lived Ramp Developer API bearer token. Give it only the scopes listed in the selected pack's contract. Do not paste credentials into command history. For example, in an interactive Bash session:

```bash
read -rsp 'Ramp access token: ' RAMP_ACCESS_TOKEN; echo
export RAMP_ACCESS_TOKEN
umask 077
bash packs/ramp/api/hth-ramp-1.03-minimize-roles-and-privileges.sh > roles.json
unset RAMP_ACCESS_TOKEN
```

Keep the entire API directory together. The helpers are local standard-library JSON processing support, **not an official Ramp SDK**. The transport uses bash+curl and only `https://api.ramp.com`. Alternative origins are rejected, including sandbox; do not modify the origin for arbitrary servers. Curl configuration and proxy inheritance are disabled. The token is passed in a mode-0600 temporary configuration file, never in curl arguments, and removed on exit. Do not invoke under `bash -x`, run from an untrusted checkout, or store output in shared CI logs. Temporary responses may contain more fields than the projected report and reside in a mode-0700 temporary directory until exit.

Redirect reports only into an access-controlled directory. Files are not encrypted, immutable, or automatically retained by these packs. Use your approved encrypted log store, access control, retention, deletion and backup policies. The shell redirection is performed by your shell, so set `umask 077` **before** redirection. Failure exits nonzero without emitting a partial API report; the shell may still create an empty destination file. Use a temporary destination and rename it only on success if replacing existing evidence.

| Control | Scope / prerequisites | Output and limits |
|---------|-----------------------|-------------------|
| 1.3 | users:read | Users' base roles and custom-role capability catalog. Default users listing excludes suspended users. Custom roles are additive; this API does not join custom-role assignments to users or prove effective privileges. |
| 1.4 | users:read | Default user inventory plus explicit suspended-user inventory for comparison with approved HR/IdP rosters. Not an offboarding decision list. |
| 2.2 | Official CLI, existing login | Manual sign-in/access-level and identity review. No automatic login or changes. |
| 2.3 | accounting:read | Accounting provider metadata, current is_active and connection_type. Deprecated status is deliberately omitted; this does not assess balances or integration permissions. |
| 2.5 | Existing bearer token | Webhook subscription metadata. GET declares no named OAuth scope; do not infer this means unauthenticated access. |
| 2.6 | Managed Google Chrome on Linux; administrator/privacy approval | Inert native policy example; force-installs the Ramp extension if deployed. |
| 3.1 | funds:read, spend_programs:read | Fund and spend-program policy restrictions. No balances, card details or transaction data in output. |
| 5.1 | audit_logs:read, Ramp Plus | Projected audit NDJSON, requiring an explicit UTC interval. |
| 5.2 | SIEM ingestion and Sigma backend | Experimental security-change rule, not a configured SIEM connector. |

### Safe offboarding boundary

Ramp documents `PATCH /developer/v1/users/{user_id}/deactivate` with `users:write`. It prevents login, card spending and notifications. This pack intentionally does **not** implement it: the verified Developer API response cannot establish the caller's identity or a user's additive custom-role assignments. Base-role checks alone cannot safely protect every owner/admin/caller. Reconcile the report with HR and the authenticated administrator's console, confirm the exact person and privilege assignments, then perform approved deactivation using Ramp's supported workflow. No `--apply` or other mutation option exists; unexpected arguments fail.

### CLI review

Install and verify the official [Ramp CLI](https://github.com/ramp-public/ramp-cli) separately. If your policy permits enrollment, a human may explicitly run:

```bash
ramp auth login --read-only
bash packs/ramp/cli/hth-ramp-2.02-restrict-ai-connections-and-cli-access.sh
```

The login creates access and is not executed by the pack. The CLI may refresh an existing authorized session during identity lookup; the pack does not enroll a new connection. Current Ramp CLI uses your Ramp role, not OAuth scope selection; the old `--scope` flag is unsupported. Review `ramp auth status` for the access level. Reporting your identity does not itself demonstrate that access is read-only. Both commands force JSON output, and the identity lookup supplies the required `--rationale`. Source verification at [official CLI commit a29141b](https://github.com/ramp-public/ramp-cli/tree/a29141b5293c4e1ad15befc9587314b52c1b0bc6) found that `src/ramp_cli/commands/auth.py` emits authentication state, base URL, granted-scope names and access level, not token values; `src/ramp_cli/specs/agent-tool.json` maps `users me` to the read-only identity lookup and requires rationale. Authentication status includes every configured environment, even though the identity lookup explicitly targets production. Treat identity and configuration output as private.

### Webhook receiver requirements

The inventory does not authenticate deliveries. Implement the documented `X-Ramp-Signature` check in the receiver: HMAC-SHA256 using the subscription secret and **exact raw request body**, compared in constant time before parsing or accepting work. Do not reserialize JSON before verification. Follow the current [webhook authentication reference](https://docs.ramp.com/developer-api/v1/webhooks). Signature validity alone does not prevent replay; persist the verified payload's documented `id` (business-event `X-Ramp-Webhook-ID` matches it) in a durable, atomic deduplication store before processing side effects and retain it for your replay/retry window. Do not use process memory as the replay ledger. TLS endpoint inventory cannot prove any of these controls.

### Audit collection and detection

```bash
export RAMP_FROM_UTC=2026-11-01T00:00:00Z
export RAMP_TO_UTC=2026-11-02T00:00:00Z
umask 077
bash packs/ramp/api/hth-ramp-5.01-collect-and-preserve-audit-logs.sh > audit.ndjson
```

Use `YYYY-MM-DDTHH:MM:SSZ` UTC values with start before end. Ramp's date filters are inclusive; overlapping runs can repeat events. Deduplicate by `id` in your durable ingestion pipeline and preserve collection-window metadata separately. Output is a **projection**, retaining `id`, `event_time`, `event_type`, `actor_id`, `actor_type`, not a full-fidelity forensic archive. Preserve full source logs separately using an approved collection pipeline if required. Null actor IDs are allowed. No access denied, malformed response or exhausted pagination is treated as an empty successful audit.

All paginated packs require documented `data` and `page.next`, allow at most 1,000 pages (lower this with `RAMP_MAX_PAGES`), and validate HTTPS origin, exact resource path, duplicate parameters, cursor presence and unchanged filters before following the next URL. They reject unexpected URL shapes rather than silently dropping filters. There are no automatic retries. Narrow collection windows if bounds are exceeded. APIs are not claimed to provide snapshot consistency while administrators are changing data.

Ingest each NDJSON line as an event and map the Sigma `ramp/audit_logs` logsource to your actual SIEM dataset. Preserve the five output field names or configure equivalent backend mappings. No index, table, connector or normalized vendor field is assumed. Test and tune the experimental rule with authorized changes before enabling alerts; valid changes are expected false positives. The rule detects only its listed documented event strings, not every security-relevant change.

## Offline verification

```bash
python3 scripts/test-ramp-packs.py
```

Tests substitute curl and ramp with local mocks. No live tenant, credentials, installation or network requests are used. Response projections were derived from [Ramp OpenAPI](https://docs.ramp.com/openapi/developer-api.json), retrieved 2026-11-08. CLI commands were checked against [official CLI documentation](https://docs.ramp.com/developer-api/v1/cli). The schema subset validates fields consumed by the reports; it is not a complete OpenAPI validator.

## Managed Chrome deployment: control 2.6

The configuration example in `config/hth-ramp-2.06-deploy-ramp-browser-phishing-protection.jsonc` is inert until an administrator deploys it. Its contract is **mutating** because applying it changes managed-browser policy and force-installs Ramp for Chrome. Unlike the assessment scripts, it is not read-only. It is a native Chrome policy example for **Google Chrome on Linux**, not a Ramp API setting, a Google Admin import format, a Windows registry file, or a macOS configuration profile. Chromium distribution paths may differ.

The [Ramp administrator instructions](https://support.ramp.com/install-ramp-for-chrome-for-employees-in-google-admin/) identify extension `idefohglmnkliiadgfofeokcpjobdeik`. Google's [ExtensionInstallForcelist policy](https://chromeenterprise.google/policies/?policy=ExtensionInstallForcelist) and [Chromium policy definition](https://github.com/chromium/chromium/blob/main/components/policy/resources/templates/policy_definitions/Extensions/ExtensionInstallForcelist.yaml) specify a list of extension-ID/update-URL strings and the Chrome Web Store update URL used here. The update URL controls initial installation; later updates normally follow the extension manifest. No undocumented Ramp toggle is configured.

**Approval and privacy:** Force installation silently installs the extension and implicitly grants its requested permissions. Users cannot disable or uninstall the force-installed extension through Chrome. Ramp says License Intelligence tracking is enabled by default when the extension is force-installed; employees can opt out in the extension settings. Obtain administrator/security and privacy approval for the target devices, scope, permissions and employee communication before deployment. A phishing-protection use case does not remove this separate software-usage tracking consequence. This file does not disable tracking, guarantee complete phishing prevention, or prove the extension is active for every user. The policy does not apply to Incognito mode.

**Prepare, merge and review:** The repository artifact has comment lines for documentation. Remove those lines to create a JSON candidate in a working directory, not directly in a managed policy directory:

```bash
sed '/^[[:space:]]*\/\//d' packs/ramp/config/hth-ramp-2.06-deploy-ramp-browser-phishing-protection.jsonc > proposed-ramp-policy.json
python3 -m json.tool proposed-ramp-policy.json
```

Review existing effective Chrome policies and their source first. Back up the current administrator-controlled configuration. If `ExtensionInstallForcelist` already exists, merge **only** the Ramp entry into its existing array, preserving all other entries. Do not replace the existing array with this one-entry example, do not duplicate the key across files, and do not override conflicting cloud-managed `ExtensionSettings` or extension policies without resolving their intended precedence. Use your organization's existing configuration-management system and a small pilot group before wider deployment.

The [official Linux quick-start](https://www.chromium.org/administrators/linux-quick-start/) specifies `/etc/opt/chrome/policies/managed/` for required Google Chrome policies in JSON files. Only the approved, merged, comment-free JSON belongs there. Administrator ownership and write protection are required; do not allow ordinary users to edit managed policy files. These instructions do not perform or authorize a local filesystem deployment themselves. For Google Admin-managed users and browsers, use Ramp's documented OU/group console workflow instead of treating this JSON as an import file.

**Verify and roll back:** In the targeted Chrome installation, review `chrome://policy` for the effective `ExtensionInstallForcelist` value and policy errors; reload policies if needed. Check `chrome://extensions` for the Ramp extension's exact ID and managed installation status. Confirm its intended protection works using an approved harmless test and verify employee tracking choices/notice. No live validation is claimed here. For rollback, remove only the Ramp entry from the authoritative policy and preserve other extensions and keys. Google documents that removing a previously force-installed extension from this list automatically uninstalls it; consider loss of the extension's protection and workflows, and check for another management source that still forces installation. If this pack introduced a standalone file and no other settings were added to it, the administrator may remove that file through the same approved configuration workflow. Verify the resulting effective policy and extension state rather than assuming rollback succeeded.
