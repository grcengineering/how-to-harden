// Local assessment of documented effective settings, never Security Center check results.
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
const schema = JSON.parse(readFileSync(new URL('./settings-schema.json', import.meta.url), 'utf8'));
const object = v => v !== null && typeof v === 'object' && !Array.isArray(v);
const canonical = v => Array.isArray(v) ? JSON.stringify(v.map(canonical).sort()) : object(v)
  ? JSON.stringify(Object.keys(v).sort().map(k => [k, canonical(v[k])])) : JSON.stringify(v);
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export function validValue(type, v) {
  switch (type) {
    case 'boolean': return typeof v === 'boolean';
    case 'integer': return v === null || Number.isSafeInteger(v) && v >= 0;
    case 'string': return v === null || typeof v === 'string';
    case 'string_list': return Array.isArray(v) && v.every(s => typeof s === 'string') && new Set(v).size === v.length;
    case 'provisioning_mode': return ['jit_advanced','jit_permissive','login_only','scim_advanced','scim_permissive'].includes(v);
    case 'data_retention': return object(v) && (!Object.hasOwn(v,'all') || Object.keys(v).length === 1)
      && Object.values(v).every(x => object(x) && (x.type === 'indefinite'
        || x.type === 'fixed' && Number.isFinite(x.duration) && x.duration > 0 && ['day','month'].includes(x.timescale)));
    default: return false;
  }
}
export function assess(payload, baseline, expectedOrg) {
  if (!uuid.test(expectedOrg ?? '') || !object(payload) || payload.type !== 'effective_organization_settings'
    || payload.organization_id?.toLowerCase() !== expectedOrg.toLowerCase() || !Array.isArray(payload.settings)
    || !Array.isArray(payload.api_keys)) throw new Error('Invalid or wrong-organization settings evidence');
  if (!Array.isArray(baseline) || !baseline.length || baseline.length > 1000) throw new Error('An explicit nonempty operator baseline is required');
  const rows = new Map();
  for (const row of payload.settings) {
    if (!object(row) || typeof row.name !== 'string' || rows.has(row.name) || !validValue(row.type, row.value))
      throw new Error('Malformed/duplicate settings evidence');
    rows.set(row.name, row);
  }
  const seen = new Set();
  const checks = baseline.map(b => {
    if (!object(b) || typeof b.name !== 'string' || seen.has(b.name) || !schema[b.type]?.includes(b.name)
      || !validValue(b.type,b.value) || Object.keys(b).some(k => !['name','type','value'].includes(k)))
      throw new Error('Invalid, unknown, or duplicate baseline setting');
    seen.add(b.name);
    const actual = rows.get(b.name);
    // Missing means not admin-controllable/unavailable. Never coerce to false.
    const status = !actual ? 'unavailable' : actual.type !== b.type ? 'unknown'
      : canonical(actual.value) === canonical(b.value) ? 'matches_operator_baseline' : 'differs_from_operator_baseline';
    return {name:b.name,status};
  });
  const differs = checks.filter(c => c.status === 'differs_from_operator_baseline').length;
  const unknown = checks.filter(c => ['unavailable','unknown'].includes(c.status)).length;
  return {kind:'operator_effective_settings_assessment',native_security_center:false,
    checked:new Date().toISOString(),counts:{matches:checks.length-differs-unknown,differs,unknown},checks,
    unassessed_settings:payload.settings.length - checks.filter(c=>rows.has(c.name)).length,
    exit_code:unknown ? 2 : differs ? 1 : 0};
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    const result = assess(JSON.parse(readFileSync(process.argv[2],'utf8')),
      JSON.parse(readFileSync(process.argv[3],'utf8')), process.argv[4]);
    process.stdout.write(JSON.stringify(result,null,2)+'\n');
    process.exitCode = result.exit_code;
  } catch { console.error('Invalid evidence or baseline; no assessment completed.'); process.exitCode=2; }
}
