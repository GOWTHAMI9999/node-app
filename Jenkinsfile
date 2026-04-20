pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "gowthamireddy7/sai-node-app"
        DOCKER_TAG = "${BUILD_NUMBER}"
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
                    sh '''
                        cd terraform
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        terraform init
                        terraform apply -auto-approve
                        terraform output -raw ec2_public_ip > ../ec2_ip.txt
                        echo "=== EC2 IP ==="
                        cat ../ec2_ip.txt
                    '''
                }
            }
        }

        stage('Ansible - Setup Server') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'ec2-key',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {
                    sh '''
                        EC2_IP=$(cat ec2_ip.txt)
                        echo "EC2 IP: $EC2_IP"
                        echo "SSH KEY PATH: $SSH_KEY"
                        echo "SSH USER: $SSH_USER"
                        echo "[app_server]" > ansible/inventory.ini
                        echo "$EC2_IP ansible_user=$SSH_USER" >> ansible/inventory.ini
                        export ANSIBLE_HOST_KEY_CHECKING=False
                        sleep 90
                        ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --private-key $SSH_KEY
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS')]) {
                    sh "echo $PASS | docker login -u $USER --password-stdin"
                    sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    sh "docker push ${DOCKER_IMAGE}:latest"
                }
            }
        }

        stage('Update Manifest') {
            steps {
                sh """
                    sed -i "s|image: gowthamireddy7/sai-node-app:.*|image: gowthamireddy7/sai-node-app:${BUILD_NUMBER}|g" deployment.yaml
                    git config user.email "jenkins@pipeline.com"
                    git config user.name "Jenkins"
                    git add deployment.yaml
                    git commit -m "Update image tag to ${BUILD_NUMBER}"
                    git push https://<GITHUB-TOKEN>@github.com/gowthami9999/node-app.git main
                """
            }
        }

        stage('Setup ArgoCD App') {
            steps {
                sh '''
                    EC2_IP=$(cat ec2_ip.txt)
                    ssh -i /var/lib/jenkins/.ssh/saikey.pem \
                        -o StrictHostKeyChecking=no \
                        ubuntu@$EC2_IP \
                        "kubectl apply -f /home/ubuntu/argocd-app.yaml"
                '''
            }
        }

    }

    post {
        success {
            echo '✅ Pipeline completed! ArgoCD will deploy the app!'
        }
        failure {
            echo '❌ Pipeline failed! Check logs above.'
        }
    }
}