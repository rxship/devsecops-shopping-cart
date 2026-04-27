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
    }

    post {
        always {
            echo "Pipeline finished with status: ${currentBuild.currentResult}"
        }
    }
}