// Real released SDK checks. No replacement SDK/model catalog or credential is supplied.
import { afterEach, beforeEach, describe, expect, test } from 'bun:test';
import { mkdtempSync, readFileSync, rmSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const python = process.env.FENIC_PYTHON;
if (!python) console.warn('Fenic real-SDK tests skipped: supply FENIC_PYTHON with official fenic==0.13.0.');
const root = resolve(import.meta.dir, '..');
const reader = join(root, 'packs/fenic/sdk/hth-fenic-1.01-inspect-response-cache.py');
const generator = join(root, 'packs/fenic/sdk/hth-fenic-2.01-build-provider-routing-candidate.py');
const secret = 'HTH_SYNTHETIC_FENIC_SECRET';
const guard = `import sys
def guard(event, args):
    # urllib3 probes local IPv6 support at import with a short-lived ::1:0 bind.
    # Permit only that capability probe; every DNS/connect or other bind is blocked.
    if event == 'socket.bind' and args[1] == ('::1', 0):
        return
    if event in {'socket.connect', 'socket.getaddrinfo', 'socket.bind'}:
        print('HTH_NETWORK_ATTEMPT', file=sys.stderr)
        raise RuntimeError('network prohibited in local SDK checks')
sys.addaudithook(guard)
`;
let dir: string;
let path: string;
let env: Record<string, string>;
function run(script: string, overrides = {}) {
  const r = spawnSync(python!, ['-c', guard + '\nimport runpy\nrunpy.run_path(sys.argv[1], run_name="__main__")', script], {
    env: { ...env, ...overrides }, encoding: 'utf8', timeout: 20000,
  });
  expect(r.error).toBeUndefined();
  expect(r.stderr).not.toContain('HTH_NETWORK_ATTEMPT');
  expect(r.stdout + r.stderr).not.toContain(secret);
  return r;
}
function config(semantic: unknown) { writeFileSync(path, JSON.stringify({ semantic, private_fixture: secret })); }

describe.skipIf(!python)('Fenic v0.13.0 actual classes and local pack boundaries', () => {
  beforeEach(() => {
    dir = mkdtempSync(join(tmpdir(), 'hth-fenic-'));
    path = join(dir, 'session.json');
    env = { PATH: process.env.PATH ?? '', HOME: dir, HTH_PROFILE_LEVEL: '2', FENIC_SESSION_CONFIG_FILE: path,
      FENIC_OPENROUTER_MODEL: 'openai/gpt-4o-mini', FENIC_APPROVED_PROVIDERS: '["OpenAI"]' };
  });
  afterEach(() => rmSync(dir, { recursive: true, force: true }));

  test('actual SDK reproduces ignored enabled field and correct disabled default', () => {
    const r = spawnSync(python!, ['-c', guard + `
import importlib.metadata
from fenic import LLMResponseCacheConfig, SemanticConfig, OpenRouterLanguageModel
assert importlib.metadata.version('fenic') == '0.13.0'
assert set(LLMResponseCacheConfig.model_fields) == {'backend','ttl','max_size_mb','namespace'}
assert LLMResponseCacheConfig(enabled=False).model_dump() == LLMResponseCacheConfig().model_dump()
assert SemanticConfig().llm_response_cache is None
assert 'ignore' in OpenRouterLanguageModel.Provider.model_fields
assert 'exclude' not in OpenRouterLanguageModel.Provider.model_fields
assert LLMResponseCacheConfig(ttl='0m').ttl_seconds() == 0
assert LLMResponseCacheConfig(ttl='2592001s').ttl_seconds() == 2592001
`], { env, encoding: 'utf8', timeout: 20000 });
    expect(r.error).toBeUndefined(); expect(r.status).toBe(0); expect(r.stderr).not.toContain('HTH_NETWORK_ATTEMPT');
  });
  test.each([null, { llm_response_cache: null }])('disabled export is recognized: %p', semantic => {
    config(semantic); const r = run(reader); expect(r.status).toBe(0);
    expect(JSON.parse(r.stdout)).toEqual({ scope: 'exported-config-only', cache_enabled: false });
  });
  test('enabled export reports bounded settings without namespace', () => {
    config({ llm_response_cache: { ttl: '30m', max_size_mb: 64, namespace: secret } });
    const r = run(reader); expect(r.status).toBe(1);
    expect(JSON.parse(r.stdout)).toEqual({ scope: 'exported-config-only', cache_enabled: true, ttl_seconds: 1800, max_size_mb: 64 });
  });
  test.each([
    { enabled: false }, { ttl: '0m' }, { ttl: '2592001s' }, { ttl: '31d' }, { ttl: secret }, { max_size_mb: 0 },
  ])('unknown or unsafe cache does not pass: %p', cache => {
    config({ llm_response_cache: cache }); const r = run(reader); expect(r.status).toBe(2); expect(r.stdout).toBe('');
  });
  test.each([{}, [], 'bad'].map(value => ({ value })))('incomplete semantic export stays unknown: %p', ({ value }) => {
    config(value); expect(run(reader).status).toBe(2);
  });
  test('malformed, oversized, missing and symlink inputs stay unknown', () => {
    expect(run(reader).status).toBe(2);
    writeFileSync(path, '{"secret":"' + secret); expect(run(reader).status).toBe(2);
    writeFileSync(path, ' '.repeat(1048577)); expect(run(reader).status).toBe(2);
    const link = join(dir, 'link'); symlinkSync(path, link);
    expect(run(reader, { FENIC_SESSION_CONFIG_FILE: link }).status).toBe(2);
  });
  test.each(['0', '1', '5', 'invalid'])('profile %s refuses both packs', profile => {
    config(null); expect(run(reader, { HTH_PROFILE_LEVEL: profile }).status).toBe(2);
    expect(run(generator, { HTH_PROFILE_LEVEL: profile }).status).toBe(2);
  });
  test('candidate uses real SDK fields without a session, catalog, key or inference', () => {
    const r = run(generator); expect(r.status).toBe(0);
    expect(JSON.parse(r.stdout)).toEqual({ model_name: 'openai/gpt-4o-mini', profiles: { approved: {
      models: [], provider: { data_collection: 'deny', only: ['OpenAI'] },
    } }, default_profile: 'approved' });
  });
  test.each(['[]', '["OpenAI","OpenAI"]', '{"only":["OpenAI"]}', '[123]', '["' + secret + '\\n"]'])('invalid provider input refuses: %s', providers => {
    const r = run(generator, { FENIC_APPROVED_PROVIDERS: providers }); expect(r.status).toBe(2); expect(r.stdout).toBe('');
  });
  test('invalid model and unknown extra-key documentation examples do not pass', () => {
    expect(run(generator, { FENIC_OPENROUTER_MODEL: secret + '\n' }).status).toBe(2);
    const text = readFileSync(join(root, 'packs/fenic/config/hth-fenic-1.01-disable-response-cache.jsonc'), 'utf8');
    const raw = text.split('\n').filter(line => !line.trimStart().startsWith('//')).join('\n');
    expect(JSON.parse(raw)).toEqual({ semantic: { llm_response_cache: null } });
  });
});
