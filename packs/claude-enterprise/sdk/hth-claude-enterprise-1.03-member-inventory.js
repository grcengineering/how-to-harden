// HTH Pack Contract: v1
//   control: claude-enterprise-1.3
//   guide: https://howtoharden.com/guides/claude-enterprise/#13-apply-least-privilege-roles-and-groups
//   profile: L1
//   mode: read-only
//   requires: ANTHROPIC_ADMIN_KEY(Enterprise read:members)
// Source: official @anthropic-ai/sdk 1.6.0 organization/users.ts; no native Compliance settings resource in inspected SDK.
import Anthropic from '@anthropic-ai/sdk';
import {mkdtempSync,writeFileSync,renameSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {pathToFileURL} from 'node:url';
// HTH Guide Excerpt: begin native-sdk-member-inventory
export async function inventory(apiKey, transport) {
  if (typeof apiKey !== 'string' || !apiKey || /\s/.test(apiKey)) throw new Error('Invalid credential');
  const client = new Anthropic({apiKey,authToken:null,baseURL:'https://api.anthropic.com',
    maxRetries:0,timeout:30_000,logLevel:'off',openTelemetry:false,...(transport ? {fetch:transport} : {})});
  const rows=[], ids=new Set(),cursors=new Set();
  let cursor, pages=0;
  while (true) {
    // Read the raw native response: SDK Page defaults missing has_more to false.
    const response=await client.organization.users.list({limit:1000,...(cursor?{after_id:cursor}:{})}).asResponse();
    const page=await response.json();
    if (!Array.isArray(page.data) || typeof page.has_more!=='boolean') throw new Error('Invalid page envelope');
    for (const row of page.data) {
      if (row.type !== 'user' || !/^user_[A-Za-z0-9]+$/.test(row.id) || ids.has(row.id)
        || typeof row.role !== 'string' || typeof row.email !== 'string') throw new Error('Invalid/repeated member');
      ids.add(row.id); rows.push(row);
    }
    if (!page.has_more) break;
    cursor=page.last_id;
    if (typeof cursor!=='string'||!cursor||cursors.has(cursor)||++pages>=10000) throw new Error('Invalid pagination cursor');
    cursors.add(cursor);
  }
  return rows; // Retrieval is not a least-privilege or SSO pass verdict.
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const dir=mkdtempSync(join(tmpdir(),'hth-anthropic-sdk-')); process.umask(0o077);
  try {
    const rows=await inventory(process.env.ANTHROPIC_ADMIN_KEY);
    writeFileSync(join(dir,'members.pending'),JSON.stringify(rows,null,2)+'\n',{mode:0o600,flag:'wx'});
    renameSync(join(dir,'members.pending'),join(dir,'members.json'));
    console.log(`Complete private member inventory: ${join(dir,'members.json')}`);
  } catch { rmSync(join(dir,'members.pending'),{force:true}); console.error('Member inventory incomplete; no success evidence written.'); process.exitCode=2; }
}
// HTH Guide Excerpt: end native-sdk-member-inventory
