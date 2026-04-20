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
                    sh '''
                        echo "=== Checking workspace files ==="
                        ls -la
                        echo "=== Moving into terraform folder ==="
                        cd terraform
                        echo "=== Terraform files ==="
                        ls -la
                        echo "=== Setting AWS credentials ==="
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        echo "=== Running Terraform Init ==="
                        terraform init
                        echo "=== Running Terraform Apply ==="
                        terraform apply -auto-approve
                        echo "=== Getting EC2 IP ==="
                        terraform output -raw ec2_public_ip > ../ec2_ip.txt
                        echo "=== EC2 IP is ==="
                        cat ../ec2_ip.txt
                    '''
                }
            }
        }

        stage('Ansible - Setup Server') {
            steps {
                sh '''
                    echo "=== Reading EC2 IP ==="
                    EC2_IP=$(cat ec2_ip.txt)
                    echo "EC2 IP: $EC2_IP"
                    echo "[app_server]" > ansible/inventory.ini
                    echo "$EC2_IP ansible_user=ubuntu ansible_ssh_private_key_file=$SSH_KEY" >> ansible/inventory.ini
                    echo "=== Inventory file ==="
                    cat ansible/inventory.ini
                    export ANSIBLE_HOST_KEY_CHECKING=False
                    echo "=== Waiting 90 seconds for EC2 to fully boot ==="
                    sleep 90
                    echo "=== Running Ansible ==="
                    ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
                        
                        
                    
                    
                       
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
                sh 'kubectl apply -f deployment.yaml'
                sh 'kubectl apply -f service.yaml'
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
//test