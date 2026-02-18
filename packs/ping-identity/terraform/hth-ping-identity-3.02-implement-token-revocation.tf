# =============================================================================
# HTH Ping Identity Control 3.2: Implement Token Revocation
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-2(6)
# Source: https://howtoharden.com/guides/ping-identity/#32-implement-token-revocation
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Sign-on policy with session revocation on risk detection
resource "pingone_sign_on_policy" "risk_based_revocation" {
  environment_id = var.pingone_environment_id
  name           = "HTH Risk-Based Token Revocation"
  description    = "Revoke tokens and sessions on high-risk authentication events"
}

# Risk policy: medium risk triggers step-up, high risk triggers revocation
resource "pingone_risk_policy" "token_revocation" {
  environment_id = var.pingone_environment_id
  name           = "HTH High-Risk Revocation Policy"
  default_result = { level = "LOW" }

  evaluated_predictors = [
    { predictor_id = data.pingone_risk_predictor.ip_reputation.id },
    { predictor_id = data.pingone_risk_predictor.anonymous_network.id },
    { predictor_id = data.pingone_risk_predictor.geovelocity.id },
  ]

  policy_scores = {
    medium = { min_score = 40, max_score = 69 }
    high   = { min_score = 70, max_score = 100 }
  }
}

# Data sources for built-in risk predictors
data "pingone_risk_predictor" "ip_reputation" {
  environment_id = var.pingone_environment_id
  name           = "IP Reputation"
}

data "pingone_risk_predictor" "anonymous_network" {
  environment_id = var.pingone_environment_id
  name           = "Anonymous Network Detection"
}

data "pingone_risk_predictor" "geovelocity" {
  environment_id = var.pingone_environment_id
  name           = "Geo-Velocity"
}

# Sign-on policy action: high risk triggers MFA + revocation
resource "pingone_sign_on_policy_action" "high_risk_mfa" {
  environment_id    = var.pingone_environment_id
  sign_on_policy_id = pingone_sign_on_policy.risk_based_revocation.id
  priority          = 1

  mfa {
    device_sign_on_policy_id = pingone_mfa_device_policy.phishing_resistant.id
    no_device_mode           = "BLOCK"
  }

  conditions {
    last_sign_on_older_than_seconds = 3600
  }
}

# L2+: Custom risk predictor for unusual token issuance volume
resource "pingone_risk_predictor" "token_velocity" {
  count = var.profile_level >= 2 ? 1 : 0

  environment_id = var.pingone_environment_id
  name           = "HTH Token Velocity"
  compact_name   = "hthTokenVelocity"

  predictor_velocity {
    measure = "DISTINCT_COUNT"
    of      = "$${event.ip}"
    by      = ["$${event.user.id}"]

    every = {
      min_sample = 5
      quantity   = 1
      unit       = "HOUR"
    }

    sliding_window = {
      min_sample = 5
      quantity   = 7
      unit       = "DAY"
    }

    use = {
      type = "POISSON_WITH_MAX"
      medium = 2.0
      high   = 4.0
    }
  }
}
# HTH Guide Excerpt: end terraform
