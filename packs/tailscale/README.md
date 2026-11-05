# Tailscale Code Pack

39 source packs support 22 of the 23 controls in the [Tailscale guide](https://howtoharden.com/guides/tailscale/). The remaining control, upstream IdP MFA, retains an evidenced manual verdict. Packs use the documented REST API, first-party CLI, native tailnet and device policy, official Terraform resources/data sources, maintained Go SDK, and configuration-log JSON in Splunk. These counts measure the authored corpus; the source inventory separately records discovery coverage and remaining research limits.

**Validation scope:** documentation and offline tests only; no live tailnet, identity provider, endpoint policy, TPM, SIEM or credentialed API was exercised. The guide remains `ai-drafted`. See the [source-first inventory](../../docs/research/tailscale-source-coverage.md) and [refresh verification](../../docs/research/tailscale-refresh-validation.md). The earlier research files remain labeled historical snapshots.

## Contents

| Surface | Packs | Purpose |
|---------|-------|---------|
| `api/` | 13 shell packs | Users, settings, device keys, selected state-encryption attribute, raw policy/ETag, candidate validation, known trust credentials, visible auth keys, route approvals, inbound external devices, DNS, audit logs and stream status. |
| `config/` | 3 generators, 6 JSONC fragments | Complete minimal grants candidate; node-state and managed-client settings; tag owners, SSH, posture, CI access, client web-interface removal and approved Taildrive access. |
| `cli/` | 8 shell packs | Local Tailnet Lock, Funnel/Serve, installed version, incoming/web preferences, selected system policies, Taildrive shares and DNS status. |
| `terraform/` | 7 control packs | Users/devices/policy data sources; optional settings, device expiry, complete policy, subnet routes, complete DNS and existing S3 log destinations. |
| `sdk/` | 1 Go pack | Device inventory through the maintained official SDK, pinned to 2.12.0. |
| `siem/` | 1 SPL query | Investigation of configuration changes using documented JSON fields. |

`common.sh`, `api/common.sh`, `config/system-policy.sh`, `terraform/provider.tf`, dependency files and tests are support files, not extra control packs. Download the whole vendor directory. The generated guide excerpts call these helpers and are not standalone scripts.

## Safe defaults and outputs

- Shell/SDK operations are read-only. The only REST POST targets `/acl/validate`; no policy-apply, device-approval, key-creation, node-signing or publication operation is implemented.
- Scripts validate `HTH_PROFILE_LEVEL` (1–4, default 1); a lower level than the pack requires fails before network/CLI work. Terraform uses the separate `TF_VAR_hth_profile_level` input. Native fragments and SPL have fixed review labels rather than runtime environment gates.
- Terraform defaults to zero managed resources and zero inventory reads. Its provider origin is fixed and its official version is pinned to 0.29.3. Opt in to inventory with `collect_inventory=true`, or explicitly supply reviewed resource inputs.
- All executable collectors and local generators require `TAILSCALE_OUTPUT`, a **new absolute filename in an existing trusted directory outside source control**. They refuse existing files and symlinks, save mode 0600, suppress vendor errors and discard incomplete collections. Protect the containing directory and retain evidence under your privacy policy.
- `COLLECTED` means evidence was retrieved. It is not a compliant verdict. `VALIDATED-CANDIDATE` means the server accepted candidate validation, with `applied:false`; it is not a live enforcement result. `UNKNOWN` / exit 2 means no complete result was produced. The generator reports `GENERATED-CANDIDATE`.

API transport uses HTTPS with normal certificate verification, fixed `api.tailscale.com`, no redirect following, bounded connect/total time and a 20 MiB response cap. Curl configuration is disabled with `-q`; the bearer header is passed through stdin rather than process arguments. `TAILSCALE_BASE_URL` overrides are rejected. The SDK independently restricts its HTTP transport to the single device-list GET endpoint. No pack prints a resolved credential or the vendor’s error body.

## Inputs

All REST packs require an injected `TAILSCALE_ACCESS_TOKEN` and explicit `TAILSCALE_TAILNET` (reviewed tailnet ID/name, or deliberately `-` for the credential’s default). Prefer a scoped short-lived access token from a pre-existing approved trust credential. The scripts do not create one or exchange a client secret. Use a secret manager’s runtime environment injection; do not put credentials in command arguments, shell history, committed `.env` files or this repository.

| Control | Additional inputs / least privilege | Coverage limit |
|---------|-------------------------------------|----------------|
| 1.2 users | `users:read` | Current user/role/status inventory; reconcile IdP and console separately. |
| 1.3 settings | `feature_settings:read` | Defaults, not per-device behavior. |
| 1.4 devices and SDK | `devices:core:read` | A device snapshot; does not prove expiry/recovery behavior. |
| 1.6 state attribute | `devices:posture_attributes:read`; `TAILSCALE_DEVICE_ID` | One explicit device ID (1–128 letters, digits, `_` or `-`); only `node:tsStateEncrypted` is exported. Missing/unrecognized values fail as `UNKNOWN`. A Boolean or string is preserved, not interpreted as a compliance verdict. |
| 1.6, 4.5 native settings | `TAILSCALE_PLATFORM`, `TAILSCALE_CLIENT_VERSION`; profile 2+ | Offline generators; supported formats and version floors below. No token, installation or restart. |
| 2.1 policy snapshot | `policy_file:read`, `devices:core:read`, `devices:posture_attributes:read` | Raw HuJSON and ETag in one private JSON envelope, preserving comments. |
| 2.1 local generator | `TAILSCALE_POLICY_INPUT` | Strict JSON object with nonempty, distinct lowercase `admins` and `staff` email arrays; maximum 100 entries each. No product request. |
| 2.2 candidate validation | Same dependent read scopes as snapshot; `TAILSCALE_POLICY_FILE` | Complete candidate HuJSON, nonempty, at most 2 MiB. Only empty HTTP 200 counts as documented success. |
| 3.1 trust credentials | `TAILSCALE_KEY_IDS_FILE`; `oauth_keys:read` or `federated_keys:read` for reviewed types | Strict unique JSON array of 1–100 metadata IDs, not secret values. Known IDs only; reconcile the full console inventory. |
| 3.2 auth keys | `auth_keys:read` | Credential-visible auth-key IDs plus metadata. Empty results are not proof that no other principal has keys. |
| 3.3 routes | `devices:core:read`, `devices:routes:read`; profile 2+ | Snapshot every returned device then read routes. At most 1,000 devices; any failed read discards the collection. |
| 4.1 external nodes | `devices:core:read`; profile 2+ | Inbound external nodes only. Outbound shares/recipients/invites need console review. |
| 3.3, 4.4–4.7 local CLI evidence | Existing local client/account; profile as labeled in each pack | Fixed read commands only. Some commands require newer clients; unavailable/malformed results fail as `UNKNOWN`. System-policy exports omit credential keys and raw errors. Local status does not prove central approval or enforcement. |
| 4.7 DNS | `dns:read`; profile 2+ | Four legacy GETs: nameservers, preferences, search paths and split DNS. Explicitly does not cover Override DNS, exit-node flags or certificate issuance settings. |
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

The web-interface fragment targets member-owned devices; review tagged hosts separately. Turning off the remote web-client preference does not disable its local UI. Taildrop and Taildrive are different sharing models: Taildrop's own-user transfers are not blocked by restrictive network ACLs. The Taildrive fragment is an **alpha, approved-use example**, not a recommendation to enable sharing. Remove unneeded existing sharing capabilities; if Taildrive is explicitly approved, adapt the named read-only share and verify the actual local share list. No pack creates a share or transfers a file.

## Native device settings and state recovery

Both native generators require `TAILSCALE_PLATFORM=windows`, `macos-standalone` or `linux`, plus the explicit stable installed `TAILSCALE_CLIENT_VERSION` in `major.minor.patch` form. They emit settings only:

| Target | Artifact | Compatibility floor |
|--------|----------|---------------------|
| Windows | `.reg` settings for `HKLM\SOFTWARE\Policies\Tailscale`, Boolean values as DWORDs | 1.86.0 |
| Standalone macOS | Plist dictionary for `io.tailscale.ipn.macsys`; not a complete MDM configuration profile | 1.86.0 |
| Linux | Flat JSON settings for the managed system-policy loader, normally `/etc/tailscale/syspolicy.json` | 1.102.0 |

These are feature-compatibility floors, not recommended patch versions. Stage current vendor security updates. Merge the artifact into existing managed settings through the endpoint owner; never replace a complete profile or daemon configuration with the fragment. No registry, keystore, daemon, MDM or connection setting is changed by a generator.

The 1.6 generator emits `EncryptState: true`. Linux 1.86–1.100 can instead use the documented `tailscaled --encrypt-state` service flag, preserving existing flags; the JSON loader is newer. Linux/Windows require a functioning TPM 2.0. Standalone macOS uses Keychain; App Store Apple variants and Android use native encrypted storage and are not targets of these generated fragments. Versions 1.90.2–1.92.4 enabled protection by default on supported platforms; since 1.92.5 Linux and Windows require opt-in. Inspect actual state after a separately approved rollout and restart.

TPM loss/reset or hardware migration can prevent unsealing and startup. Establish independent access and a vendor-supported state reset/reenrollment recovery procedure on disposable hardware first. Do not reset a production TPM or copy node state as a test. Disabling protection migrates state to plaintext. Local-file protection does not configure remote SSM/KMS or in-memory state backends. The pack neither checks hardware nor deletes/reinitializes state.

The 4.5 generator additionally requires `TAILSCALE_ALLOWED_TAILNET_ID`, an approved tailnet (`T…`) or organization (`o…`) unique ID. It emits `Tailnet: required:<ID>` and `PostureChecking: always`. Desktop variants also emit AlwaysOn with an audited five-minute disconnect exception. Linux omits unsupported AlwaysOn keys. Review Apple VPN prerequisites and recovery before deploying: these Tailscale policies cannot coexist with an independently managed VPN profile. Custom On Demand rules can prevent reconnection. No `AuthKey` or alternate `LoginURL` is generated. The read-only policy collector reports selected effective settings/error flags; that is configuration evidence, not a connection or encryption test.

## Terraform

Use a dedicated reviewed workspace and protected state storage. Supply the documented provider environment variables (`TAILSCALE_TAILNET` and a supported credential mechanism) out of band. Never store plan/state or credential values in source control. The module has no auth-key, OAuth-client or federated-identity creation resource.

The single optional settings object accepts reviewed fields only: device approval, auto-updates, key duration, flow logging and external-tailnet joining role. Omitted optional fields retain provider state; import existing settings before management and inspect the complete plan. Enabling device approval also requires `tailnet_lock_is_disabled=true` after independent verification. This acknowledgment is a guard, not an API check.

`reviewed_expiring_device_ids` names only devices intended for expiry management. `reviewed_policy_file` names a complete policy; import the existing `tailscale_acl.reviewed["policy"]` with ID `acl` before changing it. The provider validates policy during planning; a plan can therefore contact the API even before apply. `overwrite_existing_content` and `reset_acl_on_destroy` are false, and managed resources carry `prevent_destroy`. This prevents accidental destruction; it does not stop an authorized update from disrupting access.

`reviewed_subnet_routes` is the **complete enabled set** per stable node ID. Advertisements occur on the host separately; permissions occur in grants. The pack rejects IPv4/IPv6 `/0` routes, so it deliberately cannot approve an exit node. Review those separately. `reviewed_log_streams` accepts only configuration/network S3 streams to existing approved role/bucket/region/external-ID combinations. Configure AWS trust/retention separately and verify receipt; no cloud infrastructure is provisioned here.

Use `TF_VAR_hth_profile_level=2` for route/log management. Do not set the shell profile variable and assume it configures Terraform. Empty/default resource inputs perform no writes.

`reviewed_dns_configuration` is one **complete DNS owner**: explicit global nameservers, split-DNS mappings, search paths, Override DNS and MagicDNS choices. Import existing configuration into `tailscale_dns_configuration.reviewed["dns"]` before management. Do not combine it with the provider's individual DNS resources. Exit-node resolver flags require verified 1.88.1+ client support and `dns_clients_support_exit_node_resolvers=true`. This acknowledgment is not client discovery. A DNS replacement can disrupt administration; preserve a known-good complete configuration and independently test actual resolution. Certificate issuance and its public Certificate Transparency disclosure remain separate review steps.

## SDK and SIEM

The SDK is `tailscale.com/client/tailscale/v2` 2.12.0 and requires Go 1.24+. The older `tailscale-client-go` implementation is unmaintained. Run `go mod download all` using normal checksum verification, then `go run .` from `sdk/` with the same injected token/tailnet/output variables. The explicit `all` initializes archive checksums as well as module metadata on a clean cache. The device collector does not reserialize a tailnet policy through the SDK’s typed ACL structure, which could drop fields the SDK schema does not represent.

For Splunk, extract the **marked query region** of the SPL pack; the surrounding `#` lines are HTH metadata, not SPL. The example `index` and `sourcetype` are operator-selected ingestion names. If importing API exports, turn the `logs` array into individual JSON events first. Confirm field extraction using your actual integration before using the investigation query in an alert.

## Verification commands

```bash
make test-tailscale-packs  # Existing Python suite plus Bun refresh tests (Bun required).
shellcheck -x -P SCRIPTDIR packs/tailscale/common.sh packs/tailscale/api/*.sh \
  packs/tailscale/cli/*.sh packs/tailscale/config/*.sh
bash scripts/sync-packs-to-data.sh
bash scripts/validate-guides.sh
bash scripts/validate-packs.sh tailscale
```

With pinned dependencies available (Terraform 1.7+ for the mocked-provider tests; CI pins 1.17.1):

```bash
cd packs/tailscale/sdk
go mod download all
go test ./...
cd ../terraform
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
terraform test
```

SDK tests use fake HTTP transports and Terraform tests use a mocked provider. They prove local transport/validation/default behavior, not live feature availability or enforcement. `validate-packs.sh tailscale` still scans the full corpus; the vendor argument scopes its coverage report. Compare existing failures to the clean baseline. After a local commit, `validate-packs.sh --touched` gates the actual changed files.
