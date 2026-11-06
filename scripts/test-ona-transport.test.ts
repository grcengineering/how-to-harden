// Offline Ona transport tests: curl is replaced; no credentials or tenant calls.
import { afterAll, describe, expect, test } from 'bun:test';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, readdirSync, existsSync, rmSync, statSync, symlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

const repo=resolve(import.meta.dir,'..');
const api=join(repo,'packs/ona/api');
const files=readdirSync(api).filter(n=>/^hth-ona-.*\.sh$/.test(n)).sort();
const work=mkdtempSync(join(tmpdir(),'hth-ona-transport-tests-'));
const bin=join(work,'bin');mkdirSync(bin,{mode:0o700});
const actualJq=Bun.spawnSync(['which','jq']).stdout.toString().trim();
const path=process.env.PATH??'/usr/bin:/bin';
const credential='fixture-ona-bearer-do-not-print';
const organization='b0e12f6c-4c67-429d-a4a6-d9838b5da047';

// The fake records argv and stdin separately, checks staging permissions while
// files exist, and returns method-specific native protobuf-JSON fixtures.
writeFileSync(join(bin,'curl'),`#!/usr/bin/env bun
import {readFileSync,writeFileSync,appendFileSync,existsSync,statSync} from 'node:fs';
import {dirname} from 'node:path';
const args=process.argv.slice(2), config=await Bun.stdin.text(), url=args.at(-1);
const method=url.split('/gitpod.v1.')[1];
const output=args[args.indexOf('--output')+1], data=args[args.indexOf('--data-binary')+1];
const request=JSON.parse(readFileSync(data.slice(1),'utf8'));
const old=existsSync(process.env.ONA_MOCK_LOG)?readFileSync(process.env.ONA_MOCK_LOG,'utf8').trim().split('\\n').filter(Boolean).map(JSON.parse):[];
const count=old.filter(x=>x.method===method).length;
appendFileSync(process.env.ONA_MOCK_LOG,JSON.stringify({args,config,url,method,request,
 directoryMode:statSync(dirname(output)).mode&511,requestMode:statSync(data.slice(1)).mode&511,
 responseMode:statSync(output).mode&511})+'\\n');
const responses=JSON.parse(readFileSync(process.env.ONA_MOCK_FIXTURE,'utf8'));
let entry=responses[method];if(Array.isArray(entry))entry=entry[Math.min(count,entry.length-1)];
if(!entry)entry={body:{}};
writeFileSync(output,typeof entry.body==='string'?entry.body:JSON.stringify(entry.body??{}));
if(entry.noise)process.stderr.write(entry.noise);
process.stdout.write(String(entry.status??200));
process.exit(entry.exit??0);
`,{mode:0o700});

// Log external jq arguments only. Secret values should have become raw/slurp
// files inside the helper before crossing this process boundary.
writeFileSync(join(bin,'jq'),`#!/usr/bin/env bash
if [[ -n "\${ONA_MOCK_JQ_LOG:-}" ]]; then
  printf '%s\\0' "$@" >> "$ONA_MOCK_JQ_LOG"
fi
exec "$ONA_REAL_JQ" "$@"
`,{mode:0o700});
afterAll(()=>rmSync(work,{recursive:true,force:true}));
let sequence=0;

const goodPolicies={restrictAccountCreationToScim:true,securityPolicyId:'fixture-policy',
  agentPolicy:{commandDenyList:['credential-reader'],mcpDisabled:true,scmToolsDisabled:true},
  webBrowserDisabled:true,maximumEnvironmentLifetime:'86400s',maximumEnvironmentTimeout:'1800s',
  maximumEnvironmentLifetimeStrict:true,disableFromScratch:true,membersRequireProjects:true,
  maxPortAdmissionLevel:'ADMISSION_LEVEL_CREATOR_ONLY',securityAgentPolicy:{crowdstrike:{enabled:true}}};
function defaults():Record<string,unknown>{return {
  'IdentityService/GetAuthenticatedIdentity':{body:{organizationId:organization,organizationTier:'ORGANIZATION_TIER_ENTERPRISE'}},
  'OrganizationService/GetOrganizationPolicies':{body:{policies:goodPolicies}},
  'OrganizationService/GetOrganization':{body:{organization:{id:organization}}},
  'OrganizationService/GetOrganizationInvite':{status:404,body:{code:'not_found'}},
  'OrganizationService/GetOIDCConfig':{body:{oidcConfig:{v3:{extraSubFields:['project_id']}}}},
};}
type Result={code:number,stdout:string,stderr:string,calls:any[],jqArgs:string,stagingRemaining:string[]};
async function run(name:string, overrides:Record<string,unknown>={}, args:string[]=[], extra:Record<string,string>={}):Promise<Result>{
  const dir=join(work,String(++sequence));mkdirSync(dir,{mode:0o700});
  const log=join(dir,'calls'),fixture=join(dir,'responses'),jqLog=join(dir,'jq-args');
  writeFileSync(fixture,JSON.stringify({...defaults(),...overrides}),{mode:0o600});
  const env:Record<string,string>={PATH:bin+':'+path,TMPDIR:dir,HTH_PROFILE_LEVEL:'4',ONA_TOKEN:credential,
    ONA_ORGANIZATION_ID:organization,ONA_MOCK_LOG:log,ONA_MOCK_FIXTURE:fixture,ONA_REAL_JQ:actualJq,
    ONA_MOCK_JQ_LOG:jqLog,ONA_AUDIT_FROM:'2026-11-01T00:00:00Z',ONA_AUDIT_TO:'2026-11-02T00:00:00Z',...extra};
  const command=name==='helper'?['bash','-c',args[0],'-',join(api,'common.sh')]:['bash',join(api,name),...args];
  const proc=Bun.spawn(command,{cwd:repo,env,stdout:'pipe',stderr:'pipe'});
  const [code,stdout,stderr]=await Promise.all([proc.exited,new Response(proc.stdout).text(),new Response(proc.stderr).text()]);
  return {code,stdout,stderr,calls:existsSync(log)?readFileSync(log,'utf8').trim().split('\n').filter(Boolean).map(x=>JSON.parse(x)):[],
    jqArgs:existsSync(jqLog)?readFileSync(jqLog,'utf8'):'',stagingRemaining:readdirSync(dir).filter(n=>n.startsWith('hth-ona.'))};
}
const select=(prefix:string)=>files.find(n=>n.startsWith('hth-ona-'+prefix+'-'))!;

describe('Ona transport boundary',()=>{
  test('all 20 default entrypoints use private fixed-origin read transports and complete verdicts',async()=>{
    expect(files).toHaveLength(20);
    for(const file of files){
      const r=await run(file);
      expect([0,1],file+' '+r.stderr).toContain(r.code);
      expect(r.calls.length,file).toBeGreaterThan(0);
      expect(r.stagingRemaining,file).toEqual([]);
      expect(r.stdout+r.stderr,file).not.toContain(credential);
      expect(r.jqArgs,file).not.toContain(credential);
      for(const call of r.calls){
        expect(call.url).toStartWith('https://app.gitpod.io/api/gitpod.v1.');
        expect(call.method).toMatch(/\/(Get|List|Check)/);
        expect(call.args[0]).toBe('-q');
        expect(call.args).not.toContain('-L');expect(call.args).not.toContain('--location');
        expect(call.args).not.toContain('--insecure');expect(call.args).not.toContain('-k');
        expect(call.args).toContain('--max-time');expect(call.args).toContain('--max-filesize');
        expect(call.args.join(' ')).not.toContain(credential);
        expect(call.config).toContain('Authorization: Bearer '+credential);
        expect(call.directoryMode).toBe(0o700);expect(call.requestMode).toBe(0o600);expect(call.responseMode).toBe(0o600);
      }
    }
  },120000);

  test('minimum profile, credential controls, and unreviewed/unsafe bases fail before requests',async()=>{
    const unsafe=['http://custom.example/api','https://user:pass@custom.example/api','https://custom.example/api?token=x',
      'https://custom.example/api#fragment','https://custom.example/api/','https://custom.example:0/api','https://custom.example:65536/api',
      'https://custom.example/api','https://custom.example/api\\evil'];
    for(const base of unsafe){const r=await run(select('2.03'),{},[],{ONA_API_BASE:base});expect(r.code).toBe(2);expect(r.calls).toEqual([]);expect(r.stdout).toBe('');}
    for(const extra of [{HTH_PROFILE_LEVEL:'1'},{HTH_PROFILE_LEVEL:'x'},{ONA_TOKEN:'fixture\nheader-injection'},{ONA_TOKEN:''},{ONA_MAX_PAGES:'201'}]){
      const r=await run(select('2.03'),{},[],extra);expect(r.code).toBe(2);expect(r.calls).toEqual([]);expect(r.stdout).toBe('');
    }
    const r=await run(select('2.03'),{},[],{ONA_API_BASE:'https://reviewed.example.test:8443/api',ONA_REVIEWED_API_BASE:'https://reviewed.example.test:8443/api'});
    expect(r.code).toBe(0);expect(r.calls.every(c=>c.url.startsWith('https://reviewed.example.test:8443/api/'))).toBe(true);
  },30000);

  test('jq string and JSON bindings plus curl body carry no secret process arguments',async()=>{
    const code='source "$1"; ona_init 1; request=$(jq -nc --arg token "$ONA_TOKEN" --argjson other "{\\\"secret\\\":\\\"$ONA_TOKEN\\\"}" \'{token:$token,other:$other}\'); api_strict OrganizationService/GetOrganizationPolicies "$request"; ona_complete';
    const r=await run('helper',{},[code]);expect(r.code,r.stderr).toBe(0);
    expect(r.jqArgs).not.toContain(credential);expect(r.calls[0].args.join(' ')).not.toContain(credential);
    expect(r.calls[0].request).toEqual({token:credential,other:{secret:credential}});
    expect(r.stdout+r.stderr).not.toContain(credential);
    const invalid=await run('helper',{},['source "$1"; ona_init 1; value=$(jq -nc --argjson bad "{} {}" \'$bad\'); ona_complete']);
    expect(invalid.code).toBe(2);expect(invalid.calls).toEqual([]);expect(invalid.stdout).toBe('');
  },30000);

  test('redirect/auth/server/transport errors are redacted and publish no partial evidence',async()=>{
    for(const response of [{status:308,body:'redirect '+credential},{status:401,body:{code:'unauthenticated',message:credential}},
      {status:403,body:{code:credential,message:credential}},{status:500,body:{code:'internal',message:credential}},
      {exit:7,status:200,body:{policies:goodPolicies},noise:credential}]){
      const r=await run(select('2.03'),{'OrganizationService/GetOrganizationPolicies':response});
      expect(r.code).toBe(2);expect(r.calls).toHaveLength(1);expect(r.stdout).toBe('');
      expect(r.stderr).not.toContain(credential);expect(r.stagingRemaining).toEqual([]);
    }
  },30000);

  test('malformed success envelopes and string Boolean spoofing are never compliance',async()=>{
    for(const body of ['not-json','{} {}',[],{code:'permission_denied',message:credential},{policies:{agentPolicy:{mcpDisabled:'true'}}}]){
      const r=await run(select('2.03'),{'OrganizationService/GetOrganizationPolicies':{body}});
      expect(r.code).toBe(2);expect(r.stdout).toBe('');expect(r.stderr).not.toContain(credential);
    }
  },30000);
  test('unexpected exit and missing required resource messages cannot publish a success artifact',async()=>{
    const interrupted=await run('helper',{},['source "$1"; ona_init 1; printf "partial-fixture"; false']);
    expect(interrupted.code).toBe(2);expect(interrupted.stdout).toBe('');expect(interrupted.stagingRemaining).toEqual([]);
    for(const overrides of [
      {'OrganizationService/GetOrganization':{body:{}}},
      {'OrganizationService/GetOrganizationInvite':{body:{}}},
      {'OrganizationService/GetOrganizationInvite':{status:403,body:{code:'permission_denied',message:credential}}},
    ]){const r=await run(select('1.05'),overrides);expect(r.code).toBe(2);expect(r.stdout).toBe('');expect(r.stderr).not.toContain(credential);}
    const notVerified=await run(select('1.05'),{'OrganizationService/GetOrganization':{body:{}}},['--clear-invite-domains']);
    expect(notVerified.code).toBe(2);expect(notVerified.stdout).toBe('');
  },30000);
  test('nonempty runner fanout strips endpoint userinfo and redacts reach-probe error text',async()=>{
    const runners={body:{runners:[{runnerId:'fixture-runner',status:{phase:'RUNNER_PHASE_ACTIVE'}}]}};
    const llm=await run(select('2.04'),{'RunnerService/ListRunners':runners,
      'RunnerConfigurationService/ListLLMIntegrations':{body:{integrations:[{endpoint:'https://user:'+credential+'@provider.example.test/path?key='+credential}]}}});
    expect(llm.code,llm.stderr).toBe(0);expect(llm.stdout).toContain('endpointHost=provider.example.test');
    expect(llm.stdout+llm.stderr+llm.jqArgs).not.toContain(credential);
    const scm=await run(select('4.03'),{'RunnerService/ListRunners':runners,
      'RunnerConfigurationService/ListSCMIntegrations':{body:{integrations:[{host:'github.example.test',scmId:'fixture-scm',oauth:{}}]}},
      'RunnerService/CheckAuthenticationForHost':{body:{supportsOauth2:{}}},
      'RunnerService/CheckRepositoryAccess':{body:{hasAccess:false,errorMessage:credential}}},['--check-repo','https://github.example.test/org/repo']);
    expect(scm.code,scm.stderr).toBe(0);expect(scm.calls.map(c=>c.method)).toContain('RunnerService/CheckRepositoryAccess');
    expect(scm.stdout).toContain('vendor message withheld');expect(scm.stdout+scm.stderr+scm.jqArgs).not.toContain(credential);
  },30000);
  test('optional private output commits only complete evidence, refuses existing/symlink and unsafe parents',async()=>{
    const parent=join(work,'private-output');mkdirSync(parent,{mode:0o700});
    const target=join(parent,'complete.json');
    const good=await run(select('4.01'),{},[],{ONA_OUTPUT:target});
    expect(good.code,good.stderr).toBe(0);expect(good.stdout).toStartWith('COMPLETE:');
    expect(statSync(target).mode&0o777).toBe(0o600);expect(readFileSync(target,'utf8')).toContain('no organization-scoped secrets');
    const link=join(parent,'symlink');symlinkSync(target,link);
    for(const output of [target,link]){const r=await run(select('4.01'),{},[],{ONA_OUTPUT:output});expect(r.code).toBe(2);expect(r.calls).toEqual([]);}
    const failedPath=join(parent,'failed.json');
    const bad=await run(select('4.01'),{'SecretService/ListSecrets':{status:403,body:{code:'permission_denied'}}},[],{ONA_OUTPUT:failedPath});
    expect(bad.code).toBe(2);expect(existsSync(failedPath)).toBe(false);expect(bad.stdout).toBe('');
    const unsafe=join(work,'public-output');mkdirSync(unsafe,{mode:0o755});
    const refused=await run(select('4.01'),{},[],{ONA_OUTPUT:join(unsafe,'refused.json')});
    expect(refused.code).toBe(2);expect(refused.calls).toEqual([]);
  },30000);
});

describe('Ona pagination and publication',()=>{
  test('proto3 omitted empty lists are valid and findings retain exit 1',async()=>{
    const r=await run(select('1.01'));expect(r.code).toBe(1);expect(r.stdout).toContain('FINDING:');expect(r.stderr).toBe('');
    const inventory=await run(select('4.01'));expect(inventory.code).toBe(0);expect(inventory.stdout).toContain('no organization-scoped secrets');
  },30000);
  test('multiple pages preserve native cursors privately and include all metadata',async()=>{
    const cursor='sensitive-cursor-not-an-argv';
    const r=await run(select('4.01'),{'SecretService/ListSecrets':[
      {body:{secrets:[{name:'first'}],pagination:{nextToken:cursor}}},{body:{secrets:[{name:'second'}]}}]});
    expect(r.code,r.stderr).toBe(0);expect(r.calls).toHaveLength(2);expect(r.calls[1].request.pagination.token).toBe(cursor);
    expect(r.stdout).toContain('first');expect(r.stdout).toContain('second');
    expect(r.jqArgs).not.toContain(cursor);expect(r.calls.map(c=>c.args.join(' ')).join('')).not.toContain(cursor);
  },30000);
  test('bad pages, repeated cursors and ceilings discard all pages rather than pass a truncated inventory',async()=>{
    const cases=[{responses:[{body:{secrets:'wrong'}}]},
      {responses:[{body:{secrets:false}}]},
      {responses:[{body:{secrets:[],pagination:{nextToken:false}}}]},
      {responses:[{body:{secrets:[{name:'partial'}],pagination:{nextToken:7}}}]},
      {responses:[{body:{secrets:[{name:'partial'}],pagination:{nextToken:'again'}}},{body:{pagination:{nextToken:'again'}}}]},
      {responses:[{body:{secrets:[{name:'partial'}],pagination:{nextToken:'more'}}}],extra:{ONA_MAX_PAGES:'1'}}];
    for(const item of cases){const r=await run(select('4.01'),{'SecretService/ListSecrets':item.responses},[],item.extra??{});
      expect(r.code).toBe(2);expect(r.stdout).toBe('');expect(r.stagingRemaining).toEqual([]);}
  },30000);
  test('nested inventory failure suppresses an earlier otherwise-compliant policy observation',async()=>{
    const r=await run(select('2.03'),{'IntegrationService/ListIntegrations':{status:403,body:{code:'permission_denied',message:credential}}});
    expect(r.code).toBe(2);expect(r.stdout).toBe('');expect(r.stderr).not.toContain(credential);
  },30000);
  test('audit export publishes clean complete NDJSON but never partial data or a checkpoint on late failure',async()=>{
    const entries=[{kind:'AUDIT_LOG_ENTRY_KIND_ENVIRONMENT_VETO',fixture:'veto'},{kind:'OTHER',fixture:'other'}];
    const successful=await run(select('6.01'),{'EventService/ListAuditLogs':[
      {body:{}},{body:{entries:[entries[0]],pagination:{nextToken:'next'}}},{body:{entries:[entries[1]]}}]},['--veto-only']);
    expect(successful.code,successful.stderr).toBe(0);expect(successful.stdout.trim().split('\n').map(s=>JSON.parse(s))).toEqual([entries[0]]);
    expect(successful.stderr).toContain("ONA_AUDIT_FROM='2026-11-02T00:00:00Z'");
    const failed=await run(select('6.01'),{'EventService/ListAuditLogs':[
      {body:{}},{body:{entries:[entries[0]],pagination:{nextToken:'next'}}},{status:503,body:{code:'unavailable',message:credential}}]});
    expect(failed.code).toBe(2);expect(failed.stdout).toBe('');expect(failed.stderr).not.toContain('exported ');expect(failed.stderr).not.toContain('next run:');
  },30000);
});

describe('Ona explicit mutation branches',()=>{
  test('domain creation and verification preserve explicit operations and public DNS instructions',async()=>{
    const created=await run(select('1.01'),{'OrganizationService/CreateDomainVerification':{body:{domainVerification:{id:organization,
      state:'DOMAIN_VERIFICATION_STATE_PENDING',verificationToken:'public-dns-txt-fixture'}}}},['--apply-domain','example.test']);
    expect(created.code,created.stderr).toBe(0);expect(created.calls).toHaveLength(1);expect(created.calls[0].method).toBe('OrganizationService/CreateDomainVerification');
    expect(created.calls[0].request).toEqual({organizationId:organization,domain:'example.test'});expect(created.stdout).toContain('public-dns-txt-fixture');
    const verified=await run(select('1.01'),{'OrganizationService/VerifyDomain':{body:{domainVerification:{state:'DOMAIN_VERIFICATION_STATE_VERIFIED'}}}},['--verify-domain',organization]);
    expect(verified.code,verified.stderr).toBe(0);expect(verified.calls[0].method).toBe('OrganizationService/VerifyDomain');expect(verified.stdout).toContain('DOMAIN_VERIFICATION_STATE_VERIFIED');
  },30000);
  test('invite writes retain readback and never print the join credential',async()=>{
    const cleared=await run(select('1.05'),{},['--clear-invite-domains']);expect(cleared.code,cleared.stderr).toBe(0);
    expect(cleared.calls.map(c=>c.method)).toEqual(['OrganizationService/UpdateOrganization','OrganizationService/GetOrganization']);
    const rotated=await run(select('1.05'),{'OrganizationService/CreateOrganizationInvite':{body:{invite:{inviteId:credential}}}},['--reset-invite-link']);
    expect(rotated.code).toBe(0);expect(rotated.stdout).toContain('invite link rotated');expect(rotated.stdout+rotated.stderr).not.toContain(credential);
  },30000);
  test('denied or incomplete writes do not retry or claim success',async()=>{
    for(const response of [{status:403,body:{code:'permission_denied',message:credential}},{body:{}}]){
      const r=await run(select('1.01'),{'OrganizationService/CreateDomainVerification':response},['--apply-domain','example.test']);
      expect(r.code).toBe(2);expect(r.calls).toHaveLength(1);expect(r.stdout).toBe('');expect(r.stderr).not.toContain(credential);
    }
  },30000);
});
