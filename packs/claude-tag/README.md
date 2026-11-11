# Claude Tag Code Packs

Source: [official beta Admin API](https://platform.claude.com/docs/en/manage-claude/claude-tag-api), checked 2026-11-11. See the [guide](https://howtoharden.com/guides/claude-tag/) and [coverage/limits ledger](../../docs/research/claude-tag-source-coverage-2026-11.md).

These packs have **offline fixture validation only**. No live tenant validation or production change was performed. API beta changes can invalidate the contract.

## Prerequisites

- Run from a complete repository checkout: the Tag API helper reuses `packs/anthropic-claude/api/common.sh`.
- Bash, curl and jq for API scripts; Python 3 plus the current official `anthropic` SDK exposing `beta.organization.claude_tag` for the SDK script. SDK availability is checked at runtime; an unsupported installed version fails rather than producing success.
- An Enterprise organization (the Tag API is not available on Team) and an authorized **claude.ai organization-scoped API key**, with `read:claude_tag`, and `write:claude_tag` only for a deliberate apply. A Claude Console Admin key is not interchangeable.
- Supply the key via an approved secret-injection environment, not a committed file or shell-history command. API scripts use `ANTHROPIC_ADMIN_KEY`; CLI and SDK use `ANTHROPIC_API_KEY`. Never run with shell tracing enabled.
- Protect reports and private snapshots as organizational evidence. They include resource IDs; apply snapshots can also contain existing instructions. No evidence should be uploaded publicly.

## Read-only inventory

Run `bash packs/claude-tag/api/hth-claude-tag-1.01-audit.sh`.

Optional `HTH_GRID_IDS` supplies space-separated Slack Grid IDs (`E...`) that the workspace list cannot discover. `HTH_APPROVED_CHANNEL_IDS` supplies exact reviewed API channel IDs (`slch_...`); without an allowlist every enabled channel is flagged for review, not automatically changed.

Run `python3 packs/claude-tag/sdk/hth-claude-tag-1.03-bundle-target-inventory.py` for an independent SDK route to explicit bundle targets. SDK iterators paginate; they cannot expose bundle contents, default Slack grants or name-rule-derived access.

Neither inventory proves all Slack channels or all effective permissions were discovered. Reconcile the console and upstream resource permissions.

## Native CLI read

With a current official `ant` CLI installed, set the exact `HTH_CHANNEL_ID` and supply the scoped key as secret-injected `ANTHROPIC_API_KEY`, then run `bash packs/claude-tag/cli/hth-claude-tag-1.01-effective-channel.sh`. It retrieves one channel with inherited values, validates the response, and omits instructions from output. This is not a list or full inventory. Exact command/flags were source-verified and fixture-tested; the native binary was unavailable for execution in this review.

## Preview and explicit containment

Set `HTH_CHANNEL_ID`, `HTH_SLACK_WORKSPACE_ID` and `HTH_SLACK_CHANNEL_ID` to the exact existing target. Run `bash packs/claude-tag/api/hth-claude-tag-1.02-lockdown-channel.sh` to preview. It performs reads and emits the proposed partial update only.

After reviewing the exact target, set both `HTH_APPLY=1` and `HTH_CONFIRM_CHANNEL_ID` equal to the exact API channel ID and run again. This disables that channel and restricts guests; it does not grant, delete, provision credentials or change other channel settings. It saves private before/after snapshots and verifies stored and inherited read-back. It is **not a global kill switch**, does not disable DMs, revoke upstream credentials or prove that running sessions terminated.

The API is last-write-wins, without conditional writes. Coordinate with other administrators and inspect failures/concurrent edits; do not blindly retry or replay an old snapshot. Any rollback must be a new reviewed decision against current state, not an automatic restoration of potentially unsafe access.

## Tests

`python3 scripts/test-claude-tag-packs.py` exercises mock transport and SDK objects without credentials or network access. Bash syntax and ShellCheck provide static checks. These tests do not change maturity to live-validated.
