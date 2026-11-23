#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: inspect-3.3
#   guide: https://howtoharden.com/guides/inspect/#33-bind-sandbox-workload-identity-to-exact-trust
#   profile: L2
#   mode: read-only
#   requires: python3; exact issuer and subject from Inspect settings; AWS account ID
# Source: https://docs.inspect.com/settings/sandbox-workload-identity (2026-11-17)
# Source: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html
# Status: documented public configuration; no tenant validation.
# Emits a CANDIDATE AWS trust policy to stdout. No API calls, token reads or writes.
# This is an Inspect integration boundary, not a general AWS hardening baseline.
# Prefer the AWS MCP connector when repository processes do not need credentials.
# Review/merge through the approved IAM change process; do not overwrite existing
# trust automatically. Attach a separately approved least-privilege permissions
# policy. This policy alone grants no AWS actions. Restore prior trust to roll back;
# changing trust does not invalidate already-issued credentials.
# HTH Guide Excerpt: begin exact-workload-trust
set -euo pipefail
python3 - "$@" <<'PY'
import argparse
import json
import re
from urllib.parse import urlsplit

p = argparse.ArgumentParser(description='Emit exact-repository, exact-lifecycle Inspect OIDC trust; never apply it.')
p.add_argument('--issuer', required=True, help='Copy the full issuer from Organization > Security > Workload identities')
p.add_argument('--subject', required=True, help='Exact canonical subject including organization, repository and runtime or build lifecycle')
p.add_argument('--account-id', required=True, help='AWS account containing the already configured Inspect OIDC provider')
a = p.parse_args()
u = urlsplit(a.issuer)
if (u.scheme != 'https' or not u.hostname or u.netloc != u.hostname
        or not re.fullmatch(r'[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.inspect\.com', u.hostname)
        or u.path != '/api/oidc' or u.query or u.fragment):
    p.error('issuer must be the exact HTTPS <workspace>.inspect.com/api/oidc URL, without credentials, port, query or fragment')
# Use already-canonical, percent-encoded values as supplied by Inspect. Do not
# guess organization IDs, use workspace aliases, or silently URL-encode twice.
component = r'(?:[A-Za-z0-9_.~-]|%[0-9A-Fa-f]{2})+'
pattern = rf'org:{component}:repository:{component}:{component}/{component}:lifecycle:(?:runtime|build)'
if not re.fullmatch(pattern, a.subject):
    p.error('subject must name one exact organization, host key, owner/repository and runtime or build lifecycle; wildcards are forbidden')
if not re.fullmatch(r'\d{12}', a.account_id):
    p.error('account-id must contain exactly 12 digits')
issuer_key = u.netloc + u.path
policy = {
    'Version': '2012-10-17',
    'Statement': [{
        'Effect': 'Allow',
        'Principal': {'Federated': f'arn:aws:iam::{a.account_id}:oidc-provider/{issuer_key}'},
        'Action': 'sts:AssumeRoleWithWebIdentity',
        'Condition': {'StringEquals': {
            issuer_key + ':aud': 'sts.amazonaws.com',
            issuer_key + ':sub': a.subject,
        }},
    }],
}
print(json.dumps(policy, indent=2))
PY
# HTH Guide Excerpt: end exact-workload-trust
