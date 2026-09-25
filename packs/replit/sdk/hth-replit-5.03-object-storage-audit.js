// HTH Pack Contract: v1
//   control: replit-5.3
//   guide:   https://howtoharden.com/guides/replit/#53-segment-app-storage-per-project-dev-and-prod-share-it
//   profile: L2
//   mode:    read-only
//   requires: runs inside a Replit App (the SDK authenticates implicitly there); REPLIT_BUCKET_ID(optional, defaults to the App's default bucket)
// =============================================================================
// HTH Replit Control 5.3: Segment App Storage per Project (Dev and Prod Share It)
// Profile Level: L2 (Walk) | Plans: all
// Frameworks: NIST 800-53 AC-3/AC-6 | CIS Controls v8 3.3
// Interface: @replit/object-storage (official App Storage JS SDK)
//   https://docs.replit.com/features/sdks/object-storage-javascript-sdk
//   https://docs.replit.com/features/data-and-storage/object-storage
//
// SCOPE NOTE: each App Storage bucket is exclusive to the project that created it — it
// cannot be attached to another project — and the SAME bucket serves that project's
// development AND production environments. So the question this pack answers is "what
// would dev-time Agent or code activity be able to read in the data production serves?",
// not "which Apps is this bucket attached to" (there is no attach step). The SDK is not a
// remote admin API: it authenticates only inside the running Replit App.
//
// Install:  npm install @replit/object-storage
// Run:      node hth-replit-5.03-object-storage-audit.js [object-name]   (from the App's Shell)
// Exit codes: 0 compliant | 1 finding | 2 error (nothing was verified)

import { Client } from '@replit/object-storage';

// Outside a Replit App the SDK THROWS (it cannot reach the App's credential sidecar)
// instead of returning a Result. Map every thrown error to exit 2: an uncaught error
// would exit 1, which this pack reserves for findings.
const bail = (e) => {
  console.error('5.3 ERROR: the SDK threw — nothing was audited (run this from the App\'s Shell):', e?.message ?? e);
  process.exit(2);
};
process.on('uncaughtException', bail);
process.on('unhandledRejection', bail);

const bucketId = process.env.REPLIT_BUCKET_ID;
const client = new Client(bucketId ? { bucketId } : undefined);
let finding = false;

// HTH Guide Excerpt: begin storage-inventory
// Inventory what this project's bucket holds. Every object listed here is readable by any
// code running in the project — in development as well as in production.
const { ok, value: objects, error } = await client.list();
if (!ok) {
  console.error('5.3 ERROR: could not list bucket contents — nothing was audited:', error);
  process.exit(2);
}
console.log(`5.3 Bucket contains ${objects.length} objects.`);
for (const obj of objects.slice(0, 50)) {
  console.log(`  ${obj.name}`);
}
if (objects.length > 50) console.log(`  … and ${objects.length - 50} more`);
// HTH Guide Excerpt: end storage-inventory

// HTH Guide Excerpt: begin storage-sensitivity-flag
// Flag objects whose names suggest they do not belong in storage that development work can
// reach. Buckets cannot be shared across projects, so the only real segmentation is to keep
// such data in its own project — or delete it (App Storage → Settings view → Delete Bucket
// removes the bucket and every object in it, irreversibly: back up first).
const SENSITIVE = /(\.env|secret|credential|password|token|key|dump|backup|export|customer|pii)/i;
const flagged = objects.filter((o) => SENSITIVE.test(o.name));
if (flagged.length > 0) {
  finding = true;
  console.warn(`5.3 REVIEW: ${flagged.length} object(s) look sensitive — this bucket is readable from development as well as production:`);
  for (const f of flagged) console.warn(`  ${f.name}`);
  console.warn('  Move sensitive objects into their own project, or delete them.');
} else {
  console.log('5.3 PASS: no obviously sensitive object names in this bucket.');
}
// HTH Guide Excerpt: end storage-sensitivity-flag

// HTH Guide Excerpt: begin storage-existence-check
// Targeted check: prove that a specific object is gone from this project's bucket (for
// example after removing a sensitive export). A failed call is reported as an error, never
// as "not present" — an error is not evidence that the object was removed.
const target = process.argv[2];
if (target) {
  const r = await client.exists(target);
  if (!r.ok) {
    console.error('5.3 ERROR: exists() failed — the result is NOT evidence of removal:', r.error);
    process.exit(2);
  }
  if (r.value) {
    finding = true;
    console.log(`5.3 STILL PRESENT in this project's bucket: ${target}`);
  } else {
    console.log(`5.3 NOT PRESENT in this project's bucket: ${target}`);
  }
}
// HTH Guide Excerpt: end storage-existence-check

process.exit(finding ? 1 : 0);
