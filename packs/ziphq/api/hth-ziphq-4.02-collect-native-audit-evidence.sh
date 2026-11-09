#!/usr/bin/env bash
# HTH Pack Contract: v1
# control: ziphq-4.2
# guide: https://howtoharden.com/guides/ziphq/#42-collect-native-audit-evidence
# profile: L2
# mode: read-only
# requires: Bash; Python 3; curl >=8.4; ZIP_API_KEY
# HTH ZipHQ Control 4.2: Collect Native Audit Evidence
# Profile Level: L2 (Walk)
# Frameworks: NIST SP 800-53 AU-2, AU-6, AU-9, CA-7
# Dependencies: Bash, Python 3 standard library, curl >=8.4.
# Source (authenticated documentation read 2026-11-08, available):
# https://developers.ziphq.com/zipapidocs/reference/queryauditlogs
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
params = {'page_size': '100', 'sort_by': 'created_at', 'sort_order': 'asc'}
after = os.environ.pop('ZIP_CREATED_AFTER', '')
before = os.environ.pop('ZIP_CREATED_BEFORE', '')
if not re.fullmatch(r'[0-9]{1,12}', after) or not re.fullmatch(r'[0-9]{1,12}', before):
    fail('ZIP_CREATED_AFTER and ZIP_CREATED_BEFORE must be finite epoch seconds.')
after, before = int(after), int(before)
if not (0 <= after < before and before - after <= 31 * 86400):
    fail('Audit window must increase and span at most 31 days (collector safety limit).')
params.update(created_after=str(after), created_before=str(before))
known_events = set(('LOGIN_SUCCESS LOGIN_FAILURE LOGIN_RESULT_UNKNOWN LOGOUT_SUCCESS '
                    'UPDATE_USER_ACTIVE_STATUS UPDATE_USER_BASIC_INFO UPDATE_USER_DEPARTMENT '
                    'UPDATE_USER_MANAGER UPDATE_USER_SUBSIDIARY CREATE_WORKFLOW CLONE_WORKFLOW '
                    'DELETE_WORKFLOW UPDATE_WORKFLOW_DATA ADD_APPROVAL EDIT_APPROVAL DELETE_APPROVAL '
                    'ADD_CONDITION UPDATE_CONDITION DELETE_CONDITION ADD_GROUP_DEPENDENCY '
                    'DELETE_GROUP_DEPENDENCY').split())
endpoint = 'https://api.ziphq.com/event_logs'
seen_cursors = set()
seen_records = {}
counts = collections.Counter()
pages = 0


def get_page():
    target = endpoint + '?' + urllib.parse.urlencode(params)
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
    require(isinstance(data, dict) and 'error' not in data
            and isinstance(data.get('list'), list))
    for field in ('size', 'total'):
        require(field not in data or (type(data[field]) is int and data[field] >= 0))
    require(len(data['list']) <= 100)
    require('size' not in data or data['size'] == len(data['list']))
    return data


try:
    while True:
        require(pages < 100)
        data = get_page()
        pages += 1
        for item in data['list']:
            require(isinstance(item, dict) and uuid(item.get('id')))
            identifier = item['id'].lower()
            timestamp = item.get('timestamp')
            require('timestamp' not in item or (type(timestamp) is int and timestamp >= 0))
            event_type = item.get('event_type')
            require('event_type' not in item or isinstance(event_type, str))
            actor = item.get('actor')
            require(actor is None or isinstance(actor, dict))
            actor_type = actor.get('type') if actor else None
            require(actor_type is None or isinstance(actor_type, str))
            # Retain only safe projection in memory for conflict detection.
            summary = (timestamp, event_type, actor_type)
            if identifier in seen_records:
                require(seen_records[identifier] == summary)
                continue
            require(len(seen_records) < 10000)
            seen_records[identifier] = summary
            counts['event:' + (event_type if event_type in known_events else 'OTHER_OR_UNKNOWN')] += 1
            counts['actor:' + (actor_type if actor_type in (
                'USER', 'MCP', 'SUPER_AGENT', 'API_KEY', 'SYSTEM') else 'UNKNOWN')] += 1
            if timestamp is None:
                counts['timestampUnknown'] += 1
            elif not after <= timestamp <= before:
                counts['timestampOutsideRequestedWindow'] += 1
        cursor = data.get('next_page_token')
        if cursor is None:
            break
        require(isinstance(cursor, str) and 0 < len(cursor) <= 8192
                and all(ord(c) >= 32 and ord(c) != 127 for c in cursor)
                and cursor not in seen_cursors)
        seen_cursors.add(cursor)
        params['page_token'] = cursor
    result = {'result': 'review-required', 'scope': 'Zip native API evidence',
              'apiVersion': '2024-06-06', 'pages': pages,
              'uniqueRecords': len(seen_records), 'collectionComplete': True,
              'counts': dict(sorted(counts.items()))}
    result['window'] = {'created_after': after, 'created_before': before}
    result['limitation'] = 'Premier required. Collection completeness is for returned pagination only, not retention or exhaustive event coverage. Unknown event types are counted in OTHER_OR_UNKNOWN. MCP events with a human creator may have USER actor.'
    print(json.dumps(result, sort_keys=True))
except (ValueError, TypeError, KeyError, RecursionError):
    fail('Invalid or incomplete Zip response.')
PYTHON
# HTH Guide Excerpt: end native-evidence
