pipeline {
    agent any

    environment {
        ACR_NAME       = 'tangodown15'
        ACR_REGISTRY   = 'tangodown15.azurecr.io'
        IMAGE_NAME     = 'shopping-cart'
        IMAGE_TAG      = "${BUILD_NUMBER}"
        AKS_RG         = 'learning-rg'
        AKS_CLUSTER    = 'aks-learning'
        K8S_NAMESPACE  = 'shopping-cart'
        HELM_RELEASE   = 'shopping-cart'
        HELM_CHART_DIR = './chart/shopping-cart'
        SONAR_PROJECT  = 'shopping-cart'
    }

    stages {
        stage('Sanity Check') {
            steps {
                echo "Pipeline started for build #${BUILD_NUMBER}"
                echo "Image will be: ${ACR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                sh 'echo "Running on:"; hostname'
                sh 'echo "Tools available:"; which git node docker az kubectl helm trivy snyk sonar-scanner || true'
            }
        }
        stage('Checkout Code') {
            steps {
                cleanWs()
                checkout scm
                sh 'echo "Workspace contents:"; ls -la'
                sh 'echo "Current commit:"; git rev-parse --short HEAD'
            }
        }
        stage('Install Dependencies') {
            steps {
                sh '''
                    echo "=== Node version ==="
                    node --version
                    npm --version

                    echo "=== Installing dependencies with npm ci ==="
                    npm ci

                    echo "=== Sanity check on installed deps ==="
                    ls node_modules | head -20
                    echo "Total packages installed:"
                    ls node_modules | wc -l
                '''
            }
        }
    stage('SonarQube SAST') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'
                    withSonarQubeEnv('MySonarQube') {
                        sh """
                            echo "=== Running SonarQube scan ==="
                            ${scannerHome}/bin/sonar-scanner \\
                                -Dsonar.projectKey=${SONAR_PROJECT} \\
                                -Dsonar.projectName=${SONAR_PROJECT} \\
                                -Dsonar.projectVersion=${BUILD_NUMBER}
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished with status: ${currentBuild.currentResult}"
        }
    }
}