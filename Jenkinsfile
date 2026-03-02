pipeline {
  agent any

  tools {
    maven 'Maven'
  }

  environment {
    // ✅ Mets ici ton chemin EXACT python (celui qui marche chez toi)
    PYTHON_EXE = 'C:\\Users\\USER\\AppData\\Local\\Programs\\Python\\Python313\\python.exe'

    // Nom image docker
    IMAGE_NAME = 'asecurityguru/testeb:latest'

    // URL de test pour ZAP
    DAST_URL = 'https://www.example.com'
  }

  stages {

    stage('CompileandRunSonarAnalysis') {
      steps {
        withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_TOKEN')]) {
          bat('mvn -Dmaven.test.failure.ignore verify sonar:sonar -Dsonar.token=%SONAR_TOKEN% -Dsonar.projectKey=EasyBuggy -Dsonar.host.url=http://localhost:9000/')
        }
      }
    }

    stage('BuildDockerImage') {
      steps {
        withDockerRegistry([credentialsId: "dockerlogin", url: ""]) {
          script {
            def app = docker.build("asecurityguru/testeb:latest")
          }
        }
      }
    }

    // ✅ Container Scan (Snyk) - accès à l'image locale (Windows Docker Engine pipe)
    stage('SnykContainerScan') {
      steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {

          // Optionnel: couper suggestions
          bat('''
            docker run --rm ^
              -e SNYK_TOKEN=%SNYK_TOKEN% ^
              snyk/snyk:docker ^
              snyk config set disableSuggestions=true
          ''')

          // ✅ IMPORTANT: monter le docker engine pipe pour que Snyk voie les images locales
          bat('''
            docker run --rm ^
              -e SNYK_TOKEN=%SNYK_TOKEN% ^
              -v //./pipe/docker_engine://./pipe/docker_engine ^
              snyk/snyk:docker ^
              snyk container test %IMAGE_NAME% --severity-threshold=high || exit /b 0
          ''')
        }
      }
    }

    // ✅ WhoAmI (si tu veux garder)
    stage('SnykWhoAmI') {
      steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
          bat('''
            docker run --rm ^
              -e SNYK_TOKEN=%SNYK_TOKEN% ^
              snyk/snyk:docker ^
              snyk --experimental whoami || exit /b 0
          ''')
        }
      }
    }

    // ✅ SCA (Java/Maven) : utilise une image qui a Maven + Java pour éviter exit code -2
    stage('SnykSCA') {
      steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
          bat('''
            docker run --rm ^
              -e SNYK_TOKEN=%SNYK_TOKEN% ^
              -v "%WORKSPACE%:/app" ^
              -w /app ^
              maven:3.9-eclipse-temurin-17 ^
              bash -lc "mvn -q -DskipTests dependency:tree && curl -sSL https://static.snyk.io/cli/latest/snyk-linux -o /usr/local/bin/snyk && chmod +x /usr/local/bin/snyk && snyk test --all-projects || true"
          ''')
        }
      }
    }

    // ✅ DAST ZAP via Docker (plus besoin de C:\zap)
    stage('DAST_ZAP_Docker') {
      steps {
        bat('''
          docker run --rm ^
            -v "%WORKSPACE%:/zap/wrk" ^
            ghcr.io/zaproxy/zaproxy:stable ^
            zap-baseline.py -t "%DAST_URL%" -r zap-report.html || exit /b 0

          echo [INFO] ZAP report saved to %WORKSPACE%\\zap-report.html
        ''')
      }
    }

    // ✅ Checkov : Jenkins ne reconnait pas "py" => appeler python.exe direct
    stage('Checkov') {
      steps {
        bat('"%PYTHON_EXE%" -m checkov.main -s -f main.tf || exit /b 0')
      }
    }
  }
}
