#!/usr/bin/env python3
"""Offline behavioral checks; never calls Assembled or mutates a real widget."""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('assembled_pack', ROOT / 'packs/assembled/api/common.py')
pack = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pack)


def person(ident, roles=None, email='former@example.invalid', deleted=False):
    return {'id': ident, 'roles': ['role-a'] if roles is None else roles,
            'email': email, 'deleted': deleted}


def page(kind, rows, total=None):
    return {kind: {r['id']: r for r in rows}, 'total': len(rows) if total is None else total}


def event(ident, time=100):
    return {'id': ident, 'modified_at': time, 'modified_by': {'id': 'actor', 'email': 'private@example.invalid', 'name': 'Private'},
            'event_change_type': 'modify', 'description': 'private text'}


class CollectionTests(unittest.TestCase):
    def test_paginates_by_actual_count_and_requests_deleted_explicitly(self):
        responses = [page('people', [person('a')], 2), page('people', [person('b')], 2)]
        with patch.object(pack, 'request', side_effect=responses) as request:
            rows = pack.collect('/v0/people', 'people', 'dummy', '&include_deleted=true')
        self.assertEqual(list(rows), ['a', 'b'])
        self.assertEqual(request.call_args_list[1].args[0], '/v0/people?limit=100&offset=1&include_deleted=true')

    def test_valid_empty_page(self):
        with patch.object(pack, 'request', return_value=page('people', [])):
            self.assertEqual(pack.collect('/v0/people', 'people', 'dummy'), {})

    def test_invalid_pages_fail_closed(self):
        bad = [[], {'people': []}, {'people': {'a': person('b')}, 'total': 1},
               {'people': {}}, {'people': {}, 'total': True}, {'people': {}, 'total': -1},
               page('people', [], 1), page('people', [person('a')], 0)]
        for response in bad:
            with self.subTest(response=response), patch.object(pack, 'request', return_value=response):
                with self.assertRaises((pack.PackError, AttributeError)):
                    pack.collect('/v0/people', 'people', 'dummy')

    def test_repeated_page_and_changed_total_rejected(self):
        first = page('people', [person('a')], 2)
        for second in [first, page('people', [person('b')], 3)]:
            with patch.object(pack, 'request', side_effect=[first, second]):
                with self.assertRaises(pack.PackError):
                    pack.collect('/v0/people', 'people', 'dummy')

    def test_oversize_page_rejected(self):
        with patch.object(pack, 'request', return_value=page('people', [person(str(i)) for i in range(101)])):
            with self.assertRaises(pack.PackError):
                pack.collect('/v0/people', 'people', 'dummy')


class ReportTests(unittest.TestCase):
    def capture(self, fn, *args):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            fn(*args)
        return out.getvalue()

    def test_roles_membership_is_review_and_omits_pii(self):
        roles = {'roles': {'role-a': {'id': 'role-a', 'name': 'Admin'}}}
        people = page('people', [person('a'), person('b', ['unknown'])])
        with patch.object(pack, 'request', side_effect=[roles, people]):
            output = self.capture(pack.roles_report, 'dummy')
        self.assertNotIn('former@', output)
        result = json.loads(output)
        self.assertEqual(result['result'], 'REVIEW')
        self.assertEqual(result['ambiguous_or_unknown_role_assignments'], 1)
        self.assertEqual(result['roles'][0]['assigned_people'], 1)

    def test_missing_role_fields_emit_no_report(self):
        bad = person('a'); del bad['roles']
        out = io.StringIO()
        with patch.object(pack, 'request', side_effect=[{'roles': {}}, page('people', [bad])]), contextlib.redirect_stdout(out):
            with self.assertRaises(pack.PackError):
                pack.roles_report('dummy')
        self.assertEqual(out.getvalue(), '')

    def test_leavers_match_case_insensitively_without_claiming_revocation(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / 'leavers.txt'; target.write_text('FORMER@example.invalid\n')
            rows = page('people', [person('a'), person('b', deleted=True), person('c', email='other@example.invalid')])
            with patch.object(pack, 'request', return_value=rows):
                output = self.capture(pack.leavers_report, 'dummy', target)
        self.assertNotIn('example.invalid', output)
        result = json.loads(output)
        self.assertEqual(len(result['matching_directory_records']), 2)
        self.assertIn('not a login/deactivation signal', result['limitation'])

    def test_empty_leavers_file_rejected_before_request(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / 'leavers.txt'; target.write_text('')
            with patch.object(pack, 'request') as request:
                with self.assertRaises(pack.PackError): pack.leavers_report('dummy', target)
                request.assert_not_called()

    def test_event_output_uses_documented_minimal_fields(self):
        with patch.dict(os.environ, {'ASSEMBLED_START_TIME': '1', 'ASSEMBLED_END_TIME': '101'}), patch.object(pack, 'request', return_value=page('event_changes', [event('b'), event('a', 50)])):
            output = self.capture(pack.event_report, 'dummy')
        records = [json.loads(row) for row in output.splitlines()]
        self.assertEqual([row['id'] for row in records], ['a', 'b'])
        self.assertEqual(set(records[0]), {'id', 'modified_at', 'modified_by', 'event_change_type'})
        self.assertNotIn('private', output.lower())

    def test_late_invalid_event_emits_no_partial_output(self):
        bad = event('b'); del bad['modified_by']
        out = io.StringIO()
        with patch.dict(os.environ, {'ASSEMBLED_START_TIME': '1', 'ASSEMBLED_END_TIME': '101'}), patch.object(pack, 'request', return_value=page('event_changes', [event('a'), bad])), contextlib.redirect_stdout(out):
            with self.assertRaises(pack.PackError): pack.event_report('dummy')
        self.assertEqual(out.getvalue(), '')

    def test_invalid_windows_do_not_call_transport(self):
        for start, end in [('x', '12'), ('1', '1'), ('2', '1'), ('0', str(32*86400)), ('-1', '2')]:
            with self.subTest(start=start, end=end), patch.dict(os.environ, {'ASSEMBLED_START_TIME': start, 'ASSEMBLED_END_TIME': end}), patch.object(pack, 'request') as request:
                with self.assertRaises(pack.PackError): pack.event_report('dummy')
                request.assert_not_called()


class TransportTests(unittest.TestCase):
    def response(self, body='{}', status='200', code=0):
        return subprocess.CompletedProcess([], code, body+'\n'+status, 'secret-like remote error')

    def test_key_stays_off_argv_and_url_and_uses_basic_auth(self):
        key = 'sk_live_FIXTURE_ONLY'
        with patch.object(pack.subprocess, 'run', return_value=self.response()) as run:
            self.assertEqual(pack.request('/v0/roles', key), {})
        args = run.call_args.args[0]
        self.assertNotIn(key, ' '.join(args))
        self.assertEqual(args[0:2], ['curl', '-q'])
        self.assertEqual(args[-1], 'https://api.assembledhq.com/v0/roles')
        self.assertNotIn('--location', args)
        self.assertEqual(run.call_args.kwargs['input'], 'user = "sk_live_FIXTURE_ONLY:"\n')

    def test_http_transport_and_schema_errors_rejected(self):
        bad = [self.response(status='301'), self.response(status='401'), self.response(status='429'),
               self.response(code=1), self.response('not JSON'), self.response('[]')]
        for response in bad:
            with patch.object(pack.subprocess, 'run', return_value=response):
                with self.assertRaises(pack.PackError): pack.request('/v0/roles', 'dummy')

    def test_invalid_key_and_newline_injection_do_not_call_curl(self):
        for key in ['', 'sk_live_bad\nuser=x', 'sk_live_quote"', 'Bearer token']:
            with patch.dict(os.environ, {'ASSEMBLED_API_KEY': key}), patch.object(pack.subprocess, 'run') as run:
                with self.assertRaises(pack.PackError): pack.main()
                run.assert_not_called()

    def test_main_removes_key_from_child_environment(self):
        with patch.dict(os.environ, {'ASSEMBLED_API_KEY': 'sk_live_FIXTURE_ONLY'}), patch.object(pack.sys, 'argv', ['common.py', 'roles']), patch.object(pack, 'roles_report') as report:
            pack.main()
            self.assertNotIn('ASSEMBLED_API_KEY', os.environ)
            report.assert_called_once_with('sk_live_FIXTURE_ONLY')

    def test_wrappers_reject_arguments_without_network(self):
        for vendor in ['assembled', 'assembled-wfm']:
            for path in (ROOT / 'packs' / vendor / 'api').glob('hth-*.sh'):
                args = [] if 'departed' in path.name else ['unexpected']
                result = subprocess.run(['bash', str(path)] + args, capture_output=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, b'')

    def test_browser_sdk_awaits_clear_and_does_not_reinitialize(self):
        path = ROOT / 'packs/assembled-ai/sdk/hth-assembled-ai-2.03-clear-chat-sessions.js'
        test = '''import fs from 'node:fs'; import assert from 'node:assert/strict';
const code = fs.readFileSync(process.argv[1], 'utf8');
const {clearAssembledChatSession: clear} = await import('data:text/javascript;base64,'+Buffer.from(code).toString('base64'));
globalThis.window = {};
await assert.rejects(clear(), /unavailable/);
let resolve, called = 0, finished = false;
window.assembled = {teardown(options) {called++; assert.deepEqual(options, {clearSession:true}); return new Promise(r => {resolve=r;});}, init() {throw Error('must not auto-initialize');}};
const promise = clear().then(() => {finished = true;});
await Promise.resolve(); assert.equal(finished, false); assert.equal(called, 1);
resolve(); await promise; assert.equal(finished, true);
window.assembled.teardown = async () => {throw Error('fixture failure');};
await assert.rejects(clear(), /fixture failure/);
'''
        subprocess.run(['node', '--input-type=module', '-e', test, str(path)], check=True, capture_output=True)


if __name__ == '__main__':
    unittest.main(verbosity=2)
