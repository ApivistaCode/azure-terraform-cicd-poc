pipeline {
    agent { dockerfile true }

    options {
        // Discard old builds
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }

    stages {
        stage('Deploy to UAT') {
            when { tag '*.*.*' }
            steps {
                echo "Deploying to UAT: ${env.TAG_NAME}"
            }
        }
        stage ('Deploy to DEV') {
            when { branch 'development' }
            steps {
                echo "Deploying to DevTest: ${env.GIT_COMMIT}"
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
