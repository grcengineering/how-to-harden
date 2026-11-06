// HTH Control claude-enterprise 4.1: Effective spend-limit inventory (read-only)
// Profile: L2 | Requires: existing ANTHROPIC_ADMIN_KEY(read:spend_limits)
// https://howtoharden.com/guides/claude-enterprise/#41-enforce-per-member-spend-limits
// Source: official @anthropic-ai/sdk 1.6.0 organization/spend-limits/effective
import {scopedClient,privateEvidence} from './lib/native.js';
import {pathToFileURL} from 'node:url';
// HTH Guide Excerpt: begin native-sdk-spend-inventory
export async function spendInventory(key,transport){
  const client=scopedClient(key,transport),rows=[],seen=new Set();let page;
  while(true){
    const response=await client.organization.spendLimits.effective.list({period:['monthly'],limit:1000,...(page?{page}:{})}).asResponse();
    const data=await response.json();
    if(!Array.isArray(data.data)||!Object.hasOwn(data,'next_page')||!(data.next_page===null||typeof data.next_page==='string'&&data.next_page.length>0))throw Error('Incomplete native page');
    for(const row of data.data){
      if(!row.scope||typeof row.period!=='string'||!Object.hasOwn(row,'amount')||!(row.amount===null||typeof row.amount==='string'&&/^\d+$/.test(row.amount)))throw Error('Invalid spend row');
      rows.push(row);
    }
    if(data.next_page===null)break;page=data.next_page;if(seen.has(page)||seen.size>=10000)throw Error('Repeated/unterminated cursor');seen.add(page);
  }
  return rows; // No native policy score: null, unknown scopes and future periods require review.
}
if(process.argv[1]&&import.meta.url===pathToFileURL(process.argv[1]).href){
  try{privateEvidence('effective-spend-limits',await spendInventory(process.env.ANTHROPIC_ADMIN_KEY));}
  catch{console.error('Incomplete spend evidence; no success file.');process.exitCode=2;}
}
// HTH Guide Excerpt: end native-sdk-spend-inventory
