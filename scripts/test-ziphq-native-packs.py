#!/usr/bin/env python3
"""Offline Zip native API contracts; mock curl, no credentials or live calls."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
PACKS = [next((ROOT/'packs/ziphq/api').glob('hth-ziphq-'+number+'-*.sh'))
         for number in ('1.05','1.06','2.04','4.02','2.05')]
ID = '11111111-2222-3333-4444-555555555555'
OTHER = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
KEY = 'MOCK_SECRET_KEY'
MOCK = r'''#!/usr/bin/env python3
import json, os, pathlib, sys, urllib.parse
args=sys.argv[1:]; config=sys.stdin.read()
assert args[0]=='-q'
for flag,value in [('--request','GET'),('--proto','=https'),('--max-redirs','0'),
                   ('--proxy',''),('--noproxy','*'),('--config','-'),
                   ('--max-time','60'),('--connect-timeout','10'),('--max-filesize','10485760')]:
    assert args[args.index(flag)+1]==value
for flag in ['--tlsv1.2','--silent','--fail']: assert flag in args
for flag in ['-k','--insecure','-L','--location','--data']: assert flag not in args
assert 'ZIP_API_KEY' not in os.environ and 'GRAPH_ACCESS_TOKEN' not in os.environ
assert 'MOCK_SECRET_KEY' not in ' '.join(args)
assert config=='header = "Zip-Api-Key: MOCK_SECRET_KEY"\nheader = "Zip-Api-Version: 2024-06-06"\nheader = "Accept: application/json"\n'
u=urllib.parse.urlsplit(args[args.index('--url')+1])
assert u.scheme=='https' and u.netloc=='api.ziphq.com' and not u.fragment
assert u.path==os.environ['MOCK_PATH']
# Python 3.9 rejects an empty query under strict parsing; no query is valid
# for the single-queue endpoint. Still parse every nonempty query strictly.
q=urllib.parse.parse_qs(u.query,strict_parsing=True) if u.query else {}
if not u.path.startswith('/queues/'):
    assert q['page_size']==['100'] and q['sort_by']==['created_at'] and q['sort_order']==['asc']
else: assert not q
if u.path=='/delegations': assert q['is_active']==['true']
if u.path=='/event_logs': assert q['created_after']==['100'] and q['created_before']==['200']
p=pathlib.Path(os.environ['MOCK_STATE']); n=int(p.read_text()) if p.exists() else 0
p.write_text(str(n+1)); fixtures=json.loads(pathlib.Path(os.environ['MOCK_FIXTURES']).read_text())
assert n<len(fixtures), 'Unexpected extra request'
f=fixtures[n]
if 'cursor' in f: assert q['page_token']==[f['cursor']]
if f.get('rc'): sys.exit(f['rc'])
sys.stdout.write(f.get('raw',json.dumps(f.get('body')))+'\n'+str(f.get('status',200)))
'''


def page(items=None, **fields):
    return {'body':dict(list=items or [],size=len(items or []),total=len(items or []),**fields)}


class NativeCollectors(unittest.TestCase):
    def run_pack(self,index,pages,*,ok=True,env_extra=None,calls=None):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp);(p/'curl').write_text(MOCK);(p/'curl').chmod(0o700)
            (p/'fixtures').write_text(json.dumps(pages))
            env=dict(os.environ,PATH=tmp+os.pathsep+os.environ['PATH'],
                     ZIP_API_KEY=KEY,GRAPH_ACCESS_TOKEN='ANOTHER_SECRET',
                     ZIP_CREATED_AFTER='100',ZIP_CREATED_BEFORE='200',ZIP_QUEUE_ID=ID,
                     MOCK_PATH=('/users','/users','/delegations','/event_logs','/queues/'+ID)[index],
                     MOCK_STATE=str(p/'state'),MOCK_FIXTURES=str(p/'fixtures'))
            # No ambient options should affect test semantics.
            for name in ['ZIP_API_VERSION','ZIP_APPROVED_GROUP_IDS','ZIP_APPROVED_SSO_EXCEPTION_IDS']:
                env.pop(name,None)
            env.update(env_extra or {})
            result=subprocess.run(['bash','-x',str(PACKS[index])],env=env,
                                  capture_output=True,text=True,timeout=30)
            self.assertEqual(result.returncode==0,ok,result.stderr)
            for secret in [KEY,'ANOTHER_SECRET',ID,OTHER,'PRIVATE_TEXT']:
                self.assertNotIn(secret,result.stdout+result.stderr)
            if calls is not None:
                self.assertEqual(int((p/'state').read_text()) if (p/'state').exists() else 0,calls)
            if ok:
                value=json.loads(result.stdout)
                self.assertEqual(value['result'],'review-required')
                return value
            self.assertEqual(result.stdout,'')

    def test_queue(self):
        obj={'id':ID,'queue_owners':[{'id':ID,'email':'PRIVATE_TEXT'}],
             'queue_members':[{'id':OTHER},{'id':OTHER}],
             'all_members_can_view_approvals':False,
             'all_members_will_receive_approval_notifications':None,
             'group_email':'PRIVATE_TEXT','description':'PRIVATE_TEXT'}
        out=self.run_pack(4,[{'body':obj}],calls=1)
        self.assertEqual(out['counts']['owners'],1)
        self.assertEqual(out['counts']['members'],1)
        self.assertEqual(out['counts']['viewApprovals:false'],1)
        self.assertEqual(out['counts']['receiveApprovalNotifications:unknown'],1)
        out=self.run_pack(4,[{'body':{'id':ID}}])
        self.assertIsNone(out['counts']['owners'])
        for change in [dict(id=OTHER),dict(queue_members=None),dict(queue_owners={}),
                       dict(all_members_can_view_approvals='false'),dict(queue_members=[{}])]:
            self.run_pack(4,[{'body':dict(obj,**change)}],ok=False)
        for identifier in ['',ID+'/../../users','not-a-uuid']:
            self.run_pack(4,[],env_extra={'ZIP_QUEUE_ID':identifier},ok=False,calls=0)
        for status in [301,401,403,404,429,500]:
            self.run_pack(4,[{'body':obj,'status':status}],ok=False)

    def test_inputs(self):
        for i in range(4):
            for key in ['', 'bad\nline','bad"','bad\\','bad token']:
                self.run_pack(i,[],env_extra={'ZIP_API_KEY':key},ok=False,calls=0)
            self.run_pack(i,[],env_extra={'ZIP_API_VERSION':'2026-07-01'},ok=False,calls=0)
        for i,name in [(0,'ZIP_APPROVED_SSO_EXCEPTION_IDS'),(1,'ZIP_APPROVED_GROUP_IDS')]:
            self.run_pack(i,[],env_extra={name:'Admins'},ok=False,calls=0)
        for after,before in [('', '200'),('NaN','200'),('200','100'),('100','100'),
                             ('0','99999999'),('-1','200'),('1.5','200')]:
            self.run_pack(3,[],env_extra={'ZIP_CREATED_AFTER':after,'ZIP_CREATED_BEFORE':before},ok=False,calls=0)

    def test_http_and_json_failures(self):
        for i in range(4):
            for status in [204,301,302,401,403,405,429,500]:
                self.run_pack(i,[dict(page(),status=status)],ok=False,calls=1)
            for rc in [22,28,60,63]:
                self.run_pack(i,[{'rc':rc}],ok=False)
            for body in [None,[],{},dict(list=[],size=0,total=None),dict(list=None,size=0,total=0),
                         dict(list=[],size=1,total=100),dict(list=[],size=True,total=0),dict(list=[],size=0,total=-1),
                         dict(list=[{}],size=1,total=1),dict(list=[],size=0,total=0,error=KEY)]:
                self.run_pack(i,[{'body':body}],ok=False)
            for raw in ['', '{', '<html>PRIVATE_TEXT</html>']:
                self.run_pack(i,[{'raw':raw}],ok=False)

    def test_missing_fields_and_empty(self):
        for i in range(4):
            out=self.run_pack(i,[page()]);self.assertEqual(out['uniqueRecords'],0)
            for body in [dict(list=[]), dict(list=[],size=0), dict(list=[],total=0)]:
                out=self.run_pack(i,[{'body':body}])
                self.assertEqual(out['uniqueRecords'],0)
            for field in ('size','total'):
                for malformed in (None, True, -1, '0', [], {}):
                    self.run_pack(i,[{'body':dict(list=[],**{field:malformed})}],ok=False)
            out=self.run_pack(i,[page([{'id':ID}])]);self.assertEqual(out['uniqueRecords'],1)
            self.assertTrue(any('Unknown' in k or 'UNKNOWN' in k for k in out['counts']))
        self.run_pack(0,[page([{'id':ID,'is_active':None}])],ok=False)
        self.run_pack(1,[page([{'id':ID,'groups':None}])],ok=False)
        self.run_pack(2,[page([{'id':ID,'starts_at':'yesterday'}])],ok=False)
        self.run_pack(3,[page([{'id':ID,'timestamp':True}])],ok=False)

    def test_sso_and_group_baselines(self):
        user={'id':ID,'is_active':True,'sso_enforced':False,'email':'PRIVATE_TEXT'}
        out=self.run_pack(0,[page([user])],env_extra={'ZIP_APPROVED_SSO_EXCEPTION_IDS':OTHER})
        self.assertEqual(out['counts']['unapprovedExceptions'],1)
        out=self.run_pack(0,[page([user])],env_extra={'ZIP_APPROVED_SSO_EXCEPTION_IDS':ID})
        self.assertEqual(out['counts']['approvedExceptions'],1)
        groups=[{'id':ID,'name':'Not an admin'},{'id':OTHER,'name':'PRIVATE_TEXT'}]
        out=self.run_pack(1,[page([{'id':ID,'groups':groups,'roles':[{'name':'Admin'}]}])],
                          env_extra={'ZIP_APPROVED_GROUP_IDS':ID})
        self.assertEqual(out['counts']['membershipsOutsideApprovedGroups'],1)
        self.assertEqual(out['counts']['observedMemberships'],2)
        self.run_pack(1,[page([{'id':ID,'groups':[{'name':'Admin'}]}])],ok=False)

    def test_membership_memory_boundary(self):
        # One bounded JSON response, not 100,000 subprocesses or live requests.
        groups=[{'id': '00000000-0000-0000-0000-'+format(n,'012x')} for n in range(100000)]
        out=self.run_pack(1,[page([{'id':ID,'groups':groups}])])
        self.assertEqual(out['counts']['observedMemberships'],100000)
        # Repeated user projection must not spend the budget twice.
        small={'id':ID,'groups':groups[:2]}
        out=self.run_pack(1,[page([small],next_page_token='next'),page([small])])
        self.assertEqual(out['counts']['observedMemberships'],2)
        # A distinct second user's single membership crosses the retained limit.
        self.run_pack(1,[page([{'id':ID,'groups':groups}],next_page_token='next'),
                         page([{'id':OTHER,'groups':[groups[0]]}])],ok=False,calls=2)

    def test_delegations_and_audit(self):
        out=self.run_pack(2,[page([{'id':ID,'status':'UPCOMING','starts_at':100,'ends_at':200,
                                   'delegator':{'id':ID},'delegate':{'id':OTHER},'note':'PRIVATE_TEXT'}])])
        self.assertEqual(out['counts']['status:UPCOMING'],1)
        events=[{'id':ID,'timestamp':150,'event_type':'LOGIN_FAILURE','actor':{'type':'API_KEY','display_name':'PRIVATE_TEXT'},
                 'api_key':KEY,'user_ip_address':'PRIVATE_TEXT','description':'PRIVATE_TEXT','data':{'key':KEY}},
                {'id':OTHER,'event_type':'PRIVATE_TEXT','actor':{'type':'PRIVATE_TEXT'}}]
        out=self.run_pack(3,[page(events)])
        self.assertEqual(out['counts']['event:LOGIN_FAILURE'],1)
        self.assertEqual(out['counts']['event:OTHER_OR_UNKNOWN'],1)
        self.assertEqual(out['counts']['actor:UNKNOWN'],1)

    def test_pagination_encoded_tokens_and_dedup(self):
        token='https://evil.test/p?x=1&created_after=0#frag'
        for i in range(4):
            record={'id':ID}
            first=page([record],next_page_token=token);first['body']['total']=10000
            second=page([record]);second['cursor']=token
            out=self.run_pack(i,[first,second],calls=2)
            self.assertEqual(out['uniqueRecords'],1)
            self.assertEqual(out['pages'],2)
            self.run_pack(i,[page()],calls=1)
            self.run_pack(i,[page(next_page_token=None)],calls=1)
            for cursor in ['',4,{},'bad\nline']:
                self.run_pack(i,[page(next_page_token=cursor)],ok=False,calls=1)
            self.run_pack(i,[page(next_page_token='repeat')]*2,ok=False,calls=2)
        for i,changed in [(0,{'is_active':True}),(1,{'groups':[]}),(2,{'status':'ACTIVE'}),(3,{'timestamp':150})]:
            self.run_pack(i,[page([{'id':ID},dict(id=ID,**changed)])],ok=False)
        pages=[page(next_page_token=str(n)) for n in range(100)]
        self.run_pack(3,pages,ok=False,calls=100)


if __name__=='__main__':
    unittest.main(verbosity=2)
