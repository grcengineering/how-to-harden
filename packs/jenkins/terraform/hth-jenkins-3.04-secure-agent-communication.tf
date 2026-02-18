# =============================================================================
# HTH Jenkins Control 3.4: Secure Agent Communication
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.10, NIST SC-8
# Source: https://howtoharden.com/guides/jenkins/#34-secure-agent-communication
#
# NOTE: Agent protocol configuration is a system-level setting managed via
# JCasC. This generates configuration to disable insecure protocols and
# enforce TLS-encrypted inbound agent connections (JNLP4).
# =============================================================================

# HTH Guide Excerpt: begin terraform
# JCasC configuration to enforce secure agent protocols
resource "local_file" "secure_agent_communication" {
  filename = "${path.module}/generated/casc-secure-agent-protocols.yaml"
  content  = yamlencode({
    jenkins = {
      agentProtocols = [
        "JNLP4-connect",
      ]
      slaveAgentPort = var.agent_inbound_port
    }
    security = {
      # Disable CLI over remoting (use SSH or HTTP API instead)
      csp = {
        # Content Security Policy for Jenkins UI
      }
    }
  })

  file_permission = "0644"
}

# Groovy init script to enforce JNLP4 only and disable legacy protocols
resource "local_file" "secure_agent_protocols_groovy" {
  filename = "${path.module}/generated/init.groovy.d/secure-agent-protocols.groovy"
  content  = <<-GROOVY
    // HTH Jenkins Control 3.4: Secure Agent Communication
    // Profile Level: L1 (Baseline)
    import jenkins.model.Jenkins

    def instance = Jenkins.instance

    // Enable only JNLP4 (TLS-encrypted) protocol
    Set<String> agentProtocols = new HashSet<>()
    agentProtocols.add("JNLP4-connect")
    instance.setAgentProtocols(agentProtocols)

    // Set fixed inbound agent port (required for firewall rules)
    instance.setSlaveAgentPort(${var.agent_inbound_port})

    instance.save()
    println("[HTH] Agent protocols restricted to JNLP4-connect (TLS)")
    println("[HTH] Inbound agent port set to ${var.agent_inbound_port}")
  GROOVY

  file_permission = "0644"
}
# HTH Guide Excerpt: end terraform
