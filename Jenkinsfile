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
                // NOTE: Agar tumhari credential ID 'k3s-key' hai to 'ec2-user' ko 'k3s-key' se replace kar do
                sshagent(['ec2-user']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ${K3S_NODE} '
                        set -e
                        # Repo ensure / update
                        if [ ! -d /home/ec2-user/DeploymentWithK8 ]; then
                            cd /home/ec2-user
                            git clone ${GIT_REPO}
                        else
                            cd /home/ec2-user/DeploymentWithK8 && git pull
                        fi

                        # Ensure correct kubeconfig (K3s default)
                        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

                        # Apply Kubernetes Manifests with validation disabled to avoid OpenAPI timeout
                        kubectl apply --validate=false -f ${MANIFEST_DIR}/deployment.yaml
                        kubectl apply --validate=false -f ${MANIFEST_DIR}/service.yaml

                        # Rollout (force restart ensures nginx serves new content even with cached image)
                        kubectl rollout restart deployment/html-demo || true
                        kubectl rollout status deployment/html-demo --timeout=120s || true
                    '
                    """
                }
            }
        }
    }

    post {
        success {
            // ${K3S_NODE} = ec2-user@<IP>, isse sirf IP print karne ke liye split kar rahe hain
            script {
                def host = "${K3S_NODE}".split('@')[-1]
                echo "APP LIVE ON: http://${host}:30080"
            }
        }
        failure {
            echo "Deployment Failed!"
        }
    }
}
