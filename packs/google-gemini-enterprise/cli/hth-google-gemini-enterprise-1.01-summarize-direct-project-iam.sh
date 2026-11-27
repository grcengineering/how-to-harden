#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: google-gemini-enterprise-1.1
#   guide: https://howtoharden.com/guides/google-gemini-enterprise/#11-remove-unintended-project-wide-app-access
#   profile: L1
#   mode: read-only
#   requires: Bash, gcloud, jq, and authorized read access
# HTH google-gemini-enterprise 1.1: Remove unintended project-wide app access
# Profile: L1 (Crawl)
# Guide: https://howtoharden.com/guides/google-gemini-enterprise/
# Reference: https://docs.cloud.google.com/sdk/gcloud/reference/projects/get-iam-policy
# HTH Guide Excerpt: begin summarize-direct-project-iam
set +x
set -euo pipefail
: "${GEMINI_PROJECT_ID:?Set the explicitly approved Google Cloud project ID}"
if ! [[ "$GEMINI_PROJECT_ID" =~ ^[a-z][a-z0-9-]{4,28}[a-z0-9]$ ]]; then
  printf '%s\n' 'Use an ordinary Google Cloud project ID (6–30 characters)' >&2
  exit 2
fi
gcloud projects get-iam-policy "$GEMINI_PROJECT_ID" --format=json --quiet |
  jq -ces '
def summarize:
  def bindings: if has("bindings") then .bindings else [] end;
  if type == "object" and
    (has("bindings") or has("etag") or length == 0) and
    ((has("version") | not) or (.version | type == "number" and (. == 0 or . == 1 or . == 3))) and
    (bindings | type == "array" and
      all(.[]; type == "object" and (.role | type == "string") and
       (.members | type == "array" and all(.[]; type == "string")) and
       (.condition == null or (.condition | type == "object"))))
  then {policy_version: (.version // null),
        direct_bindings: (bindings |
          map({role, principal_count: (.members | length),
               public_principal_count: ([.members[] | select(. == "allUsers" or . == "allAuthenticatedUsers")] | length),
               conditional: (.condition != null)}))}
  else error("Unexpected IAM policy response") end;

    if length == 1 then .[0] | summarize
    else error("Expected one direct project IAM policy") end'
# HTH Guide Excerpt: end summarize-direct-project-iam
