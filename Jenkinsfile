podTemplate(yaml: readTrusted('pod.yaml')) {
  node(POD_LABEL) {
    stage('Checkout Source') {
        
      git branch: 'main', url: 'https://github.com/maxpain62/eos-user-api.git'
      script {
            // Capture tag into a Groovy variable
            env.GIT_TAG = sh(
                script: "git tag --sort=-creatordate | head -1",
                returnStdout: true
            ).trim()
        }
        echo "${env.GIT_TAG}"
      }
    stage ('save codeartifact token') {
      container('aws-cli-helm') {
        sh """
          aws codeartifact get-authorization-token --domain eos --domain-owner 134448505602 --region ap-south-1 --query authorizationToken --output text > /root/.m2/token.txt
          aws ecr get-login-password --region ap-south-1 | helm registry login --username AWS --password-stdin 134448505602.dkr.ecr.ap-south-1.amazonaws.com
          """
        }
      }
    stage ('buils maven project') {
      container('maven') {
      script {
        try {
          sh '''
          cp settings.xml /root/.m2/settings.xml
          TOKEN=$(cat /root/.m2/token.txt)
          sed "s|replace_me|$TOKEN|" settings-template.xml > /root/.m2/settings.xml
          mvn clean deploy
          '''
          }
        catch(e) {
          echo "An error occurred: ${e}"
          }
        }
      }
    }
    stage ('build docker image') {
      container ('buildkit') {
        sh """
          ls -l && ls -l target/
          buildctl --addr tcp://buildkitd.devops-tools.svc.cluster.local:1234\
          --tlscacert /certs/ca.pem\
          --tlscert /certs/cert.pem\
          --tlskey /certs/key.pem\
          build --frontend dockerfile.v0\
          --opt filename=Dockerfile --local context=.\
          --local dockerfile=.\
          --output type=image,name=134448505602.dkr.ecr.ap-south-1.amazonaws.com/dev/eos-user-api:latest,push=true
          """
      }
    }
    stage ('package helm chart and push aws ecr repository') {
      container('aws-cli-helm') {
        sh """
          helm package eos-user-api-chart && ls -l
          helm push eos-user-api-0.1.0.tgz oci://134448505602.dkr.ecr.ap-south-1.amazonaws.com/dev/helm/
          aws ecr describe-images --repository-name dev/helm/eos-user-api --region ap-south-1
          """
      }
    }
  }
}
