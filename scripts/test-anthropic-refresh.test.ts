import {test,expect,describe} from 'bun:test';
import {mkdtempSync,writeFileSync,readFileSync,readdirSync,statSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {assess,validValue} from '../packs/claude-enterprise/lib/effective-settings.js';
import {inventory} from '../packs/claude-enterprise/sdk/hth-claude-enterprise-1.03-member-inventory.js';
const root=resolve(import.meta.dir,'..');
const org='11111111-2222-3333-4444-555555555555';
const other='99999999-2222-3333-4444-555555555555';
const schema=JSON.parse(readFileSync(join(root,'packs/claude-enterprise/lib/settings-schema.json'),'utf8'));
const payload=(settings:any[])=>({type:'effective_organization_settings',organization_id:org,settings,api_keys:[]});
const baseline=(name='sso_enabled',type='boolean',value:any=true)=>[{name,type,value}];
const cleanEnv=()=>Object.fromEntries(Object.entries(process.env).filter(([k])=>!(/^(ANTHROPIC_|HTH_|CLAUDE_|OTEL_)/.test(k))));
function run(path:string,env:Record<string,string>={},args:string[]=[]) {
  return Bun.spawnSync(['bash',join(root,path),...args],{cwd:root,env:{...cleanEnv(),...env},timeout:15000});
}
function mock(responses:any[],status=0){
  const dir=mkdtempSync(join(tmpdir(),'hth-anthropic-test-'));
  const curl=String.raw`#!/usr/bin/env bash
set -euo pipefail
n=0; [[ ! -f "$MOCK_DIR/count" ]] || n=$(cat "$MOCK_DIR/count")
printf '%s\n' "$((n+1))" > "$MOCK_DIR/count"
printf '%s\n' "$@" > "$MOCK_DIR/args.$n"
cat > "$MOCK_DIR/stdin.$n"
cat "$MOCK_DIR/response.$n"
exit "\${MOCK_STATUS:-0}"
`.replaceAll('\\${','${');
  writeFileSync(join(dir,'curl'),curl,{mode:0o700});
  responses.forEach((r,i)=>writeFileSync(join(dir,`response.${i}`),typeof r==='string'?r:JSON.stringify(r)));
  return {dir,env:{PATH:`${dir}:${process.env.PATH}`,MOCK_DIR:dir,MOCK_STATUS:String(status),ANTHROPIC_ADMIN_KEY:'sk-ant-test-NOT-A-CREDENTIAL'}};
}
function helper(command:string,m:ReturnType<typeof mock>,extra:Record<string,string>={}){
  return Bun.spawnSync(['bash','-c',`source packs/anthropic-claude/api/common.sh\n${command}`],{cwd:root,env:{...cleanEnv(),...m.env,...extra},timeout:15000});
}
describe('effective settings are distinct from native posture results',()=>{
  test('snapshot enumerates all 64 documented boolean names',()=>expect(schema.boolean.length).toBe(64));
  for(const name of schema.boolean){
    test(`${name}: explicit true matches; omitted never passes`,()=>{
      const result=assess(payload([{name,type:'boolean',value:true}]),baseline(name),org);
      expect(result.native_security_center).toBe(false);expect(result.exit_code).toBe(0);
      const absent=assess(payload([]),baseline(name),org);
      expect(absent.exit_code).toBe(2);expect(absent.checks[0].status).toBe('unavailable');
    });
  }
  test('false and absent are different; strings never become booleans',()=>{
    expect(assess(payload([{name:'sso_enabled',type:'boolean',value:false}]),baseline(),org).exit_code).toBe(1);
    expect(()=>assess(payload([{name:'sso_enabled',type:'boolean',value:'false'}]),baseline(),org)).toThrow();
  });
  test('wrong organization, empty baseline and missing response metadata fail closed',()=>{
    expect(()=>assess(payload([]),baseline(),other)).toThrow();
    expect(()=>assess(payload([]),[],org)).toThrow();
    expect(()=>assess({settings:[]},baseline(),org)).toThrow();
  });
  test('duplicate rows and duplicate/unknown baseline names cannot hide evidence',()=>{
    const r={name:'sso_enabled',type:'boolean',value:true};
    expect(()=>assess(payload([r,r]),baseline(),org)).toThrow();
    expect(()=>assess(payload([r]),[...baseline(),...baseline()],org)).toThrow();
    expect(()=>assess(payload([]),baseline('invented_secure','boolean',false),org)).toThrow();
  });
  test('null session limit is not a finite limit; type mismatch is unknown',()=>{
    const name='account_session_duration_seconds';
    expect(assess(payload([{name,type:'integer',value:null}]),baseline(name,'integer',604800),org).exit_code).toBe(1);
    expect(assess(payload([{name,type:'boolean',value:true}]),baseline(name,'integer',604800),org).exit_code).toBe(2);
  });
  test('typed list, provisioning and retention comparison preserve policy semantics',()=>{
    expect(validValue('string_list',['a','a'])).toBe(false);
    expect(validValue('provisioning_mode','scim_advanced')).toBe(true);
    expect(validValue('provisioning_mode','scim')).toBe(false);
    const value={chat:{type:'fixed',duration:30,timescale:'day'}};
    expect(assess(payload([{name:'data_retention_periods',type:'data_retention',value}]),baseline('data_retention_periods','data_retention',value),org).exit_code).toBe(0);
    expect(validValue('data_retention',{all:{type:'indefinite'},chat:{type:'indefinite'}})).toBe(false);
    expect(validValue('data_retention',{chat:{type:'fixed',duration:-1,timescale:'day'}})).toBe(false);
  });
  test('future returned names remain unassessed, never implicit checks',()=>{
    const r=assess(payload([{name:'sso_enabled',type:'boolean',value:true},{name:'future_flag',type:'boolean',value:true}]),baseline(),org);
    expect(r.unassessed_settings).toBe(1);expect(r.checks).toHaveLength(1);
  });
});
describe('fixed-host API transport and complete evidence',()=>{
  test('credential goes over stdin, curlrc and redirects cannot reroute it',()=>{
    const m=mock([{ok:true}]);const r=helper('anthropic_get /v1/organizations/me',m);
    expect(r.exitCode).toBe(0);
    const args=readFileSync(join(m.dir,'args.0'),'utf8');
    expect(args.startsWith('-q\n')).toBe(true);expect(args).not.toContain(m.env.ANTHROPIC_ADMIN_KEY);
    expect(args).not.toContain('--location');expect(args).toContain('--proto\n=https');
    expect(args).toContain('--connect-timeout');expect(args).toContain('--max-time');
    expect(readFileSync(join(m.dir,'stdin.0'),'utf8')).toContain(m.env.ANTHROPIC_ADMIN_KEY);
    expect(helper('anthropic_get /v1/organizations/me',m,{ANTHROPIC_API_BASE:'https://attacker.example'}).exitCode).not.toBe(0);
  });
  for(const response of ['', 'null','[]','{}\n{}','{"ok":true}\nfalse'])test(`reject invalid/multiple response objects ${response}`,()=>{
    const m=mock([response]);expect(helper('anthropic_get /v1/organizations/me',m).exitCode).not.toBe(0);
  });
  test('HTTP/transport failure cannot be converted to a healthy inventory',()=>{
    const m=mock([{data:[],has_more:false}],22);
    expect(helper('anthropic_list_all /v1/organizations/users',m).exitCode).not.toBe(0);
    expect(helper('fail failure; summary; exit 0',m).exitCode).toBe(1);
  });
  test('all pages are returned; late failure emits no partial list',()=>{
    const first={data:[{id:'user_A'}],has_more:true,last_id:'user_A'};
    const m=mock([first,{data:[{id:'user_B'}],has_more:false}]);
    const r=helper('anthropic_list_all /v1/organizations/users',m);
    expect(r.exitCode).toBe(0);expect(JSON.parse(r.stdout.toString())).toHaveLength(2);
    expect(readFileSync(join(m.dir,'args.1'),'utf8')).toContain('after_id=user_A');
    const late=mock([first,'not json']);const bad=helper('anthropic_list_all /v1/organizations/users',late);
    expect(bad.exitCode).not.toBe(0);expect(bad.stdout.length).toBe(0);
  });
  for(const page of [{data:[]},{data:[],has_more:'false'},{data:[],has_more:true,last_id:null}])test('missing/invalid cursor envelope is not end of list '+JSON.stringify(page),()=>{
    const m=mock([page]);expect(helper('anthropic_list_all /v1/organizations/users',m).exitCode).not.toBe(0);
  });
  test('repeated cursors stop a cycle',()=>{
    const p={data:[],has_more:true,last_id:'user_A'};const m=mock([p,p]);
    expect(helper('anthropic_list_all /v1/organizations/users',m).exitCode).not.toBe(0);
  });
  test('report pagination keeps empty cursor-bearing page and escapes opaque token',()=>{
    const m=mock([{data:[],has_more:true,next_page:'p+/='},{data:[{cost:1}],has_more:false,next_page:null}]);
    const r=helper('anthropic_report_all "/v1/organizations/analytics/cost?limit=1"',m);
    expect(r.exitCode).toBe(0);expect(JSON.parse(r.stdout.toString())).toHaveLength(1);
    expect(readFileSync(join(m.dir,'args.1'),'utf8')).toContain('page=p%2B%2F%3D');
  });
  test('next_page-only rate-limit family is not mistaken for report pagination',()=>{
    const m=mock([{data:[],next_page:'token'},{data:[{type:'workspace_rate_limit'}],next_page:null}]);
    const r=helper('anthropic_page_token_all "/v1/organizations/workspaces/wrkspc_A/rate_limits?include_inherited=true"',m);
    expect(r.exitCode).toBe(0);expect(JSON.parse(r.stdout.toString())).toHaveLength(1);
  });
  test('mutation opt-in is mandatory even if ambient target variables exist',()=>{
    const m=mock([{ok:true}]);const r=helper('anthropic_post /v1/organizations/users/user_A \'{"role":"managed"}\'',m);
    expect(r.exitCode).toBe(2);expect(readdirSync(m.dir)).not.toContain('args.0');
  });
});
describe('sign-out and WIF never claim a broader containment boundary',()=>{
  const sign='packs/claude-enterprise/api/hth-claude-enterprise-1.04-member-sign-out.sh';
  test('sign-out defaults to target read; mutation requires exact confirmation',()=>{
    const member={id:'user_A',type:'user',role:'user'};
    const m=mock([member]);const r=run(sign,{...m.env,HTH_USER_ID:'user_A'});
    expect(r.exitCode).toBe(0);expect(readFileSync(join(m.dir,'count'),'utf8').trim()).toBe('1');
    const denied=mock([member]);expect(run(sign,{...denied.env,HTH_USER_ID:'user_A',HTH_APPLY:'1',HTH_CONFIRM_USER_ID:'user_B'}).exitCode).toBe(2);
  });
  test('primary owner and wrong target are refused',()=>{
    for(const member of [{id:'user_A',type:'user',role:'primary_owner'},{id:'user_B',type:'user',role:'user'}]){
      const m=mock([member]);expect(run(sign,{...m.env,HTH_USER_ID:'user_A',HTH_APPLY:'1',HTH_CONFIRM_USER_ID:'user_A'}).exitCode).not.toBe(0);
      expect(readFileSync(join(m.dir,'count'),'utf8').trim()).toBe('1');
    }
  });
  test('confirmed sign-out uses beta and no body, and reports the residual work',()=>{
    const member={id:'user_A',type:'user',role:'user'},m=mock([member,member]);
    const r=run(sign,{...m.env,HTH_USER_ID:'user_A',HTH_APPLY:'1',HTH_CONFIRM_USER_ID:'user_A'});
    expect(r.exitCode).toBe(0);const args=readFileSync(join(m.dir,'args.1'),'utf8');
    expect(args).toContain('admin-user-sign-out-2026-10-08');expect(args).not.toContain('--data');
    expect(r.stdout.toString()).toContain('cloud sessions and routines may remain');
  });
  const wif='packs/anthropic-claude/api/hth-anthropic-claude-2.03-wif-token-exchange.sh';
  test('present empty key/auth/profile is rejected before reading a token or network',()=>{
    for(const key of ['ANTHROPIC_API_KEY','ANTHROPIC_AUTH_TOKEN','ANTHROPIC_PROFILE']){
      const m=mock([]);expect(run(wif,{...m.env,[key]:''}).exitCode).toBe(2);expect(readdirSync(m.dir)).not.toContain('args.0');
    }
  });
  test('WIF default performs no credential exchange',()=>{
    const m=mock([]);const token=join(m.dir,'identity.jwt');writeFileSync(token,'e30.e30.ZmFrZQ');
    const r=run(wif,{...m.env,ANTHROPIC_FEDERATION_RULE_ID:'fdrl_A',ANTHROPIC_ORGANIZATION_ID:org,ANTHROPIC_IDENTITY_TOKEN_FILE:token});
    expect(r.exitCode).toBe(0);expect(readdirSync(m.dir)).not.toContain('args.0');
  });
});
describe('native Desktop payloads',()=>{
  const pack='packs/claude-enterprise/config/hth-claude-enterprise-3.06-desktop-policy.sh';
  test('macOS emits a parseable separate Desktop profile with narrow folders and no install',()=>{
    const r=run(pack,{HTH_ORGANIZATION_ID:org,HTH_WORKSPACE_FOLDERS:'["/work/approved"]'});
    expect(r.exitCode).toBe(0);
    const p=Bun.spawnSync(['python3','-c','import plistlib,sys,json; print(json.dumps(plistlib.loads(sys.stdin.buffer.read())))'],{stdin:r.stdout});
    expect(p.exitCode).toBe(0);const obj=JSON.parse(p.stdout.toString()).PayloadContent[0];
    expect(obj.PayloadType).toBe('com.anthropic.claudefordesktop');expect(obj.forceLoginOrgUUID).toBe(org);
    expect(obj.allowedWorkspaceFolders).toEqual(['/work/approved']);expect(obj.isLocalDevMcpEnabled).toBe(false);
  });
  test('Windows uses HKLM Claude, escaped JSON list and DWORD values',()=>{
    const r=run(pack,{HTH_ORGANIZATION_ID:org,HTH_WORKSPACE_FOLDERS:JSON.stringify(['C:\\Approved\\work'])},['windows']);
    expect(r.exitCode).toBe(0);const s=r.stdout.toString();
    expect(s).toContain('HKEY_LOCAL_MACHINE\\SOFTWARE\\Policies\\Claude]');expect(s).not.toContain('ClaudeCode');
    expect(s).toContain('"isLocalDevMcpEnabled"=dword:00000000');
    expect(s).toContain('allowedWorkspaceFolders');
  });
  for(const folders of ['[]','["/"]','["relative"]','["/work/*"]','["/work/../secret"]'])test('broad/invalid folder refused '+folders,()=>{
    expect(run(pack,{HTH_ORGANIZATION_ID:org,HTH_WORKSPACE_FOLDERS:folders}).exitCode).not.toBe(0);
  });
  test('optional EDR needs vendor/path pair and never launches installer',()=>{
    expect(run(pack,{HTH_ORGANIZATION_ID:org,HTH_WORKSPACE_FOLDERS:'["/work"]',HTH_EDR_PACKAGE:'/tmp/vendor-package'}).exitCode).not.toBe(0);
    const r=run(pack,{HTH_ORGANIZATION_ID:org,HTH_WORKSPACE_FOLDERS:'["/work"]',HTH_EDR_PACKAGE:'/approved/vendor-package',HTH_EDR_VENDOR:'reviewed-vendor'});
    expect(r.exitCode).toBe(0);expect(r.stdout.toString()).toContain('coworkEDRIntegration');
  });
});
describe('actual pinned official SDK transport',()=>{
  const user=(id:string)=>({id,type:'user',role:'user',email:'fixture@example.invalid',name:'fixture',added_at:'2026-11-05T00:00:00Z'});
  test('native org users route and complete pagination; auth never in URL',async()=>{
    const calls:Request[]=[];
    const transport=async(input:any,init:any)=>{
      const request=new Request(input,init);calls.push(request);
      const a=calls.length===1;
      return Response.json({data:[user(a?'user_A':'user_B')],has_more:a,last_id:a?'user_A':'user_B',first_id:a?'user_A':'user_B'});
    };
    const result=await inventory('sk-ant-test-NOT-A-CREDENTIAL',transport);
    expect(result).toHaveLength(2);expect(calls[0].url).toStartWith('https://api.anthropic.com/v1/organizations/users?');
    expect(calls[1].url).toContain('after_id=user_A');expect(calls[0].url).not.toContain('sk-ant');
    expect(calls[0].headers.get('authorization')).toBe('Bearer sk-ant-test-NOT-A-CREDENTIAL');
  });
  test('late native SDK HTTP failure discards partial result and does not retry',async()=>{
    let count=0;const transport=async()=>++count===1?Response.json({data:[user('user_A')],has_more:true,last_id:'user_A'}):Response.json({type:'error',error:{type:'permission_error',message:'fixture'}},{status:403});
    await expect(inventory('sk-ant-test',transport)).rejects.toThrow();expect(count).toBe(2);
  });
  test('invalid/repeated member cannot produce healthy evidence',async()=>{
    await expect(inventory('sk-ant-test',async()=>Response.json({data:[user('user_A'),user('user_A')],has_more:false}))).rejects.toThrow();
  });
  test('native SDK missing boolean/cursor metadata fails instead of silently truncating',async()=>{
    for(const p of [{data:[]},{data:[],has_more:'false'},{data:[],has_more:true,last_id:null}])
      await expect(inventory('sk-ant-test',async()=>Response.json(p))).rejects.toThrow();
  });
});
describe('existing and newly emitted native configs',()=>{
  const dir=join(root,'packs/anthropic-claude/config');
  const entries=readdirSync(dir).filter(x=>x.endsWith('.jsonc'));
  for(const file of entries)test('every executable JSON excerpt parses: '+file,()=>{
    const source=readFileSync(join(dir,file),'utf8');
    for(const m of source.matchAll(/\/\/ HTH Guide Excerpt: begin ([^\n]+)\n([\s\S]*?)\/\/ HTH Guide Excerpt: end \1/g)){
      const text=m[2].replace(/^\s*\/\/.*$/gm,'').trim();if(!text)continue;
      const json=JSON.parse(text);expect(typeof json).toBe('object');
      expect(json.sandbox?.excludedCommands??[]).toEqual([]);
      expect(json).not.toHaveProperty('disableBypassPermissionsMode');
    }
  });
  test('Managed Agents has no shell/write tool enabled or wildcard egress',()=>{
    const source=readFileSync(join(dir,'hth-anthropic-claude-4.02-managed-agents.jsonc'),'utf8');
    const chunks=[...source.matchAll(/begin [^\n]+\n([\s\S]*?)\/\/ HTH Guide Excerpt: end/g)].map(m=>JSON.parse(m[1].replace(/^\s*\/\/.*$/gm,'')));
    expect(chunks[0].tools[0].default_config.enabled).toBe(false);
    expect(chunks[0].tools[0].configs.map((x:any)=>x.name)).toEqual(['read','web_fetch']);
    expect(chunks[1].config.networking.type).toBe('limited');
    expect(chunks[1].config.networking.allow_package_managers).toBe(false);
  });
});

describe('real pack evidence and native pagination families',()=>{
  test('effective-settings pack writes private evidence, distinct unknown/different/match exits',()=>{
    for (const [rows,code] of [[[],2],[[{name:'sso_enabled',type:'boolean',value:false}],1],[[{name:'sso_enabled',type:'boolean',value:true}],0]] as const){
      const m=mock([payload(rows as any[])]), f=join(m.dir,'baseline.json');writeFileSync(f,JSON.stringify(baseline()));
      const r=run('packs/claude-enterprise/api/hth-claude-enterprise-2.04-effective-settings.sh',{...m.env,ANTHROPIC_COMPLIANCE_ACCESS_KEY:'sk-ant-compliance-fixture',HTH_ORGANIZATION_ID:org,HTH_BASELINE_FILE:f});
      expect(r.exitCode).toBe(code);const output=r.stdout.toString();expect(output).not.toContain('sk-ant-');
      const dir=output.match(/Private evidence: ([^ ]+)/)?.[1];expect(dir).toBeDefined();
      expect(statSync(dir!).mode&0o777).toBe(0o700);expect(statSync(join(dir!,'assessment.json')).mode&0o077).toBe(0);
      expect(JSON.parse(readFileSync(join(dir!,'assessment.json'),'utf8')).native_security_center).toBe(false);
    }
  });
  test('native role and permission resources use page tokens, not member cursors',()=>{
    const m=mock([{data:[{id:'user_A',type:'user',role:'managed'}],has_more:false},{data:[{id:'rbac_role_A',type:'rbac_role'}],next_page:'opaque+/ role'},{data:[],next_page:null},{data:[{action:'capability_access_all',resource:{type:'organization'}}],next_page:null}]);
    const r=run('packs/claude-enterprise/api/hth-claude-enterprise-1.03-member-roles.sh',m.env);expect(r.exitCode).toBe(0);
    expect(readFileSync(join(m.dir,'args.2'),'utf8')).toContain('/v1/organizations/rbac_roles?page=opaque%2B%2F%20role');
    expect(readFileSync(join(m.dir,'args.3'),'utf8')).toContain('/v1/organizations/rbac_roles/rbac_role_A/permissions');
  });
  test('opaque activity cursors are encoded without interpreting their content',()=>{
    const m=mock([{data:[{id:'a'}],has_more:true,last_id:'opaque+/ activity|cursor'},{data:[{id:'b'}],has_more:false}]);
    const r=helper('anthropic_list_all /v1/compliance/activities',m);expect(r.exitCode).toBe(0);
    expect(readFileSync(join(m.dir,'args.1'),'utf8')).toContain('after_id=opaque%2B%2F%20activity%7Ccursor');
  });
  test('empty page-token is malformed, not a terminal null',()=>{
    expect(helper('anthropic_page_token_all /v1/organizations/rbac_roles',mock([{data:[],next_page:''}])).exitCode).not.toBe(0);
  });
  test('spend sweep does not equate null, zero, future periods or empty results',()=>{
    const row={scope:{type:'user',user_id:'user_A'},amount:'0',period:'monthly',currency:'USD'};
    for(const [data,exit]of [[[row],0],[[{...row,amount:null}],1],[[],2],[[{...row,period:'future'}],2],[[row,row],2]] as const){
      const m=mock([{data,next_page:null}]);const r=run('packs/claude-enterprise/api/hth-claude-enterprise-4.01-effective-spend-limits.sh',m.env);expect(r.exitCode).toBe(exit);
    }
  });
  test('fractional cents preserved in complete usage/cost evidence, beta is explicit',()=>{
    const m=mock([{data:[{group:{workspace_id:'wrkspc_A'},usage:{total_tokens:11}}],has_more:false,next_page:null},{data:[{group:{workspace_id:'wrkspc_A'},cost:{currency:'USD',amount:'12.345'}}],has_more:false,next_page:null}]);
    const r=run('packs/anthropic-claude/api/hth-anthropic-claude-5.01-monitor-usage-and-costs.sh',{...m.env,HTH_STARTING_AT:'2026-11-01T00:00:00Z',HTH_ENDING_AT:'2026-11-02T00:00:00Z'});
    expect(r.exitCode).toBe(0);expect(r.stdout.toString()).toContain('fractional CENTS');expect(readFileSync(join(m.dir,'args.0'),'utf8')).toContain('analytics-usage-cost-2026-08-24');
  });
});
describe('native CLI stream boundary',()=>{
  function fakeAnt(output:string,exit=0){
    const dir=mkdtempSync(join(tmpdir(),'hth-ant-test-'));
    writeFileSync(join(dir,'fixture'),output);
    writeFileSync(join(dir,'ant'),`#!/usr/bin/env bash\nset -euo pipefail\ncat > "$MOCK_DIR/key"\nprintf '%s\\n' "$@" > "$MOCK_DIR/args"\nprintf '%s|%s|%s' "\${ANTHROPIC_AUTH_TOKEN-unset}" "\${ANTHROPIC_PROFILE-unset}" "\${ANTHROPIC_CONFIG_DIR-unset}" > "$MOCK_DIR/env"\ncat "$MOCK_DIR/fixture"\nexit ${exit}\n`,{mode:0o700});
    return {dir,env:{PATH:`${dir}:${process.env.PATH}`,MOCK_DIR:dir,ANTHROPIC_ADMIN_KEY:'sk-ant-stdin-fixture',ANTHROPIC_AUTH_TOKEN:'shadow-fixture',ANTHROPIC_PROFILE:'other-tenant-fixture',ANTHROPIC_CONFIG_DIR:'/tmp/untrusted-config-fixture'}};
  }
  const item={type:'user',id:'user_A',role:'user'};
  test('actual ant 2.7.0 JSON-object stream is normalized and ambient profiles cleared',()=>{
    const m=fakeAnt(JSON.stringify(item)+'\n'+JSON.stringify({...item,id:'user_B'}));
    const r=run('packs/claude-enterprise/cli/hth-claude-enterprise-1.03-member-inventory.sh',m.env);expect(r.exitCode).toBe(0);
    expect(readFileSync(join(m.dir,'key'),'utf8')).toBe(m.env.ANTHROPIC_ADMIN_KEY);
    expect(readFileSync(join(m.dir,'args'),'utf8')).not.toContain(m.env.ANTHROPIC_ADMIN_KEY);
    expect(readFileSync(join(m.dir,'args'),'utf8')).toContain('organization:users');
    expect(readFileSync(join(m.dir,'env'),'utf8')).toStartWith('unset|unset|');
    const f=r.stdout.toString().trim().split(': ').at(-1)!;expect(JSON.parse(readFileSync(f,'utf8'))).toHaveLength(2);
    expect(statSync(f).mode&0o077).toBe(0);
  });
  for(const [label,output,exit]of [['duplicate',JSON.stringify(item)+'\n'+JSON.stringify(item),0],['old array assumption',JSON.stringify([item]),0],['wrong resource',JSON.stringify({...item,type:'workspace'}),0],['late failure',JSON.stringify(item),1]] as const)test(label+' cannot emit success evidence',()=>{
    const m=fakeAnt(output,exit);const r=run('packs/claude-enterprise/cli/hth-claude-enterprise-1.03-member-inventory.sh',m.env);expect(r.exitCode).not.toBe(0);expect(r.stdout.toString()).not.toContain('Private CLI inventory');
  });
});

describe('additional actual official SDK surfaces',()=>{
  test('workspace native request includes Default Workspace and rejects truncated metadata',async()=>{
    const {workspaceInventory}=await import('../packs/anthropic-claude/sdk/hth-anthropic-claude-3.01-workspace-inventory.js');
    const calls:Request[]=[];
    const result=await workspaceInventory('sk-ant-fixture',async(input:any,init:any)=>{const r=new Request(input,init);calls.push(r);return Response.json({data:[{type:'workspace',id:'wrkspc_A',data_residency:{workspace_geo:'us'}}],has_more:false});});
    expect(result).toHaveLength(1);expect(calls[0].url).toContain('/v1/organizations/workspaces?');expect(calls[0].url).toContain('include_default=true');
    await expect(workspaceInventory('sk-ant-fixture',async()=>Response.json({data:[]}))).rejects.toThrow();
  });
  test('spend native PageCursor keeps null/zero and encodes opaque page, never silently truncates',async()=>{
    const {spendInventory}=await import('../packs/claude-enterprise/sdk/hth-claude-enterprise-4.01-spend-limits.js');let count=0;const calls:Request[]=[];
    const rows=await spendInventory('sk-ant-fixture',async(input:any,init:any)=>{calls.push(new Request(input,init));return Response.json({data:[{scope:{type:'user',user_id:'user_'+(++count)},period:'monthly',amount:count===1?null:'0'}],next_page:count===1?'opaque +/page':null});});
    expect(rows.map((r:any)=>r.amount)).toEqual([null,'0']);expect(new URL(calls[1].url).searchParams.get('page')).toBe('opaque +/page');
    await expect(spendInventory('sk-ant-fixture',async()=>Response.json({data:[]}))).rejects.toThrow();
  });
  test('Managed Agents fragments use separate native SDK routes and request bodies',async()=>{
    const {scopedClient}=await import('../packs/claude-enterprise/sdk/lib/native.js');const requests:Request[]=[],bodies:any[]=[];
    const client=scopedClient('sk-ant-fixture',async(input:any,init:any)=>{const r=new Request(input,init);requests.push(r);bodies.push(await r.clone().json());return Response.json({id:'fixture',type:'fixture'});});
    const source=readFileSync(join(root,'packs/anthropic-claude/config/hth-anthropic-claude-4.02-managed-agents.jsonc'),'utf8');
    const fragments=[...source.matchAll(/\/\/ HTH Guide Excerpt: begin [^\n]+\n([\s\S]*?)\/\/ HTH Guide Excerpt: end/g)].map(m=>JSON.parse(m[1].replace(/^\s*\/\/.*$/gm,'')));
    await client.beta.agents.create({...fragments[0],betas:['managed-agents-2026-04-01']});
    await client.beta.environments.create({...fragments[1],betas:['managed-agents-2026-04-01']});
    expect(new URL(requests[0].url).pathname).toBe('/v1/agents');expect(new URL(requests[1].url).pathname).toBe('/v1/environments');
    expect(bodies[0]).toEqual(fragments[0]);expect(bodies[1]).toEqual(fragments[1]);expect(requests[0].headers.get('anthropic-beta')).toContain('managed-agents-2026-04-01');
  });
  test('residency pack never passes an empty inventory or equates storage geo with constrained inference',()=>{
    const path='packs/anthropic-claude/api/hth-anthropic-claude-4.01-enforce-data-residency.sh';
    expect(run(path,mock([{data:[],has_more:false}]).env).exitCode).toBe(2);
    const m=mock([{data:[{type:'workspace',id:'wrkspc_A',data_residency:{workspace_geo:'us',allowed_inference_geos:'unrestricted'}}],has_more:false}]);const r=run(path,m.env);
    expect(r.exitCode).toBe(0);expect(r.stdout.toString()).toContain('no residency pass asserted');expect(readFileSync(join(m.dir,'args.0'),'utf8')).toContain('include_default=true');
  });
});

test('each standalone Python WIF excerpt rejects empty shadow credentials/profile before importing the SDK',()=>{
  const source=readFileSync(join(root,'packs/anthropic-claude/sdk/hth-anthropic-claude-2.03-wif-python.py'),'utf8');
  const excerpts=[...source.matchAll(/# HTH Guide Excerpt: begin [^\n]+\n([\s\S]*?)# HTH Guide Excerpt: end/g)].map(m=>m[1]);
  expect(excerpts).toHaveLength(2);
  for(const excerpt of excerpts)for(const variable of ['ANTHROPIC_API_KEY','ANTHROPIC_AUTH_TOKEN','ANTHROPIC_PROFILE']){
    const r=Bun.spawnSync(['python3','-c',excerpt],{env:{...cleanEnv(),[variable]:''},timeout:10000});expect(r.exitCode).not.toBe(0);expect(r.stderr.toString()).toContain(variable);expect(r.stderr.toString()).not.toContain('ModuleNotFoundError');
  }
});

describe('recording singleton is separate from effective settings and native posture',()=>{
  test('REST records enabled/disabled distinctly and unknown never passes',()=>{
    for(const [body,exit]of [[{type:'compliance_settings',state:{type:'enabled'}},0],[{type:'compliance_settings',state:{type:'disabled'}},1],[{type:'compliance_settings',state:{type:'future'}},2],[{type:'compliance_settings'},2]] as const){
      const m=mock([body]);const r=run('packs/claude-enterprise/api/hth-claude-enterprise-2.02-recording-state.sh',m.env);expect(r.exitCode).toBe(exit);expect(readFileSync(join(m.dir,'args.0'),'utf8')).toContain('/v1/organizations/compliance_settings');expect(readFileSync(join(m.dir,'args.0'),'utf8')).not.toContain('/v1/compliance/organizations/');
    }
  });
  test('actual official SDK calls the recording singleton, not effective-setting or posture endpoints',async()=>{
    const {recordingState}=await import('../packs/claude-enterprise/sdk/hth-claude-enterprise-2.02-recording-state.js');const calls:Request[]=[];
    const r=await recordingState('sk-ant-fixture',async(input:any,init:any)=>{calls.push(new Request(input,init));return Response.json({type:'compliance_settings',state:{type:'disabled'}});});
    expect(r.state.type).toBe('disabled');expect(new URL(calls[0].url).pathname).toBe('/v1/organizations/compliance_settings');expect(calls[0].method).toBe('GET');
    await expect(recordingState('sk-ant-fixture',async()=>Response.json({type:'compliance_settings',state:{type:'future'}}))).rejects.toThrow();
  });
  test('native CLI uses retrieve without list pagination flags and validates singleton state',()=>{
    for(const state of ['enabled','disabled','future']){
      const dir=mkdtempSync(join(tmpdir(),'hth-ant-recording-'));writeFileSync(join(dir,'fixture'),JSON.stringify({type:'compliance_settings',state:{type:state}}));
      writeFileSync(join(dir,'ant'),'#!/usr/bin/env bash\ncat >/dev/null\nprintf "%s\\n" "$@" > "$MOCK_DIR/args"\ncat "$MOCK_DIR/fixture"\n',{mode:0o700});
      const r=run('packs/claude-enterprise/cli/hth-claude-enterprise-2.02-recording-state.sh',{PATH:`${dir}:${process.env.PATH}`,MOCK_DIR:dir,ANTHROPIC_ADMIN_KEY:'sk-ant-fixture'});
      expect(r.exitCode===0).toBe(state==='enabled');const args=readFileSync(join(dir,'args'),'utf8');expect(args).toContain('organization:compliance-settings\nretrieve');expect(args).not.toContain('--max-items');
    }
  });
});
