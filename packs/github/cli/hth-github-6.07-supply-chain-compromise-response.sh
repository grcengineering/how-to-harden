#!/usr/bin/env bash
# HTH GitHub Control 6.07: CI/CD Supply Chain Compromise Response
# Profile: L1 | NIST: IR-4, IR-5, IR-6
# https://howtoharden.com/guides/github/#66-respond-to-cicd-supply-chain-compromises

set -euo pipefail

# HTH Guide Excerpt: begin cli-supply-chain-compromise-response
# Usage: ./hth-github-6.07-supply-chain-compromise-response.sh <action> [org]
# Example: ./hth-github-6.07-supply-chain-compromise-response.sh aquasecurity/trivy-action myorg
COMPROMISED_ACTION="${1:-aquasecurity/trivy-action}"
ORG="${2:-$(gh api user --jq '.login')}"

echo "=== Supply Chain Compromise Response ==="
echo "Scanning org '$ORG' for: $COMPROMISED_ACTION"

# Step 1: Find affected repositories
echo ""
echo "--- Affected Repositories ---"
gh api --paginate "/orgs/$ORG/repos" --jq '.[].full_name' | while read -r repo; do
  result=$(gh api "repos/$repo/git/trees/HEAD?recursive=1" \
    --jq '.tree[] | select(.path | startswith(".github/workflows/")) | .path' 2>/dev/null || true)
  for workflow in $result; do
    content=$(gh api "repos/$repo/contents/$workflow" \
      --jq '.content' 2>/dev/null | base64 -d 2>/dev/null || true)
    if echo "$content" | grep -qi "$COMPROMISED_ACTION"; then
      echo "  AFFECTED: $repo ($workflow)"
    fi
  done
done

# Step 2: List secrets requiring rotation
echo ""
echo "--- Secrets Requiring Immediate Rotation ---"
echo "Organization secrets:"
gh api "/orgs/$ORG/actions/secrets" \
  --jq '.secrets[] | "  - \(.name) (updated: \(.updated_at))"' 2>/dev/null \
  || echo "  (requires admin access)"
echo ""
echo "Check each affected repo: gh api /repos/OWNER/REPO/actions/secrets"

# Step 3: TeamPCP-specific indicators
echo ""
echo "--- TeamPCP Exfiltration Indicators ---"
gh api "/orgs/$ORG/repos" --jq '.[].name' 2>/dev/null | \
  grep -i "tpcp" && echo "  ALERT: Found tpcp exfil repo!" || \
  echo "  OK: No tpcp-docs repos found"
echo ""
echo "Check network logs for:"
echo "  - scan.aquasecurtiy.org (Trivy typosquat, resolves to 45.148.10.212)"
echo "  - *.gist.githubusercontent.com (tj-actions exfil)"
echo ""
echo "Known compromised commit SHAs (Trivy March 2026):"
echo "  - setup-trivy: 8afa9b9f9183b4e00c46e2b82d34047e3c177bd0"
echo "  - trivy-action: ddb9da4 (and all tags except v0.62.1)"
echo ""
echo "Check package managers for compromised tool versions:"
echo "  - Homebrew: brew info trivy (v0.69.4 was malicious)"
echo "  - Helm charts: check for automated version bump PRs"
echo "  - Container images: check builds using trivy during compromise window"

# Step 4: Containment actions
echo ""
echo "--- Immediate Containment ---"
echo "1. Pin to known-good SHA: npx pin-github-action .github/workflows/*.yml"
echo "2. Disable workflows: gh workflow disable WORKFLOW --repo OWNER/REPO"
echo "3. Rotate ALL secrets (org + repo + environment)"
echo "4. Revoke OIDC cloud sessions (AWS STS, Azure, GCP)"
echo "5. Audit artifact registries for tainted builds"
echo "6. Notify downstream consumers"
# HTH Guide Excerpt: end cli-supply-chain-compromise-response
