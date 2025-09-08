pipeline {
    agent {
        docker {
            image 'python-java:3.11'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
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
                    script {
                        def scannerHome = tool 'sonar-scanner'
                        sh """
                            . venv/bin/activate && \
                            ${scannerHome}/bin/sonar-scanner \
                              -Dsonar.projectKey=fastapi-app \
                              -Dsonar.sources=. \
                              -Dsonar.host.url=$SONAR_HOST_URL \
                              -Dsonar.login=$SONAR_AUTH_TOKEN \
                              -Dsonar.userHome=$WORKSPACE/.sonar
                        """
                    }
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
