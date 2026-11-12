"""Offline contract tests. No tenant access; does not establish live validation."""
import json, os, pathlib, subprocess, tempfile, unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
class AuditTests(unittest.TestCase):
 def run_pack(self, name, pages, url='https://test.crm.dynamics.com', token='fixture'):
  with tempfile.TemporaryDirectory() as d:
   p=pathlib.Path(d); (p/'pages.json').write_text(json.dumps(pages))
   (p/'curl').write_text('''#!/usr/bin/env python3
import json,os,sys,pathlib
p=pathlib.Path(os.environ['FAKE_DIR']); counter=p/'n'; n=int(counter.read_text()) if counter.exists() else 0
counter.write_text(str(n+1)); pages=json.loads((p/'pages.json').read_text())
a=sys.argv; pathlib.Path(a[a.index('--output')+1]).write_text(json.dumps(pages[n])); print('200',end='')
'''); (p/'curl').chmod(0o700)
   env=dict(os.environ,PATH=str(p)+':'+os.environ['PATH'],FAKE_DIR=d,DATAVERSE_URL=url,DATAVERSE_TOKEN=token)
   result=subprocess.run(['bash',str(ROOT/'packs/copilot-studio/api'/name)],env=env,capture_output=True,text=True)
   return result, int((p/'n').read_text()) if (p/'n').exists() else 0
 def test_auth_enum_and_pagination(self):
  rows=[{'botid':str(i),'authenticationmode':i} for i in range(6)]
  out,n=self.run_pack('hth-copilot-studio-1.01-bots-audit.sh',[{'value':rows[:3],'@odata.nextLink':'https://test.crm.dynamics.com/api/data/v9.2/bots?next=2'},{'value':rows[3:]}])
  self.assertEqual(out.returncode,0,out.stderr);self.assertEqual(n,2)
  r=json.loads(out.stdout);self.assertEqual(r[0]['review'],'UNSPECIFIED_REVIEW');self.assertEqual(r[1]['review'],'NO_AUTH');self.assertEqual(r[5]['review'],'UNKNOWN_REVIEW')
 def test_foreign_nextlink_blocked(self):
  out,n=self.run_pack('hth-copilot-studio-1.01-bots-audit.sh',[{'value':[],'@odata.nextLink':'https://evil.example/api/data/v9.2/bots'}]);self.assertNotEqual(out.returncode,0);self.assertEqual(n,1);self.assertEqual(out.stdout,'')
 def test_loop_blocked(self):
  link='https://test.crm.dynamics.com/api/data/v9.2/bots?next=2'
  out,n=self.run_pack('hth-copilot-studio-1.01-bots-audit.sh',[{'value':[],'@odata.nextLink':link},{'value':[],'@odata.nextLink':link}]);self.assertNotEqual(out.returncode,0);self.assertEqual(n,2)
 def test_error_not_clean(self):
  out,n=self.run_pack('hth-copilot-studio-1.01-bots-audit.sh',[{'error':{'message':'denied'}}]);self.assertNotEqual(out.returncode,0);self.assertEqual(out.stdout,'')
 def test_secret_not_output(self):
  out,n=self.run_pack('hth-copilot-studio-2.04-botcomponents-audit.sh',[{'value':[{'botcomponentid':'x','data':'secret-canary','content':'content-canary','unexpected_secret':'extra-canary'}]}]);self.assertEqual(out.returncode,0,out.stderr);self.assertNotIn('secret-canary',out.stdout);self.assertNotIn('extra-canary',out.stdout);self.assertNotIn('content-canary',out.stdout);self.assertEqual(len(json.loads(out.stdout)[0]['data_sha256']),64)
 def test_invalid_origin(self):
  out,n=self.run_pack('hth-copilot-studio-1.01-bots-audit.sh',[],url='http://test.crm.dynamics.com');self.assertNotEqual(out.returncode,0);self.assertEqual(n,0)
 def test_duplicate_id_fails(self):
  out,n=self.run_pack('hth-copilot-studio-1.01-bots-audit.sh',[{'value':[{'botid':'x'},{'botid':'x'}]}]);self.assertNotEqual(out.returncode,0);self.assertEqual(out.stdout,'')
 def test_missing_id_fails(self):
  out,n=self.run_pack('hth-copilot-studio-1.01-bots-audit.sh',[{'value':[{'name':'x'}]}]);self.assertNotEqual(out.returncode,0);self.assertEqual(out.stdout,'')
 def test_token_header_injection(self):
  out,n=self.run_pack('hth-copilot-studio-1.01-bots-audit.sh',[],token='bad\r\nX-Extra: injected');self.assertNotEqual(out.returncode,0);self.assertEqual(n,0)
 def test_curl_config_disabled(self):
  for p in (ROOT/'packs/copilot-studio/api').glob('*.sh'):
   s=p.read_text();self.assertIn('curl -q ',s);self.assertIn('--max-redirs 0',s);self.assertIn('--max-filesize 52428800',s)
 def test_artifact_no_delete(self):
  p=ROOT/'packs/copilot-studio/api/hth-copilot-studio-4.02-flowsessionbinaries-audit.sh';s=p.read_text();self.assertNotIn('--request DELETE',s);self.assertNotIn("type eq 'CuaScreenshot'",s)
  out,n=self.run_pack(p.name,[{'value':[{'flowsessionbinaryid':'x','createdon':'2026-01-01'}]}]);self.assertEqual(out.returncode,0,out.stderr)
if __name__=='__main__':unittest.main()
