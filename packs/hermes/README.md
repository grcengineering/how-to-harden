# Hermes Agent Code Pack

Source-checked on 2026-11-15. The [guide](https://howtoharden.com/guides/hermes/) and [source ledger](../../docs/research/agent-source-coverage-2026-11.md) explain applicability and limits. Reviewed release: **0.23.1**. Other versions, including newer releases, fail closed until reconciled with upstream. OpenCode's policy feature floors are documented separately; they do not prove this entire candidate works on an older release.

Requires Bash, Python 3.9+ on a POSIX host (macOS/Linux, or an approved WSL environment) and the full HTH checkout. Hermes/OhMyPi YAML audits additionally require PyYAML; strict JSON candidates work without it. No installer, native agent, Docker daemon, provider or tenant is required for the default operations. These packs never install configuration, chmod a device, start services or execute a launch plan. They are local candidate tooling, not an enterprise policy engine or a sandbox.

## Generate, inspect and compare

```bash
bash packs/hermes/config/hth-hermes-1.02-baseline.sh --version 0.23.1
```

This writes only to stdout. To save a new private candidate, use an operator-chosen directory with `umask 077` and the shell's `noclobber` option before redirecting. Review the whole candidate before deploying it through your existing change process as `config.yaml`. JSON is valid YAML for Hermes/OhMyPi. The 4.1 and 4.2 outputs are **fragments**, not standalone baselines; do not concatenate JSON objects or replace ordered policy arrays blindly.

```bash
bash packs/hermes/config/hth-hermes-5.01-audit-candidate.sh --version 0.23.1 --config /absolute/private/config.yaml
```

The audit compares an explicit file with the reviewed restrictive baseline, preserving array order and value types. Unexpected fields, duplicate keys, missing fields, malformed data, aliases, symlinks, FIFOs and oversized files fail. OpenCode/Pi audits accept **strict JSON**, not general JSONC. It prints only known finding identifiers. It does not merge layers, resolve variables, follow resources, prove filesystem ownership, interrogate an agent or certify the complete native schema. Exit 0 means the file matches; exit 1 means a baseline finding; exit 2 means it could not be checked. No result is effective-policy or live-validation evidence.

OpenCode defaults to **all providers denied**, intentionally unusable for inference. Only OpenCode's emitter/auditor accept `--approved-provider anthropic` (replace with your exact reviewed provider ID) to allow the bare provider integration. Use the same option for generation and audit. Connected personal accounts with `#account` suffixes remain denied. Console workspace deployments need a separately reviewed account-scoped policy; this pack does not invent your organization ID. Other products' default model selectors do not enforce a provider allowlist.

## Inspect the launch boundary

```bash
bash packs/hermes/config/hth-hermes-2.01-launch-plan.sh --version 0.23.1 --workspace /absolute/quarantine --state-dir /absolute/private/state --binary /absolute/reviewed/binary
```

Directories must already exist. The result is **JSON describing a plan**, never a shell command to eval. There is no launch `--execute` option. Start the entire process inside your approved isolation boundary, with a dedicated state home, controlled discovery roots, minimal credentials and externally enforced network policy. The plan does not configure that boundary or change the current environment. In particular, a different state directory does not change the real OS user, prevent HOME discovery or remove inherited credentials by itself. The Pi plan uses fixed resource/trust flags and an absolute session directory; arbitrary extra agent flags are rejected. The OhMyPi plan audits its overlay and supplies a fixed approval mode; runtime/SDK overrides and project resources still require governance.

```bash
bash packs/hermes/config/hth-hermes-2.02-network-environment.sh --version 0.23.1
bash packs/hermes/config/hth-hermes-3.01-credential-environment.sh --version 0.23.1
bash packs/hermes/config/hth-hermes-3.02-resource-inventory.sh --version 0.23.1 --workspace /absolute/quarantine
```

These are bounded checks of the **calling process** and named top-level workspace entries. They never print environment values or file contents. They do not inspect ancestors, hidden user credentials, service-manager environments, remote MCP servers or descendant package code. A clean report is not proof that egress or discovery is restricted.

## Native reads require explicit opt-in

The 1.1 version script previews by default. Set `HTH_BINARY` to an absolute reviewed binary; `HTH_EXECUTE=1` invokes only its `--version` command. Raw output is suppressed. The 5.2 diagnostic script takes `--binary /absolute/reviewed/binary --version 0.23.1` and previews fixed native argv. `--execute` opts into those **read commands**, with a 30-second timeout per command. Pi uses `auth check --json --no-refresh` without credential output. Native commands run with the calling process's environment and may load product state; run them only in the approved isolated test context. They are not performed automatically by any config audit or test.

A completed native command is reported only as a completion/exit code. It is never reported as an effective-policy pass. Review effective settings, startup warnings and a harmless denied operation separately. Never publish raw diagnostics, pairing links, provider headers, auth files, session transcripts or proxy URLs.

## Validation and recovery

`python3 scripts/test-agent-hardening-packs.py` uses temporary directories, hostile input fixtures and fake native executables. Source/syntax/schema/fixture validation earns no `ai-validated` maturity. No live app was hardened. Preserve the approved previous configuration, inspect a diff and redeploy through your existing change process if rollback is needed; restarting or revoking sessions is product-specific and not performed by this pack.
