# Devin Desktop Code Pack

Source-backed templates and read-only tools for the [Devin Desktop guide](https://howtoharden.com/guides/devin-desktop/). Verified against documentation on **2026-10-29**; **no live client or tenant validation**. Covers current Devin Desktop (formerly Windsurf), not air-gapped/federal editions.

## Safety and scope

- Tools under `config/` only print configuration or inspect an explicitly chosen file. They do not install policy, launch the agent, use credentials, or call a network service.
- API 5.2 is GET-only. API 4.4 defaults to an **offline plan**; only explicit `--apply` sends a PUT replacing the model allowlist. No live API calls were made during authoring/testing. The v2alpha endpoint may change. Inject a `cog_` service-user key through an approved secret manager; never put it in an argument, committed file, or terminal transcript.
- JSONC files are native configuration templates with comment headers. Remove comment lines before strict-JSON deployment, merge into existing configuration, and deploy through your approved management tool. Their `mutating` contracts describe the deployment effect; do not assume a read-only audit installs them.
- Keep a copy of the prior baseline. Pilot on a test device, restart the client, and verify managed settings plus actual restrictions. Roll back only the relevant keys/hook entries.
- **Linux `/etc/vscode/policy.json` is shared with VS Code.** Do not clobber its existing policy. Windows and macOS use the policy templates shipped with the installed Devin Desktop release; no guessed macOS domain is encoded here.
- Team `Extension policy` overrides device `AllowedExtensions`; device `ExtensionGalleryServiceUrl` overrides the team marketplace URL. A disk match does not prove effective client behavior.
- Cascade command lists only control approval. The L3 constant-denial pre-hook rejects Cascade shell calls with exit 2; it does not cover human terminals, MCP, Devin Local, third-party agents, or Restricted Mode where hooks do not run.
- `.devinignore` is context exclusion, not a shell sandbox or DLP boundary.

## Pack inventory

| Control | File | Behavior |
|---------|------|----------|
| 1.3 | `config/hth-devin-desktop-1.03-block-cascade-shell.jsonc` | Hooks configuration rejecting every Cascade shell action; merge into managed hooks.json |
| 2.1 | `config/hth-devin-desktop-2.01-extension-allowlist.sh` | Emits a policy fragment from approved exact extension IDs |
| 2.2 | `config/hth-devin-desktop-2.02-extension-marketplace.sh` | Emits an HTTPS gallery policy fragment; no URL request |
| 2.3 | `config/hth-devin-desktop-2.03-client-updates.jsonc` | Enables the normal automatic client-update policy |
| 4.1 | `config/hth-devin-desktop-4.01-devinignore.sh` | Prints candidate ignore rules; merge, never overwrite |
| 4.2 | `config/hth-devin-desktop-4.02-minimize-telemetry.jsonc` | Disables optional telemetry/feedback, not model requests |
| 5.1 | `config/hth-devin-desktop-5.01-verify-managed-policy.sh` | Read-only comparison against your approved merged baseline |
| 4.4 | `api/hth-devin-desktop-4.04-model-allowlist.sh` | Offline plan by default; full replacement only with --apply, same credential, and reviewed ETag |
| 5.2 | `api/hth-devin-desktop-5.02-audit-model-allowlist.sh` | GET-only model access snapshot, without prices or raw response body |

## Examples

From the repository root, print an extension policy fragment without modifying the machine:

```bash
bash packs/devin-desktop/config/hth-devin-desktop-2.01-extension-allowlist.sh \
  ms-python.python github.vscode-pull-request-github
```

Print a marketplace fragment using your real, approved gallery service URL (the example domain is not a service):

```bash
bash packs/devin-desktop/config/hth-devin-desktop-2.02-extension-marketplace.sh \
  https://gallery.example.test/api/v1
```

Compare only keys in an approved baseline with the real Linux policy. The baseline must be a nonempty strict-JSON object using supported keys; it should contain no secrets:

```bash
bash packs/devin-desktop/config/hth-devin-desktop-5.01-verify-managed-policy.sh \
  --expected reviewed-baseline.json
```

The verifier accepts `AllowedExtensions`, `ExtensionGalleryServiceUrl`, `UpdateMode`, `TelemetryLevel`, and `EnableFeedback`. It requires the extension baseline to explicitly deny `*`, preserves all files, checks exact types, rejects duplicate keys and symlink files, and prints only key verdicts. Unknown additional policy keys are not evaluated. Exit **0** means selected disk keys and file-ownership checks match, **1** means drift/insecure file permissions, **2** means input or observation is invalid/unknown. `--policy PATH` supports fixture checks; that option does not make a fixture authoritative. Parent-directory protections and effective server overrides still require administrator review.

## Model API workflow

Use the documented [read](https://docs.devin.ai/desktop/accounts/api-reference/list-models) and [write](https://docs.devin.ai/desktop/accounts/api-reference/update-models) methods. The read role needs **Use Devin Desktop**; writes also need **account.windsurf.admin**. Do not use a legacy Windsurf service key. `common.sh` supplies the shared transport; download it with the individual API pack.

After approved credential injection, capture a protected snapshot:

```bash
umask 077
bash packs/devin-desktop/api/hth-devin-desktop-5.02-audit-model-allowlist.sh > snapshot.json
```

Create `approved.json` with exactly `allowed_model_uids` and `allowed_model_tags`, each an array of real reviewed values from the account. Both arrays replace existing values; this pack deliberately refuses to send two empty arrays. Prefer specific UIDs when provider tags would authorize future models too broadly. Then inspect the offline plan:

```bash
bash packs/devin-desktop/api/hth-devin-desktop-4.04-model-allowlist.sh approved.json snapshot.json
```

An administrator may append **`--apply`** only after approving the full selection. The snapshot is bound to the same credential by a SHA-256 fingerprint, not a stored key. Its ETag is sent in `If-Match`; HTTP 412 requires a new read and human re-approval, not automatic retry. After success, re-read and verify the normal-member picker. To roll back, approve the prior lists using a fresh snapshot/ETag. Network/permission/response-shape failures are **unknown**, not a security pass.

## Offline verification

```bash
python3 scripts/test-devin-desktop-packs.py
```

The suite uses temporary fixtures, parses configuration, exercises emitters and a constant local shell-denial command, and checks invalid inputs and no-write behavior. API tests replace curl with an offline shim: GET/PUT request shape, ETag checks, credential non-disclosure, no-network default plan, schema errors and HTTP failures are tested without a tenant. A mocked root-owner fixture tests the success branch. It does **not** launch Devin, deploy a policy, prove Windows PowerShell behavior, or qualify this guide for `ai-validated`.

The guide uses native `config/` plus documented model-policy `api/` packs. Cloud APIs/Terraform, CLI permissions, legacy SCIM, and analytics are distinct surfaces; no undocumented dashboard endpoint or fabricated SDK is used.
