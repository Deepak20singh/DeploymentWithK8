
pipeline {
  agent any

  environment {
    AWS_REGION = 'us-east-1'
    AWS_ACCOUNT = '471112576461'      // apna account ID daalna
    ECR_REPO = 'static-site'
    IMAGE_TAG = 'latest'
    ECR_URI = "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build Docker Image') {
      steps {
        sh "docker build -t ${ECR_REPO}:${IMAGE_TAG} ."
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

    stage('Tag & Push') {
      steps {
        sh """
          docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_URI}
          docker push ${ECR_URI}
        """
      }
    }

    stage('Create Pull Secret') {
      steps {
        sh """
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
          sed -i 's|<AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/static-site:latest|${ECR_URI}|' k8s/deployment.yaml

          kubectl apply -f k8s/deployment.yaml
          kubectl apply -f k8s/service.yaml

          kubectl rollout status deployment/static-site --timeout=120s
        """
      }
    }
  }
}
