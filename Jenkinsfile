
pipeline {
  agent any

  environment {
    AWS_REGION = 'ap-south-1'            // apni region daalo
    AWS_ACCOUNT = '<AWS_ACCOUNT_ID>'     // apna account id
    ECR_REPO = 'static-site'
    IMAGE_TAG = 'latest'
    ECR_URI = "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"
    KUBECONFIG = "${env.WORKSPACE}/.kubeconfig"  // optional if Jenkins node par global set nahi
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build Docker Image') {
      steps {
        sh """
          docker build -t ${ECR_REPO}:${IMAGE_TAG} .
        """
      }
    }

    stage('Login to ECR') {
      steps {
        sh """
          aws ecr describe-repositories --repository-names ${ECR_REPO} --region ${AWS_REGION} \
            || aws ecr create-repository --repository-name ${ECR_REPO} --region ${AWS_REGION}

          aws ecr get-login-password --region ${AWS_REGION} \
            | docker login --username AWS --password-stdin ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com
        """
      }
    }

    stage('Tag & Push Image') {
      steps {
        sh """
          docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_URI}
          docker push ${ECR_URI}
        """
      }
    }

    stage('Kubeconfig (if needed)') {
      steps {
        // If Jenkins node has IAM creds, ye kubeconfig generate karega.
        sh """
          aws eks update-kubeconfig --name DONT_USE_EKS --region ${AWS_REGION} || true
        """
        // Hum kubeadm use kar rahe hain; kubeconfig already Jenkins node par ho to skip.
        // Agar master node ≠ Jenkins node hai, to master se ~/.kube/config copy karke Jenkins me store credentials me use karo.
      }
    }

    stage('Create/Update ImagePullSecret') {
      steps {
        sh """
          # ECR dockerconfig as secret (works for kubeadm clusters too)
          kubectl delete secret ecr-creds --ignore-not-found
          aws ecr get-login-password --region ${AWS_REGION} | \
            kubectl create secret docker-registry ecr-creds \
              --docker-server=${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com \
              --docker-username=AWS \
              --docker-password-stdin
        """
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        sh """
          # Replace image in deployment manifest on the fly
          sed -i 's|<AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/static-site:latest|${ECR_URI}|' k8s/deployment.yaml

          kubectl apply -f k8s/deployment.yaml
          kubectl apply -f k8s/service.yaml

          # Wait for rollout
          kubectl rollout status deploy/static-site --timeout=120s
        """
      }
    }
  }

  post {
    success {
      echo "Deployed successfully! Hit NodeIP:30080 to view."
    }
    failure {
      echo "Deployment failed. Check logs."
      sh "kubectl get pods -o wide || true"
    }
  }
}
