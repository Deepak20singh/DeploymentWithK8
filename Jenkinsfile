pipeline {
    agent any

    environment {
        IMAGE = "deepaksingh20i1/html-demo:${BUILD_NUMBER}"
        GIT_REPO = "https://github.com/Deepak20singh/DeploymentWithK8.git"
        K3S_NODE = "ec2-user@18.232.140.179"
        MANIFEST_DIR = "k8s"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: "${GIT_REPO}"
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh 'echo $PASS | docker login -u $USER --password-stdin'
                }
            }
        }

        stage('Build Docker Image (No Cache)') {
            steps {
                sh 'docker build --no-cache -t ${IMAGE} .'
            }
        }

        stage('Push Image to DockerHub') {
            steps {
                sh 'docker push ${IMAGE}'
            }
        }

        stage('Update Deployment YAML Locally') {
            steps {
                sh "sed -i 's#image:.*#image: ${IMAGE}#g' k8s/deployment.yaml"
            }
        }

        stage('Commit Updated Manifest to GitHub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'github-creds',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_PASS'
                )]) {
                    sh """
                        git config user.email "jenkins@local"
                        git config user.name "Jenkins"

                        git add k8s/deployment.yaml
                        git commit -m "Update image tag to ${BUILD_NUMBER}" || true

                        git push https://${GIT_USER}:${GIT_PASS}@github.com/Deepak20singh/DeploymentWithK8.git main
                    """
                }
            }
        }

        stage('Deploy to K3s') {
            steps {
                sshagent(['k3s-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ${K3S_NODE} '
                        cd /home/ec2-user/DeploymentWithK8 && git pull

                        kubectl apply -f /home/ec2-user/DeploymentWithK8/k8s/deployment.yaml
                        kubectl apply -f /home/ec2-user/DeploymentWithK8/k8s/service.yaml

                        kubectl rollout status deployment/html-demo --timeout=60s || true
                    '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "APP LIVE ON: http://${K3S_NODE}:30080"
        }
        failure {
            echo "Deployment Failed!"
        }
    }
}
