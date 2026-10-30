# Devin CLI Code Pack

Companion to the [Devin CLI hardening guide](https://howtoharden.com/guides/devin-cli/). These examples target the documented current cloud-connected CLI, not the separate federal air-gapped deployment. Sources were fetched on 2026-10-29; no Devin installation, login or real tenant was exercised.

## Safe execution

- Review the full file and its `HTH Pack Contract` before running. Bash scripts require Bash and the dependencies in their headers. They do not install the CLI.
- `cli/hth-devin-cli-1.01-pin-device-identity.sh` runs only `devin version` and `devin auth status`. Keep account-identifying output local.
- The 2.1 sandbox launcher performs dependency preflight by default. The 2.2 workspace-trust launcher prints its planned command. Only explicit `--launch` starts an interactive session; this can consume service usage and execute reviewed workspace hooks. Neither launcher is a sandbox proof.
- The 3.1 MCP pack defaults to inventory. `disable NAME local|project|user` prints the intended change; `--apply` is required to disable that exact server/scope. A change in one scope does not prove other scopes are clear.
- The 3.2 and 5.1 packs list rules/skills/plugins; they do not install or remove anything. Do not open an unreviewed workspace to inspect hooks because startup hooks can execute.
- The 1.1 config script prints candidate `system.json` on `emit`, validates a named file on `validate FILE`, or checks strict JSON plus Unix ownership/ancestor modes on `audit FILE`. It never deploys a managed file. `DEVIN_ENTERPRISE_HOST` and `DEVIN_ACCOUNT_ID` must be confirmed account values; the optional proxy URL must contain no credentials.

## Config templates

Files in `config/*.jsonc` carry explanatory comment headers. Remove comment lines before strict-JSON deployment and **merge only the relevant object**, not an entire sample over your existing settings. The 1.2 object is for the enterprise Terminal Permissions editor; local configuration uses its documented wrapper. The other files identify their intended scope in comments.

Back up your baseline and use endpoint management to protect system policy from modification. Malformed device policy can fail open; a schema match does not prove an already-authenticated user has been revalidated. The guide covers enterprise policy precedence, sandbox preview limitations, file-path constraints, and fail-open plugin/hook behavior.

## Offline verification

```bash
python3 scripts/test-devin-cli-packs.py
for file in packs/devin-cli/cli/*.sh packs/devin-cli/config/*.sh; do
  bash -n "$file"
done
```

Tests use fixture files and a mocked `devin` executable, including explicit-launch/apply gates and invalid input handling. They do not establish live authorization, endpoint-management enforcement, sandbox isolation, Windows ACL behavior or cloud policy adoption. All guide maturity remains `ai-drafted`.
