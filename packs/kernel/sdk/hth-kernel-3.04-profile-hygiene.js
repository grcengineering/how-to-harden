// Control: 3.4 Treat Browser Profiles as Credential Material
// Profile Level: L1 (Baseline)
// Frameworks: NIST 800-53 SC-28/AC-6, CIS Controls v8 3, SOC 2 CC6.1
// Guide: https://howtoharden.com/guides/kernel/
// Interface: Kernel SDK — https://www.kernel.sh/docs/auth/profiles

// HTH Guide Excerpt: begin single-writer-discipline
// Profiles persist cookies + local storage — live session tokens.
// Create the profile once, and give WRITE access (save_changes: true)
// to exactly one designated refresher workload. Saves replace the whole
// profile, and the browser that ends last overwrites the profile — so
// concurrent writers silently clobber each other.
await kernel.profiles.create({ name: 'crm-agent' });

// The ONE designated writer session:
const writer = await kernel.browsers.create({
  profile: { name: 'crm-agent', save_changes: true },
});
// NOTE: state persists when the browser is deleted or times out;
// browser.close() does NOT save profile state.
// HTH Guide Excerpt: end single-writer-discipline

// HTH Guide Excerpt: begin read-only-consumers
// Every other consumer loads the profile WITHOUT save_changes: state from
// untrusted browsing is discarded, never persisted into the trusted profile.
const reader = await kernel.browsers.create({
  profile: { name: 'crm-agent' },
});

// Browser pools enforce this for you: pooled browsers load their profile
// read-only — any save_changes is ignored (not rejected), so pooled
// browsers never write back to the profile.
// HTH Guide Excerpt: end read-only-consumers
