#!/usr/bin/env bash
# HTH Cursor Control 2.3: Configure .cursorignore for Sensitive Files
# Profile: L1 | NIST: SC-4, AC-3
# https://howtoharden.com/guides/cursor/#23-configure-cursorignore-for-sensitive-files

# HTH Guide Excerpt: begin cli-cursorignore-template
# Create a comprehensive .cursorignore file to exclude sensitive files from AI context
cat > .cursorignore <<'IGNORE'
# === Credentials & Secrets ===
.env
.env.*
.env.local
.env.production
**/.env
**/secrets/
**/credentials/
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

echo ".cursorignore written with sensitive file exclusions"
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
  if ! grep -qF "$pattern" .cursorignore; then
    echo "  MISSING: $pattern not in .cursorignore"
    MISSING=$((MISSING + 1))
  fi
done

if [ "$MISSING" -eq 0 ]; then
  echo "PASS: All critical patterns present in .cursorignore"
else
  echo "WARN: $MISSING critical patterns missing from .cursorignore"
fi
# HTH Guide Excerpt: end cli-verify-cursorignore
