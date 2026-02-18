# =============================================================================
# HTH Jenkins Control 3.3: Use Ephemeral Agents
# Profile Level: L2 (Hardened)
# Frameworks: CIS 4.1, NIST CM-6
# Source: https://howtoharden.com/guides/jenkins/#33-use-ephemeral-agents
#
# NOTE: Cloud agent configuration (Kubernetes, EC2, Docker) is managed via
# JCasC. This generates the JCasC YAML for Kubernetes pod templates with
# ephemeral agents that are destroyed after each build.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# JCasC configuration for Kubernetes ephemeral agents (L2+)
resource "local_file" "ephemeral_agents_k8s" {
  count = var.profile_level >= 2 && var.cloud_agent_type == "kubernetes" ? 1 : 0

  filename = "${path.module}/generated/casc-ephemeral-agents-k8s.yaml"
  content  = yamlencode({
    jenkins = {
      clouds = [
        {
          kubernetes = {
            name                  = "kubernetes"
            serverUrl             = var.k8s_server_url
            namespace             = var.k8s_namespace
            jenkinsUrl            = var.jenkins_server_url
            retentionTimeout      = 5
            connectTimeout        = 5
            readTimeout           = 15
            containerCapStr       = var.k8s_max_containers
            podRetention          = "never"
            templates = [
              {
                name      = "secure-agent"
                label     = var.secure_pipeline_agent_label
                nodeUsageMode = "EXCLUSIVE"
                containers = [
                  {
                    name            = "jnlp"
                    image           = var.agent_image
                    resourceLimitCpu    = var.agent_cpu_limit
                    resourceLimitMemory = var.agent_memory_limit
                    workingDir      = "/home/jenkins/agent"
                  }
                ]
                idleMinutes = 0
                yamlMergeStrategy = "override"
              }
            ]
          }
        }
      ]
    }
  })

  file_permission = "0644"
}

# JCasC configuration for Docker ephemeral agents (L2+)
resource "local_file" "ephemeral_agents_docker" {
  count = var.profile_level >= 2 && var.cloud_agent_type == "docker" ? 1 : 0

  filename = "${path.module}/generated/casc-ephemeral-agents-docker.yaml"
  content  = yamlencode({
    jenkins = {
      clouds = [
        {
          docker = {
            name = "docker"
            dockerApi = {
              dockerHost = {
                uri = var.docker_host_uri
              }
            }
            templates = [
              {
                labelString   = var.secure_pipeline_agent_label
                dockerTemplateBase = {
                  image = var.agent_image
                }
                remoteFs     = "/home/jenkins/agent"
                instanceCapStr = var.docker_max_instances
                retentionStrategy = {
                  idleMinutes = 0
                }
              }
            ]
          }
        }
      ]
    }
  })

  file_permission = "0644"
}
# HTH Guide Excerpt: end terraform
