# Statsig code packs

Nine numbered packs support seven of the guide's thirteen controls. They cover observed project/review settings, paginated key metadata, a native private-user parameter, Siggy version, two native Terraform settings and an actual web-analytics plugin factory. Manual identity, SCIM, pre-commit, MCP, warehouse and audit instructions are not represented by invented policy files or endpoints.

Download this directory with its structural helpers. Bash entrypoints require Bash, curl, jq and Bun. Set `HTH_PROFILE_LEVEL` to the selected 1–4 profile; L2 packs require at least 2. Inject approved credentials through the environment without logging them. These packs create no credentials.

## Reads and local generation

Set `STATSIG_OUTPUT` to a **new absolute file outside the repository**, with an existing private parent directory. Existing files/symlinks and paths inside this checkout are refused; output is created mode0600. Evidence can still contain project names, key descriptions/scopes and reviewed user attributes. Keep it out of source control, logs and shared artifacts.

| Entry point | Additional input | Actual effect |
|-------------|------------------|---------------|
| api/hth-statsig-1.02-read-project-boundary.sh | STATSIG_CONSOLE_KEY | GET project settings; selected fields only |
| api/hth-statsig-2.01-inventory-key-metadata.sh | STATSIG_CONSOLE_KEY | GET up to100 pages/10000 key records, replace key values with SHA-256 fingerprints |
| api/hth-statsig-3.01-read-review-flags.sh | STATSIG_CONSOLE_KEY | GET flags; preserves false and omitted optional flags |
| api/hth-statsig-5.02-read-existing-deletion-status.sh | STATSIG_SERVER_KEY, STATSIG_REQUEST_ID | POST **status read only** for a previously authorized existing request |
| config/hth-statsig-2.02-prepare-private-user.sh | STATSIG_USER_INPUT file | Emit native StatsigUser subset; no SDK initialization or request |
| cli/hth-statsig-3.03-inventory-siggy-version.sh | Approved installed siggy | `siggy --version` only; no config/credential read |

REST origins/operations are fixed. Keys are supplied to curl through stdin configuration rather than process arguments. Redirects and base-origin overrides are not supported. Responses are bounded, validated and privately staged; failed/partial collection produces no complete output. UNKNOWN is nonzero. Collection is not a compliance or enforcement verdict. The key collector refuses unexpected response contracts, duplicate fingerprints, hostile pagination and incomplete reported totals. It cannot prove caller visibility covers every personal/organization credential.

The local user input deliberately supports only `userID`, `email`, `ip`, `userAgent`, `country`, `locale` and a flat primitive `custom` object. Provide an independently selected pseudonymous `userID`; it is not anonymized here. Other fields are moved to `privateAttributes`. Reserved/duplicate/nested/unsupported fields and JavaScript magic keys `__proto__`, `constructor` and `prototype` are refused as a local pack restriction. Review the resulting native object before passing it to your supported SDK. **Browser initialization still sends private attributes for evaluation**; this is log minimization, not a no-egress policy, consent system or deletion tool.

The deletion status endpoint uses POST but does not submit deletion. It accepts recognized PENDING/COMPLETE values; UNKNOWN or malformed output fails. Deletion submission, retries and uncancellable requests remain in your separate approved privacy process.

## Terraform

Use the complete terraform directory with Terraform>=1.7 and pinned `statsig-io/statsig`2.2.1. Inject `STATSIG_CONSOLE_KEY`; never put its resolved value in HCL. Protect plan/state artifacts. `terraform init -backend=false`, `terraform validate` and `terraform test` can validate the schema and mocked plans without tenant credentials. Do not run apply as an assessment check.

Both resources default to zero instances. Opting in requires reviewed existing project values or an explicit snapshot of the other review flags. The key identifies the target project; cross-check the read-only evidence and console before a plan. `statsig_settings_project` Create updates that existing project, has no ImportState implementation and Delete is a no-op. This recipe requires a nonempty existing default unit type and preserves the existing name; use the console for null-default projects. Reviews require an explicit Cloud/Warehouse Native declaration and preserve the supplied other flags. These resources do not enforce per-role/environment bypass or granular creation roles. Role API updates can reset granular creation permissions; no such role writer is supplied.

Review the plan with an independent administrator before any explicit apply. Roll back settings using a reviewed prior snapshot or the console; deleting Terraform state/configuration does not reverse a vendor setting. `prevent_destroy` protects Terraform's managed instance, not the underlying SaaS from other writers. No import, plan against a tenant or apply was performed during authoring.

## SDK

In sdk, use `bun install --frozen-lockfile --ignore-scripts` for the exact locked `@statsig/web-analytics`3.33.7. Import `limitedCaptureOptions` or `createLimitedCapturePlugin` into an already reviewed browser application. No client is initialized here. Defaults reject all capture; opt in only exact approved HTTPS page URLs without query/fragment. The filter permits page-view events and disables copied text and console logs.

The filter reads actual browser `window.location.href` independently and requires matching native `page_url` and `current_url`; query parameters can otherwise overwrite those metadata fields in3.33.7. Missing browser context, query/fragment-bearing location and mismatches are denied. This does not redact all page-view metadata, manual events or user identity; it does not govern another plugin, consent or Session Replay. Disabled SDK logging can buffer events and replay them when logging resumes, so gate initialization/event generation when consent requires it. Test actual payloads and console overrides with synthetic data before deploying. Withdraw/revert the application's plugin configuration through its normal release process.

## Verification

`bun test scripts/test-statsig-packs.test.ts` from the repository root runs offline transport fixtures, failure/partial-output cases, native user-object checks and the real plugin constructor/filter without SDK initialization. ShellCheck and Terraform mocked plan tests cover their respective entrypoints. See [validation evidence](../../docs/research/statsig-validation.md) and [source coverage](../../docs/research/statsig-source-coverage.md) for exact results and unresolved interfaces. No tenant or integration is contacted by the tests.
