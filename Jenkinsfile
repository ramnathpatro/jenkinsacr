node {
    dir('demo') {
        // Mark the code checkout 'stage'....
        stage('Checkout from GitHub') {
            git url: 'https://github.com/jldeen/swampup2017'
        }

        // Build and Deploy to Artifactory 'stage'... 
        stage('Build and Push to Azure Container Registry') {
                def tagName='acrjdtest.azurecr.io/node-demo:'+env.BUILD_NUMBER
                docker.build(tagName)
                withCredentials([usernamePassword(credentialsId: 'acr_credentials', passwordVariable: 'acr_pw', usernameVariable: 'acr_un')]) {
                    sh 'docker login acrjdtest.azurecr.io -u ${acr_un} -p ${acr_pw}'
                    sh 'docker push '+tagName
                }
        }

        stage('Open SSH Tunnel to Azure Swarm Cluster') {
                // Open SSH Tunnel to ACS Cluster
                sshagent(['acs_key']) {
                    sh 'ssh -fNL 2375:localhost:2375 -p 2200 jldeen@dnsprefix.datacenter.cloudapp.azure.com -o StrictHostKeyChecking=no -o ServerAliveInterval=240 && echo "ACS SSH Tunnel successfully opened..."'
                }
        }

        // Pull, Run, and Test on ACS 'stage'... 
        stage('ACS Docker Pull and Run') {
        // Set env variable for stage for SSH ACS Tunnel
            withCredentials([usernamePassword(credentialsId: 'acr_credentials', passwordVariable: 'acr_pw', usernameVariable: 'acr_un')]) {
                env.DOCKER_HOST=':2375'
                sh 'echo "DOCKER_HOST is $DOCKER_HOST"'
                sh 'docker info'
                def imageName='acrjdtest.azurecr.io/node-demo'+':'+env.BUILD_NUMBER
                sh "docker login acrjdtest.azurecr.io -u ${acr_un} -p ${acr_pw}"
                sh "docker pull ${imageName}"
                sh "docker run -d --name node-demo -p 80:8080 ${imageName}"
            }
        }
    }
}