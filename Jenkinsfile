pipeline {
    agent any

    environment {
        REPO_URL = 'https://github.com/hafeez381/devops-superhero-project.git'
        BRANCH = 'main'
        SONAR_HOST_URL = 'http://localhost:9000'
        SONARQUBE_PROJECT_KEY = 'devops-superhero-project'
        SONARQUBE_LOGIN = credentials('sonarqube-token')
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
                apt-get update
                apt-get install -y r-base
                R -e "install.packages(c('ggplot2', 'mosaic', 'dplyr'), repos='http://cran.rstudio.com/')"
                '''
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') { // 
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
                    def app = docker.build("devops/devops-superhero-project:${env.BUILD_ID}")  
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
