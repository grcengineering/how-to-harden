// Public-contract fixtures only; no account, key creation or OpenAI request.
// Requires actual openai@7.51.0. Sources and limitations in Ads coverage ledger.
import { afterAll, describe, expect, test } from "bun:test";
import { createHash, createHmac } from "node:crypto";
import { join, resolve } from "node:path";
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import OpenAI from "../packs/openai-ads/sdk/node_modules/openai/index.mjs";
import { initializeConsentControlledPixel } from "../packs/openai-ads/sdk/hth-openai-ads-3.01-pixel-consent.js";
import { createLeadReceiver } from "../packs/openai-ads/sdk/hth-openai-ads-4.02-verify-leads.js";

let handler: (request: Request) => Response = () => new Response(null, { status: 500 });
const observed: { path: string; query: URLSearchParams; method: string; body: string }[] = [];
const server = Bun.serve({ hostname: "127.0.0.1", port: 0, async fetch(request) {
  const url = new URL(request.url);
  // GET has no request payload. Consume only a POST body; cloning empty GET
  // streams can leave a fixture pending across curl connection lifecycles.
  observed.push({ path: url.pathname, query: url.searchParams, method: request.method, body: request.method === "POST" ? await request.text() : "" });
  return handler(request);
} });
afterAll(() => server.stop(true));
async function runPack(path: string, input = "", extra: Record<string, string> = {}, args: string[] = []) {
  const child = Bun.spawn(["bash", resolve(`packs/openai-ads/${path}`), ...args], {
    env: { PATH: "/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin", HTH_FIXTURE_LOOPBACK: "1", OPENAI_ADS_BASE_URL: `${server.url.origin}/v1`,
      OPENAI_ADS_API_KEY: "fixture-account-key", OPENAI_ADS_EXPECTED_ACCOUNT_ID: "adacct_fixture", ...extra },
    stdin: new Blob([input]), stdout: "pipe", stderr: "pipe",
  });
  const [code, stdout, stderr] = await Promise.all([child.exited, new Response(child.stdout).text(), new Response(child.stderr).text()]);
  return { code, stdout, stderr };
}

describe("Ads native REST and request/file emitters", () => {
  test("account check fails on wrong account and never exports names/URLs", async () => {
    handler = () => Response.json({ id: "adacct_fixture", name: "PRIVATE", url: "https://private.example.test", status: "active" });
    let result = await runPack("api/hth-openai-ads-1.02-verify-account.sh");
    expect(result.code).toBe(0); expect(result.stdout).not.toContain("PRIVATE"); expect(result.stdout).not.toContain("private.example");
    expect(JSON.parse(result.stdout).integrity_review_status).toBeNull();
    result = await runPack("api/hth-openai-ads-1.02-verify-account.sh", "", { OPENAI_ADS_EXPECTED_ACCOUNT_ID: "adacct_other" });
    expect(result.code).toBe(1);
  });
  test("audit follows last_id, retains filters, and rejects incomplete collection", async () => {
    observed.length = 0;
    handler = (request) => { const after = new URL(request.url).searchParams.get("after");
      return Response.json({ data: [{ id: after ? "alog_2" : "alog_1", obj_id: "cmpn_fixture", audit_log_type: "update_campaign" }],
        has_more: !after, last_id: after ? "audit-cursor-2" : "audit-cursor-1" }); };
    let result = await runPack("api/hth-openai-ads-4.01-export-audit.sh", "", { OPENAI_ADS_AUDIT_START: "1760000000" });
    expect(result.code).toBe(0); expect(result.stdout.trim().split("\n")).toHaveLength(2);
    expect(observed[1].query.get("after")).toBe("audit-cursor-1");
    expect(observed.every((r) => r.method === "GET" && r.query.get("start_time") === "1760000000" && r.query.get("order") === "asc")).toBe(true);
    for (const response of [() => Response.json({ data: [], has_more: true, last_id: null }),
      () => Response.json({ data: [{ id: "alog_1" }], has_more: true, last_id: "same" }),
      () => Response.json({ data: [], has_more: "false" }), () => new Response(null, { status: 403 })]) {
      handler = response;
      result = await runPack("api/hth-openai-ads-4.01-export-audit.sh", "", { OPENAI_ADS_AUDIT_START: "1760000000" });
      expect(result.code).not.toBe(0);
    }
  });
  test("spend draft uses integer micros and observed revision; emits no HTTP request", async () => {
    observed.length = 0;
    const path = "config/hth-openai-ads-2.01-draft-daily-limit.sh";
    const result = await runPack(path, "", { ADS_DAILY_AMOUNT_MICROS: "100000000", ADS_EXPECTED_REVISION: "12" });
    expect(result.code).toBe(0); expect(JSON.parse(result.stdout)).toEqual({ amount_micros: 100000000, expected_revision: 12 });
    expect(observed).toHaveLength(0);
    for (const amount of ["-1", "1.5", "1000000000000001"]) {
      expect((await runPack(path, "", { ADS_DAILY_AMOUNT_MICROS: amount, ADS_EXPECTED_REVISION: "12" })).code).not.toBe(0);
    }
    handler = () => Response.json({ data: [], revision: 12, daily_limit: { amount_micros: 100000000, spent_micros: null } });
    const read = await runPack("api/hth-openai-ads-2.01-read-spend-limits.sh");
    expect(read.code).toBe(0); expect(JSON.parse(read.stdout).daily_limit.spent_micros).toBeNull();
  });
  test("CAPI defaults to draft and forces validate_only even with caller false", async () => {
    const path = "api/hth-openai-ads-3.02-validate-conversions.sh";
    const input = JSON.stringify({ events: [{ id: "synthetic-order-1", type: "order_created", timestamp_ms: 1760000000000, data: { type: "contents", amount: 100, currency: "USD", contents: [] } }], validate_only: false });
    observed.length = 0;
    const draft = await runPack(path, input);
    expect(draft.code).toBe(0); expect(JSON.parse(draft.stdout).validate_only).toBe(true); expect(observed).toHaveLength(0);
    handler = () => Response.json({ fixture: true });
    const send = await runPack(path, input, { OPENAI_ADS_CONVERSION_BASE_URL: server.url.origin, OPENAI_ADS_CONVERSION_KEY: "fixture-conversion-key", OPENAI_ADS_PIXEL_ID: "pixel_fixture" }, ["--send"]);
    expect(send.code).toBe(0); expect(observed[0].path).toBe("/v1/events"); expect(observed[0].query.get("pid")).toBe("pixel_fixture");
    expect(JSON.parse(observed[0].body).validate_only).toBe(true);
    expect((await runPack(path, '{"events":[]}')).code).not.toBe(0);
  });
  test("audience hash preserves email plus/dot semantics and rejects unsupported inputs", async () => {
    const path = "config/hth-openai-ads-3.03-hashed-audience.sh";
    const result = await runPack(path, JSON.stringify(["  Alex.Tag+Ads@Example.TEST  "]));
    const expected = createHash("sha256").update("alex.tag+ads@example.test").digest("hex");
    expect(result.code).toBe(0); expect(result.stdout.trim()).toBe(`email_sha256\n${expected}`);
    expect(result.stdout).not.toContain("Alex");
    expect((await runPack(path, JSON.stringify(["not-an-email"])) ).code).not.toBe(0);
    expect((await runPack(path, JSON.stringify(["josé@example.test"])) ).code).not.toBe(0);
  });
  test("feed read omits connection URI; lead list refuses undocumented pagination", async () => {
    handler = (request) => new URL(request.url).pathname.endsWith("/sftp_access")
      ? Response.json({ enabled: true, authentication_method: "ssh_key", connection_uri: "sftp://user:PRIVATE@upload.example.test" })
      : Response.json({ id: "fd_fixture", is_eligible_search: false });
    const feed = await runPack("api/hth-openai-ads-3.04-read-feed-access.sh", "", { OPENAI_ADS_FEED_ID: "fd_fixture" });
    expect(feed.code).toBe(0); expect(feed.stdout).not.toContain("PRIVATE"); expect(feed.stdout).not.toContain("connection_uri");
    handler = () => Response.json({ data: [{ subscription_id: "leadsync_fixture_g1", status: "active", signing_secret: "PRIVATE" }], has_more: false });
    const leads = await runPack("api/hth-openai-ads-4.02-list-lead-subscriptions.sh");
    expect(leads.code).toBe(0); expect(leads.stdout).not.toContain("PRIVATE");
    handler = () => Response.json({ data: [], has_more: true });
    expect((await runPack("api/hth-openai-ads-4.02-list-lead-subscriptions.sh")).code).not.toBe(0);
  });
  test("late audit failure produces no partial export or raw vendor error", async () => {
    for (const failure of [() => Response.json({ error: "PRIVATE_VENDOR_ERROR" }, { status: 403 }),
      () => Response.json({ data: "PRIVATE_VENDOR_ERROR", has_more: false })]) {
      handler = (request) => new URL(request.url).searchParams.has("after") ? failure()
        : Response.json({ data: [{ id: "first-page" }], last_id: "cursor-1", has_more: true });
      const result = await runPack("api/hth-openai-ads-4.01-export-audit.sh", "", { OPENAI_ADS_AUDIT_START: "1760000000" });
      expect(result.code).not.toBe(0); expect(result.stdout).toBe("");
      expect(result.stderr).not.toContain("PRIVATE_VENDOR_ERROR");
    }
  });
  test("unsafe keys, origins and non-explicit loopback overrides never receive a request", async () => {
    observed.length = 0;
    for (const extra of [{ OPENAI_ADS_API_KEY: "fixture\nheader = injected" }, { OPENAI_ADS_API_KEY: "fixture\rkey" },
      { OPENAI_ADS_BASE_URL: "https://api.ads.openai.com.evil.test/v1" }, { OPENAI_ADS_BASE_URL: "http://api.ads.openai.com/v1" },
      { HTH_FIXTURE_LOOPBACK: "", OPENAI_ADS_BASE_URL: `${server.url.origin}/v1` },
      { OPENAI_ADS_BASE_URL: `${server.url.origin}/v1?invalid=query` }]) {
      const result = await runPack("api/hth-openai-ads-1.02-verify-account.sh", "", extra);
      expect(result.code).not.toBe(0); expect(result.stdout).toBe("");
    }
    const result = await runPack("api/hth-openai-ads-3.02-validate-conversions.sh", JSON.stringify({ events: [{}] }), {
      OPENAI_ADS_CONVERSION_KEY: "fixture-conversion-key", OPENAI_ADS_PIXEL_ID: "pixel_fixture",
      OPENAI_ADS_CONVERSION_BASE_URL: "https://bzr.openai.com.evil.test",
    }, ["--send"]);
    expect(result.code).not.toBe(0); expect(result.stdout).toBe(""); expect(observed).toHaveLength(0);
  });
  test("CAPI uses private request files and stdin credentials, ignores curlrc and cleans staging", async () => {
    const directory = mkdtempSync(join(tmpdir(), "hth-ads-fixture-"));
    const bin = join(directory, "bin"), staging = join(directory, "staging");
    mkdirSync(bin); mkdirSync(staging);
    const argsPath = join(directory, "args"), configPath = join(directory, "config");
    writeFileSync(join(bin, "curl"), '#!/usr/bin/env bash\numask 077\nprintf \'%s\\0\' "$@" > "$HTH_ARGS_LOG"\n/usr/bin/tee "$HTH_CONFIG_LOG" | /usr/bin/curl "$@"\n');
    chmodSync(join(bin, "curl"), 0o700);
    writeFileSync(join(directory, ".curlrc"), 'header = "X-From-Curlrc: PRIVATE"\n');
    const key = "fixture-" + String.fromCharCode(34, 92) + "-tail";
    try {
      handler = (request) => {
        expect(request.headers.get("Authorization")).toBe(`Bearer ${key}`);
        expect(request.headers.get("X-From-Curlrc")).toBeNull();
        for (const entry of readdirSync(staging)) {
          expect(statSync(join(staging, entry)).mode & 0o777).toBe(0o700);
          for (const file of readdirSync(join(staging, entry))) expect(statSync(join(staging, entry, file)).mode & 0o777).toBe(0o600);
        }
        return Response.json({ success: true });
      };
      const result = await runPack("api/hth-openai-ads-3.02-validate-conversions.sh", JSON.stringify({ events: [{ event_name: "fixture_event" }] }), {
        PATH: `${bin}:/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin`,
        OPENAI_ADS_CONVERSION_KEY: key, OPENAI_ADS_PIXEL_ID: "pixel_fixture", OPENAI_ADS_CONVERSION_BASE_URL: server.url.origin,
        CURL_HOME: directory, TMPDIR: staging, HTH_ARGS_LOG: argsPath, HTH_CONFIG_LOG: configPath,
      }, ["--send"]);
      expect(result.code).toBe(0);
      const args = readFileSync(argsPath, "utf8").split("\0");
      expect(args[0]).toBe("-q"); expect(args.join(" ")).not.toContain("Authorization");
      expect(args.join(" ")).not.toContain("fixture_event");
      for (const option of ["--config", "--connect-timeout", "--max-time", "--max-filesize", "--proto"]) expect(args).toContain(option);
      expect(readdirSync(staging)).toHaveLength(0);
    } finally { rmSync(directory, { recursive: true, force: true }); }
  });
  test("oversized Ads responses fail with no output prefix", async () => {
    handler = () => new Response("x".repeat(8388609));
    const result = await runPack("api/hth-openai-ads-1.02-verify-account.sh");
    expect(result.code).not.toBe(0); expect(result.stdout).toBe(""); expect(result.stderr).not.toContain("xxxx");
  });
});

test("official Pixel command contract denies consent before init and exposes withdrawal", () => {
  const queue: unknown[][] = [];
  const controls = initializeConsentControlledPixel((...args: unknown[]) => queue.push(args), "pixel_fixture");
  expect(queue).toEqual([["consent", false], ["init", { pixelId: "pixel_fixture", debug: false }]]);
  controls.grant(); controls.withdraw();
  expect(queue.slice(-2)).toEqual([["consent", true], ["consent", false]]);
});

const signingSecret = "fixture-lead-signing-secret";
const leadClient = new OpenAI({ apiKey: "fixture-not-a-credential", webhookSecret: signingSecret });
function leadRequest(payload: object, candidate = "leadsync_fixture_g1", tamper = false, age = 0) {
  const raw = JSON.stringify(payload); const timestamp = String(Math.floor(Date.now() / 1000) - age);
  const signature = createHmac("sha256", signingSecret).update(`delivery-lead-1.${timestamp}.${raw}`).digest("base64");
  return new Request("https://receiver.example.test/leads", { method: "POST", body: tamper ? `${raw} ` : raw,
    headers: { "OpenAI-Subscription-Id": candidate, "webhook-id": "delivery-lead-1", "webhook-timestamp": timestamp, "webhook-signature": `v1,${signature}` } });
}
test("lead receiver real SDK rejects tamper/replay/routing and isolates synthetic probes", async () => {
  const queued = new Map<string, unknown>(); let fail = false; let validSchema = true;
  const receive = createLeadReceiver({
    findSubscription: async (id: string) => id === "leadsync_fixture_g1" ? { client: leadClient, adAccountId: "adacct_fixture" } : null,
    // This fixture exercises adapter rejection, not full schema conformance.
    validateLeadEvent: () => validSchema,
    enqueueOnce: async (id: string, payload: unknown) => { if (fail) throw new Error("fixture store unavailable"); if (!queued.has(id)) queued.set(id, payload); },
  });
  const event = { id: "evt_fixture", object: "event", created_at: 1760000000, type: "lead_form.response.created", subscription_id: "leadsync_fixture_g1", data: { ad_account_id: "adacct_fixture" } };
  expect((await receive(leadRequest(event, undefined, true))).status).toBe(400);
  expect((await receive(leadRequest(event, undefined, false, 600))).status).toBe(400);
  expect((await receive(leadRequest(event, "leadsync_unknown_g1"))).status).toBe(400);
  expect((await receive(leadRequest({ ...event, subscription_id: "leadsync_different_g1" }))).status).toBe(400);
  expect((await receive(leadRequest({ ...event, data: { ad_account_id: "adacct_other" } }))).status).toBe(400);
  expect((await receive(leadRequest({ ...event, synthetic: true, data: { ad_account_id: null } }))).status).toBe(204);
  expect(queued.size).toBe(0);
  validSchema = false; expect((await receive(leadRequest(event))).status).toBe(400); validSchema = true;
  fail = true; expect((await receive(leadRequest(event))).status).toBe(503); fail = false;
  expect((await receive(leadRequest(event))).status).toBe(204); expect((await receive(leadRequest(event))).status).toBe(204);
  expect(queued.size).toBe(1); expect(queued.has("leadsync_fixture_g1:delivery-lead-1")).toBe(true);
});
