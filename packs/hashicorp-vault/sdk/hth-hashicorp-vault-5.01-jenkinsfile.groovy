// HTH HashiCorp Vault Control 5.1: Jenkins Vault Integration
// Profile: L1 | NIST: AC-3, AC-6
// https://howtoharden.com/guides/hashicorp-vault/#51-secure-jenkins-integration

// HTH Guide Excerpt: begin sdk-jenkinsfile
// Jenkinsfile
pipeline {
    agent any

    environment {
        VAULT_ADDR = 'https://vault.company.com'
    }

    stages {
        stage('Get Secrets') {
            steps {
                withVault(configuration: [
                    vaultUrl: "${VAULT_ADDR}",
                    vaultCredentialId: 'vault-approle'
                ], vaultSecrets: [
                    [path: 'secret/data/jenkins/api-keys',
                     secretValues: [[envVar: 'API_KEY', vaultKey: 'data.api_key']]]
                ]) {
                    sh 'echo "Using secret safely"'
                }
            }
        }
    }
}
// HTH Guide Excerpt: end sdk-jenkinsfile
