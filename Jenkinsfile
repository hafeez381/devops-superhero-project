pipeline {
    agent any

    environment {
        REPO_URL = 'https://github.com/hafeez381/devops-superhero-project.git'
        BRANCH = 'main'
        SONAR_HOST_URL = 'http://<your-ec2-public-ip>:9000'  // Replace <your-ec2-public-ip> with your EC2 public IP
        SONARQUBE_PROJECT_KEY = 'devops-superhero-project'
        SONARQUBE_LOGIN = credentials('sonarqube-token')  // Ensure you have added SonarQube token in Jenkins credentials
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: "${BRANCH}"]], userRemoteConfigs: [[url: "${REPO_URL}"]]])
            }
        }
        stage('Install R and Dependencies') {
            steps {
                sh '''
                sudo apt-get update
                sudo apt-get install -y r-base
                sudo R -e "install.packages(c('ggplot2', 'mosaic', 'dplyr'), repos='http://cran.rstudio.com/')"
                '''
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh "sonar-scanner -Dsonar.projectKey=${SONARQUBE_PROJECT_KEY} -Dsonar.sources=. -Dsonar.host.url=${SONAR_HOST_URL} -Dsonar.login=${SONARQUBE_LOGIN}"
                }
            }
        }
        stage('Quality Gate') {
            steps {
                script {
                    timeout(time: 1, unit: 'HOURS') {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }
        stage('Run R Script') {
            steps {
                sh 'Rscript CI-Analysis.R'
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    def app = docker.build("your-docker-repo/devops-superhero-project:${env.BUILD_ID}")  // Replace your-docker-repo with your Docker repository name
                    app.push()
                }
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: '**/*.Rout', allowEmptyArchive: true
        }
    }
}
