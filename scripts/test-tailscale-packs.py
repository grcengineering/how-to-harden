#!/usr/bin/env python3
"""Offline pack boundary tests. Fake curl/tailscale never contact a tailnet."""
import datetime as dt
import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
PACKS = ROOT / 'packs/tailscale'
TOKEN = 'HTH_SYNTHETIC_ACCESS_TOKEN_ONLY'
PRIVATE = 'HTH_SYNTHETIC_PRIVATE_RESPONSE'
FILES = {
    'users':'api/hth-tailscale-1.02-inventory-users.sh',
    'settings':'api/hth-tailscale-1.03-read-enrollment-settings.sh',
    'devices':'api/hth-tailscale-1.04-inventory-device-keys.sh',
    'snapshot':'api/hth-tailscale-2.01-snapshot-policy.sh',
    'validate':'api/hth-tailscale-2.02-validate-candidate-policy.sh',
    'trust':'api/hth-tailscale-3.01-review-trust-credentials.sh',
    'auth':'api/hth-tailscale-3.02-inventory-auth-key-capabilities.sh',
    'routes':'api/hth-tailscale-3.03-inventory-route-approvals.sh',
    'external':'api/hth-tailscale-4.01-inventory-external-devices.sh',
    'audit':'api/hth-tailscale-5.01-collect-configuration-audit.sh',
    'streams':'api/hth-tailscale-5.02-read-log-stream-status.sh',
    'policy':'config/hth-tailscale-2.01-build-grants-policy.sh',
    'lock':'cli/hth-tailscale-1.05-inspect-tailnet-lock.sh',
    'funnel':'cli/hth-tailscale-4.02-inspect-funnel.sh',
    'version':'cli/hth-tailscale-4.03-inventory-client-version.sh',
}

FAKE_CURL = r'''#!/usr/bin/env python3
import json, os, pathlib, sys
args = sys.argv[1:]
assert args[0] == '-q'
assert '--location' not in args and '-L' not in args
assert args[args.index('--proto')+1] == '=https'
assert '--tlsv1.2' in args and '--max-filesize' in args and '--max-time' in args
assert os.environ['TAILSCALE_ACCESS_TOKEN'] not in ' '.join(args)
assert sys.stdin.read() == 'header = "Authorization: Bearer '+os.environ['TAILSCALE_ACCESS_TOKEN']+'"\n'
state = pathlib.Path(os.environ['HTH_TEST_STATE'])
position = int(state.read_text()) if state.exists() else 0
responses = json.loads(pathlib.Path(os.environ['HTH_TEST_RESPONSES']).read_text())
assert position < len(responses), 'unexpected extra request'
reply = responses[position]
assert args[-1] == 'https://api.tailscale.com'+reply['path'], args[-1]
assert args[args.index('--request')+1] == reply.get('method','GET')
state.write_text(str(position+1))
if reply.get('method') == 'POST':
    assert args[-1].endswith('/acl/validate'), 'policy apply forbidden'
    body = args[args.index('--data-binary')+1]
    assert body.startswith('@')
    assert pathlib.Path(body[1:]).read_text() == os.environ['HTH_TEST_CANDIDATE']
if reply.get('transport_error'):
    print(os.environ['TAILSCALE_ACCESS_TOKEN'], file=sys.stderr)
    print('HTH_SYNTHETIC_PRIVATE_RESPONSE', file=sys.stderr)
    sys.exit(7)
pathlib.Path(args[args.index('--dump-header')+1]).write_text(reply.get('headers','HTTP/2 200\r\nETag: "revision-1"\r\n\r\n'))
pathlib.Path(args[args.index('--output')+1]).write_text(reply.get('raw',json.dumps(reply.get('body',{}))))
print(reply.get('status',200),end='')
'''

FAKE_CLI = r'''#!/usr/bin/env python3
import json, os, pathlib, sys
args = sys.argv[1:]
assert args in [['lock','status'],['funnel','status','--json'],['version','--json']]
with pathlib.Path(os.environ['HTH_TEST_CLI_CALLS']).open('a') as f:
    f.write(json.dumps(args)+'\n')
if os.environ.get('HTH_TEST_CLI_ERROR'):
    print('HTH_SYNTHETIC_PRIVATE_RESPONSE',file=sys.stderr)
    print(os.environ.get('TAILSCALE_ACCESS_TOKEN',''),file=sys.stderr)
    sys.exit(1)
print(os.environ.get('HTH_TEST_CLI_BODY','{}'))
'''

def response(path, body=None, **kw):
    return dict(path=path, body=body, **kw)

def device(**kw):
    return dict(id='123', nodeId='node123', authorized=True, expires='2026-12-01T00:00:00Z',
                keyExpiryDisabled=False, isExternal=False, tags=[], **kw)

class TailscalePacks(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='hth-tailscale-test-')
        self.dir = Path(self.tmp.name)
        self.output = self.dir/'evidence.json'
        self.state = self.dir/'state'
        self.candidate = '{\n  // preserve HuJSON\n  "acls": [],\n}\n'
        self.env = {k:v for k,v in os.environ.items() if not k.startswith(('TAILSCALE_','HTH_'))}
        for name, content in [('curl',FAKE_CURL),('tailscale',FAKE_CLI)]:
            path = self.dir/name
            path.write_text(content)
            path.chmod(0o700)
        (self.dir/'candidate.hujson').write_text(self.candidate)
        (self.dir/'ids.json').write_text('["k123"]')
        (self.dir/'approved.json').write_text('{"admins":["admin@example.com"],"staff":["staff@example.com"]}')
        now = dt.datetime.now(dt.timezone.utc).replace(microsecond=0)
        self.env.update({
            'PATH':str(self.dir)+':'+os.environ['PATH'], 'TMPDIR':str(self.dir),
            'TAILSCALE_ACCESS_TOKEN':TOKEN, 'TAILSCALE_TAILNET':'example.com',
            'TAILSCALE_OUTPUT':str(self.output), 'HTH_PROFILE_LEVEL':'3',
            'TAILSCALE_POLICY_INPUT':str(self.dir/'approved.json'),
            'TAILSCALE_POLICY_FILE':str(self.dir/'candidate.hujson'),
            'TAILSCALE_KEY_IDS_FILE':str(self.dir/'ids.json'),
            'TAILSCALE_LOG_START':(now-dt.timedelta(hours=2)).strftime('%Y-%m-%dT%H:%M:%SZ'),
            'TAILSCALE_LOG_END':(now-dt.timedelta(hours=1)).strftime('%Y-%m-%dT%H:%M:%SZ'),
            'HTH_TEST_STATE':str(self.state), 'HTH_TEST_RESPONSES':str(self.dir/'responses.json'),
            'HTH_TEST_CLI_CALLS':str(self.dir/'cli.jsonl'), 'HTH_TEST_CANDIDATE':self.candidate,
        })

    def tearDown(self):
        self.tmp.cleanup()

    def run_pack(self, name, replies=(), expected=0, **env):
        (self.dir/'responses.json').write_text(json.dumps(replies))
        result = subprocess.run(['bash',str(PACKS/FILES[name])], env=dict(self.env,**env),
                                text=True, capture_output=True, timeout=15)
        self.assertEqual(result.returncode,expected,result.stdout+result.stderr)
        self.assertNotIn(TOKEN,result.stdout+result.stderr)
        self.assertNotIn(PRIVATE,result.stdout+result.stderr)
        self.assertEqual(list(self.dir.glob('hth-tailscale.*')),[],'temporary evidence leaked')
        if expected == 0:
            self.assertTrue(self.output.is_file())
            self.assertEqual(stat.S_IMODE(self.output.stat().st_mode),0o600)
        else:
            self.assertFalse(self.output.exists())
        return result

    def read(self):
        return json.loads(self.output.read_text())

    def test_user_inventory(self):
        self.run_pack('users',[response('/api/v2/tailnet/example.com/users',{'users':[{'id':'u1','role':'member','status':'active'}]})])
        self.assertEqual(self.read()['users'][0]['id'],'u1')

    def test_invalid_user_envelopes(self):
        for body in ({}, {'users':None}, {'users':[{'id':'u'}]}, {'users':[], 'pagination':{}},
                     {'users':[{'id':'u','role':'member','status':'active'}]*2}):
            with self.subTest(body=body):
                self.state.unlink(missing_ok=True)
                self.run_pack('users',[response('/api/v2/tailnet/example.com/users',body)],expected=2)

    def test_empty_inventory_is_collected_not_compliant(self):
        r=self.run_pack('users',[response('/api/v2/tailnet/example.com/users',{'users':[]})])
        self.assertIn('COLLECTED',r.stdout)
        self.assertNotIn('PASS',r.stdout)

    def test_settings(self):
        self.run_pack('settings',[response('/api/v2/tailnet/example.com/settings',{
            'devicesApprovalOn':True,'devicesKeyDurationDays':30,'devicesAutoUpdatesOn':True})])

    def test_missing_settings_unknown(self):
        self.run_pack('settings',[response('/api/v2/tailnet/example.com/settings',{})],expected=2)

    def test_device_inventory(self):
        self.run_pack('devices',[response('/api/v2/tailnet/example.com/devices?fields=all',{'devices':[device()]})])

    def test_device_expiry_missing_unknown(self):
        d=device(); del d['keyExpiryDisabled']
        self.run_pack('devices',[response('/api/v2/tailnet/example.com/devices?fields=all',{'devices':[d]})],expected=2)

    def test_snapshot_preserves_hujson_and_etag(self):
        self.run_pack('snapshot',[response('/api/v2/tailnet/example.com/acl',raw=self.candidate)])
        self.assertEqual(self.read(),{'etag':'"revision-1"','hujson':self.candidate})

    def test_snapshot_requires_etag(self):
        self.run_pack('snapshot',[response('/api/v2/tailnet/example.com/acl',raw=self.candidate,headers='HTTP/2 200\r\n\r\n')],expected=2)

    def test_validation_uses_only_nonmutating_endpoint(self):
        r=self.run_pack('validate',[response('/api/v2/tailnet/example.com/acl/validate',method='POST',raw='')])
        self.assertEqual(self.read(),{'candidateValidated':True,'applied':False})
        self.assertIn('VALIDATED-CANDIDATE',r.stdout)

    def test_nonempty_http_200_is_not_validation_pass(self):
        for raw in ('{"message":"failed tests"}', '{}', '[]', ' '):
            with self.subTest(raw=raw):
                self.state.unlink(missing_ok=True)
                self.run_pack('validate',[response('/api/v2/tailnet/example.com/acl/validate',method='POST',raw=raw)],expected=2)

    def test_empty_candidate_no_request(self):
        (self.dir/'candidate.hujson').write_text('')
        self.run_pack('validate',expected=2)
        self.assertFalse(self.state.exists())

    def test_http_and_transport_errors_are_private(self):
        for kw in ({'status':401,'raw':PRIVATE}, {'status':302,'raw':PRIVATE}, {'status':429,'raw':PRIVATE}, {'transport_error':True}):
            with self.subTest(kw=kw):
                self.state.unlink(missing_ok=True)
                self.run_pack('users',[response('/api/v2/tailnet/example.com/users',**kw)],expected=2)

    def test_malformed_api_json(self):
        self.run_pack('users',[response('/api/v2/tailnet/example.com/users',raw='not JSON')],expected=2)

    def test_schema_errors_do_not_echo_private_values(self):
        for name,field,path in [
            ('users','users','/api/v2/tailnet/example.com/users'),
            ('devices','devices','/api/v2/tailnet/example.com/devices?fields=all'),
            ('auth','keys','/api/v2/tailnet/example.com/keys'),
            ('routes','devices','/api/v2/tailnet/example.com/devices?fields=all'),
            ('external','devices','/api/v2/tailnet/example.com/devices?fields=all'),
        ]:
            with self.subTest(name=name):
                self.state.unlink(missing_ok=True)
                self.run_pack(name,[response(path,{field:PRIVATE})],expected=2)

    def test_credential_and_origin_validation_before_network(self):
        for env in ({'TAILSCALE_ACCESS_TOKEN':''},{'TAILSCALE_ACCESS_TOKEN':'token\nheader = injected'},
                    {'TAILSCALE_TAILNET':'../other'},{'TAILSCALE_TAILNET':''},
                    {'TAILSCALE_BASE_URL':'https://example.invalid'}):
            with self.subTest(env=env):
                self.run_pack('users',expected=2,**env)
                self.assertFalse(self.state.exists())

    def test_profile_gates_before_cli_or_api(self):
        for name,level in [('users','0'),('users','99'),('routes','1'),('streams','1'),('lock','2')]:
            with self.subTest(name=name,level=level):
                self.run_pack(name,expected=2,HTH_PROFILE_LEVEL=level)
                self.assertFalse(self.state.exists())
                self.assertFalse((self.dir/'cli.jsonl').exists())

    def test_existing_output_and_symlink_refused_before_requests(self):
        target=self.dir/'keep'
        target.write_text('keep')
        for symlink in (False,True):
            if symlink: self.output.symlink_to(target)
            else: self.output.write_text('keep')
            result=subprocess.run(['bash',str(PACKS/FILES['users'])],env=self.env,capture_output=True,text=True)
            self.assertEqual(result.returncode,2)
            self.assertEqual(self.output.read_text(),'keep')
            self.assertEqual(target.read_text(),'keep')
            self.assertFalse(self.state.exists())
            self.output.unlink()

    def test_known_trust_credentials_project_out_secrets(self):
        self.run_pack('trust',[response('/api/v2/tailnet/example.com/keys/k123',{
            'id':'k123','scopes':['devices:core:read'],'key':PRIVATE,'keyType':'client'})])
        self.assertNotIn(PRIVATE,self.output.read_text())
        self.assertIn('known IDs',self.read()['coverage'])

    def test_trust_id_injection_no_request(self):
        (self.dir/'ids.json').write_text('["../escape"]')
        self.run_pack('trust',expected=2)
        self.assertFalse(self.state.exists())

    def test_key_inventory_fetches_metadata(self):
        self.run_pack('auth',[
            response('/api/v2/tailnet/example.com/keys',{'keys':[{'id':'k123'}]}),
            response('/api/v2/tailnet/example.com/keys/k123',{'id':'k123','key':PRIVATE,'capabilities':{'devices':{'create':{'reusable':False,'ephemeral':True,'preauthorized':False,'tags':['tag:ci']}}}}),
        ])
        self.assertEqual(self.state.read_text(),'2')
        self.assertNotIn(PRIVATE,self.output.read_text())
        self.assertIn('credential-visible',self.read()['coverage'])

    def test_later_key_read_failure_discards_collection(self):
        self.run_pack('auth',[response('/api/v2/tailnet/example.com/keys',{'keys':[{'id':'k123'}]}),
                              response('/api/v2/tailnet/example.com/keys/k123',status=403,raw=PRIVATE)],expected=2)

    def test_route_inventory_uses_stable_node_id(self):
        self.run_pack('routes',[response('/api/v2/tailnet/example.com/devices?fields=all',{'devices':[device()]}),
            response('/api/v2/device/node123/routes',{'advertisedRoutes':['10.0.0.0/24'],'enabledRoutes':[]})])
        self.assertEqual(self.read()['routes'][0]['deviceId'],'node123')

    def test_route_later_failure_is_not_partial_evidence(self):
        self.run_pack('routes',[response('/api/v2/tailnet/example.com/devices?fields=all',{'devices':[device()]}),
            response('/api/v2/device/node123/routes',status=500,raw=PRIVATE)],expected=2)

    def test_external_inventory_does_not_claim_outbound_coverage(self):
        d=device(); d['isExternal']=True
        self.run_pack('external',[response('/api/v2/tailnet/example.com/devices?fields=all',{'devices':[d]})])
        self.assertIn('outbound',self.read()['coverage'])
        self.assertEqual(len(self.read()['externalDevices']),1)

    def test_missing_external_flag_is_unknown(self):
        self.run_pack('external',[response('/api/v2/tailnet/example.com/devices?fields=all',{'devices':[{'id':'123'}]})],expected=2)

    def test_audit_window_and_schema(self):
        from urllib.parse import urlencode
        query=urlencode({'start':self.env['TAILSCALE_LOG_START'],'end':self.env['TAILSCALE_LOG_END']})
        self.run_pack('audit',[response('/api/v2/tailnet/example.com/logging/configuration?'+query,
                                      {'logs':[],'version':'1.1'})])

    def test_invalid_windows_do_not_request(self):
        for value in ('2020-01-01T00:00:00Z','9999-01-01T00:00:00Z','2026-01-01','injected&param=1'):
            with self.subTest(value=value):
                self.run_pack('audit',expected=2,TAILSCALE_LOG_START=value)
                self.assertFalse(self.state.exists())

    def test_streams_both_reads_required(self):
        self.run_pack('streams',[response('/api/v2/tailnet/example.com/logging/configuration/status',{'status':'fixture'}),
                                 response('/api/v2/tailnet/example.com/logging/network/status',{'status':'fixture'})])
        self.assertEqual(set(self.read()),{'configuration','network'})

    def test_second_stream_failure_no_partial_output(self):
        self.run_pack('streams',[response('/api/v2/tailnet/example.com/logging/configuration/status',{}),
                                 response('/api/v2/tailnet/example.com/logging/network/status',status=404)],expected=2)

    def test_cli_reads_only(self):
        for name,args in [('lock',['lock','status']),('funnel',['funnel','status','--json']),('version',['version','--json'])]:
            with self.subTest(name=name):
                self.output.unlink(missing_ok=True)
                self.run_pack(name)
                self.assertEqual(json.loads((self.dir/'cli.jsonl').read_text().splitlines()[-1]),args)

    def test_cli_errors_private_and_invalid_json_unknown(self):
        self.run_pack('funnel',expected=2,HTH_TEST_CLI_ERROR='1')
        self.run_pack('version',expected=2,HTH_TEST_CLI_BODY='invalid JSON')

    def test_policy_generator_narrow_defaults_and_negative_tests(self):
        self.run_pack('policy')
        p=self.read()
        self.assertEqual(p['acls'],[])
        self.assertEqual(p['ssh'],[])
        self.assertNotIn('nodeAttrs',p)
        self.assertNotIn('autoApprovers',p)
        self.assertTrue(all('*' not in g['ip']+g['src']+g['dst'] for g in p['grants']))
        self.assertTrue(all(test.get('deny') for test in p['tests']))

    def test_policy_generator_rejects_conflicting_or_injected_identities(self):
        values = [[],{}, {'admins':[],'staff':['s@example.com']},
                  {'admins':['a@example.com'],'staff':['a@example.com']},
                  {'admins':['a@example.com'],'staff':['x@example.com','x@example.com']},
                  {'admins':['Admin@example.com'],'staff':['s@example.com']},
                  {'admins':['a@example.com\nfoo'],'staff':['s@example.com']},
                  {'admins':['a@example.com'],'staff':['s@example.com'],'extra':True}]
        for value in values:
            with self.subTest(value=value):
                (self.dir/'approved.json').write_text(json.dumps(value))
                self.run_pack('policy',expected=2)
        (self.dir/'approved.json').write_text('{"admins":["a@example.com"],"admins":["b@example.com"],"staff":["s@example.com"]}')
        self.run_pack('policy',expected=2)

    def test_native_fragments_parse_and_preserve_security_conditions(self):
        fragments={}
        for path in (PACKS/'config').glob('*.jsonc'):
            value=json.loads('\n'.join(line for line in path.read_text().splitlines() if not line.lstrip().startswith('//')))
            fragments[path.name]=value
        ssh=next(v for k,v in fragments.items() if '-2.04-' in k)
        self.assertEqual(ssh['ssh'][0]['users'],['ops'])
        self.assertEqual(ssh['ssh'][0]['action'],'check')
        posture=next(v for k,v in fragments.items() if '-2.05-' in k)
        self.assertIn('assertions',posture['postures']['posture:stableAutoUpdate'])
        self.assertTrue(posture['grants'][0]['srcPosture'])

    def test_apply_endpoint_is_blocked_by_transport(self):
        (self.dir/'responses.json').write_text('[]')
        command='source "$1"; hth_api_init 1; hth_request POST "/api/v2/tailnet/${HTH_TAILNET}/acl" "$HTH_TEMP/reply"'
        result=subprocess.run(['bash','-c',command,'test',str(PACKS/'api/common.sh')],env=self.env,text=True,capture_output=True)
        self.assertEqual(result.returncode,2)
        self.assertFalse(self.state.exists())

if __name__ == '__main__':
    unittest.main(verbosity=2)
