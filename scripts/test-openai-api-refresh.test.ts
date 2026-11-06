// Offline contract tests. Requires official openai@7.51.0; no API key or tenant.
// Sources: current OpenAI Webhooks, hosted Agents and Admin list references,
// fetched 2026-11-05; see docs/research/openai-api-source-coverage.md.
import { afterAll, describe, expect, test } from "bun:test";
import OpenAI from "../packs/openai-api/sdk/node_modules/openai/index.mjs";
import { createHmac } from "node:crypto";
import { join, resolve } from "node:path";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { buildReviewedSession, executeReviewedSession } from "../packs/openai-api/sdk/hth-openai-api-4.01-reviewed-hosted-session.js";
import { buildRestrictedMcp } from "../packs/openai-api/sdk/hth-openai-api-4.02-restrict-mcp.js";
import { createWebhookReceiver } from "../packs/openai-api/sdk/hth-openai-api-5.01-verify-webhooks.js";
import { buildCyberRequest, executeCyberRequest } from "../packs/openai-api/sdk/hth-openai-api-5.04-explicit-cyber-program.js";

const secret = "fixture-webhook-secret-not-a-credential";
test("installed CLI fixture validates profiles and stages a single response without raw errors", async () => {
  const directory = mkdtempSync(join(tmpdir(), "hth-openai-cli-fixture-"));
  const binary = join(directory, "openai"), called = join(directory, "called");
  writeFileSync(binary, `#!/usr/bin/env bash
set -eu
printf '%s\\n' "$*" > "$HTH_CLI_CALLED"
if [ "\${HTH_CLI_FAILURE:-0}" = 1 ]; then
  printf '%s\\n' '{"data":[{"id":"partial"}]}'
  printf '%s\\n' 'PRIVATE_CLI_ERROR' >&2
  exit 1
fi
printf '%s\\n' '{"data":[{"id":"proj_fixture"}]}'
`);
  chmodSync(binary, 0o700);
  const run = async (extra: Record<string, string> = {}) => {
    const child = Bun.spawn(["bash", resolve("packs/openai-api/cli/hth-openai-api-1.01-list-projects.sh")], {
      env: { PATH: `${directory}:/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin`, OPENAI_ADMIN_KEY: "fixture-not-a-credential", HTH_CLI_CALLED: called, ...extra },
      stdout: "pipe", stderr: "pipe",
    });
    const [code, stdout, stderr] = await Promise.all([child.exited, new Response(child.stdout).text(), new Response(child.stderr).text()]);
    return { code, stdout, stderr };
  };
  try {
    const success = await run();
    expect(success.code).toBe(0);
    expect(JSON.parse(success.stdout)).toEqual([{ id: "proj_fixture" }]);
    expect(readFileSync(called, "utf8").trim()).toBe("admin organization projects list --format json");
    rmSync(called);
    for (const level of ["0", "5", "invalid"]) {
      const invalid = await run({ HTH_PROFILE_LEVEL: level });
      expect(invalid.code).toBe(2); expect(invalid.stdout).toBe("");
      expect(existsSync(called)).toBe(false);
    }
    const failure = await run({ HTH_CLI_FAILURE: "1" });
    expect(failure.code).toBe(2); expect(failure.stdout).toBe("");
    expect(failure.stderr).not.toContain("PRIVATE_CLI_ERROR");
    // This checks the wrapper only, not a real CLI's response schema or paging.
  } finally { rmSync(directory, { recursive: true, force: true }); }
});
const client = new OpenAI({ apiKey: "fixture-not-a-credential", webhookSecret: secret });
function signedRequest(body: string, options: { id?: string; age?: number; mutate?: boolean } = {}) {
  const id = options.id ?? "delivery-fixture-1";
  const timestamp = String(Math.floor(Date.now() / 1000) - (options.age ?? 0));
  const signature = createHmac("sha256", secret).update(`${id}.${timestamp}.${body}`).digest("base64");
  return new Request("https://receiver.example.test/callback", {
    method: "POST", body: options.mutate ? `${body} ` : body,
    headers: { "webhook-id": id, "webhook-timestamp": timestamp, "webhook-signature": `v1,${signature}` },
  });
}
const event = JSON.stringify({ id: "evt_fixture", type: "response.completed", data: { id: "resp_fixture" } });

describe("real SDK webhook verifier and receiver acknowledgement", () => {
  test("verifies raw bytes, rejects tampering/stale/future/unsigned deliveries before enqueue", async () => {
    const deliveries: string[] = [];
    const receive = createWebhookReceiver({ client, enqueueOnce: async (id: string) => { deliveries.push(id); } });
    expect((await receive(signedRequest(event))).status).toBe(204);
    expect((await receive(signedRequest(event, { mutate: true }))).status).toBe(400);
    expect((await receive(signedRequest(event, { age: 600 }))).status).toBe(400);
    expect((await receive(signedRequest(event, { age: -600 }))).status).toBe(400);
    expect((await receive(new Request("https://receiver.example.test/callback", { method: "POST", body: event }))).status).toBe(400);
    expect(deliveries).toHaveLength(1);
  });
  test("uses delivery id for durable adapter, retries storage failures and filters events", async () => {
    // A Map is only this test's atomic-storage fixture, never a production adapter.
    const queued = new Map();
    let fail = true;
    const receive = createWebhookReceiver({ client, enqueueOnce: async (id: string, payload: unknown) => {
      if (fail) throw new Error("fixture unavailable store");
      if (!queued.has(id)) queued.set(id, payload);
    } });
    expect((await receive(signedRequest(event))).status).toBe(503);
    fail = false;
    expect((await receive(signedRequest(event))).status).toBe(204);
    expect((await receive(signedRequest(event))).status).toBe(204);
    expect(queued.size).toBe(1);
    expect(queued.has("delivery-fixture-1")).toBe(true);
    const unrelated = JSON.stringify({ type: "batch.completed", data: { id: "batch_fixture" } });
    expect((await receive(signedRequest(unrelated, { id: "delivery-filtered" }))).status).toBe(204);
    expect(queued.size).toBe(1);
    expect((await receive(signedRequest("not-json"))).status).toBe(400);
  });
});

describe("official SDK serializes reviewed hosted sessions", () => {
  test("default disables environment network; explicit exact hosts restrict it", async () => {
    let observed: { url: string; body: any } | undefined;
    const sdk = new OpenAI({ apiKey: "fixture-not-a-credential", maxRetries: 0, fetch: async (input: any, init: any) => {
      observed = { url: String(input), body: JSON.parse(init.body) };
      return Response.json({ id: "asess_fixture", object: "agent.session" });
    } });
    const options = { model: "approved-model-fixture", input: "fixture task" };
    await executeReviewedSession(sdk, options);
    expect(observed?.url).toBe("https://api.openai.com/v1/agents/sessions");
    expect(observed?.body.environment.network).toEqual({ access: "disabled" });
    expect(observed?.body.review).toBe("auto_review");
    expect(buildReviewedSession({ ...options, allowedDomains: ["api.example.test", "api.example.test"] }).environment.network)
      .toEqual({ access: "restricted", allowed_domains: ["api.example.test"] });
    for (const host of ["*.example.test", "https://example.test", "example.test/path", "example.test:443"]) {
      expect(() => buildReviewedSession({ ...options, allowedDomains: [host] })).toThrow();
    }
  });
  test("MCP requires explicit tool allowlist, fail-closed startup and independent origin", () => {
    const tool = buildRestrictedMcp({ serverLabel: "approved", serverUrl: "https://mcp.example.test/mcp", allowedTools: ["read_ticket", "read_ticket"] });
    expect(tool).toMatchObject({ type: "mcp", connection_origin: "service", required: true, allowed_tools: ["read_ticket"] });
    for (const url of ["http://mcp.example.test", "https://user:pass@mcp.example.test", "https://mcp.example.test?token=x"]) {
      expect(() => buildRestrictedMcp({ serverLabel: "x", serverUrl: url, allowedTools: ["read_ticket"] })).toThrow();
    }
    expect(() => buildRestrictedMcp({ serverLabel: "x", serverUrl: "https://mcp.example.test", allowedTools: ["*"] })).toThrow();
  });
});

describe("explicit Daybreak request contract", () => {
  const options = { model: "gpt-6.1-terra", input: "Review a defensive patch fixture", safetyIdentifier: "internal-user-fixture" };
  test("uses explicit standard by default and rejects null or invalid programs", () => {
    expect(buildCyberRequest(options).access_programs).toEqual({ cyber: "standard" });
    for (const cyber of [null, "red", "", {}]) {
      expect(() => buildCyberRequest({ ...options, cyber })).toThrow();
    }
    expect(() => buildCyberRequest({ ...options, safetyIdentifier: "" })).toThrow();
  });
  test("actual SDK sends the chosen program and returns minimized served-model evidence", async () => {
    let observed: any;
    const sdk = new OpenAI({ apiKey: "fixture-not-a-credential", maxRetries: 0, fetch: async (url: any, init: any) => {
      observed = { url: String(url), body: JSON.parse(init.body) };
      return Response.json({ id: "resp_fixture", model: "gpt-6-sol-fixture-snapshot", access_programs: { cyber: "daybreak_blue" },
        output: [{ text: "PRIVATE_MODEL_OUTPUT" }] }, { headers: { "x-request-id": "req_fixture" } });
    } });
    const result = await executeCyberRequest(sdk, { ...options, model: "gpt-6-sol", cyber: "daybreak_blue" });
    expect(observed.url).toBe("https://api.openai.com/v1/responses");
    expect(observed.body.access_programs).toEqual({ cyber: "daybreak_blue" });
    expect(observed.body.safety_identifier).toBe("internal-user-fixture");
    expect(result).toEqual({ response_id: "resp_fixture", request_id: "req_fixture", model: "gpt-6-sol-fixture-snapshot", access_programs: { cyber: "daybreak_blue" } });
    expect(JSON.stringify(result)).not.toContain("PRIVATE_MODEL_OUTPUT");
  });
  test("incompatible, unavailable and cyber-policy failures do not trigger a program-changing fallback", async () => {
    for (const [status, code] of [[400, "invalid_access_program"], [400, "unsupported_access_program"], [403, "access_program_not_enabled"], [403, "cyber_policy"]] as const) {
      const programs: string[] = [];
      const sdk = new OpenAI({ apiKey: "fixture-not-a-credential", maxRetries: 0, fetch: async (_url: any, init: any) => {
        programs.push(JSON.parse(init.body).access_programs.cyber);
        return Response.json({ error: { message: "Fixture denial", type: "invalid_request_error", code } }, { status });
      } });
      await expect(executeCyberRequest(sdk, { ...options, model: "gpt-6-cyber", cyber: "daybreak_red" })).rejects.toMatchObject({ status, code });
      expect(programs).toEqual(["daybreak_red"]);
    }
  });
});

let handler: (request: Request) => Response = () => new Response(null, { status: 500 });
const requests: URL[] = [];
const server = Bun.serve({ hostname: "127.0.0.1", port: 0, fetch(request) {
  const url = new URL(request.url); requests.push(url);
  if (request.method !== "GET") return new Response(null, { status: 405 });
  return handler(request);
} });
afterAll(() => server.stop(true));
async function runPack(name: string, extra: Record<string, string> = {}) {
  const child = Bun.spawn(["bash", resolve(`packs/openai-api/api/${name}`)], {
    env: { PATH: "/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin", HTH_FIXTURE_LOOPBACK: "1", OPENAI_BASE_URL: `${server.url.origin}/v1`,
      OPENAI_ADMIN_KEY: "fixture-admin", OPENAI_API_KEY: "fixture-project", OPENAI_PROJECT_ID: "proj_fixture", ...extra },
    stdout: "pipe", stderr: "pipe",
  });
  const [code, stdout, stderr] = await Promise.all([child.exited, new Response(child.stdout).text(), new Response(child.stderr).text()]);
  return { code, stdout, stderr };
}
describe("read-only REST packs against loopback fixtures", () => {
  test("follows key cursors and never exports key value, redaction or identity", async () => {
    requests.length = 0;
    handler = (request) => {
      const after = new URL(request.url).searchParams.get("after");
      const key = { id: after ? "key_2" : "key_1", owner: { type: "service_account", email: "private@example.test" },
        name: "private", value: "SECRET", redacted_value: "SECRET", owner_project_access: after ? "inactive" : "active", expires_at: 4102444800 };
      return Response.json({ data: after ? [key, { ...key, id: "key_3", owner_project_access: "active", expires_at: null }] : [key], has_more: !after });
    };
    const result = await runPack("hth-openai-api-1.02-key-expiration-audit.sh");
    expect(result.code).toBe(0);
    const rows = result.stdout.trim().split("\n").map(JSON.parse);
    expect(rows.map((row) => row.review_required)).toEqual([false, true, true]);
    expect(result.stdout).not.toContain("SECRET"); expect(result.stdout).not.toContain("private");
    expect(requests[1].searchParams.get("after")).toBe("key_1");
    expect(requests.every((url) => url.pathname.endsWith("/api_keys"))).toBe(true);
    expect(requests.every((url) => url.searchParams.get("owner_project_access") === "any")).toBe(true);
  });
  test("refuses HTTP, malformed and non-advancing pages; audit filters stay on every page", async () => {
    for (const response of [() => new Response(null, { status: 500 }), () => Response.json({ data: [], has_more: "false" }),
      () => Response.json({ data: [{ id: "same" }], has_more: true }), () => Response.json({ data: [], has_more: true })]) {
      handler = response;
      expect((await runPack("hth-openai-api-1.01-project-membership.sh")).code).not.toBe(0);
    }
    requests.length = 0;
    handler = (request) => { const after = new URL(request.url).searchParams.get("after");
      return Response.json({ data: [{ id: after ? "audit_2" : "audit_1", type: "ip_allowlist.updated" }], has_more: !after }); };
    const result = await runPack("hth-openai-api-5.02-export-audit.sh", { OPENAI_AUDIT_START: "1760000000" });
    expect(result.code).toBe(0);
    expect(requests).toHaveLength(2);
    expect(requests.every((url) => url.searchParams.get("effective_at[gte]") === "1760000000")).toBe(true);
  });
  test("distinguishes documented ingress denial from bad credentials", async () => {
    handler = () => Response.json({ data: [] });
    expect((await runPack("hth-openai-api-2.01-network-check.sh")).code).toBe(0);
    handler = () => Response.json({ error: { code: "ip_not_authorized" } }, { status: 401 });
    expect((await runPack("hth-openai-api-2.01-network-check.sh")).code).toBe(3);
    handler = () => Response.json({ error: { code: "invalid_api_key" } }, { status: 401 });
    expect((await runPack("hth-openai-api-2.01-network-check.sh")).code).toBe(2);
  });
  test("state inventory reads Files and Vector Stores only", async () => {
    requests.length = 0;
    handler = () => Response.json({ data: [{ id: "state_fixture", created_at: 1760000000 }], has_more: false });
    const result = await runPack("hth-openai-api-3.02-stored-state-inventory.sh");
    expect(result.code).toBe(0);
    expect(requests.map((url) => url.pathname)).toEqual(["/v1/files", "/v1/vector_stores"]);
  });
  test("PSP assessment reports saved status only and omits storage connection details", async () => {
    for (const status of ["pending", "validated", "unhealthy"]) {
      handler = (request) => {
        expect(request.headers.get("OpenAI-Organization")).toBe("org_fixture");
        return Response.json({ id: "extstorage_fixture", status, provider: { bucket: "PRIVATE_BUCKET", role_arn: "PRIVATE_ROLE" } });
      };
      const result = await runPack("hth-openai-api-5.04-read-psp-status.sh", { OPENAI_ORG_ID: "org_fixture", OPENAI_EXTERNAL_STORAGE_ID: "extstorage_fixture" });
      expect(result.code).toBe(0);
      expect(JSON.parse(result.stdout)).toEqual({ id: "extstorage_fixture", status, saved_state_only: true, review_required: status !== "validated" });
      expect(result.stdout).not.toContain("PRIVATE");
    }
  });
  test("late-page failures emit no partial rows or raw vendor errors", async () => {
    for (const failure of [() => Response.json({ error: "PRIVATE_VENDOR_ERROR" }, { status: 500 }),
      () => Response.json({ data: "PRIVATE_VENDOR_ERROR", has_more: false })]) {
      handler = (request) => new URL(request.url).searchParams.has("after") ? failure()
        : Response.json({ data: [{ id: "first_page" }], has_more: true });
      const result = await runPack("hth-openai-api-1.01-project-membership.sh");
      expect(result.code).not.toBe(0); expect(result.stdout).toBe("");
      expect(result.stderr).not.toContain("PRIVATE_VENDOR_ERROR");
    }
  });
  test("refuses unsafe credential representations and unapproved destinations before networking", async () => {
    requests.length = 0;
    for (const extra of [
      { OPENAI_ADMIN_KEY: "fixture\nheader = injected" }, { OPENAI_ADMIN_KEY: "fixture\rkey" },
      { OPENAI_BASE_URL: "https://api.openai.com.evil.test/v1" }, { OPENAI_BASE_URL: "http://api.openai.com/v1" },
      { HTH_FIXTURE_LOOPBACK: "", OPENAI_BASE_URL: `${server.url.origin}/v1` },
      { OPENAI_BASE_URL: `${server.url.origin}/v1?query=invalid` },
    ]) {
      const result = await runPack("hth-openai-api-1.01-project-membership.sh", extra);
      expect(result.code).not.toBe(0); expect(result.stdout).toBe("");
    }
    expect(requests).toHaveLength(0);
  });
  test("stdin curl configuration hides argv credentials, ignores curlrc and cleans private staging", async () => {
    const directory = mkdtempSync(join(tmpdir(), "hth-api-fixture-"));
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
        return Response.json({ data: [], has_more: false });
      };
      const result = await runPack("hth-openai-api-1.01-project-membership.sh", {
        PATH: `${bin}:/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin`, OPENAI_ADMIN_KEY: key,
        CURL_HOME: directory, TMPDIR: staging, HTH_ARGS_LOG: argsPath, HTH_CONFIG_LOG: configPath,
      });
      expect(result.code).toBe(0);
      const args = readFileSync(argsPath, "utf8").split("\0");
      expect(args[0]).toBe("-q"); expect(args.join(" ")).not.toContain("Authorization");
      for (const option of ["--config", "--connect-timeout", "--max-time", "--max-filesize", "--proto"]) expect(args).toContain(option);
      expect(readdirSync(staging)).toHaveLength(0);
    } finally { rmSync(directory, { recursive: true, force: true }); }
  });
  test("oversized responses fail without exposing a response prefix", async () => {
    handler = () => new Response("x".repeat(8388609));
    const result = await runPack("hth-openai-api-1.01-project-membership.sh");
    expect(result.code).not.toBe(0); expect(result.stdout).toBe(""); expect(result.stderr).not.toContain("xxxx");
  });
});
