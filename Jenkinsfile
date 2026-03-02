pipeline {
  agent any

  tools {
    maven 'Maven'
  }

  environment {
    PYTHON_EXE = 'C:\\Users\\USER\\AppData\\Local\\Programs\\Python\\Python313\\python.exe'
    IMAGE_NAME = 'asecurityguru/testeb:latest'
    DAST_URL   = 'https://www.example.com'

    // IMPORTANT pour Docker daemon Windows depuis un conteneur
    DOCKER_HOST = 'npipe:////./pipe/docker_engine'
  }

  stages {

    stage('VerifyTools') {
      steps {
        bat """
          echo ===== WORKSPACE =====
          echo %WORKSPACE%
          echo ===== DOCKER =====
          docker --version
          docker images | findstr /i testeb || ver >nul
          echo ===== PYTHON =====
          "%PYTHON_EXE%" --version
          "%PYTHON_EXE%" -m checkov.main -v
          echo ===== FILES =====
          dir
          if exist main.tf (echo main.tf OK) else (echo main.tf NOT FOUND)
        """
      }
    }

    stage('CompileandRunSonarAnalysis') {
      steps {
        withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_TOKEN')]) {
          bat 'mvn -Dmaven.test.failure.ignore verify sonar:sonar -Dsonar.token=%SONAR_TOKEN% -Dsonar.projectKey=EasyBuggy -Dsonar.host.url=http://localhost:9000/'
        }
      }
    }

    stage('BuildDockerImage') {
      steps {
        withDockerRegistry([credentialsId: "dockerlogin", url: ""]) {
          script {
            docker.build("${IMAGE_NAME}")
          }
        }
      }
    }

    stage('SnykContainerScan') {
      steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {

          // (optionnel) config
          bat '''
            docker run --rm ^
              -e SNYK_TOKEN=%SNYK_TOKEN% ^
              snyk/snyk:docker ^
              snyk config set disableSuggestions=true
          '''

          // Container scan - accès Docker Windows via npipe + montage pipe
          bat '''
            docker run --rm ^
              -e SNYK_TOKEN=%SNYK_TOKEN% ^
              -e DOCKER_HOST=npipe:////./pipe/docker_engine ^
              -v //./pipe/docker_engine://./pipe/docker_engine ^
              snyk/snyk:docker ^
              snyk container test %IMAGE_NAME% --severity-threshold=high || exit /b 0
          '''
        }
      }
    }

    stage('SnykSCA') {
      steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
          bat '''
            docker run --rm ^
              -e SNYK_TOKEN=%SNYK_TOKEN% ^
              -v "%WORKSPACE%:/app" ^
              -w /app ^
              maven:3.9-eclipse-temurin-17 ^
              bash -lc "mvn -q -DskipTests dependency:tree || true; curl -sSL https://static.snyk.io/cli/latest/snyk-linux -o /usr/local/bin/snyk && chmod +x /usr/local/bin/snyk && snyk test --all-projects --org=YOUR_SNYK_ORG_SLUG || true"
          '''
        }
      }
    }

    stage('DAST_ZAP_Docker') {
      steps {
        bat '''
          docker run --rm ^
            -v "%WORKSPACE%:/zap/wrk" ^
            ghcr.io/zaproxy/zaproxy:stable ^
            zap-baseline.py -t "%DAST_URL%" -r zap-report.html || exit /b 0

          echo [INFO] ZAP report saved to %WORKSPACE%\\zap-report.html
        '''
      }
    }

    stage('Checkov') {
      steps {
        bat '"%PYTHON_EXE%" -m checkov.main -s -f main.tf || exit /b 0'
      }
    }
  }
}
