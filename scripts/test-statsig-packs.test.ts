// Offline public-contract fixtures. Curl and Siggy are replaced; no tenant access.
import { afterAll, describe, expect, test } from 'bun:test';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync, statSync, symlinkSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, join } from 'node:path';
import { createHash } from 'node:crypto';
import { limitedCaptureOptions, createLimitedCapturePlugin } from '../packs/statsig/sdk/hth-statsig-4.01-limit-autocapture.js';
// Pinned released implementation, used only to build real native event metadata.
import { _gatherAllMetadata } from '../packs/statsig/sdk/node_modules/@statsig/web-analytics/src/utils/metadataUtils.js';
const root=mkdtempSync(join(tmpdir(),'hth-statsig-tests-'));
const bin=join(root,'bin'); mkdirSync(bin);
const realPath=process.env.PATH??'/usr/bin:/bin';
// Keep transport arguments and credential stdin separate to test leakage boundaries.
writeFileSync(join(bin,'curl'),`#!/usr/bin/env bun
import {writeFileSync,readFileSync,appendFileSync} from 'node:fs';
const args=process.argv.slice(2), body=await Bun.stdin.text(), call=args.at(-1);
appendFileSync(process.env.MOCK_LOG,JSON.stringify({args,stdin:body})+'\\n');
const pages=JSON.parse(readFileSync(process.env.MOCK_RESPONSE,'utf8'));
const n=call.includes('page=2')?1:0;
writeFileSync(args[args.indexOf('--output')+1], typeof pages[n]==='string'?pages[n]:JSON.stringify(pages[n]));
process.stdout.write(process.env.MOCK_STATUS??'200');
`,{mode:0o700});
writeFileSync(join(bin,'siggy'),'#!/bin/sh\nprintf "%s\\n" "${MOCK_VERSION:-1.2.3}"\n',{mode:0o700});
afterAll(()=>rmSync(root,{recursive:true,force:true}));
let seq=0;
async function run(pack:string, response:unknown[], extra:Record<string,string>={}){
  const dir=join(root,String(++seq));mkdirSync(dir);
  const output=join(dir,'evidence.json'), log=join(dir,'calls'), fixture=join(dir,'responses');
  writeFileSync(fixture,JSON.stringify(response));
  const env:Record<string,string>={PATH:`${bin}:${realPath}`,HOME:dir,TMPDIR:dir,HTH_PROFILE_LEVEL:'2',
    STATSIG_OUTPUT:output,STATSIG_CONSOLE_KEY:'console-fixture-test-secret',STATSIG_SERVER_KEY:'secret-server-fixture',
    MOCK_LOG:log,MOCK_RESPONSE:fixture,...extra};
  const child=Bun.spawn(['bash',resolve('packs/statsig',pack)],{env,stdout:'pipe',stderr:'pipe'});
  const [code,stdout,stderr]=await Promise.all([child.exited,new Response(child.stdout).text(),new Response(child.stderr).text()]);
  return {code,stdout,stderr,output,exists:existsSync(output),evidence:existsSync(output)?readFileSync(output,'utf8'):'',
    calls:existsSync(log)?readFileSync(log,'utf8').trim().split('\n').map(x=>JSON.parse(x)):[]};
}
const project='api/hth-statsig-1.02-read-project-boundary.sh';
const keys='api/hth-statsig-2.01-inventory-key-metadata.sh';
const reviews='api/hth-statsig-3.01-read-review-flags.sh';
const status='api/hth-statsig-5.02-read-existing-deletion-status.sh';
const key=(value='raw-key-fixture')=>({key:value,type:'CONSOLE',status:'active',description:'reviewed automation',scopes:['console_read']});
const page=(data:unknown[],n=1,next:string|null=null,total=data.length)=>({data,pagination:{pageNumber:n,itemsPerPage:100,nextPage:next,totalItems:total}});
describe('Statsig fixed reads and private evidence',()=>{
  test('projects retain CLOSED/OPEN as observations, strip unknown secrets, and protect file',async()=>{
    const r=await run(project,[{data:{name:'reviewed',visibility:'OPEN',default_unit_type:null,secret:'DO-NOT-EXPORT'}}]);
    expect(r.code).toBe(0);expect(JSON.parse(r.evidence).project.visibility).toBe('OPEN');
    expect(r.evidence).not.toContain('DO-NOT-EXPORT');expect(statSync(r.output).mode&0o777).toBe(0o600);
    expect(r.stdout).not.toMatch(/PASS|COMPLIANT/);expect(r.calls[0].args.at(-1)).toBe('https://statsigapi.net/console/v1/settings/project');
    expect(r.calls[0].args).not.toContain('-L');expect(r.calls[0].args.join(' ')).not.toContain('console-fixture');
    expect(r.calls[0].stdin).toContain('STATSIG-API-KEY: console-fixture-test-secret');
  });
  test('missing visibility, malformed response and denied transport produce no success evidence',async()=>{
    for(const [body,extra]of [[{data:{name:'x'}},{}],['not-json',{}],[{data:{name:'x',visibility:'CLOSED'}},{MOCK_STATUS:'403'}]] as const){
      const r=await run(project,[body],extra);expect(r.code).not.toBe(0);expect(r.exists).toBe(false);
      expect(r.stdout+r.stderr).not.toContain('secret-server-fixture');
    }
  });
  test('profile and origin overrides fail before any request',async()=>{
    for(const extra of [{HTH_PROFILE_LEVEL:'0'},{STATSIG_BASE_URL:'https://attacker.example'}]){
      const r=await run(project,[],extra);expect(r.code).not.toBe(0);expect(r.calls).toHaveLength(0);
    }
  });
  test('key pages are complete, independently rebuilt, and raw credentials never exported',async()=>{
    const r=await run(keys,[page([key()],1,'/console/v1/keys?page=2&limit=100',2),page([key('different-fixture')],2,null,2)]);
    expect(r.code).toBe(0);expect(r.calls).toHaveLength(2);
    expect(r.calls[1].args.at(-1)).toBe('https://statsigapi.net/console/v1/keys?limit=100&page=2');
    expect(JSON.parse(r.evidence).keys[0].fingerprint).toBe(createHash('sha256').update('raw-key-fixture').digest('hex'));
    expect(r.evidence).not.toContain('raw-key-fixture');expect(r.evidence).not.toContain('different-fixture');
  });
  test('hostile/duplicate pagination, duplicate keys and incomplete totals discard all evidence',async()=>{
    const cases=[
      [page([key()],1,'https://attacker.example/console/v1/keys?page=2',2)],
      [page([key()],1,'/console/v1/keys?page=2&page=2',2)],
      [page([key()],1,'/console/v1/keys?page=2&extra=1',2)],
      [page([key()],1,'/console/v1/keys?page=2',2),page([key()],2,null,2)],
      [page([key()],1,null,2)],
      [{data:[{...key(),status:undefined}],pagination:{pageNumber:1,itemsPerPage:100,nextPage:null}}],
    ];
    for(const fixture of cases){const r=await run(keys,fixture);expect(r.code).not.toBe(0);expect(r.exists).toBe(false);}
  });
  test('review false flags remain false; absent mandatory fields stay unknown',async()=>{
    const data={is_config_review_required:false,is_metric_review_required:true,is_metric_review_required_on_verified_only:false};
    const r=await run(reviews,[{data}]);expect(r.code).toBe(0);expect(JSON.parse(r.evidence).flags).toEqual(data);
    expect((await run(reviews,[{data:{is_config_review_required:true}}])).code).not.toBe(0);
  });
  test('deletion pack only reads existing request status through documented POST',async()=>{
    for(const value of ['PENDING','COMPLETE']){
      const r=await run(status,[value],{STATSIG_REQUEST_ID:'request-fixture-1'});
      expect(r.code).toBe(0);expect(JSON.parse(r.evidence).status).toBe(value);
      expect(r.calls[0].args.at(-1)).toBe('https://api.statsig.com/v1/get_delete_user_data_request_status');
      expect(r.calls[0].args[r.calls[0].args.indexOf('--request')+1]).toBe('POST');
      expect(r.calls[0].args.join(' ')).not.toContain('/v1/delete_user_data');
    }
    expect((await run(status,['UNKNOWN'],{STATSIG_REQUEST_ID:'request-fixture-1'})).code).not.toBe(0);
    expect((await run(status,[])).calls).toHaveLength(0);
  });
  test('existing file and symlink targets are preserved',async()=>{
    const existing=join(root,'existing');writeFileSync(existing,'KEEP');
    const link=join(root,'link');symlinkSync(existing,link);
    for(const output of [existing,link]){const r=await run(project,[],{STATSIG_OUTPUT:output});expect(r.code).not.toBe(0);expect(r.calls).toHaveLength(0);}
    expect(readFileSync(existing,'utf8')).toBe('KEEP');
  });
  test('native private user emitter moves sensitive fields and rejects conflicting/unsupported shapes',async()=>{
    const input=join(root,'user');
    writeFileSync(input,JSON.stringify({userID:'pseudonymous-17',email:'synthetic@example.test',custom:{reviewedTier:'trial'}}));
    const r=await run('config/hth-statsig-2.02-prepare-private-user.sh',[],{STATSIG_USER_INPUT:input});
    expect(r.code).toBe(0);expect(JSON.parse(r.evidence)).toEqual({userID:'pseudonymous-17',privateAttributes:{email:'synthetic@example.test',reviewedTier:'trial'}});
    expect(r.calls).toHaveLength(0);
    for(const user of [{userID:'x',custom:{email:'duplicate'}},{userID:'x',privateAttributes:{}},{userID:'x',custom:{nested:{a:1}}},JSON.parse('{"userID":"x","custom":{"__proto__":"synthetic","tier":"trial"}}')]){
      writeFileSync(input,JSON.stringify(user));const bad=await run('config/hth-statsig-2.02-prepare-private-user.sh',[],{STATSIG_USER_INPUT:input});
      expect(bad.code).not.toBe(0);expect(bad.exists).toBe(false);
    }
  });
  test('Siggy version is bounded, format checked and never mistaken for settings verification',async()=>{
    const r=await run('cli/hth-statsig-3.03-inventory-siggy-version.sh',[]);
    expect(r.code).toBe(0);expect(JSON.parse(r.evidence).version).toBe('1.2.3');expect(r.calls).toHaveLength(0);
    expect((await run('cli/hth-statsig-3.03-inventory-siggy-version.sh',[],{MOCK_VERSION:'secret accidentally printed'})).code).not.toBe(0);
  });
});
test('actual AutoCapture metadata cannot spoof approved browser location',()=>{
  expect(createLimitedCapturePlugin()).toBeDefined();
  const approved='https://public.example.test/';
  const previous=Object.getOwnPropertyDescriptor(globalThis,'window');
  function nativeEvent(href:string){
    Object.defineProperty(globalThis,'window',{configurable:true,value:{location:{href},document:{title:'Synthetic',referrer:''},navigator:{userAgent:'synthetic',language:'en'},screen:{},innerWidth:100,innerHeight:100}});
    // Same native merge order as AutoCapture._enqueueAutoCapture in 3.33.7.
    return {eventName:'auto_capture::page_view',value:new URL(href).origin+'/',metadata:{page_url:href,..._gatherAllMetadata(new URL(href))}};
  }
  const event=nativeEvent(approved);
  try {
  expect(limitedCaptureOptions().eventFilterFunc(event)).toBe(false);
  const options=limitedCaptureOptions([approved]);
  expect(options.captureCopyText).toBe(false);expect(options.consoleLogAutoCaptureSettings.enabled).toBe(false);
  expect(options.eventFilterFunc(event)).toBe(true);
  for(const candidate of [{...event,eventName:'auto_capture::copy'},{...event,metadata:{pageUrl:approved}},{...event,metadata:{page_url:approved,current_url:'https://other.example.test/'}},{}])expect(options.eventFilterFunc(candidate)).toBe(false);
  for(const key of ['pageUrl','page_url','current_url']){
    const spoof=nativeEvent(`https://unapproved.example.test/?private=synthetic&${key}=${encodeURIComponent(approved)}`);
    expect(spoof.metadata[key]).toBe(approved); // verify actual released query projection
    expect(options.eventFilterFunc(spoof)).toBe(false);
  }
  // Even every event URL field forged together cannot authorize a different browser URL.
  nativeEvent('https://unapproved.example.test/');
  expect(options.eventFilterFunc({eventName:'auto_capture::page_view',metadata:{page_url:approved,current_url:approved}})).toBe(false);
  nativeEvent(approved+'?private=synthetic');
  expect(options.eventFilterFunc(event)).toBe(false);
  delete globalThis.window;
  expect(options.eventFilterFunc(event)).toBe(false);
  expect(()=>limitedCaptureOptions(['http://public.example.test/'])).toThrow();
  expect(()=>limitedCaptureOptions(['https://public.example.test/#private'])).toThrow();
  } finally { if(previous)Object.defineProperty(globalThis,'window',previous);else delete globalThis.window; }
});
