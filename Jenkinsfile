pipeline {
    agent {label 'ubuntu'}

    stages {
        stage('Git Checkout') { 
            steps { 
                echo 'Checking out the main repository'                
                checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'CleanBeforeCheckout']], submoduleCfg: [], userRemoteConfigs: [[url: 'git@gitlab.com:snsw-int/apigee_automation.git']]])
                echo 'Checking out the apigee apis repository'      
                checkout changelog: false, poll: false, scm: [$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'CloneOption', noTags: true, reference: '', shallow: false], [$class: 'RelativeTargetDirectory', relativeTargetDir: 'apigee_apis']], submoduleCfg: [], userRemoteConfigs: [[url: 'git@gitlab:snsw-int/apigee_apis.git']]]
            }
        }
        stage('Apigee proxy generation'){
                steps {
                    echo 'Creating Apigee proxy'
                    sh './proxy_gen.sh $API_NAME $API_TARGET_URL $API_NAME'
                }
        }
        stage('Setup Apigee proxy policies'){
                steps {
                    echo 'Setup Apigee proxy policies'
                    sh 'python police.py $API_NAME/apiproxy/ $API_NAME'
                }
        }
        stage('Apigee proxy deploy'){
                steps {
                    echo 'Apigee proxy deploy'
                    sh './proxy_deploy.sh $API_NAME'
                }
        }
        stage('Apigee configuration persistence'){
                steps {
                    echo 'Save the new config on Gitlab'
                    sh './proxy_git_persist.sh $API_NAME'
                }
        }
    }
}
