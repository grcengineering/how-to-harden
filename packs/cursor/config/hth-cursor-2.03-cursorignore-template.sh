#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-2.3
#   guide:   https://howtoharden.com/guides/cursor/#23-configure-cursorignore-for-sensitive-files
#   profile: L1
#   mode:    mutating
#   requires: run from the project root
# =============================================================================
# HTH Cursor Control 2.3: Configure .cursorignore for Sensitive Files
# Profile Level: L1 (Crawl) | NIST 800-53: SC-4, AC-3
# Source: https://howtoharden.com/guides/cursor/#23-configure-cursorignore-for-sensitive-files
#
# Writes a .cursorignore template (.gitignore syntax,
# https://cursor.com/docs/reference/ignore-file) — but NEVER over an existing
# one. An earlier revision ran `cat > .cursorignore`, which silently dropped any
# curated exclusions the project already had and re-exposed those files to AI
# context. If the file exists, the template goes to .cursorignore.hth for a
# manual merge and the pack exits 1.
#
# Remember the documented limit: .cursorignore does not stop the Agent's
# terminal or MCP tools from reading a file. Pair it with 5.1/5.2 and 7.2.
#
# Exit codes: 0 written / verified | 1 not written (file existed, template left
# in .cursorignore.hth) or a critical pattern is missing
# =============================================================================

# HTH Guide Excerpt: begin cli-cursorignore-template
# Create a .cursorignore that keeps secrets and infrastructure state out of AI
# context. Refuses to overwrite an existing .cursorignore.
TARGET=".cursorignore"
if [ -e "$TARGET" ]; then
  TARGET=".cursorignore.hth"
  echo "NOTE: .cursorignore already exists — writing the template to $TARGET for a manual merge"
fi
cat > "$TARGET" <<'IGNORE'
# === Credentials & Secrets ===
.env
.env.*
**/.env
**/.env.*
**/secrets/
**/credentials/
**/credentials.json
**/secrets.json
*.pem
*.key
*.p12
*.pfx
*.jks
id_rsa*
id_ed25519*
*.keystore

# === Cloud & Infrastructure Configs ===
.aws/
.azure/
.gcloud/
kubeconfig*
terraform.tfstate*
terraform.tfvars
*.auto.tfvars

# === Internal Configuration ===
**/config/production.*
**/config/secrets.*
docker-compose.override.yml

# === Cursor / IDE Configuration ===
.cursor/mcp.json
.vscode/launch.json

# === Compliance & Legal ===
**/compliance/
**/legal/
**/audit/
IGNORE
echo "Template written to $TARGET"
[ "$TARGET" = ".cursorignore" ] || exit 1
# HTH Guide Excerpt: end cli-cursorignore-template

# HTH Guide Excerpt: begin cli-verify-cursorignore
# Verify .cursorignore is present and covers critical patterns
echo "=== .cursorignore Audit ==="
if [ ! -f .cursorignore ]; then
  echo "FAIL: .cursorignore not found in project root"
  exit 1
fi

REQUIRED_PATTERNS=(".env" "*.pem" "*.key" "id_rsa" "terraform.tfstate" ".aws/")
MISSING=0
for pattern in "${REQUIRED_PATTERNS[@]}"; do
  if ! grep -qF -- "$pattern" .cursorignore; then
    echo "  MISSING: $pattern not in .cursorignore"
    MISSING=$((MISSING + 1))
  fi
done

if [ "$MISSING" -eq 0 ]; then
  echo "PASS: All critical patterns present in .cursorignore"
else
  echo "FAIL: $MISSING critical pattern(s) missing from .cursorignore"
  exit 1
fi
# HTH Guide Excerpt: end cli-verify-cursorignore
