// These installed-CLI fixtures test gate control flow, not Ona behavior. The
// separate Linux job loads the actual pinned provider for native validation.
import { afterAll, expect, test } from "bun:test";
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { tmpdir } from "node:os";
import { isKnownScmUnknownDiagnostic, validateOnaRecipes } from "./validate-ona-terraform";

const repositoryRoot = resolve(import.meta.dir, "..");
const scratch = mkdtempSync(join(tmpdir(), "hth-ona-validator-fixtures-"));
afterAll(() => rmSync(scratch, { recursive: true, force: true }));
const diagnostic = {
  valid: false, error_count: 1, warning_count: 0,
  diagnostics: [{ severity: "error", summary: "Missing OAuth Client ID", detail: 'Set oauth_client_id when auth_mode is "oauth".' }],
};

test("only the exact single native unknown-ID diagnostic is recognized", () => {
  expect(isKnownScmUnknownDiagnostic(diagnostic)).toBe(true);
  for (const changed of [
    undefined, {}, { ...diagnostic, valid: true }, { ...diagnostic, error_count: 2 },
    { ...diagnostic, warning_count: 1 }, { ...diagnostic, diagnostics: [] },
    { ...diagnostic, diagnostics: [null] }, { ...diagnostic, diagnostics: ["malformed"] },
    { ...diagnostic, diagnostics: [...diagnostic.diagnostics, { severity: "warning", summary: "Unexpected warning" }] },
    { ...diagnostic, diagnostics: [{ ...diagnostic.diagnostics[0], detail: "Different provider error" }] },
    { ...diagnostic, diagnostics: [{ ...diagnostic.diagnostics[0], severity: "warning" }] },
  ]) expect(isKnownScmUnknownDiagnostic(changed)).toBe(false);
});

function installedTerraformFixture(mode: "valid" | "early-failure" | "extra-scm-error" | "accept-empty-id") {
  const directory = mkdtempSync(join(scratch, `${mode}-`));
  const executable = join(directory, "terraform"), log = join(directory, "calls.jsonl");
  writeFileSync(executable, `#!${process.execPath}
import { appendFileSync } from "node:fs";
import { join } from "node:path";
const args = Bun.argv.slice(2);
const directory = args.find(arg => arg.startsWith("-chdir=")).slice(7);
const action = args.find(arg => ["init", "validate", "plan", "apply"].includes(arg));
appendFileSync(${JSON.stringify(log)}, JSON.stringify({ args, action, directory }) + "\\n");
if (action === "init") process.exit(0);
if (action !== "validate") throw Error("Forbidden action in offline harness");
const mode = ${JSON.stringify(mode)}, missing = ${JSON.stringify(diagnostic)};
const valid = { valid: true, error_count: 0, warning_count: 0, diagnostics: [] };
let report = valid;
const fixturePath = join(directory, "main.tf.json");
if (await Bun.file(fixturePath).exists()) {
  const fixture = await Bun.file(fixturePath).json();
  const input = fixture.module.recipe;
  if (input.source !== "./recipe" || input.scm_runner_id !== "00000000-0000-0000-0000-000000000000" ||
      input.scm_oauth_client_secret !== "synthetic-offline-value-not-a-credential") throw Error("Not an explicit synthetic fixture");
  if (input.scm_oauth_client_id === "" && mode !== "accept-empty-id") report = missing;
} else {
  const source = await Bun.file(join(directory, "recipe.tf")).text();
  if (source.includes('resource "ona_scm_integration" "primary"')) {
    report = mode === "extra-scm-error" ? { ...missing, error_count: 2,
      diagnostics: [...missing.diagnostics, { severity: "error", summary: "Unsupported argument", detail: "New native schema defect" }] } : missing;
  } else if (mode === "early-failure" && source.includes("control: ona-1.1\\n")) {
    report = { valid: false, error_count: 1, warning_count: 0,
      diagnostics: [{ severity: "error", summary: "Unsupported argument", detail: "Early recipe fixture failure" }] };
  }
}
console.log(JSON.stringify(report));
process.exit(report.valid ? 0 : 1);
`);
  chmodSync(executable, 0o700);
  return { executable, log, directory };
}

async function run(mode: Parameters<typeof installedTerraformFixture>[0]) {
  const fixture = installedTerraformFixture(mode);
  const results = await validateOnaRecipes({ repositoryRoot, terraformBinary: fixture.executable, scratchParent: fixture.directory, log() {} });
  const calls = readFileSync(fixture.log, "utf8").trim().split("\n").map(line => JSON.parse(line));
  expect(calls.every(call => ["init", "validate"].includes(call.action))).toBe(true);
  expect(readdirSync(fixture.directory).some(name => name.startsWith("hth-ona-schema-"))).toBe(false);
  return { results, calls };
}

test("all 20 recipes and both configured SCM cases run without changing production inputs", async () => {
  const source = join(repositoryRoot, "packs/ona/terraform/hth-ona-4.03-scm-integration.tf");
  const before = readFileSync(source, "utf8");
  const { results, calls } = await run("valid");
  expect(results).toHaveLength(20);
  expect(results.every(result => result.passed)).toBe(true);
  expect(calls.filter(call => call.action === "init")).toHaveLength(22);
  expect(calls.filter(call => call.action === "validate")).toHaveLength(22);
  expect(readFileSync(source, "utf8")).toBe(before);
});

test("an early unexpected failure is retained while later recipes still run", async () => {
  const { results, calls } = await run("early-failure");
  expect(results).toHaveLength(20);
  expect(results.filter(result => !result.passed)).toHaveLength(1);
  expect(results[0].passed).toBe(false);
  expect(results.at(-1)?.recipe).toBe("hth-ona-6.02-webhook.tf");
  expect(results.at(-1)?.passed).toBe(true);
  expect(calls.filter(call => call.action === "validate")).toHaveLength(22);
});

test("the SCM exception never hides a second native error", async () => {
  const { results } = await run("extra-scm-error");
  const scm = results.find(result => result.recipe.includes("4.03"))!;
  expect(scm.passed).toBe(false);
  expect(scm.detail).toContain("Unexpected direct-root SCM result");
  expect(scm.detail).toContain("Unsupported argument");
  expect(results.at(-1)?.passed).toBe(true);
});

test("accepting an empty SCM client ID fails the gate", async () => {
  const { results } = await run("accept-empty-id");
  const scm = results.find(result => result.recipe.includes("4.03"))!;
  expect(scm.passed).toBe(false);
  expect(scm.detail).toContain("did not reject exactly the empty-ID fixture");
});

test("an incomplete recipe census cannot pass without running Terraform", async () => {
  const reducedRoot = mkdtempSync(join(scratch, "incomplete-"));
  const target = join(reducedRoot, "packs/ona/terraform");
  mkdirSync(target, { recursive: true });
  const names = readdirSync(join(repositoryRoot, "packs/ona/terraform")).filter(name => /^hth-.*\.tf$/.test(name));
  for (const name of names.slice(0, 19)) writeFileSync(join(target, name), "# incomplete census fixture\n");
  await expect(validateOnaRecipes({ repositoryRoot: reducedRoot, terraformBinary: "/missing-must-not-run", log() {} }))
    .rejects.toThrow("Expected all 20 numbered Ona recipes");
});
