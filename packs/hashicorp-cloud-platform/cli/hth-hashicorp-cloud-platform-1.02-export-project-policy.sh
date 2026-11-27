#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: hashicorp-cloud-platform-1.2
#   guide: https://howtoharden.com/guides/hashicorp-cloud-platform/
#   profile: L1
#   mode: read-only
#   requires: Bash and authorized first-party hcp CLI
# Source: https://developer.hashicorp.com/hcp/docs/cli/commands/projects/iam/read-policy
# HTH Guide Excerpt: begin export-project-policy
set -euo pipefail
set +x
: "${HCP_AUDIT_PROJECT:?Set the authorized HCP project UUID}"
: "${HCP_AUDIT_PROFILE:?Set the known HCP CLI profile}"
if [[ ! "$HCP_AUDIT_PROJECT" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ||
      ! "$HCP_AUDIT_PROFILE" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_-]{0,63}$ ]]; then
  printf 'Invalid project UUID or profile.\n' >&2
  exit 2
fi
umask 077
file=$(mktemp "${TMPDIR:-/tmp}/hth-hcp-policy.XXXXXXXX")
if ! hcp projects iam read-policy --project="$HCP_AUDIT_PROJECT" --profile="$HCP_AUDIT_PROFILE" \
     --format=json --quiet > "$file" || [[ ! -s "$file" ]]; then
  rm -f -- "$file"
  printf 'HCP project policy read failed or returned no data.\n' >&2
  exit 1
fi
printf 'Private project policy snapshot: %s\n' "$file"
# HTH Guide Excerpt: end export-project-policy
