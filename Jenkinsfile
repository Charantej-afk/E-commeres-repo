pipeline {
    agent any

    environment {
        // Credentials
        SONAR_TOKEN = credentials('SONAR_TOKEN')
        NEXUS_CRED  = credentials('NEXUS_CRED')
        DOCKER_HUB  = credentials('DOCKER_HUB')

        // App Variables
        APP_NAME = "ecommerce-app"
        VERSION  = "1.0.${BUILD_NUMBER}"

        SONAR_URL = "http://sonarqube:9000"
        NEXUS_URL = "http://nexus:8081"

        IMAGE = "charantej/ecommerce-app"
    }

    stages {

        /* ----------------------------------------------------------
         * Checkout Code
         * ---------------------------------------------------------- */
        stage('Checkout Code') {
            steps {
                git url: 'https://github.com/Charantej-afk/E-commeres-repo.git', branch: 'main'
            }
        }

        /* ----------------------------------------------------------
         * Maven Build
         * ---------------------------------------------------------- */
        stage('Maven Build') {
            steps {
                script {
                    mvnHome = tool 'Maven-3'
                }
                sh """
                    ${mvnHome}/bin/mvn clean package -DskipTests
                """
            }
        }

        /* ----------------------------------------------------------
         * SonarQube Scan
         * ---------------------------------------------------------- */
        stage('SonarQube Scan') {
            steps {
                script {
                    mvnHome = tool 'Maven-3'
                }
                withSonarQubeEnv('My SonarQube Server') {
                    sh """
                        ${mvnHome}/bin/mvn sonar:sonar \
                        -Dsonar.projectKey=ecommerce-app \
                        -Dsonar.host.url=${SONAR_URL} \
                        -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }

        /* ----------------------------------------------------------
         * SonarQube Quality Gate
         * ---------------------------------------------------------- */
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        /* ----------------------------------------------------------
         * Upload WAR to Nexus
         * ---------------------------------------------------------- */
        stage('Upload WAR to Nexus') {
            steps {
                sh """
                    curl -v -u ${NEXUS_CRED_USR}:${NEXUS_CRED_PSW} \
                    --upload-file target/${APP_NAME}-${VERSION}.war \
                    ${NEXUS_URL}/repository/maven-releases/com/ecommerce/${APP_NAME}/${VERSION}/${APP_NAME}-${VERSION}.war
                """
            }
        }

        /* ----------------------------------------------------------
         * Download WAR from Nexus
         * ---------------------------------------------------------- */
        stage('Download WAR from Nexus') {
            steps {
                sh "rm -f ${APP_NAME}.war || true"

                sh """
                    curl -u ${NEXUS_CRED_USR}:${NEXUS_CRED_PSW} \
                    -o ${APP_NAME}.war \
                    ${NEXUS_URL}/repository/maven-releases/com/ecommerce/${APP_NAME}/${VERSION}/${APP_NAME}-${VERSION}.war
                """
            }
        }

        /* ----------------------------------------------------------
         * Build Docker Image
         * ---------------------------------------------------------- */
        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${IMAGE}:${VERSION} .
                    docker tag ${IMAGE}:${VERSION} ${IMAGE}:latest
                """
            }
        }

        /* ----------------------------------------------------------
         * Push Docker Image
         * ---------------------------------------------------------- */
        stage('Push Docker Image') {
            steps {
                sh """
                    echo ${DOCKER_HUB} | docker login -u charantej --password-stdin
                    docker push ${IMAGE}:${VERSION}
                    docker push ${IMAGE}:latest
                """
            }
        }

        /* ----------------------------------------------------------
         * Deploy Docker Container
         * ---------------------------------------------------------- */
        stage('Deploy to Docker') {
            steps {
                sh """
                    docker rm -f ${APP_NAME} || true

                    docker run -d --name ${APP_NAME} \
                    -p 8080:8080 \
                    ${IMAGE}:latest
                """
            }
        }
    }

    post {
        success {
            echo "🎉 Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
