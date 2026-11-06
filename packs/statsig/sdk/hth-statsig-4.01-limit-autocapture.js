// HTH Pack Contract: v1
//   control: statsig-4.1
//   guide: https://howtoharden.com/guides/statsig/#41-minimize-replay-and-autocapture
//   profile: L2
//   mode: read-only
//   requires: browser application, @statsig/web-analytics 3.33.7, reviewed capture routes/consent
// HTH Statsig 4.1 — Minimize Replay and Autocapture; NIST PT-3, SI-12; SOC 2 CC6.1
// Sources: https://docs.statsig.com/webanalytics/overview
// https://github.com/statsig-io/js-client-monorepo/blob/main/packages/web-analytics/src/AutoCaptureOptions.ts (2026-11-05)
import { StatsigAutoCapturePlugin } from '@statsig/web-analytics';

// HTH Guide Excerpt: begin limit-autocapture
// Import into the existing reviewed browser app. No client is initialized here.
// Empty routes deny all capture. Pass only explicit, nonsensitive public-page URLs.
export function limitedCaptureOptions(approvedPageURLs = []) {
  if (!Array.isArray(approvedPageURLs) || approvedPageURLs.length > 100) throw new Error('Supply reviewed exact page URLs');
  const allowed = new Set(approvedPageURLs.map(value => {
    const url = new URL(value);
    if (url.protocol !== 'https:' || url.username || url.password || url.search || url.hash) throw new Error('Only reviewed HTTPS pages without query/fragment');
    return url.href;
  }));
  return {
    captureCopyText: false,
    consoleLogAutoCaptureSettings: { enabled: false },
    eventFilterFunc(event) {
      // Keep only page views. Clicks/copies/forms/errors/console events are denied.
      if (event?.eventName !== 'auto_capture::page_view') return false;
      try {
        // SDK 3.33.7 emits page_url/current_url, but query parameters can overwrite
        // metadata keys. Read the browser's actual location independently; never
        // authorize a route from an event's query-derived metadata alone.
        const href = globalThis.window?.location?.href;
        if (typeof href !== 'string') return false; // no browser/SSR: deny
        const url = new URL(href);
        return url.protocol === 'https:' && !url.username && !url.password &&
          !url.search && !url.hash && allowed.has(url.href) &&
          event?.metadata?.page_url === url.href && event?.metadata?.current_url === url.href;
      } catch { return false; }
    },
  };
}
export function createLimitedCapturePlugin(approvedPageURLs = []) {
  return new StatsigAutoCapturePlugin(limitedCaptureOptions(approvedPageURLs));
}
// This filters event types/page URLs; it does not redact every metadata field,
// manual logEvent, user identity, another plugin or Session Replay. Review actual
// SDK payloads and consent separately. Do not initialize a capture plugin as a test.
// HTH Guide Excerpt: end limit-autocapture
