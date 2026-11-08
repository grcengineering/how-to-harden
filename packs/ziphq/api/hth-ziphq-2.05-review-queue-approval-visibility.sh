#!/usr/bin/env bash
# HTH Pack Contract: v1
# control: ziphq-2.5
# guide: https://howtoharden.com/guides/ziphq/#25-review-queue-approval-visibility
# profile: L2
# mode: read-only
# requires: Bash; Python 3; curl >=8.4; ZIP_API_KEY; ZIP_QUEUE_ID
# HTH ZipHQ Control 2.5: Review Queue Approval Visibility
# Profile Level: L2 (Walk)
# Frameworks: NIST SP 800-53 AC-3, AC-4, AC-6
# Dependencies: Bash, Python 3 standard library, curl >=8.4.
# Source (authenticated documentation read 2026-11-08, available):
# https://developers.ziphq.com/zipapidocs/reference/getqueuebyid
# Authentication/version conflict: use explicitly pinned legacy API-key mode;
# 2026-07-01+ OpenAPI requires bearer JWT, unsupported by this collector.
# https://developers.ziphq.com/zipapidocs/docs/versioning
# https://developers.ziphq.com/zipapidocs/docs/getting-started
# HTH Guide Excerpt: begin native-evidence
# GET-only evidence, not enforcement. Use an existing restricted Read only key.
# Pins documented legacy API-key version 2024-06-06, NOT the latest version.
# No live tenant validation. Successful collection always requires human review.
set +x
set -euo pipefail
command -v python3 >/dev/null || { echo 'ERROR: python3 required.' >&2; exit 1; }
command -v curl >/dev/null || { echo 'ERROR: curl required.' >&2; exit 1; }
python3 - <<'PYTHON'
import collections
import json
import os
import re
import subprocess
import sys
import urllib.parse


def fail(message):
    print('ERROR: ' + message + ' No complete evidence produced.', file=sys.stderr)
    raise SystemExit(1)


def require(condition):
    if not condition:
        fail('Invalid or incomplete Zip response.')


def uuid(value):
    return isinstance(value, str) and bool(re.fullmatch(
        r'[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}', value))


def baseline(name):
    value = os.environ.pop(name, '')
    if not value:
        return None
    values = value.split(',')
    if len(values) > 10000 or not all(uuid(v) for v in values):
        fail('Approved baseline must be comma-separated UUIDs without spaces.')
    return {v.lower() for v in values}


def optional_bool(item, name):
    value = item.get(name)
    require(name not in item or type(value) is bool)
    return value


key = os.environ.pop('ZIP_API_KEY', '')
# No invented key format; reject characters that can inject curl config lines.
if not key or len(key) > 8192 or not all(33 <= ord(c) <= 126 and c not in '\\"' for c in key):
    fail('ZIP_API_KEY must be a nonempty single-line safe token.')
if os.environ.pop('ZIP_API_VERSION', '2024-06-06') != '2024-06-06':
    fail('This collector only supports pinned legacy API-key version 2024-06-06.')
# Do not propagate credentials to subprocesses, even from an unrelated collector.
os.environ.pop('GRAPH_ACCESS_TOKEN', None)
queue_id = os.environ.pop('ZIP_QUEUE_ID', '')
if not uuid(queue_id):
    fail('ZIP_QUEUE_ID must be one known, approved queue UUID.')
queue_id = queue_id.lower()
endpoint = 'https://api.ziphq.com/queues/' + queue_id


def get_page():
    target = endpoint
    # No response URL is ever used. page_token is only an encoded query value.
    try:
        response = subprocess.run(
            ['curl', '-q', '--config', '-', '--request', 'GET',
             '--proto', '=https', '--tlsv1.2', '--max-redirs', '0',
             '--proxy', '', '--noproxy', '*', '--connect-timeout', '10',
             '--max-time', '60', '--max-filesize', '10485760', '--silent',
             '--fail', '--write-out', '\n%{http_code}', '--url', target],
            input=('header = "Zip-Api-Key: ' + key + '"\n'
                   'header = "Zip-Api-Version: 2024-06-06"\n'
                   'header = "Accept: application/json"\n').encode(),
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            timeout=65, check=False)
    except (OSError, subprocess.TimeoutExpired):
        fail('Request failed or timed out.')
    # Includes 401/403/405/429/5xx; never echo response bodies or curl errors.
    if response.returncode:
        fail('HTTP, TLS or transport error. Check access or retry later.')
    body, separator, code = response.stdout.rpartition(b'\n')
    require(separator and code == b'200' and len(body) <= 10485760)
    try:
        data = json.loads(body)
    except (ValueError, UnicodeError):
        fail('Invalid JSON.')
    require(isinstance(data, dict) and 'error' not in data)
    return data


try:
    data = get_page()
    require(uuid(data.get('id')) and data['id'].lower() == queue_id)
    counts = {'requestedQueues': 1, 'fetchedQueues': 1, 'errors': 0}
    for field, label in (('queue_owners', 'owners'), ('queue_members', 'members')):
        values = data.get(field)
        require(field not in data or isinstance(values, list))
        if values is None:
            counts[label] = None
        else:
            require(len(values) <= 10000 and all(
                isinstance(v, dict) and uuid(v.get('id')) for v in values))
            counts[label] = len({v['id'].lower() for v in values})
    for field, label in (
        ('all_members_can_view_approvals', 'viewApprovals'),
        ('all_members_will_receive_approval_notifications', 'receiveApprovalNotifications')):
        value = data.get(field)
        require(value is None or type(value) is bool)
        counts[label + ':' + ('unknown' if value is None else str(value).lower())] = 1
    print(json.dumps({'result': 'review-required', 'scope': 'One explicitly supplied Zip queue',
                      'apiVersion': '2024-06-06', 'counts': counts,
                      'limitation': 'Not tenant-wide inventory or proof of separation of duties. Missing memberships are null (unknown), not zero.'}, sort_keys=True))
except (ValueError, TypeError, KeyError, RecursionError):
    fail('Invalid or incomplete Zip response.')
PYTHON
# HTH Guide Excerpt: end native-evidence
