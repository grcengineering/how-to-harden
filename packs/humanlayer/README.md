# HumanLayer Code Pack

Four source-backed packs support four of the eight controls in the [HumanLayer guide](https://howtoharden.com/guides/humanlayer/). HumanLayer has its own hosted/desktop/daemon plane; Factory Droid policy and keys do not configure these files or commands.

| Type/control | Operation | Required input |
|--------------|-----------|----------------|
| CLI 1.1 | Production `humanlayer logout`; dry run by default | Existing approved `@humanlayer/cli`; `HTH_APPLY=1` to execute |
| CLI 3.2 | `linear list-workflow-states TEAM --output-format json` | Existing approved **HumanLayer** `@humanlayer/linear-cli`, authenticated state, explicit `HUMANLAYER_LINEAR_TEAM`, new absolute `HUMANLAYER_LINEAR_STATES_OUTPUT` |
| Config 2.1 | Emit strict workspace JSON with reviewed source and setup blocking | `HUMANLAYER_SOURCE_REF`, `jq`, profile 2+ |
| Config 3.1 | Emit Codex gateway shell environment | `HUMANLAYER_CODEX_GATEWAY_URL`, `jq`, profile 2+ |

Run with Bash from a trusted checkout; keep `common.sh` beside the directories. `HTH_PROFILE_LEVEL` must be 1–4 (default 1); scripts refuse a level below the control's minimum. Exit 0 means the stated collection/generation/action request completed, not that the organization is hardened. Exit 2 means unknown/not run. No script installs a product, logs in, creates a token, starts a daemon, invokes a coding model or executes an unattended automation session.

The logout writer is intentionally guarded. Review the production identity before `HTH_APPLY=1`; it does not terminate separately supervised daemons, delete task data, revoke underlying provider credentials or establish beta-session cleanup. The companion `linear` command must come from HumanLayer's package rather than another vendor's executable with the same name. Its JSON envelope is not published as a stable schema; collection validates structured JSON without inventing record fields. The evidence file is published as a complete mode-0600 file in an existing trusted directory and refuses existing paths and symlinks. Keep it outside version control.

The workspace candidate adds **no** copy patterns or shell commands. HumanLayer's default `copyGlobs` include `.env` and local coding-agent settings and append to shared/local patterns. `copyGlobs: []` cannot remove those defaults. Clean the source checkout and review all effective configuration, including uncommitted local overrides, before using it. A reviewed `sourceRef` string is not a repository-trust check.

The gateway generator emits a literal `${HUMANLAYER_GATEWAY_TOKEN:?...}` reference and does not read its value. It deliberately supports HTTPS only and rejects credentials, query, fragment and shell syntax. Deploy through the existing daemon-host environment workflow after review and inject the token from a secret manager. Restart the daemon and verify real gateway egress separately. This sets HumanLayer's documented Codex endpoint variables; it is not a general model allowlist, Claude configuration or organization policy.

No supported hosted administration REST/GraphQL, official policy SDK, provider resource/data-source catalog, SIEM schema or MDM policy was verified. These remain research gaps, not evidence of absence. GitHub/Jira/Slack connections, task access, local-daemon preference and hosted lifecycle retain their documented UI workflows. No code guesses their endpoints or secret paths.

Validation is documentation plus offline fixtures only. Run `bun test scripts/test-factory-refresh.test.ts`; see [source coverage](../../docs/research/factory-source-coverage.md) and [refresh validation](../../docs/research/factory-refresh-validation.md). No tenant or installed HumanLayer client was exercised. The hosted service's transition and open-source announcement do not establish a tested export, migration, retention or self-hosting contract.
