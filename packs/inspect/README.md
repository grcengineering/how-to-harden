# Inspect Code Packs

Companion to the [Inspect hardening guide](https://howtoharden.com/guides/inspect/). Inspect is Ramp's coding agent, not the Ramp financial API. Sources: [Inspect API](https://docs.inspect.com/api), [OpenAPI schema](https://docs.inspect.com/api/openapi.json), and the exact documentation cited in each pack. All were documentation-checked on November 17, 2026. No Inspect tenant was exercised.

## Contents

| Control | Pack | Effect |
|---------|------|--------|
| 2.1 | `api/hth-inspect-2.01-inventory-repositories.sh` | Read repositories visible to one API key; refuses truncated results. |
| 2.2 | `api/hth-inspect-2.02-audit-agent.sh` | Read one exact custom agent, excluding prompt content from the report. |
| 2.6 | `api/hth-inspect-2.06-restrict-agent-repositories.sh` | Preview or explicitly apply a non-broadening, nonempty repository allowlist. |
| 3.3 | `config/hth-inspect-3.03-exact-workload-trust.sh` | Emit an exact-repository, exact-lifecycle AWS OIDC trust candidate; never deploy it. |
| 4.1 | `config/hth-inspect-4.01-human-review-approval-baseline.yml` | Vendor-native Approval agent policy that always requires human review. |
| 4.2 | `api/hth-inspect-4.02-request-verification.sh` | Preview or explicitly request verification of one reviewed session/PR target; starts work and may incur cost. |
| 4.2 | `config/hth-inspect-4.02-review-verification-config.sh` | Emit one Review or Verification configuration candidate using an existing local skill. |
| 4.3 | `api/hth-inspect-4.03-inventory-automations.sh` | Paginated inventory visible to one API key, with redaction/scope caveats. |
| 4.5 | `api/hth-inspect-4.05-disable-automation.sh` | Preview or explicitly disable automatic triggers on one editable automation. |

`api/common.sh` is a shared transport helper, not a tenth control pack or a vendor CLI. Keep it beside the API scripts. These are REST scripts and vendor-consumed configuration, not an official SDK. No undocumented audit-log export route is used.

## Requirements and safety

Use Bash, curl, jq, and Python 3 for API packs. Inject `INSPECT_API_KEY` at process launch through your approved secret manager; never paste it into source, command history, logs, or a repository environment file. The API scripts call only `https://app.inspect.com/api/v2`, reject origin overrides, ignore curl configuration/proxies, do not follow redirects, and do not retry writes. Use only where direct approved HTTPS egress is available. They never accept MCP OAuth tokens as REST keys.

Use a key with access to the intended resources. A key's visible objects do not establish organization-wide coverage. Read-only packs require `HTH_OUTPUT_FILE` naming a **new** file in an existing trusted private directory; an existing file is never overwritten. Reports can still contain repository IDs/names, skill names, and automation settings. Apply your evidence retention/access rules.

Mutating packs default to preview and require both `HTH_APPLY=1` and `HTH_CONFIRM_ID` matching the exact object. Obtain authorized change approval before setting them. They retain private before/request/after evidence in a new temporary directory and re-read before writing. The API has no documented conditional-write primitive for these operations: a residual race exists. Stop competing administrators and reconcile uncertain errors manually. A transport error does not prove a write failed. Never blindly repeat a write.

## Read-only usage

With the key already securely injected:

```bash
HTH_OUTPUT_FILE=/trusted/private/new-repositories.json \
  bash packs/inspect/api/hth-inspect-2.01-inventory-repositories.sh
INSPECT_AGENT_ID=exact-agent-id HTH_OUTPUT_FILE=/trusted/private/new-agent.json \
  bash packs/inspect/api/hth-inspect-2.02-audit-agent.sh
HTH_OUTPUT_FILE=/trusted/private/new-automations.json \
  bash packs/inspect/api/hth-inspect-4.03-inventory-automations.sh
```

Agent capabilities are deprecated in the API and are **not a security boundary**. In particular, `git_write=false` does not block pushes or PR creation. The audit does not certify isolation, connector permissions, or enforcement of repository selection. Automation inventory excludes archived objects, omits sensitive prompts/trigger details and reports visibility/redaction limitations. Inspect trigger details and destinations in the console. A page limit, duplicate item, malformed response or missing cursor produces an unknown/incomplete result, never a compliance pass.

## Reviewable changes

For an agent, create a reviewed JSON array of allowed repository IDs. The pack refuses empty/null lists and refuses additions to an existing restricted list. Start with preview:

```bash
INSPECT_AGENT_ID=exact-agent-id HTH_REPOSITORIES_FILE=/trusted/approved-repositories.json \
  bash packs/inspect/api/hth-inspect-2.06-restrict-agent-repositories.sh
INSPECT_AUTOMATION_ID=exact-automation-id \
  bash packs/inspect/api/hth-inspect-4.05-disable-automation.sh
```

After approval, repeat the same command with `HTH_APPLY=1 HTH_CONFIRM_ID=exact-object-id`. A successful read-back proves stored fields, not runtime enforcement. Disabling automatic triggers does not stop active sessions or prevent manual runs. Re-enabling an automation or widening/restoring an agent's scope is a separately reviewed change in the console; no automatic rollback is attempted. Preserve the snapshots but do not upload them to this public repository.

## Explicit verification invocation

The 4.2 API pack starts paid agent work, can supersede prior verification runs, and can run even when automatic verification is off. It defaults to preview and requires the target session, repository, PR number and reviewed 40-character commit SHA:

```bash
INSPECT_SESSION_ID=exact-session-id INSPECT_REPOSITORY_ID=exact-repository-id \
INSPECT_PULL_REQUEST_NUMBER=123 INSPECT_EXPECTED_HEAD_SHA=0000000000000000000000000000000000000000 \
  bash packs/inspect/api/hth-inspect-4.02-request-verification.sh
```

The SHA above is a placeholder, not a valid reviewed target. Only after approving the exact work/cost, set `HTH_APPLY=1 HTH_CONFIRM_ID=exact-session-id`. The session owner or original API creator must have access; the repository must have a valid verification configuration. The pack rechecks the observed target but the endpoint uses the current PR head and has no atomic expected-SHA condition. Avoid concurrent pushes and independently verify the tested commit in the resulting report. A `202 started` or `already_running` response proves acceptance, **not** successful testing or review. There is no retry or automated cancellation/rollback; inspect the current session before repeating an uncertain invocation.

## Native configuration candidates

The Approval baseline belongs at `.inspect/approvals/path_rules.yaml` in the target repository's default branch. Review and merge it with existing rules rather than overwriting them. It deliberately permits **no** autoapprovals and does not enable the organization switch. Narrow allow/classifier rules require separate review; GitHub required human reviews remain a separate control. Test harmless PRs and restore the prior reviewed policy commit to roll back.

The workload trust emitter requires exact issuer and canonical subject copied from Inspect settings, plus the AWS account containing the configured OIDC provider. This example uses dummy identifiers and the commercial AWS partition:

```bash
bash packs/inspect/config/hth-inspect-3.03-exact-workload-trust.sh \
  --issuer https://example.inspect.com/api/oidc \
  --subject 'org:org-id:repository:github:owner/repo:lifecycle:runtime' \
  --account-id 123456789012
```

Review the emitted candidate through your IAM process; merge existing trust and attach separately approved minimal permissions. It grants no AWS action permissions by itself. Prefer the AWS MCP connector when repository code need not hold credentials. Runtime and build identities are separate. Restore prior trust to roll back; existing temporary credentials may remain valid until expiration.

For Review/Verification, first create and test the skill in a trusted checkout:

```bash
bash packs/inspect/config/hth-inspect-4.02-review-verification-config.sh \
  review --repo /trusted/repo --skill security
bash packs/inspect/config/hth-inspect-4.02-review-verification-config.sh \
  verification --repo /trusted/repo --skill .agents/skills/verify-web/SKILL.md
```

The review skill must exist at `.claude/skills/security/SKILL.md`. The verification skill must be an existing repository-relative `SKILL.md`. Review emitted JSON (valid YAML), then merge it into `.inspect/reviews/rules.yml` or `.inspect/verification/config.yml` respectively through a reviewed PR. Existence is not proof of skill safety. Inspect reads review rules from the PR head; protect rules and skills. Restore prior configuration and rerun the intended SHA to roll back.

## Offline verification

```bash
python3 scripts/test-inspect-packs.py
python3 scripts/test-inspect-config-packs.py
python3 scripts/test-inspect-approval-config.py
bash scripts/validate-packs.sh inspect
```

Mocks exercise request shapes, safe defaults, failure handling and local configuration. They are not a vendor policy evaluator, a live API call, or proof that a tenant enforces the recommendation. See the guide's source coverage and validation ledgers for remaining limits.
