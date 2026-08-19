# =============================================================================
# HTH Pack Contract: v1
#   control: ona-2.2
#   guide:   https://howtoharden.com/guides/ona/#22-configure-the-agent-command-deny-list
#   profile: L1
#   mode:    mutating
#   requires: ONA_TOKEN(read-write PAT)
#
# HTH Ona Control 2.2: Configure the Agent Command Deny List
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 2.7 | NIST 800-53 CM-7 | NIST AI RMF MANAGE-2.3
# Source: https://howtoharden.com/guides/ona/#22-configure-the-agent-command-deny-list
#
# PROVIDER BLOCK LIVES IN hth-ona-1.01-configure-sso.tf.
#
# Transcribed from https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/organization_policies
# (registry v2 provider-doc 13236800, provider-version 105656 = 0.4.0-beta.1).
#
# SINGLETON — merge these attributes into ONE ona_organization_policies resource
# if you adopt more than one pack; two resources managing the same object drift
# forever.
#
# WHY TERRAFORM FOR THIS CONTROL: a deny list is a set that grows by accretion in
# a console and nobody can say who added what. As a versioned set literal, every
# addition and every quiet removal is a reviewable diff.
#
# TRAPS
#  1. agent_policy IS AN ATTRIBUTE, NOT A BLOCK. Write `agent_policy = { ... }`
#     with the `=`. Block syntax fails validation. command_deny_list is a Set of
#     String nested inside it.
#  2. OMITTING THE ATTRIBUTE IS NOT "EMPTY". Omit command_deny_list and the remote
#     deny list is left UNMANAGED — whatever someone set in the console survives
#     and Terraform will never revert it. Setting it to [] is what actively clears
#     it. Declare the set explicitly; that is what converts a console edit into
#     drift the next plan reverts.
#  3. THIS IS COMMAND-STRING MATCHING, NOT EXECUTABLE-PATH ENFORCEMENT. It sits
#     above the agent, not in the kernel. Pair it with the Veto executable policy
#     (pack 2.01), which enforces on the executable path itself and cannot be
#     evaded by rewriting the command line. A deny list alone is a speed bump.
#  4. PROTO3 OMITS DEFAULTS. On the read path an empty deny list is simply absent
#     from the API response. Absent means EMPTY (no commands denied), never
#     "compliant".
#  5. DESTROY IS NOT DELETE. Destroying ona_organization_policies restores the
#     server-defined policy configuration captured before Terraform first managed
#     the organization — the deny list reverts to whatever it was then.
# =============================================================================

variable "agent_command_deny_list" {
  description = "Commands agents may not execute. Setting [] CLEARS the remote list; omitting the attribute leaves it unmanaged."
  type        = set(string)
  default = [
    # History rewrite and force-push: the agent should never be able to destroy
    # review history or overwrite a protected branch non-interactively.
    "git push --force",
    "git push -f",
    "git reset --hard",
    "git clean -fdx",
    # Credential exfiltration helpers.
    "git config --global credential.helper store",
    # Untrusted-code fetch-and-run, the single most common agent-abuse pattern.
    "curl | bash",
    "curl | sh",
    "wget | bash",
    "wget | sh",
    # Privilege escalation inside the environment.
    "sudo su",
    "chmod 777",
  ]
}

# HTH Guide Excerpt: begin terraform
# SINGLETON: at most one ona_organization_policies per organization (import id "current") —
# merge these attributes with any other ona pack you adopt; two resources drift forever.
resource "ona_organization_policies" "agent_command_deny_list" {
  # ATTRIBUTE syntax (`=`), not a block.
  agent_policy = {
    # Declared explicitly so a console addition or deletion shows up as drift.
    command_deny_list = var.agent_command_deny_list
  }
}
# HTH Guide Excerpt: end terraform

output "ona_agent_command_deny_list_size" {
  description = "Number of denied command patterns actually in force. Zero means the control is off."
  value       = length(ona_organization_policies.agent_command_deny_list.agent_policy.command_deny_list)
}
