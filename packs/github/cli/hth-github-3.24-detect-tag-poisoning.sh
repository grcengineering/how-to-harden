#!/usr/bin/env bash
# HTH GitHub Control 3.24: Detect and Prevent Action Tag Poisoning
# Profile: L1 | NIST: SI-7, SA-12
# https://howtoharden.com/guides/github/#310-detect-and-prevent-action-tag-poisoning

set -euo pipefail

# HTH Guide Excerpt: begin cli-detect-tag-poisoning
# Audit 1: Find action references NOT pinned to full SHAs
echo "=== Unpinned Action References ==="
find .github/workflows -name '*.yml' -o -name '*.yaml' | while read -r file; do
  grep -nE 'uses:\s+[^#]+@' "$file" | \
    grep -vE '@[0-9a-f]{40}' | \
    while read -r line; do
      echo "  $file:$line"
    done
done
echo "Fix: npx pin-github-action .github/workflows/*.yml"

# Audit 2: Verify pinned SHAs match expected tagged versions
echo ""
echo "=== SHA Verification ==="
find .github/workflows -name '*.yml' -o -name '*.yaml' | while read -r file; do
  grep -oE 'uses:\s+([a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+)@([0-9a-f]{40})\s+#\s*(v[0-9]+[^\s]*)' "$file" | \
    sed 's/uses:\s*//' | while read -r match; do
      action=$(echo "$match" | cut -d'@' -f1)
      sha=$(echo "$match" | cut -d'@' -f2 | cut -d' ' -f1)
      expected_tag=$(echo "$match" | grep -oE 'v[0-9]+[^\s]*')
      if [ -n "$expected_tag" ]; then
        actual_sha=$(gh api "repos/$action/git/ref/tags/$expected_tag" \
          --jq '.object.sha' 2>/dev/null || echo "FAILED")
        if [ "$actual_sha" = "$sha" ]; then
          echo "  OK: $action@$expected_tag"
        elif [ "$actual_sha" = "FAILED" ]; then
          echo "  WARN: $action@$expected_tag (API error)"
        else
          echo "  ALERT: $action@$expected_tag SHA MISMATCH!"
          echo "    Pinned:  $sha"
          echo "    Current: $actual_sha"
          echo "    Possible tag poisoning!"
        fi
      fi
    done
done

# Dependabot config for automatic SHA updates
# File: .github/dependabot.yml
cat <<'DEPENDABOT'

# Recommended: .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    groups:
      actions:
        patterns: ["*"]
DEPENDABOT
# HTH Guide Excerpt: end cli-detect-tag-poisoning
