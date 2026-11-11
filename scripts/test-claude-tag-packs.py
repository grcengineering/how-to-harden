#!/usr/bin/env python3
"""Offline API fixtures only; never uses real credentials or tenant APIs."""
import json, os, pathlib, subprocess, tempfile, unittest, importlib.util
from types import SimpleNamespace as NS
ROOT = pathlib.Path(__file__).resolve().parents[1]
PACK = ROOT / 'packs/claude-tag/api'
def channel(enabled=True):
    return dict(type='slack_channel',id='slch_A',slack=dict(workspace_id='T123',channel_id='C123'),settings=dict(enabled=enabled,guest_policy={'type':'restrict'},instructions='PRIVATE',model=None,environment_id='ccpool_existing'),sources={})
def page(data, cursor=None): return dict(data=data,next_page=cursor)
class Tests(unittest.TestCase):
    def runpack(self, name, responses, extra=None):
        with tempfile.TemporaryDirectory() as d:
            p=pathlib.Path(d)
            (p/'curl').write_text('''#!/usr/bin/env python3
import os,sys,json,pathlib
p=pathlib.Path(os.environ['MOCK']); n=len(list(p.glob('call.*')))
(p/f'call.{n}').write_text(json.dumps(sys.argv[1:]))
(p/f'header.{n}').write_text(sys.stdin.read())
f=p/f'response.{n}'
if not f.exists(): sys.exit(99)
print(f.read_text())
''')
            (p/'curl').chmod(0o700)
            for i,r in enumerate(responses): (p/f'response.{i}').write_text(json.dumps(r))
            env={k:v for k,v in os.environ.items() if not k.startswith(('HTH_','ANTHROPIC_'))}
            env.update(PATH=d+':'+os.environ['PATH'], MOCK=d, ANTHROPIC_ADMIN_KEY='fake-test-key', TMPDIR=d)
            env.update(extra or {})
            result=subprocess.run(['bash',str(PACK/name)],env=env,capture_output=True,text=True)
            calls=[json.loads(f.read_text()) for f in sorted(p.glob('call.*'))]
            headers=[f.read_text() for f in sorted(p.glob('header.*'))]
            return result,calls,headers
    def audit(self, responses, extra=None): return self.runpack('hth-claude-tag-1.01-audit.sh',responses,extra)
    def lock(self,responses,apply=False,extra=None):
        env=dict(HTH_CHANNEL_ID='slch_A',HTH_SLACK_WORKSPACE_ID='T123',HTH_SLACK_CHANNEL_ID='C123')
        if apply: env.update(HTH_APPLY='1',HTH_CONFIRM_CHANNEL_ID='slch_A')
        env.update(extra or {})
        return self.runpack('hth-claude-tag-1.02-lockdown-channel.sh',responses,env)
    def test_empty_cursor_page_and_private_transport(self):
        r,c,h=self.audit([page([], 'p+/='),page([]),page([])])
        self.assertEqual(r.returncode,0,r.stderr)
        self.assertIn('page=p%2B%2F%3D',c[1][-1]); self.assertEqual(c[0][0],'-q')
        self.assertNotIn('fake-test-key',str(c)); self.assertIn('fake-test-key',str(h))
        self.assertNotIn('--location',str(c)); self.assertIn('experimental-claude-tag-2026-10-21',str(c))
    def test_invalid_pagination_never_emits_partial_report(self):
        for response in ({'data':[]},page([],'')):
            r,_,_=self.audit([response]); self.assertNotEqual(r.returncode,0); self.assertEqual(r.stdout,'')
    def test_repeated_cursor_fails(self):
        r,_,_=self.audit([page([],'a'),page([],'a')]);self.assertNotEqual(r.returncode,0)
    def test_grid_inventory_and_redaction(self):
        r,c,_=self.audit([page([]),page([channel()]),page([])],{'HTH_GRID_IDS':'E123'})
        self.assertEqual(r.returncode,0,r.stderr);self.assertIn('slack_workspace_id=E123',str(c));self.assertNotIn('PRIVATE',r.stdout)
        self.assertEqual(json.loads(r.stdout)['findings'][0]['reason'],'enabled without supplied approval')
    def test_bad_ids_no_network(self):
        r,c,_=self.lock([],extra={'HTH_CHANNEL_ID':'slch_A/../../foo'})
        self.assertNotEqual(r.returncode,0);self.assertEqual(c,[])
    def test_preview_is_read_only(self):
        r,c,_=self.lock([channel()]);self.assertEqual(r.returncode,0,r.stderr);self.assertEqual(len(c),1);self.assertIn('preview',r.stdout)
    def test_confirmation_required(self):
        r,c,_=self.lock([],True,{'HTH_CONFIRM_CHANNEL_ID':'slch_B'})
        self.assertNotEqual(r.returncode,0);self.assertEqual(c,[])
    def test_wrong_identity_no_write(self):
        wrong=channel();wrong['slack']['channel_id']='C999'
        r,c,_=self.lock([wrong],True);self.assertNotEqual(r.returncode,0);self.assertEqual(len(c),1)
    def test_apply_partial_update_and_readback(self):
        r,c,_=self.lock([channel(),channel(False),channel(False),channel(False)],True)
        self.assertEqual(r.returncode,0,r.stderr);self.assertEqual(len(c),4)
        body=json.loads(c[1][c[1].index('--data')+1]);self.assertEqual(body,{'settings':{'enabled':False,'guest_policy':{'type':'restrict'}}})
        self.assertIn('include_inherited=true',c[-1][-1])
    def test_concurrent_unrelated_edit_detected(self):
        after=channel(False);after['settings']['model']='changed'
        r,c,_=self.lock([channel(),after,after],True);self.assertNotEqual(r.returncode,0);self.assertEqual(len(c),3)
    def test_mutation_failure_not_retried(self):
        r,c,_=self.lock([channel()],True);self.assertNotEqual(r.returncode,0);self.assertEqual(len(c),2)
class SDKTests(unittest.TestCase):
    def test_bundle_ids_retained_and_descriptions_omitted(self):
        spec=importlib.util.spec_from_file_location('tag_sdk',ROOT/'packs/claude-tag/sdk/hth-claude-tag-1.03-bundle-target-inventory.py')
        module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
        class Targets:
            def list(self, bundle):
                assert bundle=='capp_A'
                yield NS(id='btgt_A',type='slack_workspace',slack_workspace_id='slws_A')
        tag=NS(bundles=NS(list=lambda:iter([NS(id='capp_A',description='PRIVATE')]),targets=Targets()))
        report=module.inventory(tag)
        self.assertEqual(report['explicit_targets'][0]['bundle_id'],'capp_A')
        self.assertNotIn('PRIVATE',json.dumps(report))
class CLITests(unittest.TestCase):
    def runcli(self, response, profile=False):
        with tempfile.TemporaryDirectory() as d:
            p=pathlib.Path(d)
            (p/'ant').write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$MOCK/args"\ncat > "$MOCK/stdin"\ncat "$MOCK/response"\n')
            (p/'ant').chmod(0o700);(p/'response').write_text(json.dumps(response))
            env={k:v for k,v in os.environ.items() if not k.startswith(('HTH_','ANTHROPIC_'))}
            env.update(PATH=d+':'+os.environ['PATH'],MOCK=d,ANTHROPIC_API_KEY='fake-key',HTH_CHANNEL_ID='slch_A')
            if profile: env['ANTHROPIC_PROFILE']=''
            r=subprocess.run(['bash',str(ROOT/'packs/claude-tag/cli/hth-claude-tag-1.01-effective-channel.sh')],env=env,capture_output=True,text=True)
            return r,(p/'args').read_text() if (p/'args').exists() else '',(p/'stdin').read_text() if (p/'stdin').exists() else ''
    def test_exact_read_command_minimizes_output_and_stdin_key(self):
        r,args,key=self.runcli(channel())
        self.assertEqual(r.returncode,0,r.stderr);self.assertNotIn('PRIVATE',r.stdout)
        self.assertIn('--include-inherited',args);self.assertIn('https://api.anthropic.com',args)
        self.assertNotIn('fake-key',args);self.assertEqual(key,'fake-key')
    def test_bad_response_and_ambient_profile_refused(self):
        wrong=channel();wrong['id']='slch_B'
        r,_,_=self.runcli(wrong);self.assertNotEqual(r.returncode,0);self.assertEqual(r.stdout,'')
        r,args,_=self.runcli(channel(),True);self.assertNotEqual(r.returncode,0);self.assertEqual(args,'')
if __name__=='__main__': unittest.main()
