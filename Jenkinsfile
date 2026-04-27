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
        stage('Snyk SCA') {
            steps {
                withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
                    sh '''
                        echo "=== Authenticating with Snyk ==="
                        snyk auth $SNYK_TOKEN

                        echo "=== Running Snyk dependency scan (informational mode) ==="
                        snyk test --severity-threshold=high || true

                        echo "=== Sending snapshot to Snyk dashboard ==="
                        snyk monitor --project-name=shopping-cart || true

                        echo "=== Snyk SCA complete ==="
                    '''
                }
            }
        }
        stage('Docker Build') {
            steps {
                sh '''
                    echo "=== Building Docker image ==="
                    docker build -t $ACR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG .

                    echo "=== Tagging as latest for convenience ==="
                    docker tag $ACR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG $ACR_REGISTRY/$IMAGE_NAME:latest

                    echo "=== Image info ==="
                    docker images $ACR_REGISTRY/$IMAGE_NAME --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
                '''
            }
        }
        stage('Trivy Image Scan') {
            steps {
                sh '''
                    echo "=== Running Trivy scan on built image ==="

                    # Run Trivy. Exit code 0 = no issues at this severity.
                    # Exit code 1 = issues found (which we expect for old codebase).
                    # Other exit codes = real errors.
                    trivy image \
                        --severity HIGH,CRITICAL \
                        --ignore-unfixed \
                        --no-progress \
                        --format table \
                        $ACR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG
                    SCAN_EXIT=$?

                    if [ $SCAN_EXIT -ne 0 ] && [ $SCAN_EXIT -ne 1 ]; then
                        echo "ERROR: Trivy crashed (exit code $SCAN_EXIT). Failing the build."
                        exit $SCAN_EXIT
                    fi
                    echo "Trivy scan completed (exit code $SCAN_EXIT). Continuing pipeline."

                    echo "=== Generating Trivy JSON report for archival ==="
                    trivy image \
                        --severity HIGH,CRITICAL \
                        --format json \
                        --output trivy-report.json \
                        $ACR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG || true

                    echo "=== Trivy scan complete ==="
                    ls -la trivy-report.json
                '''
                archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: true
            }
        }
    }

    post {
        always {
            echo "Pipeline finished with status: ${currentBuild.currentResult}"
        }
    }
}