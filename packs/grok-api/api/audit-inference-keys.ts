// HTH Pack Contract: v1
// control: grok-api-1.2
// guide: https://howtoharden.com/guides/grok-api/#12-audit-key-expiry-limits-and-owner-lifecycle
// profile: L1
// mode: read-only
// requires: Bun; XAI_MANAGEMENT_API_KEY; XAI_TEAM_ID; HTH_TEAM_ADMIN_CONFIRMED=1
// NIST AC-2/AC-6. Source fetched 2026-11-05:
// https://docs.x.ai/developers/rest-api-reference/management/auth
// Usage: bun <this-file>. GET only; does not mint/rotate/delete any key.
import {get, pages, required, main, type Get} from './common';
// HTH Guide Excerpt: begin audit-key-metadata
export async function auditKeys(env=process.env, read:Get=get) {
  if (env.HTH_TEAM_ADMIN_CONFIRMED!=='1') throw new Error('PRECONDITION: team admin must set HTH_TEAM_ADMIN_CONFIRMED=1; member lists are incomplete');
  const token=required('XAI_MANAGEMENT_API_KEY',env), team=required('XAI_TEAM_ID',env);
  const identity=await read(new URL('https://management-api.x.ai/auth/management-keys/validation'),token);
  if(identity.scope!=='SCOPE_TEAM'||identity.scopeId!==team) throw new Error('UNKNOWN: management key is not authoritatively scoped to requested team');
  const url=new URL(`https://management-api.x.ai/auth/teams/${encodeURIComponent(team)}/api-keys`);
  url.searchParams.set('pageSize','100'); url.searchParams.set('activeOnly','false');
  const keys=await pages(url,token,'apiKeys','paginationToken','paginationToken',read);
  let enabled=0, unboundedExpiry=0, wildcardAcl=0, missingLimits=0;
  const seen=new Set();
  for(const key of keys){
    if(!key || key.teamId!==team || typeof key.apiKeyId!=='string' || !key.apiKeyId || seen.has(key.apiKeyId) || typeof key.disabled!=='boolean' || !Array.isArray(key.aclStrings) || !key.aclStrings.every((x:unknown)=>typeof x==='string')) throw new Error('UNKNOWN: malformed, duplicated or wrong-team key metadata');
    seen.add(key.apiKeyId);
    if(key.disabled) continue;
    enabled++;
    if(!key.expireTime) unboundedExpiry++;
    else if(typeof key.expireTime!=='string'||!Number.isFinite(Date.parse(key.expireTime))) throw new Error('UNKNOWN: invalid key expiration');
    if(key.aclStrings.some((x:string)=>x.includes('*'))) wildcardAcl++;
    if(!Number.isInteger(key.qps)||key.qps<=0||!Number.isInteger(key.qpm)||key.qpm<=0||typeof key.tpm!=='string'||!/^\d+$/.test(key.tpm)||BigInt(key.tpm)<=0n) missingLimits++;
  }
  return {status:'REVIEW',scope:'team-admin attested; team ID verified',total:keys.length,enabled,unboundedExpiry,wildcardAcl,missingLimits,limitation:'Metadata inventory; no key material, names, user identifiers or raw response emitted. Not a compliance verdict.'};
}
// HTH Guide Excerpt: end audit-key-metadata
if(import.meta.main) main(()=>auditKeys());
