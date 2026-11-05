// HTH Pack Contract: v1
// control: grok-api-3.1
// guide: https://howtoharden.com/guides/grok-api/#31-keep-files-private-and-expire-public-media-links
// profile: L1
// mode: read-only
// requires: Bun; XAI_API_KEY; HTH_MAX_PUBLIC_URL_HOURS(optional, default24)
// NIST SC-8/SI-12. Sources fetched 2026-11-05:
// https://docs.x.ai/developers/files/public-urls
// https://docs.x.ai/developers/files/managing-files
// Usage: bun <this-file>. GET metadata only; never fetches or prints bearer URLs.
import {get,pages,required,main,type Get} from './common';
// HTH Guide Excerpt: begin audit-public-links
export async function auditPublicLinks(env=process.env,read:Get=get,now=Date.now()){
  const token=required('XAI_API_KEY',env), max=Number(env.HTH_MAX_PUBLIC_URL_HOURS??24);
  if(!Number.isFinite(max)||max<1||max>720)throw new Error('PRECONDITION: HTH_MAX_PUBLIC_URL_HOURS must be 1..720');
  const url=new URL('https://api.x.ai/v1/files'); url.searchParams.set('limit','100');
  const files=await pages(url,token,'data','pagination_token','pagination_token',read);
  let publicLinks=0,unbounded=0,overPolicy=0; const seen=new Set();
  for(const file of files){
    if(!file||typeof file.id!=='string'||!file.id||seen.has(file.id))throw new Error('UNKNOWN: malformed or duplicate file');
    seen.add(file.id);
    if(file.public_url===undefined||file.public_url===null||file.public_url==='')continue;
    if(typeof file.public_url!=='string')throw new Error('UNKNOWN: malformed public URL state');
    publicLinks++;
    const expiry=file.public_url_expires_at;
    if(expiry===undefined||expiry===null||expiry===0){unbounded++;continue;}
    if(typeof expiry!=='number'||!Number.isFinite(expiry)||expiry<=0)throw new Error('UNKNOWN: invalid public URL expiration');
    if(expiry*1000-now>max*3600000)overPolicy++;
  }
  return {status:'REVIEW',files:files.length,publicLinks,unbounded,overPolicy,maxRemainingHours:max,limitation:'Metadata visible to this key; no URL/content/filename emitted. Review approved sharing and file-level expiry separately.'};
}
// HTH Guide Excerpt: end audit-public-links
if(import.meta.main)main(()=>auditPublicLinks());
