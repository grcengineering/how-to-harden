#!/usr/bin/env bun
// Synthetic transport and shell-boundary regression tests. Never calls vendor APIs.
import {test,expect,afterEach,afterAll} from 'bun:test';
import {mkdtempSync,writeFileSync,rmSync,readdirSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {get,pages,required} from '../packs/grok-api/api/common';
import {auditKeys} from '../packs/grok-api/api/audit-inference-keys';
import {auditPublicLinks} from '../packs/grok-api/api/audit-public-file-links';
import {auditEvents} from '../packs/grok-api/api/count-audit-events';
import {inventoryAgents} from '../packs/cursor-cloud-agents/api/inventory-agents';
import {inventoryInstallations} from '../packs/cursor-origin/api/inventory-app-installations';
import {request} from '../packs/grok-api/config/prepare-moderation-request';

const root=resolve(import.meta.dir,'..'),temp=mkdtempSync(join(tmpdir(),'hth-spacexai-test-'));
const privateText='PRIVATE_TOKEN_OR_RESPONSE_4d4358';
const realFetch=globalThis.fetch;
afterEach(()=>{globalThis.fetch=realFetch;});
afterAll(()=>rmSync(temp,{recursive:true,force:true}));
function responses(values:any[],calls:URL[]=[]){let n=0;return async(url:URL,_token:string)=>{calls.push(url);if(n>=values.length)throw Error('UNEXPECTED request');return structuredClone(values[n++]);};}
const keyEnv={XAI_MANAGEMENT_API_KEY:privateText,XAI_TEAM_ID:'team-a',HTH_TEAM_ADMIN_CONFIRMED:'1'};
const identity={scope:'SCOPE_TEAM',scopeId:'team-a'};
const key=(id='key-a')=>({teamId:'team-a',apiKeyId:id,disabled:false,aclStrings:['api-key:model:grok-4.7'],expireTime:'2030-01-01T00:00:00Z',qps:10,qpm:100,tpm:'100000',name:privateText,apiKey:privateText});

test('transport fixes first-party HTTPS target, GET, timeout and no redirect forwarding',async()=>{
  let calls=0;
  globalThis.fetch=(async(url:any,options:any)=>{calls++;expect(new URL(url).hostname).toBe('api.x.ai');expect(options.method).toBe('GET');expect(options.redirect).toBe('error');expect(options.headers.Authorization).toBe(`Bearer ${privateText}`);expect(options.signal).toBeInstanceOf(AbortSignal);return Response.json({ok:true});}) as any;
  for(const url of ['http://api.x.ai/x','https://api.x.ai.evil.test/x','https://evil.test/x','https://user@api.x.ai/x','https://api.x.ai:444/x'])await expect(get(new URL(url),privateText)).rejects.toThrow('noncanonical');
  expect(calls).toBe(0);expect(await get(new URL('https://api.x.ai/v1/files'),privateText)).toEqual({ok:true});expect(calls).toBe(1);
});
test('HTTP, network, malformed, missing/oversized JSON errors never echo response text',async()=>{
  for(const response of [new Response(privateText,{status:403}),new Response(privateText),Response.json([]),Response.json(null),new Response(' '.repeat(10000001))]){
    globalThis.fetch=(async()=>response) as any;
    try{await get(new URL('https://api.x.ai/v1/files'),privateText);throw Error('accepted invalid response');}catch(error){expect(String(error)).toContain('UNKNOWN');expect(String(error)).not.toContain(privateText);}
  }
  globalThis.fetch=(async()=>{throw Error(privateText);}) as any;
  await expect(get(new URL('https://api.x.ai/v1/files'),privateText)).rejects.toThrow('transport or redirect failure');
  expect(()=>required('KEY',{KEY:'bad\r\nheader'})).toThrow('PRECONDITION');
});
test('pagination uses documented request token, completes all pages and rejects loops/bad schema',async()=>{
  const calls:URL[]=[];
  expect(await pages(new URL('https://api.x.ai/v1/files'),privateText,'data','pagination_token','pagination_token',responses([{data:[1],pagination_token:'next/value'},{data:[2]}],calls))).toEqual([1,2]);
  expect(calls[1].searchParams.get('pagination_token')).toBe('next/value');
  for(const fixtures of [[{data:[],pagination_token:'same'},{data:[],pagination_token:'same'}],[{items:[]}],[{data:[],pagination_token:7}]])await expect(pages(new URL('https://api.x.ai/v1/files'),privateText,'data','pagination_token','pagination_token',responses(fixtures))).rejects.toThrow('UNKNOWN');
});
test('key inventory verifies authoritative scope and explicit admin boundary before list',async()=>{
  let calls=0;
  await expect(auditKeys({...keyEnv,HTH_TEAM_ADMIN_CONFIRMED:'0'},async()=>{calls++;return identity;})).rejects.toThrow('team admin');expect(calls).toBe(0);
  for(const wrong of [{scope:'SCOPE_ORGANIZATION',scopeId:'team-a'},{scope:'SCOPE_TEAM',scopeId:'other'},{teamId:'team-a'}])await expect(auditKeys(keyEnv,responses([wrong]))).rejects.toThrow('authoritatively');
  const urls:URL[]=[];
  const report=await auditKeys(keyEnv,responses([identity,{apiKeys:[key()],paginationToken:'p2'},{apiKeys:[{...key('key-b'),aclStrings:['*'],expireTime:null,qpm:0}]}],urls));
  expect(report).toMatchObject({status:'REVIEW',total:2,enabled:2,unboundedExpiry:1,wildcardAcl:1,missingLimits:1});
  expect(urls[1].searchParams.get('activeOnly')).toBe('false');expect(urls[2].searchParams.get('paginationToken')).toBe('p2');expect(JSON.stringify(report)).not.toContain(privateText);
});
test('key inventory refuses wrong teams, duplicate IDs and typed schema drift',async()=>{
  for(const keys of [[{...key(),teamId:'other'}],[key(),key()],[{...key(),disabled:'false'}],[{...key(),aclStrings:null}],[{...key(),expireTime:'never'}]])await expect(auditKeys(keyEnv,responses([identity,{apiKeys:keys}]))).rejects.toThrow('UNKNOWN');
});
test('public link audit counts unbounded/over-policy, paginates and never prints bearer URLs',async()=>{
  const now=Date.parse('2026-11-05T00:00:00Z'),urls:URL[]=[];
  const report=await auditPublicLinks({XAI_API_KEY:privateText},responses([{data:[{id:'private'},{id:'public',public_url:`https://example.test/${privateText}`,public_url_expires_at:now/1000+3600}],pagination_token:'next'},{data:[{id:'unbounded',public_url:privateText},{id:'long',public_url:privateText,public_url_expires_at:now/1000+25*3600}]}],urls),now);
  expect(report).toMatchObject({status:'REVIEW',files:4,publicLinks:3,unbounded:1,overPolicy:1});expect(JSON.stringify(report)).not.toContain(privateText);expect(urls[1].searchParams.get('pagination_token')).toBe('next');
  for(const data of [[{id:'a',public_url:5}],[{id:'a',public_url:privateText,public_url_expires_at:'forever'}],[{id:'a'},{id:'a'}]])await expect(auditPublicLinks({XAI_API_KEY:privateText},responses([{data}]),now)).rejects.toThrow('UNKNOWN');
});
test('audit metadata uses bounded window, team identity and exact token; malformed event cannot pass',async()=>{
  const env={...keyEnv,HTH_AUDIT_FROM:'2026-11-04T00:00:00Z',HTH_AUDIT_TO:'2026-11-05T00:00:00Z'},urls:URL[]=[];
  const event={eventId:'e1',eventTime:'2026-11-04T12:00:00Z',description:privateText};
  const report=await auditEvents(env,responses([identity,{events:[event],nextPageToken:'p2'},{events:[]}],urls));expect(report.count).toBe(1);expect(urls[2].searchParams.get('pageToken')).toBe('p2');expect(urls[1].searchParams.get('eventTimeFrom')).toBe(env.HTH_AUDIT_FROM);expect(JSON.stringify(report)).not.toContain(privateText);
  for(const events of [[event,event],[{...event,eventTime:'2020-01-01'}],[{eventTime:event.eventTime}]])await expect(auditEvents(env,responses([identity,{events}]))).rejects.toThrow('UNKNOWN');
  await expect(auditEvents({...env,HTH_AUDIT_TO:env.HTH_AUDIT_FROM},responses([]))).rejects.toThrow('PRECONDITION');
});
test('Cloud inventory is explicitly user-scoped and validates current durable states',async()=>{
  const urls:URL[]=[];const report=await inventoryAgents({CURSOR_API_KEY:privateText},responses([{items:[{id:'a',status:'ACTIVE',name:privateText}],nextCursor:'next'},{items:[{id:'b',status:'ARCHIVED'}]}],urls));
  expect(report).toMatchObject({status:'REVIEW',scope:'authenticated user only',count:2,byStatus:{ACTIVE:1,ARCHIVED:1}});expect(urls[1].searchParams.get('cursor')).toBe('next');expect(urls[0].searchParams.get('includeArchived')).toBe('true');expect(JSON.stringify(report)).not.toContain(privateText);
  await expect(inventoryAgents({CURSOR_API_KEY:privateText},responses([{items:[{id:'a',status:'RUNNING'}]}]))).rejects.toThrow('UNKNOWN');
});
test('Origin inventory stays app-scoped and counts broad/delegated grants without identity leakage',async()=>{
  const urls:URL[]=[];const report=await inventoryInstallations({ORIGIN_APP_JWT:privateText},responses([{installations:[{id:'i1',repoSelectionMode:'selected',scopes:['repository:contents:read'],installedBy:privateText}],nextPageToken:'next'},{installations:[{id:'i2',repoSelectionMode:'all',scopes:['repository:contents:write','namespace:user_tokens:write']}]}],urls));
  expect(report).toMatchObject({status:'REVIEW',scope:'authenticated app only',installations:2,allRepos:1,writeGrants:1,userDelegation:1});expect(urls[1].searchParams.get('pageToken')).toBe('next');expect(JSON.stringify(report)).not.toContain(privateText);
  await expect(inventoryInstallations({ORIGIN_APP_JWT:privateText},responses([{installations:[{id:'i',repoSelectionMode:'new-mode',scopes:[]}]}]))).rejects.toThrow('UNKNOWN');
});
function botShell(body:string){return Bun.spawnSync(['bash','-c',`source "$1"\n${body}`,'hth',join(root,'packs/grok-bot/api/common.sh')],{cwd:root,env:{...process.env,CURSOR_TEAM_ID:'70',TMPDIR:temp}});}
test('destructive Bot identity gate accepts authoritative ID only; equal email sets cannot authorize',()=>{
  const marker=join(temp,'mutation');
  for(const [code,json,expected] of [['200','{"teamId":70}',0],['200','{"teamId":71}',2],['403','{"members":[{"email":"same@example.test"}]}',3],['200','{"members":[{"email":"same@example.test"}]}',3],['200','{"teamId":"70"}',3],['000','{}',3]] as const){
    rmSync(marker,{force:true});
    const body=`gb_get() { GB_CODE=${code}; printf '%s' '${json}' > "$GB_BODY_FILE"; }\ngb_org_members_for_team() { echo 'EMAIL FALLBACK MUST NOT RUN'; exit 99; }\ngb_require_team_key_matches\nprintf done > '${marker}'`;
    const result=botShell(body);expect(result.exitCode).toBe(expected);expect(result.stdout.toString()+result.stderr.toString()).not.toContain('EMAIL FALLBACK MUST NOT RUN');expect(Bun.file(marker).size>0).toBe(expected===0);
  }
});
test('partial Bot evidence has machine-actionable UNKNOWN exit 3 and cannot become a pass',()=>{
  for(const body of ['GB_UNPROVEN="source plane invisible"; gb_exit','GB_UNPROVEN="source plane invisible"; GB_MODE=enforce; check() { :; }; gb_main check check']){
    const result=botShell(body);expect(result.exitCode).toBe(3);expect(result.stdout.toString()).toContain('RESULT: UNKNOWN');
  }
  expect(botShell('GB_UNPROVEN="gap"; GB_FINDINGS=1; gb_exit').exitCode).toBe(1);
  expect(botShell('gb_exit').exitCode).toBe(0);
});
test('offline moderation emitter uses documented native request fields and no secrets',()=>{
  expect(request()).toMatchObject({model:'grok-4.7',guidelines:[{type:'policy',category:'nsfw',behavior:'decline'},{type:'policy',category:'violence',behavior:'decline'},{type:'policy',category:'profanity',behavior:'decline'}]});
  expect(JSON.stringify(request())).not.toContain(privateText);
  const result=Bun.spawnSync(['bash',join(root,'packs/grok-api/config/hth-grok-api-4.03-prepare-moderation-request.sh')],{env:{...process.env,XAI_API_KEY:privateText}});expect(result.exitCode).toBe(0);expect(JSON.parse(result.stdout.toString())).toEqual(request());
});
test('published Bash entrypoints execute their adjacent helpers and fail before network without credentials',()=>{
  for(const file of [
    'grok-api/api/hth-grok-api-1.02-audit-inference-keys.sh',
    'grok-api/api/hth-grok-api-3.01-audit-public-file-links.sh',
    'grok-api/api/hth-grok-api-5.01-count-audit-events.sh',
    'cursor-cloud-agents/api/hth-cursor-cloud-agents-5.02-inventory-agents.sh',
    'cursor-origin/api/hth-cursor-origin-3.01-inventory-app-installations.sh',
  ]){
    const entrypoint=join(root,'packs',file);
    expect(Bun.spawnSync(['bash','-n',entrypoint]).exitCode).toBe(0);
    const result=Bun.spawnSync(['bash',entrypoint],{env:{PATH:process.env.PATH!,TMPDIR:temp}});
    expect(result.exitCode).toBe(3);
    expect(JSON.parse(result.stdout.toString())).toMatchObject({status:'UNKNOWN'});
    expect(result.stderr.toString()).not.toContain('syntax error');
  }
});
