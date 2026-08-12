# Control: 4.1 Enforce Chrome Enterprise Policies on Browsers and Pools
# Profile Level: L2 (Walk)
# Frameworks: NIST 800-53 CM-7/CM-6, CIS Controls v8 4, SOC 2 CC6.8
# Guide: https://howtoharden.com/guides/kernel/
# Interface: Terraform provider kernel/kernel, kernel_browser_pool.chrome_policy —
#   https://github.com/kernel/terraform-provider-kernel (docs/resources/browser_pool.md)
#   Policy examples: https://www.kernel.sh/docs/browsers/chrome-policies

# HTH Guide Excerpt: begin hardened-pool-policy
# Pool-level policy applies to EVERY browser in the pool — the hardened
# configuration becomes the fleet default, not a per-callsite opt-in.
# chrome_policy is a JSON object of Chrome enterprise policies (max 5 MiB);
# Kernel-managed areas (extensions, proxy, CDP/automation) are rejected.
resource "kernel_browser_pool" "hardened_agents" {
  name    = "hardened-agents"
  size    = 5
  stealth = true

  chrome_policy = jsonencode({
    # Contain prompt-injection-driven navigation: allow only the domains
    # this workload legitimately needs; more specific entries win.
    URLAllowlist = [
      "crm.example.com",
      "docs.example.com",
    ]

    # Kernel's documented security example: block in-browser inspection
    # surfaces (cookies, storage, network internals).
    URLBlocklist = [
      "devtools://*",
      "chrome://inspect",
      "view-source:*",
      "*", # everything not on the allowlist
    ]
  })

  # Roll the new policy onto idle browsers when this config changes;
  # warming/leased browsers are not rebuilt.
  rebuild_idle_browsers_on_update = true
}
# HTH Guide Excerpt: end hardened-pool-policy
