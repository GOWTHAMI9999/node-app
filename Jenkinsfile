pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "gowthamireddy7/sai-node-app"
        DOCKER_TAG = "latest"
    }

    stages {

        stage('Clone Code') {
            steps {
                git branch: 'main', url: 'https://github.com/gowthami9999/node-app.git'
            }
        }

        stage('Terraform - Create EC2') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir('terraform') {
                        sh 'terraform init'
                        sh 'terraform apply -auto-approve'
                        sh 'terraform output -raw ec2_public_ip > ../ec2_ip.txt'
                    }
                }  // ← this was missing!
            }
        }

        stage('Ansible - Setup Server') {
            steps {
                sh '''
                  EC2_IP=$(cat ec2_ip.txt)
                  echo "[app_server]" > ansible/inventory.ini
                  echo "$EC2_IP ansible_user=ubuntu ansible_ssh_private_key_file=/var/lib/jenkins/.ssh/saikey.pem" >> ansible/inventory.ini
                  export ANSIBLE_HOST_KEY_CHECKING=False
                  ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS')]) {
                    sh "docker login -u $USER -p $PASS"
                    sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh 'kubectl apply -f k8s/deployment.yaml'
                sh 'kubectl apply -f k8s/service.yaml'
                sh 'kubectl rollout restart deployment/node-app'
            }
        }

    }

    post {
        success {
            echo '✅ Pipeline completed successfully! App is live!'
        }
        failure {
            echo '❌ Pipeline failed! Check logs above.'
        }
    }
}