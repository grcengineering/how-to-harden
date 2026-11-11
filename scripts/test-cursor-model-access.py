#!/usr/bin/env python3
"""Offline contract/safety tests; fake HTTP transport, not a live tenant validation."""
import copy
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / 'packs/cursor/api/hth-cursor-2.02-audit-model-access.sh'
APPLY = ROOT / 'packs/cursor/api/hth-cursor-2.07-enforce-model-allowlist.sh'
PARAM = [{'id': 'fast', 'allowedValues': ['false'], 'configuredDefaultValue': 'false'}]
CATALOG = {'teamId': 7, 'state': 'custom', 'providers': [
    {'id': 'trusted', 'enabled': False, 'models': [
        {'id': 'approved', 'enabled': False, 'parameters': PARAM},
        {'id': 'unapproved', 'enabled': True, 'parameters': PARAM}]},
    {'id': 'other', 'enabled': True, 'models': [
        {'id': 'blocked', 'enabled': True, 'parameters': PARAM}]}]}
POLICY = {'teamId': 7, 'models': [{'provider': 'trusted', 'id': 'approved'}]}
FAKE = r'''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
from urllib.parse import unquote, urlsplit
args=sys.argv[1:]
def option(name, default=None):
    return args[args.index(name)+1] if name in args else default
root=Path(os.environ['FIXTURE'])
s=json.loads((root/'state.json').read_text())
method=option('--request','GET'); url=args[-1]
body=json.loads(option('--data','null'))
assert url.startswith('https://api.cursor.com/')
assert '--location' not in args and '-L' not in args
assert '--disable' in args and option('--config')=='-'
assert 'test-key' not in ' '.join(args)
assert 'test-key' in sys.stdin.read()
calls=s.setdefault('calls',[]); calls.append({'method':method,'url':url,'body':body})
code=200; result={}
if s.get('fail_at')==len(calls):
    code=s.get('status',500)
else:
    parts=[unquote(p) for p in urlsplit(url).path.split('/')]
    if method=='GET':
        if parts[-1]=='configuration':
            result=s['config'].copy()
            if s.get('defaults_mismatch') and any(c['method']=='PUT' for c in calls):
                result['newModelDefault']='enabled'
        else:
            result=json.loads(json.dumps(s['catalog']))
            # API returns resolved flags: a disabled provider masks model flags.
            for provider in result['providers']:
                for model in provider['models']:
                    model['enabled']=provider['enabled'] and model['enabled']
            if s.get('readback_mismatch') and any(c['method']=='PUT' for c in calls):
                result=json.loads(json.dumps(result)); result['providers'][0]['enabled']=False
    elif parts[-1]=='configuration': s['config'].update(body)
    else:
        provider=next(p for p in s['catalog']['providers'] if p['id']==parts[4])
        target=next(m for m in provider['models'] if m['id']==parts[6]) if len(parts)==7 else provider
        target.update(body)
        result=target
(root/'state.json').write_text(json.dumps(s))
Path(option('--output')).write_text(json.dumps(result))
print(code,end='')
if s.get('transport_at')==len(calls): sys.exit(28)
'''

class Safety(unittest.TestCase):
    def run_pack(self, *, audit=False, apply=False, policy=None, state=None, env=None):
        fixture={'config': {'teamId':7,'state':'custom','newProviderDefault':'enabled','newModelDefault':'enabled'}, 'catalog':copy.deepcopy(CATALOG)}
        if state: fixture.update(copy.deepcopy(state))
        with tempfile.TemporaryDirectory() as directory:
            p=Path(directory); (p/'state.json').write_text(json.dumps(fixture))
            (p/'curl').write_text(FAKE); (p/'curl').chmod(0o700)
            (p/'sleep').write_text('#!/bin/sh\nexit 0\n'); (p/'sleep').chmod(0o700)
            (p/'policy.json').write_text(json.dumps(POLICY if policy is None else policy))
            environment={**os.environ, 'PATH':str(p)+os.pathsep+os.environ['PATH'], 'FIXTURE':str(p), 'CURSOR_ADMIN_API_KEY':'test-key'}
            environment.pop('CURSOR_API_BASE',None)
            if env: environment.update(env)
            cmd=['bash',str(AUDIT if audit else APPLY)]
            if not audit: cmd += [str(p/'policy.json')] + (['--apply'] if apply else [])
            result=subprocess.run(cmd,env=environment,text=True,capture_output=True,timeout=15)
            saved=json.loads((p/'state.json').read_text())
            self.assertNotIn('test-key',result.stdout+result.stderr)
            return result,saved

    def writes(self,s): return [c for c in s.get('calls',[]) if c['method']=='PUT']

    def test_plan_read_only(self):
        r,s=self.run_pack(); self.assertEqual(r.returncode,0,r.stderr); self.assertFalse(self.writes(s))

    def test_apply_defaults_parameters_and_restrict_before_widen(self):
        r,s=self.run_pack(apply=True); self.assertEqual(r.returncode,0,r.stderr)
        writes=self.writes(s); self.assertEqual(writes[0]['body'],{'newProviderDefault':'disabled','newModelDefault':'disabled'})
        flags=[c['body']['enabled'] for c in writes[1:]]
        self.assertEqual(flags,sorted(flags))
        for p in s['catalog']['providers']:
            self.assertEqual(p['enabled'],p['id']=='trusted')
            for m in p['models']:
                self.assertEqual(m['enabled'],m['id']=='approved'); self.assertEqual(m['parameters'],PARAM)
        self.assertTrue(all(set(c['body'])=={'enabled'} for c in writes[1:]))

    def test_wrong_team(self):
        p=copy.deepcopy(POLICY); p['teamId']=8
        r,s=self.run_pack(apply=True,policy=p); self.assertEqual(r.returncode,2); self.assertFalse(self.writes(s))

    def test_bad_policy(self):
        for p in ({}, {'teamId':7,'models':[]}, {'teamId':7,'models':[POLICY['models'][0]]*2}, {'teamId':7,'models':[{'provider':'missing','id':'x'}]}):
            with self.subTest(policy=p):
                r,s=self.run_pack(apply=True,policy=p); self.assertEqual(r.returncode,2); self.assertFalse(self.writes(s))

    def test_noncustom_no_catalog_or_write(self):
        for policy_state in ('legacy','unrestricted'):
            config={'teamId':7,'state':policy_state,'newProviderDefault':None,'newModelDefault':None}
            for audit in (False,True):
                with self.subTest(state=policy_state,audit=audit):
                    r,s=self.run_pack(audit=audit,apply=True,state={'config':config})
                    self.assertEqual(r.returncode,1 if audit else 2,r.stderr)
                    self.assertEqual(len(s['calls']),1); self.assertFalse(self.writes(s))

    def test_duplicate_catalog_ids_rejected(self):
        c=copy.deepcopy(CATALOG); c['providers'].append(copy.deepcopy(c['providers'][0]))
        r,s=self.run_pack(apply=True,state={'catalog':c}); self.assertEqual(r.returncode,2); self.assertFalse(self.writes(s))

    def test_catalog_team_mismatch(self):
        c=copy.deepcopy(CATALOG); c['teamId']=8
        r,s=self.run_pack(apply=True,state={'catalog':c}); self.assertEqual(r.returncode,2); self.assertFalse(self.writes(s))

    def test_http_failures_stop(self):
        for code in (301,400,401,403,409,429,500):
            with self.subTest(code=code):
                r,s=self.run_pack(apply=True,state={'fail_at':1,'status':code})
                self.assertEqual(r.returncode,2); self.assertEqual(len(s['calls']),1)

    def test_partial_mutation_no_retry_or_rollback(self):
        r,s=self.run_pack(apply=True,state={'fail_at':5,'status':500})
        self.assertEqual(r.returncode,2); self.assertEqual(len(s['calls']),5)
        self.assertEqual(s['config']['newModelDefault'],'disabled')
        self.assertFalse(s['catalog']['providers'][0]['models'][1]['enabled'])
        self.assertIn('not rolled back',r.stderr)

    def test_uncertain_transport_stops(self):
        r,s=self.run_pack(apply=True,state={'transport_at':3})
        self.assertEqual(r.returncode,2); self.assertEqual(len(s['calls']),3)

    def test_readback_mismatch(self):
        for key in ('readback_mismatch','defaults_mismatch'):
            with self.subTest(key=key):
                r,s=self.run_pack(apply=True,state={key:True}); self.assertEqual(r.returncode,2,r.stdout); self.assertIn('mismatch',r.stderr)

    def test_url_encoding(self):
        c=copy.deepcopy(CATALOG); c['providers'][0]['id']='trusted/a ?'; c['providers'][0]['models'][0]['id']='approved/a ?'
        p={'teamId':7,'models':[{'provider':'trusted/a ?','id':'approved/a ?'}]}
        r,s=self.run_pack(apply=True,state={'catalog':c},policy=p); self.assertEqual(r.returncode,0,r.stderr)
        self.assertTrue(any('trusted%2Fa%20%3F/models/approved%2Fa%20%3F' in x['url'] for x in self.writes(s)))

    def test_origin_and_key_guard(self):
        for env in ({'CURSOR_API_BASE':'https://evil.example'}, {'CURSOR_ADMIN_API_KEY':'bad\nurl = evil'}, {'CURSOR_ADMIN_API_KEY':''}):
            for audit in (False,True):
                with self.subTest(env=env,audit=audit):
                    r,s=self.run_pack(audit=audit,apply=True,env=env); self.assertEqual(r.returncode,2); self.assertFalse(s.get('calls'))

    def test_audit_defaults(self):
        r,s=self.run_pack(audit=True); self.assertEqual(r.returncode,1); self.assertFalse(self.writes(s))
        config={'teamId':7,'state':'custom','newProviderDefault':'disabled','newModelDefault':'disabled'}
        r,s=self.run_pack(audit=True,state={'config':config}); self.assertEqual(r.returncode,0,r.stderr); self.assertIn('BASELINE CHECK ONLY',r.stdout)

if __name__=='__main__': unittest.main(verbosity=2)
