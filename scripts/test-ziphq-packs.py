#!/usr/bin/env python3
"""Offline executable contract tests. Mock curl only; never use a real tenant."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
PACKS = sorted((ROOT / 'packs/ziphq/api').glob('hth-ziphq-1.0[124]-*.sh'))
SP = '11111111-2222-3333-4444-555555555555'
TOKEN = 'TEST_SECRET_DO_NOT_PRINT'
BASE = 'https://graph.microsoft.com/v1.0/servicePrincipals/' + SP
GOOD_SP = dict(id=SP, appId=SP, accountEnabled=True,
               preferredSingleSignOnMode='saml', appRoleAssignmentRequired=True)
MOCK = r'''#!/usr/bin/env python3
import json, os, pathlib, sys
args = sys.argv[1:]
config = sys.stdin.read()
assert args[0] == '-q'
assert args[args.index('--request')+1] == 'GET'
for flag, value in [('--proto','=https'),('--tlsv1.2',None),('--max-redirs','0'),
                    ('--connect-timeout','10'),('--max-time','60'),
                    ('--max-filesize','10485760'),('--config','-'),('--fail',None)]:
    assert flag in args
    if value is not None: assert args[args.index(flag)+1] == value
assert not any(x in args for x in ['-L','--location','-k','--insecure','--data','--data-raw'])
assert 'GRAPH_ACCESS_TOKEN' not in os.environ
assert 'TEST_SECRET_DO_NOT_PRINT' not in ' '.join(args)
assert config == 'header = "Authorization: Bearer TEST_SECRET_DO_NOT_PRINT"\nheader = "Accept: application/json"\n'
p = pathlib.Path(os.environ['MOCK_STATE'])
n = int(p.read_text()) if p.exists() else 0
p.write_text(str(n+1))
fixtures = json.loads(pathlib.Path(os.environ['MOCK_FIXTURES']).read_text())
assert n < len(fixtures), 'Unexpected extra request'
f = fixtures[n]
if 'url' in f: assert args[args.index('--url')+1] == f['url']
if f.get('rc'): sys.exit(f['rc'])
sys.stdout.write(f.get('raw', json.dumps(f.get('body')))+'\n'+str(f.get('status',200)))
'''


class Collectors(unittest.TestCase):
    def run_pack(self, pack, pages, *, token=TOKEN, sp=SP, ok=True, calls=None, trace=False):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)
            (path/'curl').write_text(MOCK)
            (path/'curl').chmod(0o700)
            (path/'fixtures').write_text(json.dumps(pages))
            env = dict(os.environ, PATH=tmp+os.pathsep+os.environ['PATH'],
                       GRAPH_ACCESS_TOKEN=token, ZIP_ENTRA_SERVICE_PRINCIPAL_ID=sp,
                       MOCK_STATE=str(path/'state'), MOCK_FIXTURES=str(path/'fixtures'))
            result = subprocess.run(['bash']+(['-x'] if trace else [])+[str(pack)],
                                    env=env, capture_output=True, text=True, timeout=30)
            self.assertEqual(result.returncode == 0, ok, result.stderr)
            self.assertNotIn(TOKEN, result.stdout+result.stderr)
            self.assertNotIn(SP, result.stdout+result.stderr)
            if calls is not None:
                actual = int((path/'state').read_text()) if (path/'state').exists() else 0
                self.assertEqual(actual, calls, result.stderr)
            if ok:
                data = json.loads(result.stdout)
                self.assertEqual(data['result'], 'review-required')
                return data
            self.assertEqual(result.stdout, '')

    def test_service_principal(self):
        out = self.run_pack(PACKS[0], [{'body': GOOD_SP}], calls=1, trace=True)
        self.assertTrue(out['assignmentRequired'])
        self.assertTrue(out['samlSelected'])
        for field, value in [('accountEnabled',False), ('preferredSingleSignOnMode',None),
                             ('appRoleAssignmentRequired',False)]:
            self.run_pack(PACKS[0], [{'body':dict(GOOD_SP, **{field:value})}])
        for key in GOOD_SP:
            body = dict(GOOD_SP); del body[key]
            self.run_pack(PACKS[0], [{'body':body}], ok=False)
        for change in [dict(id='wrong'), dict(appId='wrong'), dict(accountEnabled=1),
                       dict(appRoleAssignmentRequired='true'), dict(preferredSingleSignOnMode=[] )]:
            self.run_pack(PACKS[0], [{'body':dict(GOOD_SP, **change)}], ok=False)

    def test_invalid_input_before_network(self):
        for pack in PACKS:
            for token in ['', 'bad\nheader', 'bad"', 'bad\\', 'bad token']:
                self.run_pack(pack, [], token=token, ok=False, calls=0)
            for sp in ['', '../../users', SP+'/other', SP+'?x=1']:
                self.run_pack(pack, [], sp=sp, ok=False, calls=0)

    def test_http_transport_and_json_errors(self):
        for pack in PACKS:
            for status in [301,302,401,403,429,500,204]:
                self.run_pack(pack, [{'status':status,'body':GOOD_SP}], ok=False, calls=1)
            for rc in [22,28,60,63]:
                self.run_pack(pack, [{'rc':rc}], ok=False, calls=1)
            for body in [None, [], {}, {'error':{'message':TOKEN}}]:
                self.run_pack(pack, [{'body':body}], ok=False, calls=1)
            for raw in ['', '<html>private</html>', '{']:
                self.run_pack(pack, [{'raw':raw}], ok=False)

    def test_empty_and_malformed_collections(self):
        for pack in PACKS[1:]:
            self.assertEqual(self.run_pack(pack,[{'body':{'value':[]}}])['uniqueRecords'],0)
            for body in [{'value':None},{'value':{}},{'value':[None]}, {'value':[{}]},
                         {'value':[],'@odata.nextLink':''}, {'value':[],'@odata.nextLink':3}]:
                self.run_pack(pack,[{'body':body}],ok=False)
        for item in [{'id':'a','principalType':'Unknown'},{'id':'a'},
                     {'id':'a','principalType':None}]:
            self.run_pack(PACKS[1],[{'body':{'value':[item]}}],ok=False)
        for status in [None, 'Active', {}, {'code':'Active'}, {'code':'Active','countSuccessiveCompleteFailures':True}]:
            self.run_pack(PACKS[2],[{'body':{'value':[{'id':'a','status':status}]}}],ok=False)

    def test_pagination_counts_and_deduplication(self):
        assignment = {'id':'private-user-id','principalType':'User','principalDisplayName':'PRIVATE'}
        job = {'id':'private-job-id','status':{'code':'Paused','countSuccessiveCompleteFailures':2}}
        for pack, suffix, item in [(PACKS[1],'/appRoleAssignedTo',assignment),
                                  (PACKS[2],'/synchronization/jobs/',job)]:
            next_url = BASE+suffix+'?$skiptoken=abc%2Bdef'
            pages = [{'body':{'value':[item],'@odata.nextLink':next_url}},
                     {'body':{'value':[item]},'url':next_url}]
            out=self.run_pack(pack,pages,calls=2)
            self.assertEqual(out['uniqueRecords'],1)
            self.assertNotIn('private',json.dumps(out))
            if pack==PACKS[1]: self.assertEqual(out['countsByPrincipalType'],dict(User=1,Group=0,ServicePrincipal=0))
            else: self.assertEqual(out['countsByStatus'],{'Paused:failures-present':1})
        values=[{'id':str(i),'principalType':kind} for i,kind in enumerate(['User','User','Group','ServicePrincipal'])]
        out=self.run_pack(PACKS[1],[{'body':{'value':values}}])
        self.assertEqual(out['countsByPrincipalType'],dict(User=2,Group=1,ServicePrincipal=1))
        duplicate=[dict(id='same',principalType='User'),dict(id='same',principalType='Group')]
        self.run_pack(PACKS[1],[{'body':{'value':duplicate}}],ok=False)

    def test_nextlink_boundaries(self):
        for pack, suffix in [(PACKS[1],'/appRoleAssignedTo'),(PACKS[2],'/synchronization/jobs/')]:
            valid=BASE+suffix
            attacks=[valid, valid+'#fragment',valid+'/extra', valid.replace('https:','http:'),
                     valid.replace('graph.microsoft.com','graph.microsoft.com.evil.test'),
                     valid.replace('graph.microsoft.com','graph.microsoft.com@evil.test'),
                     valid.replace('graph.microsoft.com','evil.test@graph.microsoft.com'),
                     valid.replace('graph.microsoft.com','graph.microsoft.com:444'),
                     valid.replace('graph.microsoft.com','graph.microsoft.com.'),
                     valid.replace('/v1.0/','/v1.0/../'),valid.replace('/v1.0/','/%761.0/'),
                     valid+'\n',valid+'\\evil', '/relative',BASE+'/other']
            for attack in attacks:
                self.run_pack(pack,[{'body':{'value':[],'@odata.nextLink':attack}}],ok=False,calls=1)
            repeated=valid+'?page=2'
            self.run_pack(pack,[{'body':{'value':[],'@odata.nextLink':repeated}}]*2,ok=False,calls=2)
            pages=[{'body':{'value':[],'@odata.nextLink':valid+'?page='+str(i)}} for i in range(100)]
            self.run_pack(pack,pages,ok=False,calls=100)


if __name__ == '__main__':
    assert len(PACKS)==3
    unittest.main(verbosity=2)
