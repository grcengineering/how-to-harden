# =============================================================================
# HTH Vercel Control 4.2: Configure DDoS Protection and Attack Challenge Mode
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-5, CP-10
# Source: https://howtoharden.com/guides/vercel/#42-configure-ddos-protection-and-attack-challenge-mode
# =============================================================================

# HTH Guide Excerpt: begin terraform

# --- L1: Enable Attack Challenge Mode (activate during active attacks) ---
resource "vercel_attack_challenge_mode" "protection" {
  project_id = var.project_id
  team_id    = var.vercel_team_id
  enabled    = var.attack_challenge_mode_enabled
}

# HTH Guide Excerpt: end terraform
