pipeline {
    agent any

    environment {
        // Updated to match your deployment.yaml image name
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
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                    // Ensure your terraform output is exactly "ec2_public_ip"
                    sh 'terraform output -raw ec2_public_ip > ../ec2_ip.txt'
                }
            }
        }

        stage('Ansible - Setup Server') {
            steps {
                sh '''
                  EC2_IP=$(cat ec2_ip.txt)
                  echo "[app_server]" > ansible/inventory.ini
                  
                  # Updated path to the saikey.pem we just moved
                  echo "$EC2_IP ansible_user=ubuntu ansible_ssh_private_key_file=/var/lib/jenkins/.ssh/saikey.pem" >> ansible/inventory.ini

                  # Run playbook without manual intervention
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
                // Assuming your k8s folder is in the root of the repo
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