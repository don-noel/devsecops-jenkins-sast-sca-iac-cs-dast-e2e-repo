pipeline {
  agent any

  tools { maven 'Maven' }

  environment {
    PYTHON_EXE = 'C:\\Users\\USER\\AppData\\Local\\Programs\\Python\\Python313\\python.exe'
    IMAGE_NAME = 'asecurityguru/testeb:latest'
    DAST_URL   = 'https://www.example.com'
    SNYK_ORG   = 'don-noel'

    // ✅ Pour que Jenkins trouve snyk.cmd installé via npm
    NPM_GLOBAL_BIN = 'C:\\Users\\USER\\AppData\\Roaming\\npm'
  }

  stages {

    stage('VerifyTools') {
      steps {
        bat """
          echo ===== WORKSPACE =====
          echo %WORKSPACE%

          echo ===== DOCKER =====
          docker --version

          echo ===== PATH (ADD NPM GLOBAL) =====
          set "PATH=%PATH%;%NPM_GLOBAL_BIN%"
          echo %PATH%

          echo ===== SNYK CLI =====
          where snyk
          snyk --version

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
          docker.build("${IMAGE_NAME}")
        }
        bat '''
          echo ===== IMAGE CHECK =====
          docker image inspect %IMAGE_NAME% >nul 2>nul && echo IMAGE_OK || (echo IMAGE_NOT_FOUND & exit /b 1)
        '''
      }
    }

    stage('SnykContainerScan') {
      steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
          bat """
            echo ===== SNYK CONTAINER SCAN (DOCKER) =====
            echo IMAGE_NAME=%IMAGE_NAME%
            echo SNYK_ORG=%SNYK_ORG%
    
            docker image inspect %IMAGE_NAME% >nul 2>nul && echo IMAGE_OK_BEFORE_SNYK || (echo IMAGE_MISSING_BEFORE_SNYK & exit /b 1)
    
            rem Lancer Snyk dans Docker (pas besoin de snyk/npx local)
            docker run --rm ^
              -e SNYK_TOKEN=%SNYK_TOKEN% ^
              snyk/snyk-cli:docker ^
              snyk container test %IMAGE_NAME% --org=%SNYK_ORG% --severity-threshold=high || exit /b 0
          """
        }
      }
    }

    stage('DAST_ZAP_Docker') {
      steps {
        bat '''
          echo ===== ZAP BASELINE =====
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
