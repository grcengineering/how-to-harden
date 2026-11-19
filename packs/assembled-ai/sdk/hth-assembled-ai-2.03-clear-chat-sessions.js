// HTH Pack Contract: v1
//   control: assembled-ai-2.3
//   guide: https://howtoharden.com/guides/assembled-ai/#23-clear-chat-sessions-on-logout-and-account-switch
//   profile: L1
//   mode: mutating
//   requires: browser; initialized official window.assembled chat widget
// HTH Assembled AI 2.3: Clear Chat Sessions on Logout and Account Switch
// NIST: AC-12 | Official browser JavaScript API, available 2026-11-16.
// Source: https://support.assembled.com/hc/en-us/articles/33739515754637-Chat-widget-advanced-setup
// Integrate this module into your application's serialized logout/account-switch flow.
// The next JWT must come from your authenticated backend; never expose the signing key.
// HTH Guide Excerpt: begin clear-chat-sessions
export async function clearAssembledChatSession() {
  const widget = window.assembled;
  if (!widget || typeof widget.teardown !== "function") {
    throw new Error("Assembled widget teardown is unavailable; stop chat reinitialization.");
  }
  await widget.teardown({ clearSession: true });
  // Vendor teardown resolves after at most two seconds, even if the request fails.
  // Verify cal.assembledhq.com is allowed by connect-src and test server-side clearing.
}
// HTH Guide Excerpt: end clear-chat-sessions
