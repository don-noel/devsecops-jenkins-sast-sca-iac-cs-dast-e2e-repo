pipeline {
  agent any

  tools {
    maven 'Maven'
  }

  environment {
    PYTHON_EXE = 'C:\\Users\\USER\\AppData\\Local\\Programs\\Python\\Python313\\python.exe'

    IMAGE_REPO = 'asecurityguru/testeb'
    IMAGE_TAG  = 'latest'
    IMAGE_NAME = "${IMAGE_REPO}:${IMAGE_TAG}"

    DAST_URL   = 'https://www.example.com'

    // Docker daemon Windows (utile si tu lances des conteneurs qui parlent au daemon)
    DOCKER_HOST = 'npipe:////./pipe/docker_engine'

    // Snyk org slug (pas l'UUID)
    SNYK_ORG = 'don-noel'
  }

  stages {

    stage('VerifyTools') {
      steps {
        bat """
          echo ===== WORKSPACE =====
          echo %WORKSPACE%

          echo ===== DOCKER =====
          docker --version

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
        script {
          // Build DIRECT avec le tag final (évite les confusions repo/tag)
          def img = docker.build("${IMAGE_NAME}")

          bat """
            echo ===== IMAGE BUILT =====
            docker images | findstr /I "${IMAGE_REPO}" || exit /b 1
            docker inspect ${IMAGE_NAME} >nul 2>nul && echo IMAGE_OK || (echo IMAGE_NOT_FOUND & exit /b 1)
          """
        }
      }
    }

    stage('SnykContainerScan') {
      steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
          bat """
            echo ===== SNYK CONTAINER SCAN =====
            docker inspect ${IMAGE_NAME} >nul 2>nul || (echo IMAGE_NOT_FOUND & exit /b 1)

            docker run --rm ^
              -e SNYK_TOKEN=%SNYK_TOKEN% ^
              -e DOCKER_HOST=npipe:////./pipe/docker_engine ^
              -v //./pipe/docker_engine://./pipe/docker_engine ^
              snyk/snyk:docker ^
              snyk container test ${IMAGE_NAME} --org=%SNYK_ORG% --severity-threshold=high
          """
        }
      }
    }

    stage('SnykSCA') {
      steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
          // Utilise snyk/snyk:docker (stable) au lieu de snyk/snyk:linux
          bat """
            echo ===== SNYK SCA (CODE/DEPENDENCIES) =====
            docker run --rm ^
              -e SNYK_TOKEN=%SNYK_TOKEN% ^
              -v "%WORKSPACE%:/app" ^
              -w /app ^
              snyk/snyk:docker ^
              snyk test --all-projects --org=%SNYK_ORG% --severity-threshold=high
          """
        }
      }
    }

    stage('DAST_ZAP_Docker') {
      steps {
        bat """
          echo ===== ZAP BASELINE =====
          docker run --rm ^
            -v "%WORKSPACE%:/zap/wrk" ^
            ghcr.io/zaproxy/zaproxy:stable ^
            zap-baseline.py -t "%DAST_URL%" -r zap-report.html

          echo [INFO] ZAP report saved to %WORKSPACE%\\zap-report.html
        """
      }
    }

    stage('Checkov') {
      steps {
        bat "\"%PYTHON_EXE%\" -m checkov.main -s -f main.tf"
      }
    }
  }
}
