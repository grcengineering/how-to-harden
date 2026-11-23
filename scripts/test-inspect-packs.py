#!/usr/bin/env python3
"""Offline contract/safety tests. No network or Inspect credentials used."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
PACKS = ROOT / 'packs/inspect/api'
META = {'has_next_page': False, 'next_cursor': None}
AGENT = {'data': {'id': 'agent1', 'name': 'Test', 'builtin': False,
                  'repositories': None, 'skills': [], 'capabilities': None,
                  'prompt_context_mode': 'append', 'prompt': 'private prompt'}}
AUTO = {'data': {'id': 'auto1', 'name': 'Test', 'enabled': True,
                 'viewer_can_edit': True, 'triggers': [{'type': 'cron'}],
                 'repositories': ['web'], 'updated_at': '2026-11-17T00:00:00Z',
                 'prompt': 'private prompt', 'run_as': 'owner', 'agent_id': None,
                 'autofix_ci_failures': False, 'auto_address_pull_request_reviews_policy': None}}
MOCK = r'''#!/usr/bin/env python3
import json,os,sys
from pathlib import Path
args=sys.argv[1:]
assert args[0]=='-q'
assert 'INSPECT_API_KEY' not in os.environ
assert '--location' not in args and '--retry' not in args
assert all('test-secret' not in a for a in args)
config=sys.stdin.read()
assert config=='header = "Authorization: Bearer test-secret"\n'
assert args[-1].startswith('https://app.inspect.com/api/v2/')
state=Path(os.environ['MOCK_DIR'])
counter=state/'count'
i=int(counter.read_text()) if counter.exists() else 0
rows=json.loads((state/'responses.json').read_text())
if i>=len(rows): sys.exit('unexpected request')
r=rows[i]; counter.write_text(str(i+1))
if 'rewrite_input' in r:
 Path(os.environ['HTH_REPOSITORIES_FILE']).write_text(json.dumps(r['rewrite_input']))
record={'url':args[-1],'method':args[args.index('--request')+1]}
if '--data-binary' in args:
 record['body']=json.loads(Path(args[args.index('--data-binary')+1][1:]).read_text())
with (state/'requests.jsonl').open('a') as f: f.write(json.dumps(record)+'\n')
Path(args[args.index('--output')+1]).write_text(r.get('raw',json.dumps(r.get('body',{}))))
print(r.get('status',200),end='')
'''

class Packs(unittest.TestCase):
    def run_pack(self, num, responses, extra=None):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        d = Path(temp.name)
        (d / 'curl').write_text(MOCK)
        (d / 'curl').chmod(0o755)
        (d / 'responses.json').write_text(json.dumps(responses))
        (d / 'repos.json').write_text('["web"]')
        env = dict(os.environ, PATH=f'{d}:'+os.environ['PATH'], MOCK_DIR=str(d),
                   INSPECT_API_KEY='test-secret', INSPECT_AGENT_ID='agent1',
                   INSPECT_AUTOMATION_ID='auto1', INSPECT_SESSION_ID='session1', INSPECT_REPOSITORY_ID='web',
                   INSPECT_PULL_REQUEST_NUMBER='123', INSPECT_EXPECTED_HEAD_SHA='a'*40, HTH_OUTPUT_FILE=str(d/'output.json'),
                   HTH_REPOSITORIES_FILE=str(d/'repos.json'), TMPDIR=str(d))
        for key in ('INSPECT_API_BASE','HTH_APPLY','HTH_CONFIRM_ID','HTH_MAX_PAGES'):
            env.pop(key, None)
        if extra: env.update(extra)
        p = subprocess.run(['bash', str(next(PACKS.glob(f'hth-inspect-{num}-*.sh')))],
                           env=env, capture_output=True, text=True)
        requests = [json.loads(s) for s in (d/'requests.jsonl').read_text().splitlines()] if (d/'requests.jsonl').exists() else []
        return p, requests, d

    def test_repositories(self):
        p,r,d=self.run_pack('2.01',[{'body':{'data':[{'id':'web','name':'web','organization':'acme','auto_match_enabled':False,'automatic_reviews':'off'}],'meta':META}}])
        self.assertEqual(p.returncode,0,p.stderr)
        self.assertEqual(len(r),1)
        self.assertEqual((d/'output.json').stat().st_mode & 0o777,0o600)

    def test_undocumented_repository_paging_fails(self):
        p,_,d=self.run_pack('2.01',[{'body':{'data':[],'meta':{'has_next_page':True,'next_cursor':'x'}}}])
        self.assertNotEqual(p.returncode,0)
        self.assertFalse((d/'output.json').exists())

    def test_agent_audit_redacts_prompt(self):
        p,_,d=self.run_pack('2.02',[{'body':AGENT}])
        self.assertEqual(p.returncode,0,p.stderr)
        self.assertNotIn('private prompt',(d/'output.json').read_text())
        self.assertTrue(json.loads((d/'output.json').read_text())['unrestricted_repositories'])

    def test_agent_missing_fields_fail(self):
        p,_,_=self.run_pack('2.02',[{'body':{'data':{'id':'agent1'}}}])
        self.assertNotEqual(p.returncode,0)

    def test_wrong_id_fails(self):
        p,r,_=self.run_pack('2.02',[],{'INSPECT_AGENT_ID':'../other'})
        self.assertNotEqual(p.returncode,0); self.assertFalse(r)

    def test_origin_override_fails(self):
        p,r,_=self.run_pack('2.02',[],{'INSPECT_API_BASE':'https://evil.invalid'})
        self.assertNotEqual(p.returncode,0); self.assertFalse(r)

    def test_token_header_injection_fails(self):
        p,r,_=self.run_pack('2.02',[],{'INSPECT_API_KEY':'abc\nheader = evil'})
        self.assertNotEqual(p.returncode,0); self.assertFalse(r)

    def test_redirect_fails_without_body_leak(self):
        p,_,_=self.run_pack('2.02',[{'status':302,'raw':'private prompt'}])
        self.assertNotEqual(p.returncode,0); self.assertNotIn('private prompt',p.stdout+p.stderr)

    def test_multiple_json_fails(self):
        p,_,_=self.run_pack('2.02',[{'raw':json.dumps(AGENT)+'\n'+json.dumps(AGENT)}])
        self.assertNotEqual(p.returncode,0)

    def test_agent_preview_no_write(self):
        p,r,_=self.run_pack('2.06',[{'body':AGENT}])
        self.assertEqual(p.returncode,0,p.stderr); self.assertEqual([x['method'] for x in r],['GET'])

    def test_apply_confirmation_required(self):
        p,r,_=self.run_pack('2.06',[],{'HTH_APPLY':'1'})
        self.assertNotEqual(p.returncode,0); self.assertFalse(r)

    def test_allowlist_cannot_broaden(self):
        a=json.loads(json.dumps(AGENT)); a['data']['repositories']=['other']
        p,r,_=self.run_pack('2.06',[{'body':a}],{'HTH_APPLY':'1','HTH_CONFIRM_ID':'agent1'})
        self.assertNotEqual(p.returncode,0); self.assertEqual(len(r),1)

    def test_agent_write_minimal_and_verified(self):
        a=json.loads(json.dumps(AGENT)); a['data']['repositories']=['web']
        p,r,d=self.run_pack('2.06',[{'body':x} for x in (AGENT,AGENT,a,a)],{'HTH_APPLY':'1','HTH_CONFIRM_ID':'agent1'})
        self.assertEqual(p.returncode,0,p.stderr)
        self.assertEqual(r[2]['method'],'PATCH'); self.assertEqual(r[2]['body'],{'repositories':['web']})
        self.assertTrue(list(d.glob('hth-inspect-change.*/before.json')))

    def test_concurrent_agent_change_stops_write(self):
        a=json.loads(json.dumps(AGENT)); a['data']['name']='Changed'
        p,r,_=self.run_pack('2.06',[{'body':AGENT},{'body':a}],{'HTH_APPLY':'1','HTH_CONFIRM_ID':'agent1'})
        self.assertNotEqual(p.returncode,0); self.assertEqual([x['method'] for x in r],['GET','GET'])

    def test_readback_mismatch_fails(self):
        p,_,_=self.run_pack('2.06',[{'body':AGENT}]*4,{'HTH_APPLY':'1','HTH_CONFIRM_ID':'agent1'})
        self.assertNotEqual(p.returncode,0)

    def test_automation_pagination_and_redaction(self):
        first={'data':[], 'meta':{'has_next_page':True,'next_cursor':'x+/='}}
        second={'data':[AUTO['data']], 'meta':META}
        p,r,d=self.run_pack('4.03',[{'body':first},{'body':second}])
        self.assertEqual(p.returncode,0,p.stderr)
        self.assertIn('after=x%2B%2F%3D',r[1]['url'])
        self.assertNotIn('private prompt',(d/'output.json').read_text())

    def test_repeated_cursor_fails(self):
        page={'data':[],'meta':{'has_next_page':True,'next_cursor':'x'}}
        p,_,d=self.run_pack('4.03',[{'body':page}]*2)
        self.assertNotEqual(p.returncode,0); self.assertFalse((d/'output.json').exists())

    def test_page_limit_fails(self):
        page={'data':[],'meta':{'has_next_page':True,'next_cursor':'x'}}
        p,_,d=self.run_pack('4.03',[{'body':page}],{'HTH_MAX_PAGES':'1'})
        self.assertNotEqual(p.returncode,0); self.assertFalse((d/'output.json').exists())

    def test_manual_automation_not_disabled(self):
        a=json.loads(json.dumps(AUTO)); a['data']['triggers']=[]
        p,r,_=self.run_pack('4.05',[{'body':a}],{'HTH_APPLY':'1','HTH_CONFIRM_ID':'auto1'})
        self.assertNotEqual(p.returncode,0); self.assertEqual(len(r),1)

    def test_noneditable_automation_not_disabled(self):
        a=json.loads(json.dumps(AUTO)); a['data']['viewer_can_edit']=False
        p,r,_=self.run_pack('4.05',[{'body':a}],{'HTH_APPLY':'1','HTH_CONFIRM_ID':'auto1'})
        self.assertNotEqual(p.returncode,0); self.assertEqual(len(r),1)

    def test_automation_preview(self):
        p,r,_=self.run_pack('4.05',[{'body':AUTO}])
        self.assertEqual(p.returncode,0,p.stderr); self.assertEqual(len(r),1)

    def test_automation_disable_verified(self):
        a=json.loads(json.dumps(AUTO)); a['data']['enabled']=False; a['data']['updated_at']='2026-11-17T01:00:00Z'
        p,r,_=self.run_pack('4.05',[{'body':x} for x in (AUTO,AUTO,a,a)],{'HTH_APPLY':'1','HTH_CONFIRM_ID':'auto1'})
        self.assertEqual(p.returncode,0,p.stderr)
        self.assertEqual(r[2]['body'],{'enabled':False})
        self.assertIn('NOT stopped',p.stdout)

    def test_null_and_empty_allowlist_refused(self):
        with tempfile.TemporaryDirectory() as t:
            path=Path(t)/'repositories.json'
            for value in (None, [], ['web','web'], [''], 'web'):
                path.write_text(json.dumps(value))
                p,r,_=self.run_pack('2.06',[],{'HTH_REPOSITORIES_FILE':str(path)})
                self.assertNotEqual(p.returncode,0); self.assertFalse(r)

    def test_nonobject_response_fails(self):
        p,_,_=self.run_pack('2.02',[{'body':[]}])
        self.assertNotEqual(p.returncode,0)

    def test_agent_response_id_mismatch(self):
        a=json.loads(json.dumps(AGENT)); a['data']['id']='other'
        p,_,_=self.run_pack('2.02',[{'body':a}])
        self.assertNotEqual(p.returncode,0)

    def test_missing_cursor_fails(self):
        page={'data':[],'meta':{'has_next_page':True,'next_cursor':None}}
        p,_,d=self.run_pack('4.03',[{'body':page}])
        self.assertNotEqual(p.returncode,0); self.assertFalse((d/'output.json').exists())

    def test_duplicate_inventory_fails(self):
        page={'data':[AUTO['data'],AUTO['data']],'meta':META}
        p,_,d=self.run_pack('4.03',[{'body':page}])
        self.assertNotEqual(p.returncode,0); self.assertFalse((d/'output.json').exists())

    def test_malformed_automation_fails(self):
        a=json.loads(json.dumps(AUTO)); del a['data']['enabled']
        p,_,d=self.run_pack('4.03',[{'body':{'data':[a['data']],'meta':META}}])
        self.assertNotEqual(p.returncode,0); self.assertFalse((d/'output.json').exists())

    def test_existing_output_not_overwritten(self):
        with tempfile.TemporaryDirectory() as t:
            path=Path(t)/'existing.json'; path.write_text('preserve me')
            p,_,_=self.run_pack('2.02',[{'body':AGENT}],{'HTH_OUTPUT_FILE':str(path)})
            self.assertNotEqual(p.returncode,0); self.assertEqual(path.read_text(),'preserve me')

    def test_input_rewrite_cannot_bypass_nonbroadening_gate(self):
        with tempfile.TemporaryDirectory() as t:
            path=Path(t)/'repositories.json'; path.write_text('["other"]')
            a=json.loads(json.dumps(AGENT)); a['data']['repositories']=['web']
            p,r,_=self.run_pack('2.06',[{'body':a,'rewrite_input':['web']}],
                {'HTH_REPOSITORIES_FILE':str(path),'HTH_APPLY':'1','HTH_CONFIRM_ID':'agent1'})
            self.assertNotEqual(p.returncode,0); self.assertEqual(len(r),1)

    def test_input_snapshot_survives_rewrite(self):
        a=json.loads(json.dumps(AGENT)); a['data']['repositories']=['web']
        p,r,_=self.run_pack('2.06',[{'body':AGENT,'rewrite_input':['other']},{'body':AGENT},{'body':a},{'body':a}],
            {'HTH_APPLY':'1','HTH_CONFIRM_ID':'agent1'})
        self.assertEqual(p.returncode,0,p.stderr); self.assertEqual(r[2]['body'],{'repositories':['web']})

    def session(self,sha='a'*40):
        return {'data':{'id':'session1','read_only':False,'deleted_at':None,
            'repositories':[{'id':'web','latest_commit_sha':sha}],
            'pull_requests':[{'repository':'web','pull_request_number':123,'merged_at':None}]}}

    def test_verification_preview_never_starts(self):
        p,r,_=self.run_pack('4.02',[{'body':self.session()}])
        self.assertEqual(p.returncode,0,p.stderr); self.assertEqual(len(r),1)
        self.assertEqual(r[0]['method'],'GET')

    def test_verification_apply_confirmation(self):
        p,r,_=self.run_pack('4.02',[],{'HTH_APPLY':'1','HTH_CONFIRM_ID':'other'})
        self.assertNotEqual(p.returncode,0); self.assertFalse(r)

    def test_verification_started_and_already_running(self):
        for status in ('started','already_running'):
            receipt={'data':{'status':status,'repository':'web','pull_request_number':123}}
            p,r,_=self.run_pack('4.02',[{'body':self.session()},{'body':self.session()},{'status':202,'body':receipt}],
                {'HTH_APPLY':'1','HTH_CONFIRM_ID':'session1'})
            self.assertEqual(p.returncode,0,p.stderr); self.assertEqual(r[2]['method'],'POST')
            self.assertEqual(r[2]['body'],{'repository':'web'})
            self.assertIn('ACCEPTED: '+status,p.stdout); self.assertNotIn('VERIFIED',p.stdout)

    def test_verification_changed_head_no_invocation(self):
        p,r,_=self.run_pack('4.02',[{'body':self.session()},{'body':self.session('b'*40)}],
            {'HTH_APPLY':'1','HTH_CONFIRM_ID':'session1'})
        self.assertNotEqual(p.returncode,0); self.assertEqual(len(r),2)

    def test_verification_wrong_pr_no_invocation(self):
        s=self.session(); s['data']['pull_requests'][0]['pull_request_number']=999
        p,r,_=self.run_pack('4.02',[{'body':s}],{'HTH_APPLY':'1','HTH_CONFIRM_ID':'session1'})
        self.assertNotEqual(p.returncode,0); self.assertEqual(len(r),1)

    def test_verification_conflict_no_retry(self):
        p,r,_=self.run_pack('4.02',[{'body':self.session()},{'body':self.session()},{'status':409,'body':{'error':'verification_not_configured'}}],
            {'HTH_APPLY':'1','HTH_CONFIRM_ID':'session1'})
        self.assertNotEqual(p.returncode,0); self.assertEqual(len(r),3)

    def test_verification_receipt_mismatch_not_success(self):
        receipt={'data':{'status':'started','repository':'other','pull_request_number':123}}
        p,r,_=self.run_pack('4.02',[{'body':self.session()},{'body':self.session()},{'status':202,'body':receipt}],
            {'HTH_APPLY':'1','HTH_CONFIRM_ID':'session1'})
        self.assertNotEqual(p.returncode,0); self.assertEqual(len(r),3); self.assertNotIn('ACCEPTED',p.stdout)

    def test_no_retry_after_http_error(self):
        p,r,_=self.run_pack('4.05',[{'body':AUTO},{'body':AUTO},{'status':500,'raw':'private prompt'}],{'HTH_APPLY':'1','HTH_CONFIRM_ID':'auto1'})
        self.assertNotEqual(p.returncode,0); self.assertEqual(len(r),3)
        self.assertNotIn('private prompt',p.stdout+p.stderr)

if __name__=='__main__': unittest.main()
