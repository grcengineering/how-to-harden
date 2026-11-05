// HTH Pack Contract: v1
// control: grok-api-5.1
// guide: https://howtoharden.com/guides/grok-api/#51-export-administrative-evidence-and-contain-all-credential-planes
// profile: L1
// mode: read-only
// requires: Bun; XAI_MANAGEMENT_API_KEY; XAI_TEAM_ID; HTH_AUDIT_FROM; HTH_AUDIT_TO
// NIST AU-2/AU-6. Source: https://docs.x.ai/developers/rest-api-reference/management/audit (2026-11-05)
// Usage: bun <this-file>. Counts metadata only; no user, event descriptions or raw export printed.
import {get,pages,required,main,type Get} from './common';
// HTH Guide Excerpt: begin count-bounded-audit
export async function auditEvents(env=process.env,read:Get=get){
  const token=required('XAI_MANAGEMENT_API_KEY',env),team=required('XAI_TEAM_ID',env);
  const from=required('HTH_AUDIT_FROM',env),to=required('HTH_AUDIT_TO',env);
  if(!Number.isFinite(Date.parse(from))||!Number.isFinite(Date.parse(to))||Date.parse(from)>=Date.parse(to))throw new Error('PRECONDITION: valid increasing audit timestamps required');
  const identity=await read(new URL('https://management-api.x.ai/auth/management-keys/validation'),token);
  if(identity.scope!=='SCOPE_TEAM'||identity.scopeId!==team)throw new Error('UNKNOWN: management key team identity mismatch');
  const url=new URL(`https://management-api.x.ai/audit/teams/${encodeURIComponent(team)}/events`);
  Object.entries({pageSize:'100',eventTimeFrom:from,eventTimeTo:to}).forEach(([k,v])=>url.searchParams.set(k,v));
  const events=await pages(url,token,'events','nextPageToken','pageToken',read),seen=new Set();
  for(const event of events){
    const time=Date.parse(event?.eventTime);
    if(typeof event?.eventId!=='string'||!event.eventId||seen.has(event.eventId)||!Number.isFinite(time)||time<Date.parse(from)||time>Date.parse(to))throw new Error('UNKNOWN: invalid, duplicate or out-of-window audit event');
    seen.add(event.eventId);
  }
  return {status:'REVIEW',from,to,count:events.length,limitation:'Administrative metadata only; absence of events does not prove absence of inference/tool misuse. Configure protected evidence export separately.'};
}
// HTH Guide Excerpt: end count-bounded-audit
if(import.meta.main)main(()=>auditEvents());
