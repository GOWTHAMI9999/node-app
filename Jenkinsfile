pipeline {
    agent any
    stages {
        stage("clone code") {
            steps {
                git branch: 'main', url: 'https://github.com/gowthami9999/node-app.git'
            
            }
        }
        stage('build docker image') {
            steps {
                sh 'docker build -t gowthamireddy7/node-app:latest .'

            }
        }
        stage ('push to docker hub') {
            steps {
                withCredentials([usernamePAssword(credentailsID: 'dockerhub-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh 'docker login -u $USER -p $PASS'
                    sh 'docker push gowthamireddy7/ndoe-app:latest'
                }
            }
        }
        stage('deplot to k8s') {
            steps{
                sh 'kubectl apply -f deployment.yaml'
                sh 'kubectl apply -f service.yaml'
                sh 'kubectl apply -f ingress.yaml'
            }

        }
    }
}