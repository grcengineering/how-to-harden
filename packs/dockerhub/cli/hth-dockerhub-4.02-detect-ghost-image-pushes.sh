#!/usr/bin/env bash
# HTH Docker Hub Control 4.2: Detect Ghost Image Pushes
# Profile: L1 | NIST: SI-4, AU-6
# https://howtoharden.com/guides/dockerhub/#42-detect-unauthorized-and-ghost-image-pushes

set -euo pipefail

# HTH Guide Excerpt: begin cli-detect-ghost-image-pushes
# Usage: ./detect-ghost-pushes.sh <namespace/repo> <github-org/repo>
DOCKER_REPO="${1:-aquasec/trivy}"
GITHUB_REPO="${2:-aquasecurity/trivy}"

echo "=== Ghost Image Push Detection ==="
echo "Docker Hub: $DOCKER_REPO"
echo "GitHub:     $GITHUB_REPO"
echo ""

# Step 1: List Docker Hub tags
echo "--- Docker Hub Tags (last 20) ---"
curl -s "https://hub.docker.com/v2/repositories/$DOCKER_REPO/tags?page_size=20&ordering=-last_updated" | \
  python3 -c "
import json, sys
data = json.load(sys.stdin)
for tag in data.get('results', []):
    name = tag['name']
    updated = tag.get('last_updated', 'unknown')
    digest = tag.get('digest', 'unknown')[:19]
    print(f'  {name:20s} {updated[:19]:20s} {digest}')
"

# Step 2: List GitHub releases
echo ""
echo "--- GitHub Releases (last 20) ---"
gh api "repos/$GITHUB_REPO/releases?per_page=20" --jq '.[].tag_name' 2>/dev/null | \
  while read -r tag; do echo "  $tag"; done

# Step 3: Find Docker tags with no matching GitHub release
echo ""
echo "--- Tags on Docker Hub with NO GitHub Release ---"
DOCKER_TAGS=$(curl -s "https://hub.docker.com/v2/repositories/$DOCKER_REPO/tags?page_size=100" | \
  python3 -c "import json,sys; [print(t['name']) for t in json.load(sys.stdin).get('results',[])]" 2>/dev/null)
GITHUB_TAGS=$(gh api "repos/$GITHUB_REPO/tags?per_page=100" --jq '.[].name' 2>/dev/null | sed 's/^v//')

for dtag in $DOCKER_TAGS; do
  # Skip non-version tags
  echo "$dtag" | grep -qE '^[0-9]+\.[0-9]+' || continue
  if ! echo "$GITHUB_TAGS" | grep -qx "$dtag"; then
    echo "  ALERT: $DOCKER_REPO:$dtag has NO matching GitHub release"
  fi
done

# Step 4: Check if 'latest' tag matches the latest GitHub release
echo ""
echo "--- Latest Tag Verification ---"
LATEST_GH=$(gh api "repos/$GITHUB_REPO/releases/latest" --jq '.tag_name' 2>/dev/null | sed 's/^v//')
echo "  Latest GitHub release: $LATEST_GH"
echo "  Verify: docker pull $DOCKER_REPO:$LATEST_GH and compare digest to :latest"
# HTH Guide Excerpt: end cli-detect-ghost-image-pushes
