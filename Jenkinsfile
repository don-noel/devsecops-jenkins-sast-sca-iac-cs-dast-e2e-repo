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

    stage('RunContainerScan') {
      steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
          script {
            withEnv(["SNYK_TOKEN=${SNYK_TOKEN}"]) {
              bat('snyk config set disableSuggestions=true')
              bat('snyk container test asecurityguru/testeb --file=Dockerfile || exit /b 0')
            }
          }
        }
      }
    }

    stage('SnykWhoAmI') {
      steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
          withEnv(["SNYK_TOKEN=${SNYK_TOKEN}"]) {
            bat('snyk whoami || exit /b 0')
          }
        }
      }
    }

    stage('RunSnykSCA') {
      steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
          withEnv(["SNYK_TOKEN=${SNYK_TOKEN}"]) {
            bat('mvn snyk:test -fn || exit /b 0')
          }
        }
      }
    }

    stage('RunDASTUsingZAP') {
      steps {
        bat("C:\\zap\\ZAP_2.12.0_Crossplatform\\ZAP_2.12.0\\zap.sh -port 9393 -cmd -quickurl https://www.example.com -quickprogress -quickout C:\\zap\\ZAP_2.12.0_Crossplatform\\ZAP_2.12.0\\Output.html")
      }
    }

    stage('checkov') {
      steps {
        bat("checkov -s -f main.tf")
      }
    }
  }
}
