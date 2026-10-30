# Devin Enterprise Code Pack

Companion to the [Devin / Cognition hardening guide](https://howtoharden.com/guides/devin/). Sources and interface status were checked against Cognition's [API v3 OpenAPI schema](https://docs.devin.ai/v3-openapi.json) on 2026-10-29. Security-profile endpoints use **v3beta1 (beta)**; other API packs use v3.

## Read-only API packs

The scripts issue **GET only** to the fixed `https://api.devin.ai` origin. They do not change a tenant. Download the complete `api/` directory, including `common.sh`; an excerpt on the guide is not a standalone script.

| Control | Script | Evidence and limit |
|---------|--------|--------------------|
| 1.3 | `api/hth-devin-1.03-inventory-roles-and-service-users.sh` | Service-user identity, all roles with permission details, active and inactive service users. Human review against approved access is required. |
| 2.1 | `api/hth-devin-2.01-verify-ip-access-list.sh` | Compares canonical IPv4/IPv6 CIDR sets to an operator-approved JSON baseline; does not test live access denial. |
| 2.2 | `api/hth-devin-2.02-audit-security-profile-default.sh` | Resolves enterprise default to a mandatory read-only profile with explicit network/MCP policies. Does not prove allowlist suitability, running-session state, build defaults, or Outpost network enforcement. |
| 4.1 | `api/hth-devin-4.01-collect-audit-logs.sh` | Collects bounded-window audit records, cursor-paginates and deduplicates IDs. Empty results are not proof that logging works. |

### Prerequisites and credentials

- Bash, curl, jq and Python 3 (standard library only).
- `HTH_PROFILE_LEVEL=1` (the default) for inventory and audit collection, or 2 or higher for the L2 IP/profile checks. Packs above the selected level return 2 without making requests.
- Inject `DEVIN_API_KEY` from a secret manager; do not paste the value into shell history, code, a committed `.env`, or command-line arguments. Use a dedicated Enterprise service user for automation, not a human PAT.
- Role/membership inventory needs permissions to view account membership and role details. Audit collection needs **View Audit Logs** (`ViewAccountAuditLogs`). Security-profile collection requires the enterprise **Manage security profiles** permission, which is write-capable even for the GET endpoints. This pack uses it for reads only. Beta availability and role permission failures return unknown.
- **Important exception:** even `GET /v3/enterprise/ip-access-list` requires **Manage IP Whitelist** (`ManageIPWhitelist`), a write-capable vendor permission. `ManageEnterpriseSettings` does not substitute for it. The IP verification script nevertheless makes no writes. Issue that credential only to trusted operators and keep it separate from routine log collection.

Example after configuring a 1Password Environment that injects `DEVIN_API_KEY` (the Environment ID below is a placeholder):

```bash
HTH_PROFILE_LEVEL=2 \
DEVIN_INVENTORY_OUTPUT="$HOME/restricted-evidence/devin-inventory.json" \
op run --environment '<1password-environment-id>' -- \
  bash packs/devin/api/hth-devin-1.03-inventory-roles-and-service-users.sh
```

Create the trusted evidence directory yourself with access restricted to its intended readers. Output paths must not exist; scripts refuse existing files and symlinks and create new evidence files with mode `0600`. Raw inventory and audit records can contain names, user emails, IDs and arbitrary event data. Do not commit or print them; configure access, retention and SIEM ingestion separately. Console output contains counts and findings, not raw records or response bodies.

### IP baseline

Set `DEVIN_EXPECTED_IP_RANGES` to a JSON file containing your approved nonempty list of CIDRs. Do not use example/documentation addresses as your production baseline. The pack rejects an empty baseline and `/0` networks; a broad range smaller than `/0` still requires security review. It normalizes host bits before comparing sets, so equivalent CIDR notation matches, but splitting an approved network into multiple subnets still counts as configuration drift.

```bash
HTH_PROFILE_LEVEL=2 \
DEVIN_EXPECTED_IP_RANGES="$HOME/restricted-evidence/approved-devin-ip-ranges.json" \
op run --environment '<1password-environment-id>' -- \
  bash packs/devin/api/hth-devin-2.01-verify-ip-access-list.sh
```

### Enterprise profile evidence

```bash
HTH_PROFILE_LEVEL=2 \
op run --environment '<1password-environment-id>' -- \
  bash packs/devin/api/hth-devin-2.02-audit-security-profile-default.sh
```

An explicit empty network allowlist is deny-all except required Devin destinations; a null network policy means **no opinion**, not deny-all. A profile's presence does not mean it is bound. This pack checks the enterprise binding; review organization and build bindings separately. A running session retains its policy until its next boot/wake. No live session is started by this pack.

### Audit collection and guardrail review

Set `DEVIN_AUDIT_AFTER` and `DEVIN_AUDIT_BEFORE` to Unix timestamps in seconds. The positive window is capped at **31 days by this pack**, deliberately below the documented 100-day API limit. Use overlapping windows and deduplicate by `audit_log_id` when collecting successive batches. Set `DEVIN_AUDIT_ACTION=ai_guardrail_violation` to collect guardrail events for control 4.2, or leave unset for all actions.

```bash
HTH_PROFILE_LEVEL=2 \
DEVIN_AUDIT_AFTER=1793145600 \
DEVIN_AUDIT_BEFORE=1793232000 \
DEVIN_AUDIT_OUTPUT="$HOME/restricted-evidence/devin-audit.jsonl" \
op run --environment '<1password-environment-id>' -- \
  bash packs/devin/api/hth-devin-4.01-collect-audit-logs.sh
```

Replace those example timestamps with the intended evidence window. No response is written to the final file until pagination and record checks finish. `HTH_MAX_PAGES` defaults to 1000 (allowed 1–9999); reaching it, a missing/repeated cursor, malformed JSON, HTTP errors and beta access failures return unknown, never a successful partial export. A fixed time window is not an API snapshot: allow ingestion delay and reconcile later batches.

### Exit codes and validation

- **0:** the specific evidence collection or configuration comparison described above completed; **not** universal hardening compliance.
- **1:** a baseline finding in the IP/profile checks.
- **2:** missing prerequisite, skipped profile level, malformed/incomplete evidence, inaccessible endpoint, or other unknown state.

All scripts disable shell tracing before handling credentials, ignore `.curlrc`, reject `DEVIN_API_BASE` overrides, send the Authorization header via curl stdin rather than argv, and reject redirects. Use a trusted host and network; a configured HTTPS proxy is still part of that trust boundary.

```bash
python3 scripts/test-devin-api-packs.py
for file in packs/devin/api/*.sh; do bash -n "$file"; done
```

The tests stub curl and check real script behavior against synthetic documented response shapes: pagination, cursor failures, HTTP errors, strict input/schema checks, permission gaps, token-safe transport, private output, no-overwrite behavior, and findings versus unknown exit codes. No live tenant or credentials were used; this is offline verification, not `ai-validated` product behavior.

## Terraform: separate verification from enforcement

The source directory is a collection of **independent examples**, not a single module to run wholesale. Copy `terraform/providers.tf` and **one** selected `hth-*.tf` file into a new empty directory. The provider is pinned to official `cognitionai/devin` **0.5.0**; review provider updates and commit your own generated dependency lockfile. Inject `DEVIN_TOKEN` from a secret manager. The API collectors use `DEVIN_API_KEY`; the provider uses a different environment-variable name.

| Control | Terraform surface | Effect and limitation |
|---------|-------------------|-----------------------|
| 1.2 | `devin_users`, `devin_idp_groups` data sources | Reads direct-member/registered-group counts; does not prove SCIM/JIT settings or enumerate every group-derived member |
| 1.3 | `devin_roles`, `devin_service_users` data sources | Reads inventory and aggregate counts; permission definitions still need console/API review |
| 2.1 | `devin_ip_access_list` resource | **Mutating** singleton replacement. Requires complete real CIDRs and an explicitly verified independent access path; guard defaults false |
| 3.1 | `devin_git_permission` resource | **Mutating**, additive exact-repo read-only grant; other existing broad grants are not revoked |

Use `terraform init` and `terraform validate`, then inspect `terraform plan`. The data-only examples require no apply. Never apply the IP resource unless an independent administrator has proved a recovery route within the proposed allowlist. Back up the existing list first. A missing operator/runner egress can lock you out; removing/destroying this resource can clear restrictions. `prevent_destroy` only protects while its resource block remains present. Do not treat a boolean acknowledgment as proof that recovery works.

Terraform format checks passed. Provider initialization was attempted with backends disabled on 2026-10-30, but the official registry connection timed out; provider-backed validation, plan, and apply were not performed. Schemas were checked against the provider's fetched `v0.5.0` documentation; this is a static check, not runtime validation. State and saved plans can retain tenant metadata even when outputs contain only counts. Store them securely and do not commit them or any secrets.
