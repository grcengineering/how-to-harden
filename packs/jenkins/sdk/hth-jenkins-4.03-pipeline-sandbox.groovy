// =============================================================================
// HTH Jenkins Control 4.3: Implement Pipeline Sandbox
// Profile: L1 | Section: 4.3
// =============================================================================

// HTH Guide Excerpt: begin declarative-pipeline-example
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'make build'
            }
        }
    }
}
// HTH Guide Excerpt: end declarative-pipeline-example
