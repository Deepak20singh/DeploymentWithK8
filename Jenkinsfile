pipeline {
    agent any

    environment {
        REGISTRY = "3.236.200.249:5000"
        IMAGE_NAME = "deepak-app"
        IMAGE_TAG = "latest"
        K8S_DIR = "k8s"
    }

    options { timestamps(); ansiColor('xterm') }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Deepak20singh/DeploymentWithK8.git'
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                  docker version || true
                  echo "[BUILD] Building image..."
                  docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                '''
            }
        }

        stage('Tag Image') {
            steps {
                sh '''
                  echo "[TAG] Tagging image for local registry..."
                  docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Push to Local Registry') {
            steps {
                sh '''
                  echo "[PUSH] Pushing image to local registry..."
                  docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Kubernetes Deploy') {
            steps {
                sh '''
                  echo "[K8S] Applying manifests..."
                  grep -q "${REGISTRY}/${IMAGE_NAME}" ${K8S_DIR}/deployment.yaml || {
                      echo "ERROR: deployment.yaml image must be ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}";
                      exit 1;
                  }
                  kubectl apply -f ${K8S_DIR}/deployment.yaml
                  kubectl apply -f ${K8S_DIR}/service.yaml
                  kubectl rollout status deploy/deepak-app --timeout=120s || true
                  kubectl get pods -l app=deepak-app -o wide
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Success! Open: http://<K3S_PUBLIC_IP>:30001"
        }
        failure {
            echo "❌ Failed. Check stage logs."
        }
    }
}
