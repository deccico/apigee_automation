#!/bin/bash -e
set -o nounset

echo ------------------------
echo Persisting proxy in Git

pwd

mkdir -p /tmp/.ssh
SSH_FILE=/tmp/.ssh/id_rsa

if [ ! -z ${SSH_PRIVATE_KEY+x} ]; then
    echo Push $proxy proxy config
    echo "${SSH_PRIVATE_KEY}" > $SSH_FILE
    chmod 400 $SSH_FILE
fi

git config --global user.name "Jenkins Agent"
git config --global user.email "Jenkins_Agent@localhost"
git add $proxy
git commit -m "adding $proxy proxy config"
GIT_SSH_COMMAND="ssh -o 'StrictHostKeyChecking no' -i $SSH_FILE" git push $REPO_ORIGIN `git rev-parse HEAD`:$git_branch

