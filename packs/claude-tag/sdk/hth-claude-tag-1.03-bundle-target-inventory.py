#!/usr/bin/env python3
# HTH Pack Contract: v1
#   control: claude-tag-1.3
#   guide: https://howtoharden.com/guides/claude-tag/#13-cross-check-explicit-bundle-targets-with-the-sdk
#   profile: L1
#   mode: read-only
#   requires: Python 3, compatible anthropic SDK, organization-scoped claude.ai read:claude_tag key
# HTH 1.03: Inventory explicit Claude Tag Access bundle targets (read only)
# Claude Enterprise only: Team plans cannot use these scoped Admin API endpoints.
# Profile: L1 | NIST CSF PR.AA-05 | https://howtoharden.com/guides/claude-tag/
# Beta interface verified: https://platform.claude.com/docs/en/manage-claude/claude-tag-api
# Requires current official anthropic Python SDK with beta.organization.claude_tag.
# ANTHROPIC_API_KEY must be a claude.ai org-scoped read:claude_tag key, NOT Console.
# No Bundle descriptions, contents, instructions, or credentials are printed.
# HTH Guide Excerpt: begin bundle-inventory
import json
import os
import sys


def inventory(tag):
    rows = []
    # Official iterators exhaust pages, including empty pages with next_page.
    for bundle in tag.bundles.list():
        for target in tag.bundles.targets.list(bundle.id):
            rows.append({
                'bundle_id': bundle.id, 'target_id': target.id,
                'target_type': target.type,
                'slack_channel_id': getattr(target, 'slack_channel_id', None),
                'slack_workspace_id': getattr(target, 'slack_workspace_id', None),
            })
    return {
        'explicit_targets': rows,
        'limitations': [
            'Bundle contents are not exposed: inspect them in claude.ai.',
            'Default Slack access and rule-derived Bundle access are not targets.',
            'Workspace targets grant access across that workspace, not one channel.',
            'This is not a complete effective-permission assessment.',
        ],
    }


def main():
    # Prevent ambient SDK base URL overrides from routing the scoped key elsewhere.
    if os.getenv('ANTHROPIC_BASE_URL', 'https://api.anthropic.com') != 'https://api.anthropic.com':
        raise ValueError('Only the official API origin is supported')
    key = os.environ['ANTHROPIC_API_KEY']
    if not key or any(c.isspace() for c in key):
        raise ValueError('A scoped key is required')
    import anthropic
    import httpx
    client = anthropic.Anthropic(api_key=key, base_url='https://api.anthropic.com',
                                 max_retries=0, timeout=30.0,
                                 http_client=httpx.Client(follow_redirects=False))
    # No partial stdout if a later page fails. SDK supplies beta/version headers.
    print(json.dumps(inventory(client.beta.organization.claude_tag), indent=2))


if __name__ == '__main__':
    try:
        main()
    except Exception:
        # SDK errors may contain request/response details; do not log secrets/content.
        print('Inventory failed; check SDK version, scoped key, API access and connectivity. No complete evidence emitted.', file=sys.stderr)
        sys.exit(1)
# HTH Guide Excerpt: end bundle-inventory
