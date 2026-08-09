// =============================================================================
// HTH Vercel Control 3.5: Protect High-Value Routes with Vercel BotID
// Profile Level: L2 (Walk)
// Frameworks: NIST SC-5, SI-4, IA-2
// Source: https://howtoharden.com/guides/vercel/#35-protect-high-value-routes-with-vercel-botid
// Reference: https://vercel.com/docs/botid/get-started
// Prereq: `npm i botid` (or pnpm/yarn/bun equivalent) in a project deployed on
// Vercel. Next.js App Router shown; Nuxt/SvelteKit variants are in the docs.
// The three regions below map to three files in the application.
// =============================================================================

// HTH Guide Excerpt: begin wrap-next-config
// next.config.js — route the BotID challenge traffic through the app's own
// origin so ad-blockers and third-party scripts cannot strip the challenge.
// Skipping this wrapper silently disables enforcement.
import { withBotId } from 'botid/next/config';

const nextConfig = {
  // Your existing Next.js config
};

export default withBotId(nextConfig);
// HTH Guide Excerpt: end wrap-next-config

// HTH Guide Excerpt: begin declare-protected-routes
// instrumentation-client.js (Next.js 15.3+) — declare every protected
// (path, method) pair client-side. A route checked server-side but never
// declared here will make checkBotId() fail: this declaration is what
// attaches the classification headers that arm the challenge.
import { initBotId } from 'botid/client/core';

initBotId({
  protect: [
    {
      // High-value API endpoint: checkout
      path: '/api/checkout',
      method: 'POST',
    },
    {
      // Wildcards can expand multiple segments:
      // /team/*/activate matches /team/a/activate, /team/a/b/activate, ...
      path: '/team/*/activate',
      method: 'POST',
    },
    {
      // Trailing wildcard for dynamic routes
      path: '/api/user/*',
      method: 'POST',
    },
  ],
});
// HTH Guide Excerpt: end declare-protected-routes

// HTH Guide Excerpt: begin gate-server-handler
// app/api/checkout/route.js — gate the handler server-side. This is
// authorization code: it belongs in the handler, not in middleware.
// Local development always returns isBot: false unless developmentOptions
// is configured on checkBotId() — verify against a deployed environment.
import { checkBotId } from 'botid/server';
import { NextResponse } from 'next/server';

export async function POST(request) {
  // Check if the request is from a bot
  const verification = await checkBotId();

  if (verification.isBot) {
    return NextResponse.json(
      { error: 'Bot detected. Access denied.' },
      { status: 403 },
    );
  }

  // Process the legitimate checkout request
  const body = await request.json();

  // Your checkout logic here
  const order = await processCheckout(body);

  return NextResponse.json({
    success: true,
    orderId: order.id,
  });
}

async function processCheckout(data) {
  // Implement your checkout logic
  return { id: 'order-123' };
}
// HTH Guide Excerpt: end gate-server-handler
