pipeline {
    agent any
    
    tools{
        nodejs "node24"
    }
    
    environment {
        SCANNER_HOME=tool 'sonar-scanner'
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage("Cleanup workspace") {
            steps {
                cleanWs() // Clean the Jenkins workspace before starting
            }
        }
        
        stage("Checkout from SCM") {
            steps {
                // Clone the code from the specified GitHub repository
                git branch: 'main', 
                    credentialsId: 'github', 
                    url: 'https://github.com/Duybo007/devops-qr.git'
            }
        }
        
        stage('Frontend Compile') {
            steps {
                dir('front-end-nextjs'){
                    sh 'npm ci'
                }
            }
        }
        
        stage('Backend Compile') {
            steps {
                dir('api'){
                    sh '''
                        python3 -m venv venv
                        . venv/bin/activate
                        pip install --upgrade pip
                        pip install -r requirements.txt
                    '''
                }
            }
        }
        
        stage('GitLeaks') {
            steps {
                sh 'gitleaks detect --source ./front-end-nextjs --exit-code 1'
                sh 'gitleaks detect --source ./api --exit-code 1'
            }
        }
        
        stage("SonarQube Analysis") {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=qr \
                    -Dsonar.projectKey=qr '''
                }
            }
        }

        stage("Quality Gate") {
            steps {
                script {
                    // Wait for the SonarQube quality gate result before proceeding
                    waitForQualityGate abortPipeline: false, 
                                       credentialsId: 'sonar-token'
                }
            }
        }
        
        stage('TRIVY FS SCAN') {
            steps {
                sh "trivy fs --format table -o fs-report.txt ."
            }
        }
        
        stage('Build-Tag & Push Frontend Docker Image') {
            steps {
                script {
                    def frontendImage = "duybo95/devops-qr-code-frontend"
                    def frontendTag = "${frontendImage}:${BUILD_NUMBER}"
                    
                    withDockerRegistry(credentialsId: 'dockerhub') {
                        dir('front-end-nextjs') {
                            sh "docker build -t ${frontendTag} -t ${frontendImage}:latest ."
                            sh 'trivy image --format table -o frontend-image-report.html duybo95/devops-qr-code-frontend:latest '
                            sh "docker push ${frontendTag}"
                            sh "docker push ${frontendImage}:latest"
                        }
                    }
                }
            }
        }
        
        stage('Build-Tag & Push Backend Docker Image') {
            steps {
                script {
                    def backendImage = "duybo95/devops-qr-code-api"
                    def backendTag = "${backendImage}:${BUILD_NUMBER}"
                    
                    withDockerRegistry(credentialsId: 'dockerhub') {
                        dir('api') {
                            sh "docker build -t ${backendTag} -t ${backendImage}:latest ."
                            sh 'trivy image --format table -o backend-image-report.html duybo95/devops-qr-code-api:latest '
                            sh "docker push ${backendTag}"
                            sh "docker push ${backendImage}:latest"
                        }
                    }
                }
            }
        }
        
    }
}
