# =============================================================================
# HTH Duo Control 1.2: Protect Admin Credentials
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.11, NIST SC-12
# Source: https://howtoharden.com/guides/duo/#12-protect-admin-credentials
#
# Validates that Duo integration keys and secret keys are handled securely.
# This is a verification control -- it checks that credentials are not
# hardcoded and that proper secrets management is in place.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Validate that Duo credentials are provided via variables (not hardcoded)
resource "null_resource" "duo_credential_hygiene_check" {
  triggers = {
    run_always = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      echo "=== HTH Duo 1.2: Credential Hygiene Validation ==="
      echo ""
      echo "Verifying Duo credential security posture..."
      echo ""

      ISSUES=0

      # Check that credentials are not in plaintext tfvars
      if [ -f terraform.tfvars ]; then
        if grep -q "duo_secret_key" terraform.tfvars 2>/dev/null; then
          echo "WARNING: duo_secret_key found in terraform.tfvars"
          echo "  Recommendation: Use TF_VAR_duo_secret_key environment variable instead"
          ISSUES=$((ISSUES + 1))
        fi
        if grep -q "duo_integration_key" terraform.tfvars 2>/dev/null; then
          echo "WARNING: duo_integration_key found in terraform.tfvars"
          echo "  Recommendation: Use TF_VAR_duo_integration_key environment variable instead"
          ISSUES=$((ISSUES + 1))
        fi
      fi

      # Check that .gitignore excludes tfvars
      if [ -f .gitignore ]; then
        if ! grep -q "terraform.tfvars" .gitignore 2>/dev/null; then
          echo "WARNING: terraform.tfvars not in .gitignore"
          ISSUES=$((ISSUES + 1))
        fi
      else
        echo "WARNING: No .gitignore found -- terraform.tfvars may be committed"
        ISSUES=$((ISSUES + 1))
      fi

      if [ "$ISSUES" -eq 0 ]; then
        echo "PASS: No credential hygiene issues detected"
      else
        echo ""
        echo "FAIL: $ISSUES credential hygiene issue(s) found"
      fi

      echo ""
      echo "Best practices for Duo secret key management:"
      echo "  1. Use environment variables: export TF_VAR_duo_secret_key=..."
      echo "  2. Use a secrets manager: vault kv get -field=skey secret/duo"
      echo "  3. Never commit secrets to source control"
      echo "  4. Rotate keys immediately if compromise is suspected"
      echo "  5. Limit API credential scope to minimum required permissions"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
