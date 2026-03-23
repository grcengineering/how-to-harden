#!/usr/bin/env bash
# HTH Docker Hub Control 2.3: Pin Images by Digest
# Profile: L1 | NIST: SI-7, SA-12
# https://howtoharden.com/guides/dockerhub/#23-pin-images-by-digest-not-tag

# HTH Guide Excerpt: begin cli-pin-images-by-digest
# Get the current digest of an image tag
docker inspect --format='{{index .RepoDigests 0}}' aquasec/trivy:0.69.3
# Output: aquasec/trivy@sha256:abc123...

# Pin by digest in Dockerfile
# VULNERABLE: mutable tag
#   FROM aquasec/trivy:latest
#   FROM aquasec/trivy:0.69.3
# HARDENED: immutable digest
#   FROM aquasec/trivy@sha256:<digest>

# Pin by digest in docker-compose.yml
# services:
#   scanner:
#     image: aquasec/trivy@sha256:<digest>

# Pin by digest in GitHub Actions
# jobs:
#   scan:
#     container:
#       image: aquasec/trivy@sha256:<digest>

# Audit: find all mutable tag references in Dockerfiles
echo "=== Unpinned Image References ==="
find . -name 'Dockerfile*' -o -name 'docker-compose*.yml' | while read -r file; do
  grep -nE 'FROM\s+\S+:\S+' "$file" | grep -vE '@sha256:' | while read -r line; do
    echo "  $file:$line"
  done
  grep -nE 'image:\s+\S+:\S+' "$file" | grep -vE '@sha256:' | while read -r line; do
    echo "  $file:$line"
  done
done

# Verify a digest matches expected value
IMAGE="aquasec/trivy:0.69.3"
EXPECTED_DIGEST="sha256:<known-good-digest>"
ACTUAL_DIGEST=$(docker manifest inspect "$IMAGE" 2>/dev/null | \
  python3 -c "import json,sys; print(json.load(sys.stdin).get('config',{}).get('digest',''))" 2>/dev/null)
if [ "$ACTUAL_DIGEST" = "$EXPECTED_DIGEST" ]; then
  echo "OK: $IMAGE digest matches"
else
  echo "ALERT: $IMAGE digest mismatch!"
  echo "  Expected: $EXPECTED_DIGEST"
  echo "  Actual:   $ACTUAL_DIGEST"
fi
# HTH Guide Excerpt: end cli-pin-images-by-digest
