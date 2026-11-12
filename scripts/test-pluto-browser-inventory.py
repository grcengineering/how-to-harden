#!/usr/bin/env python3
"""Offline Chrome inventory transport tests; no network or real credentials."""
import json, os, pathlib, subprocess, tempfile, unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
SCRIPT=ROOT/'packs/google-workspace/api/hth-google-workspace-3.03-inventory-browser-extensions.sh'
class Inventory(unittest.TestCase):
 def run_case(self,pages,**extra):
  with tempfile.TemporaryDirectory() as d:
   p=pathlib.Path(d)
   for i,page in enumerate(pages): (p/str(i)).write_text(page if isinstance(page,str) else json.dumps(page))
   mock=p/'curl';mock.write_text('''#!/bin/bash
n=0; [[ ! -f "$MOCK/count" ]] || n=$(cat "$MOCK/count")
echo $((n+1)) > "$MOCK/count"
printf '%s\\n' "$@" >> "$MOCK/args"
cat >> "$MOCK/auth"
cat "$MOCK/$n"
exit "${MOCK_RC:-0}"
''');mock.chmod(0o700)
   env=dict(os.environ,PATH=d+':'+os.environ['PATH'],MOCK=d,GOOGLE_ACCESS_TOKEN='fake-test-token',HTH_PROFILE_LEVEL='2')
   env.update(extra)
   r=subprocess.run(['bash',str(SCRIPT)],env=env,capture_output=True,text=True)
   return r,(p/'args').read_text() if (p/'args').exists() else '',(p/'auth').read_text() if (p/'auth').exists() else ''
 def test_pages_and_transport(self):
  r,args,auth=self.run_case([{'installedApps':[{'appId':'a'}],'nextPageToken':'opaque+/='},{'installedApps':[{'appId':'b'}]}])
  self.assertEqual(r.returncode,0,r.stderr);self.assertEqual(len(r.stdout.splitlines()),2)
  self.assertTrue(args.startswith('-q\n'));self.assertNotIn('fake-test-token',args);self.assertIn('fake-test-token',auth)
  self.assertIn('pageToken=opaque+/=',args);self.assertIn('--max-time',args);self.assertNotIn('--location',args)
 def test_late_malformed_no_partial_output(self):
  r,_,_=self.run_case([{'installedApps':[{'appId':'a'}],'nextPageToken':'next'},'{}\n{}']);self.assertNotEqual(r.returncode,0);self.assertEqual(r.stdout,'')
 def test_invalid_cursor_error_envelopes(self):
  for p in ({'nextPageToken':3},{'error':{'message':'denied'}},[],{'installedApps':False}):
   r,_,_=self.run_case([p]);self.assertNotEqual(r.returncode,0)
 def test_repeated_cursor(self):
  r,_,_=self.run_case([{'nextPageToken':'same'},{'nextPageToken':'same'}]);self.assertNotEqual(r.returncode,0);self.assertEqual(r.stdout,'')
 def test_transport_failure(self):
  r,_,_=self.run_case([{}],MOCK_RC='22');self.assertNotEqual(r.returncode,0)
 def test_invalid_profile(self):
  for level in ('1','0','5','two',''):
   r,args,_=self.run_case([],HTH_PROFILE_LEVEL=level);self.assertEqual(r.returncode,2);self.assertEqual(args,'')
 def test_invalid_customer(self):
  r,args,_=self.run_case([],GOOGLE_CUSTOMER_ID='../other');self.assertNotEqual(r.returncode,0);self.assertEqual(args,'')
if __name__=='__main__':unittest.main()
