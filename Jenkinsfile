pipeline {
    agent {
        label 'INFRA'
    }

    environment {
        SERVER_ID = 'jfrog_java'
         MAVEN_OPTS = "--add-exports jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.comp=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.processing=ALL-UNNAMED"
    }

    triggers {
        pollSCM('* * * * *')
    }

    stages {
        stage('Git Checkout') {
            steps {
                git url: 'https://github.com/gandru123/spring-petclinic.git', branch: 'main'
            }
        }

        stage('Build Java Project') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar_id', variable: 'SONAR_TOKEN')]) {
                    withSonarQubeEnv('MYSONARQUBE') {
                        sh '''
                            mvn sonar:sonar \
                                -Dsonar.projectKey=gandru123_spring-petclinic \
                                -Dsonar.organization=jenkins-java \
                                -Dsonar.host.url=https://sonarcloud.io \
                                -Dsonar.login=$SONAR_TOKEN
                        '''
                    }
                }
            }
        }

       stage('Upload to JFrog Artifactory') {
        steps {
            script {
                def server = Artifactory.server('jfrog_java')  
                def buildInfo = Artifactory.newBuildInfo()
                
                server.upload(
                spec: """{
                    "files": [
                        {
                            "pattern": "target/*.jar",
                            "target": "java_spc-libs-release/gandru/spring-petclinic/"
                        }
                    ]
                }""",
                buildInfo: buildInfo
            )

            server.publishBuildInfo(buildInfo)
        }
    }
} 

       stage('Docker image build') {
        steps {
            sh 'docker image build -t java:1.1 .'
            sh 'docker image ls'
        }
       }
       stage('install trivy and scan image') {
        steps {
            sh """sudo apt-get install wget gnupg
                  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
                  echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
                  sudo apt-get update
                  sudo apt-get install trivy -y
                  trivy image mysql:9.2
              """

        }
       }
 
    }

    post {
        always {
            junit '**/target/surefire-reports/*.xml'
            archiveArtifacts artifacts: '**/target/*.jar'
        }
        success {
            echo 'Build completed successfully!'
        }
        failure {
            echo 'Build failed!'
        }
    }
}
