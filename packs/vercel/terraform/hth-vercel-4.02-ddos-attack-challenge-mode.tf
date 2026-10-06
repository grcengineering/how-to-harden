# =============================================================================
# HTH Vercel Control 4.2: Configure DDoS Protection and Attack Challenge Mode
# Profile Level: L1 (Crawl)
# Frameworks: NIST SC-5, CP-10
# Source: https://howtoharden.com/guides/vercel/#42-configure-ddos-protection-and-attack-challenge-mode
# =============================================================================

# HTH Guide Excerpt: begin terraform

# --- L1: Attack Challenge Mode (activate during active attacks) ---
# Managed only while enabled. With the default (false) nothing is sent, so an
# apply never switches off Attack Challenge Mode that someone turned on during
# an attack. Setting the variable back to false destroys the resource, and the
# provider then switches the mode off.
resource "vercel_attack_challenge_mode" "protection" {
  count = var.attack_challenge_mode_enabled ? 1 : 0

  project_id = var.project_id
  team_id    = var.vercel_team_id
  enabled    = true

  # Required: Unix time in ms. Vercel turns the mode off when it passes, and
  # `enabled` then drifts to false.
  attack_mode_active_until = var.attack_mode_active_until

  lifecycle {
    precondition {
      condition     = var.attack_mode_active_until > 0
      error_message = "Set attack_mode_active_until (Unix ms) when enabling Attack Challenge Mode."
    }
  }
}

# HTH Guide Excerpt: end terraform
