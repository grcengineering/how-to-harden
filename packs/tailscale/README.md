# Tailscale Code Pack

27 source packs support 17 of the 18 controls in the [Tailscale guide](https://howtoharden.com/guides/tailscale/). The remaining control, upstream IdP MFA, retains an evidenced manual verdict. Packs use the documented REST API, first-party CLI, native tailnet policy, official Terraform resources/data sources, maintained Go SDK, and configuration-log JSON in Splunk.

**Validation scope:** documentation and local tests only; no live tailnet, identity provider, endpoint, SIEM or credentialed API was exercised. The guide remains `ai-drafted`. See [source evidence](../../docs/research/tailscale-source-evidence.md) and [verification results](../../docs/research/tailscale-validation.md).

## Contents

| Surface | Packs | Purpose |
|---------|-------|---------|
| `api/` | 11 shell packs | Users, settings, device keys, raw policy/ETag, candidate validation, known trust credentials, visible auth keys, route approvals, inbound external devices, audit logs and stream status. |
| `config/` | 1 generator, 4 JSONC fragments | Complete minimal grants candidate; restricted tag owners, SSH check mode, posture conditions and CI service access. |
| `cli/` | 3 shell packs | Local Tailnet Lock status, Funnel configuration and installed client version. |
| `terraform/` | 6 control packs | Users/devices/policy data sources; optional settings, device expiry, complete policy, subnet routes and existing S3 log destinations. |
| `sdk/` | 1 Go pack | Device inventory through the maintained official SDK, pinned to 2.12.0. |
| `siem/` | 1 SPL query | Investigation of configuration changes using documented JSON fields. |

`common.sh`, `api/common.sh`, `terraform/provider.tf`, dependency files and tests are support files, not extra control packs. Download the whole vendor directory. The generated guide excerpts call these helpers and are not standalone scripts.

## Safe defaults and outputs

- Shell/SDK operations are read-only. The only REST POST targets `/acl/validate`; no policy-apply, device-approval, key-creation, node-signing or publication operation is implemented.
- Scripts validate `HTH_PROFILE_LEVEL` (1–4, default 1); a lower level than the pack requires fails before network/CLI work. Terraform uses the separate `TF_VAR_hth_profile_level` input. Native fragments and SPL have fixed review labels rather than runtime environment gates.
- Terraform defaults to zero managed resources and zero inventory reads. Its provider origin is fixed and its official version is pinned to 0.29.3. Opt in to inventory with `collect_inventory=true`, or explicitly supply reviewed resource inputs.
- All executable collectors and the local generator require `TAILSCALE_OUTPUT`, a **new absolute filename in an existing trusted directory outside source control**. They refuse existing files and symlinks, save mode 0600, suppress vendor errors and discard incomplete collections. Protect the containing directory and retain evidence under your privacy policy.
- `COLLECTED` means evidence was retrieved. It is not a compliant verdict. `VALIDATED-CANDIDATE` means the server accepted candidate validation, with `applied:false`; it is not a live enforcement result. `UNKNOWN` / exit 2 means no complete result was produced. The generator reports `GENERATED-CANDIDATE`.

API transport uses HTTPS with normal certificate verification, fixed `api.tailscale.com`, no redirect following, bounded connect/total time and a 20 MiB response cap. Curl configuration is disabled with `-q`; the bearer header is passed through stdin rather than process arguments. `TAILSCALE_BASE_URL` overrides are rejected. The SDK independently restricts its HTTP transport to the single device-list GET endpoint. No pack prints a resolved credential or the vendor’s error body.

## Inputs

All REST packs require an injected `TAILSCALE_ACCESS_TOKEN` and explicit `TAILSCALE_TAILNET` (reviewed tailnet ID/name, or deliberately `-` for the credential’s default). Prefer a scoped short-lived access token from a pre-existing approved trust credential. The scripts do not create one or exchange a client secret. Use a secret manager’s runtime environment injection; do not put credentials in command arguments, shell history, committed `.env` files or this repository.

| Control | Additional inputs / least privilege | Coverage limit |
|---------|-------------------------------------|----------------|
| 1.2 users | `users:read` | Current user/role/status inventory; reconcile IdP and console separately. |
| 1.3 settings | `feature_settings:read` | Defaults, not per-device behavior. |
| 1.4 devices and SDK | `devices:core:read` | A device snapshot; does not prove expiry/recovery behavior. |
| 2.1 policy snapshot | `policy_file:read`, `devices:core:read`, `devices:posture_attributes:read` | Raw HuJSON and ETag in one private JSON envelope, preserving comments. |
| 2.1 local generator | `TAILSCALE_POLICY_INPUT` | Strict JSON object with nonempty, distinct lowercase `admins` and `staff` email arrays; maximum 100 entries each. No product request. |
| 2.2 candidate validation | Same dependent read scopes as snapshot; `TAILSCALE_POLICY_FILE` | Complete candidate HuJSON, nonempty, at most 2 MiB. Only empty HTTP 200 counts as documented success. |
| 3.1 trust credentials | `TAILSCALE_KEY_IDS_FILE`; `oauth_keys:read` or `federated_keys:read` for reviewed types | Strict unique JSON array of 1–100 metadata IDs, not secret values. Known IDs only; reconcile the full console inventory. |
| 3.2 auth keys | `auth_keys:read` | Credential-visible auth-key IDs plus metadata. Empty results are not proof that no other principal has keys. |
| 3.3 routes | `devices:core:read`, `devices:routes:read`; profile 2+ | Snapshot every returned device then read routes. At most 1,000 devices; any failed read discards the collection. |
| 4.1 external nodes | `devices:core:read`; profile 2+ | Inbound external nodes only. Outbound shares/recipients/invites need console review. |
| 5.1 audit | `logs:configuration:read`; `TAILSCALE_LOG_START`, `TAILSCALE_LOG_END` | Past UTC `YYYY-MM-DDTHH:MM:SSZ` window, within 90 days, at most one day per export. |
| 5.2 stream status | `log_streaming:read`; profile 2+ | Records both status objects; fresh delivery must be verified at the destination. |

The current trust-credential scope reference documents `policy_file:read` dependencies explicitly. Policy writes require `policy_file` with `devices:core:read` and `devices:posture_attributes`; general feature-setting writes use `feature_settings`. A logging-only settings operation may use its documented narrower logging scope instead. An unscoped personal API key may have more authority than collection needs; using it does not turn a read-only script into least-privilege credential design.

Lists used here follow the documented nonpaginated contracts. Unexpected pagination metadata causes a failure, rather than silently collecting the first page. Audit exports have no vendor pagination or maximum page size; shorten the time window when the transport cap is exceeded. Overlap windows for delivery delay and inclusive boundaries. Do not deduplicate solely on `eventGroupID`, because several events can share that value.

## Examples

Prepare reviewed local identity input, outside the repository:

```json
{"admins":["network-admin@example.com"],"staff":["employee@example.com"]}
```

Generate a private candidate without contacting Tailscale:

```bash
export TAILSCALE_POLICY_INPUT='/absolute/trusted/approved-identities.json'
export TAILSCALE_OUTPUT='/absolute/trusted/candidate.json'
bash packs/tailscale/config/hth-tailscale-2.01-build-grants-policy.sh
```

The output is a **complete minimal candidate**, not a production replacement or merge engine. Adapt service tags/ports and all required unrelated settings, remove overlapping broad allows, and retain a known-good complete policy. Its empty legacy `acls` prevents an omitted-section fallback; its empty `ssh` permits no Tailscale SSH until you intentionally configure it. A network TCP 22 grant alone does not authorize Tailscale SSH.

For a credentialed read, inject the token through your already configured secret manager. For example, with an existing 1Password Environment:

```bash
export TAILSCALE_TAILNET='reviewed-tailnet-id'
export TAILSCALE_OUTPUT='/absolute/trusted/users.json'
op run --environment EXISTING_ENVIRONMENT_ID -- \
  bash packs/tailscale/api/hth-tailscale-1.02-inventory-users.sh
```

Do not run these examples with unresolved placeholder values. CLI packs use the machine’s already authenticated active tailnet and do not switch users. Check the intended local account/tailnet independently. Version collection can work without an active connection; a version result does not establish connectivity.

## Native policy fragments

Merge JSONC fragments into a **complete reviewed HuJSON policy**, preserving required fields and tests. Do not concatenate root objects or replace the policy with a fragment. The posture fragment must **replace the corresponding unconditioned grant**; adding it alongside that grant leaves the old allow intact. Named postures are alternatives, while assertions within one posture must all hold. The stable/auto-update example is not an MDM or disk-encryption attestation.

Tags replace user identity and combine permissions. Tagged authentication initially disables node-key expiry; reauthentication can disable it again. Tailnet Lock and device approval cannot coexist. User approval and SCIM cannot coexist according to the specific user-approval reference, despite a conflicting recommendation in the general provisioning overview. These choices need live tenant/IdP tests.

Funnel is public. The pack only reads local status; it never starts the enablement wizard or adds the `funnel` attribute. Posture is not applied to external users’ devices accessing shared nodes. Do not treat a posture definition or local status snapshot as a network-wide guarantee.

## Terraform

Use a dedicated reviewed workspace and protected state storage. Supply the documented provider environment variables (`TAILSCALE_TAILNET` and a supported credential mechanism) out of band. Never store plan/state or credential values in source control. The module has no auth-key, OAuth-client or federated-identity creation resource.

The single optional settings object accepts reviewed fields only: device approval, auto-updates, key duration, flow logging and external-tailnet joining role. Omitted optional fields retain provider state; import existing settings before management and inspect the complete plan. Enabling device approval also requires `tailnet_lock_is_disabled=true` after independent verification. This acknowledgment is a guard, not an API check.

`reviewed_expiring_device_ids` names only devices intended for expiry management. `reviewed_policy_file` names a complete policy; import the existing `tailscale_acl.reviewed["policy"]` with ID `acl` before changing it. The provider validates policy during planning; a plan can therefore contact the API even before apply. `overwrite_existing_content` and `reset_acl_on_destroy` are false, and managed resources carry `prevent_destroy`. This prevents accidental destruction; it does not stop an authorized update from disrupting access.

`reviewed_subnet_routes` is the **complete enabled set** per stable node ID. Advertisements occur on the host separately; permissions occur in grants. The pack rejects IPv4/IPv6 `/0` routes, so it deliberately cannot approve an exit node. Review those separately. `reviewed_log_streams` accepts only configuration/network S3 streams to existing approved role/bucket/region/external-ID combinations. Configure AWS trust/retention separately and verify receipt; no cloud infrastructure is provisioned here.

Use `TF_VAR_hth_profile_level=2` for route/log management. Do not set the shell profile variable and assume it configures Terraform. Empty/default resource inputs perform no writes.

## SDK and SIEM

The SDK is `tailscale.com/client/tailscale/v2` 2.12.0 and requires Go 1.24+. The older `tailscale-client-go` implementation is unmaintained. Run `go mod download` using normal checksum verification, then `go run .` from `sdk/` with the same injected token/tailnet/output variables. The device collector does not reserialize a tailnet policy through the SDK’s typed ACL structure, which could drop fields the SDK schema does not represent.

For Splunk, extract the **marked query region** of the SPL pack; the surrounding `#` lines are HTH metadata, not SPL. The example `index` and `sourcetype` are operator-selected ingestion names. If importing API exports, turn the `logs` array into individual JSON events first. Confirm field extraction using your actual integration before using the investigation query in an alert.

## Verification commands

```bash
python3 scripts/test-tailscale-packs.py
shellcheck -x -P SCRIPTDIR packs/tailscale/common.sh packs/tailscale/api/*.sh \
  packs/tailscale/cli/*.sh packs/tailscale/config/*.sh
bash scripts/sync-packs-to-data.sh
bash scripts/validate-guides.sh
bash scripts/validate-packs.sh tailscale
```

With pinned dependencies available (Terraform 1.7+ for the mocked-provider tests):

```bash
cd packs/tailscale/sdk
go test ./...
cd ../terraform
terraform init -backend=false
terraform validate
terraform test
```

SDK tests use fake HTTP transports and Terraform tests use a mocked provider. They prove local transport/validation/default behavior, not live feature availability or enforcement. `validate-packs.sh tailscale` still scans the full corpus; the vendor argument scopes its coverage report. Compare existing failures to the clean baseline. After a local commit, `validate-packs.sh --touched` gates the actual changed files.
