pipeline {
    agent any
    
    tools {
        jdk 'jdk17'
        gradle 'G3'
    }
    environment { 
        // jenkins에 등록해 놓은 docker hub credentials 이름
        DOCKERHUB_CREDENTIALS = credentials('dockerCredentials') 
        REGION = 'ap-northeast-2'
        AWS_CREDENTIAL_NAME = 'AWSCredentials'
    }

    stages {
        stage('Git Clone') {
            steps {
                echo 'Git Clone'
                git url: 'https://github.com/Hyunkyoungkang/busan-tour-aws.git',
                branch: 'main', credentialsId: 'gitToken'
            }
            post {
                success {
                    echo 'Success git clone step'
                }
                failure {
                    echo 'Fail git clone step'
                }
            }
        }
        
        stage('gradle Build') {
            steps {
                echo 'gradle Build'
                 sh """
                     cd ./project_DiB
                     chmod +x ./gradlew
                     ./gradle build -x test
                 """
           }
        }
        
        stage('Docker Image Build') {
            steps {
                echo 'Docker Image build'                
                dir("${env.WORKSPACE}") {
                    sh """
                       docker build -t hyunkyoungkang/busan-tour-aws:$BUILD_NUMBER .
                       docker tag hyunkyoungkang/busan-tour-aws:$BUILD_NUMBER hyunkyoungkang/busan-tour-aws:latest
                    """
                }
            }
        }

        stage('Docker Login') {
            steps {
                // docker hub 로그인
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
            }
        }
        stage('Docker Image Push') {
            steps {
                echo 'Docker Image Push'  
                sh "docker push hyunkyoungkang/busan-tour-aws:latest"  // docker push
            }
        }
        stage('Cleaning up') { 
              steps { 
              // docker image 제거
              echo 'Cleaning up unused Docker images on Jenkins server'
              sh """
                  docker rmi hyunkyoungkang/busan-tour-aws:$BUILD_NUMBER
                  docker rmi hyunkyoungkang/busan-tour-aws:latest
              """
            }
        }
        stage('Upload S3') { 
     steps {
              echo "upload to S3"
              dir("${env.WORKSPACE}"){
                sh 'zip -r deploy.zip ./deploy appspec.yml'
                withAWS(region:"${REGION}", credentials: "${AWS_CREDENTIAL_NAME}"){
                  s3Upload(file:"deploy.zip", bucket:"team03-bucket")
               }
               sh 'rm -rf ./deploy.zip'
             }
           }
        }
       stage('deploy create-application') { 
        steps {
                 withAWS(region:"${REGION}", credentials: "${AWS_CREDENTIAL_NAME}"){
                   sh 'aws deploy create-application --application-name team03-deploy'
                 }
            }
       }
        stage('deploy create-deployment-group') {
            steps {
                 withAWS(region:"${REGION}", credentials: "${AWS_CREDENTIAL_NAME}"){
                sh """ 
                    aws deploy create-deployment-group \
                        --application-name team03-deploy \
                        --auto-scaling-groups team03_asg \
                        --deployment-config-name CodeDeployDefault.OneAtATime \
                        --deployment-group-name team03-deploy-group \
                        --service-role-arn arn:aws:iam::491085389788:role/team03_CodeDeploy_Role
                   """
                 }
            }
        }
        stage('deploy create-deployment') {
            steps {
                 withAWS(region:"${REGION}", credentials: "${AWS_CREDENTIAL_NAME}"){
                sh """ 
                    aws deploy create-deployment \
                        --application-name team03-deploy \
                        --deployment-config-name CodeDeployDefault.OneAtATime \
                        --deployment-group-name team03-deploy-group \
                        --s3-location bucket=team03-bucket,bundleType=zip,key=deploy.zip
                   """
                 }
            }
        }
    }
}
