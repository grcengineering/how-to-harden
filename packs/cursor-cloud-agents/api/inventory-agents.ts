// HTH Pack Contract: v1
// control: cursor-cloud-agents-5.2
// guide: https://howtoharden.com/guides/cursor-cloud-agents/#52-inventory-and-stop-runs-before-removing-access
// profile: L1
// mode: read-only
// requires: Bun; CURSOR_API_KEY(personal Cloud Agent API key)
// NIST AU-2/IR-4. Source: https://cursor.com/docs/cloud-agent/api/endpoints (2026-11-05)
// Usage: bun <this-file>. GET only; current API lists THIS user's agents, not all team members.
import {get,pages,required,main,type Get} from './common';
// HTH Guide Excerpt: begin inventory-current-user-agents
export async function inventoryAgents(env=process.env,read:Get=get){
  const token=required('CURSOR_API_KEY',env),url=new URL('https://api.cursor.com/v1/agents');
  url.searchParams.set('limit','100');url.searchParams.set('includeArchived','true');
  const items=await pages(url,token,'items','nextCursor','cursor',read),byStatus:Record<string,number>={},seen=new Set();
  for(const item of items){
    if(typeof item?.id!=='string'||!item.id||seen.has(item.id)||typeof item.status!=='string'||!['ACTIVE','ARCHIVED'].includes(item.status))throw new Error('UNKNOWN: malformed, duplicate or unknown agent state');
    seen.add(item.id);byStatus[item.status]=(byStatus[item.status]??0)+1;
  }
  return {status:'REVIEW',scope:'authenticated user only',count:items.length,byStatus,limitation:'Sparse durable agents; run/owner/runtime details need Get Agent/List Runs. Not a team-wide inventory, stop, credential revocation or deletion.'};
}
// HTH Guide Excerpt: end inventory-current-user-agents
if(import.meta.main)main(()=>inventoryAgents());
