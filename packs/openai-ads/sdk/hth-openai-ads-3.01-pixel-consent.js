// HTH Pack Contract: v1
//   control: openai-ads-3.1
//   guide: https://howtoharden.com/guides/openai-ads/#31-gate-browser-measurement-and-minimize-signals
//   profile: L1
//   mode: mutating
//   requires: official Measurement Pixel oaiq queue and an approved pixelId
// Source: https://developers.openai.com/ads/measurement-pixel#control-measurement-consent
// NIST 800-53 AC-4, PT-2. Import has no effect; wire to the real consent manager.
// HTH Guide Excerpt: begin pixel-consent
export function initializeConsentControlledPixel(oaiq, pixelId) {
  if (typeof oaiq !== "function" || typeof pixelId !== "string" || !pixelId.trim()) {
    throw new Error("Load the official Pixel queue and choose the approved Pixel ID");
  }
  // Queue this BEFORE init; the vendor default is consent=true.
  oaiq("consent", false);
  oaiq("init", { pixelId, debug: false });
  return {
    grant: () => oaiq("consent", true),
    withdraw: () => oaiq("consent", false),
  };
}
// Connect grant/withdraw to actual consent state before emitting events.
// Consent is not a per-Pixel isolation mechanism. For multiple pixels, review
// every recipient and keep server-side forwarding consistent with withdrawal.
// HTH Guide Excerpt: end pixel-consent
