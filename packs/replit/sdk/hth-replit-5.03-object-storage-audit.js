// Control: 5.3 Keep Object Storage Attachment-Scoped
// Profile Level: L2 (Walk) | Plans: all
// Frameworks: NIST 800-53 AC-3/AC-6 | CIS Controls v8 3.3
// Guide: https://howtoharden.com/guides/replit/#53-keep-object-storage-attachment-scoped
// Interface: @replit/object-storage (official App Storage JS SDK)
//   https://docs.replit.com/features/sdks/object-storage-javascript-sdk
//   https://docs.replit.com/features/data-and-storage/object-storage
//
// SCOPE NOTE: this SDK authenticates implicitly INSIDE the Replit environment — it is not a
// remote admin API. Replit documents NO public/private bucket ACLs, per-object permissions,
// or signed-URL controls; the only documented access boundary is which Apps a bucket is
// attached to (attach/detach in the App Storage UI). Do not invent ACL calls.
//
// Install:  npm install @replit/object-storage
// Run:      node hth-replit-5.03-object-storage-audit.js

import { Client } from '@replit/object-storage';

const client = new Client();

// HTH Guide Excerpt: begin storage-inventory
// Inventory what the CURRENTLY ATTACHED bucket holds. Because buckets are account-wide and
// available to every App you attach them to, this listing is the practical answer to
// "what data would a newly attached App be able to read?"
const { ok, value: objects, error } = await client.list();
if (!ok) {
  console.error('5.3 FAIL: could not list bucket contents:', error);
  process.exit(1);
}
console.log(`5.3 Bucket contains ${objects.length} objects.`);
for (const obj of objects.slice(0, 50)) {
  console.log(`  ${obj.name}`);
}
if (objects.length > 50) console.log(`  … and ${objects.length - 50} more`);
// HTH Guide Excerpt: end storage-inventory

// HTH Guide Excerpt: begin storage-sensitivity-flag
// Flag objects whose names suggest they do not belong in a bucket shared with experimental
// Apps. Bucket-per-purpose is the only segmentation Replit documents — a hit here means the
// bucket should be split, or detached from every App that does not need it.
const SENSITIVE = /(\.env|secret|credential|password|token|key|dump|backup|export|customer|pii)/i;
const flagged = objects.filter((o) => SENSITIVE.test(o.name));
if (flagged.length > 0) {
  console.warn(`5.3 REVIEW: ${flagged.length} object(s) look sensitive — confirm every App attached to this bucket should read them:`);
  for (const f of flagged) console.warn(`  ${f.name}`);
  console.warn('  Detach unneeded Apps: App Storage → Settings view → select bucket → "Remove Bucket from Repl".');
} else {
  console.log('5.3 PASS: no obviously sensitive object names in this bucket.');
}
// HTH Guide Excerpt: end storage-sensitivity-flag

// HTH Guide Excerpt: begin storage-existence-check
// Targeted check: confirm whether a specific object is reachable from THIS App. Use it to
// prove a detach actually revoked access — run it from an App that should no longer have it.
const target = process.argv[2];
if (target) {
  const { ok: exists, value: present } = await client.exists(target);
  console.log(
    exists && present
      ? `5.3 REACHABLE from this App: ${target}`
      : `5.3 NOT reachable from this App: ${target}`
  );
}
// HTH Guide Excerpt: end storage-existence-check
