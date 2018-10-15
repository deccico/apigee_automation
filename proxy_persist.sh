#!/bin/bash -e
set -o nounset

echo ------------------------
echo Persisting proxy in Git

pwd

mkdir -p /tmp/.ssh
SSH_FILE=/tmp/.ssh/id_rsa

if [ $SSH_PRIVATE_KEY ]; then
    echo Create SSH file
    echo "${SSH_PRIVATE_KEY}" > $SSH_FILE
    chmod 400 $SSH_FILE
fi

git config --global user.name "Jenkins Agent"
git config --global user.email "Jenkins_Agent@localhost"
git add api-proxies/$proxy
git commit -m "adding $proxy proxy config"
echo git push origin $(git rev-parse HEAD):$git_branch
GIT_SSH_COMMAND="ssh -o 'StrictHostKeyChecking no' -i $SSH_FILE" git push origin $(git rev-parse HEAD):$git_branch

