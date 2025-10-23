pipeline {
    agent {
        label 'INFRA'
    }

    environment {
        SERVER_ID = 'jfrog_java'
        AWS_REGION = 'ap-south-1'
        ECR_REPO = '753916464885.dkr.ecr.ap-south-1.amazonaws.com/pipelinespring'
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


        stage('GIT CHECKOUT') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: '*/main']], 
                    userRemoteConfigs: [[url: 'https://github.com/gandru123/spring-petclinic.git']]]) 
            }
        }

        stage('Build Java Project') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'sonar_id', variable: 'SONAR_TOKEN')]) {
                        withSonarQubeEnv('MYSONARQUBE') {
                            sh '''
                                mvn clean package sonar:sonar \
                                    -Dsonar.projectKey=gandru123_spring-petclinic \
                                    -Dsonar.organization=jenkins-java \
                                    -Dsonar.host.url=https://sonarcloud.io \
                                    -Dsonar.login=${SONAR_TOKEN} \
                                    -Dtrivy.skip=true
                            '''
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
            def imageTag = "${ECR_REPO}:${BUILD_NUMBER}"

            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws_id']]) {
                sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}"
                sh "docker build -f Dockerfile -t ${imageTag} ."
                sh "docker push ${imageTag}"
                }
            }
        }
    }


        stage('Scan Docker Image with Trivy') {
            steps {
                sh '''
                    echo "Running Trivy vulnerability scan..."
                    trivy image ${ECR_REPO}:${BUILD_NUMBER}
                '''
            }
        }
    }

    post {
        always {
            echo 'Archiving build artifacts and test results...'
            archiveArtifacts allowEmptyArchive: true, artifacts: '**/target/*.jar'
            junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
        }
        success {
            echo 'Pipeline executed successfully.'
        }
        failure {
            echo 'Pipeline failed. Please check the logs for errors.'
        }
    }
}
