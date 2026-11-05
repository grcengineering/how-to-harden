#!/usr/bin/env bun
/** Offline boundary tests: real Bun TOML parsing, synthetic grok only, no product calls. */
import { afterAll, test, expect } from "bun:test";
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync, chmodSync, readdirSync, statSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

const root = resolve(import.meta.dir, "..");
const packs = join(root, "packs/grok-build");
const temp = mkdtempSync(join(tmpdir(), "hth-grok-build-tests-"));
const fakebin = join(temp, "bin");
mkdirSync(fakebin);
const calls = join(temp, "calls.jsonl");
const privateText = "HTH_SYNTHETIC_SECRET_CONFIG_ONLY";
const team = "12345678-1234-1234-1234-123456789abc";
const files = {
  team: "config/hth-grok-build-1.01-team-policy.sh",
  permission: "config/hth-grok-build-2.01-permission-policy.sh",
  sandbox: "config/hth-grok-build-2.02-sandbox-policy.sh",
  mcp: "config/hth-grok-build-3.01-disable-mcp-source.sh",
  compat: "config/hth-grok-build-3.02-compatibility-policy.sh",
  runtime: "config/hth-grok-build-4.01-runtime-policy.sh",
  data: "config/hth-grok-build-4.02-data-policy.sh",
  mcpRead: "cli/hth-grok-build-3.01-inventory-mcp.sh",
  lifecycle: "cli/hth-grok-build-5.01-inventory-lifecycle.sh",
} as const;
type Pack = keyof typeof files;

const fakeGrok = join(fakebin, "grok");
writeFileSync(fakeGrok, `#!${process.execPath}
const args = process.argv.slice(2);
if (process.env.GROK_DISABLE_AUTOUPDATER !== "1") { console.error("AUTOUPDATER WAS NOT SUPPRESSED"); process.exit(98); }
const allowed = [["--version"],["inspect","--json"],["mcp","list","--json"],["plugin","list"],["sessions","list"],["worktree","list"]];
if (!allowed.some(a => JSON.stringify(a) === JSON.stringify(args))) { console.error("UNEXPECTED MUTATING OR INFERENCE COMMAND"); process.exit(99); }
await Bun.write(process.env.HTH_TEST_CALLS, (await Bun.file(process.env.HTH_TEST_CALLS).exists() ? await Bun.file(process.env.HTH_TEST_CALLS).text() : "") + JSON.stringify(args) + "\\n");
console.error(process.env.HTH_TEST_PRIVATE);
if (process.env.HTH_TEST_GROK_FAIL) process.exit(7);
console.log(process.env.HTH_TEST_GROK_BODY || process.env.HTH_TEST_PRIVATE);
`);
chmodSync(fakeGrok, 0o700);

function environment(extra: Record<string, string> = {}) {
  const env = Object.fromEntries(Object.entries(process.env).filter(([k, v]) => v !== undefined && !/^(HTH_|GROK_|XAI_|DISABLE_TELEMETRY$|DISABLE_ERROR_REPORTING$)/.test(k))) as Record<string, string>;
  return {
    ...env, PATH: `${fakebin}:${process.env.PATH}`, TMPDIR: temp,
    HTH_ALLOWED_TEAM_UUID: team, HTH_MCP_SERVER_NAME: "retired-server",
    HTH_ALLOWED_MODEL_IDS_JSON: '["grok-build"]',
    HTH_TEST_CALLS: calls, HTH_TEST_PRIVATE: privateText, ...extra,
  };
}
function run(pack: Pack, args: string[] = [], extra: Record<string, string> = {}) {
  const result = Bun.spawnSync(["bash", join(packs, files[pack]), ...args], { cwd: root, env: environment(extra) });
  return { status: result.exitCode, out: result.stdout.toString(), err: result.stderr.toString() };
}
function candidate(contents: string) {
  const path = join(temp, `candidate-${crypto.randomUUID()}.toml`);
  writeFileSync(path, contents, { mode: 0o600 });
  return path;
}
function callLog(): string[][] {
  try { return readFileSync(calls, "utf8").trim().split("\n").filter(Boolean).map(line => JSON.parse(line)); }
  catch { return []; }
}
afterAll(() => rmSync(temp, { recursive: true, force: true }));

test("every pack passes bash syntax and defaults never call Grok", () => {
  for (const [name, relative] of Object.entries(files)) {
    const syntax = Bun.spawnSync(["bash", "-n", join(packs, relative)]);
    expect(syntax.exitCode).toBe(0);
    const result = run(name as Pack);
    expect(result.status).toBe(["mcpRead", "lifecycle"].includes(name) ? 2 : 0);
  }
  expect(callLog()).toEqual([]);
  expect(readdirSync(temp).filter(name => name.startsWith("hth-grok-build-"))).toEqual([]);
});

test("rendered candidate documents parse using Bun's real TOML parser", () => {
  for (const name of ["team", "permission", "sandbox", "mcp", "compat", "runtime", "data"] as Pack[]) {
    const result = run(name);
    expect(result.status).toBe(0);
    const parsed = Bun.TOML.parse(result.out);
    expect(typeof parsed).toBe("object");
    expect(Object.keys(parsed).length).toBeGreaterThan(0);
    const file = candidate(result.out + `\n[synthetic_private]\nsecret = "${privateText}"\n`);
    const checked = run(name, ["verify"], { HTH_CANDIDATE_POLICY: file });
    expect(checked.status).toBe(0);
    expect(JSON.parse(checked.out).candidate_fields_match).toBe(true);
    expect(JSON.parse(checked.out).not_proven.length).toBeGreaterThan(0);
    expect(checked.out + checked.err).not.toContain(privateText);
  }
});

test("missing, unreadable and malformed policies are preconditions, not passing checks", () => {
  for (const name of ["team", "permission", "sandbox", "mcp", "compat", "runtime", "data"] as Pack[]) {
    expect(run(name, ["verify"]).status).toBe(2);
    expect(run(name, ["verify"], { HTH_CANDIDATE_POLICY: join(temp, "does-not-exist") }).status).toBe(2);
    expect(run(name, ["verify"], { HTH_CANDIDATE_POLICY: candidate("not valid [ TOML") }).status).toBe(2);
    expect(run(name, ["verify"], { HTH_CANDIDATE_POLICY: candidate("# no required fields\n") }).status).toBe(1);
  }
});

test("string booleans and changed policy values cannot pass as typed policy", () => {
  for (const name of ["team", "permission", "sandbox", "mcp", "compat", "runtime", "data"] as Pack[]) {
    const rendered = run(name).out;
    const changed = rendered.replace(/= (true|false)/, '= "$1"');
    expect(run(name, ["verify"], { HTH_CANDIDATE_POLICY: candidate(changed) }).status).toBe(1);
  }
  expect(run("team", ["verify"], { HTH_CANDIDATE_POLICY: candidate(`[grok_com_config]\ndisable_api_key_auth = true\nforce_login_team_uuid = "wrong-team"`) }).status).toBe(1);
  expect(run("sandbox", ["verify"], { HTH_CANDIDATE_POLICY: candidate('[sandbox]\nprofile = "hth-strict"\nauto_allow_bash = false') }).status).toBe(1);
});

test("invalid identifiers and model lists cannot inject native config or shell actions", () => {
  const sentinel = join(temp, "must-not-exist");
  const hostile = `$(touch ${sentinel})\n[ui]\npermission_mode="always-approve"`;
  expect(run("team", [], { HTH_ALLOWED_TEAM_UUID: hostile }).status).toBe(2);
  expect(run("mcp", [], { HTH_MCP_SERVER_NAME: hostile }).status).toBe(2);
  for (const raw of ["[]", "{}", "null", '["*"]', '["grok-build","grok-build"]', JSON.stringify([hostile]), "not-json"]) {
    expect(run("runtime", [], { HTH_ALLOWED_MODEL_IDS_JSON: raw }).status).toBe(2);
  }
  expect(Bun.file(sentinel).size).toBe(0);
});

test("duplicate TOML tables are rejected rather than treated as merged policy", () => {
  const duplicated = run("mcp").out + "\n[compat.cursor]\nmcps = true\n";
  expect(run("mcp", ["verify"], { HTH_CANDIDATE_POLICY: candidate(duplicated) }).status).toBe(2);
});

test("optional custom sandbox and telemetry outputs are separate review artifacts", () => {
  const policy = Bun.TOML.parse(run("sandbox", ["policy"]).out);
  const custom = run("sandbox", ["profile"]);
  expect(policy.sandbox.profile).toBe("strict");
  expect(Bun.TOML.parse(custom.out).profiles["hth-strict"].deny).toContain("**/.env");
  expect(custom.out).toContain("not activated");
  const launcher = run("data", ["environment"]);
  const syntax = Bun.spawnSync(["bash", "-n"], { stdin: new TextEncoder().encode(launcher.out) });
  expect(syntax.exitCode).toBe(0);
  expect(launcher.out).toContain("DISABLE_ERROR_REPORTING=1");
  expect(launcher.out).not.toContain("grok -p");
});

test("MCP inventory is opt-in, uses exact native read commands and keeps output private", () => {
  const before = callLog().length;
  const result = run("mcpRead", [], { HTH_RUN_GROK_READS: "1" });
  expect(result.status).toBe(0);
  expect(callLog().slice(before)).toEqual([["inspect", "--json"], ["mcp", "list", "--json"]]);
  expect(result.out).toContain("NOT ASSESSED");
  expect(result.out + result.err).not.toContain(privateText);
  const path = result.out.match(/private evidence at (.+)/)?.[1];
  expect(path).toBeTruthy();
  expect(statSync(path!).mode & 0o777).toBe(0o700);
  for (const name of readdirSync(path!)) expect(statSync(join(path!, name)).mode & 0o777).toBe(0o600);
});

test("lifecycle inventory never invokes login, update, prompt, export or deletion", () => {
  const before = callLog().length;
  const result = run("lifecycle", [], { HTH_RUN_GROK_READS: "1", HTH_TEST_GROK_BODY: "malformed-json-is-not-a-policy-proof" });
  expect(result.status).toBe(0);
  expect(callLog().slice(before)).toEqual([["--version"], ["inspect", "--json"], ["plugin", "list"], ["sessions", "list"], ["worktree", "list"]]);
  expect(result.out).toContain("NOT ASSESSED");
  expect(result.out).not.toMatch(/COMPLIANT|PASS/);
  expect(result.out + result.err).not.toContain("malformed-json-is-not-a-policy-proof");
  expect(result.out + result.err).not.toContain(privateText);
});

test("a failed native command aborts inventory and preserves private partial evidence", () => {
  const before = callLog().length;
  const result = run("lifecycle", [], { HTH_RUN_GROK_READS: "1", HTH_TEST_GROK_FAIL: "1" });
  expect(result.status).not.toBe(0);
  expect(callLog().slice(before)).toEqual([["--version"]]);
  expect(result.out).not.toContain("COLLECTED");
  expect(result.err).toContain("PARTIAL evidence retained at:");
  expect(result.out + result.err).not.toContain(privateText);
});
