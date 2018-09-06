#!/bin/bash -ex
set -o nounset

API_NAME=$1

git config --global user.name "Jenkins Agent"
git config --global user.email "Jenkins_Agent@localhost"
git remote add persist $GIT_URL || echo ''

git add $API_NAME
git commit -m "adding $API_NAME proxy config"
git push origin HEAD:master


