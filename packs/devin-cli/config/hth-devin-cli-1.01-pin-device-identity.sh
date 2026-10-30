#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-cli-1.1
#   guide: https://howtoharden.com/guides/devin-cli/#11-pin-device-identity
#   profile: L2
#   mode: read-only
#   requires: bash, python3; confirmed enterprise host/account for emit
# HTH Control 1.01: Pin Device Identity
# Framework: NIST SP 800-53 Rev. 5 CM-6
# Source (fetched 2026-10-29): https://docs.devin.ai/cli/enterprise/system-config
# Validation: offline fixtures only; not tested with a Devin account.

# HTH Guide Excerpt: begin pin-device-identity
set -euo pipefail
# emit: prints strict JSON only; never writes a managed path.
# validate FILE: schema check only. audit FILE: also checks Unix ownership/mode.
# Required env for emit: DEVIN_ENTERPRISE_HOST, DEVIN_ACCOUNT_ID.
# Optional DEVIN_PROXY_URL must be a credential-free approved HTTP(S)/SOCKS5 URL.
python3 - "$@" <<'PYCODE'
import json, os, pathlib, re, stat, sys
from urllib.parse import urlsplit

def fail(msg):
    raise ValueError(msg)
def host_ok(host):
    return isinstance(host, str) and bool(re.fullmatch(r'[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?', host)) and '.' in host and '..' not in host

def validate(data):
    if not isinstance(data, dict) or set(data) - {'enterprise_host', 'account_id', 'proxy'}:
        fail('Expected only documented system.json keys')
    if not host_ok(data.get('enterprise_host')):
        fail('enterprise_host must be a bare DNS hostname (HTTPS is implicit)')
    acct = data.get('account_id')
    if not isinstance(acct, str) or not acct.strip() or acct != acct.strip():
        fail('account_id must be the confirmed, nonblank Cognition account identifier')
    if 'proxy' in data:
        proxy = data['proxy']
        if not isinstance(proxy, dict) or set(proxy) - {'mode', 'url', 'no_proxy'}:
            fail('Unrecognized proxy shape')
        if proxy.get('mode') != 'manual':
            fail('This baseline requires manual proxy mode when proxy is configured')
        if not isinstance(proxy.get('url'), str):
            fail('Proxy URL must be a string')
        url = urlsplit(proxy['url'])
        if (url.scheme not in {'http', 'https', 'socks5'} or not url.hostname or
                url.username or url.password or url.query or url.fragment or url.path not in {'', '/'}):
            fail('Proxy must have an approved scheme and no embedded credentials, query, fragment or path')
        if proxy.get('no_proxy') not in (None, ''):
            fail('Review proxy bypasses separately; this baseline permits none')

try:
    if len(sys.argv) == 2 and sys.argv[1] == 'emit':
        data = {'enterprise_host': os.environ.get('DEVIN_ENTERPRISE_HOST'),
                'account_id': os.environ.get('DEVIN_ACCOUNT_ID')}
        if os.environ.get('DEVIN_PROXY_URL'):
            data['proxy'] = {'mode': 'manual', 'url': os.environ['DEVIN_PROXY_URL'], 'no_proxy': ''}
        validate(data)
        print(json.dumps(data, indent=2))
    elif len(sys.argv) == 3 and sys.argv[1] in {'validate', 'audit'}:
        path = pathlib.Path(sys.argv[2]).absolute()
        if path.is_symlink() or not path.is_file():
            fail('Policy must be a regular, non-symlink file')
        def unique_keys(pairs):
            obj = {}
            for k, v in pairs:
                if k in obj: fail('Duplicate JSON key')
                obj[k] = v
            return obj
        data = json.loads(path.read_text(encoding='utf-8'), object_pairs_hook=unique_keys)
        validate(data)
        if sys.argv[1] == 'audit':
            if os.name != 'posix': fail('Windows ACL verification requires your endpoint-management tooling')
            for item in [path, *path.parents]:
                st = item.lstat()
                if stat.S_ISLNK(st.st_mode) or st.st_uid != 0 or st.st_mode & 0o022:
                    fail('Policy or ancestor is symlinked, non-root-owned, or group/world-writable')
            print('PASS: strict JSON and Unix ownership/modes; ACLs and effective login still require review')
        else:
            print('PASS: strict JSON/schema only; NOT deployment or login enforcement proof')
    else:
        fail('Usage: script emit | validate FILE | audit FILE')
except (ValueError, OSError) as exc:
    print('FAIL: ' + str(exc), file=sys.stderr)
    sys.exit(1)
PYCODE
# HTH Guide Excerpt: end pin-device-identity
