#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: gainsight-px-2.1
#   guide: https://howtoharden.com/guides/gainsight-px/
#   profile: L1
#   mode: read-only
#   requires: Bash and jq
# Source: https://support.gainsight.com/v1/docs/security-tracking-filters
# HTH Guide Excerpt: begin render-tracking-exclusions
set -euo pipefail
if (( $# == 0 )); then
  printf 'Supply one or more approved PX URL patterns as quoted arguments.\n' >&2
  exit 2
fi
for pattern in "$@"; do
  if [[ -z "$pattern" || "$pattern" == '*' || "$pattern" == *$'\n'* || "$pattern" == *$'\r'* ]]; then
    printf 'Empty, wildcard-only or multiline patterns are not allowed.\n' >&2
    exit 2
  fi
done
jq -cn --args '{filterType:"exclude", filterUrls:$ARGS.positional}' -- "$@"
# HTH Guide Excerpt: end render-tracking-exclusions
