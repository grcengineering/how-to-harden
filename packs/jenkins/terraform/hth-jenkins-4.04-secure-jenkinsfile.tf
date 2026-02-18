# =============================================================================
# HTH Jenkins Control 4.4: Secure Jenkinsfile Configuration
# Profile Level: L2 (Hardened)
# Frameworks: CIS 16.9, NIST CM-3
# Source: https://howtoharden.com/guides/jenkins/#44-secure-jenkinsfile-configuration
#
# Creates a secure pipeline template job demonstrating hardened Jenkinsfile
# practices: build timeouts, discard old builds, workspace cleanup,
# credential binding, and branch-restricted deployments.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Secure pipeline template job (L2+)
resource "jenkins_job" "secure_pipeline_template" {
  count = var.profile_level >= 2 && var.create_secure_pipeline_template ? 1 : 0

  name   = "hth-secure-pipeline-template"
  folder = length(var.team_folders) > 0 ? jenkins_folder.team_folder[keys(var.team_folders)[0]].id : null

  template = templatefile("${path.module}/templates/secure-pipeline-config.xml", {
    agent_label    = var.secure_pipeline_agent_label
    timeout_hours  = var.build_timeout_hours
    builds_to_keep = var.builds_to_keep
  })
}

# Generate the secure pipeline config.xml template
resource "local_file" "secure_pipeline_config_xml" {
  count = var.profile_level >= 2 && var.create_secure_pipeline_template ? 1 : 0

  filename = "${path.module}/templates/secure-pipeline-config.xml"
  content  = <<-XML
    <flow-definition plugin="workflow-job">
      <description>HTH Secure Pipeline Template - demonstrates hardened Jenkinsfile practices</description>
      <keepDependencies>false</keepDependencies>
      <properties>
        <org.jenkinsci.plugins.workflow.job.properties.DisableConcurrentBuildsJobProperty/>
        <jenkins.model.BuildDiscarderProperty>
          <strategy class="hudson.tasks.LogRotator">
            <numToKeep>${var.builds_to_keep}</numToKeep>
          </strategy>
        </jenkins.model.BuildDiscarderProperty>
      </properties>
      <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps">
        <script>
    pipeline {
        agent {
            label '${var.secure_pipeline_agent_label}'
        }
        options {
            timeout(time: ${var.build_timeout_hours}, unit: 'HOURS')
            buildDiscarder(logRotator(numToKeepStr: '${var.builds_to_keep}'))
            disableConcurrentBuilds()
        }
        stages {
            stage('Build') {
                steps {
                    sh 'echo "Build stage - replace with actual build commands"'
                }
            }
            stage('Test') {
                steps {
                    sh 'echo "Test stage - replace with actual test commands"'
                }
            }
            stage('Deploy') {
                when {
                    branch 'main'
                }
                steps {
                    withCredentials([usernamePassword(
                        credentialsId: 'deploy-creds',
                        usernameVariable: 'USER',
                        passwordVariable: 'PASS'
                    )]) {
                        sh 'echo "Deploy stage - replace with actual deploy commands"'
                    }
                }
            }
        }
        post {
            always {
                cleanWs()
            }
        }
    }
        </script>
        <sandbox>true</sandbox>
      </definition>
      <triggers/>
      <disabled>true</disabled>
    </flow-definition>
  XML

  file_permission = "0644"
}
# HTH Guide Excerpt: end terraform
