pipeline {
    agent any

    environment {
        IMAGE = "deepaksingh20i1/html-demo:latest"
        GIT_REPO = "https://github.com/Deepak20singh/DeploymentWithK8.git"
        K3S_NODE = "ec2-user@18.232.140.179"
        MANIFEST_DIR = "/home/ec2-user/DeploymentWithK8/k8s"
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

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${IMAGE} .'
            }
        }

        stage('Push Image to DockerHub') {
            steps {
                sh 'docker push ${IMAGE}'
            }
        }

        stage('Deploy to K3s') {
            steps {
                sshagent(['k3s-key']) {   // ← FIXED: Correct Credential ID
                    sh """
                    ssh -o StrictHostKeyChecking=no ${K3S_NODE} '
                        # Clone repo if not exists
                        if [ ! -d /home/ec2-user/DeploymentWithK8 ]; then
                            cd /home/ec2-user
                            git clone ${GIT_REPO}
                        else
                            cd /home/ec2-user/DeploymentWithK8 && git pull
                        fi

                        # Apply Kubernetes Manifests
                        kubectl apply -f ${MANIFEST_DIR}/deployment.yaml
                        kubectl apply -f ${MANIFEST_DIR}/service.yaml

                        # Rollout Check
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
