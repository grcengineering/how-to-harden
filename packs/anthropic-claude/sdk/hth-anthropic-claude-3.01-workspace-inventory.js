// HTH Control anthropic-api 2.1: Workspace inventory (read-only)
// Profile: L1 | Requires: existing ANTHROPIC_ADMIN_KEY(Console admin)
// https://howtoharden.com/guides/anthropic-api/#21-segment-workspaces-by-environment
// Uses the pinned official SDK installed in packs/claude-enterprise/sdk.
import {scopedClient,privateEvidence} from '../../claude-enterprise/sdk/lib/native.js';
import {pathToFileURL} from 'node:url';
// HTH Guide Excerpt: begin native-sdk-workspace-inventory
export async function workspaceInventory(key,transport){
  const client=scopedClient(key,transport),rows=[],ids=new Set(),seen=new Set();let after_id;
  while(true){
    const response=await client.organization.workspaces.list({include_default:true,limit:1000,...(after_id?{after_id}:{})}).asResponse();
    const data=await response.json();
    if(!Array.isArray(data.data)||typeof data.has_more!=='boolean')throw Error('Incomplete native page');
    for(const row of data.data){
      if(row.type!=='workspace'||typeof row.id!=='string'||ids.has(row.id)||!row.data_residency)throw Error('Invalid/repeated workspace');
      ids.add(row.id);rows.push(row);
    }
    if(!data.has_more)break;after_id=data.last_id;if(typeof after_id!=='string'||!after_id||seen.has(after_id)||seen.size>=10000)throw Error('Invalid native cursor');seen.add(after_id);
  }
  return rows; // Includes Default Workspace; does not prove segmentation/residency policy.
}
if(process.argv[1]&&import.meta.url===pathToFileURL(process.argv[1]).href){
  try{privateEvidence('workspaces',await workspaceInventory(process.env.ANTHROPIC_ADMIN_KEY));}
  catch{console.error('Incomplete workspace inventory; no success file.');process.exitCode=2;}
}
// HTH Guide Excerpt: end native-sdk-workspace-inventory
