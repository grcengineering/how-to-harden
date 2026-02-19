// =============================================================================
// HTH Jenkins Control 4.4: Secure Jenkinsfile Configuration
// Profile: L2 | Section: 4.4
// =============================================================================

// HTH Guide Excerpt: begin secure-jenkinsfile-template
pipeline {
    agent {
        label 'secure-agent'
    }

    options {
        // Limit build time
        timeout(time: 1, unit: 'HOURS')
        // Discard old builds
        buildDiscarder(logRotator(numToKeepStr: '10'))
        // Prevent concurrent builds
        disableConcurrentBuilds()
    }

    environment {
        // Use credentials binding
        AWS_CREDENTIALS = credentials('aws-deploy-creds')
    }

    stages {
        stage('Build') {
            steps {
                // Use approved methods only
                sh 'make build'
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                // Use credentials securely
                withCredentials([usernamePassword(
                    credentialsId: 'deploy-creds',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh './deploy.sh'
                }
            }
        }
    }

    post {
        always {
            // Clean up workspace
            cleanWs()
        }
    }
}
// HTH Guide Excerpt: end secure-jenkinsfile-template
