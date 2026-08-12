// Control: 5.3 Capture Session Telemetry and Replays for High-Risk Automations
// Profile Level: L2 (Hardened)
// Frameworks: NIST 800-53 SI-4/AU-14, CIS Controls v8 8, SOC 2 CC7.2
// Guide: https://howtoharden.com/guides/kernel/
// Interface: Kernel SDK — https://www.kernel.sh/docs/browsers/telemetry/overview
//   and https://www.kernel.sh/docs/browsers/replays

// HTH Guide Excerpt: begin default-telemetry-baseline
// Default set (control, connection, system, captcha) is lightweight —
// enable it broadly as the fleet baseline.
const browser = await kernel.browsers.create({
  telemetry: { enabled: true },
});
// HTH Guide Excerpt: end default-telemetry-baseline

// HTH Guide Excerpt: begin deep-capture-high-risk
// High-risk automations (sensitive targets, authenticated sessions):
// add per-category browser telemetry — console + network show what the
// page actually did, not just what the agent intended.
const sensitive = await kernel.browsers.create({
  telemetry: {
    browser: {
      console: { enabled: true },
      network: { enabled: true },
    },
  },
});
// Events stream live (SDK/CLI/SSE) or can be read back after the fact.
// SKIP deep capture and replays for ZDR-scoped workloads (Control 4.4).
// HTH Guide Excerpt: end deep-capture-high-risk

// HTH Guide Excerpt: begin replay-evidence
// Replays are explicit MP4 recordings — start before the sensitive
// workflow, stop after, and archive the download with your case record.
// Retention is plan-gated (7d Hobbyist / 30d Start-Up / custom Enterprise).
const replay = await kernel.browsers.replays.start(sensitive.session_id);
// ... agent workflow runs ...
await kernel.browsers.replays.stop(replay.replay_id, { id: sensitive.session_id });
const video = await kernel.browsers.replays.download(replay.replay_id, {
  id: sensitive.session_id,
});
// Each replay also carries a replay_view_url for interactive review.
// HTH Guide Excerpt: end replay-evidence
