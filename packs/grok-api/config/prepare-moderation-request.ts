// HTH Pack Contract: v1
// control: grok-api-4.3
// guide: https://howtoharden.com/guides/grok-api/#43-apply-per-request-moderation-and-preserve-provenance
// profile: L1
// mode: read-only
// requires: Bun
// NIST AC-3. Source: https://docs.x.ai/developers/advanced-api-usage/custom-moderation-controls (2026-11-05)
// Usage: bun <this-file>. Emits synthetic JSON only; no key, network or tenant write.
// HTH Guide Excerpt: begin prepare-guidelines
export function request(){return {
  model:'grok-4.7',input:'Write a short, suitable-for-work explanation of rain.',
  guidelines:['nsfw','violence','profanity'].map(category=>({type:'policy',category,behavior:'decline'})),
};}
if(import.meta.main)console.log(JSON.stringify(request(),null,2));
// HTH Guide Excerpt: end prepare-guidelines
