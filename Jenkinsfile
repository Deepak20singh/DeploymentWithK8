pipeline {
  agent any

  environment {
    DOCKERHUB_REPO = 'deepaksingh20i1/myapp'
    KUBECONFIG = '/var/lib/jenkins/kubeconfig'
  }

  options {
    skipDefaultCheckout(true)
    timestamps()
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
        sh 'ls -la'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          set -e
          docker build -t myapp:latest .
        '''
      }
    }

    stage('Docker Login (Docker Hub)') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub',
                                         usernameVariable: 'USER',
                                         passwordVariable: 'PASS')]) {
          sh '''
            echo "$PASS" | docker login -u "$USER" --password-stdin
          '''
        }
      }
    }

    stage('Tag & Push to Docker Hub') {
      steps {
        sh '''
          set -e
          docker tag myapp:latest ${DOCKERHUB_REPO}:$BUILD_NUMBER
          docker tag myapp:latest ${DOCKERHUB_REPO}:latest
          docker push ${DOCKERHUB_REPO}:$BUILD_NUMBER
          docker push ${DOCKERHUB_REPO}:latest
        '''
      }
    }

    stage('Deploy to k3s') {
      steps {
        sh '''
          set -e

          echo "Updating image tag inside deployment.yaml..."
          sed -i "s|deepaksingh20i1/myapp:latest|deepaksingh20i1/myapp:${BUILD_NUMBER}|g" k8s/deployment.yaml

          kubectl --kubeconfig=$KUBECONFIG apply -f k8s/deployment.yaml
          kubectl --kubeconfig=$KUBECONFIG apply -f k8s/service.yaml

          echo "Waiting for rollout..."
          kubectl --kubeconfig=$KUBECONFIG rollout status deployment/myapp-deploy --timeout=120s

          echo "Services:"
          kubectl --kubeconfig=$KUBECONFIG get svc
        '''
      }
    }

  }

  post {
    success {
      echo "✅ Deployed successfully. Visit the app using NodePort."
    }
    always {
      sh 'docker image prune -f || true'
    }
  }
}
