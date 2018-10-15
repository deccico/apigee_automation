#!/bin/bash -e
set -o nounset

echo ------------------------
echo Persisting proxy in Git

git config --global user.name "Jenkins Agent"
git config --global user.email "Jenkins_Agent@localhost"
git add api-proxies/$proxy
git commit -m "adding $proxy proxy config"

url_host=`git remote get-url origin | sed -e "s/https:\/\/gitlab-ci-token:.*@//g"`
git remote set-url origin "https://gitlab-ci-token:${SSH_PRIVATE_KEY}@${url_host}"
echo git push origin $(git rev-parse HEAD):$git_branch
git push origin $(git rev-parse HEAD):$git_branch

