// HTH Pack Contract: v1
// control: cursor-origin-3.1
// guide: https://howtoharden.com/guides/cursor-origin/#31-install-apps-on-selected-repositories-with-minimal-scopes
// profile: L1
// mode: read-only
// requires: Bun; ORIGIN_APP_JWT(existing app signing JWT; not a Cursor Admin key)
// NIST AC-6. Source: https://cursor.com/docs/api/origin (2026-11-05)
// Usage: bun <this-file>. No key generation, token minting, installation or deletion.
import {get,pages,required,main,type Get} from './common';
// HTH Guide Excerpt: begin inventory-app-specific-grants
export async function inventoryInstallations(env=process.env,read:Get=get){
  const token=required('ORIGIN_APP_JWT',env),url=new URL('https://api.cursor.com/v1/origin/app/installations');
  url.searchParams.set('pageSize','100');
  const items=await pages(url,token,'installations','nextPageToken','pageToken',read),seen=new Set();
  let allRepos=0,writeGrants=0,userDelegation=0;
  for(const item of items){
    if(typeof item?.id!=='string'||!item.id||seen.has(item.id)||!['all','selected'].includes(item.repoSelectionMode)||!Array.isArray(item.scopes)||!item.scopes.every((x:unknown)=>typeof x==='string'))throw new Error('UNKNOWN: invalid or duplicate app installation');
    seen.add(item.id);
    if(item.repoSelectionMode==='all')allRepos++;
    if(item.scopes.some((s:string)=>s.endsWith(':write')||s.endsWith(':create')))writeGrants++;
    if(item.scopes.includes('namespace:user_tokens:write'))userDelegation++;
  }
  return {status:'REVIEW',scope:'authenticated app only',installations:items.length,allRepos,writeGrants,userDelegation,limitation:'Reconcile selected repository IDs and every app in GUI; this is not org-wide inventory or a compliance verdict.'};
}
// HTH Guide Excerpt: end inventory-app-specific-grants
if(import.meta.main)main(()=>inventoryInstallations());
