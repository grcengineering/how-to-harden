// Offline process-boundary tests. Temporary first-party CLI/transport fakes never contact a service.
import { afterEach, beforeEach, expect, test } from 'bun:test';
import { chmodSync, existsSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const root = resolve(import.meta.dir, '..');
const token = 'HTH_SYNTHETIC_FACTORY_CREDENTIAL';
const privateValue = 'HTH_SYNTHETIC_PRIVATE_DETAIL';
const files = {
  secrets: 'factory/api/hth-factory-4.05-inventory-computer-secret-names.sh',
  version: 'factory/cli/hth-factory-2.07-inventory-client-version.sh',
  logout: 'humanlayer/cli/hth-humanlayer-1.01-retire-persistent-login.sh',
  linear: 'humanlayer/cli/hth-humanlayer-3.02-inventory-linear-workflow-states.sh',
  workspace: 'humanlayer/config/hth-humanlayer-2.01-build-workspace-candidate.sh',
  gateway: 'humanlayer/config/hth-humanlayer-3.01-build-codex-gateway-environment.sh',
};
let dir: string;
let output: string;
let env: Record<string, string>;
let replies: Record<string, unknown>;
const fake = `#!/usr/bin/env bun
const fs = require('node:fs');
const path = require('node:path');
const args = process.argv.slice(2);
const name = path.basename(process.argv[1]);
let key = name + ' ' + args.join(' ');
if (name === 'curl') {
  if (args[0] !== '-q' || args[args.indexOf('--request')+1] !== 'GET') process.exit(80);
  if (args.includes('-L') || args.includes('--location') || args.join(' ').includes(process.env.FACTORY_API_KEY)) process.exit(81);
  const input = await new Response(Bun.stdin.stream()).text();
  if (input !== 'header = "Authorization: Bearer ' + process.env.FACTORY_API_KEY + '"\\n') process.exit(82);
  if (args.at(-1) !== 'https://api.factory.ai/api/v0/organization/computer-secrets') process.exit(83);
  key = args.at(-1);
} else if (!['droid --version','droid update --check','humanlayer logout','linear list-workflow-states ENG --output-format json'].includes(key)) {
  process.exit(84); // catches a session, mutation, unexpected flag or widened team scope
}
fs.appendFileSync(process.env.HTH_FAKE_CALLS, JSON.stringify({name,args,key})+'\\n');
const reply=JSON.parse(fs.readFileSync(process.env.HTH_FAKE_REPLIES,'utf8'))[key];
if (!reply || reply.error) { console.error('${privateValue}'); process.exit(1); }
const body=reply.raw ?? JSON.stringify(reply.body);
if (name === 'curl') {
  fs.writeFileSync(args[args.indexOf('--output')+1],body);
  process.stdout.write(String(reply.status ?? 200));
} else { process.stdout.write(body+'\\n'); }
`;
beforeEach(() => {
  dir = mkdtempSync(join(tmpdir(), 'hth-factory-refresh-test-'));
  output = join(dir, 'evidence.json');
  env = Object.fromEntries(Object.entries(process.env).filter(([k,v]) => v !== undefined && !/^(FACTORY_|HUMANLAYER_|HTH_)/.test(k))) as Record<string,string>;
  Object.assign(env, {
    PATH: `${dir}:${process.env.PATH}`, TMPDIR: dir, HTH_PROFILE_LEVEL: '2',
    FACTORY_PROJECT_DIR: dir, FACTORY_API_KEY: token, FACTORY_SECRET_NAMES_OUTPUT: output, FACTORY_VERSION_OUTPUT: output,
    HUMANLAYER_LINEAR_TEAM: 'ENG', HUMANLAYER_LINEAR_STATES_OUTPUT: output,
    HUMANLAYER_SOURCE_REF: 'origin/main', HUMANLAYER_CODEX_GATEWAY_URL: 'https://gateway.example.invalid/v1',
    HUMANLAYER_GATEWAY_TOKEN: privateValue,
    HTH_FAKE_CALLS: join(dir,'calls.jsonl'), HTH_FAKE_REPLIES: join(dir,'replies.json'),
  });
  for (const name of ['curl','droid','humanlayer','linear']) { writeFileSync(join(dir,name),fake); chmodSync(join(dir,name),0o700); }
  replies = {};
});
afterEach(() => rmSync(dir,{recursive:true,force:true}));
function run(name: keyof typeof files, status=0, overrides:Record<string,string>={}) {
  writeFileSync(env.HTH_FAKE_REPLIES,JSON.stringify(replies));
  const r=spawnSync('bash',[join(root,'packs',files[name])],{env:{...env,...overrides},encoding:'utf8',timeout:10_000});
  expect(r.error).toBeUndefined();
  expect(r.status,r.stdout+r.stderr).toBe(status);
  expect(r.stdout+r.stderr).not.toContain(token);
  expect(r.stdout+r.stderr).not.toContain(privateValue);
  expect(readdirSync(dir).filter(n=>n.startsWith('hth-factory.')||n.startsWith('.hth-humanlayer.'))).toEqual([]);
  return r;
}
function noCalls(){expect(existsSync(env.HTH_FAKE_CALLS)).toBe(false);}
function privateFile(){expect(statSync(output).mode & 0o777).toBe(0o600);return readFileSync(output,'utf8');}
const secretURL='https://api.factory.ai/api/v0/organization/computer-secrets';

test('Computer secret collector projects names and makes one exact GET',()=>{
  replies[secretURL]={body:{secrets:[{key:'PACKAGE_TOKEN',value:privateValue}],unknown:privateValue}};
  run('secrets'); expect(JSON.parse(privateFile())).toEqual({secrets:[{key:'PACKAGE_TOKEN'}]});
  expect(readFileSync(output,'utf8')).not.toContain(privateValue);
  expect(readFileSync(env.HTH_FAKE_CALLS,'utf8').trim().split('\n')).toHaveLength(1);
});
test('empty secret-name inventory is retained without a compliant verdict',()=>{
  replies[secretURL]={body:{secrets:[]}}; const r=run('secrets');
  expect(JSON.parse(privateFile())).toEqual({secrets:[]});expect(r.stdout).not.toContain('COMPLIANT');
});
for(const body of [{}, {secrets:null}, {secrets:[{key:1}]}, {secrets:[{key:''}]}, {secrets:[{key:'X'},{key:'X'}]}]){
  test(`malformed secret inventory is unknown ${JSON.stringify(body)}`,()=>{replies[secretURL]={body};run('secrets',2);expect(existsSync(output)).toBe(false);});
}
test('HTTP failure discards secret evidence and hides response',()=>{replies[secretURL]={status:403,body:{error:privateValue}};run('secrets',2);expect(existsSync(output)).toBe(false);});
test('origin override is refused before a transport call',()=>{run('secrets',2,{FACTORY_API_BASE:'https://evil.invalid'});noCalls();});
test('version inventory requests only version and check-only update',()=>{
  replies['droid --version']={raw:'1.4.0'};replies['droid update --check']={raw:'current'};
  run('version');expect(privateFile()).toContain('1.4.0');
  expect(readFileSync(env.HTH_FAKE_CALLS,'utf8').trim().split('\n')).toHaveLength(2);
});
test('failed update check discards partial version evidence',()=>{replies['droid --version']={raw:'1.4.0'};replies['droid update --check']={error:true};run('version',2);expect(existsSync(output)).toBe(false);});
test('logout dry run invokes no client',()=>{const r=run('logout');expect(r.stdout).toContain('DRY RUN');noCalls();});
test('explicit logout invokes only the documented production command',()=>{replies['humanlayer logout']={raw:'logged out'};run('logout',0,{HTH_APPLY:'1'});expect(readFileSync(env.HTH_FAKE_CALLS,'utf8')).toContain('humanlayer logout');});
test('invalid logout apply flag is refused without a client',()=>{run('logout',2,{HTH_APPLY:'yes'});noCalls();});
test('failed logout is unknown',()=>{replies['humanlayer logout']={error:true};run('logout',2,{HTH_APPLY:'1'});});
test('workspace generator emits strict JSON without secret-copy or setup claims',()=>{
  const r=run('workspace');expect(JSON.parse(r.stdout)).toEqual({sourceRef:'origin/main',setupBlocksFirstSession:true});noCalls();
});
for(const ref of ['', '-bad', 'main;touch /tmp/no', 'main\nnext']){
  test(`unsafe or missing workspace input is refused ${JSON.stringify(ref)}`,()=>{run('workspace',2,{HUMANLAYER_SOURCE_REF:ref});noCalls();});
}
test('gateway fragment retains a literal credential reference and does not launch a session',()=>{
  const r=run('gateway');expect(r.stdout).toContain("export CODELAYER_CODEX_BASE_URL='https://gateway.example.invalid/v1'");
  expect(r.stdout).toContain('${HUMANLAYER_GATEWAY_TOKEN:?');noCalls();
});
for(const url of ['http://internal/v1','https://user:pass@host/v1','https://host/v1?token=x','https://host/v1#x','https://host:99999/v1','https://host/v1;touch/tmp/no','https://host/$(id)']){
  test(`unsafe gateway is refused ${url}`,()=>{run('gateway',2,{HUMANLAYER_CODEX_GATEWAY_URL:url});noCalls();});
}
test('Linear collector preserves structured JSON privately with no mutation',()=>{
  replies['linear list-workflow-states ENG --output-format json']={body:[{id:'state1',name:'code-review'}]};
  run('linear');expect(JSON.parse(privateFile())).toEqual([{id:'state1',name:'code-review'}]);
});
test('invalid Linear response is unknown and creates no evidence',()=>{replies['linear list-workflow-states ENG --output-format json']={raw:'not JSON '+privateValue};run('linear',2);expect(existsSync(output)).toBe(false);});
test('Linear team injection is refused before client access',()=>{run('linear',2,{HUMANLAYER_LINEAR_TEAM:'--all'});noCalls();});
for(const name of ['secrets','version','linear'] as const){
  test(`${name} refuses existing or symlink output`,()=>{
    const keep=join(dir,'keep');writeFileSync(keep,'keep');symlinkSync(keep,output);
    replies[secretURL]={body:{secrets:[]}};replies['droid --version']={raw:'1.4.0'};replies['droid update --check']={raw:'current'};
    replies['linear list-workflow-states ENG --output-format json']={body:[]};
    run(name,2);expect(readFileSync(keep,'utf8')).toBe('keep');
  });
}
for(const name of Object.keys(files) as (keyof typeof files)[]){
  test(`${name} rejects an invalid profile before vendor access`,()=>{run(name,2,{HTH_PROFILE_LEVEL:'0',HTH_APPLY:'1'});noCalls();});
}
