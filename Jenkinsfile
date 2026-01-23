
pipeline {
  agent any

  options {
    timestamps()
  }

  environment {
    AWS_REGION = 'us-east-1'                 // <-- apni region
    ACCOUNT_ID = '222165755374'            // <-- 12 digit account id
    ECR_REPO  = 'deployment-with-k8'          // <-- repo name ECR me
    IMAGE     = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest"
    KUBECONFIG = "${WORKSPACE}/kubeconfig"
  }

  triggers {
    githubPush() // webhook se auto-trigger
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Prep kubeconfig') {
      steps {
        sh '''
          # Jenkins EC2 par ~/.kube/config me tumne K3s ka kubeconfig paste kiya hai na?
          # Usko workspace me copy kar rahe
          if [ -f ~/.kube/config ]; then
            cp ~/.kube/config "${KUBECONFIG}"
          else
            echo "ERROR: ~/.kube/config not found on Jenkins node"; exit 1
          fi
        '''
      }
    }

    stage('Login to ECR') {
      steps {
        sh '''
          aws --version
          aws ecr describe-repositories --repository-names ${ECR_REPO} --region ${AWS_REGION} >/dev/null 2>&1 || \
          aws ecr create-repository --repository-name ${ECR_REPO} --region ${AWS_REGION}

          aws ecr get-login-password --region ${AWS_REGION} | \
          docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
        '''
      }
    }

    stage('Build & Push Image') {
      steps {
        sh '''
          docker build -t ${IMAGE} .
          docker push ${IMAGE}
        '''
      }
    }

    stage('Deploy to K3s') {
      steps {
        sh '''
          export KUBECONFIG="${KUBECONFIG}"

          # Manifest me image placeholder replace
          sed -i "s#<ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/<ECR_REPO>:latest#${IMAGE}#g" k8s/deployment.yaml

          kubectl apply -f k8s/deployment.yaml
          kubectl apply -f k8s/service.yaml

          echo "Waiting for rollout..."
          kubectl rollout status deploy/demo-app --timeout=120s
          kubectl get pods -o wide
          kubectl get svc demo-app-svc -o wide
        '''
      }
    }
  }

  post {
    always {
      sh 'docker logout ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com || true'
    }
  }
}
