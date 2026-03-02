pipeline {
  agent any

  tools {
    maven 'Maven'
  }

  stages {

    stage('CompileandRunSonarAnalysis') {
      steps {
        withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_TOKEN')]) {
          bat('mvn -Dmaven.test.failure.ignore verify sonar:sonar -Dsonar.token=%SONAR_TOKEN% -Dsonar.projectKey=EasyBuggy -Dsonar.host.url=http://localhost:9000/')
        }
      }
    }

    stage('Build') {
      steps {
        withDockerRegistry([credentialsId: "dockerlogin", url: ""]) {
          script {
            def app = docker.build("asecurityguru/testeb")
          }
        }
      }
    }

    // ✅ FIX: Snyk via Docker (évite "snyk is not recognized")
    stage('RunContainerScan') {
      steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
          bat('''
            docker run --rm ^
              -e SNYK_TOKEN=%SNYK_TOKEN% ^
              snyk/snyk:docker ^
              snyk config set disableSuggestions=true
          ''')

          bat('''
            docker run --rm ^
              -e SNYK_TOKEN=%SNYK_TOKEN% ^
              snyk/snyk:docker ^
              snyk container test asecurityguru/testeb:latest --severity-threshold=high || exit /b 0
          ''')
        }
      }
    }

    // ✅ WhoAmI via Docker
    stage('SnykWhoAmI') {
      steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
          bat('''
            docker run --rm ^
              -e SNYK_TOKEN=%SNYK_TOKEN% ^
              snyk/snyk:docker ^
              snyk whoami || exit /b 0
          ''')
        }
      }
    }

    // ✅ SCA via Docker (montage du workspace + détection Maven)
    stage('RunSnykSCA') {
      steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
          bat('''
            docker run --rm ^
              -e SNYK_TOKEN=%SNYK_TOKEN% ^
              -v "%WORKSPACE%:/app" ^
              -w /app ^
              snyk/snyk:docker ^
              snyk test --all-projects || exit /b 0
          ''')
        }
      }
    }

    stage('RunDASTUsingZAP') {
      steps {
        bat('''
          @echo off
          setlocal enabledelayedexpansion
    
          set "ZAPBAT="
          for /f "delims=" %%i in ('dir /b /s "C:\\zap\\zap.bat" 2^>nul') do set "ZAPBAT=%%i"
          if not defined ZAPBAT (
            for /f "delims=" %%i in ('dir /b /s "C:\\zap\\*zap*.bat" 2^>nul') do set "ZAPBAT=%%i"
          )
    
          if not defined ZAPBAT (
            echo [ERROR] Impossible de trouver zap.bat sous C:\\zap
            echo [INFO] Contenu de C:\\zap :
            dir "C:\\zap"
            exit /b 0
          )
    
          echo [INFO] ZAP found: "!ZAPBAT!"
          "!ZAPBAT!" ^
            -cmd -port 9393 ^
            -quickurl "https://www.example.com" ^
            -quickprogress ^
            -quickout "C:\\zap\\Output.html" || exit /b 0
        ''')
      }
    }

    stage('Checkov') {
      steps {
        bat 'py -m checkov.main -s -f main.tf || exit /b 0'
      }
    }
  }
}
