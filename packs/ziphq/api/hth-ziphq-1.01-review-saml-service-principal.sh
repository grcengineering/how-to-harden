#!/usr/bin/env bash
# HTH Pack Contract: v1
# control: ziphq-1.1
# guide: https://howtoharden.com/guides/ziphq/#11-configure-workforce-saml-sso
# profile: L1
# mode: read-only
# requires: Bash; Python 3; curl >=8.4; GRAPH_ACCESS_TOKEN; ZIP_ENTRA_SERVICE_PRINCIPAL_ID
# HTH ZipHQ Control 1.01: Review Saml Service Principal
# Profile Level: L1 (Crawl)
# Frameworks: NIST SP 800-53 AC-2, AC-3; CIS Controls 6.1
# Guide: https://howtoharden.com/guides/ziphq/#11-configure-workforce-saml-sso
# Dependencies: Bash, Python 3 (stdlib), curl >= 8.4 (bounded response support).
# Permission: Application.Read.All (delegated or application). No credential acquisition.
# Source (available v1.0, fetched 2026-11-08):
# https://learn.microsoft.com/en-us/graph/api/serviceprincipal-get?view=graph-rest-1.0
# Validation: Tier 0/static and Tier 1/mocked only; no real tenant tested.
# Not Zip-native automation. Do not grant write permissions for this collector.
# HTH Guide Excerpt: begin entra-evidence
# Entra ID verification only, not Zip-native hardening. GET requests only.
# Supply an existing read-only GRAPH_ACCESS_TOKEN and the Zip enterprise app's
# ZIP_ENTRA_SERVICE_PRINCIPAL_ID (Object ID, not application/client ID).
# Exit 0 = evidence collected, NOT a passing control. Never run with shell tracing.
set +x
set -euo pipefail
command -v python3 >/dev/null || { printf '%s\n' 'ERROR: python3 is required.' >&2; exit 1; }
command -v curl >/dev/null || { printf '%s\n' 'ERROR: curl is required.' >&2; exit 1; }
python3 - <<'PYTHON'
import collections
import json
import os
import re
import subprocess
import sys
import urllib.parse


def fail(message):
    print('ERROR: ' + message, file=sys.stderr)
    raise SystemExit(1)


def require(condition):
    if not condition:
        fail('Invalid or incomplete Graph response; evidence not collected.')


# Restrict token characters to the RFC 6750 bearer-token alphabet: no config
# injection, whitespace, quotes or backslashes. Never put a token in curl argv.
token = os.environ.pop('GRAPH_ACCESS_TOKEN', '')
sp = os.environ.pop('ZIP_ENTRA_SERVICE_PRINCIPAL_ID', '')
if not re.fullmatch(r'[A-Za-z0-9._~+/-]+=*', token):
    fail('GRAPH_ACCESS_TOKEN must be a nonempty bearer token without whitespace.')
if not re.fullmatch(r'[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}', sp):
    fail('ZIP_ENTRA_SERVICE_PRINCIPAL_ID must be a UUID Object ID.')
base = 'https://graph.microsoft.com/v1.0/servicePrincipals/' + sp
url = base + '?$select=id,appId,accountEnabled,preferredSingleSignOnMode,appRoleAssignmentRequired'
expected_path = urllib.parse.urlsplit(url).path
seen_urls = set()
seen_items = {}
counts = collections.Counter()


def get_page(target):
    # Validate EVERY URL before forwarding authorization, including nextLink.
    # Literal path equality deliberately rejects encodings and traversal, and
    # exact authority equality rejects suffix hosts, ports and userinfo.
    parsed = urllib.parse.urlsplit(target)
    require(parsed.scheme == 'https' and parsed.netloc == 'graph.microsoft.com'
            and parsed.path == expected_path and not parsed.fragment
            and all(33 <= ord(c) <= 126 for c in target)
            and '\\' not in target and len(target) <= 16384)
    require(target not in seen_urls and len(seen_urls) < 100)
    seen_urls.add(target)
    try:
        response = subprocess.run(
            ['curl', '-q', '--config', '-', '--request', 'GET',
             '--proto', '=https', '--tlsv1.2', '--max-redirs', '0',
             '--connect-timeout', '10', '--max-time', '60',
             '--max-filesize', '10485760', '--silent', '--fail',
             '--write-out', '\n%{http_code}', '--url', target],
            input=('header = "Authorization: Bearer ' + token + '"\n'
                   'header = "Accept: application/json"\n').encode(),
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            timeout=65, check=False)
    except (OSError, subprocess.TimeoutExpired):
        fail('Graph request failed or timed out; no response details printed.')
    if response.returncode != 0:
        fail('Graph request failed (HTTP, TLS or transport error); no response details printed.')
    body, separator, code = response.stdout.rpartition(b'\n')
    if not separator or code != b'200' or len(body) > 10485760:
        fail('Expected HTTP 200 with a bounded JSON response; evidence not collected.')
    try:
        data = json.loads(body)
    except (ValueError, UnicodeError):
        fail('Graph returned invalid JSON; evidence not collected.')
    require(isinstance(data, dict) and 'error' not in data)
    return data


try:
    data = get_page(url)
    require(isinstance(data.get('id'), str) and data['id'].lower() == sp.lower())
    require(isinstance(data.get('appId'), str) and bool(re.fullmatch(
        r'[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}', data['appId'])))
    require(type(data.get('accountEnabled')) is bool
            and type(data.get('appRoleAssignmentRequired')) is bool
            and 'preferredSingleSignOnMode' in data
            and (data['preferredSingleSignOnMode'] is None
                 or isinstance(data['preferredSingleSignOnMode'], str)))
    print(json.dumps({'result': 'review-required', 'scope': 'Microsoft Entra ID only',
                      'accountEnabled': data['accountEnabled'],
                      'samlSelected': data['preferredSingleSignOnMode'] == 'saml',
                      'assignmentRequired': data['appRoleAssignmentRequired'],
                      'limitation': 'Does not prove Zip SSO enforcement or MFA.'}, sort_keys=True))
except (ValueError, TypeError, KeyError, RecursionError):
    fail('Invalid or incomplete Graph response; evidence not collected.')
PYTHON
# HTH Guide Excerpt: end entra-evidence
