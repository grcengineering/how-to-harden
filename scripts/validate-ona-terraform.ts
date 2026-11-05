// Native schema checks only: never plan/apply, configure credentials or call Ona.
import { copyFile, mkdir, mkdtemp, readdir, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { basename, join, resolve } from "node:path";

const scmRecipe = "hth-ona-4.03-scm-integration.tf";
const expectedRecipes = 20;
const missingIdSummary = "Missing OAuth Client ID";
const missingIdDetail = 'Set oauth_client_id when auth_mode is "oauth".';
export const syntheticScmClientId = "synthetic-offline-oauth-client-id";

type Diagnostic = { severity?: string; summary?: string; detail?: string };
type Validation = { valid?: boolean; error_count?: number; warning_count?: number; diagnostics?: Diagnostic[] };
type Command = { code: number; stdout: string; stderr: string };
export type RecipeResult = { recipe: string; passed: boolean; detail: string };

// Reject additional errors and warnings instead of broadly ignoring the failure.
export function isKnownScmUnknownDiagnostic(value: unknown): value is Validation {
  if (!value || typeof value !== "object") return false;
  const report = value as Validation;
  return report.valid === false && report.error_count === 1 && report.warning_count === 0 &&
    Array.isArray(report.diagnostics) && report.diagnostics.length === 1 &&
    report.diagnostics[0] !== null && typeof report.diagnostics[0] === "object" &&
    report.diagnostics[0].severity === "error" &&
    report.diagnostics[0].summary === missingIdSummary &&
    report.diagnostics[0].detail?.trim() === missingIdDetail;
}

// Bind only the known-bug expression in a private CI copy. Every other byte,
// including required production variables and provider configuration, survives.
export function bindSyntheticScmClientId(source: string, clientId: string): string {
  if (clientId !== syntheticScmClientId && clientId !== "") throw new Error("Only synthetic SCM fixture values are allowed.");
  const expression = /^([ \t]*oauth_client_id[ \t]*=[ \t]*)var\.scm_oauth_client_id([ \t]*)$/gm;
  const matches = [...source.matchAll(expression)];
  if (matches.length !== 1) throw new Error(`Expected exactly one SCM client-ID variable expression; found ${matches.length}.`);
  const match = matches[0];
  const replacement = match[1] + JSON.stringify(clientId) + match[2];
  return source.slice(0, match.index!) + replacement + source.slice(match.index! + match[0].length);
}

function parsed(command: Command): Validation {
  try { return JSON.parse(command.stdout); }
  catch { throw new Error(`Terraform returned no valid diagnostic JSON (exit ${command.code}).\n${command.stderr}`); }
}

export async function validateOnaRecipes(options: {
  repositoryRoot?: string;
  terraformBinary?: string;
  scratchParent?: string;
  log?: (line: string) => void;
} = {}): Promise<RecipeResult[]> {
  const repository = resolve(options.repositoryRoot ?? join(import.meta.dir, ".."));
  const recipesDirectory = join(repository, "packs/ona/terraform");
  const recipes = (await readdir(recipesDirectory)).filter(name => /^hth-.*\.tf$/.test(name)).sort();
  if (recipes.length !== expectedRecipes || !recipes.includes(scmRecipe)) {
    throw new Error(`Expected all ${expectedRecipes} numbered Ona recipes, including ${scmRecipe}; found ${recipes.length}.`);
  }
  const scratch = await mkdtemp(join(options.scratchParent ?? tmpdir(), "hth-ona-schema-"));
  const log = options.log ?? console.log;
  const results: RecipeResult[] = [];
  const terraform = options.terraformBinary ?? "terraform";

  async function command(directory: string, args: string[]): Promise<Command> {
    const child = Bun.spawn([terraform, `-chdir=${directory}`, ...args], { stdout: "pipe", stderr: "pipe" });
    const [code, stdout, stderr] = await Promise.all([
      child.exited, new Response(child.stdout).text(), new Response(child.stderr).text(),
    ]);
    return { code, stdout, stderr };
  }
  async function initialize(directory: string) {
    const result = await command(directory, ["init", "-backend=false", "-input=false", "-no-color"]);
    if (result.code !== 0) throw new Error(`Provider initialization failed.\n${result.stdout}\n${result.stderr}`);
  }
  async function validate(directory: string) {
    const commandResult = await command(directory, ["validate", "-json"]);
    return { command: commandResult, report: parsed(commandResult) };
  }
  async function scmFixture(parent: string, clientId: string, name: string) {
    const directory = join(parent, name);
    await mkdir(directory, { mode: 0o700 });
    await copyFile(join(recipesDirectory, "versions.tf"), join(directory, "versions.tf"));
    const production = await Bun.file(join(recipesDirectory, scmRecipe)).text();
    await writeFile(join(directory, "recipe.tf"), bindSyntheticScmClientId(production, clientId), { mode: 0o600 });
    await initialize(directory);
    return validate(directory);
  }

  try {
    for (const recipe of recipes) {
      const directory = join(scratch, basename(recipe, ".tf"));
      await mkdir(directory, { mode: 0o700 });
      await copyFile(join(recipesDirectory, "versions.tf"), join(directory, "versions.tf"));
      await copyFile(join(recipesDirectory, recipe), join(directory, "recipe.tf"));
      try {
        await initialize(directory);
        const direct = await validate(directory);
        if (recipe === scmRecipe) {
          if (direct.command.code === 0 || !isKnownScmUnknownDiagnostic(direct.report)) {
            throw new Error(`Unexpected direct-root SCM result; only the documented single unknown-ID diagnostic is expected.\n${direct.command.stdout}\n${direct.command.stderr}`);
          }
          const positive = await scmFixture(directory, syntheticScmClientId, "known-id");
          if (positive.command.code !== 0 || positive.report.valid !== true || positive.report.error_count !== 0) {
            throw new Error(`Native SCM validation rejected the literal-bound CI copy.\n${positive.command.stdout}\n${positive.command.stderr}`);
          }
          const negative = await scmFixture(directory, "", "empty-id");
          if (negative.command.code === 0 || !isKnownScmUnknownDiagnostic(negative.report)) {
            throw new Error(`Native SCM validation did not reject exactly the empty-ID fixture.\n${negative.command.stdout}\n${negative.command.stderr}`);
          }
          results.push({ recipe, passed: true, detail: "Exact direct-root diagnostic; native literal-bound CI copy accepted and empty ID rejected." });
        } else {
          if (direct.command.code !== 0 || direct.report.valid !== true || direct.report.error_count !== 0) {
            throw new Error(`Native recipe validation failed.\n${direct.command.stdout}\n${direct.command.stderr}`);
          }
          results.push({ recipe, passed: true, detail: "Native schema validation passed." });
        }
      } catch (error) {
        results.push({ recipe, passed: false, detail: error instanceof Error ? error.message : String(error) });
      }
      const result = results.at(-1)!;
      log(`${result.passed ? "PASS" : "FAIL"} ${recipe}: ${result.detail}`);
    }
  } finally { await rm(scratch, { recursive: true, force: true }); }
  return results;
}

if (import.meta.main) {
  try {
    const results = await validateOnaRecipes();
    const failures = results.filter(result => !result.passed);
    console.log(`Ona native schema summary: ${results.length - failures.length}/${results.length} recipes passed; ${failures.length} failed. No plan/apply was run.`);
    if (failures.length) process.exitCode = 1;
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  }
}
