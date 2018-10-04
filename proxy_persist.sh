#!/bin/bash -ex

if [ ! -z ${SSH_PRIVATE_KEY+x} ]; then
    echo Push $proxy proxy config
    echo "${SSH_PRIVATE_KEY}" > /tmp/.id_rsa
    cd $pwd
    git config --global user.name "Jenkins Agent"
    git config --global user.email "Jenkins_Agent@localhost"
    git add $proxy
    git commit -m "adding $proxy proxy config"
    GIT_SSH_COMMAND="ssh -o 'StrictHostKeyChecking no' -i /tmp/.id_rsa" git push origin $git_branch
    cd /code/apigee_automation/
fi

