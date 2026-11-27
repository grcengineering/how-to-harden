#!/usr/bin/env python3
"""Offline contract checks. Neither gcloud nor curl can reach real services."""
from pathlib import Path
import os,json,subprocess as sp,tempfile
root=Path(__file__).resolve().parents[1] / 'packs' / 'google-gemini-enterprise'
app=next((root/'api').glob('*app-iam.sh'))
store=next((root/'api').glob('*store-iam.sh'))
settings=next((root/'api').glob('*observability.sh'))
iam=next((root/'cli').glob('*project-iam.sh'))
logs=next((root/'cli').glob('*audit-metadata.sh'))
with tempfile.TemporaryDirectory() as d:
 t=Path(d)
 for name,code in {
 'curl':'''#!/usr/bin/env python3
import os,sys
a=sys.argv[1:]
assert a[:3]==['--disable','--config','-'] and a[a.index('--request')+1]=='GET'
assert '--location' not in a
assert a[-1]==os.environ['EXPECTED_URL'], a[-1]
assert all('mock.token' not in arg for arg in a)
assert sys.stdin.read().strip()=='header = "Authorization: Bearer mock.token"'
with open(os.environ['CALLS'],'a') as f: f.write('curl')
status=int(os.environ.get('STATUS','200'))
if status>=400: sys.exit(22)
print(os.environ.get('BODY','') + ' ' + str(status),end='')
''',
 'gcloud':'''#!/usr/bin/env python3
import os,sys
a=sys.argv[1:]
pid=os.environ['GEMINI_PROJECT_ID']
if a[0]=='projects':
 assert a==['projects','get-iam-policy',pid,'--format=json','--quiet']
else:
 assert a[:2]==['logging','read']
 assert a[2]=='logName="projects/'+pid+'/logs/discoveryengine.googleapis.com%2Fgemini_enterprise_user_activity" OR logName=~"^projects/'+pid+'/logs/discoveryengine[.]googleapis[.]com%2Fgen_ai.*$"'
 assert [f'--project={pid}','--freshness=24h','--limit=20','--order=desc','--format=json(logName,timestamp)','--quiet']==a[3:]
with open(os.environ['CALLS'],'a') as f: f.write('gcloud')
print(os.environ.get('BODY',''))
'''
 }.items():
  f=t/name;f.write_text(code);f.chmod(0o700)
 call_file=t/'calls'
 env={'GEMINI_PROJECT_ID':'example-abc','GEMINI_LOCATION':'global','GEMINI_APP_ID':'engine-a','GEMINI_DATA_STORE_ID':'store-b','GEMINI_OAUTH_TOKEN':'mock.token'}
 def run(f,payload,over=None,value=None,rc=0,called=True):
  call_file.write_text('')
  r=sp.run(['/bin/bash',str(f)],env={**os.environ,'PATH':str(t)+':'+os.environ['PATH'],'CALLS':str(call_file),'BODY':json.dumps(payload),**env,**(over or {})},text=True,capture_output=True)
  assert (r.returncode==0)==(rc==0),(payload,r)
  assert bool(call_file.read_text())==called,r
  if rc:
   assert not r.stdout,r
  else:
   assert json.loads(r.stdout)==value,r
  assert not any(s in r.stdout+r.stderr for s in ['mock.token','sensitive@example.org','secret-prompt']), r
 arm={'EXPECTED_URL':'https://discoveryengine.googleapis.com/v1/projects/example-abc/locations/global/collections/default_collection/engines/engine-a:getIamPolicy?options.requestedPolicyVersion=3'}
 drm={'GEMINI_LOCATION':'eu','EXPECTED_URL':'https://eu-discoveryengine.googleapis.com/v1/projects/example-abc/locations/eu/collections/default_collection/dataStores/store-b:getIamPolicy?options.requestedPolicyVersion=3'}
 orm={'GEMINI_LOCATION':'us','EXPECTED_URL':'https://us-discoveryengine.googleapis.com/v1alpha/projects/example-abc/locations/us/collections/default_collection/engines/engine-a?fields=appType%2CobservabilityConfig'}
 sample={'etag':'mock','version':3,'bindings':[{'role':'roles/discoveryengine.agentspaceUser','members':['user:sensitive@example.org'],'condition':{'title':'time','expression':'expr'}}]}
 summary={'policy_version':3,'direct_bindings':[{'role':'roles/discoveryengine.agentspaceUser','principal_count':1,'public_principal_count':0,'conditional':True}]}
 empty={'policy_version':None,'direct_bindings':[]}
 run(app,sample,arm,summary)
 run(store,sample,drm,summary)
 run(iam,sample,value=summary)
 run(app,{},arm,empty)
 role={'role':'roles/discoveryengine.agentspaceUser','members':['allUsers','allAuthenticatedUsers','user:sensitive@example.org']}
 public={'role':role['role'],'principal_count':3,'public_principal_count':2,'conditional':False}
 run(app,{'version':1,'bindings':[role]},arm,{'policy_version':1,'direct_bindings':[public]})
 run(store,{'bindings':False},drm,rc=1)
 run(iam,{'version':'secret-prompt','bindings':[]},rc=1)
 run(store,{'etag':'mock'},drm,empty)
 run(app,{'error':{'message':'secret-prompt'}},arm,rc=1)
 run(store,{'bindings':'bad'},drm,rc=1)
 run(app,{'bindings':[{'role':'a','members':None}]},arm,rc=1)
 run(app,{}, {**arm,'STATUS':'302'},rc=1)
 run(store,{}, {**drm,'STATUS':'403'},rc=1)
 for bad in [{'GEMINI_LOCATION':'asia'},{'GEMINI_PROJECT_ID':'other/path'},{'GEMINI_APP_ID':'a?fields=foo'},{'GEMINI_OAUTH_TOKEN':'str\nhdr'}]:
  run(app,{},bad,rc=1,called=False)
 boolean={'app_type':'APP_TYPE_INTRANET','observability_enabled':True,'sensitive_logging_enabled':False}
 run(settings,{'appType':'APP_TYPE_INTRANET','observabilityConfig':{'observabilityEnabled':True,'sensitiveLoggingEnabled':False}},orm,boolean)
 run(settings,{'appType':'APP_TYPE_INTRANET'},orm,{'app_type':'APP_TYPE_INTRANET','observability_enabled':None,'sensitive_logging_enabled':None})
 run(settings,{'appType':'OTHER'},orm,rc=1)
 run(settings,{'appType':'APP_TYPE_INTRANET','observabilityConfig':{'sensitiveLoggingEnabled':'false'}},orm,rc=1)
 run(logs,[{'logName':'path','timestamp':'2026-11-27T22:00:00.7Z','payload':'secret-prompt'},{'logName':'p','timestamp':'2026-11-27T22:00:00Z'}],value={'sampled':2,'newest_timestamp':'2026-11-27T22:00:00.7Z'})
 run(logs,[],value={'sampled':0,'newest_timestamp':None})
 run(logs,[{'logName':'path'}],rc=1)
 run(logs,[{'logName':'path','timestamp':'2026-11-27T22:00:00Z'}]*21,rc=1)
 run(iam,{}, {'GEMINI_PROJECT_ID':'--project=other'},rc=1,called=False)
 print('26 strict offline HTTP/CLI cases passed')
