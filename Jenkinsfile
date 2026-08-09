pipeline {
    agent any

    environment {
        IMAGE_NAME = "omkardile2682/devsecops-nexus:${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'mvn test'
            }
        }

        stage('OWASP Dependency-Check') {
            steps {
                sh '''
                    echo "=== Jenkins Workspace ==="
                    pwd

                    echo "=== Creating report directory ==="
                    mkdir -p "$WORKSPACE/dependency-check-report"

                    echo "=== Checking directory ==="
                    ls -ld "$WORKSPACE/dependency-check-report"

                    echo "=== Running Dependency-Check ==="
                    dependency-check.sh \
                        --project "DevSecOps-Nexus" \
                        --scan "$WORKSPACE" \
                        --format HTML \
                        --format XML \
                        --out "$WORKSPACE/dependency-check-report" \
                        --failOnCVSS 11 \
                        --disableOssIndex
                '''
            }
        }

        stage('SonarQube Analysis') {
            environment {
                SCANNER_HOME = tool 'SonarScanner'
            }

            steps {
                withSonarQubeEnv('SonarCloud') {
                    sh """
                        ${SCANNER_HOME}/bin/sonar-scanner
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 1, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false
                }
            }
        }

        stage('Upload Artifact to JFrog') {
            steps {
                sh '''
                    jf c use jfrog-server
                    jf rt upload "target/*.jar" "libs-release-local/"
                '''
            }
        }

        stage('Download Artifact from JFrog') {
            steps {
                sh '''
                    mkdir -p downloaded
                    jf c use jfrog-server
                    jf rt download "libs-release-local/**/*.jar" "downloaded/"
                '''
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    dockerImage = docker.build("${IMAGE_NAME}")
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh '''
                    trivy image \
                        --severity HIGH,CRITICAL \
                        --exit-code 0 \
                        "${IMAGE_NAME}"
                '''
            }
        }

        stage('Docker Push to JFrog') {
            steps {
                script {
                    docker.withRegistry(
                        'https://index.docker.io/v1/',
                        'credentials-dockerhub'
                    ) {
                        dockerImage.push("${BUILD_NUMBER}")
                        dockerImage.push('latest')
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                    aws eks update-kubeconfig \
                        --region eu-north-1 \
                        --name my-eks-cluster

                    kubectl apply -f deployment.yaml
                    kubectl apply -f service.yaml

                    kubectl get pods
                '''
            }
        }
    }

    post {
        always {
            cleanWs()
        }

        success {
            echo 'Pipeline executed successfully.'
        }

        failure {
            echo 'Pipeline execution failed.'
        }
    }
}
