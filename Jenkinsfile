pipeline {
  agent any

  environment {
    DOCKERHUB_USER = "deepaksingh20i1"
    IMAGE_NAME     = "demo-app"
    BUILD_VER      = "${env.BUILD_NUMBER}"
    K3S_HOST       = "ec2-user@98.81.60.59"   // agar Ubuntu hai to ubuntu@IP
  }

  options { timestamps() }

  stages {
    stage('Checkout') {
      steps {
        git 'https://github.com/Deepak20singh/DeploymentWithK8.git'
      }
    }

    stage('Docker Build') {
      steps {
        sh 'docker --version'
        sh 'docker build -t ${IMAGE_NAME}:latest --build-arg BUILD_VERSION=${BUILD_VER} .'
      }
    }

    stage('Tag for Docker Hub') {
      steps {
        sh 'docker tag ${IMAGE_NAME}:latest ${DOCKERHUB_USER}/${IMAGE_NAME}:latest'
        sh 'docker tag ${IMAGE_NAME}:latest ${DOCKERHUB_USER}/${IMAGE_NAME}:${BUILD_VER}'
      }
    }

    stage('Login & Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                                          usernameVariable: 'DH_USER',
                                          passwordVariable: 'DH_PASS')]) {
          sh 'echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin'
        }
        sh 'docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:latest'
        sh 'docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:${BUILD_VER}'
      }
    }

    stage('Deploy to k3s (Rolling Update)') {
      steps {
        // Jenkins EC2 -> k3s EC2 SSH key-based login required
        sh """
          ssh -o StrictHostKeyChecking=no ${K3S_HOST} \
            'sudo k3s kubectl set image deployment/demo-deploy demo-container=${DOCKERHUB_USER}/${IMAGE_NAME}:latest --record && \
             sudo k3s kubectl rollout status deployment/demo-deploy --timeout=120s'
        """
      }
    }
  }

  post {
    always {
      sh 'docker image prune -f || true'
    }
  }
}
