pipeline {
    agent {
        docker {
            image 'python:3.11'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }
    environment {
        SONARQUBE = credentials('sonarqube_token')
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/sareefhub/fastapi-app.git'
            }
        }
        stage('Install Dependencies') {
            steps {
                sh '''
                    python -m venv venv
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                    pip install pytest coverage pytest-cov
                '''
            }
        }
        stage('Run Tests & Coverage') {
            steps {
                sh '''
                    . venv/bin/activate
                    export PYTHONPATH=.
                    pytest --cov=app tests/ --cov-report=xml
                '''
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        . venv/bin/activate
                        /opt/sonar-scanner/bin/sonar-scanner \
                          -Dsonar.projectKey=fastapi-clean-demo \
                          -Dsonar.projectName="FastAPI Clean Demo" \
                          -Dsonar.projectVersion=1.0 \
                          -Dsonar.sources=app \
                          -Dsonar.tests=tests \
                          -Dsonar.python.coverage.reportPaths=coverage.xml \
                          -Dsonar.exclusions=**/tests/**,**/__pycache__/**,**/*.pyc,venv/** \
                          -Dsonar.sourceEncoding=UTF-8 \
                          -Dsonar.host.url=$SONAR_HOST_URL \
                          -Dsonar.login=$SONARQUBE
                    '''
                }
            }
        }
        stage('Quality Gate') {
            steps {
                timeout(time: 30, unit: 'SECONDS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'DOCKER_CONFIG=$WORKSPACE/.docker docker build -t fastapi-app:latest .'
            }
        }
        stage('Deploy Container') {
            steps {
                sh 'docker run -d -p 8000:8000 fastapi-app:latest'
            }
        }
    }
    post {
        always {
            echo "Pipeline finished"
        }
    }
}
