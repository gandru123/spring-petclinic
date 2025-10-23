pipeline {
    agent {
        label 'INFRA'
    }

    environment {
        SERVER_ID = 'jfrog_java'
        AWS_REGION = 'ap-south-1'
        ECR_REPO = '753916464885.dkr.ecr.ap-south-1.amazonaws.com/pipelinespring'
        MAVEN_HOME = '/opt/apache-maven-3.9.11'
        PATH = "$PATH:$MAVEN_HOME/bin"
        MAVEN_OPTS = "--add-exports jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED \
                      --add-exports jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED \
                      --add-exports jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED \
                      --add-exports jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED \
                      --add-exports jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED \
                      --add-exports jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED \
                      --add-exports jdk.compiler/com.sun.tools.javac.comp=ALL-UNNAMED \
                      --add-exports jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED \
                      --add-exports jdk.compiler/com.sun.tools.javac.processing=ALL-UNNAMED"
    }

    triggers {
        pollSCM('* * * * *')
    }

    stages {
        stage('Build Java Project') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'sonar_id', variable: 'SONAR_TOKEN')]) {
                        withSonarQubeEnv('MYSONARQUBE') {
                            def result = sh(
                                script: """
                                    mvn sonar:sonar \
                                        -Dsonar.projectKey=gandru123_spring-petclinic \
                                        -Dsonar.organization=jenkins-java \
                                        -Dsonar.host.url=https://sonarcloud.io \
                                        -Dsonar.login=${SONAR_TOKEN}
                                """,
                                returnStatus: true
                            )
                            if (result != 0) {
                                echo '⚠️ SonarQube analysis failed (possibly SonarCloud outage). Continuing pipeline...'
                            }
                        }
                    }
                }
            }
        }

        stage('Upload to JFrog Artifactory') {
            steps {
                script {
                    def server = Artifactory.server(env.SERVER_ID)
                    def buildInfo = Artifactory.newBuildInfo()
                    server.upload(
                        spec: """{
                            "files": [{
                                "pattern": "target/*.jar",
                                "target": "java_spc-libs-release/gandru/spring-petclinic/"
                            }]
                        }""",
                        buildInfo: buildInfo
                    )
                    server.publishBuildInfo(buildInfo)
                }
            }
        }

        stage('Build & Push Docker Image to ECR') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws_id']]) {
                        def imageTag = "${ECR_REPO}:latest"
                        sh """
                            aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin ${ECR_REPO}
                        """
                        sh "docker build -t ${imageTag} ."
                        sh "docker push ${imageTag}"
                    }
                }
            }
        }

        stage('Scan Docker Image with Trivy') {
            steps {
                sh "trivy image ${ECR_REPO}:latest"
            }
        }
    }

    post {
        always {
            script {
                if (fileExists('target/surefire-reports')) {
                    junit '**/target/surefire-reports/*.xml'
                } else {
                    echo 'No JUnit reports found — skipping test report publishing.'
                }
            }
            archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true
        }
        success {
            echo '✅ Build completed successfully!'
        }
        failure {
            echo '❌ Build failed!'
        }
    }
}
