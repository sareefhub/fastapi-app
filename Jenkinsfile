pipeline {
  agent {
    docker {
      image 'python:3.11'
      args '-u 0:0 -v /var/run/docker.sock:/var/run/docker.sock'
    }
  }

  options { timestamps() }

  stages {

    stage('Install Base Tooling') {
      steps {
        sh '''
          set -eux
          apt-get update
          DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            git wget unzip ca-certificates docker-cli default-jre-headless

          command -v git
          command -v docker
          docker --version
          java -version || true

          SCAN_VER=7.2.0.5079
          BASE_URL="https://binaries.sonarsource.com/Distribution/sonar-scanner-cli"

          CANDIDATES="
            sonar-scanner-${SCAN_VER}-linux-x64.zip
            sonar-scanner-${SCAN_VER}-linux.zip
            sonar-scanner-cli-${SCAN_VER}-linux-x64.zip
            sonar-scanner-cli-${SCAN_VER}-linux.zip
          "

          rm -f /tmp/sonar.zip || true
          for f in $CANDIDATES; do
            URL="${BASE_URL}/${f}"
            echo "Trying: $URL"
            if wget -q --spider "$URL"; then
              wget -qO /tmp/sonar.zip "$URL"
              break
            fi
          done

          test -s /tmp/sonar.zip || { echo "Failed to download SonarScanner ${SCAN_VER}"; exit 1; }

          unzip -q /tmp/sonar.zip -d /opt
          SCAN_HOME="$(find /opt -maxdepth 1 -type d -name 'sonar-scanner*' | head -n1)"
          ln -sf "$SCAN_HOME/bin/sonar-scanner" /usr/local/bin/sonar-scanner
          chmod +x /usr/local/bin/sonar-scanner
          sonar-scanner --version

          test -S /var/run/docker.sock || { echo "ERROR: /var/run/docker.sock not mounted"; exit 1; }
        '''
      }
    }

    stage('Checkout') {
      steps {
        git branch: 'main', url: 'https://github.com/sareefhub/fastapi-app.git'
      }
    }

    stage('Install Python Deps') {
      steps {
        sh '''
          set -eux
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install pytest pytest-cov
          test -f app/__init__.py || touch app/__init__.py
        '''
      }
    }

    stage('Run Tests & Coverage') {
      steps {
        sh '''
          set -eux
          export PYTHONPATH="$PWD"
          pytest -q --cov=app --cov-report=xml tests/
          ls -la
          test -f coverage.xml
          test -d app
          test -d tests
        '''
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('SonarQube') {
          withCredentials([string(credentialsId: 'FastApi', variable: 'SONAR_TOKEN')]) {
            sh '''
              set -eux
              sonar-scanner \
                -Dsonar.host.url="$SONAR_HOST_URL" \
                -Dsonar.login="$SONAR_TOKEN" \
                -Dsonar.projectBaseDir="$PWD" \
                -Dsonar.projectKey=TestFastApi \
                -Dsonar.projectName="TestFastApi" \
                -Dsonar.sources=app \
                -Dsonar.tests=tests \
                -Dsonar.python.version=3.11 \
                -Dsonar.python.coverage.reportPaths=coverage.xml \
                -Dsonar.sourceEncoding=UTF-8
            '''
          }
        }
      }
    }

    stage('Quality Gate') {
      steps {
        timeout(time: 10, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t fastapi-app:latest .'
      }
    }

    stage('Deploy Container') {
      steps {
        sh '''
          set -eux
          docker rm -f fastapi-app || true
          docker run -d --name fastapi-app -p 8000:8000 fastapi-app:latest
        '''
      }
    }
  }

  post { always { echo "Pipeline finished" } }
}
