#!/usr/bin/env bash
# =============================================================================
# HTH Buildkite Control 3.5: Manage Build Secrets — pipeline-settings exposure
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 3.11 | NIST 800-53 SC-12, SC-28
# Source: https://howtoharden.com/guides/buildkite/#35-manage-build-secrets
#
# Guide Step 3 states the exposure and ships no way to find it. Buildkite says it
# plainly: "pipeline settings are often returned in REST and GraphQL API
# payloads." A credential pasted into a pipeline's env block is therefore not
# exposed to the build — it is exposed to every token that can read the pipeline,
# a far larger population, and it leaves no build log behind. Log redaction does
# not touch this path at all: the value never had to be printed to be disclosed.
#
# Control 3.5 Step 3 is a prohibition, so there is nothing to positively
# configure. The deliverable is enumerate -> classify -> exit non-zero, wired
# into a scheduled pipeline as a gate, plus a guarded removal for afterwards.
#
# ── ⚠️ TRAP 1: a scanner that prints what it finds is worse than no scanner ──
# The naive version of this tool pipes GET /pipelines into grep and lands every
# credential it discovers in a CI log, a scrollback buffer and a shell history
# file — converting a settings exposure into a log exposure as well. Nothing here
# ever emits a value. A finding carries the pipeline, the location, the variable
# NAME, the value's length, a format classification, and a truncated digest.
# The digest is sha256 over the value's base64 form, which is deliberately NOT
# the sha256 of the secret: it is stable across runs and machines, so it answers
# "did this rotate?" and "is this same credential reused in three pipelines?",
# and it is not a hash an attacker can match against a table of known values.
#
# ── ⚠️ TRAP 2: `configuration` is a STRING, not parsed YAML ─────────────────
# `env` and each step's `env` are JSON objects and traverse normally. The
# pipeline's `configuration` field is the raw YAML document delivered as ONE
# string, so jq path traversal finds nothing inside it. It is split and scanned
# line-wise below. Line-wise matters twice over: most issuer formats are anchored
# patterns that can only match a whole field, and entropy scoring over a whole
# pipeline definition flags every pipeline in the organization (ordinary YAML
# runs about 4.3 bits/char at byte level) which turns the scanner into noise.
#
# ── ⚠️ TRAP 3: `steps` only covers pipelines defined IN Buildkite ───────────
# A pipeline whose Buildkite step list is a single `buildkite-agent pipeline
# upload` keeps its real steps in `.buildkite/pipeline.yml` in the repository,
# where this API cannot see them. A clean result there means "no secret in the
# stored settings", never "no secret in this pipeline". Rather than leave that in
# a comment nobody reads, `upload_driven` is computed per pipeline and `summary`
# lists those pipelines under `upload_driven_not_meaningfully_scanned`. Repo-
# defined steps need a source-side secret scanner.
#
# ── ⚠️ TRAP 4: a pointer into a secret store is the GOAL, not a finding ─────
# `DEPLOY_TOKEN: $BUILDKITE_DEPLOY_TOKEN`, `vault:secret/data/prod#key` and
# `arn:aws:secretsmanager:...` are all exactly what control 3.5 steers people
# toward. Flagging them trains readers to ignore the scanner, which is how a
# detection control dies. Reference-shaped values are classified OK_REFERENCE and
# counted separately from material.
#
# ── ⚠️ TRAP 5: `provider.settings` is a third surface ───────────────────────
# Findings are not confined to `env`. The source-control provider settings block
# is part of the same payload and is where webhook and integration tokens end up.
# A scanner that walks only `.env` and `.steps[].env` misses it entirely.
#
# ── ⚠️ TRAP 6: `$VAR` and `$$VAR` are opposite bugs ─────────────────────────
# Buildkite interpolates a single `$` at UPLOAD time, so the value is substituted
# into the uploaded pipeline and rendered in the build timeline; `$$VAR` survives
# to the shell and expands inside the job. Against a secret-shaped name the
# difference is whether the credential gets published. `interpolation` reports
# single-`$` references and deliberately ignores correctly escaped `$$` and `\$`.
#
# ── ⚠️ TRAP 7: removal is not remediation ──────────────────────────────────
# Anything this finds has already been served to every token that could read the
# pipeline, and if it was interpolated it sits in past build timelines. Deleting
# the variable stops the bleeding; it does not un-expose the credential. Rotation
# at the issuer is the remediation, which is why `strip-env` refuses to run
# without an explicit `--rotated` acknowledgement.
#
# ── ⚠️ TRAP 8: archived pipelines still serve their settings ───────────────
# `archived_at` stops builds; it does not redact the payload. An archived
# pipeline's stored credential stays readable by any token with read_pipelines,
# and it is exactly the kind nobody rotates because nobody looks at it. Archived
# pipelines are scanned and labelled, never skipped.
#
# ── ⚠️ TRAP 9: `read_pipelines` understates who can see this ───────────────
# REST needs the `read_pipelines` scope. GraphQL returns the same fields and, per
# Buildkite, is "accessed using an authenticated API access token whose scopes
# cannot be restricted" (see the 2.5 token-hygiene pack, TRAP 5). Reasoning about
# blast radius from the REST scope list alone undercounts it.
#
# ── ⚠️ TRAP 10: short values are exposed twice ─────────────────────────────
# The agent's log redactor ignores anything under 6 bytes
# (internal/redact/redact.go: `const LengthMin = 6`). A short credential in
# pipeline settings is therefore both API-readable AND unredactable if it is ever
# echoed. Such findings are labelled `below_redaction_floor` rather than dropped.
#
# Name matching is suffix-anchored on purpose: it mirrors how the agent's
# `redacted-vars` globs match, so this pack and the 3.5 config pack agree on what
# "secret-shaped" means. The consequence is worth knowing — `MYSECRET` matches
# nothing, only `*_SECRET` does.
#
# ── VERIFICATION STATUS ─────────────────────────────────────────────────────
#   Field names, the steps[] shape, `page`/`per_page` + Link-header pagination
#   and the required `read_pipelines` scope were read from Buildkite's REST
#   pipelines documentation. The core secret-shaped name patterns are the agent's
#   own documented `redacted-vars` default set, so a key flagged here is a key the
#   agent would also have redacted had the value been printed.
#   DRIFT-CHECKED-ONLY: not executed against the principal's organization. That
#   tenant has 0 pipelines, so a live run would have matched against an empty set
#   and proved nothing; the classifier was instead exercised against fixture
#   payloads shaped like the documented response, covering literal credentials in
#   env, in step env, in provider settings and in the configuration YAML, plus
#   reference-shaped values, archived pipelines and upload-driven pipelines.
#   `strip-env` is the only mutation in this pack and was NOT executed.
#
# Requires: BUILDKITE_TOKEN (scope: read_pipelines; write_pipelines for
#           strip-env), BUILDKITE_ORG_SLUG, curl, jq, and shasum or sha256sum.
# =============================================================================

set -euo pipefail

: "${BUILDKITE_TOKEN:?set BUILDKITE_TOKEN (API access token with read_pipelines)}"
: "${BUILDKITE_ORG_SLUG:?set BUILDKITE_ORG_SLUG (organization slug from your Buildkite URL)}"

REST="https://api.buildkite.com/v2"
PER_PAGE="${HTH_PER_PAGE:-100}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "FATAL: '$1' not found on PATH." >&2; exit 5; }; }
need curl; need jq

# HTH Guide Excerpt: begin scan-pipeline-settings-for-secrets
# TRAP 1: the only thing this script is ever permitted to say about a value.
# Input is the value's base64 form, which keeps the digest portable and keeps it
# from doubling as a lookup key for the plaintext.
fingerprint_b64() {
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$1" | sha256sum | cut -c1-12
  elif command -v shasum >/dev/null 2>&1; then
    printf '%s' "$1" | shasum -a 256 | cut -c1-12
  else
    echo "FATAL: need sha256sum or shasum to fingerprint findings without printing them." >&2
    exit 5
  fi
}

# Enumerate every pipeline, archived ones included (TRAP 8), following the
# documented Link-header pagination rather than guessing at page counts.
collect_pipelines() {
  local url="${REST}/organizations/${BUILDKITE_ORG_SLUG}/pipelines?per_page=${PER_PAGE}"
  local hdr body next jsonl
  hdr="$(mktemp)"; jsonl="$(mktemp)"
  trap 'rm -f "${hdr}" "${jsonl}"' RETURN

  while [ -n "${url}" ]; do
    body="$(curl -sS --fail-with-body -D "${hdr}" \
      -H "Authorization: Bearer ${BUILDKITE_TOKEN}" \
      -H "Accept: application/json" "${url}")"

    jq -e 'type == "array"' >/dev/null <<<"${body}" || {
      echo "unexpected response from ${url}:" >&2
      jq -r '.message // "non-array payload"' <<<"${body}" >&2
      exit 4
    }
    jq -c '.[]' <<<"${body}" >>"${jsonl}"

    # rel="next" is authoritative; its absence ends the collection.
    next="$(tr -d '\r' <"${hdr}" \
      | sed -n 's/^[Ll]ink:.*//p; s/.*<\([^>]*\)>; *rel="next".*/\1/p' | tail -1)"
    [ "${next}" = "${url}" ] && next=""
    url="${next}"
  done

  jq -s '.' "${jsonl}"
}

# Digests are computed in the shell because jq has no hash builtin. Values travel
# as base64 so a value containing tabs or newlines cannot corrupt the stream, and
# so no plaintext is ever passed through argv (TRAP 1).
build_digest_table() {
  jq -r '
      .[] as $p
      | ( ($p.env // {}) | to_entries[]
          | ["pipeline.env", $p.slug, .key, ((.value|tostring)|@base64)] )
      , ( ($p.steps // [])[] | (.env // {}) | to_entries[]
          | ["step.env", $p.slug, .key, ((.value|tostring)|@base64)] )
      , ( ($p.provider.settings // {}) | to_entries[]
          | ["provider.settings", $p.slug, .key, ((.value|tostring)|@base64)] )
      | @tsv' \
  | while IFS=$'\t' read -r loc slug name b64; do
      [ -n "${slug:-}" ] || continue
      jq -cn --arg k "${loc}::${slug}::${name}" \
             --arg d "$(fingerprint_b64 "${b64}")" '{($k): $d}'
    done \
  | jq -s 'add // {}'
}

# The classifier. Held in a single-quoted heredoc so the jq source needs no shell
# escaping — an escaped-jq-inside-double-quotes program is where these scripts
# silently break.
read -r -d '' HTH_SCAN_JQ <<'JQEOF' || true
# Shannon entropy over the raw bytes, in bits per character. Credential material
# drawn from a random alphabet sits above 4.2; prose, paths, versions and
# identifiers sit below it.
def shannon:
  (explode) as $b | ($b | length) as $n
  | if $n == 0 then 0
    else ($b | group_by(.) | map(length / $n) | map(. * (log / (2 | log))) | add | -.)
    end;

# TRAP 4: a pointer INTO a secret store is the pattern this control wants people
# to adopt. Includes the Buildkite interpolation form, which is the shape the
# guide's own examples use.
def is_reference:
  test("^(https?://|s3://|gs://|vault:|arn:|/|\\./|secret/|projects/[^/]+/secrets/)")
  or test("^\\$\\$?\\{?[A-Za-z_][A-Za-z0-9_]*\\}?$");

# Suffix-anchored, mirroring the agent's redacted-vars globs so this pack and the
# 3.5 config pack agree on "secret-shaped". Consequence: MYSECRET matches
# nothing, only *_SECRET does.
def name_is_secret_shaped:
  ascii_upcase
  | test("(_PASSWORD|_SECRET|_TOKEN|_PRIVATE_KEY|_ACCESS_KEY|_SECRET_KEY|_CONNECTION_STRING|_SSH_KEY|_API_KEY|_CREDENTIALS?|_PASSWD|_APIKEY|_AUTH)$")
    or test("^(PASSWORD|SECRET|TOKEN|API_KEY|AWS_SECRET_ACCESS_KEY|NPM_TOKEN|GITHUB_TOKEN|GH_TOKEN|DOCKER_PASSWORD|SLACK_TOKEN)$");

# Issuer-documented credential formats. These describe SHAPES, never values, so
# they are safe to publish and stable across rotations. The PEM test matches the
# armour envelope generically, catching RSA, EC and OPENSSH key blocks without
# this file having to carry a key header verbatim.
def issuer_format_kind:
  if   test("^-----BEGIN [A-Z0-9 ]*KEY-----")                                          then "pem_key_block"
  elif test("(^|[^A-Z0-9])(AKIA|ASIA|AGPA|AIDA|AROA|AIPA|ANPA|ABIA|ACCA)[A-Z0-9]{16}") then "aws_access_key_id"
  elif test("^gh[pousr]_[A-Za-z0-9]{36,}$")                                            then "github_token"
  elif test("^github_pat_[A-Za-z0-9_]{20,}$")                                          then "github_fine_grained_pat"
  elif test("^xox[abposr]-[A-Za-z0-9-]{10,}$")                                          then "slack_token"
  elif test("^sk-[A-Za-z0-9_-]{20,}$")                                                  then "openai_style_key"
  elif test("^AIza[0-9A-Za-z_-]{35}$")                                                  then "google_api_key"
  elif test("^eyJ[A-Za-z0-9_-]{10,}\\.[A-Za-z0-9_-]{10,}\\.")                            then "jwt"
  else null end;

# Entropy heuristics, applied only to individual values and to single
# configuration lines — never to a whole YAML document (TRAP 2). The mixed-class
# requirement is what separates a random credential from a path, a semver, a
# hostname or an identifier.
def opaque_material_kind:
  if   test("^[A-Za-z0-9+/]{32,}={0,2}$") and (shannon > 4.0)                       then "high_entropy_base64"
  elif test("^[0-9a-fA-F]{40,}$")                                                   then "long_hex_digest_or_key"
  elif test("^[!-~]{24,256}$") and test("[a-z]") and test("[A-Z]") and test("[0-9]")
       and (shannon > 4.2) and (is_reference | not)                                 then "high_entropy_opaque"
  else null end;

def value_material_kind: issuer_format_kind // opaque_material_kind;

# TRAP 1: name, length, classification, digest. Never a value.
def finding($digests; $pipeline; $location; $name; $value):
  ($value | value_material_kind) as $kind
  | ($name  | name_is_secret_shaped) as $named
  | if ($kind == null and $named == false) then empty
    else {
      pipeline: $pipeline,
      location: $location,
      variable: $name,
      name_is_secret_shaped: $named,
      value_material_kind: $kind,
      value_length: ($value | length),
      # TRAP 10: under 6 bytes the agent's redactor would not have masked it
      # either, so such a value is exposed on both paths at once.
      below_redaction_floor: (($value | length) > 0 and ($value | length) < 6),
      value_sha256_prefix: ($digests[$location + "::" + $pipeline + "::" + $name] // "n/a"),
      severity: (if $kind != null then "CRITICAL"
                 elif ($value | is_reference) then "OK_REFERENCE"
                 else "REVIEW" end),
      finding: (if $kind != null then
                  "Holds text matching a credential format. Every API token that can read this pipeline can read this value."
                elif ($value | is_reference) then
                  "Named like a secret but holds a pointer into a secret store. That is the pattern control 3.5 steers toward - no action."
                else
                  "Named like a secret. Confirm by hand whether the value is material or a harmless reference."
                end)
    } end;

# TRAP 2: the configuration YAML arrives as one string, so it is split and judged
# a line at a time. Each line is tested twice — as a `key: value` pair, which lets
# the name rules and the anchored issuer formats apply, and as raw text, which
# catches material pasted straight into a command with no variable at all.
def configuration_findings($p):
  [ ($p.configuration // "") | split("\n") | to_entries[]
    | .key as $ln | (.value) as $line
    | ( ( $line
          | capture("^\\s*(?<k>[A-Za-z_][A-Za-z0-9_]*)\\s*:\\s*(?<v>\\S.*?)\\s*$") // empty
          | { k: .k, v: (.v | sub("^[\"']"; "") | sub("[\"'],?$"; "")) }
          | select((.k | name_is_secret_shaped) or ((.v | value_material_kind) != null))
          | { pipeline: $p.slug,
              location: ("pipeline.configuration:line " + (($ln + 1) | tostring)),
              variable: .k,
              name_is_secret_shaped: (.k | name_is_secret_shaped),
              value_material_kind: (.v | value_material_kind),
              value_length: (.v | length),
              below_redaction_floor: ((.v | length) > 0 and (.v | length) < 6),
              value_sha256_prefix: "n/a",
              severity: (if (.v | value_material_kind) != null then "CRITICAL"
                         elif (.v | is_reference) then "OK_REFERENCE"
                         else "REVIEW" end),
              finding: "Declared inside the stored pipeline YAML, which is returned in full by the REST and GraphQL pipeline payloads." } )
      , ( $line
          | select((capture("^\\s*[A-Za-z_][A-Za-z0-9_]*\\s*:\\s*\\S") // null) == null)
          | select(issuer_format_kind != null)
          | { pipeline: $p.slug,
              location: ("pipeline.configuration:line " + (($ln + 1) | tostring)),
              variable: "<literal in step configuration>",
              name_is_secret_shaped: false,
              value_material_kind: issuer_format_kind,
              value_length: length,
              below_redaction_floor: false,
              value_sha256_prefix: "n/a",
              severity: "CRITICAL",
              finding: "The stored pipeline YAML contains text matching a credential format - material pasted into a command rather than referenced through a variable." } ) )
  ];

def classify($digests):
  map(. as $p | {
    pipeline: $p.slug,
    visibility: ($p.visibility // "unknown"),
    # TRAP 8: archived stops builds, not disclosure.
    archived: (($p.archived_at // null) != null),
    # TRAP 3: on an upload-driven pipeline a clean verdict describes the
    # settings, not the steps that actually run.
    upload_driven: ((($p.configuration // "")
                     + (($p.steps // []) | map(.command // "") | join("\n")))
                    | test("buildkite-agent[[:space:]]+pipeline[[:space:]]+upload")),
    # Surfaced so a REST shape change shows up in the report instead of
    # silently narrowing what was scanned.
    fields_seen: ($p | keys | map(select(. == "env" or . == "steps" or . == "configuration" or . == "provider"))),
    findings: (
        [ ($p.env // {}) | to_entries[]
          | finding($digests; $p.slug; "pipeline.env"; .key; (.value | tostring)) ]
      + [ ($p.steps // [])[] | (.env // {}) | to_entries[]
          | finding($digests; $p.slug; "step.env"; .key; (.value | tostring)) ]
      # TRAP 5: provider settings ride in the same payload and are where webhook
      # and integration tokens end up.
      + [ ($p.provider.settings // {}) | to_entries[]
          | finding($digests; $p.slug; "provider.settings"; .key; (.value | tostring)) ]
      + configuration_findings($p)
    )
  })
  | map(select((.findings | length) > 0 or .upload_driven));
JQEOF

scan() {
  local pipelines digests
  pipelines=$(collect_pipelines)
  digests=$(build_digest_table <<<"${pipelines}")
  jq --argjson digests "${digests}" "${HTH_SCAN_JQ}"'
    classify($digests)' <<<"${pipelines}"
}

# Exits non-zero when credential material is being served, so this drops into a
# scheduled pipeline as a gate rather than a report nobody opens.
summary() {
  local report
  report=$(scan)
  jq '{
    pipelines_with_findings: (map(select((.findings | length) > 0)) | length),
    critical:     ([.[].findings[] | select(.severity == "CRITICAL")]     | length),
    review:       ([.[].findings[] | select(.severity == "REVIEW")]       | length),
    ok_reference: ([.[].findings[] | select(.severity == "OK_REFERENCE")] | length),
    # TRAP 10: served in the payload AND unredactable in logs.
    below_redaction_floor: ([.[].findings[] | select(.below_redaction_floor)] | length),
    # TRAP 8: least likely to be rotated, still fully readable.
    archived_pipelines_with_findings: (map(select(.archived and ((.findings | length) > 0)) | .pipeline)),
    # TRAP 3, made unmissable: a clean scan across upload-driven pipelines is not
    # a clean estate, it is an unscanned one.
    upload_driven_not_meaningfully_scanned: (map(select(.upload_driven) | .pipeline)),
    verdict: (if ([.[].findings[] | select(.severity == "CRITICAL")] | length) > 0
              then "FAIL - credential material is being served in pipeline settings"
              else "no credential material found in pipeline settings" end)
  }' <<<"${report}"
  [ "$(jq '[.[].findings[] | select(.severity == "CRITICAL")] | length' <<<"${report}")" -eq 0 ]
}
# HTH Guide Excerpt: end scan-pipeline-settings-for-secrets

# HTH Guide Excerpt: begin detect-unescaped-interpolation
# TRAP 6. `$VAR` is substituted when the pipeline is UPLOADED and the result is
# visible in the build timeline; `$$VAR` reaches the shell and is expanded inside
# the job. Against a secret-shaped name the difference is whether the credential
# gets printed. This reports single-`$` references and deliberately ignores
# correctly escaped `$$` and `\$`.
interpolation() {
  collect_pipelines | jq '
    def secret_shaped: ascii_upcase
      | test("(_PASSWORD|_SECRET|_TOKEN|_PRIVATE_KEY|_ACCESS_KEY|_SECRET_KEY|_CONNECTION_STRING|_SSH_KEY|_API_KEY|_CREDENTIALS?)$");

    map(. as $p
      | (($p.configuration // "") + "\n"
         + (($p.steps // []) | map((.command // "") + "\n" + (.label // "")) | join("\n"))) as $text
      | {
          pipeline: $p.slug,
          # A `$` preceded by neither another `$` nor a backslash, followed by a
          # secret-shaped identifier, bare or braced.
          interpolated_at_upload_time: (
            [ $text
              | scan("(?:^|[^$\\\\])\\$\\{?([A-Za-z_][A-Za-z0-9_]*)\\}?")
              | .[0] | select(secret_shaped) ] | unique
          )
        }
      | select((.interpolated_at_upload_time | length) > 0)
      | . + { finding: "These secret-shaped names are interpolated at UPLOAD time, so their values are substituted into the uploaded pipeline and shown in the build timeline. Escape them as $$NAME so the shell expands them inside the job instead." }
    )'
}
# HTH Guide Excerpt: end detect-unescaped-interpolation

# HTH Guide Excerpt: begin remove-secret-from-pipeline-settings
# TRAP 7. Removal is not remediation. Anything `scan` finds has already been
# served in REST and GraphQL payloads to every token that can read the pipeline,
# and if it was interpolated it sits in past build timelines. Rotation at the
# issuer is the remediation; this only stops the bleeding afterwards.
rest_get() {
  curl -sS --fail-with-body \
    -H "Authorization: Bearer ${BUILDKITE_TOKEN}" \
    -H "Accept: application/json" \
    "${REST}$1"
}

# The PATCH sends the COMPLETE remaining env object, read immediately before the
# write. That is correct whether the API merges the field or replaces it — and
# under replace semantics a partial env would silently delete every other
# variable on the pipeline.
strip_env() {
  local slug="$1" var="$2" ack="${3:-}" current remaining response after

  if [ "${ack}" != "--rotated" ]; then
    cat >&2 <<'ROTATE'
REFUSING: pass --rotated as the third argument.

Deleting the variable does not un-expose the credential. It has already been
returned in REST and GraphQL payloads to every token that can read this
pipeline, and if it was interpolated into an uploaded pipeline it is in the
build timeline of every build since it was added.

Correct order:
  1. Rotate the credential at its issuer, so the exposed value is worthless.
  2. Move the new value into a cluster secret with an access policy
     (packs/buildkite/terraform/hth-buildkite-3.05-cluster-secrets.tf)
     or into your external secret store.
  3. Re-run this command with --rotated.
ROTATE
    exit 3
  fi

  current=$(rest_get "/organizations/${BUILDKITE_ORG_SLUG}/pipelines/${slug}" | jq '.env // {}')

  if [ "$(jq --arg v "${var}" 'has($v)' <<<"${current}")" != "true" ]; then
    echo "pipeline '${slug}' has no env variable named '${var}'; nothing to remove." >&2
    exit 4
  fi

  remaining=$(jq --arg v "${var}" 'del(.[$v])' <<<"${current}")

  if ! response=$(curl -sS --fail-with-body -X PATCH \
    -H "Authorization: Bearer ${BUILDKITE_TOKEN}" \
    -H "Content-Type: application/json" \
    --data "$(jq -n --argjson env "${remaining}" '{env: $env}')" \
    "${REST}/organizations/${BUILDKITE_ORG_SLUG}/pipelines/${slug}"); then
    echo "FAILED: the API rejected the PATCH for pipeline '${slug}':" >&2
    printf '%s\n' "${response}" >&2
    echo "'${var}' is still set and the credential remains exposed." >&2
    exit 5
  fi

  # VERIFY THE REMOVAL — do not assert it. The comment above establishes that the
  # request is correct under EITHER merge or replace semantics; it does not
  # establish that the key is gone. Under merge semantics the variable survives
  # the PATCH, and printing removed_variable from the write's own reply reports a
  # removal that did not happen. This runs during a live credential exposure,
  # immediately after the operator confirmed rotation, so a false "removed" is
  # exactly the output that ends an incident response one step too early.
  # Re-read from the server rather than reading the write's echo: the PATCH
  # response is not guaranteed to carry .env, and an omitted field is
  # indistinguishable from a deleted key when you only look at the reply.
  after=$(rest_get "/organizations/${BUILDKITE_ORG_SLUG}/pipelines/${slug}" | jq '.env // {}')

  if [ "$(jq --arg v "${var}" 'has($v)' <<<"${after}")" = "true" ]; then
    echo "FAILED: '${var}' is STILL present on pipeline '${slug}' after the PATCH." >&2
    echo "This API merged the env object rather than replacing it, so a payload" >&2
    echo "that omits a key cannot delete it. Remove the variable in the console" >&2
    echo "(Pipeline Settings -> Environment Variables) and re-run this command to" >&2
    echo "confirm. Until it reports verified_absent, treat the value as exposed." >&2
    exit 6
  fi

  jq -n --arg s "${slug}" --arg v "${var}" --argjson after "${after}" '{
      pipeline: $s,
      removed_variable: $v,
      verified_absent: true,
      remaining_env_keys: ($after | keys),
      reminder: "Rotation at the issuer is what actually remediated this. Confirm the old credential is dead."
    }'
}
# HTH Guide Excerpt: end remove-secret-from-pipeline-settings

case "${1:-summary}" in
  scan)          scan ;;
  summary)       summary ;;
  interpolation) interpolation ;;
  strip-env)     strip_env "${2:?pipeline slug required}" "${3:?env variable name required}" "${4:-}" ;;
  *)
    cat >&2 <<'USAGE'
usage:
  hth-buildkite-3.05-pipeline-env-scan.sh summary                     # counts + verdict (exit 1 on CRITICAL)
  hth-buildkite-3.05-pipeline-env-scan.sh scan                        # per-pipeline findings
  hth-buildkite-3.05-pipeline-env-scan.sh interpolation               # unescaped $SECRET in step config
  hth-buildkite-3.05-pipeline-env-scan.sh strip-env SLUG VAR --rotated

env:
  BUILDKITE_TOKEN               API access token (read_pipelines; write_pipelines for strip-env)
  BUILDKITE_ORG_SLUG            organization slug
  HTH_PER_PAGE                  page size (default 100)

Findings never contain secret values - only names, lengths, a credential-format
classification and a truncated digest for cross-run correlation.
USAGE
    exit 2 ;;
esac
