pipeline {
    agent any
    environment {
        SONAR_TOKEN    = credentials('SONAR_TOKEN')
        SNYK_TOKEN     = credentials('SNYK_TOKEN')
        PYTHON_EXE     = 'C:\\Users\\USER\\AppData\\Local\\Programs\\Python\\Python313\\python.exe'
        NPM_GLOBAL_BIN = 'C:\\Users\\USER\\AppData\\Roaming\\npm'
    }
    tools {
        maven 'Maven'
    }
    stages {

        stage('Checkout') {
            steps {
                git url: 'https://github.com/don-noel/devsecops-jenkins-sast-sca-iac-cs-dast-e2e-repo.git',
                    branch: 'main'
            }
        }

        stage('Build') {
            steps {
                bat 'mvn clean package -DskipTests'
            }
        }

        stage('SAST - SonarQube') {
            steps {
                bat """
                set JAVA_HOME=C:\\Program Files\\Eclipse Adoptium\\jdk-17.0.18.8-hotspot
                set PATH=%JAVA_HOME%\\bin;%PATH%
                mvn sonar:sonar ^
                -Dsonar.projectKey=EasyBuggy ^
                -Dsonar.host.url=http://localhost:9000 ^
                -Dsonar.login=%SONAR_TOKEN%
                """
            }
        }

        stage('SCA - Snyk') {
            steps {
                bat """
                set "PATH=%PATH%;%NPM_GLOBAL_BIN%"
                snyk auth %SNYK_TOKEN%
                snyk test --all-projects ^
                --severity-threshold=high ^
                --no-remote-repo-url || exit 0
                """
            }
        }

        stage('IaC - Checkov') {
            steps {
                bat '"%PYTHON_EXE%" -m checkov.main -d . --output cli || exit /b 0'
            }
        }

        stage('Container Security - Trivy') {
            steps {
                bat """
                docker build -t easybuggy-scan:latest . || exit 0
                docker run --rm ^
                -v /var/run/docker.sock:/var/run/docker.sock ^
                aquasec/trivy:latest image ^
                --severity HIGH,CRITICAL ^
                --format table ^
                easybuggy-scan:latest || exit 0
                """
            }
        }

        stage('Secrets Detection - Gitleaks') {
            steps {
                bat """
                docker run --rm ^
                -v "%WORKSPACE%:/path" ^
                zricethezav/gitleaks:latest detect ^
                --source="/path" ^
                --report-format=json ^
                --report-path="/path/gitleaks-report.json" ^
                --no-git || exit 0
                """
            }
        }

        stage('DAST - OWASP ZAP') {
            steps {
                bat """
                set JAVA_HOME=C:\\Program Files\\Eclipse Adoptium\\jdk-17.0.18.8-hotspot
                set PATH=%JAVA_HOME%\\bin;%PATH%
                "C:\\Program Files\\Eclipse Adoptium\\jdk-17.0.18.8-hotspot\\bin\\java.exe" ^
                -jar "C:\\Users\\USER\\DevSecOps\\ZAP\\ZAP_2.16.0\\zap-2.16.0.jar" ^
                -cmd -quickurl http://localhost:8080 ^
                -quickout "%WORKSPACE%\\zap_report.html" ^
                -port 8090 || exit 0
                """
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/target/*.war, **/zap_report.html, **/gitleaks-report.json',
                allowEmptyArchive: true
        }
        success {
            echo 'Pipeline DevSecOps Option A completed successfully!'
        }
        failure {
            echo 'Pipeline failed — check logs above.'
        }
    }
}
