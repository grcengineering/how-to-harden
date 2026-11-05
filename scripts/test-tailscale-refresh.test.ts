// Offline process-boundary tests: every vendor executable is a temporary fake.
import { afterEach, beforeEach, expect, test } from 'bun:test';
import { mkdtempSync, readFileSync, writeFileSync, chmodSync, existsSync, readdirSync, rmSync, statSync, symlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const root = resolve(import.meta.dir, '..');
const packs = join(root, 'packs/tailscale');
const privateValue = 'HTH_SYNTHETIC_PRIVATE_VALUE';
const token = 'HTH_SYNTHETIC_ACCESS_TOKEN';
const files = {
  state: 'config/hth-tailscale-1.06-protect-node-state.sh',
  attribute: 'api/hth-tailscale-1.06-read-node-state-attribute.sh',
  managed: 'config/hth-tailscale-4.05-prepare-managed-client-policy.sh',
  policies: 'cli/hth-tailscale-4.05-review-managed-system-policy.sh',
  inbound: 'cli/hth-tailscale-4.04-inspect-inbound-preferences.sh',
  serve: 'cli/hth-tailscale-3.03-inspect-local-service-publication.sh',
  drive: 'cli/hth-tailscale-4.06-list-local-taildrive-shares.sh',
  dns: 'api/hth-tailscale-4.07-review-dns-configuration.sh',
  localDNS: 'cli/hth-tailscale-4.07-inspect-local-dns.sh',
};
let dir: string;
let output: string;
let env: Record<string, string>;
let replies: Record<string, unknown>;

const fake = `#!/usr/bin/env bun
const fs = require('node:fs');
const path = require('node:path');
const args = process.argv.slice(2);
const curl = path.basename(process.argv[1]) === 'curl';
let key = args.join(' ');
if (curl) {
  if (args[args.indexOf('--request') + 1] !== 'GET') process.exit(80);
  if (args[0] !== '-q' || args.includes('-L') || args.includes('--location')) process.exit(81);
  if (args.join(' ').includes(process.env.TAILSCALE_ACCESS_TOKEN)) process.exit(82);
  const input = await new Response(Bun.stdin.stream()).text();
  if (input !== 'header = "Authorization: Bearer ' + process.env.TAILSCALE_ACCESS_TOKEN + '"\\n') process.exit(83);
  if (!args.at(-1).startsWith('https://api.tailscale.com/')) process.exit(84);
  key = args.at(-1).slice('https://api.tailscale.com'.length);
}
fs.appendFileSync(process.env.HTH_FAKE_CALLS, JSON.stringify({curl,args,key}) + '\\n');
const r = JSON.parse(fs.readFileSync(process.env.HTH_FAKE_REPLIES, 'utf8'))[key];
if (!r || r.error) { console.error('${privateValue}'); process.exit(1); }
const body = r.raw ?? JSON.stringify(r.body);
if (curl) {
  fs.writeFileSync(args[args.indexOf('--dump-header') + 1], 'HTTP/2 200\\r\\n\\r\\n');
  fs.writeFileSync(args[args.indexOf('--output') + 1], body);
  process.stdout.write(String(r.status ?? 200));
} else { console.log(body); }
`;

beforeEach(() => {
  dir = mkdtempSync(join(tmpdir(), 'hth-refresh-test-'));
  output = join(dir, 'evidence');
  env = Object.fromEntries(Object.entries(process.env).filter(([k, v]) => v !== undefined && !k.startsWith('TAILSCALE_') && !k.startsWith('HTH_'))) as Record<string, string>;
  Object.assign(env, {
    PATH: `${dir}:${process.env.PATH}`, TMPDIR: dir, HTH_PROFILE_LEVEL: '2',
    TAILSCALE_OUTPUT: output, TAILSCALE_PLATFORM: 'linux', TAILSCALE_CLIENT_VERSION: '1.104.4',
    TAILSCALE_ALLOWED_TAILNET_ID: 'T123456CNTRL', TAILSCALE_DEVICE_ID: 'node123',
    TAILSCALE_ACCESS_TOKEN: token, TAILSCALE_TAILNET: 'example.com',
    HTH_FAKE_REPLIES: join(dir, 'replies.json'), HTH_FAKE_CALLS: join(dir, 'calls.jsonl'),
  });
  for (const name of ['tailscale', 'tailscaled', 'curl']) {
    writeFileSync(join(dir, name), fake);
    chmodSync(join(dir, name), 0o700);
  }
  replies = {};
});
afterEach(() => rmSync(dir, { recursive: true, force: true }));

function run(name: keyof typeof files, expected = 0, overrides: Record<string, string> = {}) {
  writeFileSync(env.HTH_FAKE_REPLIES, JSON.stringify(replies));
  const result = spawnSync('bash', [join(packs, files[name])], { env: { ...env, ...overrides }, encoding: 'utf8', timeout: 10_000 });
  expect(result.error).toBeUndefined();
  expect(result.status, result.stdout + result.stderr).toBe(expected);
  expect(result.stdout + result.stderr).not.toContain(privateValue);
  expect(result.stdout + result.stderr).not.toContain(token);
  expect(readdirSync(dir).filter(x => x.startsWith('hth-tailscale.'))).toEqual([]);
  if (expected === 0) expect(statSync(output).mode & 0o777).toBe(0o600);
  else expect(existsSync(output)).toBe(false);
  return result;
}
function saved() { return JSON.parse(readFileSync(output, 'utf8')); }
function noCalls() { expect(existsSync(env.HTH_FAKE_CALLS)).toBe(false); }
const attributePath = '/api/v2/device/node123/attributes';

test('Linux state policy is typed JSON and performs no product operation', () => {
  run('state'); expect(saved()).toEqual({ EncryptState: true }); noCalls();
});
test('Windows state policy uses the documented machine key and DWORD', () => {
  run('state', 0, { TAILSCALE_PLATFORM: 'windows', TAILSCALE_CLIENT_VERSION: '1.86.0' });
  const s = readFileSync(output, 'utf8');
  expect(s).toContain('[HKEY_LOCAL_MACHINE\\SOFTWARE\\Policies\\Tailscale]\r\n');
  expect(s).toContain('"EncryptState"=dword:00000001\r\n'); noCalls();
});
test('standalone macOS state policy is a Boolean plist fragment for the correct domain', () => {
  run('state', 0, { TAILSCALE_PLATFORM: 'macos-standalone', TAILSCALE_CLIENT_VERSION: '1.86.0' });
  const s = readFileSync(output, 'utf8');
  expect(s).toContain('io.tailscale.ipn.macsys');
  expect(s).toContain('<key>EncryptState</key>\n<true/>');
  if (process.platform === 'darwin') expect(spawnSync('plutil', ['-lint', output]).status).toBe(0);
  noCalls();
});
for (const [platform, version] of [['linux', '1.101.9'], ['windows', '1.85.9'], ['macos-standalone', '1.85.9'], ['ios', '1.104.4'], ['linux', 'bad-version']]) {
  test(`reject unsupported policy target ${platform} ${version}`, () => {
    run('state', 2, { TAILSCALE_PLATFORM: platform, TAILSCALE_CLIENT_VERSION: version }); noCalls();
  });
}
test('Linux managed policy excludes desktop-only AlwaysOn and contains no auth key', () => {
  run('managed'); expect(saved()).toEqual({ Tailnet: 'required:T123456CNTRL', PostureChecking: 'always' }); noCalls();
});
test('Windows managed policy gives an audited, bounded disconnect exception', () => {
  run('managed', 0, { TAILSCALE_PLATFORM: 'windows' }); const s = readFileSync(output, 'utf8');
  expect(s).toContain('"AlwaysOn.Enabled"=dword:00000001');
  expect(s).toContain('"AlwaysOn.OverrideWithReason"=dword:00000001');
  expect(s).toContain('"ReconnectAfter"="5m"'); expect(s).not.toContain('AuthKey'); noCalls();
});
for (const id of ['', 'example.com', 'T12345\n"AuthKey"="injected"', '../other']) {
  test(`reject invalid managed tailnet input ${JSON.stringify(id)}`, () => { run('managed', 2, { TAILSCALE_ALLOWED_TAILNET_ID: id }); noCalls(); });
}
test('new artifact does not overwrite an existing file or symlink', () => {
  const keep = join(dir, 'keep'); writeFileSync(keep, 'keep'); symlinkSync(keep, output);
  const r = spawnSync('bash', [join(packs, files.state)], { env, encoding: 'utf8' });
  expect(r.status).toBe(2); expect(readFileSync(keep, 'utf8')).toBe('keep'); noCalls();
});
for (const value of [true, false, 'true', 'false']) {
  test(`preserve reported state type/value ${JSON.stringify(value)} without attestation claim`, () => {
    replies[attributePath] = { body: { attributes: { 'node:tsStateEncrypted': value, 'custom:secret': privateValue } } };
    run('attribute'); expect(saved()).toEqual({ attribute: 'node:tsStateEncrypted', reportedValue: value, assessment: 'REQUIRES-REVIEW' });
  });
}
for (const body of [{}, { attributes: {} }, { attributes: { 'node:tsStateEncrypted': null } }, { attributes: { 'node:tsStateEncrypted': privateValue } }]) {
  test(`unreported or unrecognized state is unknown ${JSON.stringify(body)}`, () => { replies[attributePath] = { body }; run('attribute', 2); });
}
test('invalid device ID is rejected before any API call', () => { run('attribute', 2, { TAILSCALE_DEVICE_ID: '../other?bad' }); noCalls(); });
test('selected policy projection excludes auth keys, origins, unknown keys and raw errors', () => {
  replies['syspolicy list --json'] = { body: { Settings: {
    AuthKey: { Value: privateValue }, EncryptState: { Value: true }, Tailnet: { Value: 'required:T123456CNTRL', Error: privateValue, Origin: privateValue }, Unknown: { Value: privateValue },
  } } };
  run('policies'); expect(saved()).toEqual({ policies: { EncryptState: { value: true, hasError: false }, Tailnet: { value: 'required:T123456CNTRL', hasError: true } }, assessment: 'CONFIGURATION-ONLY' });
  expect(readFileSync(output, 'utf8')).not.toContain(privateValue);
});
test('an empty policy snapshot remains configuration-only', () => {
  replies['syspolicy list --json'] = { body: {} }; run('policies'); expect(saved()).toEqual({ policies: {}, assessment: 'CONFIGURATION-ONLY' });
});
test('malformed selected policy values are rejected privately', () => {
  replies['syspolicy list --json'] = { body: { Settings: { Tailnet: privateValue } } }; run('policies', 2);
});
test('false inbound preferences are retained, with local/remote web scope explicit', () => {
  replies['get --json shields-up'] = { body: { 'shields-up': false, private: privateValue } };
  replies['get --json webclient'] = { body: { webclient: false } };
  run('inbound'); expect(saved()).toEqual({ shieldsUp: false, remoteWebClient: false });
});
test('a failed second CLI read leaves no partial evidence', () => {
  replies['get --json shields-up'] = { body: { 'shields-up': true } };
  replies['get --json webclient'] = { error: true }; run('inbound', 2);
});
test('Serve collector reads config without publishing or approving', () => {
  replies['serve status --json'] = { body: { Services: { 'svc:approved': {} } } };
  run('serve'); expect(saved()).toEqual({ Services: { 'svc:approved': {} } });
  expect(readFileSync(env.HTH_FAKE_CALLS, 'utf8')).toContain('serve status --json');
});
test('Taildrive lists metadata without transferring or creating a share', () => {
  replies['drive list'] = { raw: 'NAME PATH\napproved-docs /srv/docs' }; run('drive');
  expect(readFileSync(output, 'utf8')).toContain('approved-docs /srv/docs');
  expect(readFileSync(env.HTH_FAKE_CALLS, 'utf8')).toContain('drive list');
});
test('local DNS collector is read-only and preserves the returned object', () => {
  replies['dns status --json'] = { body: { MagicDNS: true } }; run('localDNS'); expect(saved()).toEqual({ MagicDNS: true });
});
function dnsReplies() {
  return {
    '/api/v2/tailnet/example.com/dns/nameservers': { body: { dns: ['10.0.0.53'] } },
    '/api/v2/tailnet/example.com/dns/preferences': { body: { magicDNS: false } },
    '/api/v2/tailnet/example.com/dns/searchpaths': { body: { searchPaths: ['corp.example.com'] } },
    '/api/v2/tailnet/example.com/dns/split-dns': { body: { 'corp.example.com': ['10.0.0.54'] } },
  };
}
test('DNS collection retains false values and documents legacy-endpoint limits', () => {
  replies = dnsReplies(); run('dns'); const s = saved();
  expect(s.magicDNS).toBe(false); expect(s.nameservers).toEqual(['10.0.0.53']);
  expect(s.splitDNS).toEqual({ 'corp.example.com': ['10.0.0.54'] }); expect(s.coverage).toContain('Override DNS');
});
test('a failed final DNS response discards the complete collection', () => {
  replies = dnsReplies(); replies['/api/v2/tailnet/example.com/dns/split-dns'] = { error: true }; run('dns', 2);
});
test('malformed DNS values cannot become a complete snapshot', () => {
  replies = dnsReplies(); replies['/api/v2/tailnet/example.com/dns/preferences'] = { body: {} }; run('dns', 2);
});
for (const name of ['state', 'attribute', 'managed', 'policies', 'serve', 'drive', 'dns', 'localDNS'] as const) {
  test(`${name} enforces its profile before vendor access`, () => { run(name, 2, { HTH_PROFILE_LEVEL: '1' }); noCalls(); });
}
test('shared transports reject new mutation attempts before reaching vendor fakes', () => {
  for (const expression of [
    'source "$1/common.sh"; hth_init 1; hth_cli set --shields-up',
    'source "$1/api/common.sh"; hth_api_init 2; hth_request POST /api/v2/device/node123/attributes "$HTH_TEMP/response"',
    'source "$1/api/common.sh"; hth_api_init 2; hth_request POST /api/v2/tailnet/example.com/dns/preferences "$HTH_TEMP/response"',
  ]) {
    const r = spawnSync('bash', ['-c', expression, 'hth-test', packs], { env, encoding: 'utf8' });
    expect(r.status).toBe(2); noCalls(); expect(existsSync(output)).toBe(false);
  }
});
