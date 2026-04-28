#!/usr/bin/env bash
# HTH CyberArk Control 5.1: Configure Automatic Password Rotation — Complexity
# Profile: L1 | NIST: IA-5(1)
# https://howtoharden.com/guides/cyberark/#51-configure-automatic-password-rotation
#
# CyberArk Platform password-policy values. Apply via the CyberArk PVWA UI
# or the Platform Management API. (No first-party CyberArk CLI for PSM.)

set -euo pipefail

OUT_FILE="${OUT_FILE:-./password-complexity.platform.conf}"

# HTH Guide Excerpt: begin config-password-complexity
cat > "${OUT_FILE}" <<'CONF'
MinLength=20
RequireUppercase=true
RequireLowercase=true
RequireNumbers=true
RequireSpecial=true
ExcludedCharacters='"<>;
CONF
# HTH Guide Excerpt: end config-password-complexity

echo "Wrote password-complexity policy to ${OUT_FILE}"
echo "Apply these values to the target Platform via PVWA → Platform Management."
